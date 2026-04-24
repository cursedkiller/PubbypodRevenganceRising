/mob/camera/god
	name = "deity"
	real_name = "deity"
	desc = "A divine being watching over their followers."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "marker-neutral"
	invisibility = INVISIBILITY_OBSERVER
	see_in_dark = 0
	see_invisible = SEE_INVISIBLE_LIVING
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/team_colour = HOG_TEAM_RED
	var/faith = HOG_FAITH_STARTING
	var/max_faith = HOG_FAITH_MAX
	var/obj/structure/divine/nexus/god_nexus = null
	var/nexus_required = FALSE
	var/list/obj/structure/divine/structures = list()
	var/prophets_sacrificed_in_name = 0
	var/alive_followers = 0
	var/free_pylon_used = FALSE

/mob/camera/god/Initialize(mapload)
	. = ..()
	update_icons()
	addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), HOG_NEXUS_FORCE_TIME)
	addtimer(CALLBACK(src, PROC_REF(start_death_check)), 30 SECONDS)

/mob/camera/god/Destroy()
	if(god_nexus)
		QDEL_NULL(god_nexus)
	structures.Cut()
	return ..()

/mob/camera/god/proc/start_death_check()
	if(QDELETED(src))
		return
	refresh_followers()
	if(!god_nexus && !alive_followers)
		check_death()
	addtimer(CALLBACK(src, PROC_REF(start_death_check)), 30 SECONDS)

/mob/camera/god/proc/get_my_followers()
	RETURN_TYPE(/list)
	var/list/followers = list()
	for(var/datum/mind/mind as anything in SSticker.minds)
		if(!mind.current)
			continue
		if(!IS_HOG_CULTIST(mind.current))
			continue
		var/datum/antagonist/hog_cultist/cultist = mind.has_antag_datum(/datum/antagonist/hog_cultist)
		if(cultist?.cult_team?.team_colour == team_colour)
			followers += mind
	return followers

/mob/camera/god/proc/pick_deity_name()
	var/newname = tgui_input_text(src, "Choose your divine name:", "Divine Identity", real_name, MAX_NAME_LEN)
	if(newname)
		name = newname
		real_name = newname
		to_chat(src, span_notice("You shall be known as [newname]!"))

/mob/camera/god/proc/can_afford(faith_cost)
	if(faith < faith_cost)
		to_chat(src, span_warning("Not enough faith! You have [faith]/[faith_cost]."))
		return FALSE
	return TRUE

/mob/camera/god/proc/spend_faith(faith_cost)
	if(!can_afford(faith_cost))
		return FALSE
	faith = clamp(faith - faith_cost, 0, max_faith)
	update_faith_hud()
	return TRUE

/mob/camera/god/proc/force_place_nexus()
	if(god_nexus)
		return
	to_chat(src, span_danger("You failed to place your nexus in time! It has been placed for you."))
	place_nexus()

/mob/camera/god/proc/place_nexus()
	if(god_nexus)
		to_chat(src, span_warning("You already have a nexus! You cannot place another."))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/obj/structure/divine/nexus/N = new(T)
	N.assign_deity(src)
	god_nexus = N
	nexus_required = TRUE
	update_nexus_health_hud()
	to_chat(src, span_notice("You have placed your nexus! It will slowly heal over time."))

/mob/camera/god/proc/god_speak_input()
	if(!alive_followers)
		to_chat(src, span_warning("You have no followers to speak to!"))
		return
	var/msg = tgui_input_text(src, "Message to followers:", "Divine Telepathy", "", MAX_MESSAGE_LEN, multiline = TRUE)
	if(!msg)
		return
	god_speak(msg)

/mob/camera/god/proc/build_structure()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(HOG_FAITH_COST_STRUCTURE))
		return
	var/list/choices = list(
		"Power Pylon" = /obj/structure/divine/powerpylon,
		"Translocator" = /obj/structure/divine/translocator,
		"Forge" = /obj/structure/divine/forge,
		"Sacrifice Altar" = /obj/structure/divine/sacrificealtar,
		"Conversion Altar" = /obj/structure/divine/convertaltar,
		"Shrine" = /obj/structure/divine/shrine,
		"Fountain" = /obj/structure/divine/fountain,
		"Conduit" = /obj/structure/divine/conduit,
		"Lazarus" = /obj/structure/divine/lazarus,
		"Defense Pylon" = /obj/structure/divine/defensepylon,
	)
	var/chosen_name = tgui_input_list(src, "Choose a structure:", "Build Structure", choices)
	if(!chosen_name)
		return
	var/build_path = choices[chosen_name]
	if(build_path == /obj/structure/divine/defensepylon && !free_pylon_used)
		free_pylon_used = TRUE
		if(!spend_faith(HOG_FAITH_COST_STRUCTURE))
			free_pylon_used = FALSE
			return
		var/obj/structure/divine/defensepylon/P = new(get_turf(src))
		P.assign_deity(src)
		to_chat(src, span_notice("You manifest a defense pylon! Future pylons will require construction."))
		return
	if(!spend_faith(HOG_FAITH_COST_STRUCTURE))
		return
	var/obj/structure/divine/construction_holder/CH = new(get_turf(src))
	CH.assign_deity(src)
	CH.setup_construction(build_path)
	CH.visible_message(span_notice("A transparent, unfinished [chosen_name] appears!"))

