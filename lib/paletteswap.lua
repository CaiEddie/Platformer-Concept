local class = require 'lib.middleclass'


local PaletteSwap = class ("PaletteSwap")

local threshold = 0.15

function PaletteSwap:initialize()
    self.shader = love.graphics.newShader( -- load the shader
  [[
    //Fragment shader
    uniform sampler2D ColorTable; 
    uniform sampler2D MyIndexTexture;
    varying vec2 TexCoord0;

    vec4 effect( vec4 color, Image MyIndexTexture, vec2 TexCoord0, vec2 screen_coords ){
        //What color do we want to index?
        vec4 myindex = texture2D(MyIndexTexture, TexCoord0);
        //Do a dependency texture read
        vec4 texel = texture2D(ColorTable, myindex.xy);
        return texel;   //Output the color
    }
  ]] )

      self.greyShader = love.graphics.newShader( -- load the shader
  [[
    //Greyscale Shader
    uniform float threshold;

    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
        if (pixel.a > threshold){
          return vec4(0.0,0.0,0.0,1.0);
        } else {
          return vec4(0.0,0.0,0.0,0.0);
        }
    }
  ]] )

  local numberOfPalettes = 0
  local paletteData = love.image.newImageData( 'assets/palettes.png' )

  local coordinates = {}
      for x = 1, paletteData:getWidth() do
        local r, g, b, a = paletteData:getPixel(x - 1, 0)
        table.insert(coordinates, {x = r, y = g})
      end

  self.palettes = {}
      for y = 1, paletteData:getHeight() do
        numberOfPalettes = numberOfPalettes + 1
        local canvas = love.graphics.newCanvas(256, 256)
        local canvasData = canvas:newImageData()
        for x = 1, paletteData:getWidth() do
          local cx, cy = coordinates[x].x, coordinates[x].y
          local r, g, b, a = paletteData:getPixel(x - 1, y - 1)
          canvasData:setPixel(cx, cy, r, g, b, a)
        end
        local result = love.graphics.newImage(canvasData)
        result:setFilter( 'nearest' )
        table.insert(self.palettes, result)
    end

  local currentPalette = 1
  self.shader:send( "ColorTable", self.palettes[currentPalette] )
  self.greyShader:send( "threshold", threshold)
end

function PaletteSwap:set(shader)
  if shader == 'grey' then
    love.graphics.setShader(self.greyShader);
  else
    love.graphics.setShader(self.shader);
  end
end

function PaletteSwap:unset()
    love.graphics.setShader();
end

function PaletteSwap:setPalette(currentPalette)
    self.shader:send( "ColorTable", self.palettes[currentPalette])
end

return PaletteSwap

