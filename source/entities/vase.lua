local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Timer = require 'lib.timer'
local Debris = require 'source.entities.debris'
local DustParticles = require 'source.entities.dustparticles'
local Light = require 'source.entities.light'

local Vase = class ('Vase', Entity)
Vase.static.drawOrder = 2
local width = 6
local height = 14
local img = love.graphics.newImage('assets/sprites/vase/vase.png')

local respawnTime = 3
local jumpSpeed = -190

local debris1 = love.graphics.newImage('assets/sprites/vase/vasedebris1.png')
local debris2 = love.graphics.newImage('assets/sprites/vase/vasedebris2.png')
local debris3 = love.graphics.newImage('assets/sprites/vase/vasedebris3.png')

local eyesImg = love.graphics.newImage('assets/sprites/player/eyes.png')
local eyesOx = 4
local eyesOy = 2

local friction = 0.0001

function Vase:initialize(map, world, x, y)
	Entity.initialize(self, map, world, x, y, width, height)
	self.originalX = x 
	self.originalY = y
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
	self.timer = Timer()
	self.properties = {possessable = true, onGround = true, vase = true}
	self.timer:tween(0.5, self, {Sx = 1, Sy = 1, r = 0}, 'in-out-cubic')

	self.dustParticles = DustParticles:new(self.x, self.y)
	self.light = Light:new(self.map, self.x, self.y,'circle', 0.3, 0.3, "normal")
end

function Vase:filter(other)
	if (self.properties.possessed and other.properties.player) or self.properties.isDying or other.properties.isDying or  other.properties.passable or other.properties.player then 
		return false 
	elseif other.properties.jumpthru and self.y + self.h > other.y then 
		return false
	else 
		return "slide" 
	end
end

function Vase:checkOnGround(ny, other, dt)
  if ny < 0 then 
  	self.properties.onGround = true 
  	if other.actualdx then 
  		self.dx = other.actualdx
  	elseif not other.properties.bounciness then
  		self.dx = self.dx math.pow(friction, dt)
  	end
  else 
  	self.properties.onGround = false 
  end
end

function Vase:moveCollisions(dt)
		local world = self.world
	local tx = self.x + self.dx * dt
	local ty = self.y + self.dy * dt 

	local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

	for i=1, len do 
		local col = cols[i]
		
		self:bounce(col.normal.x, col.normal.y, col.other.properties.bounciness)
		
		if col.other.properties.bounciness and self.properties.possessed and self.map.player.leftKey then
			self.dx = jumpSpeed/3
			self.timer:after(0.1, function() self.properties.active = true end)
		end

		if col.other.properties.bounciness and self.properties.possessed and self.map.player.rightKey then
			self.dx = -jumpSpeed/3
			self.timer:after(0.1, function() self.properties.active = true end)
		end


		self:checkOnGround(col.normal.y, col.other, dt)

	end

	if len == 0 then 
		self.properties.onGround = false
	else 
		if self.properties.active == true then 
			self.map.player.dx = 0
			self.map.player.dy = jumpSpeed
			self.map.player.charge = 1
			self.map.player:gotoState(nil)
			self.properties.possessed = false
  		self:die()
  		return false
  	end
  end

		self.x = rx 
		self.y = ry 

end

function Vase:update(dt)
	self.timer:update(dt)
	self.dustParticles:update(dt)
	self.light.x = self.Gx 
	self.light.y = self.Gy
	if self.properties.isDying then return false end
	self:applyGravity(dt)
	self:moveCollisions(dt)
end

function Vase:draw(debug)

	self.dustParticles:draw()

	if self.properties.isDying then return false end

	self.Gx, self.Gy = self:getCenter()
	love.graphics.draw(self.img, self.Gx, self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)

	if self.properties.possessed then
		if self.map.player.leftKey then 
			self.eyesOx = eyesOx + 1
		elseif self.map.player.rightKey then
			self.eyesOx = eyesOx 
		end	
		love.graphics.draw(eyesImg, self.Gx, self.Gy, self.r, 1, 1, self.eyesOx, eyesOy)
	end

end

function Vase:die()
	if self.properties.isDying then return false end

	self.x = self.originalX 
	self.y = self.originalY 
	self.world:update(self, self.x, self.y)

	if self.properties.possessed then 
			self.map.player.dx = 0
			self.map.player.dy = jumpSpeed
			self.map.player.charge = 1
			self.map.player:gotoState(nil)
  end

  self.map:sleep(0.05)
	self.map.camera:screenShake(0.1, 2, 2)
	self.properties.isDying = true
	self.properties.possessed = false
	self.properties.passable = true
	self.light:die()

  self.dustParticles:emit(20, self.Gx, self.Gy)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris1, 200)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris1, 200)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris2, 200)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris3, 200)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris3, 200)
	Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris3, 200)

	self.timer:after(respawnTime, function() self:respawn() end )
end

function Vase:respawn()
	self.timer:after(0.2, function() 
		local items, len = self.world:queryRect(self.originalX-2, self.originalY, width+2, height)

			if len > 1 then 
				self:respawn()
			else
				local vase = Vase:new(self.map, self.world, self.originalX, self.originalY)
				self:destroy()
			end
		end
		)	
end

function Vase:possessedEntered(player)
	self.properties.possessed = true
	self.timer:tween(0.1, self, {r = 0.2, Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {r=-0.2, Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {r=0, Ox = self.Ox-1}, "in-out-cubic")   end)   end)
end

function Vase:possessedUpdate(player, dt)
	if self.properties.isDying then return false end
	player.x = self.x 
	player.y = self.y 
end

function Vase:possessedKeyPressed(player, key)
	if self.properties.onGround and key == "c" then 
		if player.leftKey then 
			self.dx = jumpSpeed/3
		end
		if player.rightKey then 
			self.dx = -jumpSpeed/3
		end
		self.dy = jumpSpeed
		self.timer:after(0.1, function() self.properties.active = true end)

		 self.dustParticles:emit(20, self.Gx, self.Gy +4)

	end

	if key == "x" then
		player:gotoState("Dash") 
		self.properties.possessed = false
		self:die()
	end

	self.timer:tween(0.1, self, {r = 0.2, Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {r=-0.2, Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {r=0, Ox = self.Ox-1}, "in-out-cubic")   end)   end)

end


return Vase