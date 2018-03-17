local Timer = require 'lib.timer'
local PaletteSwap = require 'lib.paletteswap'
local AmbientParticles = require 'lib.ambientparticles'

local Camera = class("Camera")

function Camera:initialize(map, x, y, w, h)
	self.map = map
	self.x = x 
	self.y = y 
	self.w = w
	self.h = h
	self.Ox = 0 
	self.Oy = 0
	self.Gx = 0
	self.Gy = 0
	self.Wx = 0
	self.Wy = 0
	self.WScale = 1 
	self.scale = 1
	self.timer = Timer()
	self.paletteSwap = PaletteSwap:new()
	self.ambientParticles = AmbientParticles:new(self)
	self.darkPalette = 4
	self:neonFlicker()
end

function Camera:neonFlicker()
	self.timer:every({0.5, 3}, function() 

			self.darkPalette = 5  
			self.timer:after({0.1, 0.5}, function() 
				self.darkPalette = 4 
			end)

		end)
end

function Camera:adjustPosition()
	if (self.x > 0) then 
		self.Gx = 0 
	elseif self.x < -self.map.level.width*8 +self.w then
		self.Gx = -self.map.level.width*8 +self.w 
	else 
		self.Gx = self.x 
	end
	if (self.y > 0) then 
		self.Gy = 0 
	elseif self.y < -self.map.level.height*8 +self.h then
		self.Gy = -self.map.level.height*8 +self.h
	else
		self.Gy = self.y 
	end
end

function Camera:setPosition(x, y)
	self.x = x 
	self.y = y
	self:adjustPosition()
end

function Camera:getPosition()
	return self.x, self.y 
end

function Camera:setScale(scale)
	self.scale = scale
end

function Camera:getScale()
	return self.scale 
end

function Camera:setCenter(x, y)
	local x = -x + self.w/2
	local y = -y + self.h/2

	self:setPosition(x, y)

end

function Camera:getCenter()
	return -self.Gx + self.w/2 , -self.Gy + self.h/2
end

function Camera:getAspectRatioScale(wx, wy)
	local sfx, sfy
  if wx > self.w and wy > self.h then 
    sfx = wx / self.w
    sfy = wy / self.h

    if sfx > sfy then sfx = sfy end
    if sfy > sfx then sfy = sfx end
  end
  return sfx or 1
end

function Camera:resize(w, h)

	self.WScale = self:getAspectRatioScale(w, h)

	local new_w = self.w*self.WScale
	local new_h = self.h*self.WScale
	local new_x = (love.graphics.getWidth() - new_w) / 2
	local new_y = (love.graphics.getHeight() - new_h) / 2 

	self.Wx = new_x 
	self.Wy = new_y 

end

function Camera:getScreenInfo()
	return self.Wx, self.Wy, self.WScale
end

function Camera:screenShake(duration, xmagnitude, ymagnitude)
	self.timer:during(duration, function() 
		local dx = love.math.random(-xmagnitude, xmagnitude)
		local dy = love.math.random(-ymagnitude, ymagnitude)
		self.Ox = dx 
		self.Oy = dy
		end, function() 
		self.Ox = 0
		self.Oy = 0
		end)

end

local sortByDrawOrder = function(a,b)
	return a:getDrawOrder() > b:getDrawOrder()
end

function Camera:update(dt)
	self.timer:update(dt)
	self.ambientParticles:update(dt)
end

local light_canvas = love.graphics.newCanvas()
local mask = love.graphics.newCanvas()
local light_canvas_center = love.graphics.newCanvas()
local maskCenter = love.graphics.newCanvas()
local light_canvas_red_center = love.graphics.newCanvas()
local maskRedCenter = love.graphics.newCanvas()

function Camera:draw(level, entities, lights, debug)
	lg = love.graphics
	local current_canvas = lg.getCanvas()

	lg.setCanvas(level.canvas)
	lg.clear()
	lg.setBlendMode("alpha")
	-- Scale map to 1.0 to draw onto canvas, this fixes tearing issues
	-- Map is translated to correct position so the right section is drawn
	lg.push()

	for _, layer in ipairs(level.layers) do
		if layer.visible and layer.opacity > 0 then
			local x, y = self.Gx+self.Ox , self.Gy+self.Oy

				if layer.properties.parallax then 
					x = self.Gx * layer.properties.parallax
					y = self.Gy * layer.properties.parallax
				end

			lg.origin()
			lg.translate(x or 0 , y or 0)
			level:drawLayer(layer, tx, ty)
		end
	end


	self.ambientParticles:draw()

	table.sort(entities, sortByDrawOrder)

	for i, entity in ipairs(entities) do 
		entity:draw(debug)
	end

	lg.setCanvas(mask)
	lg.clear(0,0,0)
	lg.setCanvas(maskCenter)
	lg.clear(0,0,0)
	lg.setCanvas(maskRedCenter)
	lg.clear(0,0,0)

 
  lg.setBlendMode("multiply")

  for i,light in ipairs(lights) do
  	if light.type == 'normal' then  
	  	light:drawEdge(mask, debug)
	  	light:drawCenter(maskCenter, debug)
	  elseif light.type == 'red' then
	  	light:drawCenter(maskRedCenter, debug)
	  end
	end



	lg.setColor(255,255,255,255)

	lg.setCanvas()

	lg.pop()

	lg.setBlendMode("alpha")
	lg.setCanvas(light_canvas)
	lg.draw(level.canvas)
	self.paletteSwap:set('grey')
	lg.draw(mask)
	self.paletteSwap:unset()

	lg.setCanvas(light_canvas_center)
	lg.draw(level.canvas)
	self.paletteSwap:set('grey')
	lg.draw(maskCenter)
	self.paletteSwap:unset()
	lg.setCanvas(light_canvas_red_center)
	lg.draw(level.canvas)
	self.paletteSwap:set('grey')
	lg.draw(maskRedCenter)
	self.paletteSwap:unset()

	-- Draw canvas at 0,0; this fixes scissoring issues
	-- Map is scaled to correct scale so the right section is shown
	lg.push()
	lg.origin()
	lg.translate(self.Wx, self.Wy)
	lg.scale(math.floor(self.WScale) or 1, math.floor(self.WScale) or 1)
	lg.setCanvas(current_canvas)

	self.paletteSwap:setPalette(self.darkPalette)
	self.paletteSwap:set()
	lg.draw(level.canvas)
	self.paletteSwap:unset()

	lg.setCanvas(current_canvas)

	self.paletteSwap:setPalette(3)
	self.paletteSwap:set()
	lg.draw(light_canvas)
	self.paletteSwap:unset()

	self.paletteSwap:setPalette(2)
	self.paletteSwap:set()
	lg.draw(light_canvas_center)
	self.paletteSwap:unset()

	self.paletteSwap:setPalette(6)
	self.paletteSwap:set()
	lg.draw(light_canvas_red_center)
	self.paletteSwap:unset()



	lg.pop()

end


return Camera