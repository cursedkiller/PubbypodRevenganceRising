/// Hand of God - Deity mob

/mob/camera/god
	name = "deity"
	real_name = "deity"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "marker"
	invisibility = INVISIBILITY_OBSERVER
	see_in_dark = 0
	see_invisible = SEE_INVISIBLE_LIVING
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/side = "neutral"
	var/faith = 100
	var/max_faith = 100
	var/obj/structure/divine/nexus/god_nexus = null
	var/nexus_required = FALSE
	var/list/structures = list()
	var/prophets_sacrificed_in_name = 0
	var/image/ghostimage = null
	var/alive_followers = 0

/mob/camera/god/Initialize(mapload)
	. = ..()
	update_icons()
	var/datum/game_mode/mode = SSticker.mode
	if(istype(mode, /datum/game_mode/hand_of_god))
		addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), 15 MINUTES)

/mob/camera/god/Destroy()
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
		updateallghostimages()
	return ..()

/mob/camera/god/proc/get_my_followers()
	var/datum/game_mode/mode = SSticker.mode
	if(!istype(mode))
		return list()
	switch(side)
		if("red")
			return mode.red_deity_followers | mode.red_deity_prophets
		if("blue")
			return mode.blue_deity_followers | mode.blue_deity_prophets
	return list()

/mob/camera/god/proc/ability_cost(faith_cost, check_nexus = TRUE, check_followers = TRUE)
	if(faith < faith_cost)
		to_chat(src, "<span class='warning'>Not enough faith!</span>")
		return FALSE
	return TRUE

/mob/camera/god/proc/force_place_nexus()
	if(god_nexus)
		return
	place_nexus()

/mob/camera/god/proc/place_nexus()
	if(god_nexus)
		return FALSE
	var/obj/structure/divine/nexus/N = new(get_turf(src))
	N.assign_deity(src)
	god_nexus = N
	nexus_required = TRUE
	return TRUE

/mob/camera/god/proc/update_nexus_health_hud()
	if(!hud_used?.deity_health_display || !god_nexus)
		return
	var/health_percent = (god_nexus.obj_integrity / god_nexus.max_integrity) * 100
	hud_used.deity_health_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='lime'>[round(health_percent)]%</font></div>")

/mob/camera/god/proc/update_followers()
	alive_followers = 0
	for(var/datum/mind/F in get_my_followers())
		if(F.current && F.current.stat != DEAD)
			alive_followers++
	if(!alive_followers)
		check_death()
	if(hud_used?.deity_follower_display)
		hud_used.deity_follower_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='red'>[alive_followers]</font></div>")

/mob/camera/god/proc/check_death()
	if(!alive_followers)
		to_chat(src, "<span class='userdanger'>You no longer have any followers. You fade away...</span>")
		qdel(src)

/mob/camera/god/proc/add_faith(amount)
	faith = clamp(faith + amount, 0, max_faith)
	if(hud_used?.deity_power_display)
		hud_used.deity_power_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='cyan'>[faith]</font></div>")

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
	var/rendered = "<font color='[side]'><i><span class='game say'>Divine Telepathy,</i> <span class='name'>[name]</span> <span class='message'>[msg]</span></span></font>"
	to_chat(src, rendered)
	for(var/mob/M in GLOB.mob_list)
		if(M.mind in get_my_followers())
			to_chat(M, rendered)
		else if(isobserver(M))
			to_chat(M, "[rendered]")

/mob/camera/god/update_icons()
	icon_state = "[initial(icon_state)]-[side]"
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
	ghostimage = image(icon, src, icon_state)
	GLOB.ghost_darkness_images |= ghostimage
	updateallghostimages()

/mob/camera/god/Login()
	. = ..()
	if(hud_used)
		hud_used.hoggod_hud()
	to_chat(src, "<span class='notice'>You are a deity!</span>")
	to_chat(src, "You are worshipped by a cult. Place a <b>Nexus</b> to anchor yourself to this realm.")

/mob/camera/god/Move(new_loc, direct)
	loc = new_loc
