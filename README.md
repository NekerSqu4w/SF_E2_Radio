
## Informations

You can use these example to help you !

[starfall example 1.lua](https://github.com/NekerSqu4w/SF_E2_Radio/blob/main/EXAMPLE/starfall%20example%201.lua)

or if you wanna make your own code you can [See Usage](#usage)

## Usage

To use with StarfallEx
```lua
-- To specify Starfall instance to run on clientside
--@client

-- Import the library
--@include https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/loader.lua as loader.lua
local song_loader = require("loader.lua")
```

Than call the library to load the playlist by using song_loader.load(playlist url or nil,function on execution)
```lua
song_loader.load("https://raw.githubusercontent.com/NekerSqu4w/SF_E2_Radio/main/LIST/playlist.json",function(data,error)
end
```

On execution succesfull this will return
```json
{
    "data": {
        "version": string,
        "no_background": [...]
    },
    "playlist": {
        "reformat_link": {...},
        "list_id": {...},
        "list_name": {...},
        "radio": [
            {...},
            {...}
        ],
        "mp3": [
            {...},
            {...}
        ]
    }
}
```