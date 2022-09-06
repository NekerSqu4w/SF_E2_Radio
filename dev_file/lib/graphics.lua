--A custom graphics lib made by AstalNeker

local lg = love.graphics
local lt = love.timer

local loaded_font = {}
function SetFont(font,size)
	local font = font or ".font/arial.ttf"
	local size = size or 15

	if loaded_font[font] and loaded_font[font][size] then
		lg.setFont(loaded_font[font][size].font)
	else

		if loaded_font[font] then
			print_info("Font","Adding new size: " .. size .. "\n          From Font: " .. font)
		else
			loaded_font[font] = {}
			print_info("Font","Creating new Font.. using a size of " .. size .. "\n          From Font: " .. font)
		end
		if loaded_font[font][size] then else loaded_font[font][size] = {} end

		loaded_font[font][size].size = size
		loaded_font[font][size].font = lg.newFont(font,size,"normal")
	end

	return loaded_font[font][size].font
end

function GetFont(font,size)
	local font = font or ".font/arial.ttf"
	local size = size or 15
	
	if loaded_font[font] and loaded_font[font][size] then
		return loaded_font[font][size].font
	else
		return SetFont(font,size)
	end
end

function SetColor(r,g,b,a)
	if type(r) == "table" then lg.setColor(r.r or 1,r.g or 1,r.b or 1,r.a or 1)
	elseif type(r) == "number" then lg.setColor(r or 1,g or 1,b or 1,a or 1) end
end
function ScrW() return lg.getWidth() end
function ScrH() return lg.getHeight() end

function Rect(fill,x,y,w,h)
	local fill = fill or "fill"
	local x = x or 0
	local y = y or 0
	local w = w or 50
	local h = h or 50

	lg.rectangle(fill,x,y,w,h)

	return {
		x = x,
		y = y,
		fill = fill,
		w = w,
		h = h
	}
end

function Rect2(fill,border_rad,x,y,w,h)
	local fill = fill or "fill"
	local x = x or 0
	local y = y or 0
	local w = w or 50
	local h = h or 50
	local border_rad = border_rad or 15

	lg.polygon(fill, {(x+border_rad),(y+0),(x+w),(y+0),(x+w-border_rad),(y+h),(x+0),(y+h)})

	return {
		fill = fill,
		border = border_rad,
		x = x,
		y = y,
		w = w,
		h = h
	}
end

function RotRect(fill,x,y,w,h,angle)
	local fill = fill or "fill"
	local x = x or 0
	local y = y or 0
	local w = w or 50
	local h = h or 50
	local angle = angle or 0

	lg.push()
	lg.translate(x, y)
	lg.rotate(angle)
	Rect(fill,0,0,w,h)
	lg.pop()

	return {
		fill = fill,
		x = x,
		y = y,
		w = w,
		h = h,
		angle = angle
	}
end

function Arc(fill,x,y,radius,angle1,angle2,segments)
	local fill = fill or "fill"
	local x = x or 0
	local y = y or 0
	local radius = radius or 50
	local angle1 = angle1 or 0
	local angle2 = angle2 or 360
	local segments = segments or nil

	lg.arc(fill, x, y, radius, (angle1/360)*(math.pi*2), (angle2/360)*(math.pi*2), segments)

	return {
		fill = fill,
		x = x,
		y = y,
		radius = radius,
		angle1 = angle1,
		angle2 = angle2,
		segments = segments
	}
end

function RoundRect(fill, x, y, w, h, radius, segments)
	local fill = fill or "fill"
	local x = x or 0
	local y = y or 0
	local w = w or 50
	local h = h or 50
	local radius = radius or h/2

	Rect(fill, x + radius, y + radius, w - (radius * 2), h - radius * 2)
	Rect(fill, x + radius, y, w - (radius * 2), radius)
	Rect(fill, x + radius, y + h - radius, w - (radius * 2), radius)
	Rect(fill, x, y + radius, radius, h - (radius * 2))
	Rect(fill, x + (w - radius), y + radius, radius, h - (radius * 2))
	
	Arc(fill, x + radius, y + radius, radius, -180, -90, segments)
	Arc(fill, x + w - radius , y + radius, radius, -90, 0, segments)
	Arc(fill, x + radius, y + h - radius, radius, -180, -270, segments)
	Arc(fill, x + w - radius , y + h - radius, radius, 0, 90, segments)

	return {
		fill = fill,
		x = x,
		y = y,
		w = w,
		h = h,
		radius = radius,
		segments = sements
	}
end

