
--DEFAULT VARIABLE DONT CHANGE ANYTHING
local lw = love.window
local lf = love.filesystem
local ls = love.sound
local la = love.audio
local lp = love.physics
local lt = love.timer
local li = love.image
local lg = love.graphics
local lm = love.mouse
local lma = love.math
local lk = love.keyboard
local lev = love.event
local lg = love.graphics

require("..lib/math")
require("..lib/graphics")
require("..lib/button")
require("..lib/c_settings")
------------------------------------------

function draw_background()
	return true
end
function setup_settings()
	return nil
end

function on_apk_update(dt)
end

function load_visualizer(data)
    background = data.background
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    palettes = data.palettes
    
	local total = #palettes.color

	for i=1, total do
		local r,g,b = palettes.color[i].r / 255,palettes.color[i].g / 255,palettes.color[i].b / 255

        x = i % 40
        y = math.floor(i / 40)

        SetColor(r,g,b)
        Rect("fill",x*30,y * 30,20,20)
	end
end