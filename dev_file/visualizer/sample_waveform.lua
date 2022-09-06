
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
    reset()

    text("Detail:")
    sli = slider(64,2048,128)
    text("Radius:")
    sli2 = slider(64,256,128)

	return return_obj_settings()
end

function on_apk_update(dt)
end

function load_visualizer(data)
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    data = data.sound_data

    sp_count = data:getSampleCount() / 2
    spectro = {}

    for i=1, sli:getValue() do
        sa = data:getSample((i/sli:getValue())*sp_count, 1) 
        sb = data:getSample((i/sli:getValue())*sp_count, 2)

        r = sli2:getValue() + ((sa+sb)/2) * 50

        spectro[((i-1) * 2) - 1] = screenX / 2 + math.cos((i/sli:getValue()) * (math.pi*2)) * r
        spectro[((i-1) * 2)] = screenY / 2 + math.sin((i/sli:getValue()) * (math.pi*2)) * r
    end

    SetColor(1,1,1)
    lg.line(spectro)
end