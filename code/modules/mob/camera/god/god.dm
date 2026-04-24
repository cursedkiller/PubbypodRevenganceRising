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

/mob/camera/god/Initialize(mapload)
	. = ..()
	update_icons()
	addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), HOG_NEXUS_FORCE_TIME)

/mob/camera/god/Destroy()
	if(god_nexus)
		QDEL_NULL(god_nexus)
	structures.Cut()
	return ..()

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
		to_chat(src, span_warning("You already have a nexus!"))
		return
	var/turf/T = get_turf(src)
	if(!T)
		return
	var/obj/structure/divine/nexus/N = new(T)
	N.assign_deity(src)
	god_nexus = N
	nexus_required = TRUE
	update_nexus_health_hud()
	to_chat(src, span_notice("You have placed your nexus!"))

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
	var/list/choices = list("Defense Pylon" = /obj/structure/divine/defensepylon)
	var/chosen_name = tgui_input_list(src, "Choose a structure:", "Build Structure", choices)
	if(!chosen_name)
		return
	if(!spend_faith(HOG_FAITH_COST_STRUCTURE))
		return
	var/obj/structure/divine/construction_holder/CH = new(get_turf(src))
	CH.assign_deity(src)
	CH.setup_construction(choices[chosen_name])
	CH.visible_message(span_notice("A transparent, unfinished [chosen_name] appears!"))

/mob/camera/god/proc/place_trap()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(HOG_FAITH_COST_TRAP))
		return
	if(!spend_faith(HOG_FAITH_COST_TRAP))
		return
	new /obj/structure/divine/defensepylon(get_turf(src))
	to_chat(src, span_notice("You manifest a defense pylon."))

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
	if(!alive_followers)
		check_death()
	update_follower_hud()

/mob/camera/god/proc/check_death()
	if(!alive_followers)
		to_chat(src, span_userdanger("You no longer have any followers. Your existence fades away..."))
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
	to_chat(src, span_notice("You are a deity!"))
	to_chat(src, "You are worshipped by a cult. Use the buttons on your HUD to interact with the world.")

/mob/camera/god/Move(new_loc, direct)
	loc = new_loc
