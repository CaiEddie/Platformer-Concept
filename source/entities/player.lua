local class = require 'lib.middleclass'
local Entity = require 'source.entities.entity'
local Stateful = require 'lib.stateful'
local Timer = require 'lib.timer'
local Light = require 'source.entities.light'
local Dust = require 'source.entities.dust'
local DustParticles = require 'source.entities.dustparticles'

local Player = class('Player', Entity)
Player:include(Stateful)

local width = 6
local height = 14

local hspeed = 75
local haccel = 500

local stateDelayTime = 0.1

local groundFriction = 0.00005
local airFriction = 0.01

local jumpSpeed = -150
local jumpEndSpeed = -20

local wallFriction = 0.3
local wallJumpSpeed = -80
local wallJumpMoveDelay = 0.25

local dashSpeed = 300
local dashDistance = 32
local noDashTime = 0.2
local charge = 1


local imgPart1 = love.graphics.newImage('assets/sprites/player/player1.png')
local imgPart2 = love.graphics.newImage('assets/sprites/player/player2.png')
local imgPart3 = love.graphics.newImage('assets/sprites/player/player3.png')
local imgPart4 = love.graphics.newImage('assets/sprites/player/player4.png')
local imgPart1O = love.graphics.newImage('assets/sprites/player/player1outline.png')
local imgPart2O = love.graphics.newImage('assets/sprites/player/player2outline.png')
local imgPart3O = love.graphics.newImage('assets/sprites/player/player3outline.png')
local imgPart4O = love.graphics.newImage('assets/sprites/player/player4outline.png')
local partTween = 0.4

function Player:initialize(map, world, x,y)
	Entity.initialize(self, map, world, x, y, width, height)
	self.map = map
	self.friction = airFriction
	self.charge = charge
	self.stateDelay = stateDelayTime
	self.Gx, self.Gy = self:getCenter()
	self.Ox = self.Gx - self.x +1
	self.Oy = self.Gy - self.y +1
	self.Sx = 1
	self.Sy = 1
	self.r = 0
	self.properties = { player = true, isDying = false, movable = true}
	self.timer = Timer()
	self.possessedEntity = nil
	self.possess = false
	self.dashResult = "cross"
	self.jumping = false

	self.part2x = x 
	self.part2y = y 
	self.part3x = x 
	self.part3y = y 
	self.part4x = x 
	self.part4y = y 
	
	self.drawOrder = 0

	self.light = Light:new(self.map, self.x, self.y, 'circle', 0.8, 0.8, "normal")
	self.dustParticles = DustParticles:new(self.x, self.y)

	self.dashDistance = dashDistance

	self.timer:tween(0.5, self, {Sx = 1, Sy = 1, r = 0}, 'in-out-cubic', 'sprite')
end

function Player:input()

	self.leftKey = love.keyboard.isDown('left') 
	self.rightKey = love.keyboard.isDown('right')
	self.upKey = love.keyboard.isDown('up')
	self.downKey = love.keyboard.isDown('down')
	self.jumpKey = love.keyboard.isDown('c')
	self.grabKey = love.keyboard.isDown('z')
	self.dashKey = love.keyboard.isDown('x')

end

function Player:applyMovement(dt)
	if self.properties.isDying then return false end
	
	if self.properties.movable then 
		local dx, dy = self.dx, self.dy

			if self.leftKey then
				if dx > -hspeed  then 
					dx = dx - haccel * dt
				end
				self.Sx = -1 
			end
			if self.rightKey then
				if dx < hspeed  then
					dx = dx + haccel * dt
				end
				self.Sx = 1
			end
		self.dx, self.dy = dx, dy

		if not (self.leftKey or self.rightKey) then
			self.dx = self.dx * math.pow(self.friction, dt)
		end
	end

end

function Player:keypressed(key)
	if self.properties.isDying then return false end
	if key == 'c' then 
		self:jump()
	end

	if key == 'x' and self.charge == 1 then
		self:gotoState('Dash')
		self.charge = self.charge - 1
	end
end

function Player:jump()
end

function Player:keyreleased(key)

	if key == 'c' and self.dy < jumpEndSpeed and self.jumping == true then 
		self.dy = jumpEndSpeed 
	end
end

function Player:filter(other)
	if self.properties.isDying or other.properties.isDying or (other.properties.possessable and not other.properties.shelf) then
	 	return false
	elseif other.properties.passable or other.properties.playerpassable  then 
		return 'cross'
	elseif (other.properties.jumpthru or other.properties.shelf) and self.y + self.h > other.y then 
		return false
	else
		return 'slide'
	end 
end

function Player:checkOnGround(ny, other, dt)
  if ny < 0  then 
  	self:gotoState("OnGround") 
  	self.ground = other
  end
end

function Player:checkOnWall(nx)
	if nx < 0 then 
		self.wallSide = "right" 
		self:gotoState("OnWall")
	elseif nx > 0 then 
		self.wallSide = "left"
		self:gotoState("OnWall")
	end
end

