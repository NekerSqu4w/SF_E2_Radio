
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
require("..lib/particle")
------------------------------------------

--Custom variable
local lang = {}

lang.en = {}
lang.en.s_title = "Song title.."
lang.en.s_author = "Song author.."
lang.en.s_album = "Album names.."
lang.en.s_sub = "SUBSCRIBED"
lang.en.s_nosub = "SUBSCRIBE"

lang.fr = {}
lang.fr.s_title = "Titre de la chanson.."
lang.fr.s_author = "Auteur de la chanson.."
lang.fr.s_album = "Noms de l'album.."
lang.fr.s_sub = "ABONNÉ"
lang.fr.s_nosub = "S'ABONNER"

lang.ge = {}
lang.ge.s_title = "Titel des Liedes.."
lang.ge.s_author = "Songschreiber.."
lang.ge.s_album = "Albumnamen.."
lang.ge.s_sub = "TEILNEHMER"
lang.ge.s_nosub = "ABONNIEREN"


--local logo = lg.newImage("img/astmp3-logo-new.png")
local logo = lg.newImage("img/astal_logo.png")
local like1 = lg.newImage("img/like_unactive.png")
local like2 = lg.newImage("img/like_active.png")
local particle_img = lg.newImage("img/particle.png")

local particle = {}
local graph = {}
local old_info = {}
local interface = {}

local move_x = 0
local move_y = 0
local rotate = 0

local pul = 0

local v = {}
v.black_out = 0

local function func_info(x,y,data)
	--Album cover ?
	--SetColor(1,1,1,1)
	--Rect("fill",x,y - 10,90 + 20,90 + 20)
	--Image(x,y - 10,90 + 20,90 + 20,0,logo)

	SetColor(1,1,1)
	Text(data.title,x + 90,y - 30,0,0,"font/Montserrat-Regular.ttf",30)
	Text(data.author,x + 90,y + 35 - 30,0,0,"font/Montserrat-Regular.ttf",20)
	Text(data.album,x + 90,y + 60 - 30,0,0,"font/Montserrat-Regular.ttf",20)

	Text(nice_time(data.time) .. "/" .. nice_time(data.duration),x + 90+30,y + 70,0,0,"font/Montserrat-Regular.ttf",17)

	SetColor(theme_color.theme_accent.r,theme_color.theme_accent.g,theme_color.theme_accent.b,0.2)
	Rect("fill",x + 90+30,y + 100,200,4,2)

	SetColor(theme_color.theme_accent)
	Rect("fill",x + 90+30,y + 100,(data.time/data.duration) * 200,4,2)
	lg.circle("fill", x + 90+30 + 2 + (data.time/data.duration) * 200,y + 100 + 2, 6)
end

local sub = {}
sub.show = 0
sub.color_anim = 0
local function func_sub(time,start_time,x,y)
	time = time or 0
	start_time = start_time or -1

	if time >= 0 and time <= start_time-1 then
		--Reset anim data
		sub.show = 0
		sub.color_anim = 0
	end

	if time >= start_time then
		--Do anim
		sub.show = clamp(time - start_time,0,1)
		sub.color_anim = clamp((time - start_time - 2) * 2,0,1)

		if time-4 >= start_time then
			sub.show = 1 - clamp((time - start_time - 5) * 2,0,1)
			sub.color_anim = sub.show
		end

		--Show interface
		if time-4 >= start_time then
			SetColor(1,0.15,0.15,sub.show * 0.5)
		else
			SetColor(0.3 + sub.color_anim * 0.7,0.3 - sub.color_anim * 0.15,0.3 - sub.color_anim * 0.15,sub.show * 0.5)
		end
		RoundRect("fill",x,y,230,55,20)

		--Switch between two text
		SetColor(1,1,1,sub.show - sub.color_anim)
		Text(lang[settings.lang_selected].s_nosub,x + 230/2 + 20,y + 55/2 - 2,1,1,"font/Montserrat-Regular.ttf",25)

		SetColor(1,1,1,sub.color_anim)
		Text(lang[settings.lang_selected].s_sub,x + 230/2 + 20,y + 55/2 - 2,1,1,"font/Montserrat-Regular.ttf",25)

		SetColor(1,1,1,sub.show)
		Image(x + 20,y + 10,35,35,0,play_img)
	end
end


