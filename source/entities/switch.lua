local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Light = require 'source.entities.light'


local imgon = love.graphics.newImage('assets/sprites/switch/switchon.png')
local imgoff = love.graphics.newImage('assets/sprites/switch/switchoff.png')
local width = 8 
local height = 16

local jumpSpeed = -160

local Switch = class ('LevelChange', Entity)
Switch.static.drawOrder = 2

function Switch:initialize(map, world, x, y, properties)
	Entity.initialize(self, map, world, x, y, width, height)
	self.map = map
	self.world = world 
	self.properties = properties 
	self.active = false 
	self.properties.possessable = true
	self.x = x 
	self.y = y 
	self.r = 0 
	self.Gx, self.Gy = self:getCenter()
	self.Ox = self.Gx - self.x 
	self.Oy = self.Gy - self.y 
	self.Sx = 1 
	self.Sy = 1
	self.on = true
	self.light = Light:new(self.map, self.Gx, self.Gy, 'circle', 0.3, 0.3, "normal")
end

function Switch:update(dt)
end

function Switch:draw(debug)
	if self.on then 
		love.graphics.draw(imgon, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	else 
		love.graphics.draw(imgoff, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	end
end


function Switch:possessedEntered(player)
	self.properties.possessed = true
	player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic")   end)   end)

end

function Switch:possessedUpdate(player, dt)
	player.x = self.x 
	player.y = self.y 
end

function Switch:possessedKeyPressed(player, key)

	if key == 'x' or key == 'c' then

		if  key == 'x' and (player.leftKey or player.rightKey) and not (player.leftKey and player.rightKey) then 
			self.properties.possessed = false
			self.properties.possessable = false 
			self.properties.playerpassable = true
			player.timer:after(0.2, function() self.properties.possessable = true self.properties.playerpassable = false end )
			player:gotoState("Dash") 
		else 

			if self.on then 
				self.map.level.properties[self.properties.switch] = false 
				self.on = false
				player.y = player.y+18
				player.x = player.x+1
				player.dy = -jumpSpeed
				player:gotoState(nil) 
				player.charge = 1
			else 
				self.map.level.properties[self.properties.switch] = true
				self.on = true 
				player.y = player.y-18
				player.x = player.x+1
				player.dy = jumpSpeed
				player:gotoState(nil) 
				player.charge = 1
			end
		end

		self.map.camera:screenShake(0.1, 2, 0)
	end


	player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic")   end)   end)

end



return Switch