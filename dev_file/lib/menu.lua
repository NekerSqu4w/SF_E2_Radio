--A custom menu lib made by AstalNeker

local menu = {}
menu.__index = menu

require(".lib/graphics")
require(".lib/math")
local lm = love.mouse
local lg = love.graphics

local menu_logo = lg.newImage("img/cd.png")

function inrange(x, y, w, h)
    local cx, cy = lm.getPosition()
    if not cx or not cy then return false end
        
    if cx > x and cx < x+w then
        if cy > y and cy < y+h then
            return true
        end
    end
end

function function_menu_box(fill,x,y,w,h)
	for i=1, 100 do
		local c = mix_2_color(theme_color.theme,theme_color.theme2,(i/100))
		SetColor(c)
		Rect("fill",-(1/100) * w + x + (i/100) * w - 2,y - 2,(1/100) * w + 4,h + 4)
	end

    if fill == true then
        SetColor(theme_color.gray.r/1.3,theme_color.gray.g/1.3,theme_color.gray.b/1.3)
        Rect("fill",x,y,w,h)
    end

	local box = {}

	box.x = x
	box.y = y
	box.w = w
	box.h = h

	box._x = x + 5
	box._y = y + 5
	box._w = w - 10
	box._h = h - 10

	return box
end

function NewMenu(title,x,y,w,h,default_open,resizable,show_close_button,min_w,min_h,max_w,max_h)
    local b = {}
    b.x = x or 0
	b.y = y or 0
	b.w = w or 130
	b.h = h or 30

    b.resizable = resizable
    b.show_close_button = show_close_button

    if b.resizable then
        b.min_w = min_w or 50
        b.min_h = min_h or 32
        b.max_w = max_w or 1600
        b.max_h = max_h or 900
    else
        b.min_w = w
        b.min_h = h
        b.max_w = w
        b.max_h = h
    end

    b.title = title or "Example menu"

    b.open = default_open or false
    b.exit_button = false
    b.title_bar_grabbed = false
    b.resizer_grabbed = false
    b.grab_pos = {}
    b.wasDown = false

    b.title_bar = {
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        _x = 0,
        _y = 0,
        _w = 0,
        _h = 0
    }

    b.menu = {
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        _x = 0,
        _y = 0,
        _w = 0,
        _h = 0
    }

    return setmetatable(b, menu)
end

function menu:draw()
    if self.open then
        self.menu = function_menu_box(true,self.x,self.y,self.w,self.h)
        self.title_bar = function_menu_box(false,self.x,self.y,self.w,30)

        --self._, self.wrap_text = GetFont("font/Montserrat-Regular.ttf",15):getWrap(self.title, self.w - 40 - self.title_bar._h)
        
        self._, self.wrap_text = GetFont("font/Montserrat-Regular.ttf",15):getWrap(self.title, self.w - 40)
	    if #self.wrap_text > 1 then self.wrap_text[1] = self.wrap_text[1] .. ".." end

        if #self.title > 0 then
        else
            self._ = 0
        end

        SetColor(1,1,1)
        Text(self.wrap_text[1],self.menu._x,self.menu._y,0,0,"font/Montserrat-Regular.ttf",15)

        --Text(self.wrap_text[1],self.menu._x + self.title_bar._h + 5,self.menu._y,0,0,"font/Montserrat-Regular.ttf",15)
        --Image(self.menu._x,self.menu._y,self.title_bar._h,self.title_bar._h,0,menu_logo)

        if self.show_close_button then
            SetColor(1,0.2,0.2)
            Rect("fill",self.title_bar._x + self.title_bar._w - self.title_bar._h,self.title_bar._y,self.title_bar._h,self.title_bar._h)

            SetColor(1,1,1)
            Text("X",self.title_bar._x + self.title_bar._w - self.title_bar._h + 10,self.title_bar._y + self.title_bar._h/2 - 1,1,1,"font/Montserrat-Regular.ttf",20)
        end

        if self.resizable then
            SetColor(0.2,0.2,0.2)
            --Rect("fill",self.menu.x + self.menu.w - 15,self.menu.y + self.menu.h - 15,15,15)
            lg.polygon("fill", {self.menu.x+self.menu.w,self.menu.y+self.menu.h-20,self.menu.x+self.menu.w,self.menu.y+self.menu.h,self.menu.x+self.menu.w-20,self.menu.y+self.menu.h})

            --SetColor(1,1,1)
            --lg.line(0,0,0,0)
        end
    end
