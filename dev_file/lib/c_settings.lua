
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
require("..lib/slider")
require("..lib/input_box")

function default_button_style(x,y,w,h,self,inrange)
	self.custom_data.text_align = self.custom_data.text_align or "center"

    r = self.box_color.r + self.hover_smooth * (self.box_color_on.r - self.box_color.r)*0.8 + boolToNum(self.active)*0.2
    g = self.box_color.g + self.hover_smooth * (self.box_color_on.g - self.box_color.g)*0.8 + boolToNum(self.active)*0.2
    b = self.box_color.b + self.hover_smooth * (self.box_color_on.b - self.box_color.b)*0.8 + boolToNum(self.active)*0.2
    a = self.box_color.a + self.hover_smooth * (self.box_color_on.a - self.box_color.a)*0.8 + boolToNum(self.active)*0.2
    SetColor(r,g,b,a)
    Rect("fill",x,y,w,h)

    self._, self.wrap_text = GetFont(self.font,self.font_size):getWrap(self.txt, w - 30)
	if #self.wrap_text > 1 then self.wrap_text[1] = self.wrap_text[1] .. ".." end

    if #self.txt > 0 then
    else
        self._ = 0
    end

    SetColor(1,1,1)

	if self.custom_data.text_align == "center" then
    	Text(self.txt,x + w/2,y + h/2,1,1,self.font)
	elseif self.custom_data.text_align == "left" then
		Text(self.txt,x + 5,y + h/2,0,1,self.font)
	elseif self.custom_data.text_align == "right" then
		Text(self.txt,x + w - 5,y + h/2,2,1,self.font)
	end
end

style = {
    font="font/Montserrat-Regular.ttf",
    font_size=13,
    box_color_on=theme_color.theme_accent,
    style="normal"
}
default_input_style = {
    font="font/Montserrat-Regular.ttf",
    font_size=13,
    line_color_on=theme_color.theme_accent,
    line_color={r=theme_color.theme_accent.r/2,g=theme_color.theme_accent.g/2,b=theme_color.theme_accent.b/2,a=1}
}
------------------------------------------

local obj = {}

function text(txt)
    txt = txt or "Default text"
    obj[#obj+1] = {}
    obj[#obj].type = "text"
    obj[#obj].txt = txt

    return obj[#obj]
end

function slider(min,max,default)
    min = min or 0
    max = max or 100
    default = default or min

    obj[#obj+1] = {}
    obj[#obj].type = "slider"
    obj[#obj].obj = newSlider(0, 0, 120, default, min, max, nil, {bar_color=theme_color.theme,width=15, orientation='horizontal', track='line', knob='circle'})

    return obj[#obj].obj
end

function button(txt)
    txt = txt or "Default button"
    obj[#obj+1] = {}
    obj[#obj].type = "button"
    obj[#obj].obj = NewButton(0,0,150,20,txt,false,style,default_button_style)

    return obj[#obj].obj
end

function input(txt)
    txt = txt or "Enter a value"
    obj[#obj+1] = {}
    obj[#obj].type = "input"
    obj[#obj].obj = NewInputBox(0,0,150,20,txt,default_input_style)

    return obj[#obj].obj
end


function return_obj_settings()
    local ret = obj or nil

    if ret then
        return ret
    end
end

function reset()
    if return_obj_settings() then
        for _, my_obj in pairs(return_obj_settings()) do
            if my_obj.type == "text" then
                my_obj = nil
            else
                my_obj.obj:delete()
            end
        end
    end
    obj = {}
end