/mob/camera/god/proc/place_trap()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(HOG_FAITH_COST_TRAP))
		return
	var/list/rune_choices = list(
		"Shock Trap" = /obj/structure/trap/stun,
		"Frost Trap" = /obj/structure/trap/damage,
		"Fire Trap" = /obj/structure/trap/fire,
		"Earth Trap" = /obj/structure/trap/damage,
		"Ward" = /obj/structure/divine/ward,
	)
	var/chosen_name = tgui_input_list(src, "Choose a rune to manifest:", "Rune Manifest", rune_choices)
	if(!chosen_name)
		return
	if(!spend_faith(HOG_FAITH_COST_TRAP))
		return
	var/trap_type = rune_choices[chosen_name]
	var/atom/T
	if(ispath(trap_type, /obj/structure/divine))
		T = new trap_type(get_turf(src))
		var/obj/structure/divine/D = T
		D.assign_deity(src)
	else
		T = new trap_type(get_turf(src))
		T.icon = 'icons/obj/hand_of_god_structures.dmi'
		switch(chosen_name)
			if("Shock Trap")
				T.icon_state = "trap-shock"
			if("Frost Trap")
				T.icon_state = "trap-frost"
			if("Fire Trap")
				T.icon_state = "trap-fire"
			if("Earth Trap")
				T.icon_state = "trap-earth"
	to_chat(src, span_notice("You manifest a [chosen_name]."))

/mob/camera/god/proc/smite_target()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(30))
		return
	var/list/targets = list()
	for(var/mob/living/H in view(7, src))
		if(!IS_HOG_CULTIST(H) && H.mind && H.stat != DEAD)
			targets += H
	if(!length(targets))
		to_chat(src, span_warning("No valid targets in range!"))
		return
	var/mob/living/target = tgui_input_list(src, "Choose a target to smite:", "Smite", targets)
	if(!target)
		return
	if(!spend_faith(30))
		return
	to_chat(target, span_userdanger("You are struck by divine wrath!"))
	target.adjustFireLoss(30)
	target.adjustBruteLoss(20)
	playsound(target, 'sound/machines/defib_zap.ogg', 50, 1)
	to_chat(src, span_notice("You smite [target]!"))

/mob/camera/god/proc/conjure_equipment()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(50))
		return
	var/list/followers = list()
	for(var/datum/mind/M in get_my_followers())
		if(M.current && M.current.stat != DEAD && ishuman(M.current))
			followers += M.current
	if(!length(followers))
		to_chat(src, span_warning("You have no living followers!"))
		return
	var/mob/living/carbon/human/target = tgui_input_list(src, "Grant equipment to:", "Conjure Equipment", followers)
	if(!target)
		return
	if(!spend_faith(50))
		return
	var/obj/item/melee/cultblade/dagger/D = new(target.loc)
	target.put_in_hands(D)
	target.equip_to_slot_or_del(new /obj/item/clothing/suit/hooded/cultrobes(target), ITEM_SLOT_OCLOTHING)
	to_chat(target, span_danger("Your deity grants you divine equipment!"))
	to_chat(src, span_notice("You grant equipment to [target]."))

/mob/camera/god/proc/conjure_calamity()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(100))
		return
	if(!spend_faith(100))
		return
	var/turf/T = get_turf(src)
	explosion(T, 0, 2, 4, 6)
	to_chat(src, span_userdanger("You unleash divine calamity!"))

/mob/camera/god/proc/obfuscate_structure()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(25))
		return
	var/list/structs = list()
	for(var/obj/structure/divine/S in structures)
		if(!istype(S, /obj/structure/divine/nexus))
			structs += S
	if(!length(structs))
		to_chat(src, span_warning("You have no structures to obfuscate!"))
		return
	var/obj/structure/divine/target = tgui_input_list(src, "Choose a structure to hide:", "Obfuscate Structure", structs)
	if(!target)
		return
	if(!spend_faith(25))
		return
	target.alpha = 50
	target.name = "mundane structure"
	target.desc = "Just a regular piece of station equipment."
	target.density = FALSE
	to_chat(src, span_notice("You obfuscate [target]. It can be revealed by clicking on it."))

/mob/camera/god/proc/appoint_prophet()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(40))
		return
	var/list/followers = list()
	for(var/datum/mind/M in get_my_followers())
		if(M.current && M.current.stat != DEAD && ishuman(M.current) && !IS_HOG_PROPHET(M.current))
			followers += M.current
	if(!length(followers))
		to_chat(src, span_warning("You have no eligible followers to promote!"))
		return
	var/mob/living/carbon/human/target = tgui_input_list(src, "Choose a follower to promote:", "Appoint Prophet", followers)
	if(!target)
		return
	if(!spend_faith(40))
		return
	target.mind.make_Handofgod_prophet(team_colour)
	to_chat(target, span_danger("<B>You have been appointed as the prophet of your deity!</B>"))
	to_chat(src, span_notice("You appoint [target] as your prophet."))

