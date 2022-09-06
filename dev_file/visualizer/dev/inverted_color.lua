
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

require("..lib/math")
require("..lib/graphics")
require("..lib/button")
require("..lib/c_settings")
------------------------------------------

--OPEN GL SHADER
my_shader = nil
function load_shader()
    local pixelcode = [[
        extern float multiplier;

        vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
            vec4 pixel = Texel(image, uvs);

            pixel.r = pixel.r + ((1 - pixel.r) - pixel.r) * (multiplier/100);
            pixel.g = pixel.g + ((1 - pixel.r) - pixel.g) * (multiplier/100);
            pixel.b = pixel.b + ((1 - pixel.r) - pixel.b) * (multiplier/100);

            return pixel;
        }
    ]]

    local vertexcode = [[
        vec4 position( mat4 transform_projection, vec4 vertex_position )
        {
            return transform_projection * vertex_position;
        }
    ]]

    my_shader = lg.newShader(pixelcode, vertexcode)
end

load_shader()

function draw_background()
	return false
end
function setup_settings()
    reset()

    text("Multiplier:")
    sli = slider(0,100,50)

    return return_obj_settings()
end

function on_apk_update(dt)
    if my_shader and sli then
        my_shader:send("multiplier", sli:getValue())
    end
end

function load_visualizer(data)
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    smooth_fft = data.smooth_fft
    data = data.sound_data
    left = data.left_channel
    right = data.right_channel

    lg.setShader(my_shader) --Draw the shader
    --Draw your thing into the shader

    bs = bassfft/5000
    SetColor(0.5 + pulse, 0.5 + pulse, 0.5 + pulse)
    background_func(settings.background_type_active:lower())

    lg.setShader() --Reset default shader
end