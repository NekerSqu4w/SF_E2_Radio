local default_list_url = "https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json"

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
        if has_error.error then
            exec({},has_error)
            return
        end

        local ld = json.decode(response)
        if ld.metadata.version == "v1" then
            --Reformat link

            local rewriteSpeed = 15 //number of link rewrite at once, high value can increase lag
            local as_write = 1
            local id = timer.curtime()
            timer.create("SLOW_LOAD"..id,0,0,function()
                for i=1, rewriteSpeed do
                    if as_write <= #ld.container.playlist.mp3.list then else
                        exec(ld,{error=false,"No error occured"})
                        timer.remove("SLOW_LOAD"..id)
                        break
                    end
                    local to_write = ld.container.playlist.mp3.list[as_write]
                    to_write.link = reformat_link(to_write.link,ld.container.playlist.mp3)
                    to_write.cover = reformat_link(to_write.cover,ld.container.playlist.mp3)
                    as_write = as_write + 1
                end
            end)
        end
    end)
end

return {load=load}
