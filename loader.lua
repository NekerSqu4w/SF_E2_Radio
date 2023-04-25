
local default_list_url = "https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json"

local function is_url(url)
    return (string.sub(url,0,8) == "https://" or string.sub(url,0,7) == "http://")
end

local function handle_request(url,exec)
    if http.canRequest() then
        http.get(url,function(response,error) exec(response,error) end)
    else
        timer.simple(0.4,function() handle_request(url,exec) end)
    end
end

local function reformat_link(url,data)
    for id, link_start in pairs(data.reformat_link) do
        if url then url = string.replace(url,id,link_start)
        else url = nil end
    end
    return url
end

local function load(use_own_playlist_url,exec)
    local use_url = default_list_url
    if use_own_playlist_url and is_url(use_own_playlist_url) then use_url = use_own_playlist_url end
    handle_request(use_url,function(response,has_error)
        local ld = json.decode(response)
        if ld.data.version == "v1" then
            --Reformat link
            for id, data in pairs(ld.playlist.mp3) do
                data.link = reformat_link(data.link,ld.playlist)
                data.cover = reformat_link(data.cover,ld.playlist)
            end

            exec(ld,"No error")
        end
        exec({},has_error)
    end)
end

return {load=load}