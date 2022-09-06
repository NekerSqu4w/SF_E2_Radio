--A custom math lib made by AstalNeker

local chg = {}

local lt = love.timer
local lm = love.math

function round(n, deci) deci = 10^(deci or 0) return math.floor(n*deci+.5)/deci end
function lerp(a,b,t) return b+(t-b)*a end

function setup_changed(id,default)
	chg[id] = default
end

function changed(id,value)
	if not chg[id] == value then
		chg[id] = value
		on = true
	else
		on = false
	end
	return on
end

function dir(x1,y1,x2,y2) return math.atan2(y2-y1, x2-x1) end

function smoothstep(edge0, edge1, x)
	x = clamp((x - edge0) / (edge1 - edge0), 0, 1);
	return x * x * x * (x * (x * 6 - 15) + 10);
end

function table_max(tbl)
	local max = 0
	local index = 0

	tbl = tbl or {}

	for x=1, #tbl do
		if tbl[x] > max then
			max = tbl[x]
			index = x
		end
	end

	return max, index
end

function Color(r,g,b,a)
	local r = r or 1
	local g = g or 1
	local b = b or 1
	local a = a or 1
	return {r=r,g=g,b=b,a=a}
end

function lerpColor(a2,b2,t2)
	b2 = b2 or Color(1,1,1,1)
	t2 = t2 or Color(1,1,1,1)

	b2.r = b2.r or 0
	b2.g = b2.g or 0
	b2.b = b2.b or 0
	b2.a = b2.a or 0

	t2.r = t2.r or 0
	t2.g = t2.g or 0
	t2.b = t2.b or 0
	t2.a = t2.a or 0

	r = b2.r+(t2.r-b2.r)*a2
	g = b2.g+(t2.g-b2.g)*a2
	b = b2.b+(t2.b-b2.b)*a2
	a = b2.a+(t2.a-b2.a)*a2

	return Color(r,g,b,a)
end

function lerpVector(a3,b3,t3)
	b3 = b3 or Vector(0,0,0)
	t3 = t3 or Vector(0,0,0)

	b3.x = b3.x or 0
	b3.y = b3.y or 0
	b3.z = b3.z or 0

	t3.x = t3.x or 0
	t3.y = t3.y or 0
	t3.z = t3.z or 0

	x = b3.x+(t3.x-b3.x)*a3
	y = b3.y+(t3.y-b3.y)*a3
	z = b3.z+(t3.z-b3.z)*a3

	return Vector(x,y,z)
end

function mix_2_color(use,mix_color,mix_color2,mix_ratio)
	local mix_color = mix_color or Color(1,0,0,1)
	local mix_color2 = mix_color2 or Color(0,0,1,1)
	local mix_final_color =  Color(0,0,0,1)
	local use = use or "old"

	mix_color.r = mix_color.r or 1
	mix_color.g = mix_color.g or 1
	mix_color.b = mix_color.b or 1
	mix_color.a = mix_color.a or 1

	mix_color2.r = mix_color2.r or 1
	mix_color2.g = mix_color2.g or 1
	mix_color2.b = mix_color2.b or 1
	mix_color2.a = mix_color2.a or 1

	if use == "new" then
		h,s,v = rgbToHSV(mix_color.r, mix_color.g, mix_color.b)
		h2,s2,v2 = rgbToHSV(mix_color2.r, mix_color2.g, mix_color2.b)
		mix = hsvToRGB(h + (h2 - h) * mix_ratio,s + (s2 - s) * mix_ratio,v + (v2 - v) * mix_ratio)

		mix_final_color.r = mix.r or mix_color.r
		mix_final_color.g = mix.g or mix_color.g
		mix_final_color.b = mix.b or mix_color.b
		mix_final_color.a = mix_color.a + (mix_color2.a - mix_color.a) * mix_ratio
	elseif use == "old" then
		mix_final_color.r = mix_color.r + (mix_color2.r - mix_color.r) * mix_ratio
		mix_final_color.g = mix_color.g + (mix_color2.g - mix_color.g) * mix_ratio
		mix_final_color.b = mix_color.b + (mix_color2.b - mix_color.b) * mix_ratio
		mix_final_color.a = mix_color.a + (mix_color2.a - mix_color.a) * mix_ratio
	end

	return mix_final_color
