
local class   = require 'lib.middleclass'
local Entity  = require 'source.entities.entity'

local Sign = class('Sign', Entity)

local w, h = 8, 8
local limit = 200

function Sign:initialize(map, world, x, y, properties)
  Entity.initialize(self, map, world, x, y, w, h)
  self.drawOrder = math.random(10, 900)
  self.map = map
  self.properties = properties
  self.properties.passable = true
end

function Sign:update(dt)
end

function Sign:draw()
  if self.properties.isDead then return false end
  love.graphics.printf(self.properties.text, self.x, self.y, limit)
end

return Sign
