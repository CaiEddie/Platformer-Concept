local class   = require 'lib.middleclass'
local Entity  = require 'source.entities.entity'
local Stateful = require 'lib.stateful'
local anim8 = require 'lib.anim8'
local Timer = require 'lib.timer'

local Neon = class('Neon', Entity)
Neon:include(Stateful)

local particleimg = love.graphics.newImage('assets/sprites/neon/particles.png')

function Neon:initialize(map, world, x, y, properties)
	
	local w, h
	if properties.type then 
		self.img = love.graphics.newImage('assets/sprites/neon/'..properties.type..'.png')
		w = self.img:getWidth()
		h = self.img:getHeight()/3
	end

  Entity.initialize(self, map, world, x, y, w, h)
  self.drawOrder = math.random(10, 900)
  self.map = map
  self.properties = properties


	self.PS = love.graphics.newParticleSystem(particleimg, 50)
  self.PS:setAreaSpread( "uniform", 1, 1)
  self.PS:setRadialAcceleration(-100, 100)
  self.PS:setTangentialAcceleration(-100,100)
	self.PS:setParticleLifetime( 0.1, 0.5)




	local grid = anim8.newGrid(self.w, self.h, self.img:getWidth(), self.img:getHeight())
	self.anim = anim8.newAnimation(grid(1, '1-3', 1,1), 0.05, "pauseAtEnd")
	self.timer = Timer()
	self.timer:every({0.1, 5}, function() 
		self.anim:gotoFrame(1) 
		self.anim:resume() 
		self.PS:setPosition(self.x + math.random(0,self.w), self.y + math.random(0,self.h))
		self.PS:emit(10)
		end )

end

function Neon:update(dt)
	if not self.map.level.properties[self.properties.switch] then 
		self:gotoState('Off')
	end
	self.anim:update(dt)
	self.timer:update(dt)
	self.PS:update(dt)
end

function Neon:draw()
  if self.properties.isDead then return false end
  self.anim:draw(self.img, self.x, self.y, 0, 1, 1, 0, 0)
 	love.graphics.draw(self.PS, 0, 0)
end

local Off = Neon:addState('Off')
	
function Off:enteredState()
	self.properties.passable = true
	self.anim:gotoFrame(3)
end

function Off:update(dt)
	if self.map.level.properties[self.properties.switch] then 
		local items, len = self.world:queryRect(self.x, self.y, self.w, self.h)
		if len < 2 then 
			self:gotoState(nil)
		end
	end
	self.PS:update(dt)
end

function Off:exitedState()
	self.properties.passable = false
	self.anim:gotoFrame(1) 
	self.anim:resume() 
end

return Neon
