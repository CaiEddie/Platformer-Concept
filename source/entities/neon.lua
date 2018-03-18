local class   = require 'lib.middleclass'
local Entity  = require 'source.entities.entity'
local Stateful = require 'lib.stateful'

local Neon = class('Neon', Entity)
Neon:include(Stateful)

local imgon = love.graphics.newImage('assets/sprites/neon/neon.png')
local imgoff = love.graphics.newImage('assets/sprites/neon/neoff.png')
local w, h = 64, 16

function Neon:initialize(map, world, x, y, properties)
  Entity.initialize(self, map, world, x, y, w, h)
  self.drawOrder = math.random(10, 900)
  self.map = map
  self.properties = properties
  self.imgon = imgon
  self.imgoff = imgoff
end

function Neon:update(dt)
	if not self.map.level.properties[self.properties.switch] then 
		self:gotoState('Off')
	end
end

function Neon:draw()
  if self.properties.isDead then return false end
  love.graphics.draw(self.imgon, self.x, self.y, 0, 1, 1, 0, 0)
end

local Off = Neon:addState('Off')
	
function Off:enteredState()
	self.properties.passable = true
end

function Off:update(dt)
	if self.map.level.properties[self.properties.switch] then 
		local items, len = self.world:queryRect(self.x, self.y, self.w, self.h)
		if len < 2 then 
			self:gotoState(nil)
		end
	end
end

function Off:draw()
  if self.properties.isDead then return false end
  love.graphics.draw(self.imgoff, self.x, self.y, 0, 1, 1, 0, 0)
end

function Off:exitedState()
	self.properties.passable = false
end

return Neon
