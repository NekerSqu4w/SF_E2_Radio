
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

canvas = {}
canvas[1] = lg.newCanvas(1920, 1080, {format="normal"})

function draw_background()
	return false
end
function setup_settings()
    reset()

    text("Pixel size:")
    sli = slider(1,10,1)
    text("Fading:")
    sli2 = slider(0,100,20)

	return return_obj_settings()
end

function on_apk_update(dt)
end

function load_visualizer(data)
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    better_waveform = data.waveform
    sound_data = data.sound_data

    sp_count = sound_data:getSampleCount() / 2
    spectro = {}

    lg.setCanvas(canvas[1])

    SetColor(0.5,0.5,0.5,sli2:getValue()/100)
    bs = bassfft/5000
	background_func(settings.background_type_active:lower())

    for i=1, sp_count do
        if not better_waveform[i] then
        else
            sa = (better_waveform[i].x or 0)
            sb = (better_waveform[i].y or 0)

            x = sa * 250
            y = sb * 250

            SetColor(1 - sa,0 + sb,0,1)
            Rect("fill",screenX / 2 - x - sli:getValue()/2,screenY / 2 + y - sli:getValue()/2,sli:getValue(),sli:getValue())
        end
    end

    lg.setCanvas()

	SetColor(1,1,1)
	lg.draw(canvas[1])
end