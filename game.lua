


local Map = require 'source.map'


local Game = class('Game'):include(Stateful)

	local map

function Game:initialize(width, height)
	self.width = width
	self.height = height
	self.scale = 1
	map = Map:new(self, width, height)
end

function Game:log(...)
	print(...)
end

function Game:exit()
	self:log("Goodbye!")
	love.event.push('quit')
end

function Game:resize(w, h)
	map.camera:resize(w, h)
end

function Game:update(dt)
	map:update(dt)
end

function Game:draw(debug)
	map:draw(debug)
	if debug then 
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10) 
	end
end

function Game:keypressed(key)
	if key == 'escape' then 
		self:exit()
	end
	map:keypressed(key)
end

function Game:keyreleased(key)
	map:keyreleased(key)
end

return Game