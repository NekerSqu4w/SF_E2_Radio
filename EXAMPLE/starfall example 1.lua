--@name Starfall example 1
--@author AstalNeker

--Include loader as song_loader.lua
--@include https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/song_loader.lua?raw=true as song_loader.lua

if CLIENT then
    --Import the loader
    local song_loader = require("song_loader.lua")
    
    --Some value to choose your song
    local list = "mp3" --Two list exist
    local load_id = 48

    --Used to load playlist data
    -- song_loader.load(use_own_url or nil,function)
    song_loader.load("https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/VISUALISER/playlist_v2.json",function(data,error)
        print(table.toString(error))
        print("Current list as " .. #data.playlist[list] .. " file")
        print("Current song: " .. data.playlist[list][load_id].title)
        print("Playlist name: " .. data.playlist.list_name[list])

        -- reformat_link() will work only after data was loaded
        print("Song link: " .. data.playlist[list][load_id].link)

        bass.loadURL(data.playlist[list][load_id].link, "noblock", function(snd,error)
            if not error then
                snd:setVolume(1)
                if not snd:isOnline() then
                    snd:setLooping(true)
                end
            end
        end)

    end)
end