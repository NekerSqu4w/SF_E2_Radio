--Pay no attention to that..
local lang = {}

function add(id,text)
	id = id or "default"
	text = text or "This is a default text"
	lang[id] = text
end

function get(id)
	id = id or "default"
	return (lang[id] or "%"..id.."%")
end
------------------------------------

--Write the lang here
--add("placeholder id","Text to replace")
add("debug","Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

add("menu.playlist","Playlist")

add("menu.visualizer_settings","Visualizer settings")

add("menu.lang","Change language")

add("menu.equalizer","Equalizer")

add("menu.settings","Open settings")
add("menu.settings.label","Settings")

add("menu.visualizer","Visualizer")
add("menu.visualizer.refresh","Refresh list")
add("text.load_visualizer.problem_occured","A problem occurred while loading the visualizer.")

add("menu.color_choose","Color chooser")

add("menu.debug","Debug panel")
add("menu.debug.fps","Show fps ?")

add("text.fps_label","F/s: ")

add("text.dd.mp3","Drag and drop an .mp3/.wav file to play it..")
add("text.dd.img","Drag and drop an image file to change the background..")

add("text.render.click.unactive","Double click on screen to disable render mode.")
add("text.render.txt","Render mode")
add("text.render.start","Render will start..")

add("dev.info.important","This application is still in development, it is likely that there are still some bugs, I will do my best to solve the most problems.")

------------------------------------
--Return all data to the main file
return {
	name = "English",
    get = get
}