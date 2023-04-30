--@name Starfall example 1
--@author AstalNeker

--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/loader.lua as loader.lua

if CLIENT then
    --Import the loader
    local song_loader = require("loader.lua")
    
    --Some value to choose your song
    local list = "mp3" --Two list exist
    local load_id = 1

    --Used to load playlist data
    -- song_loader.load(use_own_url or nil,function)
    song_loader.load("https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json",function(data,error)
        if error.error then
            print(error.message)
        else
            print("Current list as " .. #data.playlist[list] .. " file")
            print("Current song: " .. data.playlist[list][load_id].title)
            print("Playlist name: " .. data.playlist.list_name[list])
    
            print("Song link: " .. data.playlist[list][load_id].link)

            bass.loadURL(data.playlist[list][load_id].link, "3d noblock", function(snd,error)
                if snd then
                    snd:setVolume(1)
                    if not snd:isOnline() then snd:setLooping(true) end

                    timer.create("loop",0,0,function()
                        snd:setPos(chip():getPos())
                    end)
                end
            end)
        end
    end)
end