end

function clamp(n, low, high) return math.min(math.max(low, n), high) end
function boolToNum(value) if value == true then return 1 elseif value == false then return 0 end end

function hsvToRGB(h,s,v)
	local h = h % 360
	local r,g,b
	local x,y,z
	if s==0 then
		r=v;g=v;b=v
	else
		h=h/60
		i=math.floor(h)
		f=h-i
		x=v*(1-s)
		y=v*(1-s*f)
		z=v*(1-s*(1-f))
	end		
	if i==0 then
		r=v;g=z;b=x
	elseif i==1 then
		r=y;g=v;b=x
	elseif i==2 then
		r=x;g=v;b=z
	elseif i==3 then
		r=x;g=y;b=v
	elseif i==4 then
		r=z;g=x;b=v
	elseif i==5 then
		r=v;g=x;b=y
	else
		r=v;g=z;b=x
	end
	return {r=r,g=g,b=b}
end

function rgbToHSV(r, g, b)
	local h, s, v
	local r = r
	local g = g
	local b = b
	
	local maxColor = math.max(r, g, b)
	local minColor = math.min(r, g, b)
	
	local difference = maxColor - minColor
	
	if r == maxColor then
		h = (60 * ((g - b)/difference) + 360) % 360;
	elseif g == maxColor then
		h = (60 * ((b - r)/difference) + 120) % 360;
	elseif b == maxColor then
		h = (60 * ((r - g)/difference) + 240) % 360;
	else
		h = 0
	end
	
	if maxColor == 0 then
		s = 0
	else
		s = (difference/maxColor);
	end
	
	v = maxColor;
	
	return math.ceil(h), round(s,1), round(v,1)
end

function random(min,max)
	local min = min or 0
	local max = max or 100
	local percent = min+lm.random()*(max-min);
	return percent
end

function nice_time(time)
	local h = math.floor(time / 3600)
	local m = math.floor(time / 60)
  	local s = math.floor(time % 60)

	local mt = ""
	local ht = ""
	if m > 9 then mt = "0" end
	if h > 9 then ht = "0" end

	local formated_time = string.format("%02d",s)
	if m > 0 then formated_time = string.format("%"..mt.."2d:%02d",m,s) end
	if h > 0 then formated_time = string.format("%"..ht.."2d:%02d:%02d",h,m,s) end

	return formated_time
end

function dayname(num)
	local t = ""..num
	return t:gsub("0",""):gsub("1","Janvier"):gsub("2","Février"):gsub("3","Mars"):gsub("4","Avril"):gsub("5","Mai"):gsub("6","Juin"):gsub("7","Juillet"):gsub("8","Août"):gsub("9","Septembre"):gsub("10","Octobre"):gsub("11","Novembre"):gsub("12","Décembre")
end

function string.explode(str, div)
    assert(type(str) == "string" and type(div) == "string", "invalid arguments")
    local o = {}
    while true do
        local pos1,pos2 = str:find(div)
        if not pos1 then
            o[#o+1] = str
            break
        end
        o[#o+1],str = str:sub(1,pos1-1),str:sub(pos2+1)
    end
    return o
end

---------------------------    Prototype     ----------------------------------
local spacing = 1
function decode(tbl)
	local data = '{\n'
	local space = ''

	for i=1, spacing do
		space = space .. '\t'
	end

	if #tbl > 0 then
		for _, i in pairs(tbl) do
			if tostring(i):find('Font:') then
				data = data .. '"' .. space .. _ .. '": "User data cannot be readed..",\n'
			elseif tostring(i):find('table:') then
				spacing = spacing + 1
				data = data .. space .. '"' .. _ .. '": ' .. decode(i) .. space .. '},\n'
			else
				data = data .. space .. '"' .. _ .. '": "' .. tostring(i) .. '"\n'
			end
		end
	else
	end

	spacing = 1
	return data
end

function table_to_string(tbl)
	return decode(tbl) .. '}'
end
---------------------------------------------------------------------------