/mob/camera/god/proc/transmit_thought()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(35))
		return
	var/list/targets = list()
	for(var/mob/living/H in view(7, src))
		if(H.mind)
			targets += H
	for(var/obj/machinery/M in view(7, src))
		targets += M
	for(var/obj/structure/S in view(7, src))
		targets += S
	if(!length(targets))
		to_chat(src, span_warning("No valid targets in range!"))
		return
	var/atom/target = tgui_input_list(src, "Choose a target to speak through:", "Transmit Thought", targets)
	if(!target)
		return
	var/msg = tgui_input_text(src, "What message to broadcast?", "Transmit Thought", "", MAX_MESSAGE_LEN, multiline = TRUE)
	if(!msg)
		return
	if(!spend_faith(35))
		return
	target.visible_message(span_userdanger("<B>[target] booms with a divine voice: [msg]</B>"))
	to_chat(src, span_notice("Your voice echoes through [target]."))

/mob/camera/god/proc/update_nexus_health_hud()
	if(!hud_used?.deity_health_display || !god_nexus)
		return
	var/health_percent = 100
	if(god_nexus.max_integrity > 0)
		health_percent = round((god_nexus.get_integrity() / god_nexus.max_integrity) * 100)
	hud_used.deity_health_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='lime'>[health_percent]%</font></div>")

/mob/camera/god/proc/update_faith_hud()
	if(!hud_used?.deity_power_display)
		return
	hud_used.deity_power_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='cyan'>[faith]</font></div>")

/mob/camera/god/proc/update_follower_hud()
	if(!hud_used?.deity_follower_display)
		return
	hud_used.deity_follower_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='red'>[alive_followers]</font></div>")

/mob/camera/god/proc/update_all_huds()
	update_nexus_health_hud()
	update_faith_hud()
	update_follower_hud()

/mob/camera/god/proc/refresh_followers()
	alive_followers = 0
	for(var/datum/mind/mind as anything in get_my_followers())
		if(mind.current && mind.current.stat != DEAD)
			alive_followers++
	update_follower_hud()

/mob/camera/god/proc/check_death()
	if(!god_nexus && !alive_followers)
		to_chat(src, span_userdanger("Your nexus is destroyed and you have no followers left. Your existence fades away..."))
		qdel(src)

/mob/camera/god/proc/add_faith(amount)
	faith = clamp(faith + amount, 0, max_faith)
	update_faith_hud()

/mob/camera/god/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	if(client)
		if(stat)
			return
		if(client.handle_spam_prevention(message, MUTE_IC))
			return
	god_speak(message)

/mob/camera/god/proc/god_speak(msg)
	msg = trim(copytext_char(sanitize(msg), 1, MAX_MESSAGE_LEN))
	if(!msg)
		return
	var/rendered = "<font color='[team_colour]'><i><span class='game say'>Divine Telepathy,</i> <span class='name'>[name]</span> <span class='message'>[msg]</span></span></font>"
	to_chat(src, rendered)
	for(var/mob/M in GLOB.mob_list)
		if(IS_HOG_CULTIST(M))
			var/datum/antagonist/hog_cultist/cultist = M.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
			if(cultist?.cult_team?.team_colour == team_colour)
				to_chat(M, rendered)
		else if(IS_HOG_GOD(M))
			var/mob/camera/god/other_god = M
			if(other_god.team_colour == team_colour)
				to_chat(M, rendered)
		else if(isobserver(M))
			to_chat(M, "[rendered]")

/mob/camera/god/update_icons()
	icon_state = "marker-[team_colour]"

/mob/camera/god/Login()
	. = ..()
	if(hud_used)
		hud_used.hoggod_hud(src)
	pick_deity_name()
	to_chat(src, span_notice("You are a deity!"))
	to_chat(src, "You are worshipped by a cult. Use the buttons on your HUD to interact with the world.")

/mob/camera/god/Move(new_loc, direct)
	loc = new_loc

/mob/verb/become_red_god()
	set name = "Become Red God"
	set category = "Admin"

	if(!check_rights(R_ADMIN))
		return

	if(mind)
		mind.make_Handofgod_god(HOG_TEAM_RED)
		message_admins("[key_name_admin(src)] has become a Red Deity.")
		log_admin("[key_name(src)] has become a Red Deity.")

/mob/verb/become_blue_god()
	set name = "Become Blue God"
	set category = "Admin"

	if(!check_rights(R_ADMIN))
		return

	if(mind)
		mind.make_Handofgod_god(HOG_TEAM_BLUE)
		message_admins("[key_name_admin(src)] has become a Blue Deity.")
		log_admin("[key_name(src)] has become a Blue Deity.")
