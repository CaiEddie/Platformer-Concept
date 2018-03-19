local bump = require 'lib.bump'
local sti = require 'lib.sti'
local Camera = require 'source.camera' 
local Timer = require 'lib.timer'

local debugroom = 'dashroom1'

local entityList = {
	Player = require 'source.entities.player',
	Vase = require 'source.entities.vase',
	Sign = require 'source.entities.sign',
	Shelf = require 'source.entities.shelf',
	LevelChange = require 'source.entities.levelchange',
	Switch = require 'source.entities.switch',
	Lamp = require 'source.entities.lamp',
	Neon = require 'source.entities.neon',
	Wire = require 'source.entities.wire',
	Sparks = require 'source.entities.sparks'
}

local cameraTween = 12

local Map = class('Map')

function Map:initialize(game, width, height)
	self.game = game
	self.camera = Camera:new(self, 0,0, width, height)
	self.conditions = {vaselocked = true, shelflocked = true}
	self.timer = Timer()
	self:reset()
end

function Map:reset()
	self.game:log("Map has been reset")
	self:loadLevel(self.levelName or debugroom or "testroom")
end

function Map:loadLevel(level)
	local location = self.location or self.levelName or debugroom or "testroom"
	local locationBackup = self.levelName or debugroom or "testroom"
	self.levelName = level
	self.level = sti("assets/levels/"..level..".lua", {"bump"})
	self.entities = {}
	self.lights = {}
	self.playerSpawned = false
	self.world = nil
	self.world = bump.newWorld()
	self.level:bump_init(self.world)

	for k, obj in pairs(self.level.objects) do
		if obj.name == "Player" then
			if obj.properties.location == location then 
				self.player = entityList["Player"]:new(self, self.world, obj.x, obj.y)
				self.playerSpawned = true
			end
		else
			if not self.conditions[obj.properties.condition] then 
				if obj.name ~= '' then
					entityList[obj.name]:new(self, self.world, obj.x, obj.y, obj.properties, obj.width, obj.height, obj.polyline)
				end
			end
		end
	end

	if self.playerSpawned == false then 
		for k, obj in pairs(self.level.objects) do
			if obj.name == "Player" then
				if obj.properties.location == locationBackup then 
					self.player = entityList["Player"]:new(self, self.world, obj.x, obj.y)
					self.playerSpawned = true
				end
			end
		end
	end
end

function Map:sleep(time)
	self.sleeping = true 
	self.timer:after(time, function() self.sleeping = false end)
end

function Map:keypressed(key)
	if key == 'r' then 
		self:reset()
	end
	self.player:keypressed(key)

	if key == 't' then 
		self.level.properties.A = false 
	end
	if key == 'y' then 
		self.level.properties.A = true 
	end
end

function Map:keyreleased(key)
	self.player:keyreleased(key)
end


local targetx, targety = 0, 100

function Map:update(dt)

	self.timer:update(dt)

	if self.sleeping then return false end

						if self.player.x - targetx > 20 then 
							targetx = targetx +  (self.player.x -22 - targetx) * cameraTween * dt
						end

						if self.player.x - targetx < -20 then 
							targetx = targetx + (self.player.x +22 - targetx) * cameraTween *dt
						end

						if self.player.y - targety > 20 then 
							targety = targety +  (self.player.y -22 - targety) * cameraTween *dt
						end

						if self.player.y - targety < -20 then 
							targety = targety + (self.player.y + 22 - targety) *  cameraTween *dt
						end

--						if not self.player.properties.isDying then
--							if self.player.y > 200  then 
--								targety = targety + (300 - targety) * 0.2
--							else 
--								targety = targety + (100 - targety) * 0.2
--							end
--						end

	self.camera:setCenter(targetx, targety)
	self.camera:update(dt)

	for i, entity in pairs(self.entities) do 
		entity:update(dt)
	end

	for i, light in pairs(self.lights) do 
		light:update(dt)
	end

	self.level:update(dt)

end

function Map:draw(debug)
	self.camera:draw(self.level, self.entities, self.lights, debug)
end

return Map