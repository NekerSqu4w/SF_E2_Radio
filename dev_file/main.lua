
--"https://www.mediafire.com/file/w65ffykzewlefst/AstMP3.rar/file"

------------------ DEFAULT VARIABLE LIB ETC ----------------------------
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

require(".lib/math")
require(".lib/graphics")
require(".lib/button")
require(".lib/slider")
require(".lib/input_box")
require(".lib/menu")
local loveZip = require(".lib/zip")
local string2 = require(".lib/utf8")
local default_color_list = require(".lib/color_list")
---------------------------------------------------------


local playing = ""

local palettes = {}
palettes.current = 2


theme_color = {}
theme_color.registered_theme = {}

theme_color.registered_theme[1] = {
	theme = {r=217/255,g=237/255,b=146/255},
	theme2 = {r=24/255,g=78/255,b=119/255},
	use = "new"
}
theme_color.registered_theme[2] = {
	theme = {r=239/255,g=132/255,b=130/255},
	theme2 = {r=250/255,g=203/255,b=87/255},
	use = "new"
}

theme_color.use = theme_color.registered_theme[2].use
theme_color.theme = theme_color.registered_theme[2].theme
theme_color.theme2 = theme_color.registered_theme[2].theme2
theme_color.theme_accent = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,0.3)
theme_color.theme_accent2 = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,0.1)


theme_color.black = {r=0,g=0,b=0}
theme_color.white = {r=1,g=1,b=1}
theme_color.gray = {r=0.5,g=0.5,b=0.5}

theme_color.primary = {r=69/255,g=90/255,b=100/255}
theme_color.aqua = {r=121/255,g=134/255,b=203/255}

theme_color.interface = {r=theme_color.gray.r/1.3,g=theme_color.gray.g/1.3,b=theme_color.gray.b/1.3}

