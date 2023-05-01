--@name FFT Loader
--@author AstalNeker

if CLIENT then
    //import alot of library
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

    local visualizer = {}
    visualizer.version = "1.0"
    visualizer.current_track = {id=1,list="mp3"}
    visualizer.visualizer = {current="reactiv.lua",list={}}
    visualizer.theme_color = {global_color = Color(70,255,255)}
    visualizer.font = {}
    
    //import visualizer to data
    --@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/custom/reactiv.lua as reactiv.lua
    --@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/custom/monstercat.lua as monstercat.lua
    visualizer.visualizer.list["reactiv.lua"] = require("reactiv.lua")
    visualizer.visualizer.list["monstercat.lua"] = require("monstercat.lua")

    SFUi.static.palette = {
        foreground = Color(255, 255, 255),
        background = Color(30, 30, 30),
        hover = Color(75, 75, 75),
        component = Color(45, 45, 45),
        contrast = Color(60, 60, 60),
        highlight = visualizer.theme_color.global_color
    }

    visualizer.FFT = {}
    visualizer.FFT.fft = {}
    visualizer.FFT.fft2 = {}

    visualizer.bassfft = 0
    visualizer.currentSnd = nil
    visualizer.waitingNextSong = true
    
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
        url = url or data.container.playlist[visualizer.current_track.list].list[visualizer.current_track.id].cover or data.container.no_background[math.random(1,#data.container.no_background)]
        visualizer.cover:setTextureURL("$basetexture",url,function(_,_,w,h,layout)
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
        guiList.songList.value = visualizer.current_track.id
        if visualizer.currentSnd then visualizer.currentSnd:pause() end
        process_cover(data)
        local moreDetail = data.container.playlist[visualizer.current_track.list].list[visualizer.current_track.id].moreDetail
        if moreDetail and moreDetail.album and moreDetail.album.covers then
            process_cover(data,moreDetail.album.covers)
        end

        local WAITINGSTOP = visualizer.currentSnd
        bass.loadURL(data.container.playlist[visualizer.current_track.list].list[visualizer.current_track.id].link, "3d noblock", function(snd)
            if snd then
                visualizer.currentSnd = snd
                
                //add metadata
                visualizer.currentSnd.volume = 1
                visualizer.currentSnd.playing = true
                visualizer.currentSnd.hasFinishToggle = true
                visualizer.currentSnd.VOLUMEBEFORETRANSITION = visualizer.currentSnd.volume

                visualizer.waitingNextSong = false

                //write custom sound function
                function visualizer.currentSnd:toggle(forceToggle)
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

                function visualizer.currentSnd:setVolume2(vol)
                    self.volume = vol
                    self:setVolume(vol)
                end
                
                visualizer.currentSnd:setVolume2(guiButton.volume.value)

                if WAITINGSTOP then WAITINGSTOP:stop() end
            end
        end)
    end

    function on_load(data)
        table.sort(data.container.playlist[visualizer.current_track.list].list, function(a,b)
            if a.author < b.author then
                return b
            end
        end)

        visualizer.font.main = render.createFont("FontAwesome",15,0)
        visualizer.font.font2 = render.createFont("FontAwesome",35,0)
        visualizer.font.listFont = render.createFont("FontAwesome",15,0)

        visualizer.cover = material.create("UnlitGeneric")
        render.createRenderTarget("coverBlurBuffer")

        local mainGui = SFUi:new()
        guiButton.prev = SFUi.button(nil, Vector(10, 512 - 90), Vector(20, 20), "|<", function()
            visualizer.current_track.id = visualizer.current_track.id - 1
            if visualizer.current_track.id < 1 then visualizer.current_track.id = #data.container.playlist[visualizer.current_track.list].list end
            if visualizer.waitingNextSong == false then
                load_audio(data)
                visualizer.waitingNextSong = true
            end
        end)
        guiButton.pause = SFUi.button(nil, Vector(guiButton.prev.pos.x + guiButton.prev.size.x+5, guiButton.prev.pos.y), Vector(40, 20), "Pause", function()
            visualizer.currentSnd:toggle()
        end)
        guiButton.next = SFUi.button(nil, Vector(guiButton.pause.pos.x + guiButton.pause.size.x+5, guiButton.prev.pos.y), Vector(20, 20), ">|", function()
            visualizer.current_track.id = visualizer.current_track.id + 1
            if visualizer.current_track.id > #data.container.playlist[visualizer.current_track.list].list then visualizer.current_track.id = 1 end
            if visualizer.waitingNextSong == false then
                load_audio(data)
                visualizer.waitingNextSong = true
            end
        end)
        
        guiButton.seek = SFUi.slider(nil, Vector(-128,0), Vector(512,10),0,0,1,0.001)
        guiButton.volume = SFUi.slider(nil, Vector(guiButton.prev.pos.x,guiButton.prev.pos.y - 30), Vector(128,10),1,0,5,0.1,function(vol) visualizer.currentSnd:setVolume2(vol) end)
        mainGui:addComponent(guiButton.prev)
        mainGui:addComponent(guiButton.next)
        mainGui:addComponent(guiButton.pause)
        mainGui:addComponent(guiButton.seek)
        mainGui:addComponent(guiButton.volume)

        local songListGui = SFUi:new()
        local formatedList = {}
        for key, data in pairs(data.container.playlist[visualizer.current_track.list].list) do formatedList[key] = "#" .. key .. "> " .. data.author .. "@ " .. data.title end
        guiList.songList = SFUi.list(nil, Vector(0, 15), Vector(512, 512-15), "Song list", formatedList, function(id)
            if visualizer.waitingNextSong == false then
                visualizer.current_track.id = id
                load_audio(data)
                visualizer.waitingNextSong = true
            end
        end)
        
        local formatedList = {}
        for key, data in pairs(visualizer.visualizer.list) do formatedList[key] = key end
        guiList.visualizerList = SFUi.list(nil, Vector(512, 15), Vector(512, 512-15), "Visualizer list", formatedList, function(id)
            //reset data of unused visualizer
            local CURRENTVISUALIZER = visualizer.visualizer.list[visualizer.visualizer.current]
            CURRENTVISUALIZER.on_switch()
            visualizer.visualizer.current = id
        end)
        songListGui:addComponent(guiList.songList)
        songListGui:addComponent(guiList.visualizerList)
        guiList.songList.value = visualizer.current_track.id
        guiList.visualizerList.value = visualizer.visualizer.current
        
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
            if visualizer.currentSnd then
                visualizer.currentSnd:setPos(chip():getPos())
                if visualizer.currentSnd.playing then guiButton.pause.text = "Pause"
                else guiButton.pause.text = "Play" end
            end

            if coverBufferGenerated == false then
                render.selectRenderTarget("coverBlurBuffer")
                render.clear()
                
                render.setColor(Color(255, 255, 255))
                render.setMaterial(visualizer.cover)
                render.drawTexturedRect(-1024/2, -1024/2, 1024*2, 1024*2)
                render.setMaterial()
                render.drawBlurEffect(12,12,1)

                render.selectRenderTarget()

                coverBufferGenerated = true
            end
        end)

        hook.add("ms_render1","",function()
            local width, height = render.getResolution()

            local track_ = data.container.playlist[visualizer.current_track.list].list[visualizer.current_track.id]
            local url = track_.link
            local title = track_.title
            local author = track_.author
            local album = track_.album
            local moreDetail = track_.moreDetail or {explicit=false}
            visualizer.current_track.detail = track_

            //Due to not correct songdetail, this is not 100% accurate
            //if moreDetail and moreDetail.artists then author = table.concat(moreDetail.artists,", ") end

            if visualizer.currentSnd then
                visualizer.FFT.fft = visualizer.currentSnd:getFFT(1)
                visualizer.FFT.fft2 = visualizer.currentSnd:getFFT(4)

                visualizer.bassfft = getBass(visualizer.currentSnd,10) * 10
                local left,right = visualizer.currentSnd:getLevels()
                local mono = (left+right)/2
            end

            if visualizer.currentSnd then
                visualizer.current_track.duration = visualizer.currentSnd:getLength()
                visualizer.current_track.time = visualizer.currentSnd:getTime()
                if guiButton.seek.action.held == nil then
                    guiButton.seek.value = visualizer.current_track.time
                else
                    visualizer.currentSnd:setTime(guiButton.seek.value)
                end
                guiButton.seek.max = visualizer.current_track.duration

                if guiButton.seek.action.held == nil and visualizer.current_track.time >= visualizer.current_track.duration and visualizer.current_track.list == "mp3" and visualizer.waitingNextSong == false then
                    visualizer.current_track.id = math.random(1,#data.container.playlist[visualizer.current_track.list].list)
                    load_audio(data)
                    visualizer.waitingNextSong = true
                end
            else
                visualizer.current_track.duration = 0
                visualizer.current_track.time = 0
            end

            render.setFont(visualizer.font.main)

            //draw custom visualizer
            local CURRENTVISUALIZER = visualizer.visualizer.list[visualizer.visualizer.current]
            CURRENTVISUALIZER.render(visualizer,CURRENTVISUALIZER,width,height)

            render.setFont(visualizer.font.main)

            //interface element
            render.setColor(Color(255, 255, 255))
            render.setRenderTargetTexture("coverBlurBuffer")
            render.drawTexturedRect(5, 512 - 65, 60, 60)
            render.setRenderTargetTexture()

            render.setColor(Color(255, 255, 255))
            render.setMaterial(visualizer.cover)
            render.drawTexturedRect(5 + 4, 512 - 65 + 4, 60 - 8, 60 - 8)
            render.setMaterial()
    

            guiButton.seek.pos = Vector(10 + 60,height - 15)
            guiButton.seek.size = Vector(width - 75,10)

            if visualizer.current_track.duration < 0 then
                render.setColor(visualizer.theme_color.global_color)
                render.drawRect(10 + 60,height - 15,width - 75,10)
                render.drawFilledCircle(width-40,height-27,5)
    
                render.setColor(Color(255,255,255))
                render.drawSimpleText(width - 10 ,height - 35,"Live",2,0)

                guiButton.seek.visible = false
            else
                guiButton.seek.visible = true

                render.setColor(Color(255,255,255))
                render.drawSimpleText(width - 10,height - 35,""..string.toHoursMinutesSeconds(visualizer.current_track.time).." / "..string.toHoursMinutesSeconds(visualizer.current_track.duration),2,0)
            end
            
            local song_info = ""
            song_info = "#" .. visualizer.current_track.id .. "> "
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

            render.setFont(visualizer.font.listFont)
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
                local EVERYFOUNDFOLDER = ""
                for id, folder in pairs(data.container.playlist) do EVERYFOUNDFOLDER = EVERYFOUNDFOLDER .. "\n" .. #folder.list .. " link in " .. folder.name end
                print(visualizer.theme_color.global_color,"Playlist loaded !",Color(60,255,60), "\nLet's check what i found:" .. EVERYFOUNDFOLDER)

                if visualizer.current_track.list == "mp3" then visualizer.current_track.id = math.random(1,#data.container.playlist[visualizer.current_track.list].list) end
                on_load(data)
                load_audio(data)
            end)
        end)
    end
end