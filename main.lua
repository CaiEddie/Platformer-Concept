love.graphics.setDefaultFilter("nearest", "nearest")

class = require 'lib.middleclass'
Stateful = require 'lib.stateful'


local Game = require 'game'
local game 

debug = true
local width = 384
local height =	216


function love.load()
	love.graphics.setDefaultFilter("nearest", "nearest")
	love.window.setMode(width, height, {resizable = true})
	game = Game:new(width, height)


end

function love.resize(w, h)
	game:resize(w, h)
end

function love.update(dt)
	game:update(dt)
end


function love.draw()
	game:draw(debug)
end

function love.keypressed(key)
	game:keypressed(key)
end

function love.keyreleased(key)
	game:keyreleased(key)
end