
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
local x,y = {},{}
my_shader = nil
function load_shader()
    local pixelcode = [[
        #define NUM_LIGHTS 155

        struct Light {
            vec2 position;
            vec3 diffuse;
            float distance;
            float power;
        };

        extern Light lights[NUM_LIGHTS];
        extern int num_lights;

        extern vec2 screen;

        const float constant = 1;
        const float linear = 0.09;
        const float quadratic = 0.032;
        
        vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
            vec4 pixel = Texel(image, uvs);

            vec2 norm_screen = screen_coords / screen;
            vec3 diffuse = vec3(0);

            for(int i=0; i < num_lights; i++) {
                Light light = lights[i];
                vec2 norm_pos = light.position / screen;

                float distance = length(norm_pos - norm_screen) * light.power;
                float attenuation = 1 / (constant + linear * distance + quadratic * (distance * distance));

                diffuse += light.diffuse * attenuation;
            }

            diffuse = clamp(diffuse, 0, 1);

            return pixel * vec4(diffuse, 1);
        }
    ]]

    local vertexcode = [[
        vec4 position( mat4 transform_projection, vec4 vertex_position )
        {
            return transform_projection * vertex_position;
        }
    ]]

    my_shader = lg.newShader(pixelcode, vertexcode)

    my_shader:send("screen", {
        ScrW(),
        ScrH()
    })

    my_shader:send("num_lights", 152)

    my_shader:send("lights[0].position", {0,0})
    my_shader:send("lights[0].diffuse", {1,1,1})
    my_shader:send("lights[0].power", 256)

    my_shader:send("lights[1].position", {150,150})
    my_shader:send("lights[1].diffuse", {1,0,0})
    my_shader:send("lights[1].power", 256)

    for i=1, 150 do
        my_shader:send("lights[" .. (1 + i) .. "].position", {-ScrW() / 2,-ScrH() / 2})
        my_shader:send("lights[" .. (1 + i) .. "].diffuse", {0,1,0})
        my_shader:send("lights[" .. (1 + i) .. "].power", 512)

        x[i] = 0
        y[i] = 0
    end
end

load_shader()

function draw_background()
	return false
end
function setup_settings()
    reset()

    text("Total orb:")
    sli = slider(10,150)

    return return_obj_settings()
end

function on_apk_update(dt)
    if my_shader then
        local r = 0.5 + lma.noise(lt.getTime()) * 0.5

        my_shader:send("lights[1].diffuse", {1 * r,0.3 * r,0})
        my_shader:send("lights[0].position", {lm.getX(),lm.getY()})

        for i=1, 150 do
            x[i] = x[i] + (-3 + lma.noise(i*500 + lt.getTime() / 2.3) * 6) * (0.5 + bassfft / 10)
            y[i] = y[i] + (-3 + lma.noise(i*500 + lt.getTime() / 3) * 6) * (0.5 + bassfft / 10)

            my_shader:send("lights[" .. (1 + i) .. "].diffuse", {0,0,0})
            if sli:getValue() >= i then
                my_shader:send("lights[" .. (1 + i) .. "].position", {ScrW() / 2 + x[i],ScrH() / 2 + y[i]})
                my_shader:send("lights[" .. (1 + i) .. "].diffuse", {1 * (0.1 + pulse * 0.9),0.4 * (0.1 + pulse * 0.9),0})
            end

            x[i] = lerp(0.05,x[i],0)
            y[i] = lerp(0.05,y[i],0)
        end
    end
end

function load_visualizer(data)
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    smooth_fft = data.smooth_fft
    data = data.sound_data
    left = data.left_channel
    right = data.right_channel

    sp_count = data:getSampleCount() / 2

    lg.setShader(my_shader) --Draw the shader
    --Draw your thing into the shader

	SetColor(0.5 + pulse, 0.5 + pulse, 0.5 + pulse)
	Rect("fill",0,0,screenX,screenY)

    lg.setShader() --Reset default shader
end