local realName = string.sub(playing, 1, #playing - 4)
local path = playing
local type = string.sub(playing, #playing - 2, #playing)

------------------ Variable ----------------------------
local audio_decode = {}
audio_decode.__index = audio_decode
local bassfftVALL = 0
local last_bass = 0
local fft, ff = {}, {}
local background = nil
local background_video = nil
local smooth_fft = {}

local visualizer_list = {}
local playlist = {}

local final_visualizer_list_tbl = {}
local final_playlist_tbl = {}

local playing_id = 1
local source_time = 0

local rcu_alpha = 1
local current_volume = 0
local current_volume2 = 0

local sample_waveform_data = {}
local sample_waveform_taking = {}
local sample_left_max = 0
local sample_right_max = 0


function find_song_data(f)
	local title = ""
	local author = ""
	local album_name = ""
	local album_cover = ""

	local use_default_title = true

	local song_data = nil
	if f then
		ok, err = f:open('r')

		if ok then
			f:seek(f:getSize()-128-227)
			data, _ = f:read(400)
			f:close()

			local pos1, pos2 = string.find(data,"TAG")
			pos1 = pos1 or -1
			pos2 = pos2 or -1
			if pos1>0 and pos2>0 and string.gmatch(data,"TAG") and (pos2-pos1) >= 2 then
				start = data:sub(pos2+1,pos2 + 400):gsub(string.char(0),"")
				title = start:sub(1,30)
				author = start:sub(31,60)
				album_name = start:sub(61,90)

				use_default_title = false
			end

			--[[ BUGED
			local pos1, pos2 = string.find(data,"TAG+")
			pos1 = pos1 or -1
			pos2 = pos2 or -1
			if pos1>0 and pos2>0 and string.gmatch(data,"TAG+") and (pos2-pos1) >= 3 then
				start = data:sub(pos2+1,pos2 + 400):gsub(string.char(0),"")
				title = start:sub(1,60)
				author = start:sub(61,120)
				album_name = start:sub(121,180)

				use_default_title = false
			end
			]]
		end
	end

	song_info = {
		to_default_title = use_default_title,
		title = title,
		author = author,
		album = {
			album_name = album_name,
			album_cover = album_cover
		}
	}

	return song_info
end
---------------------------------------------------------

------------------ Load/decode data ----------------------------
function audio_decode:new(name)
	self = setmetatable({}, self)
	self.file = name
	self.source  = la.newSource(self.file, 'stream')

	local bytespersample    = self.source:getChannelCount() * 2 -- 16-bit sound
	local max_fft_frequency = 2048 * 8
	
	self.freq_max = (max_fft_frequency * bytespersample)
	
	self.decoder = ls.newDecoder(self.file, self.freq_max)
	self.sample_waveform_data = self.decoder:clone()

	local meta = getmetatable(self.source)
	for k, v in pairs(meta.__index) do
		self[k] = function(self, ...) return self.source[k](self.source, ...) end
	end
	
	self.song_data = find_song_data(self.file)

	return self
end

function audio_decode:getBytes(dt)
	local l = self.source:tell()
	l = l - dt
	l = l < 0 and 0 or l
	self.decoder:seek(l)

	source_time = l

	return self.decoder:decode()
end

local o = nil
local duration = -1
local start = lt.getTime()

lg.setLineStyle('smooth') --lg.setLineStyle('rough')
lg.setLineJoin('none')
---------------------------------------------------------------

------------------ Custom function ----------------------------
local default_for_palet = {}
for _, v in pairs(default_color_list) do
	default_for_palet[#default_for_palet+1] = {}
	default_for_palet[#default_for_palet].color = Color(v[1],v[2],v[3])
	default_for_palet[#default_for_palet].name = _
end

palettes.tbl = require("interface/color_plt")

local bassfftVALL = 0
function getbass(fft,min,range)
	--[[
	for h=1, range do
        for j=1, range do
            if ((fft[1+h].i or 0)^2 + (fft[1+h].r or 0)^2) > ((fft[1+j].i or 0)^2 + (fft[1+j].r or 0)^2) then
                bassfftVALL = lerp(0.003,bassfftVALL,((fft[1+h].i or 0)^2 + (fft[1+h].r or 0)^2)/100)
            elseif ((fft[1+h].i or 0)^2 + (fft[1+h].r or 0)^2) < ((fft[1+j].i or 0)^2 + (fft[1+j].r or 0)^2) then
                bassfftVALL = lerp(0.003,bassfftVALL,((fft[1+j].i or 0)^2 + (fft[1+j].r or 0)^2)/100)
            end
        end
    end
	]]

	bassfftVALL = 0
	for i=min, range do
		bassfftVALL = bassfftVALL + (fft[i].i^2 + fft[i].r^2)/30
	end

    return bassfftVALL / range
end

function inrange(x, y, w, h)
    local cx, cy = lm.getPosition()
    if not cx or not cy then return false end
    
    if cx > x and cx < x+w then
        if cy > y and cy < y+h then
            return true
        end
    end
end

function pic_palettes(img_data)
	local width, height = img_data:getDimensions()
	local j = 1
	local real = {}
	local a = 0

	local size = 1600 / 2
	local categorised_color = {}

	--Color to get a palettes of color
	search_grid = {}
	search_grid.x = size
	search_grid.y = size

	local sorting = {}
	local dominant = Color()
	for i=1, search_grid.x do
		x = width/2 + math.cos((i/search_grid.x) * (math.pi*2) * 141) * (width/2 - 1)
		y = height - (i/search_grid.x) * height

		r, g, b, a = img_data:getPixel(x, y)

		sorting[round((i/search_grid.x) * 10)] = Color(r*255,g*255,b*255)
	end

	local fr, fg, fb = 0, 0, 0
	for x=1, #sorting do
		_1 = sorting[x]
		fr, fg, fb = fr+_1.r, fg+_1.g, fb+_1.b
	end

	dominant = Color(fr / #sorting,fg / #sorting,fb / #sorting)

	palettes.tbl[1].color = sorting
	palettes.tbl[1].dominant = dominant

	local all_plt_color = '\n           Dominant: {r:'..dominant.r..',g:'..dominant.g..',b:'..dominant.b.."}"
	for _, k in pairs(palettes.tbl[1].color) do
		all_plt_color = all_plt_color .. "\n           " .. _ .. ' = {r:'..k.r..',g:'..k.g..',b:'..k.b.."}"
	end

	print_info("Color palettes","Changing '"..palettes.tbl[1].name.."' to new color:\n" .. all_plt_color)
end

local console = ""
function print_info(from,info)
	time = os.date("%X", os.time())

	console = console .. "At " .. time .. ""
	console = console .. "    Type >> " .. from .. "\n"
	console = console .. "       Informations: " .. info .. "\n"

	print("At " .. time .. "")
	print("    Type >> " .. from .. "")
	print("       Informations: " .. info .. "\n")
end

function load_visualizer_list(from,tree)
	local filesTable = lf.getDirectoryItems(from)
	final_visualizer_list_tbl[from] = {}

	for i,v in ipairs(filesTable) do
		local file = from.."/"..v
		local ext = v:sub(#v-3,#v)

		if lf.getInfo(file).type == "file" and ext == ".lua" then
			tree = tree.."\n"..file

			table.insert(visualizer_list,file)
			table.insert(final_visualizer_list_tbl[from],file)

			print_info("Visualizer","Loaded '" .. file)
		elseif lf.getInfo(file).type == "directory" then
			tree = tree.."\n"..file.." (DIR)"
			tree = load_visualizer_list(file, tree)
		end
	end
	return tree
end

function find_and_create_default_data(from,tree)
	lf.createDirectory(from)
	print_info("Data folder","Writing " .. from)

	local filesTable = lf.getDirectoryItems(from)
	for i,v in ipairs(filesTable) do
		local file = from.."/"..v
		if lf.getInfo(file).type == "file" then
			tree = tree.."\n"..file

			my_data = lf.read(file)
			lf.write(file, my_data)

			print_info("Data file","Writing " .. file)

		elseif lf.getInfo(file).type == "directory" then
			tree = tree.."\n"..file.." (DIR)"
			tree = find_and_create_default_data(file, tree)
		end
	end
	return tree
end

function find_and_rewrite_default_data(from,tree)
	lf.createDirectory(from)
	print_info("Data folder","Writing " .. from)

	local filesTable = lf.getDirectoryItems(from)
	for i,v in ipairs(filesTable) do
		local file = from.."/"..v
		if lf.getInfo(file).type == "file" then
			tree = tree.."\n"..file

			my_data = lf.read(file)

			lf.remove(file)
			lf.write(file, my_data)

			print_info("Data file","Writing " .. file)

		elseif lf.getInfo(file).type == "directory" then
			tree = tree.."\n"..file.." (DIR)"
			tree = find_and_create_default_data(file, tree)
		end
	end
	return tree
end

function load_song(f)
	if o then o:stop() end
	o = audio_decode:new(f)
	o:play()

	duration = o:getDuration("seconds")

	local n = f:getFilename()

	realName = string.sub(n,1,#n - #f:getExtension() - 1):gsub(string.char(92),"/"):gsub(".+/", "")
	path = f
	type = f:getExtension()

	print_info("Player","Playing '" .. realName .. "." .. type .. "'\n          Path: " .. n)

	if sample_waveform_data[path] then
	else
		sample_waveform_data[path] = {}
		sample_waveform_data[path].sample = {}
		sample_waveform_data[path].finished = false
		sample_waveform_taking[path] = 0
	end
end

function visualizer_list_load()
	menu_menu[2].other.visualizer = {}
	visualizer_list = {}
	final_visualizer_list_tbl = {}
	load_visualizer_list("visualizer","")
	
	style = {
		font="font/Montserrat-Regular.ttf",
		font_size=13,
		box_color_on={r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1}
	}

	for id, v in pairs(final_visualizer_list_tbl) do
		for id2, v2 in pairs(final_visualizer_list_tbl[id]) do
			if menu_menu[2].other.visualizer[id] then else menu_menu[2].other.visualizer[id] = {} end
			menu_menu[2].other.visualizer[id][id2] = {}
			menu_menu[2].other.visualizer[id][id2].button = NewButton(0,0,130,25,string.sub(v2,#id + 2,#v2),false,style,default_button_style)
		end
	end
end

function load_lang(lang)
	lang = require(".lang/" .. lang)

	return lang
end

function reload_button_lang()
	menu_button[1].txt = lang.get("menu.playlist")
	menu_button[2].txt = lang.get("menu.visualizer")
	menu_button[3].txt = lang.get("menu.visualizer.refresh")
	menu_button[4].txt = lang.get("menu.visualizer_settings")
	menu_button[5].txt = lang.get("menu.color_choose")
	menu_button[6].txt = lang.get("menu.lang")
	menu_button[7].txt = lang.get("menu.settings")
	menu_button[8].txt = lang.get("menu.debug.fps")
	menu_button[9].txt = lang.get("menu.equalizer")

	menu_menu[1].title = lang.get("menu.playlist")
	menu_menu[2].title = lang.get("menu.visualizer")
	menu_menu[3].title = lang.get("menu.visualizer_settings")
	menu_menu[4].title = lang.get("menu.color_choose")

	menu_menu[6].title = lang.get("menu.settings.label")
	menu_menu[5].title = lang.get("menu.lang")
	menu_menu[7].title = lang.get("menu.equalizer")

	render_button.txt = lang.get("text.render.txt")
end

function new_theme(color_system,t,t2)
	theme_color.use = color_system

	theme_color.theme = t
	theme_color.theme2 = t2
	theme_color.theme_accent = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,0.3)
	theme_color.theme_accent2 = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,0.1)

	update_theme_color()
end

function update_theme_color()
	menu_menu[4].other.palettes[2].box_color_on = theme_color.theme
	render_button.box_color_on = theme_color.theme_accent
	volume_slider.bar_color = theme_color.theme_accent
	seek_slider.bar_color = theme_color.theme_accent

	for _, but in pairs(menu_button) do but.box_color_on = theme_color.theme_accent end
	for _, sli in pairs(eq_slider) do sli.bar_color = theme_color.theme_accent end
	for _, sli in pairs(freq_slider) do sli.bar_color = theme_color.theme_accent end

	for i=1, #settings.background_type.name do
		settings.background_type.panel.settings.button[i].box_color_on = theme_color.theme_accent
	end

	for i=1, 5 do
		local mixed = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,i/5)
		palettes.tbl[2].color[i] = Color(mixed.r*255,mixed.g*255,mixed.b*255,mixed.a*255)
	end

	for _, but in pairs(menu_menu[1].other.playlist) do
		but.button.box_color_on = theme_color.theme_accent
	end

	for _, but in pairs(menu_menu[5].other.lang) do
		but.box_color_on = theme_color.theme_accent
	end
	
	for id, _ in pairs(menu_menu[2].other.visualizer) do
		for _, but in pairs(menu_menu[2].other.visualizer[id]) do
			but.button.box_color_on = theme_color.theme_accent
		end
	end

	if #menu_menu[3].other.visualizer_settings > 0 then
		for _, obj in pairs(menu_menu[3].other.visualizer_settings) do
			if not obj then return end

			if obj.type == "text" then
			elseif obj.type == "slider" then
				obj.obj.bar_color = theme_color.theme_accent
			elseif obj.type == "button" then
				obj.obj.box_color = theme_color.theme_accent
			elseif obj.type == "input" then
				obj.obj.line_color = {r=theme_color.theme_accent.r/2,g=theme_color.theme_accent.g/2,b=theme_color.theme_accent.b/2,a=1}
				obj.obj.line_color_on = theme_color.theme_accent
			end
		end
	end
end

function function_menu_box(fill,x,y,w,h)
	for i=1, 100 do
		local c = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,(i/100))
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

function answer_question(txt,title,x,y,w,h,button,get_input)
	button = button or {"Continue","Cancel"}
	get_input = get_input or true

	menu_input.open = true
	input_panel.question = {
		txt = txt,
		x = x,
		y = y,
		w = w,
		h = h,
		button = button,
		input = get_input
	}

	menu_input.x = x
	menu_input.y = y
	menu_input.w = w
	menu_input.h = h
	menu_input.title = title
end

function changelog(txt,title,x,y,w,h)
	menu_input.open = true
	input_panel.changelog = {
		txt = txt,
		x = x,
		y = y,
		w = w,
		h = h
	}

	menu_input.x = x
	menu_input.y = y
	menu_input.w = w
	menu_input.h = h
	menu_input.title = title
end

function function_changelog_menu()
	if not input_panel.changelog then return end
	x,y,w,h,txt,title = input_panel.changelog.x,input_panel.changelog.y,input_panel.changelog.w,input_panel.changelog.h,input_panel.changelog.txt,input_panel.changelog.title

	if menu_input.open then
		SetColor(0,0,0,0.3)
		Rect("fill",0,0,screenX,screenY)

		menu = menu_input.menu
		menu_input:draw()

		SetColor(1, 1, 1)
		Text(txt,menu._x,menu._y + 35,0,0,"font/Montserrat-Regular.ttf",15)

		input_panel.continue.x = menu._x
		input_panel.continue.y = menu._y + menu._h - 30
		input_panel.continue.w = menu._w
		input_panel.continue.h = 30

		input_panel.continue:draw()

		if input_panel.continue:isReleased() then
			input_panel.changelog = nil
			menu_input.open = false
		end
	end
end

function function_input_menu()
	if not input_panel.question then return end
	x,y,w,h,txt,title,button_list,get_input = input_panel.question.x,input_panel.question.y,input_panel.question.w,input_panel.question.h,input_panel.question.txt,input_panel.question.title,input_panel.question.button,input_panel.question.input

	data = {}
	data.continue = false
	data.cancel = false
	data.value = ""

	if menu_input.open then
		SetColor(0,0,0,0.3)
		Rect("fill",0,0,screenX,screenY)

		menu = menu_input.menu
		menu_input:draw()

		SetColor(1, 1, 1)
		Text(txt,menu._x,menu._y + 30,0,0,"font/Montserrat-Regular.ttf",15)

		if get_input then
			input_panel.input.x = menu._x
			input_panel.input.y = menu._y + menu._h / 2 + 15
			input_panel.input.w = menu._w
			input_panel.input.h = 25

			input_panel.answer = input_panel.input:getInput()
		end

		input_panel.continue.x = menu._x
		input_panel.continue.y = menu._y + menu._h - 25
		input_panel.continue.w = menu._w/2 - 5
		input_panel.continue.h = 20

		input_panel.cancel.x = menu._x + menu._w/2
		input_panel.cancel.y = menu._y + menu._h - 25
		input_panel.cancel.w = menu._w/2 - 5
		input_panel.cancel.h = 20

		input_panel.cancel.txt = button_list[2]
		input_panel.continue.txt = button_list[1]

		input_panel.cancel:draw()
		input_panel.continue:draw()

		if get_input then
			input_panel.input:draw()

			if #input_panel.answer > 0 then
				if input_panel.continue:isReleased() or input_panel.input:isValidated() then
					input_panel.question = nil
					data.continue = true
					menu_input.open = false
					input_panel.input:resetInput()
				end
			end
			if input_panel.cancel:isReleased() then
				input_panel.question = nil
				data.cancel = true
				menu_input.open = false
				input_panel.input:resetInput()
			end

			data.value = input_panel.answer
		else
			if input_panel.continue:isReleased() then
				input_panel.question = nil
				data.continue = true
				menu_input.open = false
			end

			if input_panel.cancel:isReleased() then
				input_panel.question = nil
				data.cancel = true
				menu_input.open = false
			end
		end
	end

	return data
end

function default_button_style(x,y,w,h,self,inrange)
	self.custom_data.text_align = self.custom_data.text_align or "center"

    self.r = self.box_color.r + self.hover_smooth * (self.box_color_on.r - self.box_color.r)*0.8 + boolToNum(self.active)*0.2
    self.g = self.box_color.g + self.hover_smooth * (self.box_color_on.g - self.box_color.g)*0.8 + boolToNum(self.active)*0.2
    self.b = self.box_color.b + self.hover_smooth * (self.box_color_on.b - self.box_color.b)*0.8 + boolToNum(self.active)*0.2
    self.a = self.box_color.a + self.hover_smooth * (self.box_color_on.a - self.box_color.a)*0.8 + boolToNum(self.active)*0.2

    SetColor(self.r,self.g,self.b,self.a)
    Rect("fill",x,y,w,h)

	self._, self.wrap_text = GetFont(self.font,self.font_size):getWrap(self.txt, w - 30)
	if #self.wrap_text > 1 then self.wrap_text[1] = self.wrap_text[1] .. ".." end

    if #self.txt > 0 then
    else
    	self._ = 0
    end

    SetColor(1,1,1)

	if self.custom_data.text_align == "center" then
    	Text(self.wrap_text[1],x + w/2,y + h/2,1,1,self.font)
	elseif self.custom_data.text_align == "left" then
		Text(self.wrap_text[1],x + 5,y + h/2,0,1,self.font)
	elseif self.custom_data.text_align == "right" then
		Text(self.wrap_text[1],x + w - 5,y + h/2,2,1,self.font)
	end
end

function background_func(type)
	w = screenX
	h = screenY

	img_w = background:getWidth()
	img_h = background:getHeight()

	move_w = (bs or 0) * img_w/2
	move_h = (bs or 0) * img_h/2

	scl_x = (img_w/w)
	scl_y = (img_h/h)
	scl = 0

	if scl_x >= scl_y then
		scl = scl_x
	end
	if scl_y >= scl_x then
		scl = scl_y
	end

	if type == "mirror" then
		Image(w/2, h/2 - (img_h/scl)/2 - move_h/2, (img_w/scl) + move_w, (img_h/scl) + move_h, 0, background)
		Image(w/2, h/2 - (img_h/scl)/2 - move_h/2, -(img_w/scl) - move_w, (img_h/scl) + move_h, 0, background)
	elseif type == "center" then
		Image(w/2 - img_w/2 - move_w / 2, screenY/2 - img_h/2 - move_h / 2, img_w + move_w, img_h + move_h, 0, background)
	elseif type == "stretch" then
		Image(0 - move_w / 2, 0 - move_h / 2, w + move_w, h + move_h, 0, background)
	elseif type == "auto" then
		Image(w/2 - (img_w/scl)/2 - move_w/2, h/2 - (img_h/scl)/2 - move_h/2, img_w/scl + move_w, img_h/scl + move_h, 0, background)
	end
end

function show_slider_info(slider,value_round,suffix,prefix,use_custom_text)
	local value_round = value_round or 0
	local suffix = suffix or ""
	local prefix = prefix or ""
	local use_custom_text = use_custom_text or false

	if slider.grabbed then
		slider_text = "" .. suffix .. round(slider:getValue(),value_round) .. prefix
		if use_custom_text then
			slider_text = "" .. suffix .. prefix
		end
		local text_data = Text(slider_text,-150,-150,1,1,"font/Montserrat-Regular.ttf",18)
		local w = text_data.w * 2 + 10

		if slider.orientation == "horizontal" then
			local menu2 = function_menu_box(true,slider.x - slider.length/2 + slider.value * slider.length - (w/2),slider.y - slider.width / 2 - 30,w,20)

			SetColor(theme_color.white)
			Text(text_data.text,menu2.x + menu2.w/2,menu2.y + menu2.h/2 - 2,1,1,"font/Montserrat-Regular.ttf",18)
		elseif slider.orientation == "vertical" then
			local menu2 = function_menu_box(true,slider.x - (w/2),slider.y + slider.length / 2 - 45 - slider.value * slider.length,w,20)
			
			SetColor(theme_color.white)
			Text(text_data.text,menu2.x + menu2.w/2,menu2.y + menu2.h/2 - 2,1,1,"font/Montserrat-Regular.ttf",18)
		end
	end

	SetColor(theme_color.white)
end

setup_changed("d_clicked",false)

local dd_current_click = 0
local last_clicked = lt.getTime()

function get_double_clicked(mouse_id,wait,x,y,w,h)
	clicked = false

	if (lt.getTime() - last_clicked) >= wait then
		dd_current_click = 0
	end

	if inrange(x,y,w,h) and changed("d_clicked",lm.isDown(mouse_id)) and lm.isDown(mouse_id) then
		dd_current_click = dd_current_click + 1

		if dd_current_click >= 2 then
			dd_current_click = 0

			clicked = true
		end

		last_clicked = lt.getTime()
	end

	return clicked
end

function love.keypressed(key, unicode)
	input_key(key)
	if key == "f11" then lw.setFullscreen(not lw.getFullscreen()) end
end

--Setup default visualizer function
function load_visualizer()
end
function on_apk_update()
end
function draw_background()
	return true
end
function setup_settings()
	return nil
end
----------------------------------------------------------------------

function love.load()
	--lm.setVisible(false)
	--w.setFullscreen(true)

	current_app_version = "v2.004 beta"


	--Create file the apk need to run properly
	my_data = lf.read("readme.txt")
	lf.write("readme.txt", my_data)


	find_and_create_default_data("interface","")
	find_and_create_default_data("visualizer","")
	find_and_create_default_data("docs","")

	find_and_rewrite_default_data("interface","")
	find_and_rewrite_default_data("visualizer","")
	find_and_rewrite_default_data("docs","")

	--[[
	if lf.getInfo("version") then
		lf.remove("version/" .. current_app_version .. ".zip")
		assert(loveZip.writeZip("", "version/"..current_app_version..".zip"))
	else
		lf.createDirectory("version")
		assert(loveZip.writeZip("", "version/"..current_app_version..".zip"))
	end
	]]

	--new_theme(Color(243/255,144/255,79/255),Color(59/255,67/255,113/255))

	if lf.getInfo("render") then else
		lf.createDirectory("render")
	end

	------------------------------
	for i=1, 5 do
		local mixed = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,i/5)
		palettes.tbl[2].color[i] = Color(mixed.r*255,mixed.g*255,mixed.b*255,mixed.a*255)
	end

	settings = {}

	settings.visualizer_id = "visualizer/astalneker_visualizer.lua"
	settings.lang_selected = "fr"
	settings.random_playing = false
	settings.pause = false

	settings.background_type = {}
	settings.background_type_active = "Auto"
	settings.background_type.name = {
		"Mirror",
		"Auto",
		"Center",
		"Stretch"
	}

	settings.show_fps = false
	settings.render_mode = false
	settings.render_mode_timer = 5

	--[[
	lang_list = {
		{
			name="Français",
			id = "fr"
		},
		{
			name="English",
			id = "en"
		},
		{
			name="German",
			id = "ge"
		}
	}
	]]
	--lang = load_lang(settings.lang_selected)
	--palettes = lf.load("data/color.lua")()   --Have to work on
	------------------------------

	background_data = li.newImageData("img/background.jpg")
	background = lg.newImage(background_data)

	cd = lg.newImage("img/cd.png")

	next_img = lg.newImage("img/button/next.png")
	play_img = lg.newImage("img/button/play.png")
	pause_img = lg.newImage("img/button/pause.png")
	previous_img = lg.newImage("img/button/back.png")
	random_img = lg.newImage("img/button/random.png")
	resize_img = lg.newImage("img/resize.png")

	resize_img = lg.newImage("img/resize.png")

	pic_palettes(background_data)

	style = {
		font="font/Montserrat-Regular.ttf",
		font_size=13,
		box_color_on={r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1}
	}

	------------[BACKGROUND TYPE]------------
	style.box_color_on={r=0,g=0,b=0,a=0}
	style.box_color={r=0,g=0,b=0,a=0}

	settings.background_type.button = NewButton(0,0,130,25,"",true,style,default_button_style)
	settings.background_type.panel = {}
	settings.background_type.panel.settings = {}
	settings.background_type.panel.settings.button = {}

	style = {
		font="font/Montserrat-Regular.ttf",
		font_size=13,
		box_color_on={r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1}
	}
	for i=1, #settings.background_type.name do
		settings.background_type.panel.settings.button[i] = NewButton(0,0,130,25,"Set to: " .. settings.background_type.name[i],false,style,default_button_style)
	end
	----------------------------------------
	
	------------[INPUT BOX PANEL]-----------
	input_panel = {}
	input_panel.cancel = NewButton(0,0,130,25,"Cancel",false,style,default_button_style)
	input_panel.continue = NewButton(0,0,130,25,"Continue",false,style,default_button_style)
	input_panel.answer = ""
	input_panel.question = nil
	input_panel.changelog = nil

	input_style = {
		font="font/Montserrat-Regular.ttf",
		font_size=13,
		line_color_on={r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1},
		line_color={r=theme_color.theme_accent.r/2,g=theme_color.theme_accent.g/2,b=theme_color.theme_accent.b/2,a=1}
	}
	input_panel.input = NewInputBox(0,0,150,30,"Playlist name.",input_style)
	-----------------------------------------

	------------[SETTINGS MENU BUTTON AND MENU]------------
	menu_button = {}
	menu_menu = {}

	menu_button[1] = NewButton(0,0,130,25,lang.get("menu.playlist"),false,style,default_button_style)
	menu_button[2] = NewButton(0,0,130,25,lang.get("menu.visualizer"),false,style,default_button_style)
	menu_button[3] = NewButton(0,0,130,25,lang.get("menu.visualizer.refresh"),false,style,default_button_style)
	menu_button[4] = NewButton(0,0,170,25,lang.get("menu.visualizer_settings"),false,style,default_button_style)
	menu_button[5] = NewButton(0,0,130,25,lang.get("menu.color_choose"),false,style,default_button_style)
	menu_button[6] = NewButton(0,0,130,25,lang.get("menu.lang"),false,style,default_button_style)
	menu_button[7] = NewButton(0,0,200,35,lang.get("menu.settings"),false,style,default_button_style)
	menu_button[8] = NewButton(0,0,130,25,lang.get("menu.debug.fps"),false,style,default_button_style)
	menu_button[9] = NewButton(0,0,130,25,lang.get("menu.equalizer"),false,style,default_button_style)

	menu_menu[1] = NewMenu(lang.get("menu.playlist"),20,60,250,600,false,true,true)
	menu_menu[2] = NewMenu(lang.get("menu.visualizer"),250 + 40,60,250,430,false,true,true)
	menu_menu[3] = NewMenu(lang.get("menu.visualizer_settings"),250 + 40,300 + 210,350,150,false,true,true)
	menu_menu[4] = NewMenu(lang.get("menu.color_choose"),250 + 40 + 370,60,250,600,false,true,true)

	menu_menu[6] = NewMenu(lang.get("menu.settings.label"),ScrW() - 300 - 20,60,300,400,false,true,true)
	menu_menu[5] = NewMenu(lang.get("menu.lang"),ScrW() - 550 - 20,60,230,180,false,true,true)
	menu_menu[7] = NewMenu(lang.get("menu.equalizer"),ScrW() - 20 - 450,480,450,250,false,false,true)

	for i=1, #menu_menu do
		menu_menu[i].other = {}
	end

	menu_menu[1].other.playlist = {}
	menu_menu[2].other.visualizer = {}

	menu_menu[3].other.visualizer_settings = {}

	menu_menu[4].other.palettes = {}

	menu_menu[5].other.lang = {}

	for i=1, #palettes.tbl do
		style.box_color_on = {r=palettes.tbl[i].color[1].r/255,g=palettes.tbl[i].color[1].g/255,b=palettes.tbl[i].color[1].b/255,a=1}

		menu_menu[4].other.palettes[i] = {}
		menu_menu[4].other.palettes[i].button = NewButton(0,0,130,25,palettes.tbl[i].name,false,style,default_button_style)
	end
	style.box_color_on = {r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1}

	for i=1, #lang_list do
		menu_menu[5].other.lang[i] = NewButton(0,0,130,25,lang_list[i].name,false,style,default_button_style)
	end


	render_button = NewButton(0,0,130,25,lang.get("text.render.txt"),false,style,default_button_style)

	visualizer_list_load()
	----------------------------------------------

	--------------[Pause-Play  Previous Next  Random song button]--------------
	style.box_color = {r=0,g=0,b=0,a=0}
	style.box_color_on = {r=0,g=0,b=0,a=0}

	play_button = NewButton(0,0,50,50,"",false,style,default_button_style)
	previous_button = NewButton(0,0,40,40,"",false,style,default_button_style)
	next_button = NewButton(0,0,40,40,"",false,style,default_button_style)
	random_button = NewButton(0,0,30,30,"",false,style,default_button_style)
	----------------------------------------

	--------------[Setup eq slider]---------------
	local default_eq = {}
	
	default_eq[1] = 0
	default_eq[2] = 0
	default_eq[3] = 0
	default_eq[4] = 0
	default_eq[5] = 0
	default_eq[6] = 0

	eq_slider = {}
	freq_slider = {}
	for i=1, 4 do
		eq_slider[i] = newSlider(0, 150, 150, default_eq[2 + i], 0, 12, nil, {row_divider=24,bar_color=theme_color.theme_accent, width=15, orientation='vertical', track='line', knob='circle'})
	end
	freq_slider[1] = newSlider(0, 150, 80, default_eq[1], 250, 480, nil, {row_divider=20,bar_color=theme_color.theme_accent,width=15, orientation='horizontal', track='line', knob='circle'})
	freq_slider[2] = newSlider(0, 150, 80, default_eq[2], 1900, 3900, nil, {row_divider=20,bar_color=theme_color.theme_accent,width=15, orientation='horizontal', track='line', knob='circle'})
	-------------------------------------------

	--------------[Volume and seek slider]---------------
	volume_slider = newSlider(0, 150, 120, 50, 0, 100, nil, {row_divider=20,bar_color=theme_color.theme_accent,width=15, orientation='horizontal', track='roundrect', knob='circle'})
	seek_slider = newSlider(0, 150, 450, 0, 0, 1, nil, {bar_color=theme_color.theme_accent,width=15, orientation='horizontal', track='roundrect', knob='circle'})
	-------------------------------------------

	setup_changed(1,false)

	if #visualizer_list > 0 then
		lf.load("" .. settings.visualizer_id)()

		local v_settings = setup_settings()
		menu_menu[3].other.visualizer_settings = v_settings
	end


	-------------------------------------------
	menu_input = NewMenu("Title goes here D:",ScrW()/2 - 350/2,ScrH()/2 - 200/2,350,200,false,false,false)

	lk.setKeyRepeat(true)
	lw.setTitle("AstMP3 " .. current_app_version)

	local changelog_txt = ""
	changelog_version = require("changelog")

	for i=1, #changelog_version do
		local change = changelog_version[i]
		local show_important = ""
		local important_thing = ""

		if change.important then
			for i=1, #change.important_to_know do
				important_thing = important_thing .. change.important_to_know[i ] .. "\n"
			end
			
			show_important = "!!!\n" .. important_thing .. "!!!\n"
		end

		changelog_txt = changelog_txt .. "" .. change.ver .. "\n" .. show_important .. "\n     "

		for x=1, #change.info do
			local info = change.info[x]
			changelog_txt = changelog_txt .. "- " .. info .. "\n     "
		end

		if i == #changelog_version then else
			changelog_txt = changelog_txt .. "\n________________________________________________________\n\n"
		end
	end

	if lf.getInfo("latest_version.txt") then
		local ver = lf.read("latest_version.txt")

		if ver == current_app_version then
		else
			lf.remove("latest_version.txt")
			lf.write("latest_version.txt", "" .. current_app_version)

			changelog(changelog_txt,"Changelog",ScrW()/2 - 800/2,ScrH()/2 - 500/2,800,500)
		end
	else
		lf.remove("latest_version.txt")
		lf.write("latest_version.txt", "" .. current_app_version)

		changelog(changelog_txt,"Changelog",ScrW()/2 - 800/2,ScrH()/2 - 500/2,800,500)
	end
	-------------------------------------------

	--answer_question("The list you want to import will be saved\n as a playtist.\nWhat name would you like to give him?","Name your playlist.",ScrW()/2 - 350/2,ScrH()/2 - 200/2,350,200)
end

function love.filedropped(f)
	local n = f:getFilename()
	if n:lower():find("%.mp3$") or n:lower():find("%.wav$") then
		add_song = n:gsub(string.char(92),"/"):gsub(".+/", "")
		if o then
			table.insert(playlist,f)

			print_info("Playlist","Adding '" .. add_song .. "' to the playlist..\n          Path: " .. n)
		else
			table.insert(playlist,f)
			load_song(f)

			last_picture = lt.getTime()
		end

		local folder = string.sub(n:gsub(string.char(92),"/"),1,#n - #add_song - 1) 
		if final_playlist_tbl[folder] then
		else
			final_playlist_tbl[folder] = {}
		end
		table.insert(final_playlist_tbl[folder],f)


		local id = #menu_menu[1].other.playlist + 1

		song_data = find_song_data(f)

		name = "#" .. #playlist .. " " .. add_song
		if song_data and song_data.to_default_title == false then
			name = "#" .. #playlist .. " " .. song_data.title
		end

		if #name > 26 then
			name = string.sub(name,0,26 - 2) .. ".."
		end

		style = {
			font="font/Montserrat-Regular.ttf",
			font_size=13,
			box_color_on={r=theme_color.theme_accent.r,g=theme_color.theme_accent.g,b=theme_color.theme_accent.b,a=1},
			text_align = "left"
		}
		menu_menu[1].other.playlist[id] = {}
		menu_menu[1].other.playlist[id].button = NewButton(0,0,130,25,name,false,style,default_button_style)

		menu_menu[1].other.playlist[id].path = f
	end

    if n:lower():find("%.png$") or n:lower():find("%.jpeg$") or n:lower():find("%.jpg$") or n:lower():find("%.bmp$") then
		background_data = li.newImageData(f)
		background = lg.newImage(background_data)

		pic_palettes(background_data)

		menu_menu[4].other.palettes[1].button.box_color_on = {r=palettes.tbl[1].color[5].r/255,g=palettes.tbl[1].color[5].g/255,b=palettes.tbl[1].color[5].b/255,a=1}

		print_info("Background","Switching background to: " .. n)
	end

	if n:lower():find("%.ogv$") then
		background_video = lg.newVideo(f)
		menu_menu[4].other.palettes[1].button.box_color_on = {r=palettes.tbl[1].color[5].r/255,g=palettes.tbl[1].color[5].g/255,b=palettes.tbl[1].color[5].b/255,a=1}

		print_info("Background","Switching background to: " .. n)
	end
end

function love.update(dt)
	on_apk_update(dt)

	if settings.render_mode then
	else
		render_button:update()

		if menu_input.open then
			input_panel.cancel:update()
			input_panel.continue:update()
			input_panel.input:update()

			menu_input:update()

			return
		end

		settings.background_type.button:update()
		if settings.background_type.button.active then
			for i=1, #settings.background_type.name do
				settings.background_type.panel.settings.button[i]:update()
			end
		end

		if o then
			play_button:update()
			previous_button:update()
			next_button:update()
			random_button:update()

			volume_slider:update()
			seek_slider:update()

			for _, button in pairs(menu_button) do
				if _ == 3 or _ == 6 or _ == 8 or _ == 9 then
				else
					button:update()
				end
			end
			for _, menu in pairs(menu_menu) do
				menu:update()
			end

			if menu_menu[1].open then
				for i=1, #menu_menu[1].other.playlist do
					menu_menu[1].other.playlist[i].button:update()

					if i * 30 >= menu_menu[1].menu._h - 80 then break end
				end
			end

			if menu_menu[2].open then
				menu_button[3]:update()

				move = 0
				for id, v in pairs(final_visualizer_list_tbl) do
					move = move + 40

					for id2, v2 in pairs(final_visualizer_list_tbl[id]) do
						move = move + 25
						menu_menu[2].other.visualizer[id][id2].button:update()

						if move >= menu_menu[2].menu._h - 100 then break end
					end
				end
			end

			if menu_menu[3].open then
				if menu_menu[3].other.visualizer_settings and #menu_menu[3].other.visualizer_settings > 0 then
					local pos = 0
					for i=1, #menu_menu[3].other.visualizer_settings do
						local me = menu_menu[3].other.visualizer_settings[i]

						if not me then return end

						if me.type == "text" then
							pos = pos + 20
						elseif me.type == "slider" then
							me.obj:update()
							pos = pos + 20
						elseif me.type == "button" then
							me.obj:update()
							pos = pos + 30
						elseif me.type == "input" then
							me.obj:update()
							pos = pos + 30
						end

						if pos >= menu_menu[3].menu._h - 55 then break end
					end
				end
			end

			if menu_menu[6].open then
				menu_button[8]:update()

				menu_button[6]:update()
				if menu_menu[5].open then
					for i=1, #menu_menu[5].other.lang do
						menu_menu[5].other.lang[i]:update()
		
						if i * 30 >= menu_menu[5].h - 100 then break end
					end
				end
				
				menu_button[9]:update()
				if menu_menu[7].open then
					for i=1, #eq_slider do
						eq_slider[i]:update()
					end
					for i=1, #freq_slider do
						freq_slider[i]:update()
					end
				end
			end

			menu_button[5]:update()
			if menu_menu[4].open then
				for i=1, #menu_menu[4].other.palettes do
					menu_menu[4].other.palettes[i].button:update()
				end
			end
		else
		end
	end
end

function love.draw()
	lg.setLineWidth(1)
	screenX,screenY = ScrW(),ScrH()

	if not o then
		SetColor(theme_color.gray)
		background_func(settings.background_type_active:lower())

		Text(lang.get("text.dd.mp3"),50,screenY/2 - 15,0,1,"font/Montserrat-Regular.ttf",25)
		Text(lang.get("text.dd.img"),50,screenY/2 + 15,0,1,"font/Montserrat-Regular.ttf",25)

		SetColor(theme_color.white)
		Text("by AstalNeker",screenX - 15,screenY - 15,2,2,"font/Montserrat-Regular.ttf",15)
		Text("" .. current_app_version,15,screenY - 15,0,2,"font/Montserrat-Regular.ttf",15)

		return
	end

	if source_time >= duration - 0.1 then
		if settings.random_playing then
			playing_id = round(random(1,#playlist))
		else
			playing_id = playing_id + 1
		end

		if playing_id > #playlist then playing_id = 1 end
		f = playlist[playing_id]
		load_song(f)
	end

	local data = o:getBytes(0 or lt.getDelta())
	if not data then return end

	local line = {}
	local line2 = {}
	local left_max, right_max = 0, 0
	local sample_left_max, sample_right_max = 0, 0
	local le, ri = 0, 0

	local len = data:getSampleCount() / 2
	local f1, p1 = 0, 0

	local better_waveform = {}

	for i=1, len do
		s1, s2 = data:getSample(i, 1), data:getSample(i, 2)

		if i % 8 == 0 then
			f1 = f1 + 1
			ff[f1] = (s1 + s2) * .5
		end
		if i % 16 == 0 then
			p1 = p1 + 1
			local m = p1 * 4

			line[m - 3] = -(1/len) * 150 + screenX-155 - 155 + (i/len) * 150
			line[m - 2] = screenY-155 + 25 + ((data:getSample((p1 - 1) * 2, 1)/2) * 50) * current_volume2
			line[m - 1] = -(1/len) * 150 + screenX-155 - 155 + (i/len) * 150
			line[m] = screenY-155 + 25 + ((data:getSample((p1 - 1) * 2, 2)/2) * 50) * current_volume2

			line2[m - 3] = -(1/len) * 150 + screenX-155 + (i/len) * 150
			line2[m - 2] = screenY-155 + 25 + ((data:getSample((p1 - 1) * 2, 1)/2) * 50) * current_volume
			line2[m - 1] = -(1/len) * 150 + screenX-155 + (i/len) * 150
			line2[m] = screenY-155 + 25 + ((data:getSample((p1 - 1) * 2, 2)/2) * 50) * current_volume

			if better_waveform[i] then else better_waveform[i] = {} end
			better_waveform[i].x = data:getSample((p1 - 1) * 2, 1)
			better_waveform[i].y = data:getSample((p1 - 1) * 2, 2)
		end

		local p = fft[i] or {i=0,r=0}

		local l = (p.i or 0)
		local r = (p.r or 0)

		if (p.i or 0) < 0 then l = -(p.i or 0) end
		if (p.r or 0) < 0 then r = -(p.r or 0) end

		l = l / 500
		r = r / 500

		smooth_fft[i] = lerp(0.4,(smooth_fft[i] or 0),(((l+r)*0.5) * math.log10(i / 2)) * current_volume2)

		if s1 < 0 then s1 = -s1 end
		if s2 < 0 then s2 = -s2 end

		if s1 > left_max then left_max = s1 end
		if s2 > right_max then right_max = s2 end
	end

	--[[
	for a=1, 10 do
		if sample_waveform_taking[path] < duration-1 and sample_waveform_data[path].finished == false then
			sample_waveform_taking[path] = sample_waveform_taking[path] + 0.1

			o.sample_waveform_data:seek(sample_waveform_taking[path])

			local sample_waveform_decode = o.sample_waveform_data:decode()
			local len = sample_waveform_decode:getSampleCount() / 2

			s1, s2 = sample_waveform_decode:getSample(len, 1), sample_waveform_decode:getSample(len, 2)

			if s1 > sample_left_max then sample_left_max = s1 end
			if s2 > sample_right_max then sample_right_max = s2 end

			id = (sample_waveform_taking[path]/duration) * 1000

			sample_waveform_data[path].sample[id] = {}
			sample_waveform_data[path].sample[id] = {}
			sample_waveform_data[path].sample[id].x = sample_left_max
			sample_waveform_data[path].sample[id].y = sample_right_max
		else
			sample_waveform_data[path].finished = true
		end
	end
	]]

	if sample_waveform_data[path].finished then
	else
		local s1lerp = 0
		local s2lerp = 0
		for id=1, 1000 do
			o.sample_waveform_data:seek(((id-1)/1000) * duration)

			local sample_waveform_decode = o.sample_waveform_data:decode()
			local len = sample_waveform_decode:getSampleCount() / 2

			sample_left_max = 0
			sample_right_max = 0
			s1max = 0
			s2max = 0
			for i=1, len do
				s1, s2 = sample_waveform_decode:getSample(i, 1), sample_waveform_decode:getSample(i, 2)
				if s1 < 0 then s1 = -s1 end
				if s2 < 0 then s2 = -s2 end

				if s1 > s1max then s1max = s1 end
				if s2 > s2max then s2max = s2 end
			end

			s1lerp = lerp(0.5,s1lerp,s1max)
			s2lerp = lerp(0.5,s2lerp,s2max)

			sample_waveform_data[path].sample[id] = {}
			sample_waveform_data[path].sample[id] = {}
			sample_waveform_data[path].sample[id].x = clamp(s1lerp,0,1)
			sample_waveform_data[path].sample[id].y = clamp(s2lerp,0,1)
		end

		sample_waveform_data[path].finished = true
	end

	lowmidfrequency = freq_slider[1]:getValue()
	highmidfrequency = freq_slider[2]:getValue()
	lowgain = eq_slider[1]:getValue()
	lowmidgain = eq_slider[2]:getValue()
	highmidgain = eq_slider[3]:getValue()
	highgain = eq_slider[4]:getValue()

	la.setEffect('equalizer', {
		type = 'equalizer',
		lowcut = lowgain,
		lowgain = lowgain,
		lowmidgain = lowmidgain,
		lowmidfrequency = lowmidfrequency,
		highmidgain = highmidgain,
		highmidfrequency = highmidfrequency,
		highgain = highgain,
		highcut = highgain
	})
	o:setEffect('equalizer')

	fft = require'.lib/fft'(ff)
	bassfft = getbass(fft,1,20)
	bassfft2 = getbass(fft,5,15)

	size_percent = clamp(bassfft,0,50)
	bassfft = (bassfft * (1 - (size_percent/150))) * current_volume2

	pulse = clamp((bassfft2 - last_bass)/50,0,1)
	last_bass = bassfft2


	left = lerp(0.3,left or 0,clamp(left_max * current_volume,0,1))
	right = lerp(0.3,right or 0,clamp(right_max * current_volume,0,1))
	mono = (left + right) * 0.5

	--Draw background
	if draw_background() then
		bs = bassfft/10000

		SetColor(0.2 + bassfft/400, 0.2 + bassfft/400, 0.2 + bassfft/400)
		background_func(settings.background_type_active:lower())
	end
	-----------------------------------------------------

	--CODE TO DRAW THE VISUALIZER HERE
	load_visualizer({
		smooth_fft = smooth_fft,
		left_channel = left,
		right_channel = right,
		mono_channel = mono,
		waveform = better_waveform,
		sound_data = data,
		palettes = palettes.tbl[palettes.current],
		screen_size = {
			w = screenX,
			h = screenY
		},
		song_info = {
			name = o.song_data,
			time = {
				duration = duration,
				time = source_time
			}
		}
	})

	if get_double_clicked(1,0.2,0,0,screenX,screenY) then
		settings.render_mode = false
	end
	
	if settings.render_mode then
		if lm.isVisible() == true then lm.setVisible(false) end

		rcu_alpha = lerp(0.02,rcu_alpha,0)

		if rcu_alpha < 0.01 then
			if settings.render_mode_timer <= 0 then
				o:play()
			else
				if (lt.getTime() - last_timer_time) > 1 then
					settings.render_mode_timer = settings.render_mode_timer - 1
					last_timer_time = lt.getTime()
				end
			end
		else
			o:pause()
			o:seek(0)

			current_volume = volume_slider:getValue()/100
			current_volume2 = 1
			o:setVolume(current_volume)

			settings.pause = false

			last_timer_time = lt.getTime()
		end
 
		SetColor(theme_color.white.r,theme_color.white.g,theme_color.white.b,rcu_alpha)
		Text(lang.get("text.render.click.unactive"),screenX/2,screenY - 150,1,1,"font/Montserrat-Regular.ttf",25)

		if settings.render_mode_timer <= 0.1 then
		else
			if rcu_alpha < 0.01 then
				SetColor(255,0,0)
				Text(settings.render_mode_timer .. "",screenX/2,screenY/2,1,1,"font/Montserrat-Regular.ttf",250)
			else
				SetColor(255,0,0)
				Text(lang.get("text.render.start"),screenX/2,screenY/2,1,1,"font/Montserrat-Regular.ttf",50)
			end
		end

		return
	else
		rcu_alpha = 1
		settings.render_mode_timer = 5
		if lm.isVisible() == false then lm.setVisible(true) end
	end
	-----------------------------------------------------

	SetColor(theme_color.white)
	Image(screenX - 155 - 155 - (150/2) - 30,screenY - 100 - (150/2) - 30, 150, 150, source_time * 64, cd)

	SetColor(theme_color.interface.r,theme_color.interface.g,theme_color.interface.b)
	Rect("fill",0,screenY-100,screenX,100)
	Rect("fill",screenX - 160*2 + 5,screenY-160,160*2,60)
	Rect("fill",screenX / 2 - 308/2,screenY - 100 - 32,308,32)
	SetColor(SetColor(theme_color.primary))
	Rect("fill",screenX / 2 - 150,screenY - 100 - 28,300,25)
	

	SetColor(theme_color.primary)
	Rect("fill",screenX - 155 - 155,screenY-155,150,50)
	SetColor(theme_color.theme)
	lg.line(line)

	SetColor(theme_color.primary)
	Rect("fill",screenX - 155,screenY-155,150,50)
	SetColor(theme_color.theme)
	lg.line(line2)


	local line3 = {}
	local sample_x = {}
	local sample_y = {}

	for i, sample in pairs(sample_waveform_data[path].sample) do
		if sample then
			sample_x[i] = sample.x
			sample_y[i] = sample.y
		else
			sample_x[i] = 0
			sample_y[i] = 0
		end

		if sample_x[i] < 0 then sample_x[i] = -sample_x[i] end
		if sample_y[i] < 0 then sample_y[i] = -sample_y[i] end

		local c = mix_2_color(theme_color.use,theme_color.theme,theme_color.theme2,(i/1000))

		if (i/1000) >= seek_slider.value then
			SetColor((c.r or 0)/2,(c.g or 0)/2,(c.b or 0)/2,0.3)
		else
			SetColor(c)
		end

		Rect("fill",seek_slider.x - (1/1000) * seek_slider.length - seek_slider.length/2 + (i/1000) * seek_slider.length,seek_slider.y - 2,(1/1000) * seek_slider.length,-((sample_x[i]+sample_y[i])/2) * 50)
	end

	SetColor(theme_color.white)

	name = realName
	if o.song_data and o.song_data.to_default_title == false then
		name = o.song_data.title
	end

	_, wrap_text = GetFont("font/Montserrat-Regular.ttf",15):getWrap(name, 300 - 30)
	if #wrap_text > 1 then wrap_text[1] = wrap_text[1] .. ".." end

	SetColor(theme_color.white)
	Text(wrap_text[1],screenX / 2,screenY - 100 - 25,1,0,"font/Montserrat-Regular.ttf",15)
	Text(nice_time(source_time).."/"..nice_time(duration),seek_slider.x - seek_slider.length/2,seek_slider.y - 15,0,1,"font/Montserrat-Regular.ttf",15)


	play_button.x = screenX / 2 - play_button.w/2
	play_button.y = screenY - 90

	previous_button.x = play_button.x - 50
	previous_button.y = play_button.y + 5

	next_button.x = play_button.x + 60
	next_button.y = play_button.y + 5

	random_button.x = previous_button.x - 50
	random_button.y = play_button.y + 10


	play_button:draw()
	previous_button:draw()
	next_button:draw()
	random_button:draw()

	
	if play_button:isReleased() then
		settings.pause = not settings.pause
	end

	if random_button:isReleased() then
		settings.random_playing = not settings.random_playing
	end

	if previous_button:isReleased() then
		settings.pause = false

		if source_time > 5 then
			o:seek(0)
		else
			if settings.random_playing then
				playing_id = round(random(1,#playlist))
			else
				playing_id = playing_id - 1
			end

			if playing_id < 1 then playing_id = #playlist end
			f = playlist[playing_id]
			load_song(f)
		end
	end

	if next_button:isReleased() then
		settings.pause = false

		if settings.random_playing then
			playing_id = round(random(1,#playlist))
		else
			playing_id = playing_id + 1
		end

		if playing_id > #playlist then playing_id = 1 end
		f = playlist[playing_id]
		load_song(f)
	end

	
	hover_size = play_button.hover_smooth * 5 + boolToNum(play_button.active) * 5
	if settings.pause then
		Image(play_button.x+5 - hover_size/2,play_button.y+5 - hover_size/2,play_button.w-10 + hover_size,play_button.h-10 + hover_size,0,play_img)
	else
		Image(play_button.x - hover_size/2,play_button.y - hover_size/2,play_button.w + hover_size,play_button.h + hover_size,0,pause_img)
	end

	if settings.random_playing then
	else
	end

	hover_size = random_button.hover_smooth * 5 + boolToNum(random_button.active) * 5
	if settings.random_playing then
		SetColor(theme_color.theme_accent)
	else
		SetColor(theme_color.white)
	end
	Image(random_button.x - hover_size/2,random_button.y - hover_size/2,random_button.w + hover_size,random_button.h + hover_size,0,random_img)

	SetColor(theme_color.white)
	hover_size = next_button.hover_smooth * 5 + boolToNum(next_button.active) * 5
	Image(next_button.x+5 - hover_size/2,next_button.y+5 - hover_size/2,next_button.w-10 + hover_size,next_button.h-10 + hover_size,0,next_img)

	hover_size = previous_button.hover_smooth * 5 + boolToNum(previous_button.active) * 5
	Image(previous_button.x+5 - hover_size/2,previous_button.y+5 - hover_size/2,previous_button.w-10 + hover_size,previous_button.h-10 + hover_size,0,previous_img)

	seek_slider.x = screenX / 2
	seek_slider.y = screenY - 20

	volume_slider.x = seek_slider.x + seek_slider.length/2 + volume_slider.length
	volume_slider.y = seek_slider.y

	volume_slider:draw()
	seek_slider:draw()

	if settings.pause then
		current_volume = lerp(0.2,current_volume,0)
		current_volume2 = lerp(0.2,current_volume2,0)
	else
		current_volume = lerp(0.1,current_volume,volume_slider:getValue()/100)
		current_volume2 = lerp(0.1,current_volume2,1)
	end
	o:setVolume(current_volume)

	if current_volume2 < 0.01 then
		if settings.pause then o:pause() end
	elseif current_volume2 > 0.01 then
		o:play()
	end

	if changed(1,seek_slider.grabbed) and seek_slider.grabbed == false then
		o:seek(seek_slider:getValue() * duration, "seconds")
	end
	if not seek_slider.grabbed then
		seek_slider:setValue(source_time/duration)
	end

	show_slider_info(seek_slider,0,nice_time(seek_slider:getValue() * duration).."/",nice_time(duration),true)
	show_slider_info(volume_slider,0,""," %")

	--Button function
	me = settings.background_type.button
	me.x = menu_button[7].x - me.w - 10
	me.y = menu_button[7].y - me:getHover("smooth") * (25+#settings.background_type.name*25)
	me.w = 250
	me.h = 25 + me:getHover("smooth") * (25+#settings.background_type.name*25)

	render_button.x = menu_button[7].x + render_button.w/2
	render_button.y = menu_button[7].y + menu_button[7].h + 10

	me.txt = ""
	me:draw()

	menu = function_menu_box(true,me.x,me.y,me.w,me.h)

	if settings.background_type.button.active then
		for i=1, #settings.background_type.name do
			settings.background_type.panel.settings.button[i].x = menu._x
			settings.background_type.panel.settings.button[i].y = -25 + menu._y + i * 25
			settings.background_type.panel.settings.button[i].w = menu._w

			if settings.background_type.name[i] == settings.background_type_active then
				settings.background_type.panel.settings.button[i]:set_active(true)
			else
				settings.background_type.panel.settings.button[i]:set_active(false)
			end

			settings.background_type.panel.settings.button[i]:draw()

			if settings.background_type.panel.settings.button[i]:isReleased() then
				settings.background_type_active = settings.background_type.name[i]
			end
		end
	end

	SetColor(theme_color.white)
	Text("Background style: " .. settings.background_type_active,me.x + me.w / 2,me.y + me.h - 13,1,1,"font/Montserrat-Regular.ttf",15)


	render_button.x = menu_button[7].x + render_button.w/2
	render_button.y = menu_button[7].y + menu_button[7].h + 10
	render_button:draw()
	if render_button:isReleased() then
		settings.render_mode = true
	end

	--[[DRAW ALL PANEL AND PANEL BUTTON]]

	for _, button in pairs(menu_button) do
		if _ == 3 or _ == 6 or _ == 8 or _ == 9 then
		else
			button:draw()
		end
	end
	for _, menu in pairs(menu_menu) do
		menu:draw()
	end

	menu_button[1].x = 10
	menu_button[1].y = screenY - 100 + 10
	if menu_button[1]:isReleased() then
		menu_menu[1].open = not menu_menu[1].open
	end

	menu_button[2].x = menu_button[1].x + menu_button[1].w + 50
	menu_button[2].y = screenY - 100 + 10
	if menu_button[2]:isReleased() then
		menu_menu[2].open = not menu_menu[2].open
	end

	menu_button[4].x = menu_button[2].x + menu_button[2].w / 2 - menu_button[4].w / 2
	menu_button[4].y = menu_button[2].y + menu_button[2].h + 5
	if menu_button[4]:isReleased() then
		menu_menu[3].open = not menu_menu[3].open
	end


	menu_button[7].x = screenX - menu_button[7].w - 10
	menu_button[7].y = menu_button[1].y
	if menu_button[7]:isReleased() then
		menu_menu[6].open = not menu_menu[6].open
	end


	menu_button[5].x = 10
	menu_button[5].y = menu_button[1].y + menu_button[1].h + 5
	if menu_button[5]:isReleased() then
		menu_menu[4].open = not menu_menu[4].open
	end



	if menu_menu[1].open then
		menu_button[1].box_color = menu_button[1].box_color_on

		for i=1, #menu_menu[1].other.playlist do
			if i == playing_id then
				menu_menu[1].other.playlist[i].button.box_color = menu_menu[1].other.playlist[i].button.box_color_on
			else
				menu_menu[1].other.playlist[i].button.box_color = {r=0,g=0,b=0,a=0.2}
			end

			menu_menu[1].other.playlist[i].button.x = menu_menu[1].menu._x
			menu_menu[1].other.playlist[i].button.y = 5 + menu_menu[1].menu._y + i * 30
			menu_menu[1].other.playlist[i].button.w = menu_menu[1].menu._w
			menu_menu[1].other.playlist[i].button:draw()

			if menu_menu[1].other.playlist[i].button:isReleased() then
				playing_id = i
				load_song(menu_menu[1].other.playlist[i].path)
			end

			if i * 30 >= menu_menu[1].menu._h - 80 then break end
		end
	else
		menu_button[1].box_color = {r=0,g=0,b=0,a=0.2}
	end


	if menu_menu[2].open then
		menu_button[2].box_color = menu_button[2].box_color_on

		menu_button[3].x = menu_menu[2].menu._x + (menu_menu[2].menu._w / 2) / 2
		menu_button[3].y = menu_menu[2].menu._y + menu_menu[2].menu._h - menu_button[3].h - 3
		menu_button[3].w = menu_menu[2].menu._w / 2
		menu_button[3]:draw()

		if menu_button[3]:isReleased() then
			visualizer_list_load()
		end

		move = -10
		for id, v in pairs(final_visualizer_list_tbl) do
			move = move + 50

			SetColor(255,255,255)
			Text(id .. "/ (" .. #final_visualizer_list_tbl[id] .. ")",menu_menu[2].menu._x,menu_menu[2].menu._y + move,0,1,"font/Montserrat-Regular.ttf",15)

			local t = id .. "/ (" .. #final_visualizer_list_tbl[id] .. ")"
			local w = 0

			w = GetFont("font/Montserrat-Regular.ttf",15):getWidth(t)

			Rect("fill",menu_menu[2].menu._x,menu_menu[2].menu._y + move + 10,w,3)
			Rect("fill",menu_menu[2].menu._x + 5,menu_menu[2].menu._y + move + 15,1,#final_visualizer_list_tbl[id] * 30 - 3)

			for id2, v2 in pairs(final_visualizer_list_tbl[id]) do
				move = move + 30

				local wrap_t = menu_menu[2].other.visualizer[id][id2].button.wrap_text or {}
				local w = 0

				if #wrap_t > 0 then w = GetFont("font/Montserrat-Regular.ttf",13):getWidth(wrap_t[1]) end
				w = w + 30

				SetColor(255,255,255)
				Rect("fill",menu_menu[2].menu._x + 5,menu_menu[2].menu._y + move + 16 - 4,15,1)

				SetColor(theme_color.theme_accent)
				Rect("fill",menu_menu[2].other.visualizer[id][id2].button.x + menu_menu[2].other.visualizer[id][id2].button.w/2 - w/2,menu_menu[2].menu._y + move + 29 - 5,w,2)

				if (id .. "/" .. v2) == settings.visualizer_id then
					menu_menu[2].other.visualizer[id][id2].button.box_color = menu_menu[2].other.visualizer[id][id2].button.box_color_on
				else
					menu_menu[2].other.visualizer[id][id2].button.box_color = {r=0,g=0,b=0,a=0.2}
				end

				menu_menu[2].other.visualizer[id][id2].button.x = menu_menu[2].menu._x + 20
				menu_menu[2].other.visualizer[id][id2].button.y = menu_menu[2].menu._y + move
				menu_menu[2].other.visualizer[id][id2].button.w = menu_menu[2].menu._w - 20

				menu_menu[2].other.visualizer[id][id2].button:draw()

				if menu_menu[2].other.visualizer[id][id2].button:isReleased() then
					function on_apk_update() end
					function load_visualizer()
						SetColor(theme_color.white)
						Text(lang.get("text.load_visualizer.problem_occured"),screenX/2,screenY/2,1,1,"font/Montserrat-Regular.ttf",25)
					end
					function draw_background()
						return true
					end

					settings.visualizer_id = id .. "/" .. v2
					lf.load("" .. v2)()

					local v_settings = setup_settings()
					menu_menu[3].other.visualizer_settings = v_settings
				end

				--if move >= menu_menu[2].menu._h - 100 then break end
			end
		end
	else
		menu_button[2].box_color = {r=0,g=0,b=0,a=0.2}
	end


	if menu_menu[3].open then
		menu_button[4].box_color = menu_button[4].box_color_on

		if menu_menu[3].other.visualizer_settings and #menu_menu[3].other.visualizer_settings > 0 then
			pos = 15
			for i=1, #menu_menu[3].other.visualizer_settings do
				local me = menu_menu[3].other.visualizer_settings[i]

				if not me then return end

				if me.type == "text" then
					SetColor(theme_color.white)
					local text_data = Text(me.txt,menu_menu[3].menu._x + menu_menu[3].menu._w/2,menu_menu[3].menu._y + 30 + pos,1,1,"font/Montserrat-Regular.ttf",15)

					pos = pos + text_data.h+5
				elseif me.type == "slider" then
					SetColor(theme_color.theme_accent)
					me.obj.x = menu_menu[3].menu._x + (menu_menu[3].menu.w-10)/2
					me.obj.y = menu_menu[3].menu._y + 30 + pos
					me.obj.length = menu_menu[3].menu.w - 30

					me.obj:draw()

					SetColor(theme_color.white)
					Text(me.obj.min,menu_menu[3].menu._x + 10,menu_menu[3].menu._y + 40 + pos,0,1,"font/Montserrat-Regular.ttf",10)
					Text(me.obj.max,menu_menu[3].menu._x + menu_menu[3].menu._w - 10,menu_menu[3].menu._y + 40 + pos,2,1,"font/Montserrat-Regular.ttf",10)

					show_slider_info(me.obj,0,"","",false)

					pos = pos + 20
				elseif me.type == "button" then
					me.obj.x = menu_menu[3].menu._x
					me.obj.y = menu_menu[3].menu._y + 30 + pos
					me.obj.w = menu_menu[3].menu._w

					me.obj:draw()

					pos = pos + 30
				elseif me.type == "input" then
					me.obj.x = menu_menu[3].menu._x
					me.obj.y = menu_menu[3].menu._y + 30 + pos
					me.obj.w = menu_menu[3].menu._w

					me.obj:draw()

					pos = pos + 30
				end

				if pos >= menu_menu[3].menu._h - 60 then break end
			end
		end
	else
		menu_button[4].box_color = {r=0,g=0,b=0,a=0.2}
	end


	if menu_menu[6].open == false then
		menu_menu[5].open = false
		menu_menu[7].open = false
	end

	if menu_menu[6].open then
		menu_button[7].box_color = menu_button[7].box_color_on

		--Draw fps button
		if settings.show_fps then
			menu_button[8].box_color = menu_button[8].box_color_on
		else
			menu_button[8].box_color = {r=0,g=0,b=0,a=0.2}
		end
		menu_button[8].x = menu_menu[6].menu._x
		menu_button[8].y = 40 + menu_menu[6].menu._y
		menu_button[8].w = menu_menu[6].menu._w
		menu_button[8]:draw()
		if menu_button[8]:isReleased() then settings.show_fps = not settings.show_fps end

		--Draw lang panel
		menu_button[6].x = menu_menu[6].menu._x
		menu_button[6].y = 40 + menu_menu[6].menu._y + menu_button[8].h + 5
		menu_button[6].w = menu_menu[6].menu._w
		menu_button[6]:draw()
		if menu_button[6]:isReleased() then menu_menu[5].open = not menu_menu[5].open end

		if menu_menu[5].open then
			menu_button[6].box_color = menu_button[6].box_color_on

			for i=1, #menu_menu[5].other.lang do
				id = lang_list[i]
				if id.id == settings.lang_selected then
					menu_menu[5].other.lang[i].box_color = menu_menu[5].other.lang[i].box_color_on
				else
					menu_menu[5].other.lang[i].box_color = {r=0,g=0,b=0,a=0.2}
				end

				menu_menu[5].other.lang[i].x = menu_menu[5].menu._x
				menu_menu[5].other.lang[i].y = 10 + menu_menu[5].menu._y + i * 30
				menu_menu[5].other.lang[i].w = menu_menu[5].menu._w
				menu_menu[5].other.lang[i]:draw()

				if menu_menu[5].other.lang[i]:isReleased() then
					settings.lang_selected = id.id

					lang = load_lang(settings.lang_selected)
					reload_button_lang()
				end

				if i * 30 >= menu_menu[5].h - 100 then break end
			end
		else
			menu_button[6].box_color = {r=0,g=0,b=0,a=0.2}
		end

		--Draw equalizer
		menu_button[9].x = menu_button[6].x
		menu_button[9].y = menu_button[6].y + menu_button[6].h + 5
		menu_button[9].w = menu_menu[6].menu._w
		menu_button[9]:draw()
		if menu_button[9]:isReleased() then menu_menu[7].open = not menu_menu[7].open end

		if menu_menu[7].open then
			menu_button[9].box_color = menu_button[9].box_color_on

			SetColor(theme_color.white)
			Text("Beta", menu_menu[7].menu._x + menu_menu[7].menu._w/2, menu_menu[7].menu._y - 4,1,0,"font/Montserrat-Regular.ttf",20)

			for i=0, 6 do
				t = ""
				value = round((i/6) * 12)
				if value > 0 then t = "+" end

				SetColor(theme_color.white)
				Text(t .. value,menu_menu[7].menu._x + menu_menu[7].menu._w/2 + 15,menu_menu[7].menu._y + menu_menu[7].menu._h - 45 - (i/6) * 150,2,1,"font/Montserrat-Regular.ttf",15)

				SetColor(theme_color.theme_accent)
				Rect("fill",menu_menu[7].menu._x + menu_menu[7].menu._w/2 + 25,menu_menu[7].menu._y + menu_menu[7].menu._h - 45 - (i/6) * 150,5,1)
			end

			local curve = {}
			local curve2 = {}
			SetColor(theme_color.theme_accent)
			for i=1, #eq_slider do
				eq_slider[i].x = menu_menu[7].menu.w/2 - 30 + menu_menu[7].menu._x + (i/#eq_slider) * (menu_menu[7].menu._w / 2)
				eq_slider[i].y = menu_menu[7].menu._y + menu_menu[7].menu._h / 2

				curve[(i*2)-1] = eq_slider[i].x
				curve[(i*2)] = eq_slider[i].y + eq_slider[i].length/2 - (eq_slider[i]:getValue() / 12) * eq_slider[i].length

				eq_slider[i]:draw()

				show_slider_info(eq_slider[i],1,"+"," db")
			end

			curve2 = lma.newBezierCurve(curve)
			SetColor(theme_color.theme_accent)
			lg.line(curve2:render())

			for i=1, #freq_slider do
				SetColor(theme_color.theme_accent)
				freq_slider[i].x = menu_menu[7].menu._x + 20 + (i/#freq_slider) * (menu_menu[7].menu._w / 2 + 100)
				freq_slider[i].y = menu_menu[7].menu._y + menu_menu[7].menu._h - 5
				freq_slider[i]:draw()

				t = "low mid"
				if i==2 then t = "high mid" end

				SetColor(theme_color.white)
				Text(t .. ": " .. round(freq_slider[i]:getValue()) .. " hz",freq_slider[i].x,freq_slider[i].y - 15,1,1,"font/Montserrat-Regular.ttf",15)
			end

			SetColor(theme_color.primary)
			Rect("fill",menu_menu[7].menu._x + 25,menu_menu[7].menu._y + 45, (menu_menu[7].menu._h / 1.5),(menu_menu[7].menu._h / 1.5))

			SetColor(theme_color.theme)
			for i=1, 50 do
				local x = menu_menu[7].menu._x + 25 + -(1/50) * (menu_menu[7].menu._h / 1.5) + (i/(50-1)) * ((menu_menu[7].menu._h / 1.5) - (1/50) * (menu_menu[7].menu._h / 1.5))
				local y = menu_menu[7].menu._y + 45 + (menu_menu[7].menu._h / 1.5)

				local val = 2 + smooth_fft[round(1-(1 / 50) * 512 + (i / 50) * 512)] * ((menu_menu[7].menu._h / 1.5) * 6)

				Rect("fill",x,y,(1/50) * (menu_menu[7].menu._h / 1.5),-clamp(val,0,menu_menu[7].menu._h / 1.5))
			end
		else
			menu_button[9].box_color = {r=0,g=0,b=0,a=0.2}
		end
	else
		menu_button[7].box_color = {r=0,g=0,b=0,a=0.2}
	end


	if menu_menu[4].open then
		menu_button[5].box_color = menu_button[5].box_color_on

		for i=1, #menu_menu[4].other.palettes do
			if i == palettes.current then
				menu_menu[4].other.palettes[i].button.box_color = menu_menu[4].other.palettes[i].button.box_color_on
			else
				menu_menu[4].other.palettes[i].button.box_color = {r=0,g=0,b=0,a=0.2}
			end

			menu_menu[4].other.palettes[i].button.x = menu_menu[4].menu._x
			menu_menu[4].other.palettes[i].button.y = 10 + menu_menu[4].menu._y + i * 30
			menu_menu[4].other.palettes[i].button.w = menu_menu[4].menu._w

			menu_menu[4].other.palettes[i].button:draw()

			if menu_menu[4].other.palettes[i].button:isReleased() then
				palettes.current = i
			end

			if i * 30 >= menu_menu[4].menu.h - 100 then break end
		end
	else
		menu_button[5].box_color = {r=0,g=0,b=0,a=0.2}
	end

	------------------------------------------------------------

	if settings.show_fps then
		if lt.getFPS() >= 40 then SetColor(0, 1, 0) end
		if lt.getFPS() <= 40 then SetColor(1, .5, .2) end
		if lt.getFPS() <= 20 then SetColor(1, 0, 0) end
		Text(lang.get("text.fps_label") .. lt.getFPS() .. " (" .. round(lt.getDelta() * 1000) .. " ms)",10,10,0,0,"font/Montserrat-Regular.ttf",15)
	end

	SetColor(0.6,0.5,0.5)
	Text(lang.get("dev.info.important"),screenX/2,10,1,0,"font/Montserrat-Regular.ttf",15)

	if menu_input.open then
		if input_panel.question then
			if input_panel.question.input then
				input = function_input_menu()
				if input.continue then
					print("Import has background")
				elseif input.cancel then
					print("Import has album cover")
				end
			else
				input = function_input_menu()
				if input.continue then
					print("Answer: "..input.value)
				elseif input.cancel then
					print("Canceled")
				end
			end
		elseif input_panel.changelog then
			function_changelog_menu()
		end
	end

	--[[
	move = 0
	b_id = 0
	for id, v in pairs(final_visualizer_list_tbl) do
		move = move + 40
		Text(id .. "/ (" .. #final_visualizer_list_tbl[id] .. ")",50,move,0,1,"font/Montserrat-Regular.ttf",15)

		for id2, v2 in pairs(final_visualizer_list_tbl[id]) do
			b_id = b_id + 1
			move = move + 25

			if b_id == settings.visualizer_id then
				menu_menu[2].other.visualizer[id][id2].button.box_color = menu_menu[2].other.visualizer[id][id2].button.box_color_on
			else
				menu_menu[2].other.visualizer[id][id2].button.box_color = {r=0,g=0,b=0,a=0.2}
			end
	
			menu_menu[2].other.visualizer[id][id2].button.x = 70
			menu_menu[2].other.visualizer[id][id2].button.y = move - 5
			menu_menu[2].other.visualizer[id][id2].button.w = 300

			menu_menu[2].other.visualizer[id][id2].button:update()
			menu_menu[2].other.visualizer[id][id2].button:draw()

			if menu_menu[2].other.visualizer[id][id2].button:isReleased() then
				function on_apk_update() end
				function load_visualizer()
					SetColor(theme_color.white)
					Text(lang.get("text.load_visualizer.problem_occured"),screenX/2,screenY/2,1,1,"font/Montserrat-Regular.ttf",25)
				end
				function draw_background()
					return true
				end

				settings.visualizer_id = b_id
				lf.load("" .. v2)()

				local v_settings = setup_settings()

				menu_menu[3].other.visualizer_settings = v_settings
			end

			if move >= menu_menu[2].menu._h - 100 then break end
		end
	end
	]]

	--[[
	move = 0
	for id, v in pairs(final_playlist_tbl) do
		move = move + 20
		Text(id .. "/ (" .. #final_playlist_tbl[id] .. ")",350,move,0,1,"font/Montserrat-Regular.ttf",15)

		for id2, v2 in pairs(final_playlist_tbl[id]) do
			move = move + 20
			Text(v2:getFilename(),370,move,0,1,"font/Montserrat-Regular.ttf",15)
		end
	end
	]]
end