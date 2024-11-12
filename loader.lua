local default_list_url = "https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist_v1.json"

local function is_url(url)
    return (string.sub(url,0,8) == "https://" or string.sub(url,0,7) == "http://")
end

local function handle_request(url,exec)
    if http.canRequest() then
        http.get(url,function(response) exec(response,{error=false,msg="No error occured"}) end,function(error) exec("",{error=true,msg=error}) end)
    else
        //retry request
        timer.simple(0.4,function() handle_request(url,exec) end)
    end
end

local function load(use_own_playlist_url,exec)
    local use_url = default_list_url
    if use_own_playlist_url and is_url(use_own_playlist_url) then use_url = use_own_playlist_url end
    handle_request(use_url,function(response,has_error)
        if has_error.error then
            exec({},has_error)
            return
        end

        local ld = json.decode(response)
        if ld.metadata.version == 1 then
        end
    end)
end

return {load=load}
