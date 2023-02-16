
--Some code will go here later..

function check_version(use_version)
    if use_version == "v1" then
        return true
    elseif use_version == "v2" then
        print("/!\\ WARNING, v2 is still in development so it doesn't fully work, so please use v1 if you encounter any issues!")
        return true
    end

    print("It looks like you're using a version that doesn't exist. Be sure to use v1 or v2.")
    return false
end

function get_list(list)
    http.get("https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true",function(response)
        return current_track = json.decode(response)[list]
    end)
end

function get_url(use_version,list,id)
    if check_version(use_version) then
        if use_version == "v1" then
            return get_list(list)[id]
        elseif use_version == "v2" then
        end
    end
end

return {get_url=get_url,get_list=get_list}