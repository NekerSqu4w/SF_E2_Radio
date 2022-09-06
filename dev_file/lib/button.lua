--A custom button lib made by AstalNeker

local button = {}
button.__index = button

local num_button = 0

require(".lib/graphics")
require(".lib/math")
local lm = love.mouse
local lg = love.graphics

function inrange(x, y, w, h)
    local cx, cy = lm.getPosition()
    if not cx or not cy then return false end
        
    if cx > x and cx < x+w then
        if cy > y and cy < y+h then
            return true
        end
    end
end

function NewButton(x,y,w,h,txt,hover_only,style,setter)
    num_button = num_button + 1
    local b = {}
    b.x = x or 0
	b.y = y or 0
	b.w = w or 130
	b.h = h or 30
    b.txt = txt or "Example button"
    b.hover_only = hover_only or false

    b.font = style.font or ".font/arial.ttf"
    b.font_size = style.font_size or 15

    b.txt_color = style.txt_color or {r=1,g=1,b=1,a=1}
    b.box_color = style.box_color or  {r=0,g=0,b=0,a=0.2}
    b.line_color = style.line_color or {r=1,g=1,b=1,a=1}
    b.txt_color_on = style.txt_color_on or {r=1,g=1,b=1,a=1}
    b.box_color_on = style.box_color_on or {r=0,g=0,b=0,a=0.2}
    b.line_color_on = style.line_color_on or {r=1,g=0.5,b=0.2,a=1}
    b.style = style.style or "normal"
    b.rad = style.radius or 0
    b.segments = style.segments or nil

    b.custom_data = style
    b.setter = setter or nil

    b.active = false
    b.hover_smooth = 0
    b.hover = false

    b.released = false
    b.pressed = false
    b.can_grab = true

    b.id = num_button .. "_" .. b.txt:lower() .. "_" .. b.style -- Prototype

    setup_changed(b.id,false)

    return setmetatable(b, button)
end

function button:draw()
    if self.setter then
        self.setter(self.x,self.y,self.w,self.h,self,self.hover)
    else
        if self.hover then SetColor(self.box_color_on.r, self.box_color_on.g, self.box_color_on.b, self.box_color_on.a) self.on = true else SetColor(self.box_color.r, self.box_color.g, self.box_color.b, self.box_color.a) self.on = false end
        
        if self.style == "round" then
            RoundRect("fill",self.x,self.y,self.w,self.h,self.rad,self.segments)
        elseif self.style == "normal" then
            Rect("fill",self.x,self.y,self.w,self.h)
        elseif self.style == "tri" then
            Rect2("fill",self.rad,self.x,self.y,self.w,self.h)
        end

        if self.hover then SetColor(self.line_color_on.r, self.line_color_on.g, self.line_color_on.b, self.line_color_on.a) else SetColor(self.line_color.r, self.line_color.g, self.line_color.b, self.line_color.a) end

        if self.style == "round" then
            Rect("fill", self.x + self.rad, self.y + self.h, self.w - self.rad*2, 2)
        elseif self.style == "normal" then
            Rect("fill", self.x, self.y + self.h, self.w, 2)
        elseif self.style == "tri" then
            Rect("fill", self.x, self.y + self.h, self.w - self.rad, 2)
        end

        self._, self.wrap_text = GetFont(self.font,self.font_size):getWrap(self.txt, self.w - 30)
	    if #self.wrap_text > 0 then self.wrap_text[1] = self.wrap_text[1] .. ".." end

        if #self.txt > 0 then
        else
            self._ = 0
        end

        if self.hover then SetColor(self.txt_color_on.r, self.txt_color_on.g, self.txt_color_on.b, self.txt_color_on.a) else SetColor(self.txt_color.r, self.txt_color.g, self.txt_color.b, self.txt_color.a) end
        self.text_data = Text(self.wrap_text[1],self.x + self.w/2,self.y + self.h/2,1,1,self.font,self.font_size)
    end
end

function button:update()
    if inrange(self.x,self.y,self.w,self.h) then
        self.hover_smooth = lerp(0.3,self.hover_smooth,1)
        self.hover = true

        self.cursor = "hand"
        lm.setCursor(lm.getSystemCursor("hand"))
    else
        self.hover_smooth = lerp(0.3,self.hover_smooth,0)
        self.hover = false

        if self.cursor == "hand" then
            self.reset_cursor = true
        end
    end

    if self.reset_cursor then
        lm.setCursor()
        self.cursor = nil
        self.reset_cursor = false
    end

    if self.hover_only then
        if self.hover then
            self.active = true
        else
            self.active = false
        end
    else
        if not self.hover and lm.isDown(1) and self.can_grab then
            self.can_grab = false
            self.active = false
        else
            if self.hover and not lm.isDown(1) then
                self.can_grab = true
            end
        end

        if self.can_grab then
            if self.hover and lm.isDown(1) then
                self.active = true
            else
                self.active = false
            end
        end
    end
end

function button:getHover(type)
    type = type or "direct"
    if type == "smooth" then
        return self.hover_smooth
    elseif type == "direct" then
        return self.hover
    end
end

function button:isPressed()
    self.pressed = false
    if changed(self.id,self.active) and self.active then
        self.pressed = true
    end
    return self.pressed
end

function button:isReleased()
    self.released = false
    if changed(self.id,self.active) and self.active == false then
        self.released = true
    end
    return self.released
end

function button:data()
    return self
end

function button:setLabel(lbl) self.txt = lbl end
function button:setPos(x,y) self.x = x self.y = y end
function button:setSize(w,h) self.w = w self.h = h end
function button:setStyle(style) self.style = style end


function button:set_active(value)
    value = value or false
    if value then self.box_color = self.box_color_on
	else self.box_color = {r=0,g=0,b=0,a=0.2} end
end

function button:delete()
    if self then
        self = nil
    end
end