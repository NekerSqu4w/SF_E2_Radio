
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

function load(use_version)
    if check_version(use_version) then
        print("Loading from version: " .. use_version)
    end
end

return load