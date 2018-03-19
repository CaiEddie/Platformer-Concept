local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Light = require 'source.entities.light'
local Timer = require 'lib.timer'

local particleimg = love.graphics.newImage('assets/sprites/neon/particles.png')
local imgon = love.graphics.newImage('assets/sprites/switch/switchon.png')
local imgoff = love.graphics.newImage('assets/sprites/switch/switchoff.png')
local width = 13
local height = 22

local jumpSpeed = -220

local Switch = class ('LevelChange', Entity)
Switch.static.drawOrder = 2

function Switch:initialize(map, world, x, y, properties)
	Entity.initialize(self, map, world, x, y, width, height)
	self.map = map
	self.world = world 
	self.properties = properties 
	self.active = false 
	self.properties.possessable = true
	self.properties.passable = true
	self.x = x 
	self.y = y 
	self.r = 0 
	self.Gx, self.Gy = self:getCenter()
	self.Ox = self.Gx - self.x 
	self.Oy = self.Gy - self.y 
	self.Sx = 1 
	self.Sy = 1
	self.on = self.map.level.properties[self.properties.switch]
	self.light = Light:new(self.map, self.Gx, self.Gy, 'circle', 0.3, 0.3, "normal")

	self.timer = Timer()

	self.PS = love.graphics.newParticleSystem(particleimg, 50)
  self.PS:setAreaSpread( "uniform", 1, 1)
  self.PS:setRadialAcceleration(-100, 100)
  self.PS:setTangentialAcceleration(-100,100)
	self.PS:setParticleLifetime( 0.1, 0.5)

	self.timer:every({0.1, 5}, function() 
		self.PS:setPosition(self.x + math.random(0,self.w), self.y + math.random(0,self.h))
		self.PS:emit(10)
		end )

end

function Switch:update(dt)
	self.PS:update(dt)
	self.timer:update(dt)
end

function Switch:draw(debug)

	if self.on then 
		love.graphics.draw(imgon, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	else 
		love.graphics.draw(imgoff, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	end
 	love.graphics.draw(self.PS, 0, 0)
end


function Switch:possessedEntered(player)
	self.properties.possessed = true
	player.timer:tween(0.1, self, {Oy = self.Oy-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Oy = self.Oy+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Oy = self.Oy-1}, "in-out-cubic")   end)   end)
	
	self.PS:setPosition(self.x + math.random(0,self.w), self.y + math.random(0,self.h))
	self.PS:emit(10)
end

function Switch:possessedUpdate(player, dt)
	player.x = self.x 
	player.y = self.y 
end

function Switch:possessedKeyPressed(player, key)

	self.PS:setPosition(self.x + math.random(0,self.w), self.y + math.random(0,self.h))
	self.PS:emit(10)

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
				player.x = player.x + 4
				player.dy = -jumpSpeed
				player:gotoState(nil) 
				player.timer:after(0.05, function() player.charge = 1 end )
			else 
				self.map.level.properties[self.properties.switch] = true
				self.on = true 
				player.x = player.x + 4
				player.dy = jumpSpeed
				player:gotoState(nil) 
				player.timer:after(0.05, function() player.charge = 1 end )
			end
		end

		self.map.camera:screenShake(0.1, 2, 0)
	end


	player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic")   end)   end)

end




return Switch