local like = {}
like.show = 0
like.color_anim = 0
local function func_like(time,start_time,x,y)
	time = time or 0
	start_time = start_time or -1

	if time >= 0 and time <= start_time-1 then
		--Reset anim data
		like.show = 0
		like.color_anim = 0
	end

	if time >= start_time then
		--Do anim
		like.show = clamp(time - start_time,0,1)
		like.color_anim = clamp((time - start_time - 2) * 2,0,1)

		if time-4 >= start_time then
			like.show = 1 - clamp((time - start_time - 5) * 2,0,1)
			like.color_anim = like.show
		end

		--Show interface
		SetColor(0.3,0.3,0.3,like.show * 0.5)
		RoundRect("fill",x,y,120,55,20)

		--Switch between two logo
		SetColor(0.3,0.3,0.3,like.show - like.color_anim)
		Image(x + 120/2 - 35/2,y + 10,35,35,0,like1)

		SetColor(0.15,0.4,0.7,like.color_anim)
		Image(x + 120/2 - 35/2,y + 10,35,35,0,like2)
	end
end


interface.info = func_info
interface.subscribe = func_sub
interface.like = func_like
-------------------------------

function star_particle(particle,speed)
	for id, p in pairs(particle) do
        if (lt.getTime() - p.spawn_at) >= p.die_time then table.remove(particle,id) end
        if not p then return end
        ds = (lt.getTime() - p.spawn_at) / p.die_time

        if p.pos.x <= (p.current_size/4) or p.pos.x >= (ScrW()-p.current_size/4) then
        else
            --p.pos.x = p.pos.x + p.vel.x
        end
        if p.pos.y <= (p.current_size/4) or p.pos.y >= (ScrH()-p.current_size/4) then
        else
            --p.pos.y = p.pos.y + p.vel.y
        end

        p.pos.x = p.pos.x + p.vel.x * speed
        p.pos.y = p.pos.y + p.vel.y * speed

        --Reduce velocity
        p.vel.x = p.vel.x/p.air_resistance
        p.vel.y = p.vel.y/p.air_resistance

        --Up gravity
        p.vel.x = p.vel.x + p.gravity.x
        p.vel.y = p.vel.y + p.gravity.y

		--Randomise velocity
		p.vel.x = p.vel.x + random(-0.3,0.3)/2
		p.vel.y = p.vel.y + random(-0.3,0.3)/2

        --Change particle size and ang
        p.current_size = p.size_start + ds * (p.size_end - p.size_start)
        p.current_ang = p.ang_start + ds * (p.ang_end - p.ang_start)

        SetColor(mix_2_color("old",p.color1,p.color2,ds))
    	Image(p.pos.x - p.current_size/2,p.pos.y - p.current_size/2,p.current_size,p.current_size,p.current_ang,particle_img)
    end
end

function draw_background()
	return true
end
function setup_settings()
	reset()

	text("Song info:")
	title_input = input(lang[settings.lang_selected].s_title)
	author_input = input(lang[settings.lang_selected].s_author)
	album_input = input(lang[settings.lang_selected].s_album)

	text("")
	text("Visualizer settings:")
	text("")
	text("Decay:")
    sli3 = slider(0,100,0.02*100)

	text("Sensivity mult:")
    sli2 = slider(0.2,10,1)

	text("Curve detail:")
    sli = slider(20,512,130)

	title_input.current_answer = "A visualizer"
	author_input.current_answer = "by AstalNeker"
	album_input.current_answer = "From the apk AstMP3"

	return return_obj_settings()
end

function on_apk_update(dt)
end

