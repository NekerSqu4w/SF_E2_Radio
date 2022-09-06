local slider = {}
slider.__index = slider

local lm = love.mouse

require(".lib/graphics")
require(".lib/math")

function inrange(x, y, w, h)
    local cx, cy = lm.getPosition()
    if not cx or not cy then return false end
        
    if cx > x and cx < x+w then
        if cy > y and cy < y+h then
            return true
        end
    end
end

function newSlider(x, y, length, value, min, max, setter, style)
    local s = {}
    s.value = (value - min) / (max - min)
    s.min = min
    s.max = max
    s.setter = setter
    s.x = x
    s.y = y
    s.length = length

    local p = style or {}
    s.width = p.width or length * 0.1
    s.orientation = p.orientation or 'horizontal'
    s.track = p.track or 'rectangle'
    s.knob = p.knob or 'rectangle'
    s.bar_color = p.bar_color or {1,1,1,1}
    s.row_divider = clamp(p.row_divider or -1,-1,length)

    s.grabbed = false
    s.wasDown = true
    s.ox = 0
    s.oy = 0

    return setmetatable(s, slider)
end

function slider:update(mouseX, mouseY, mouseDown)
    local x = mouseX or love.mouse.getX()
    local y = mouseY or love.mouse.getY()
    local down = love.mouse.isDown(1)
    if mouseDown ~= nil then
        down = mouseDown
    end

    local knobX = self.x
    local knobY = self.y
    if self.orientation == 'horizontal' then
        knobX = self.x - self.length/2 + self.length * self.value
    elseif self.orientation == 'vertical' then
        knobY = self.y + self.length/2 - self.length * self.value
    end

    local ox = x - knobX
    local oy = y - knobY

    local dx = ox - self.ox
    local dy = oy - self.oy


    if inrange(knobX - self.width/2,knobY - self.width/2,self.width,self.width) or self.grabbed then
        if self.orientation == 'horizontal' then
            self.cursor = "sizewe"
            lm.setCursor(lm.getSystemCursor("sizewe"))
        elseif self.orientation == 'vertical' then
            self.cursor = "sizens"
            lm.setCursor(lm.getSystemCursor("sizens"))
        end
    else
        if self.cursor == "sizewe" then
            self.reset_cursor = true
        end
        if self.cursor == "sizens" then
            self.reset_cursor = true
        end
    end
    if self.reset_cursor then
        lm.setCursor()
        self.cursor = nil
        self.reset_cursor = false
    end


    if down then
        if self.grabbed then
            if self.orientation == 'horizontal' then
                self.value = self.value + dx / self.length
            elseif self.orientation == 'vertical' then
                self.value = self.value - dy / self.length
            end
        elseif (x > knobX - self.width/2 and x < knobX + self.width/2 and y > knobY - self.width/2 and y < knobY + self.width/2) and not self.wasDown then
            self.ox = ox
            self.oy = oy
            self.grabbed = true
        end
    else
        self.grabbed = false
    end

    self.value = math.max(0, math.min(1, self.value))
    if self.row_divider == -1 then else
        self.value = round(self.value * self.row_divider) / self.row_divider
    end

    if self.setter ~= nil then
        self.setter(self.min + self.value * (self.max - self.min))
    end

    self.wasDown = down
end

function slider:draw()
    if self.track == 'rectangle' then
        if self.orientation == 'horizontal' then
            love.graphics.rectangle('line', self.x - self.length/2 - self.width/2, self.y - self.width/2, self.length + self.width, self.width)
        elseif self.orientation == 'vertical' then
            love.graphics.rectangle('line', self.x - self.width/2, self.y - self.length/2 - self.width/2, self.width, self.length + self.width)
        end
    elseif self.track == 'line' then
        if self.orientation == 'horizontal' then
            SetColor(Color(1,1,1,0.3))
            love.graphics.line(self.x - self.length/2, self.y, self.x + self.length/2, self.y)

            SetColor(self.bar_color)
            love.graphics.line(self.x - self.length/2, self.y, self.x - self.length/2 + self.value * self.length, self.y)
        elseif self.orientation == 'vertical' then
            SetColor(Color(1,1,1,0.3))
            love.graphics.line(self.x, self.y - self.length/2, self.x, self.y + self.length/2)

            SetColor(self.bar_color)
            love.graphics.line(self.x, self.y + self.length/2, self.x, self.y + self.length/2 - self.value * self.length)
        end
    elseif self.track == 'roundrect' then 
        if self.orientation == 'horizontal' then
            SetColor(Color(1,1,1,0.3))
            Rect("fill", self.x - self.length/2 - self.width/2, self.y - (self.width/2)/4, self.length + self.width, self.width/4)

            SetColor(self.bar_color)
            Rect("fill", self.x - self.length/2 - self.width/2, self.y - (self.width/2)/4, self.value * self.length + self.width, self.width/4)
        elseif self.orientation == 'vertical' then
            SetColor(Color(1,1,1,0.3))
            Rect("fill", self.x - self.width/2, self.y - self.length/2 - self.width/2, self.width, self.length + self.width)

            SetColor(self.bar_color)
            Rect("fill", self.x - self.width/2, self.y - self.length/2 - self.width/2, self.width, self.value * self.length + self.width)
        end
    end

    local knobX = self.x
    local knobY = self.y
    if self.orientation == 'horizontal' then
        knobX = self.x - self.length/2 + self.length * self.value
    elseif self.orientation == 'vertical' then
        knobY = self.y + self.length/2 - self.length * self.value
    end

    if self.knob == 'rectangle' then
        love.graphics.rectangle('fill', knobX - self.width/2, knobY - self.width/2, self.width, self.width)
    elseif self.knob == 'circle' then
        love.graphics.circle('fill', knobX, knobY, self.width/2)
    end
end

function slider:getValue()
    return self.min + self.value * (self.max - self.min)
end

function slider:setMax(mx)
    self.max = mx
end

function slider:setValue(val)
    self.value = val
end


function slider:delete()
    if self then
        self = nil
    end
end