local class = require 'lib.middleclass'

local Entity = class('Entity')

local gravity = 400
local maxSpeed = 150

function Entity:initialize(map, world, x,y,w,h, passable)
  self.map = map
	self.world, self.x, self.y, self.w, self.h = world, x,y,w,h
	self.dx, self.dy = 0,0
  if not passable then 
  	self.world:add(self, x,y,w,h)
  end
  self.gravity = gravity
  self.fallSpeed = maxSpeed

  table.insert(self.map.entities, self)
end

function Entity:getCenter()
	return 	self.x + self.w / 2,
					self.y + self.h / 2
end

function Entity:applyGravity(dt)
  if self.dy < self.fallSpeed then 
    self.dy = self.dy + self.gravity * dt
  end
end

function Entity:bounce(nx, ny, bounciness)

  if self.properties.movable and self.timer and bounciness then 
    self.properties.movable = false 
    self.timer:after(0.2, function() self.properties.movable = true end)
  end

  bounciness = bounciness or 0 or self.bounciness
  local dx, dy = self.dx, self.dy

  if (nx < 0 and dx > 0) then
    dx = -bounciness
    if bounciness ~= 0 then 
      dy = -bounciness/2
    end
  end
  if (nx > 0 and dx < 0) then
    dx = bounciness
    if bounciness ~= 0 then 
      dy = -bounciness/2
    end
  end
  if (ny < 0 and dy > 0) then
    dy = -bounciness
  end
  if (ny > 0 and dy < 0) then
    dy = bounciness
  end

  if self.spin then 
    self.spin = -self.spin
  end


  self.dx, self.dy = dx, dy
end

function Entity:destroy()
  self.properties.isDead = true
  if self.timer then 
    self.timer:destroy()
  end

  if self.light then 
    self.light:die()
  end

	self.world:remove(self)
  for i, v in pairs(self.map.entities) do
    if v.properties.isDead then 
      table.remove(self.map.entities, i)
    end
  end
end

function Entity:getDrawOrder()
	return self.class.drawOrder or self.drawOrder or 10000
end

return Entity