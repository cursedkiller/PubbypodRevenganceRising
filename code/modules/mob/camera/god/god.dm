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
	var/image/ghostimage = null
	var/alive_followers = 0

/mob/camera/god/Initialize(mapload)
	. = ..()
	update_icons()
	addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), HOG_NEXUS_FORCE_TIME)

/mob/camera/god/Destroy()
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
		updateallghostimages()
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
		return FALSE
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	var/obj/structure/divine/nexus/N = new(T)
	N.assign_deity(src)
	god_nexus = N
	nexus_required = TRUE
	update_nexus_health_hud()
	return TRUE

/mob/camera/god/proc/update_nexus_health_hud()
	if(!hud_used?.deity_health_display || !god_nexus)
		return
	var/health_percent = round((god_nexus.obj_integrity / god_nexus.max_integrity) * 100)
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
		SEND_SIGNAL(src, COMSIG_HOG_DEITY_DEATH)
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
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
	ghostimage = image(icon, src, icon_state)
	GLOB.ghost_darkness_images |= ghostimage
	updateallghostimages()

/mob/camera/god/Login()
	. = ..()
	if(hud_used)
		hud_used.hoggod_hud(src)

	var/datum/action/cooldown/hog_place_nexus/nexus_action = new(src)
	nexus_action.Grant(src)

	var/datum/action/cooldown/hog_god_speak/speak_action = new(src)
	speak_action.Grant(src)

	var/datum/action/cooldown/hog_build_structure/build_action = new(src)
	build_action.Grant(src)

	var/datum/action/cooldown/hog_place_trap/trap_action = new(src)
	trap_action.Grant(src)

	to_chat(src, span_notice("You are a deity!"))
	to_chat(src, "You are worshipped by a cult. Place your <b>Nexus</b> to anchor yourself to this realm, or one will be placed for you in [HOG_NEXUS_FORCE_TIME/600] minutes.")

/mob/camera/god/Move(new_loc, direct)
	loc = new_loc
