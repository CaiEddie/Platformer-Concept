local class   = require 'lib.middleclass'
local Entity  = require 'source.entities.entity'
local Timer = require 'lib.timer'

local Sparks = class('Sparks', Entity)

local particleimg = love.graphics.newImage('assets/sprites/neon/particles.png')

function Sparks:initialize(map, world, x, y, properties, width, height)
 	self.map = map 
  self.properties = properties
  self.x = x 
  self.y = y
  table.insert(self.map.entities, self)


	self.PS = love.graphics.newParticleSystem(particleimg, 50)
  self.PS:setAreaSpread( "uniform", 1, 1)
  self.PS:setRadialAcceleration(-100, 100)
  self.PS:setTangentialAcceleration(-100,100)
	self.PS:setParticleLifetime( 0.1, 0.5)

	self.timer = Timer()

	self.timer:every({0.05, 0.07}, function() 
		self.PS:setPosition(self.x + math.random(0,width), self.y + math.random(0, height))
		self.PS:emit(10)
		end )

end

function Sparks:update(dt)
	self.timer:update(dt)
	self.PS:update(dt)
end

function Sparks:draw()
	love.graphics.draw(self.PS, 0, 0)
end

return Sparks