end

--BETA TEST
function top_drawing()
    for key, obj in pairs(menu) do
        obj:draw()
    end
end

function menu:update()
    if self.open then
        self.exit_button = false

        if inrange(self.title_bar.x,self.title_bar.y,self.title_bar.w,self.title_bar.h) then
            self.title_bar_hover = true

            self.cursor = "hand"
            lm.setCursor(lm.getSystemCursor("hand"))
        else
            self.title_bar_hover = false

            if self.cursor == "hand" then
                self.reset_cursor = true
            end
        end

        if self.resizable then
            if inrange(self.menu.x + self.menu.w - 20,self.menu.y + self.menu.h - 20,20,20) then
                self.resizer_hover = true

                self.cursor = "sizeall"
                lm.setCursor(lm.getSystemCursor("sizeall"))
            else
                self.resizer_hover = false

                if self.cursor == "sizeall" then
                    self.reset_cursor = true
                end
            end
        end

        if lm.isDown(1) then
            if self.title_bar_grabbed then
            elseif self.title_bar_hover and not self.wasDown then
                if inrange(self.title_bar._x + self.title_bar._w - self.title_bar._h,self.title_bar._y,self.title_bar._h,self.title_bar._h) and self.show_close_button then
                    self.exit_button = true
                    self.open = false
                end

                local gx, gy = lm.getPosition()
                self.grab_pos.mouse = {x=gx,y=gy}
                self.grab_pos.menu = {x=self.x,y=self.y}
                
                self.title_bar_grabbed = true
            end

            if self.resizer_grabbed then
            elseif self.resizer_hover and not self.wasDown then                
                local gx, gy = lm.getPosition()
                self.grab_pos.mouse = {x=gx,y=gy}
                self.grab_pos.menu = {x=self.x,y=self.y}
                self.grab_pos.size = {w=self.w,h=self.h}
                    
                self.resizer_grabbed = true
            end
        else
            self.resizer_grabbed = false
            self.title_bar_grabbed = false
        end

        if self.title_bar_grabbed then
            local cx, cy = lm.getPosition()

            local to_pos = {}
            to_pos.x = (self.grab_pos.mouse.x - self.grab_pos.menu.x) - self.title_bar._w/2
            to_pos.y = (self.grab_pos.mouse.y - self.grab_pos.menu.y) - self.title_bar._h/2

            self.x = (cx - self.title_bar._w/2) - to_pos.x
            self.y = (cy - self.title_bar._h/2) - to_pos.y
        end

        if self.resizer_grabbed then
            local cx, cy = lm.getPosition()

            local to_size = {}
            to_size.w = self.grab_pos.size.w
            to_size.h = self.grab_pos.size.h

            self.w = (cx - self.grab_pos.mouse.x) + to_size.w
            self.h = (cy - self.grab_pos.mouse.y) + to_size.h

            self.w = clamp(self.w,self.min_w,self.max_w)
            self.h = clamp(self.h,self.min_h,self.max_h)
        end

        self.wasDown = lm.isDown(1)
    else
        self.resizer_grabbed = false
        self.title_bar_grabbed = false

        if self.cursor then
            self.reset_cursor = true
        end
    end

    if self.reset_cursor then
        lm.setCursor()
        self.cursor = nil
        self.reset_cursor = false
    end
end