local class = require 'lib.middleclass'
local Timer = require 'lib.timer'

local Light = class ("Light")

local imgCenter = love.graphics.newImage("assets/sprites/lightcenter.png")
local imgEdge = love.graphics.newImage("assets/sprites/lightedge.png")
local buffer = love.graphics.newCanvas()

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

function Light:drawEdge(canvas, debug)
	if self.shape == circle then 
		lg.setCanvas(buffer)
		lg.clear(0,0,0)
		lg.setBlendMode('multiply')
		lg.push()
		lg.origin()
		love.graphics.draw(imgEdge, math.floor(self.x)+0.5, math.floor(self.y)+0.5, 0, self.Sx, self.Sy, imgEdge:getWidth()/2, imgEdge:getHeight()/2 )
		lg.setBlendMode('alpha')	
		lg.setColor(0,0,0)
		self:drawShadows()
		lg.pop()
		lg.setColor(255,255,255, 255)
		lg.setCanvas(canvas)
		lg.setBlendMode('multiply')
		lg.draw(buffer)
	end
end

function Light:drawCenter(canvas, debug)
	if self.shape == 'circle' then

		lg.setCanvas(buffer)
		lg.clear(0,0,0)
		lg.setBlendMode('multiply')
		lg.push()
		lg.origin()
		love.graphics.draw(imgCenter, math.floor(self.x)+0.5, math.floor(self.y)+0.5, 0, self.Sx, self.Sy, imgCenter:getWidth()/2, imgCenter:getHeight()/2 )
		lg.setBlendMode('alpha')	
		lg.setColor(0,0,0)
		self:drawShadows()
		lg.pop()
		lg.setColor(255,255,255, 255)
		lg.setCanvas(canvas)
		lg.setBlendMode('multiply')
		lg.draw(buffer)
	end

	if self.shape == 'rectangle' then 
	lg.setCanvas(buffer)
		lg.clear(0,0,0)
		lg.setBlendMode('multiply')
		lg.push()
		lg.origin()
		lg.setColor(255,255,255, 0)
		love.graphics.rectangle('fill', self.x-self.Sx, self.y-self.Sy, self.Sx*2, self.Sy*2)
		lg.pop()
		lg.setColor(255,255,255, 255)
		lg.setCanvas(canvas)
		lg.setBlendMode('multiply')
		lg.draw(buffer)
	end

end

function Light:drawShadows()
local Gx, Gy = self.x, self.y

	local items, len = self.map.world:queryRect(self.x-imgCenter:getWidth()/2, self.y-imgCenter:getWidth()/2, imgCenter:getWidth() , imgCenter:getHeight())

	for i=1, len do 
		item = items[i]
		if item.properties.shadows then 

			local N = item.y 
			local S = item.y + (item.height or item.h)
			local W = item.x 
			local E = item.x + (item.width  or item.w)

			local horizontal
			local vertical

			local x, y, x2, y2

			if Gy < N then 
				vertical = 'north'
			elseif Gy > S then
				vertical = 'south'
			else 
				vertical = 'center'
			end

			if Gx < W then 
				horizontal = 'west'
			elseif Gx > E then
				horizontal = 'east'
			else 
				horizontal = 'center'
			end

			if vertical == 'north' then 
				if horizontal == 'west' then 
					x = E 
					y = N 
					x2 = W
					y2 = S
				elseif horizontal == 'east' then 
					x = W 
					y = N 
					x2 = E
					y2 = S
				else 
					x = W 
					y = N +1
					x2 = E 
					y2 = N +1
				end
			elseif vertical == 'south' then
				if horizontal == 'west' then 
					x = W 
					y = N 
					x2 = E 
					y2 = S
				elseif horizontal == 'east' then 
					x = E 
					y = N 
					x2 = W
					y2 = S
				else 
					x = W 
					y = S -1
					x2 = E 
					y2 = S -1
				end
			else 
				if horizontal == 'west' then 
					x = W +1
					y = N 
					x2 = W +1
					y2 = S 
				elseif horizontal == 'east' then 
					x = E -1
					y = N 
					x2 = E -1
					y2 = S
				end
			end

			if x and y and x2 and y2 then 
				love.graphics.polygon('fill', x, y, x2, y2,  Gx + (x-Gx)*50, Gy + (y-Gy)*50,  Gx+ (x2-Gx)*50, Gy+ (y2-Gy)*50, x2, y2 ) 
			end
		end
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