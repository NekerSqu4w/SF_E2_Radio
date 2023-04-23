
local default_list_url = "https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/playlist.json?raw=true"

-- // this function is unused for the moment
local function check_version(use_version)
    if use_version == "v1" then
        return {error=false,msg="No error"}
    elseif use_version == "v2" then
        return {error=false,warning=true,msg="/!\\ WARNING, v2 is still in development so it doesn't fully work, so please use v1 if you encounter any issues!"}
    end

    return {error=true,msg="It looks like you're using a version that doesn't exist. Be sure to use v1 or v2."}
end
-- //

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

local function reformat_link(data)
    for id, link_start in pairs(data.playlist.reformat_link) do
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
        if(check_version(ld.data.version).error == false) {
            if(ld.data.version == "v1" || ld.data.version == "v2") {
                --Reformat link
                for id, data in pairs(ld) do
                    data.link = reformat_link(data.link)
                    data.cover = reformat_link(data.cover)
                end

                exec(ld,{msg=has_error})
            }
            else{
                exec({},{error=true,msg="Cannot find version"})
            }
        }
        else{
            exec({},check_version(ld.data.version))
        }
    end)
end

return {load=load}