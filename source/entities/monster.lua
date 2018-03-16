local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Timer = require 'lib.timer'

local Monster = class ('Monster', Entity)
Monster.static.drawOrder = 0
local width = 16
local height = 32
local img = love.graphics.newImage('assets/sprites/monster.png')
local speed = 0

function Monster:initialize(map, world, x, y)
	Entity.initialize(self, map, world, x, y, width, height)
	self.img = img 
	self.map = map
	self.world = world 
	self.dx = 0
	self.dy = 0
	self.Gx, self.Gy = self:getCenter()
	self.Ox = self.Gx - self.x +1
	self.Oy = self.Gy - self.y +1
	self.Sx = 0
	self.Sy = 0
	self.r = 0
	self.targetx = x
	self.targety = y
	self.timer = Timer()
	self.properties = {monster = true, damaging = true, passable = true}
	self.timer:tween(0.5, self, {Sx = 1, Sy = 1, r = 0}, 'in-out-cubic')
end

function Monster:filter(other)
	if self.properties.isDying or other.properties.isDying or  other.properties.passable then 
		return false 
	else 
		return false
	end
end


function Monster:AI(dt)

	self.dx = self.dx/2 
	self.dy = self.dy/2

	if self:seePlayer() then 
		self.targetx, self.targety = self:seePlayer() 
	end

		if self.x < self.targetx - self.w/2  then
			self.dx = self.dx + speed*dt
		end

		if self.x > self.targetx - self.w/2 then
			self.dx = self.dx - speed*dt
		end

		if self.y < self.targety - self.h/2 then
			self.dy = self.dy + speed*dt
		end

		if self.y > self.targety - self.h/2 then
			self.dy = self.dy - speed*dt
		end

	self.dx = self.dx + math.random(-2, 2)
	self.dy = self.dy + math.random(-2, 2)

	self.targetx = self.targetx + math.random(-2,2)
	self.targety = self.targety + math.random(-2,2)

end

function Monster:seePlayer()
	if self.map.player.possess then return false else return self.map.player:getCenter() end
end

function Monster:moveCollisions(dt)
	local world = self.world
	local tx = self.x + self.dx * dt
	local ty = self.y + self.dy * dt 

	local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

	for i=1, len do 
		local col = cols[i]
		self:bounce(col.normal.x, col.normal.y, col.other.properties.bounciness)



		if col.other.properties.debris then
				col.other:die()
		end

		if col.other.properties.vase then
				col.other:die()
		end

	end

		self.x = rx 
		self.y = ry 

end

function Monster:update(dt)
	self.timer:update(dt)
	self:AI(dt)
	self:moveCollisions(dt)
end

function Monster:draw(debug)
	self.Gx, self.Gy = self:getCenter()
	love.graphics.draw(self.img, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)

end

return Monster