function Player:moveCollision(dt)

	if self.properties.isDying then 
		self.x = self.x + self.dx*dt 
		self.y = self.y + self.dy*dt
		return false 
	end
	
	local world = self.world
	local tx = self.x + self.dx * dt
	local ty = self.y + self.dy * dt 

	local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

	for i=1, len do 
		local col = cols[i]
		if not col.other.properties.passable then 
			self:bounce(col.normal.x, col.normal.y, col.other.properties.bounciness)
		
			self:checkOnGround(col.normal.y, col.other, dt) 
			self:checkOnWall(col.normal.x)
			

		end
		if col.other.properties.damaging then 
			self:die()
		end

		if col.other.onTouch then 
			col.other:onTouch()
		end

	end


	if len == 0 then 
		self.stateDelay = self.stateDelay -dt
		if self.stateDelay < 0 then 
			self:gotoState(nil)
			self.ground = nil
		end
	else
		self.stateDelay = stateDelayTime
	end

	self.x, self.y = rx, ry
end

function Player:updateLight(dt)
	self.light.x = self.Gx 
	self.light.y = self.Gy
end

function Player:updateDustParticles(dt)
	self.dustParticles:update(dt)
end

function Player:update(dt)
	self.timer:update(dt)
	self:input(dt)
	self:updateLight(dt)
	self:updateDustParticles(dt)
	self:applyGravity(dt)
	self:applyMovement(dt)
	self:moveCollision(dt)
	self:updateParts(dt)
end

function Player:updateParts(dt)
	self.Gx, self.Gy = self:getCenter() 
	self.Gy = self.Gy + math.sin(4*love.timer.getTime())
	self.part2x = self.part2x + (self.Gx - self.part2x) * partTween 
	self.part2y = self.part2y + (self.Gy - self.part2y) * partTween 
	self.part3x = self.part3x + (self.part2x - self.part3x) * partTween 
	self.part3y = self.part3y + (self.part2y - self.part3y) * partTween 
	self.part4x = self.part4x + (self.part3x - self.part4x) * partTween 
	self.part4y = self.part4y + (self.part3y - self.part4y) * partTween 
end

