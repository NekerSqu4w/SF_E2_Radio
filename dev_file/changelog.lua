--[[
To add an important changelog:

    important = true,
    important_to_know = {
        "",
        "",
        ""
    },

]]

local important_change_from_files = {
    "Please note, significant changes have been made to the application file.",
    "Therefore it is possible that the app crash.",
    "",
    "Want to fix the problem? Goto %appdata%/LOVE/ simply deletes the file /.AstMP3",
    "Now you can restart the app D: and enjoy !"
}


local changelog_version = {
    {
        ver = "v2.004 beta",
        info = {
            "Fixed some bug.",
            "New apk logo and new theme color !",
            "AstalNeker visualizer modifications.",
        }
    },
    {
        ver = "v2.003",
        info = {
            "After a moment of work the version 2.003 is available D:",
            "",
            "Fixed alot of bug.",
            "Theme color improvements",
            "New menu system. (Movable and resizable), \nyou can try by grabbing the title of this panel D: *BETA VERSION this will not work very good*",
            "Fixed default file saving",
            "New Apk logo",
            "Visualizer modification.",
            "Added Fullscreen mode by pressing f11",
            "New visualizer listing format (Playlist listing come later)"
        }
    }
}

return changelog_version