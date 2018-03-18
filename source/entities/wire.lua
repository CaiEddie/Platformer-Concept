local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'

local Wire = class ("Wire", Entity)

local img = love.graphics.newImage("assets/sprites/player/landingdust.png")


function Wire:initialize(map, world, x, y, properties, width, height, polyline)
	self.map = map 
	self.curve = love.math.newBezierCurve(0,0, 100, 100)
end

function Wire:update(dt)
end

function Wire:draw(debug)
	love.graphics.setColor(255,255,255,255)
	love.graphics.line(0,0, 100,100)
end

return Wire