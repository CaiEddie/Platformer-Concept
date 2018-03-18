local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'

local Wire = class ("Wire", Entity)

local img = love.graphics.newImage("assets/sprites/player/landingdust.png")


function Wire:initialize(map, world, x, y, properties, width, height, polyline)
	self.map = map 
	local points = {polyline[1].x, polyline[1].y, polyline[2].x, polyline[2].y, polyline[3].x, polyline[3].y}
	self.curve = love.math.newBezierCurve(points)
	self.properties = properties
  table.insert(self.map.entities, self)
end

function Wire:update(dt)
	local time = love.timer.getTime()
	local x, y = self.curve:getControlPoint(2)
	self.curve:setControlPoint(2, x, y + 0.05*math.sin(time))
end

function Wire:draw(debug)
	love.graphics.setColor(103,114,169,255)
	love.graphics.setLineStyle('rough')
	love.graphics.setLineWidth( 1.0 )
	love.graphics.line(self.curve:render(5))
	love.graphics.setColor(255,255,255,255)
end

return Wire