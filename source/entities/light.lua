local class = require 'lib.middleclass'
local Timer = require 'lib.timer'

local Light = class ("Light")

local imgCenter = love.graphics.newImage("assets/lightcenter.png")
local imgEdge = love.graphics.newImage("assets/lightedge.png")

function Light:initialize(map, x, y, shape, aSx, aSy, type)
	self.map = map 
	self.x = x 
	self.y = y 
	self.shape = shape
	self.Sx = 0
	self.Sy = 0
	self.type = type
	self.timer = Timer()
	table.insert(self.map.lights, self)
	self.timer:tween(0.5, self, {Sx = aSx, Sy = aSy}, "in-out-cubic")
end

function Light:update(dt)
	self.timer:update(dt)
end

function Light:drawEdge(debug)
	if self.shape == 'circle' then
		love.graphics.draw(imgEdge, math.floor(self.x)+0.5, math.floor(self.y)+0.5, 0, self.Sx, self.Sy, imgEdge:getWidth()/2, imgEdge:getHeight()/2 )
	end
end

function Light:drawCenter(debug)
	if self.shape == 'circle' then
		love.graphics.draw(imgCenter, math.floor(self.x)+0.5, math.floor(self.y)+0.5, 0, self.Sx, self.Sy, imgCenter:getWidth()/2, imgCenter:getHeight()/2 )
	end
end

function Light:die()
	self.timer:tween(0.5, self, {Sx = 0, Sy = 0}, "in-out-cubic", function() self:destroy() end)
end

function Light:destroy()
	self.isDead = true
	table.insert(self.map.lights, self)
	for i=#self.map.lights,1,-1 do
	    if self.map.lights[i].isDead then
	        table.remove(self.map.lights, i)
	    end
	end
end

return Light