function Text(text,x,y,alignX,alignY,font_path,font_size)
	local text = text or ""
	local x = x or 0
	local y = y or 0

	local alignX = alignX or 0
	local alignY = alignY or 0

	local height = 0
	local width = 0

	local font = SetFont(font_path,font_size)

	if font and text then
		--text = text:gsub(0,"")

		if alignY == 0 then height = 0 end
		if alignY == 1 then height = font:getHeight()/2 end
		if alignY == 2 then height = font:getHeight() end

		if alignX == 0 then width = 0 end
		if alignX == 1 then width = font:getWidth(text)/2 end
		if alignX == 2 then width = font:getWidth(text) end

		lg.print(text,x - width,y - height)
	end

	return {
		text = text,
		x = x,
		y = y,
		alignX = alignX,
		alignY = alignY,
		w = width,
		h = height,
		font = font
	}
end

function Image(x,y,w,h,angle,texture)
	lg.push()
	lg.translate(x + w/2, y + h/2)
	lg.rotate((angle/360)*(math.pi*2))

	local quad = lg.newQuad(0, 0, w, h, w, h)
	lg.draw(texture, quad, -w/2, -h/2, 0)

	lg.pop()

	return {
		x = x,
		y = y,
		w = w,
		h = h,
		angle = angle,
		texture = texture,
		quad = quad
	}
end

--WORK IN PROGRESS
local pixelcode = [[
    vec4 effect(vec4 color, Image image, vec2 uvs, vec2 screen_coords) {
        vec4 pixel = Texel(image, uvs);

        return pixel;
    }
]]
local vertexcode = [[
    vec4 position( mat4 transform_projection, vec4 vertex_position )
    {
        return transform_projection * vertex_position;
    }
]]

local blur_shader = lg.newShader(pixelcode, vertexcode)

function blur(intensity)
	intensity = intensity or 5

	--blur_shader:send("intensity", intensity)
	lg.setShader(blur_shader)
end

function stop_effect()
	lg.setShader()
end


function Image_quad(x,y,w,h,quad,angle,texture)
	local quad2 = {}
	local quad = quad or {}
	quad2.start_x = quad.uv_x or 0
	quad2.start_y = quad.uv_y or 0
	quad2.end_x = quad.uv_end_x or 1
	quad2.end_y = quad.uv_end_y or 1

	quad2.start_x = clamp(quad2.start_x,0,1)
	quad2.start_y = clamp(quad2.start_y,0,1)
	quad2.end_x = clamp(quad2.end_x,0,1)
	quad2.end_y = clamp(quad2.end_y,0,1)

	lg.push()
	lg.translate(x + w/2, y + h/2)
	lg.rotate((angle/360)*(math.pi*2))

	local quad = lg.newQuad(
		quad2.start_x * w, quad2.start_y * h, 
		quad2.end_x * w, quad2.end_y * h,
		texture:getWidth(), texture:getHeight()
	)

	lg.draw(texture, quad, -w/2, -h/2, 0)

	lg.pop()

	return {
		x = x,
		y = y,
		w = w,
		h = h,
		angle = angle,
		texture = texture,
		quad = quad
	}
end
------------------------------------

-- ADVANCED GRAPHICS SYSTEM

local animated_sprite = {}
animated_sprite.__index = animated_sprite

function Sprite(x,y,w,h,angle,data)
	local b = {}
    b.x = x or 0
	b.y = y or 0
	b.w = w * data.grid.x or 130 * data.grid.x
	b.h = h * data.grid.y or 30 * data.grid.y
	b.skip = data.skip or {x=0,y=0}

	b.grid = {x=data.grid.x,y=data.grid.y}
    b.pic_size = {w=b.w/data.grid.x,h=b.h/data.grid.y}
	b.grid_pos = {x=1,y=1}

	b.angle = angle or 0
	b.last_frame = lt.getTime()
	b.last_frame2 = lt.getTime()
	b.frame = 0
	b.frametime = 0

	return setmetatable(b, animated_sprite)
end

function animated_sprite:draw(texture,framerate)
	if (lt.getTime() - self.last_frame) > framerate then
        self.grid_pos.x = self.grid_pos.x + 1
		self.frame = self.frame + 1

        if self.grid_pos.x >= self.grid.x - self.skip.x then self.grid_pos.x = 1 self.grid_pos.y = self.grid_pos.y + 1 end
        if self.grid_pos.y >= self.grid.y - self.skip.y then self.grid_pos.y = 1 end

        self.last_frame = lt.getTime()
    end

	if (lt.getTime() - self.last_frame2) > 1 then
		self.frametime = self.frame
		self.frame = 0
		self.last_frame2 = lt.getTime()
	end

    local quad = lg.newQuad((self.grid_pos.x-1) * self.pic_size.w, (self.grid_pos.y-1) * self.pic_size.h, self.pic_size.w,  self.pic_size.h, self.w, self.h)
	lg.draw(texture, quad, self.x, self.y, (self.angle/360)*(math.pi*2))
end

function animated_sprite:setSize(w,h)
	self.w = w * self.grid.x
	self.h = h * self.grid.y

	self.grid = {x=self.grid.x,y=self.grid.y}
    self.pic_size = {w=self.w/self.grid.x,h=self.h/self.grid.y}
end

function animated_sprite:setPos(x,y)
	self.x = x
	self.y = y
end