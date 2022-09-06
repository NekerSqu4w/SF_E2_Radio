--Ne fais pas attention à ça..
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

--Écrivez la langue ici
--add("placeholder id","Phrase remplacer")
add("debug","Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")

add("menu.playlist","Wiedergabeliste")

add("menu.lang","Sprache ändern")

add("menu.equalizer","Equalizer")

add("menu.visualizer_settings","Visualizer-Einstellungen")

add("menu.settings","Einstellungen öffnen")
add("menu.settings.label","Einstellungen")

add("menu.visualizer","Zuschauer")
add("menu.visualizer.refresh","Liste aktualisieren")
add("text.load_visualizer.problem_occured","Beim Laden des Visualizers ist ein Problem aufgetreten.")

add("menu.color_choose","Farbwähler")

add("menu.debug","Fehlerkorrekturfeld")
add("menu.debug.fps","fps anzeigen ?")

add("text.fps_label","F/s: ")

add("text.dd.mp3","Ziehen Sie eine .mp3/.wav-Datei per Drag-and-Drop, um sie abzuspielen.")
add("text.dd.img","Ziehen Sie eine Bilddatei per Drag-and-Drop, um den Hintergrund zu ändern.")

add("text.render.click.unactive","Doppelklicken Sie auf den Bildschirm, um den Rendermodus zu deaktivieren.")
add("text.render.txt","Rendermodus")
add("text.render.start","Das Rendern wird gestartet..")

add("dev.info.important","Diese Anwendung befindet sich noch in der Entwicklung, es ist wahrscheinlich, dass es noch einige Fehler gibt, ich werde mein Bestes tun, um die meisten Probleme zu lösen.")

------------------------------------
--Renvoient toutes les données au fichier principale
return {
	name = "German",
    get = get
}