--@name FFT Reactiv
--@author AstalNeker

//own library
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/retro_screen.txt as retro_screen.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/multiple_screen_lib.txt as multiple_screen_lib.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/my-starfall-library/main/permission_handler.txt as permission_handler.txt
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/loader.lua as loader.lua

//gui library
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/sfui.lua as sfui.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/component.lua as components/component.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/window.lua as components/window.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/button.lua as components/button.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/list.lua as components/list.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/slider.lua as components/slider.lua
--@include https://raw.githubusercontent.com/itisluiz/SFUi/main/sfui/components/label.lua as components/label.lua


if CLIENT then
    local retro_screen = require("retro_screen.txt")
    local msl = require("multiple_screen_lib.txt")
    local permission = require("permission_handler.txt")

    require("sfui.lua")
    require("components/component.lua")
    require("components/window.lua")
    require("components/button.lua")
    require("components/list.lua")
    require("components/slider.lua")
    require("components/label.lua")

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
    
    //search highest value
    function math.maxt(tbl,min,limit)
        local max = 0
        for x=min, limit do
            for y=min, limit do
                if (tbl[x] or 0) > (tbl[y] or 0) then max = (tbl[x] or 0)
                elseif (tbl[x] or 0) < (tbl[y] or 0) then max = (tbl[y] or 0) end
            end
        end
        return max
    end

    //search low frequency power
    local bassVal = 0
    function getBass(snd,smooth)
        local ft = snd:getFFT(4)
        if snd.playing then bassVal = math.lerp(timer.frametime() * smooth,bassVal,math.maxt(ft,3,9))
        else bassVal = math.lerp(timer.frametime() * smooth,bassVal,0) end
        return bassVal
    end
    
    local validTypeName = {"Yes","No","Cancel","Ok","Continue"}
    function dialogBox(usegui,title,info,button,on_press)
        local dialog_window = SFUi.window(Vector(64,64), Vector(300,150), title, true, true, function() on_press(dialog_window,0) end)

        for i=1, #info:split("\n") do
            //limit to 6 newline
            if i > 6 then break end
            SFUi.label(dialog_window, Vector(4, 15 + 4 - 15 + i * 15), "" .. info:split("\n")[i])
        end

        for i=1, #button do
            //allow 3 max button
            if i > 3 then break end
            SFUi.button(dialog_window,Vector(dialog_window.size.x - 70 - math.clamp(#button,0,3) * 70 + i * 70,dialog_window.size.y - 30),Vector(60,20),validTypeName[button[i]],function() on_press(dialog_window,i) end)
        end
        usegui:addComponent(dialog_window)
    end

    local coverBufferGenerated = true
    local coverInfo = {}
    coverInfo.realSize = Vector(0,0)
    coverInfo.realPos = Vector(0,0)
    function process_cover(data,url)
        url = url or data.container.playlist[list].list[track].cover or data.container.no_background[math.random(1,#data.container.no_background)]
        cover:setTextureURL("$basetexture",url,function(_,_,w,h,layout)
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
    end
    
    function load_audio(data)
        guiList.list.value = track
        if currentSnd then currentSnd:pause() end
        process_cover(data)
        local moreDetail = data.container.playlist[list].list[track].moreDetail
        if moreDetail and moreDetail.album and moreDetail.album.covers then
            process_cover(data,moreDetail.album.covers)
        end

        local WAITINGSTOP = currentSnd
        bass.loadURL(data.container.playlist[list].list[track].link, "3d noblock", function(snd)
            if snd then
                currentSnd = snd
                
                //add metadata
                currentSnd.volume = 1
                currentSnd.playing = true
                currentSnd.hasFinishToggle = true
                currentSnd.VOLUMEBEFORETRANSITION = currentSnd.volume

                waitingNextSong = false

                //write custom sound function
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
                
                currentSnd:setVolume2(guiButton.volume.value)

                if WAITINGSTOP then WAITINGSTOP:stop() end
            end
        end)
    end

    function on_load(data)
        table.sort(data.container.playlist[list].list, function(a,b)
            if a.author < b.author then
                return b
            end
        end)

        local font = render.createFont("FontAwesome",15,0)
        local font2 = render.createFont("FontAwesome",35,0)
        local listFont = render.createFont("FontAwesome",15,0)

        cover = material.create("UnlitGeneric")
        render.createRenderTarget("coverBlurBuffer")

        local mainGui = SFUi:new()
        guiButton.prev = SFUi.button(nil, Vector(10, 512 - 90), Vector(20, 20), "|<", function()
            track = track - 1
            if track < 1 then track = #data.container.playlist[list].list end
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
            if track > #data.container.playlist[list].list then track = 1 end
            if waitingNextSong == false then
                load_audio(data)
                waitingNextSong = true
            end
        end)
        
        guiButton.seek = SFUi.slider(nil, Vector(-128,0), Vector(512,10),0,0,1,0.001)
        guiButton.volume = SFUi.slider(nil, Vector(guiButton.prev.pos.x,guiButton.prev.pos.y - 30), Vector(128,10),1,0,5,0.1,function(vol) currentSnd:setVolume2(vol) end)
        mainGui:addComponent(guiButton.prev)
        mainGui:addComponent(guiButton.next)
        mainGui:addComponent(guiButton.pause)
        mainGui:addComponent(guiButton.seek)
        mainGui:addComponent(guiButton.volume)

        local songListGui = SFUi:new()
        local formatedList = {}
        for key, data in pairs(data.container.playlist[list].list) do formatedList[key] = "#" .. key .. "> " .. data.author .. "@ " .. data.title end

        guiList.list = SFUi.list(nil, Vector(0, 15), Vector(512, 512-15), "Song list", formatedList, function(id)
            if waitingNextSong == false then
                track = id
                load_audio(data)
                waitingNextSong = true
            end
        end)  
        songListGui:addComponent(guiList.list)
        guiList.list.value = track
        
        --[[
        //FEATURE IN DEV
        //but almost done
        dialogBox(mainGui,"This is a title","Description\nwith also some newline",{1,2,3,4,5},function(win,id)
            //print(id)
            
            //do close window on button press
            mainGui:removeComponent(win)
        end)
        ]]


        hook.add("render","",function()
            msl.update()
            if currentSnd then
                currentSnd:setPos(chip():getPos())
                if currentSnd.playing then guiButton.pause.text = "Pause"
                else guiButton.pause.text = "Play" end
            end

            if coverBufferGenerated == false then
                render.selectRenderTarget("coverBlurBuffer")
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

            local track_ = data.container.playlist[list].list[track]
            local url = track_.link
            local title = track_.title
            local author = track_.author
            local album = track_.album
            local moreDetail = track_.moreDetail or {explicit=false}

            //Due to not correct songdetail, this is not 100% accurate
            //if moreDetail and moreDetail.artists then author = table.concat(moreDetail.artists,", ") end

            if currentSnd then
                fft = currentSnd:getFFT(1)
                fft2 = currentSnd:getFFT(4)

                bassfft = getBass(currentSnd,10) * 10
                local left,right = currentSnd:getLevels()
                local mono = (left+right)/2
            end

            if currentSnd then
                duration = currentSnd:getLength()
                time = currentSnd:getTime()
                if guiButton.seek.action.held == nil then
                    guiButton.seek.value = time
                else
                    currentSnd:setTime(guiButton.seek.value)
                end
                guiButton.seek.max = duration

                if guiButton.seek.action.held == nil and time >= duration and list == "mp3" and waitingNextSong == false then
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
            for i=1, num do
                smooth_fft[i] = math.lerp(timer.frametime()*10,smooth_fft[i] or 0, fft2[i] or 0)
    
                r = 100 + bassfft*60 + smooth_fft[i] * 150
                r2 = 100 + bassfft*60 + (smooth_fft[i-1] or smooth_fft[num] or 0) * 150
                x,y = math.cos((i/num) * (math.pi*2)) * r,math.sin((i/num) * (math.pi*2)) * r
                lx,ly = math.cos(((i-1)/num) * (math.pi*2)) * r2,math.sin(((i-1)/num) * (math.pi*2)) * r2

                render.setColor(Color((i / num) * 360 + bassfft/2 * 230,1,1):hsvToRGB())
                render.drawLine(256+x,256+y,256+lx,256+ly)
    
    
                r = 100 - bassfft*60 - smooth_fft[i] * 80
                r2 = 100 - bassfft*60 - (smooth_fft[i-1] or smooth_fft[num] or 0) * 80
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
            render.setRenderTargetTexture("coverBlurBuffer")
            render.drawTexturedRect(5, 512 - 65, 60, 60)
            render.setRenderTargetTexture()

            render.setColor(Color(255, 255, 255))
            render.setMaterial(cover)
            render.drawTexturedRect(5 + 4, 512 - 65 + 4, 60 - 8, 60 - 8)
            render.setMaterial()
    

            guiButton.seek.pos = Vector(10 + 60,height - 15)
            guiButton.seek.size = Vector(width - 75,10)

            if duration < 0 then
                render.setColor(ui_color)
                render.drawRect(10 + 60,height - 15,width - 75,10)
                render.drawFilledCircle(width-40,height-27,5)
    
                render.setColor(Color(255,255,255))
                render.drawSimpleText(width - 10 ,height - 35,"Live",2,0)

                guiButton.seek.visible = false
            else
                guiButton.seek.visible = true

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
            
            //render.setColor(Color(255,255,255))
            //render.drawText(10,10,""..table.toString(track_,nil,true),0,0)

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
        "http.get",
        "material.urlcreate"
    }

    if permission.can_create() then
        permission.setup_permission(perms,"Accept permission to see anything of the visualizer",function()
            song_loader.load("https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json",function(data)
                playlist = data
                print(ui_color,"Playlist loaded !",Color(60,255,60), " (Found " .. #data.container.playlist.radio .. " radio and " .. #data.container.playlist.mp3 .. " audio file)")
                if list == "mp3" then track = math.random(1,#data.container.playlist[list].list) end
                on_load(data)
                load_audio(data)
            end)
        end)
    end
end