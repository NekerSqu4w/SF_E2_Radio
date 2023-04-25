--@name FFT Reactiv
--@author AstalNeker

//own library
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/retro_screen.txt as retro_screen.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/multiple_screen_lib.txt as multiple_screen_lib.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/permission_handler.txt as permission_handler.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/uuid.txt as uuid.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/loader.lua as loader.lua

//gui library
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/sfui.lua as sfui.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/component.lua as components/component.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/window.lua as components/window.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/button.lua as components/button.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/list.lua as components/list.lua


if CLIENT then
    local retro_screen = require("retro_screen.txt")
    local msl = require("multiple_screen_lib.txt")
    local permission = require("permission_handler.txt")

    require("sfui.lua")
    require("components/component.lua")
    require("components/window.lua")
    require("components/button.lua")
    require("components/list.lua")

    local song_loader = require("loader.lua")
    local playlist = {}

    local track = 1
    local list = "mp3"
    local ui_color = Color(70,255,255)
    
    SFUi.static.palette = {
        foreground = Color(255, 255, 255),
        background = Color(30, 30, 30),
        hover = Color(75, 75, 75),
        component = Color(45, 45, 45),
        contrast = Color(60, 60, 60),
        highlight = ui_color
    }


    local buffers = {"rt", "rt2"}
    local buffernum = 1
    render.createRenderTarget("rt")
    render.createRenderTarget("rt2")

    local fft = {}
    local fft2 = {}
    local smooth_fft = {}

    local bassVal = 0
    local bassfft = 0
    local currentSnd = nil
    local waitingNextSong = true
    
    
    local guiButton = {}
    local guiList = {}
    
    local max = 0
    function math.maxt(tbl,min,limit)
        for x=min, limit do
            for y=min, limit do
                if (tbl[x] or 0) > (tbl[y] or 0) then
                    max = (tbl[x] or 0)
                elseif (tbl[x] or 0) < (tbl[y] or 0) then
                    max = (tbl[y] or 0)
                end
            end
        end
        
        return max
    end
    
    local bassVal = 0
    function getBass(snd,smooth)
        local ft = snd:getFFT(4)
        if snd.playing then
            bassVal = math.lerp(timer.frametime() * smooth,bassVal,math.maxt(ft,3,9))
        else  
            bassVal = math.lerp(timer.frametime() * smooth,bassVal,0)
        end
        return bassVal
    end
    
    local volume_multiplier = 1

    
    local coverBufferGenerated = true
    local coverInfo = {}
    coverInfo.realSize = Vector(0,0)
    coverInfo.realPos = Vector(0,0)
    function load_audio(data)
        guiList.list.value = track
        if currentSnd then currentSnd:pause() end
        cover:setTextureURL("$basetexture",data.playlist[list][track].cover or data.data.no_background[math.random(1,#data.data.no_background)],function(_,_,w,h,layout)
            //fix size to 1024x1024 depending of proportion
            local fw, fh = w or 1024, h or 1024
            local scl = 1
    
            scl = 1024 / fh
            if fh > fw then scl = 1024 / fw end
            fw = fw * scl
            fh = fh * scl
            
            coverInfo.realPos = Vector(512 - fw/2,512 - fh/2)
            coverInfo.realSize = Vector(fw,fh)
            
            layout(512 - fw/2,512 - fh/2,fw,fh)
        end,
        function() coverBufferGenerated = false end)

        local WAITINGSTOP = currentSnd
        bass.loadURL(data.playlist[list][track].link, "3d noblock", function(snd)
            if snd then
                currentSnd = snd
                
                //add metadata
                currentSnd.volume = 1
                currentSnd.playing = true
                currentSnd.hasFinishToggle = true
                currentSnd.VOLUMEBEFORETRANSITION = currentSnd.volume

                waitingNextSong = false

                //write custom use function
                    
                function currentSnd:toggle(forceToggle)
                    local id = timer.curtime()
                    if self then else return end
                    if self.hasFinishToggle then else return end
                    if self.playing || forceToggle == false then
                        //do pause transition
                        self.VOLUMEBEFORETRANSITION = self.volume
                        self.hasFinishToggle = false
                        self.playing = false

                        timer.create("LOOPSOUNDVOLUME_"..id,0,0,function()
                            if self then
                                self.volume = math.lerp(timer.frametime() * 10,self.volume,0)
                                self:setVolume(self.volume)

                                if self.volume <= 0.02 then
                                    self:pause()
                                    self.hasFinishToggle = true
                                    timer.stop("LOOPSOUNDVOLUME_"..id)
                                end
                            else
                                timer.stop("LOOPSOUNDVOLUME_"..id)
                            end
                        end)
 
                    elseif self.playing == false || forceToggle == true then
                        //do play transition
                        self.hasFinishToggle = false
                        self.playing = true
                        self:play()

                        timer.create("LOOPSOUNDVOLUME_"..id,0,0,function()
                            if self then
                                self.volume = math.lerp(timer.frametime() * 10,self.volume,self.VOLUMEBEFORETRANSITION)
                                self:setVolume(self.volume)
            
                                if self.volume >= self.VOLUMEBEFORETRANSITION - 0.02 then
                                    self.hasFinishToggle = true
                                    timer.stop("LOOPSOUNDVOLUME_"..id)
                                end
                            else
                                timer.stop("LOOPSOUNDVOLUME_"..id)
                            end
                        end)
                    end
                end

                function currentSnd:setVolume2(vol)
                    self.volume = vol
                    self:setVolume(vol)
                end

                if WAITINGSTOP then WAITINGSTOP:stop() end
            end
        end)
    end

    function on_load(data)
        table.sort(data.playlist[list], function(a,b)
            if a.title < b.title then
                return b
            end
        end)

        local font = render.createFont("FontAwesome",15,0)
        local font2 = render.createFont("FontAwesome",35,0)
        local listFont = render.createFont("FontAwesome",15,0)

        cover = material.create("UnlitGeneric")
        render.createRenderTarget("coverBuffer")

        local mainGui = SFUi:new()
        guiButton.prev = SFUi.button(nil, Vector(10, 512 - 90), Vector(20, 20), "|<", function()
            track = track - 1
            if track < 1 then track = #data.playlist[list] end
            if waitingNextSong == false then
                load_audio(data)
                waitingNextSong = true
            end
        end)
        guiButton.pause = SFUi.button(nil, Vector(guiButton.prev.pos.x + guiButton.prev.size.x+5, guiButton.prev.pos.y), Vector(40, 20), "Pause", function()
            currentSnd:toggle()
        end)
        guiButton.next = SFUi.button(nil, Vector(guiButton.pause.pos.x + guiButton.pause.size.x+5, guiButton.prev.pos.y), Vector(20, 20), ">|", function()
            track = track + 1
            if track > #data.playlist[list] then track = 1 end
            if waitingNextSong == false then
                load_audio(data)
                waitingNextSong = true
            end
        end)
        mainGui:addComponent(guiButton.prev)
        mainGui:addComponent(guiButton.next)
        mainGui:addComponent(guiButton.pause)

        local songListGui = SFUi:new()
        local formatedList = {}
        for key, data in pairs(data.playlist[list]) do formatedList[key] = "#" .. key .. "> " .. data.title end

        guiList.list = SFUi.list(nil, Vector(0, 15), Vector(512, 512-15), "Song list", formatedList, function(id)
            if waitingNextSong == false then
                track = id
                load_audio(data)
                waitingNextSong = true
            end
        end)  
        songListGui:addComponent(guiList.list)
        guiList.list.value = track

        hook.add("render","",function()
            msl.update()
            if currentSnd then
                currentSnd:setPos(chip():getPos())
                
                if currentSnd.playing then
                    guiButton.pause.text = "Pause"
                else
                    guiButton.pause.text = "Play"
                end
            end

            if coverBufferGenerated == false then
                render.selectRenderTarget("coverBuffer")
                render.clear()
                
                render.setColor(Color(255, 255, 255))
                render.setMaterial(cover)
                render.drawTexturedRect(-1024/2, -1024/2, 1024*2, 1024*2)
                render.setMaterial()
                render.drawBlurEffect(12,12,1)

                render.selectRenderTarget()

                coverBufferGenerated = true
            end
        end)

        hook.add("ms_render1","",function()
            local width, height = render.getResolution()
            
            local track_ = data.playlist[list][track]
            local url = track_.link
            local title = track_.title
            local author = track_.author
            local album = track_.album

            if currentSnd then
                fft = currentSnd:getFFT(1)
                fft2 = currentSnd:getFFT(4)

                bassfft = getBass(currentSnd,10) * volume_multiplier

                local left,right = currentSnd:getLevels()
                left = left * volume_multiplier
                right = right * volume_multiplier
                local mono = (left+right)/2
    
                if bassfft <= 0.1 then
                    volume_multiplier = volume_multiplier + 0.2
                end
    
                if bassfft >= 0.9 then
                    volume_multiplier = volume_multiplier - 0.2
                end
            end

            volume_multiplier = 10
            if currentSnd then
                duration = currentSnd:getLength()
                time = currentSnd:getTime()

                if time >= duration and list == "mp3" and waitingNextSong == false then
                    track = math.random(1,#data.playlist[list])
                    load_audio(data)
                    waitingNextSong = true
                end
            else
                duration = 0
                time = 0
            end

            render.setFont(font)
            local nextbuffer = (buffernum%#buffers)+1
            render.setRenderTargetTexture(buffers[buffernum])
            render.selectRenderTarget(buffers[nextbuffer])
            render.clear(Color(0,0,0,255))

            render.setColor(Color(255, 255, 255, 180))
            render.drawTexturedRect(-8/4, -8/4, 1024+8, 1024+8)
    
            render.setColor(Color(255, 255, 255, 60))
            render.drawTexturedRect(0, 0, 1024, 1024)

            local m = Matrix()
            m:rotate(Angle(0,45,0))
            m:setTranslation(Vector(256,256,0))
                        
            render.pushMatrix(m)
            render.drawTexturedRect(-256, -256, 1024, 1024)
            render.popMatrix()
 
            render.setColor(Color(255,255,255))
            num = 100
            for i=1, bassfft*15 do
                render.setColor(Color((i / (bassfft*15)) * 360,1,1):hsvToRGB())
                render.drawRect(math.random(1,512),math.random(1,512),1,1)
            end
            
            for i=1, num do
                smooth_fft[i] = math.lerp(timer.frametime()*10,smooth_fft[i] or 0, fft2[i] or 0)
    
                r = 100 + bassfft*60 + smooth_fft[i] * 150
                r2 = 100 + bassfft*60 + (smooth_fft[i-1] or smooth_fft[num] or 0) * 150
                x,y = math.cos((i/num) * (math.pi*2)) * r,math.sin((i/num) * (math.pi*2)) * r
                lx,ly = math.cos(((i-1)/num) * (math.pi*2)) * r2,math.sin(((i-1)/num) * (math.pi*2)) * r2

                render.setColor(Color((i / num) * 360 + bassfft/2 * 230,1,1):hsvToRGB())
                render.drawLine(256+x,256+y,256+lx,256+ly)
    
    
                r = 100 - bassfft*60 - smooth_fft[i] * 150
                r2 = 100 - bassfft*60 - (smooth_fft[i-1] or smooth_fft[num] or 0) * 150
                x,y = math.cos((i/num) * (math.pi*2)) * r,math.sin((i/num) * (math.pi*2)) * r
                lx,ly = math.cos(((i-1)/num) * (math.pi*2)) * r2,math.sin(((i-1)/num) * (math.pi*2)) * r2
    
                render.setColor(Color((i / num) * 360 + bassfft/2 * 230,1,1):hsvToRGB())
                render.drawLine(256+x,256+y,256+lx,256+ly)
            end
    
            render.selectRenderTarget(nil)

            retro_screen.push()
            render.setColor(Color(255,255,255))
            render.setRenderTargetTexture(buffers[nextbuffer])
            render.drawTexturedRect(width/2 - 1024/4,0,1024,1024)
            retro_screen.pop()
                        
            buffernum = nextbuffer

            retro_screen.draw(512,512,false)


            //interface element 
            render.setColor(Color(255, 255, 255))
            render.setRenderTargetTexture("coverBuffer")
            render.drawTexturedRect(5, 512 - 65, 60, 60)
            render.setRenderTargetTexture()

            render.setColor(Color(255, 255, 255))
            render.setMaterial(cover)
            render.drawTexturedRect(5 + 4, 512 - 65 + 4, 60 - 8, 60 - 8)
            render.setMaterial()

            render.setColor(Color(80,80,80))
            if duration < 0 then render.setColor(ui_color) end
            render.drawRect(10 + 60,height - 15,width - 75,10)

            if duration < 0 then
                render.setColor(ui_color)
                render.drawFilledCircle(width-40,height-27,5)
    
                render.setColor(Color(255,255,255))
                render.drawSimpleText(width - 10 ,height - 35,"Live",2,0) 
            else
                render.setColor(ui_color)
                render.drawRect(10 + 60,height - 15,(time/duration) * (width - 75),10)

                render.setColor(Color(255,255,255))
                render.drawSimpleText(width - 10,height - 35,""..string.toHoursMinutesSeconds(time).." / "..string.toHoursMinutesSeconds(duration),2,0)
            end
            
            local song_info = ""
            song_info = "#" .. track .. "> "
            for i=1, 3 do
                local t = ""
                if i == 1 and title then t = title .. "\n" end
                if i == 2 and author then t = "Artist: " .. author .. "\n" end
                if i == 3 and album then t = "Album: " .. album .. "\n" end
                song_info = song_info .. t
            end
            song_info = song_info:sub(0,#song_info - 1)
            render.drawText(10 + 60,height - 65,song_info,0,0)

            mainGui:render()
        end)

        hook.add("ms_render2","",function()
            --[[
            local showQuery = ""
            local final_info = ""
            for id, song in pairs(data.playlist[list]) do
                if string.find(song.title,showQuery) or string.find(song.artist or "",showQuery) then
                    final_info = final_info .. id .. ": Title: " .. song.title .. ", Author: " .. (song.artist or "") .. "\n"
                end
            end
            render.drawText(0,0,final_info,0,0)
            ]]

            render.setFont(listFont)
            songListGui:render()
        end)
    end

    local perms = {
        "bass.loadURL",
        "sound.create",
        "bass.play2D",
        "http.get"
    }

    if permission.can_create() then
        permission.setup_permission(perms,"Accept permission to see anything of the visualizer",function()
            song_loader.load("https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json",function(data)
                playlist = data
                print(ui_color,"Playlist loaded !",Color(60,255,60), " (Found " .. #data.playlist.radio .. " radio and " .. #data.playlist.mp3 .. " audio file)")
                if list == "mp3" then track = math.random(1,#data.playlist[list]) end
                on_load(data)
                load_audio(data)
            end)
        end)
    end
end