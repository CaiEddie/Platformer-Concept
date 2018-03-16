
local class   = require 'lib.middleclass'
local Entity  = require 'source.entities.entity'
local Timer = require 'lib.timer'

local Debris = class('Debris', Entity)

local minTime = 1.5 
local maxTime = 3
local maxSpin = 2
local friction = 30


function Debris:initialize(parent, map, world, x, y, img, vel)

  local w, h = img:getWidth()-1, img:getHeight()-1

  Entity.initialize(self, map, world, x, y, w, h)
  self.drawOrder = math.random(-20, -1)
  self.map = map
  self.img = img
  self.parent = parent
  self.dx = math.random(-vel, vel)
  self.dy = math.random(-vel, vel)
  local Gx, Gy = self:getCenter()
  self.Ox = Gx - self.x
  self.Oy = Gy - self.y 
  self.Sx = 1 
  self.Sy = 1
  self.r = 0
  self.spin = math.random(-maxSpin, maxSpin)
  self.properties = {isDead = false, passable = true, debris = true}
  self.timer = Timer()
  self.timer:after(math.random(minTime, maxTime), function() self:die() end)

end

function Debris:filter(other)
  if other.properties.player or other.properties.isDead or other.properties.passable or other == self.parent  then return false else return "slide" end
end

function Debris:checkOnGround(ny, other, dt)
  if ny < 0 then 
    self.dx = self.dx * (friction) *dt
    self.r = self.r * friction * dt
    self.dy = -self.dy * friction * dt
    if other.actualdx then 
      self.dx = other.actualdx
    end
  end
end

function Debris:moveCollision(dt)
  if self.properties.isDying or self.properties.isDead then return false end
  local world = self.world
  local tx = self.x + self.dx * dt
  local ty = self.y + self.dy * dt 

  local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

  for i=1, len do 
    local col = cols[i]
    self:bounce(col.normal.x, col.normal.y, col.other.properties.bounciness)
    self:checkOnGround(col.normal.y, col.other, dt)

    if col.other.properties.shelf then 
      return false 
    end
  end
    self.x = rx 
    self.y = ry 
    self.r = self.r + self.spin*dt
end

function Debris:update(dt)
    self.timer:update(dt)
    self:applyGravity(dt)
    self:moveCollision(dt)
end

function Debris:die()
  if self.properties.isDying then return false end
  self.properties.isDying = true
  self.timer:tween(1, self, {Sx = 0, Sy = 0, r = 3}, 'in-out-cubic', function() self:destroy() end )
end

function Debris:draw()

  local Gx, Gy = self:getCenter()
  love.graphics.draw(self.img, Gx, Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
end

return Debris
