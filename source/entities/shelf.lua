local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Timer = require 'lib.timer'
local Debris = require 'source.entities.debris'
local DustParticles = require 'source.entities.dustparticles'
local Light = require 'source.entities.light'

local Shelf = class ('Shelf', Entity)
Shelf.static.drawOrder = 1
local width = 24
local height = 40
local img3 = love.graphics.newImage('assets/sprites/shelf/shelfright.png')
local img2 = love.graphics.newImage('assets/sprites/shelf/shelfleft.png')
local img 	 = love.graphics.newImage('assets/sprites/shelf/shelf.png')

local debris1 = love.graphics.newImage('assets/sprites/shelf/shelfdebris1.png')
local debris2 = love.graphics.newImage('assets/sprites/shelf/shelfdebris2.png')
local debris3 = love.graphics.newImage('assets/sprites/shelf/shelfdebris3.png')

local eyesImg = love.graphics.newImage('assets/sprites/player/eyes.png')
local eyesOx = 4
local eyesOy = 2

local haccel = 500
local hspeed = 40
local friction = 18

function Shelf:initialize(map, world, x, y)
	Entity.initialize(self, map, world, x, y, width, height)
	self.img = img 
	self.map = map
	self.world = world 
	self.dx = 0
	self.dy = 0
	self.Gx, self.Gy = self:getCenter()
	self.Ox = self.Gx - self.x +4
	self.Oy = self.Gy - self.y +11
	self.Sx = 0
	self.Sy = 0
	self.r = 0
	self.timer = Timer()
	self.friction = friction
	self.properties = {possessable = true, onGround = true, shelf = true}
	self.timer:tween(0.5, self, {Sx = 1, Sy = 1, r = 0}, 'in-out-cubic')


	self.dustParticles = DustParticles:new(self.x, self.y)
	self.light = Light:new(self.map, self.x, self.y, 'circle', 0.4, 0.4, "normal")
end

function Shelf:filter(other)
	if  other.properties.player or other.properties.isDying or other.properties.player then 
		return false 
	elseif other.properties.passable then
		return "cross"
	elseif other.properties.jumpthru then 
		return "slide"
	else
		return "slide" 
	end
end

function Shelf:checkOnGround(ny, other, dt)
  if ny < 0 then 
  	self.properties.onGround = true 
  	if other.actualdx and not self.properties.possessed then 
  		self.dx = other.actualdx
  	end
  	if self.dx ~= 0 then 
  		self.dustParticles:emit(10, self.Gx, self.Gy + self.w/2 + 6)
  	end
  else 
  	self.properties.onGround = false 
  end
end

function Shelf:moveCollisions(dt)
		local world = self.world
	local tx = self.x + self.dx * dt
	local ty = self.y + self.dy * dt 

	local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

	for i=1, len do 
		local col = cols[i]
		
		self:bounce(col.normal.x, col.normal.y, col.other.properties.bounciness)
		self:checkOnGround(col.normal.y, col.other, dt)

		if col.other.properties.debris then
			if col.normal.x ~= 0 then 
				col.other:die()
			end
		end

		if col.other.properties.vase then
			if col.normal.x ~= 0 then 
				col.other:die()
			end
		end

	end

	if len == 0 then 
		self.properties.onGround = false
  end

		self.actualdx = (rx - self.x) /dt
		self.actualdy = (ry - self.y) /dt

		self.x = rx 
		self.y = ry 

end

function Shelf:update(dt)

	self.timer:update(dt)
	self.dustParticles:update(dt)
	self.light.x = self.Gx 
	self.light.y = self.Gy
	self:applyGravity(dt)
	self:moveCollisions(dt)
end

function Shelf:draw(debug)

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

function Shelf:die()
	if self.properties.isDying then return false end

end

function Shelf:possessedEntered(player)
	self.properties.possessed = true
	player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic")   end)   end)
end

function Shelf:possessedUpdate(player, dt)
	if self.properties.isDying then return false end

			local dx, dy = self.dx, self.dy

			player.x = self.Gx 
			self.img = img

			if player.leftKey then
				if dx > -hspeed  then 
					dx = dx - haccel * dt
				end
				self.img = img2
			end

			if player.rightKey then
				if dx < hspeed  then
					dx = dx + haccel * dt
				end
				self.img = img3
			end

		self.dx, self.dy = dx, dy

		if not (player.leftKey or player.rightKey) then
			self.dx = 0
		end



	player.y = self.Gy -2
end


function Shelf:possessedKeyPressed(player, key)


	if key == "x" then



		player.dashTargetX = player.x

		if not (player.leftKey or player.rightKey) or (player.leftKey and player.rightKey)then 
			player.x = player.x -3
		elseif player.leftKey then
			player.x = player.x -16
			player.dashTargetX = player.x - player.dashDistance
		elseif player.rightKey then
			player.x = player.x +10
			player.dashTargetX = player.x + player.dashDistance
		end

		local items, len = self.world:queryRect(player.x-3, player.y-1, player.w+6, player.h+1)

		local noSpace = false

		for i=1, len do
			item = items[i]
			if not (item.properties.player or item.properties.passable or item.properties.isDying or item.properties.possessable) then 
				noSpace = true
			end  
		end


			local items, len = self.world:queryRect(player.dashTargetX-2, player.y-1, player.w+4, player.h+1)

			local dashResult = true

			for i=1, len do
				item = items[i]
				if not (item.properties.passable or item.properties.isDying or item.properties.possessable) then 
					dashResult = false
				end  
			end


		if noSpace == false or dashResult == true then 
			self.properties.possessed = false
			self.properties.possessable = false 
			self.properties.playerpassable = true
			self.timer:after(0.2, function() self.properties.possessable = true self.properties.playerpassable = false end )

			self.dx = 0 

			player:gotoState("Dash") 
		end



		self.map.camera:screenShake(0.1, 2, 0)
		Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris1, 200)
		Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris2, 200)
		Debris:new(self, self.map, self.world, self.Gx, self.Gy, debris3, 200)

	end

	player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox+2}, "in-out-cubic", function() player.timer:tween(0.1, self, {Ox = self.Ox-1}, "in-out-cubic")   end)   end)

end


return Shelf