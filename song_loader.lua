
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

function handle_request(url,exec)
    if http.canRequest() then http.get(url,function(response) exec(reponse) end)
    else timer.simple(2,function() handle_request(url) end) end
end

function get_data(exec)
    handle_request("https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true",function(response)
        local ld = json.decode(response)
        exec(ld.data)
    end)
end

function get_list(list,exec)
    handle_request("https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true",function(response)
        local ld = json.decode(response)
        if ld.playlist.list_id[list] then
            exec(ld.playlist[list])
        end
    end)
end

return {get_list=get_list,get_data=get_data}