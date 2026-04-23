/// Hand of God Gamemode
/// Two rival deities compete for control of the station through their cult followers

/datum/game_mode
	/// Red team lists
	var/list/datum/mind/red_deities = list()
	var/list/datum/mind/red_deity_prophets = list()
	var/list/datum/mind/red_deity_followers = list()
	
	/// Blue team lists
	var/list/datum/mind/blue_deities = list()
	var/list/datum/mind/blue_deity_prophets = list()
	var/list/datum/mind/blue_deity_followers = list()
	
	/// Roundstart assignment
	var/list/datum/mind/unassigned_followers = list()

/datum/game_mode/hand_of_god
	name = "hand of god"
	config_tag = "handofgod"
	antag_flag = ROLE_HOG_CULTIST
	
	required_players = 25
	required_enemies = 8
	recommended_enemies = 8
	
	restricted_jobs = list(
		"Chaplain", 
		"AI", 
		"Cyborg", 
		"Security Officer", 
		"Warden", 
		"Detective", 
		"Head of Security", 
		"Captain", 
		"Head of Personnel"
	)
	
	/// List of objective types for deity objectives
	var/list/deity_objectives = list(
		/datum/objective/deicide,
		/datum/objective/sacrifice_prophet, 
		/datum/objective/build,
		/datum/objective/follower_block,
		/datum/objective/escape_followers
	)

/datum/game_mode/hand_of_god/announce()
	to_chat(world, "<B>The current game mode is - Hand of God!</B>")
	to_chat(world, "<B>Two cults are onboard the station, seeking to overthrow the other, and anyone who stands in their way.</B>")
	to_chat(world, "<B>Followers</B> - Complete your deity's objectives. Convert crewmembers to your cause by using your deity's nexus.")
	to_chat(world, "<B>Prophets</B> - Command your cult by the will of your deity. You are a high-value target, so be careful!")
	to_chat(world, "<B>Personnel</B> - Do not let any cult succeed in its mission. Loyalty implants and holy water will revert them to neutral crew.")

/datum/game_mode/hand_of_god/pre_setup()
	if(CONFIG_GET(flag/protect_roles_from_antagonist))
		restricted_jobs += protected_jobs
	
	if(CONFIG_GET(flag/protect_assistant_from_antagonist))
		restricted_jobs += "Assistant"
	
	// Filter out restricted jobs
	for(var/datum/mind/player in antag_candidates)
		if(player.assigned_role in restricted_jobs)
			antag_candidates -= player
	
	// Assign followers randomly
	for(var/i in 1 to recommended_enemies)
		if(!length(antag_candidates))
			break
		var/datum/mind/follower = pick_n_take(antag_candidates)
		unassigned_followers += follower
		log_game("[key_name(follower)] has been selected as a Hand of God follower")
	
	// Split evenly between teams
	var/half = round(length(unassigned_followers) / 2)
	for(var/i in 1 to half)
		if(!length(unassigned_followers))
			break
		var/datum/mind/follower = pick_n_take(unassigned_followers)
		add_hog_follower(follower, "red")
	
	for(var/datum/mind/follower in unassigned_followers)
		add_hog_follower(follower, "blue")
	
	return TRUE

/datum/game_mode/hand_of_god/post_setup()
	// Select red god from followers
	var/list/datum/mind/red_candidates = get_players_for_role(ROLE_HOG_GOD)
	red_candidates &= red_deity_followers
	if(!length(red_candidates))
		red_candidates = red_deity_followers
	
	if(length(red_candidates))
		var/datum/mind/red_god = pick(red_candidates)
		red_god.make_Handofgod_god("red")
		log_game("[key_name(red_god)] has become the Red Deity")
	
	// Select blue god from followers
	var/list/datum/mind/blue_candidates = get_players_for_role(ROLE_HOG_GOD)
	blue_candidates &= blue_deity_followers
	if(!length(blue_candidates))
		blue_candidates = blue_deity_followers
	
	if(length(blue_candidates))
		var/datum/mind/blue_god = pick(blue_candidates)
		blue_god.make_Handofgod_god("blue")
		log_game("[key_name(blue_god)] has become the Blue Deity")
	
	return ..()

