/// Hand of God - The Deity mob
/// A camera mob that commands followers and places divine structures

/mob/camera/god
	name = "deity"
	real_name = "deity"
	icon = 'icons/mob/mob.dmi'
	icon_state = "marker"
	invisibility = INVISIBILITY_OBSERVER
	see_in_dark = 0
	see_invisible = SEE_INVISIBLE_LIVING
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	
	/// Red or Blue
	var/side = "neutral"
	/// Current faith resource
	var/faith = 100
	/// Maximum faith
	var/max_faith = 100
	/// The god's anchor in the world
	var/obj/structure/divine/nexus/god_nexus = null
	/// Has the nexus been placed
	var/nexus_required = FALSE
	/// List of divine structures
	var/list/structures = list()
	/// Number of prophets sacrificed
	var/prophets_sacrificed_in_name = 0
	/// Image for ghost visibility
	var/image/ghostimage = null
	/// Living followers
	var/alive_followers = 0
	
	/// Is valid for the gamemode
	var/datum/action/innate/godspeak/speak2god

/mob/camera/god/Initialize(mapload)
	. = ..()
	update_icons()
	
	// Force nexus placement after 15 minutes
	if(SSticker?.mode && istype(SSticker.mode, /datum/game_mode/hand_of_god))
		addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), 15 MINUTES)

/mob/camera/god/Destroy()
	var/list/followers = get_my_followers()
	for(var/datum/mind/F in followers)
		if(F.current)
			to_chat(F.current, "<span class='userdanger'>Your god is DEAD!</span>")
	
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
		updateallghostimages()
	
	return ..()

/// Get all followers of this deity
/mob/camera/god/proc/get_my_followers()
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return list()
	
	switch(side)
		if("red")
			return mode.red_deity_followers | mode.red_deity_prophets
		if("blue")
			return mode.blue_deity_followers | mode.blue_deity_prophets
	
	return list()

/// Check if we have enough faith for an ability
/mob/camera/god/proc/ability_cost(faith_cost, check_nexus = TRUE, check_followers = TRUE)
	if(faith < faith_cost)
		to_chat(src, "<span class='warning'>Not enough faith! ([faith]/[faith_cost])</span>")
		return FALSE
	if(check_nexus && !god_nexus)
		to_chat(src, "<span class='warning'>You need a nexus placed first!</span>")
		return FALSE
	if(check_followers && !alive_followers)
		to_chat(src, "<span class='warning'>You need at least one living follower!</span>")
		return FALSE
	return TRUE

/// Force place nexus if not done
/mob/camera/god/proc/force_place_nexus()
	if(god_nexus)
		return
	
	if(ability_cost(0, FALSE, FALSE))
		place_nexus()
	else
		place_nexus() // Force it anyway
		to_chat(src, "<span class='danger'>Your nexus has been placed for you!</span>")

/// Place the god's nexus in the world
/mob/camera/god/proc/place_nexus()
	if(god_nexus || z != 1)
		return FALSE
	
	// Create nexus at god's location
	var/turf/T = get_turf(src)
	if(!T)
		return FALSE
	
	var/obj/structure/divine/nexus/N = new(T)
	N.assign_deity(src)
	god_nexus = N
	nexus_required = TRUE
	
	var/area/A = get_area(src)
	if(A)
		for(var/datum/mind/F in get_my_followers())
			if(F.current)
				to_chat(F.current, "<span class='boldnotice'>Your god's nexus has been placed in \the [A.name]!</span>")
	
	update_health_hud()
	return TRUE

/// Update HUD health display
/mob/camera/god/proc/update_health_hud()
	if(!hud_used?.deity_health_display || !god_nexus)
		return
	
	var/health_percent = (god_nexus.obj_integrity / god_nexus.max_integrity) * 100
	hud_used.deity_health_display.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='lime'>[round(health_percent)]%</font></div>")

/// Update follower count display
/mob/camera/god/proc/update_followers()
	alive_followers = 0
	for(var/datum/mind/F in get_my_followers())
		if(F.current && F.current.stat != DEAD)
			alive_followers++
	
	if(!alive_followers)
		check_death()
	
	if(hud_used?.deity_follower_display)
		hud_used.deity_follower_display.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='red'>[alive_followers]</font></div>")

/// Check if god should die
/mob/camera/god/proc/check_death()
	if(!alive_followers)
		to_chat(src, "<span class='userdanger'>You no longer have any followers. Your existence fades...</span>")
		qdel(src)

/// Add faith to the pool
/mob/camera/god/proc/add_faith(amount)
	if(amount)
		faith = clamp(faith + amount, 0, max_faith)
		if(hud_used?.deity_power_display)
			hud_used.deity_power_display.maptext = MAPTEXT("<div align='center' valign='middle' style='position:relative; top:0px; left:6px'><font color='cyan'>[faith]</font></div>")

/// Deity speech
/mob/camera/god/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	
	if(client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, "<span class='warning'>You cannot send IC messages (muted).</span>")
			return
		if(!ignore_spam && client.handle_spam_prevention(message, MUTE_IC))
			return
	
	if(stat)
		return
	
	god_speak(message)

/// Broadcast speech to followers
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
			to_chat(M, "<a href='?src=[REF(M)];follow=[REF(src)]'>(F)</a> [rendered]")

/// Update icon based on side
/mob/camera/god/update_icons()
	icon_state = "[initial(icon_state)]-[side]"
	
	if(ghostimage)
		GLOB.ghost_darkness_images -= ghostimage
	
	ghostimage = image(icon, src, icon_state)
	GLOB.ghost_darkness_images |= ghostimage
	updateallghostimages()

/mob/camera/god/Login()
	. = ..()
	to_chat(src, "<span class='notice'>You are a deity!</span>")
	to_chat(src, "You are worshipped by a cult and can interact with the world through your followers.")
	to_chat(src, "Place a <b>Nexus</b> to anchor yourself to this realm. You have 15 minutes.")

/mob/camera/god/Move(new_loc, direct)
	loc = new_loc
