local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'

local LevelChange = class ('LevelChange', Entity)

function LevelChange:initialize(map, world, x, y, properties, width, height)
	Entity.initialize(self, map, world, x, y, width, height)
	self.map = map
	self.world = world 
	self.properties = properties 
end

function LevelChange:update(dt)
end

function LevelChange:draw(debug)
	if debug then 
		love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
	end
end

function LevelChange:onTouch()
	self.map:loadLevel(self.properties.level)
end

return LevelChange