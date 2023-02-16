--@name Starfall example 1
--@author AstalNeker

--Include loader as song_loader.lua
--@include https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/song_loader.lua?raw=true as song_loader.lua

if CLIENT then
    --Import the loader
    local song_loader = require("song_loader.lua")
    
    --Some value to choose your song
    local list = "mp3" --Two list exist
    local load_id = 31
    
    --Used to get data information
    song_loader.get_data(function(data)
        print("Playlist data version: " .. data.version)
    end)

    --Used to load playlist data
    -- song_loader.get_list(function,use_own_url or nil)
    song_loader.get_list(function(playlist)
        print("Current list as " .. #playlist[list] .. " file")
        print("Current song: " .. playlist[list][load_id].title)
        print("Playlist name: " .. playlist.list_name[list])

        -- reformat_link() will work only after data was loaded
        print("Song link: " .. song_load.reformat_link(playlist[list][load_id].link))

        bass.loadURL(song_load.reformat_link(playlist[list][load_id].link), "noblock", function(snd,error)
            if not error then
                snd:setVolume(1)
                if not snd:isOnline() then
                    snd:setLooping(true)
                end
            end
        end)

    end,"https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true")
    
    --Get last request data
    timer.simple(3,function()
        -- last_request_data() will only return something only when you loaded the selected data by using get_list() or get_data()
        print("Current list data: " .. table.toString(song_loader.last_request_data().data))
    end)
end