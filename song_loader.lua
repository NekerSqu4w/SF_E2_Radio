
local default_list_url = "https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true"
local last_request = {data=nil,playlist=nil}

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

function is_url(url)
    return (string.sub(url,0,8) == "https://" or string.sub(url,0,7) == "http://")
end

function handle_request(url,exec)
    if http.canRequest() then
        http.get(url,function(response,error) exec(response,error) end)
    else
        timer.simple(0.4,function() handle_request(url,exec) end)
    end
end

function get_data(exec,use_own_playlist_url)
    local use_url = default_list_url
    if use_own_playlist_url then use_url = use_own_playlist_url end
    handle_request(use_url,function(response,has_error)
        local ld = json.decode(response)
        last_request.data = ld.data
        exec(ld.data,has_error)
    end)
end

function get_list(exec,use_own_playlist_url)
    local use_url = default_list_url
    if use_own_playlist_url then use_url = use_own_playlist_url end
    handle_request(use_url,function(response,has_error)
        local ld = json.decode(response)
        last_request.playlist = ld.playlist
        exec(ld.playlist,has_error)
    end)
end

function last_request_data() return last_request end

return {get_list=get_list,get_data=get_data,last_request=last_request}