function Player:draw()

	self.dustParticles:draw()

	love.graphics.draw(imgPart4O, self.part4x , self.part4y , self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart3O, self.part3x , self.part3y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart2O, self.part2x , self.part2y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart1O, self.Gx , self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart4, self.part4x , self.part4y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart3, self.part3x , self.part3y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart2, self.part2x , self.part2y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart1, self.Gx , self.Gy, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
end

function Player:die()	
	if self.properties.isDying then return true end
	self.properties.isDying = true
	self.map.camera:screenShake(0.1, 2, 2)
	self.dx = 0
	self.dy = jumpEndSpeed*5
	self.dustParticles:emit(20, self.Gx, self.Gy)
	self.timer:tween(1, self, {Sx = 0, Sy = 0, r = 3}, 'in-out-cubic', function() self.map:reset() end )
end

local OnGround = Player:addState('OnGround')

function OnGround:enteredState()
	self.friction = groundFriction
	self.charge = 1
	Dust:new(self.map, self.world, self.Gx, self.Gy)
	self.timer:tween(0.1, self, {Sy = 0.6, Oy = self.Oy-4}, "in-out-cubic", function() self.timer:tween(0.1, self, {Sy = 1, Oy = self.Oy+4}, "in-out-cubic", function() end, 'sprite')  end, 'sprite')
	self.dustParticles:emit(20, self.Gx, self.Gy + self.w)
end

function OnGround:jump()

	self.y = self.y -3
	self.world:update(self, self.x, self.y)

	if self.dy < 0 then 
		self.dy = self.dy + jumpSpeed/2 
	else 
		self.dy = jumpSpeed
	end

	self.timer:tween(0.1, self, {Sy = 1.1}, "in-out-cubic", function() self.timer:tween(0.2, self, {Sy = 1}, "in-out-cubic", function() end, 'sprite')  end, 'sprite')

	self.jumping = true
	self.timer:after(0.3, function() self.jumping = false end)

	self:gotoState(nil)

	self.dustParticles:emit(10, self.Gx, self.Gy + self.w)

end

function OnGround:checkOnGround()
end

function OnGround:checkOnWall()
end

function OnGround:exitedState()
	self.friction = airFriction
end


local OnWall = Player:addState('OnWall')

function OnWall:enteredState()

end

function OnWall:applyGravity(dt)


	if self.leftKey or self.rightKey then
	  if self.dy < self.fallSpeed * wallFriction then 
	    self.dy = self.dy + self.gravity *dt
	  else 
	  	self.dy = self.fallSpeed * wallFriction 
	  end
	else
	  if self.dy < self.fallSpeed  then 
	    self.dy = self.dy + self.gravity *dt
	  else 
	  	self.dy = self.fallSpeed  
	  end
	end

  if self.wallSide == "left" then 
  	self.dx = self.dx - 1
  	self.dustParticles:emit(1, self.Gx -2, self.Gy)
  end
  if self.wallSide == "right" then
  	self.dx = self.dx + 1
  	self.dustParticles:emit(1, self.Gx +2, self.Gy)
  end
end

function OnWall:checkOnWall(nx)
	if nx < 0 then 
		self.wallSide = "right" 
	elseif nx > 0 then 
		self.wallSide = "left"
	end
end



function OnWall:jump()
	self.dy =  jumpSpeed
	if self.wallSide == "right" then 
			self.dx =  wallJumpSpeed
	elseif self.wallSide == "left" then
			self.dx =  -wallJumpSpeed
	end
			self:gotoState(nil)
			self.properties.movable = false 
			self.timer:after(wallJumpMoveDelay, function() self.properties.movable = true end)
end

function OnWall:exitedState() 
end

local Dash = Player:addState('Dash')
	
function Dash:enteredState()

	self.properties.passable = true
	self.map.camera:screenShake(0.1, 2, 0)

			local dx, dy = 0, 0
			self.dashTargetX = self.x 


			if not (self.leftKey and self.rightKey) then 
				if self.leftKey then
					dx = dx-dashSpeed
					self.dashTargetX = self.x - dashDistance
				end
				if self.rightKey then 
					dx = dx+dashSpeed
					self.dashTargetX = self.x + dashDistance
				end
			end

				self.dx = dx 
				self.dy = dy


		if not (self.leftKey or self.rightKey) or (self.leftKey and self.rightKey) then
			self.timer:after(noDashTime, function() if not self.possess then self:gotoState(nil) end  end)
		else 
			self:checkTarget()
		end
	self.dustParticles:emit(20, self.Gx, self.Gy)
end

function Dash:checkTarget()
	local items, len = self.world:queryRect(self.dashTargetX-1, self.y-1, self.w+2, self.h+1)

	self.dashResult = 'cross'

	for i=1, len do
		item = items[i]
		if not (item.properties.passable or item.properties.playerpassable or item.properties.isDying or item.properties.possessable) then 
			self.dashResult = 'slide'
		end  
	end
end

function Dash:applyMovement(dt)
	if self.dx > 0 and self.x > self.dashTargetX then 
		self.x = self.dashTargetX
		self:gotoState(nil)
	end

	if self.dx < 0 and self.x < self.dashTargetX then 
		self.x = self.dashTargetX
		self:gotoState(nil)
	end

	 self.dustParticles:emit(1, self.Gx, self.Gy)
end

function Dash:die()
	if self.properties.isDying then return true end
	self.properties.isDying = true
	self.dx = 0
	self.dy = 0
	self.timer:tween(1, self, {Sx = 0, Sy = 0, r = 3}, 'in-out-cubic', function() self.map:reset() end)
end

function Dash:filter(other)
	if other.properties.isDying  or other.properties.playerpassable then 
		return false 
	elseif other.properties.possessable or other.properties.shelf then
		return "cross"
	elseif other.properties.passable then 
		return false
	elseif other.properties.jumpthru and self.y + self.h > other.y then 
		return false
	else
		return self.dashResult
	end
end

function Dash:moveCollision(dt)
	local world = self.world
	local tx = self.x + self.dx * dt
	local ty = self.y + self.dy * dt

	local rx, ry, cols, len = world:move(self, tx, ty, self.filter)

	for i=1, len do 
		local col = cols[i]


		if col.other.onTouch then 
			col.other:onTouch()
		end

		if col.other.properties.possessable and not self.possess then 
			self.possessedEntity = col.other
			self:gotoState("Possess")
			self.possess = true
		elseif self.dashResult == "slide" then
			self:gotoState(nil)
		end
	end


	self.x, self.y = rx, ry

end

function Dash:applyGravity(dt)
end

function Dash:keypressed()
end

function Dash:exitedState()
		self.dx = 0
		self.dy = jumpEndSpeed
		self.world:update(self, self.x, self.y)
		self.properties.passable = false
end

local Possess = Player:addState("Possess")

function Possess:enteredState()
	self.possess = true
	self.possessedEntity:possessedEntered(self)
	self.drawOrder = 10
	self.ground = nil
	if self.light.Sx <0.5 then 
		self.light:destroy()
	else
		self.light:die()
	end
end

function Possess:update(dt)
	self.properties.passable = true
	self.timer:update(dt)
	self:input(dt)
	self:updateLight(dt)
	self:updateDustParticles(dt)
	self.possessedEntity:possessedUpdate(self, dt)
	self:updateParts(dt)
end

function Possess:keypressed(key)
	self.possessedEntity:possessedKeyPressed(self, key)
end

function Possess:draw()
	self.dustParticles:draw()

	love.graphics.draw(imgPart4O, self.part4x , self.part4y , self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart3O, self.part3x , self.part3y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart2O, self.part2x , self.part2y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart4, self.part4x , self.part4y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart3, self.part3x , self.part3y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
	love.graphics.draw(imgPart2, self.part2x , self.part2y, self.r, self.Sx, self.Sy, self.Ox, self.Oy)
end

function Possess:exitedState()
	self.world:update(self, self.x, self.y)
	self.possess = false
	self.timer:after(0.1, function() self.properties.passable = false end )
	self.drawOrder = 0
	self.light = Light:new(self.map, self.x, self.y, 'circle', 0.8, 0.8, "normal")
end

return Player