local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'

local Switch = class ('LevelChange', Entity)
Switch.static.drawOrder = 3

function Switch:initialize(map, world, x, y, properties, width, height)
	Entity.initialize(self, map, world, x, y, width, height)
	self.map = map
	self.world = world 
	self.properties = properties 
	self.active = false 
	self.properties.passable = true
end

function Switch:update(dt)
end

function Switch:draw(debug)
	if debug then 
		if self.active then 
			love.graphics.setColor(100, 255, 100, 255)
		else 
			love.graphics.setColor(255, 100, 100, 255)
		end
		love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

		love.graphics.setColor(255,255,255,255)
	end
end

function Switch:onTouch()
	self.active = true
	if self.properties.trigger then 
		self.map.conditions[self.properties.trigger] = false
	end
	if self.properties.location then 
		self.map.location = self.properties.location 
	end
end

return Switch