local class = require 'lib.middleclass'
local Light = require 'source.entities.light'
local Entity = require 'source.entities.entity'

local Lamp = class ("Lamp", Entity)

local img = love.graphics.newImage("assets/sprites/lamp.png")

local w = 13
local h = 25
local delay = 0.2

function Lamp:initialize(map, world, x, y)
  Entity.initialize(self, map, world, x, y, w, h, true)
	self.map = map 
	self.x = x 
	self.y = y 
	self.properties ={passable = true}
	self.light = Light:new(self.map, self.x, self.y, 'circle', 0.7, 0.7, "normal")
	self.counter = delay 
end

function Lamp:update(dt)
	if  math.sqrt ( (self.map.player.x - self.x)^2 + (self.map.player.y - self.y)^2 ) < 64 and not self.map.player.possess then 
		self.counter = self.counter - dt
	else 
		self.counter = delay 
	end

	if self.counter < 0 then 
--		self.map.player:die()
	end
end

function Lamp:draw(debug)

end

return Lamp