function load_visualizer(data)
	--Here you can see a list of default data can be get on the 'data' table
    smooth_fft = data.smooth_fft
	left_channel = data.left_channel
	right_channel = data.right_channel
	mono_channel = data.mono_channel --Or just use > (left_channel + right_channel) * 0.5
    screenX = data.screen_size.w
    screenY = data.screen_size.h
    palettes = data.palettes
	info = data.song_info --To get the original title, author, album, duration, and time of the mp3 file
	-------------------------------

	if info.name == old_info then
	else
		if title_input and author_input and album_input then
			title_input.current_answer = info.name.title
			author_input.current_answer = info.name.author
			album_input.current_answer = info.name.album.album_name
		end

		old_info = info.name
	end

	if not sli then return end
	if not sli2 then return end

	num = sli:getValue()
	num = round(num/5)*5

	pul = lerp(0.1,pul,pulse * 20)
	bass = (bassfft/5) * sli2:getValue() * (1 + pul/2)

	center = {}
	--[[
	move_x = lerp(0.2,move_x,math.cos(random(0,math.pi*2)) * bass/8)
	move_y = lerp(0.2,move_y,math.sin(random(0,math.pi*2)) * bass/8)
	rotate = lerp(0.1,rotate,random(-bass,bass))

	center.x = screenX/2 + move_x
	center.y = screenY/2 + move_y
	]]

	rotate = 0
	center.x = screenX/2
	center.y = screenY/2

	local graph = {}
	local r = (bass/2 + screenY/4)/2 + 5 + (smooth_fft[1] * screenY/1.5) * sli2:getValue()
	graph[1] = {0,0,0,-r,0,-r}
	graph[2] = {graph[1][1],graph[1][2],graph[1][3],graph[1][4],graph[1][5],graph[1][6]}

	if ff_val2 then else ff_val2 = {} end

	for i=0, num-1 do
		ff_val = smooth_fft[1 + round((i/num) * 35)]
		val = 0

		if ff_val >= (sli3:getValue()/100) then
			val = ff_val
		end

		ff_val2[1 + i] = lerp(0.4,(ff_val2[1 + i] or 0),val)
		--if i > num-2 then ff_val2[1 + i] = 0 end

		local r = (bass/2 + screenY/4)/2 + 5 + (ff_val2[1 + i] * screenY/1.5) * sli2:getValue()
        local theta = ((i-1)/(num-2)) * math.pi

		graph[1][#graph[1]+1] = r*math.sin(theta + math.pi)
		graph[1][#graph[1]+1] = r*math.cos(theta + math.pi)
		graph[2][#graph[2]+1] = r*math.sin(-theta + math.pi)
		graph[2][#graph[2]+1] = r*math.cos(-theta + math.pi)
	end

	graph[1] = lma.newBezierCurve(graph[1])
	graph[2] = lma.newBezierCurve(graph[2])


	if #particle < 500 then
		for i=1, 3 do
			local vel = {}
			local pos = {}

			ratio_x = random(-1,1)/2
			ratio_y = random(-1,1)/2
			vel.x = ratio_x * 10
			vel.y = ratio_y * 10

			pos.x = (0.5 + ratio_x) * ScrW()
			pos.y = (0.5 + ratio_y) * ScrH()

			r,g,b = palettes.color[round(random(1,#palettes.color))].r/255,palettes.color[round(random(1,#palettes.color))].g/255,palettes.color[round(random(1,#palettes.color))].b/255

			np = NewParticle(pos,vel,random(2,3),{start=1,_end=35},{start=0,_end=0},{x=0,y=0},1.0007,Color(r,g,b,1),Color(0,0,0,0))
			table.insert(particle,np)
		end
    end
	star_particle(particle,1 + bass/30)

	local total = #palettes.color
	for i=1, total do
		lg.push()
		lg.translate(center.x,center.y)
		lg.scale(1.2 - (i/total) * 0.2, 1.2 - (i/total) * 0.2)

		local r,g,b = palettes.color[i].r / 255,palettes.color[i].g / 255,palettes.color[i].b / 255

		SetColor(r, g, b)
		lg.polygon("fill", graph[1]:render(1))
		lg.polygon("fill", graph[2]:render(1))

		lg.pop()
	end


	--To round the logo
	local function stencil()
        SetColor(1,1,1,1)
        lg.circle("fill", center.x, center.y, (bass/2 + screenY/4)/2)
    end
    lg.stencil(stencil, "replace")
    lg.setStencilTest("greater", 0)
    SetColor(1,1,1)
	Image(center.x - (bass/2 + screenY/4)/2, center.y - (bass/2 + screenY/4)/2, bass/2 + screenY/4 ,bass/2 + screenY/4, (rotate/600) * (360/(math.pi*2)), logo)
    lg.setStencilTest()

	--[[
	for i=1, 50 do
		Rect("fill",200+90+30 + 3 - (1/30)*118 + (i/30) * 118,screenY - 200 + 4,2,2 + (smooth_fft[i] * sli2:getValue()) * 350)
	end
	]]

	if author_input and title_input and album_input then
		interface.info(200,screenY - 300,{
			author = author_input:getInput(),
			album = album_input:getInput(),
			title = title_input:getInput(),
			album_cover = info.name.album.album_cover,
			time = info.time.time,
			duration = info.time.duration
		})

		title_input.txt = lang[settings.lang_selected].s_title
		author_input.txt = lang[settings.lang_selected].s_author
		album_input.txt = lang[settings.lang_selected].s_album

		title_input.default_text = title_input.txt
		author_input.default_text = author_input.txt
		album_input.default_text = album_input.txt
	end

	interface.subscribe(info.time.time,12-5,screenX - 350,screenY - 200)
	interface.like(info.time.time,19-5,screenX - 350 + (190-120)/2,screenY - 200)

	--Draw black overlay on start and end
	v.black_out = clamp(info.time.time / 4,0,1)
	if info.time.time >= info.time.duration-7 then v.black_out = 1 - clamp((info.time.time - info.time.duration + 7) / 6,0,1) end

	SetColor(0,0,0,1 - v.black_out)
	Rect("fill",0,0,screenX,screenY)
end