local class = require 'lib.middleclass'

AmbientParticles = class ("AmbientParticles")

local img = love.graphics.newImage("assets/particles.png")

function AmbientParticles:initialize(camera)
	self.camera = camera
	self.PS = love.graphics.newParticleSystem(img, 400)
  self.PS:setAreaSpread( "uniform", 192*2, 108*2)
  self.PS:setEmissionRate(50)
  self.PS:setRadialAcceleration(-1,1)
  self.PS:setTangentialAcceleration(-1,1)
	self.PS:setParticleLifetime( 2, 10)
	self.PS:emit(400)
end

function AmbientParticles:update(dt)
	self.PS:setPosition(self.camera:getCenter())
	self.PS:emit(10)
	self.PS:update(dt)
end

function AmbientParticles:draw()
	love.graphics.draw(self.PS, 0, 0)
end

return AmbientParticles