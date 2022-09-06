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

add("menu.playlist","Playlist")

add("menu.visualizer_settings","Paramètres du visualiseur")

add("menu.lang","Changer de langue")

add("menu.equalizer","Égaliseur")

add("menu.settings","Ouvrir les paramètres")
add("menu.settings.label","Paramètres")

add("menu.visualizer","Visualiseur")
add("menu.visualizer.refresh","Rafraîchir la liste")
add("text.load_visualizer.problem_occured","Un probléme est survenue pendant le chargement du visualizer..")

add("menu.color_choose","Sélecteur de couleurs")

add("menu.debug","Panneau de débogage")
add("menu.debug.fps","Afficher ips ?")

add("text.fps_label","I/s: ")

add("text.dd.mp3","Faites glisser et déposez un fichier .mp3/.wav pour le lire.")
add("text.dd.img","Faites glisser et déposez un fichier image pour modifier l'arrière-plan.")

add("text.render.click.unactive","Double-cliquez sur l'écran pour désactiver le mode de rendu.")
add("text.render.txt","Mode de rendu")
add("text.render.start","Le rendu va commencer..")

add("dev.info.important","Cette application est encore en développement, il est probable qu'il y est encore quelque bugs, je vais faire mon possible pour régler le plus de probléme.")

------------------------------------
--Renvoient toutes les données au fichier principale
return {
	name = "Français",
    get = get
}