/// Add a follower to a god's team
/datum/game_mode/proc/add_hog_follower(datum/mind/follower_mind, colour = "red")
	if(!ishuman(follower_mind.current))
		return FALSE
	
	var/mob/living/carbon/human/H = follower_mind.current
	
	// Check for protections
	if(HAS_TRAIT(H, TRAIT_MINDSHIELD))
		to_chat(H, "<span class='danger'>Your loyalty implant blocked the influence of the [colour] deity.</span>")
		return FALSE
	
	if((follower_mind in red_deity_followers) || (follower_mind in red_deity_prophets) || \
	   (follower_mind in blue_deity_followers) || (follower_mind in blue_deity_prophets))
		to_chat(H, "<span class='danger'>You already belong to a deity.</span>")
		return FALSE
	
	var/obj/item/nullrod/N = locate() in H
	if(N)
		to_chat(H, "<span class='danger'>Your null rod prevented the [colour] deity from brainwashing you.</span>")
		return FALSE
	
	// Add to appropriate team
	switch(colour)
		if("red")
			red_deity_followers += follower_mind
			H.faction |= FACTION_RED_GOD
		if("blue")
			blue_deity_followers += follower_mind
			H.faction |= FACTION_BLUE_GOD
	
	to_chat(H, "<span class='danger'><FONT size = 3>You are now a follower of the [colour] deity! Serve your god well.</FONT></span>")
	follower_mind.special_role = "Hand of God: [capitalize(colour)] Follower"
	update_hog_icons_added(follower_mind, colour)
	return TRUE

/// Remove a follower from all teams
/datum/game_mode/proc/remove_hog_follower(datum/mind/follower_mind, announce = TRUE)
	red_deity_followers -= follower_mind
	red_deity_prophets -= follower_mind
	blue_deity_followers -= follower_mind
	blue_deity_prophets -= follower_mind
	
	update_hog_icons_removed(follower_mind, "red")
	update_hog_icons_removed(follower_mind, "blue")
	
	if(follower_mind.current)
		var/mob/living/carbon/human/H = follower_mind.current
		H.faction -= FACTION_RED_GOD
		H.faction -= FACTION_BLUE_GOD
	
	if(announce && follower_mind.current)
		to_chat(follower_mind.current, "<span class='danger'><b>Your mind has been cleared from the deity's influence.</b></span>")
		follower_mind.current.visible_message("<span class='warning'>[follower_mind.current] looks like their faith is shattered!</span>")

/// Update antag HUD icons when a follower is added
/datum/game_mode/proc/update_hog_icons_added(datum/mind/hog_mind, side)
	var/datum/atom_hud/antag/hud = GLOB.huds[side == "red" ? ANTAG_HUD_HOG_RED : ANTAG_HUD_HOG_BLUE]
	if(!hud)
		return
	
	var/mob/M = hog_mind.current
	if(!M)
		return
	
	hud.join_hud(M)
	
	// Determine icon state based on rank
	var/rank = "follower"
	if(M.mind in (side == "red" ? red_deity_prophets : blue_deity_prophets))
		rank = "prophet"
	if(is_handofgod_god(M))
		rank = "god"
	
	set_antag_hud(M, "hog-[side]-[rank]")

/// Remove antag HUD icons when a follower is removed
/datum/game_mode/proc/update_hog_icons_removed(datum/mind/hog_mind, side)
	var/datum/atom_hud/antag/hud = GLOB.huds[side == "red" ? ANTAG_HUD_HOG_RED : ANTAG_HUD_HOG_BLUE]
	if(!hud)
		return
	
	var/mob/M = hog_mind.current
	if(M)
		hud.leave_hud(M)
		set_antag_hud(M, null)

/// Generate objectives for a deity
/datum/game_mode/proc/forge_deity_objectives(datum/mind/deity)
	// Pick 1-2 objectives
	var/num_objectives = pick(1, 1, 1, 2, 2)
	
	for(var/i in 1 to num_objectives)
		var/obj_type = pick(deity_objectives)
		var/datum/objective/O = new obj_type
		O.owner = deity
		O.find_target()
		deity.objectives += O

/// Greet a newly converted follower  
/datum/game_mode/proc/greet_hog_follower(datum/mind/follower_mind, colour)
	if(!colour)
		return
	
	var/mob/M = follower_mind.current
	if(!M)
		return
	
	if(follower_mind in (colour == "red" ? red_deity_prophets : blue_deity_prophets))
		to_chat(M, "<span class='danger'><B>You have been appointed as the prophet of the [colour] deity!</B></span>")
	else
		to_chat(M, "<span class='danger'><B>You are a follower of the [colour] cult!</B></span>")

/// Deconvert a follower (called from holy water, etc.)
/datum/game_mode/proc/deconvert_hog_follower(datum/mind/follower_mind)
	remove_hog_follower(follower_mind, announce = TRUE)
	follower_mind.special_role = null

/// Helper procs for checking roles
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

/proc/is_handofgod_redprophet(mob/M)
	if(!ishuman(M) || !M.mind)
		return FALSE
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	return (M.mind in mode.red_deity_prophets)

/proc/is_handofgod_blueprophet(mob/M)
	if(!ishuman(M) || !M.mind)
		return FALSE
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	return (M.mind in mode.blue_deity_prophets)
