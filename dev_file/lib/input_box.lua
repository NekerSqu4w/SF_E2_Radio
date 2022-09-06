--A custom input_box lib made by AstalNeker

local input_box = {}
input_box.__index = input_box

require(".lib/graphics")
require(".lib/math")
local lm = love.mouse
local lg = love.graphics
local lt = love.timer
local lk = love.keyboard
local ls = love.system
local utf8 = require("utf8")

local last_input = ""
local backspace_pressed = false
local input_changed = false

function inrange(x, y, w, h)
    local cx, cy = lm.getPosition()
    if not cx or not cy then return false end
        
    if cx > x and cx < x+w then
        if cy > y and cy < y+h then
            return true
        end
    end
end

function love.textinput(t)
    last_input = t
    input_changed = true
end

function input_key(key)
    if key == "backspace" then
        backspace_pressed = true
    end
end

function NewInputBox(x,y,w,h,txt,style,setter)
    local b = {}
    b.x = x or 0
	b.y = y or 0
	b.w = w or 130
	b.h = h or 30
    b.txt = txt or "Answer a respond.."
    b.default_text = b.txt
    b.current_answer = ""

    b.txt_color = style.txt_color or {r=0.5,g=0.5,b=0.5,a=1}
    b.txt_color_on = style.txt_color_on or {r=1,g=1,b=1,a=1}

    b.box_color = style.box_color or  {r=0,g=0,b=0,a=0.2}
    b.line_color = style.line_color or {r=1,g=1,b=1,a=1}
    b.box_color_on = style.box_color_on or {r=0,g=0,b=0,a=0.2}
    b.line_color_on = style.line_color_on or {r=1,g=0.5,b=0.2,a=1}

    b.hover_smooth = 0
    b.hover = false
    b.grab = false

    b.custom_data = style
    b.setter = setter or nil

    b.font = style.font or ".font/arial.ttf"
    b.font_size = style.font_size or 15

    setup_changed("input_box_hover",false)

    return setmetatable(b, input_box)
end

function input_box:draw()
    if self.setter then
        self.setter(self.x,self.y,self.w,self.h,self,self.hover)
    else
        if self.hover then SetColor(self.box_color_on.r, self.box_color_on.g, self.box_color_on.b, self.box_color_on.a) self.on = true else SetColor(self.box_color.r, self.box_color.g, self.box_color.b, self.box_color.a) self.on = false end
        Rect("fill",self.x,self.y,self.w,self.h)

        SetColor(self.line_color.r, self.line_color.g, self.line_color.b, self.line_color.a)
        Rect("fill", self.x, self.y + self.h, self.w, 2)

        SetColor(self.line_color_on.r, self.line_color_on.g, self.line_color_on.b, self.line_color_on.a)
        Rect("fill", self.x + self.w/2 - (self.w/2) * self.hover_smooth, self.y + self.h, self.w * self.hover_smooth, 2)

        if #self.current_answer > 0 then
            self.txt = self.current_answer
            SetColor(self.txt_color_on.r, self.txt_color_on.g, self.txt_color_on.b, self.txt_color_on.a)
        else
            self.txt = self.default_text
            SetColor(self.txt_color.r, self.txt_color.g, self.txt_color.b, self.txt_color.a)
        end


        self._, self.wrap_text = GetFont(self.font,self.font_size):getWrap(self.txt, self.w - 30)
	    if #self.wrap_text > 1 then self.wrap_text[1] = self.wrap_text[1] .. ".." end

        if #self.current_answer > 0 then
        else
            self._ = 0
        end


        self.text_data = Text(self.wrap_text[1],self.x + 10,self.y + self.h/2,0,1,self.font,self.font_size)

        if self.grab then
            SetColor(1, 1, 1, 1 - round(lt.getTime() % 1))
            Rect("fill", self.x + self._ + 12, self.y + (self.h/2)/2, 2, self.h / 2)
        end
    end
end

function input_box:update()
    if inrange(self.x,self.y,self.w,self.h) then
        self.hover_smooth = lerp(0.3,self.hover_smooth,1)
        self.hover = true

        if lm.isDown(1) then
            self.grab = true
        end

        self.cursor = "hand"
        lm.setCursor(lm.getSystemCursor("hand"))
    else
        if self.grab then
            self.hover_smooth = lerp(0.3,self.hover_smooth,1)
        else
            self.hover_smooth = lerp(0.3,self.hover_smooth,0)
        end
        self.hover = false

        if lm.isDown(1) then
            self.grab = false
        end

        if self.cursor == "hand" then
            self.reset_cursor = true
        end
    end

    if self.reset_cursor then
        lm.setCursor()
        self.cursor = nil
        self.reset_cursor = false
    end

    if self.grab then
        if input_changed then
            --if lk.isDown("lctrl", "rctrl") and last_input == "v" then
            --     self.current_answer = self.current_answer .. ls.getClipboardText()
            --else
            --    self.current_answer = self.current_answer .. last_input
            --end

            self.current_answer = self.current_answer .. last_input
            input_changed = false
        end

        if backspace_pressed then
            local byteoffset = utf8.offset(self.current_answer, -1)
            if byteoffset then
                self.current_answer = string.sub(self.current_answer, 1, byteoffset - 1)
            end
            backspace_pressed = false
        end
    end
end

function input_box:isValidated()
    if self.grab and lk.isDown("return") and #self.current_answer > 0 then
        self.validated = true
    else
        self.validated = false
    end
    return self.validated
end

function input_box:getInput()
    return self.current_answer
end

function input_box:resetInput()
    self.current_answer = ""
end

function input_box:delete()
    if self then
        self = nil
    end
end