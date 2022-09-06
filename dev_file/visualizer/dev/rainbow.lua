
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


local lang = {}

lang.en = {}
lang.en.s_color = "Use a single color instead of a gradient ?"

lang.fr = {}
lang.fr.s_color = "Utiliser une seule couleur au lieu d'un dégradé ?"

lang.ge = {}
lang.ge.s_color = "Verwenden Sie eine einzelne Farbe anstelle eines Farbverlaufs?"

function draw_background()
	return true
end
function setup_settings()
    reset()

    text("Total bar:")
    sli = slider(20,512,256)
    text("Bar height min:")
    sli2 = slider(0,50,30)
    text("Bar height max:")
    sli3 = slider(256,2048,2048)
    text("HSV value start:")
    sli4 = slider(0,360)
    but = button("")

    text("")
    obj_text = text("")

	return return_obj_settings()
end

function on_apk_update(dt)
    if but:isReleased() then
        is_active = not is_active
        but:set_active(is_active)
    end
end

function load_visualizer(data)
    smooth_fft = data.smooth_fft
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    palettes = data.palettes

    but.txt = lang[settings.lang_selected].s_color
    obj_text.txt = "An updated text example: " .. round(lt.getDelta(),4)

    for i=1, sli:getValue() do
        if is_active then
            color = hsvToRGB(sli4:getValue(),1,1)
        else
            color = hsvToRGB(sli4:getValue() + (i/sli:getValue()) * 360,1,1)
        end

        SetColor(color)
        Rect("fill",-(1/sli:getValue()) * screenX + (i/sli:getValue()) * screenX, screenY - 100 - sli2:getValue() - smooth_fft[i] * sli3:getValue(),(1/sli:getValue()) * screenX,sli2:getValue() + smooth_fft[i] * sli3:getValue())
    end
end