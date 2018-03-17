local class = require 'lib.middleclass'

DustParticles = class ("DustParticles")

local img = love.graphics.newImage("assets/sprites/dustparticles.png")

function DustParticles:initialize(x,y)
	self.PS = love.graphics.newParticleSystem(img, 50)
  self.PS:setAreaSpread( "uniform", 3, 3)
  self.PS:setRadialAcceleration(-10, 10)
  self.PS:setTangentialAcceleration(-1,1)
	self.PS:setParticleLifetime( 0.1, 0.5)
end

function DustParticles:emit(amount, x, y)
	self.PS:setPosition(x,y)
	self.PS:emit(amount)
end

function DustParticles:update(dt)
	self.PS:update(dt)
end

function DustParticles:draw()
	love.graphics.draw(self.PS, 0, 0)
end

return DustParticles