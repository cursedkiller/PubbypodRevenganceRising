/// Hand of God Antag HUD datums
/// These allow team members to identify eachother

/datum/atom_hud/antag/hog_blue
	hud_icons = list(ANTAG_HUD)

/datum/atom_hud/antag/hog_red
	hud_icons = list(ANTAG_HUD)

/// Should be called in the main HUD initialization
/proc/initialize_hog_huds()
	var/datum/atom_hud/antag/hog_blue/blue_hud = new
	var/datum/atom_hud/antag/hog_red/red_hud = new
	
	GLOB.huds[ANTAG_HUD_HOG_BLUE] = blue_hud
	GLOB.huds[ANTAG_HUD_HOG_RED] = red_hud
