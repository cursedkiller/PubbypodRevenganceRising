/// Hand of God Gamemode

/datum/game_mode/hand_of_god
	name = "hand of god"
	config_tag = "handofgod"
	antag_flag = ROLE_HOG_CULTIST
	required_players = 25
	required_enemies = 8
	recommended_enemies = 8
	restricted_jobs = list("Chaplain", "AI", "Cyborg", "Security Officer", "Warden", "Detective", "Head of Security", "Captain", "Head of Personnel")

/datum/game_mode/hand_of_god/announce()
	to_chat(world, "<B>The current game mode is - Hand of God!</B>")
	to_chat(world, "<B>Two cults are onboard the station, seeking to overthrow the other, and anyone who stands in their way.</B>")

/datum/game_mode/hand_of_god/pre_setup()
	var/list/datum/mind/red_followers = list()
	var/list/datum/mind/blue_followers = list()
	var/list/datum/mind/unassigned = list()

	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += GLOB.protected_jobs
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"

	for(var/datum/mind/player in antag_candidates)
		if(!(player.assigned_role in restricted_jobs))
			unassigned += player

	for(var/i in 1 to recommended_enemies)
		if(!length(unassigned))
			break
		var/datum/mind/follower = pick_n_take(unassigned)
		if(i % 2)
			red_followers += follower
		else
			blue_followers += follower

	for(var/datum/mind/follower_mind in red_followers)
		add_hog_follower(follower_mind, "red")
	for(var/datum/mind/follower_mind in blue_followers)
		add_hog_follower(follower_mind, "blue")

	return TRUE

/datum/game_mode/hand_of_god/post_setup()
	var/list/datum/mind/hog_god_candidates = list()
	for(var/datum/mind/candidate in antag_candidates)
		if(candidate.current?.client?.prefs?.be_special & (1 << ROLE_HOG_GOD))
			hog_god_candidates += candidate

	var/list/datum/mind/red_god_pool = hog_god_candidates & red_deity_followers
	if(!length(red_god_pool))
		red_god_pool = red_deity_followers
	if(length(red_god_pool))
		pick(red_god_pool).make_Handofgod_god("red")

	var/list/datum/mind/blue_god_pool = hog_god_candidates & blue_deity_followers
	if(!length(blue_god_pool))
		blue_god_pool = blue_deity_followers
	if(length(blue_god_pool))
		pick(blue_god_pool).make_Handofgod_god("blue")

	return ..()

/datum/game_mode/proc/add_hog_follower(datum/mind/follower_mind, colour)
	if(!ishuman(follower_mind.current))
		return FALSE
	var/mob/living/carbon/human/H = follower_mind.current
	if(HAS_TRAIT(H, TRAIT_MINDSHIELD))
		to_chat(H, "<span class='danger'>Your loyalty implant blocked the influence of the [colour] deity.</span>")
		return FALSE
	if((follower_mind in red_deity_followers) || (follower_mind in red_deity_prophets) || (follower_mind in blue_deity_followers) || (follower_mind in blue_deity_prophets))
		to_chat(H, "<span class='danger'>You already belong to a deity.</span>")
		return FALSE
	switch(colour)
		if("red")
			red_deity_followers += follower_mind
			H.faction |= FACTION_RED_GOD
		if("blue")
			blue_deity_followers += follower_mind
			H.faction |= FACTION_BLUE_GOD
	to_chat(H, "<span class='danger'><FONT size=3>You are now a follower of the [colour] deity!</FONT></span>")
	follower_mind.special_role = "Hand of God: [capitalize(colour)] Follower"
	update_hog_icons_added(follower_mind, colour)
	return TRUE

/datum/game_mode/proc/remove_hog_follower(datum/mind/follower_mind, announce = TRUE)
	follower_mind.remove_hog_follower_prophet()
	if(follower_mind.current)
		var/mob/living/carbon/human/H = follower_mind.current
		H.faction -= FACTION_RED_GOD
		H.faction -= FACTION_BLUE_GOD
	if(announce && follower_mind.current)
		to_chat(follower_mind.current, "<span class='danger'><b>Your mind has been cleared from the deity's influence.</b></span>")

/datum/game_mode/proc/add_god(datum/mind/god_mind, colour)
	remove_hog_follower(god_mind, announce = FALSE)
	switch(colour)
		if("red")
			red_deities += god_mind
		if("blue")
			blue_deities += god_mind

/datum/game_mode/proc/update_hog_icons_added(datum/mind/hog_mind, side)
	if(!hog_mind.current)
		return
	var/datum/atom_hud/antag/hud = GLOB.huds[side == "red" ? ANTAG_HUD_HOG_RED : ANTAG_HUD_HOG_BLUE]
	if(!hud)
		return
	hud.join_hud(hog_mind.current)
	var/rank = "follower"
	if(hog_mind in (side == "red" ? red_deity_prophets : blue_deity_prophets))
		rank = "prophet"
	if(is_handofgod_god(hog_mind.current))
		rank = "god"
	set_antag_hud(hog_mind.current, "hog-[side]-[rank]")

/datum/game_mode/proc/update_hog_icons_removed(datum/mind/hog_mind, side)
	if(!hog_mind.current)
		return
	var/datum/atom_hud/antag/hud = GLOB.huds[side == "red" ? ANTAG_HUD_HOG_RED : ANTAG_HUD_HOG_BLUE]
	if(hud)
		hud.leave_hud(hog_mind.current)
		set_antag_hud(hog_mind.current, null)

/datum/game_mode/proc/forge_deity_objectives(datum/mind/deity)
	var/list/objective_types = list(
		/datum/objective/deicide,
		/datum/objective/sacrifice_prophet,
		/datum/objective/build_deity,
		/datum/objective/follower_block,
		/datum/objective/escape_followers
	)
	var/obj_type = pick(objective_types)
	var/datum/objective/O = new obj_type
	O.owner = deity
	O.find_target()
	deity.objectives += O

/datum/game_mode/proc/greet_hog_follower(datum/mind/follower_mind, colour)
	if(!follower_mind.current)
		return
	if(follower_mind in (colour == "red" ? red_deity_prophets : blue_deity_prophets))
		to_chat(follower_mind.current, "<span class='danger'><B>You are the prophet of the [colour] deity!</B></span>")

/datum/game_mode/hand_of_god/declare_completion()
	..()
	return TRUE

// Global lists for tracking gamemode data
/datum/game_mode
	var/list/datum/mind/red_deities = list()
	var/list/datum/mind/red_deity_prophets = list()
	var/list/datum/mind/red_deity_followers = list()
	var/list/datum/mind/blue_deities = list()
	var/list/datum/mind/blue_deity_prophets = list()
	var/list/datum/mind/blue_deity_followers = list()

// Helper procs
/proc/is_handofgod_god(mob/M)
	return istype(M, /mob/camera/god)

/proc/is_handofgod_redcultist(mob/M)
	if(!ishuman(M) || !M.mind)
		return FALSE
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	return (M.mind in mode.red_deity_followers) || (M.mind in mode.red_deity_prophets)

/proc/is_handofgod_bluecultist(mob/M)
	if(!ishuman(M) || !M.mind)
		return FALSE
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	return (M.mind in mode.blue_deity_followers) || (M.mind in mode.blue_deity_prophets)

/proc/is_handofgod_cultist(mob/M)
	return is_handofgod_redcultist(M) || is_handofgod_bluecultist(M)

/proc/is_handofgod_prophet(mob/M)
	if(!ishuman(M) || !M.mind)
		return FALSE
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	return (M.mind in mode.red_deity_prophets) || (M.mind in mode.blue_deity_prophets)
