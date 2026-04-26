/mob/living/simple_animal/god
	name = "deity"
	real_name = "deity"
	desc = "A divine being watching over their followers."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "marker-neutral"
	mob_biotypes = MOB_SPIRIT
	incorporeal_move = INCORPOREAL_MOVE_EMINENCE
	invisibility = INVISIBILITY_OBSERVER
	health = INFINITY
	maxHealth = INFINITY
	plane = GHOST_PLANE
	healable = FALSE
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
	throwforce = 0
	see_in_dark = 5
	lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	unsuitable_atmos_damage = 0
	damage_coeff = list(BRUTE = 0, BURN = 0, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = INFINITY
	status_flags = 0
	wander = FALSE
	density = FALSE
	is_flying_animal = TRUE
	no_flying_animation = TRUE
	move_resist = MOVE_FORCE_OVERPOWERING
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	speed = 1
	unique_name = FALSE
	hud_possible = list(ANTAG_HUD)
	hud_type = /datum/hud

	var/team_colour = HOG_TEAM_RED
	var/faith = HOG_FAITH_STARTING
	var/max_faith = HOG_FAITH_MAX
	var/obj/structure/divine/nexus/god_nexus = null
	var/nexus_required = FALSE
	var/list/obj/structure/divine/structures = list()
	var/prophets_sacrificed_in_name = 0
	var/alive_followers = 0
	var/free_pylon_used = FALSE
	var/free_conversion_altar_used = FALSE
	/// Reference to the divine transmission spell
	var/datum/action/spell/pointed/divine_transmission/transmission_spell = null

/mob/living/simple_animal/god/Initialize(mapload)
	. = ..()
	grant_all_languages(source = LANGUAGE_CURATOR)
	update_icons()
	update_vision()
	addtimer(CALLBACK(src, PROC_REF(force_place_nexus)), HOG_NEXUS_FORCE_TIME)
	addtimer(CALLBACK(src, PROC_REF(start_death_check)), 30 SECONDS)
	addtimer(CALLBACK(src, PROC_REF(start_faith_regen)), 30 SECONDS)

/mob/living/simple_animal/god/Destroy()
	for(var/obj/item/radio/R in contents)
		qdel(R)
	if(god_nexus)
		QDEL_NULL(god_nexus)
	structures.Cut()
	transmission_spell = null
	REMOVE_TRAIT(src, TRAIT_SPEECH_BOOSTER, TRAIT_HOG)
	return ..()

/mob/living/simple_animal/god/ClickOn(atom/A, params)
	// Handle defense pylon toggling directly since we're on the ghost plane
	if(istype(A, /obj/structure/divine/defensepylon))
		var/obj/structure/divine/defensepylon/P = A
		if(!P.deity)
			to_chat(src, span_warning("This pylon is not connected to a deity!"))
			return
		if(team_colour != P.deity.team_colour)
			to_chat(src, span_warning("This pylon belongs to a different deity!"))
			return
		P.active = !P.active
		P.attacking = FALSE
		if(P.active)
			P.visible_message(span_notice("[P] hums to life."))
		else
			P.visible_message(span_notice("[P] powers down."))
		P.update_icon()
		return
	return ..()

/mob/living/simple_animal/god/UnarmedAttack(atom/A, proximity_flag, modifiers)
	return FALSE

/mob/living/simple_animal/god/start_pulling(atom/movable/AM, state, force = move_force, supress_message = FALSE)
	return FALSE

/mob/living/simple_animal/god/proc/update_vision()
	if(!nexus_required)
		sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
		see_in_dark = world.view
		return
	see_in_dark = 3
	if(alive_followers > 0)
		see_in_dark = 5
	var/near_structure = FALSE
	if(god_nexus && get_dist(src, god_nexus) <= 20)
		near_structure = TRUE
	else
		for(var/obj/structure/divine/conduit/C in structures)
			if(get_dist(src, C) <= 20)
				near_structure = TRUE
				break
	if(near_structure)
		sight = SEE_TURFS | SEE_MOBS | SEE_OBJS | SEE_SELF
		see_in_dark = 20

/mob/living/simple_animal/god/proc/can_place_here(turf/T)
	if(!nexus_required)
		return TRUE
	if(god_nexus && get_dist(T, god_nexus) <= 20)
		return TRUE
	for(var/obj/structure/divine/conduit/C in structures)
		if(get_dist(T, C) <= 20)
			return TRUE
	return FALSE

/mob/living/simple_animal/god/Move(new_loc, direct)
	if(!nexus_required)
		return ..()
	if(!can_place_here(new_loc))
		if(client)
			to_chat(src, span_warning("You cannot stray from your domain! Build conduits to expand your reach."))
		return FALSE
	return ..()

/mob/living/simple_animal/god/forceMove(atom/destination)
	if(nexus_required && !can_place_here(get_turf(destination)))
		return FALSE
	return ..()

/mob/living/simple_animal/god/proc/start_death_check()
	if(QDELETED(src))
		return
	update_vision()
	refresh_followers()
	check_death()
	addtimer(CALLBACK(src, PROC_REF(start_death_check)), 30 SECONDS)

/mob/living/simple_animal/god/proc/start_faith_regen()
	if(QDELETED(src))
		return
	update_vision()
	regenerate_faith()
	addtimer(CALLBACK(src, PROC_REF(start_faith_regen)), 30 SECONDS)

/mob/living/simple_animal/god/proc/regenerate_faith()
	var/regen_amount = 1
	if(god_nexus)
		regen_amount += 1
	for(var/obj/structure/divine/conduit/C in structures)
		regen_amount += 1
	for(var/obj/structure/divine/powerpylon/P in structures)
		regen_amount += 1
	regen_amount += round(alive_followers * 0.5)
	add_faith(regen_amount)

/mob/living/simple_animal/god/proc/get_my_followers()
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

/mob/living/simple_animal/god/proc/pick_deity_name()
	var/newname = tgui_input_text(src, "Choose your divine name:", "Divine Identity", real_name, MAX_NAME_LEN)
	if(newname)
		name = newname
		real_name = newname
		to_chat(src, span_notice("You shall be known as [newname]!"))

/mob/living/simple_animal/god/proc/can_afford(faith_cost)
	if(faith < faith_cost)
		to_chat(src, span_warning("Not enough faith! You have [faith]/[faith_cost]."))
		return FALSE
	return TRUE

/mob/living/simple_animal/god/proc/spend_faith(faith_cost)
	if(!can_afford(faith_cost))
		return FALSE
	faith = clamp(faith - faith_cost, 0, max_faith)
	update_faith_hud()
	return TRUE

/mob/living/simple_animal/god/proc/force_place_nexus()
	if(god_nexus)
		return
	to_chat(src, span_danger("You failed to place your nexus in time! It has been placed for you."))
	place_nexus()

/mob/living/simple_animal/god/proc/place_nexus()
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
	update_vision()
	to_chat(src, span_notice("You have placed your nexus! It will slowly heal over time."))

/mob/living/simple_animal/god/proc/build_structure()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_place_here(get_turf(src)))
		to_chat(src, span_warning("Your domain hasn't reached this area! Build conduits to expand your reach."))
		return
	ui_interact(src)

/mob/living/simple_animal/god/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DeityStructures", "Divine Structures")
		ui.open()

/mob/living/simple_animal/god/ui_data(mob/user)
	var/list/data = list()
	data["faith"] = faith
	data["max_faith"] = max_faith
	data["team_colour"] = team_colour

	var/list/structures = list()
	var/list/available = list(
		"Power Pylon" = list(/obj/structure/divine/powerpylon, "powerpylon-red", "Increases your Divine presence and bolsters the strength of your miracles.", "10 Iron", FALSE),
		"Translocator" = list(/obj/structure/divine/translocator, "translocator-red", "Link portals together to create a gateway between locations.", "10 Iron", FALSE),
		"Forge" = list(/obj/structure/divine/forge, "forge-red", "Permit mortals to manipulate ichor to forge weapons of war.", "10 Iron", FALSE),
		"Sacrifice Altar" = list(/obj/structure/divine/sacrificealtar, "sacrificealtar-red", "Trade blood for faith or rival souls for boons.", "25 Iron, 10 Glass", FALSE),
		"Conversion Altar" = list(/obj/structure/divine/convertaltar, "convertaltar-red", "Convert the masses to your whims, as long as their minds are willing to learn.", "25 Rods, 10 Glass", !free_conversion_altar_used),
		"Shrine" = list(/obj/structure/divine/shrine, "Shrine-red", "An idol to inspire and bolster the strength of your following.", "10 Iron", FALSE),
		"Fountain" = list(/obj/structure/divine/fountain, "fountain-red", "Produces the waters of life and death to cure ailments or deliver them.", "10 Iron", FALSE),
		"Conduit" = list(/obj/structure/divine/conduit, "conduit-red", "Increases faith generation and the reach of your domain.", "10 Iron", FALSE),
		"Lazarus" = list(/obj/structure/divine/lazarus, "lazarus-red", "Imbue the dead with your power to resurrect them, or maybe even yourself...", "10 Iron", FALSE),
		"Defense Pylon" = list(/obj/structure/divine/defensepylon, "defensepylon-red", "Automatically fires upon non-believers. Toggle on/off with Left Click.", "10 Iron", !free_pylon_used),
	)

	for(var/name in available)
		var/list/info = available[name]
		structures += list(list(
			"name" = name,
			"path" = "[info[1]]",
			"icon" = "icons/obj/hand_of_god_structures.dmi",
			"icon_state" = info[2],
			"desc" = info[3],
			"cost" = HOG_FAITH_COST_STRUCTURE,
			"materials" = info[4],
			"free" = info[5],
		))

	data["structures"] = structures
	return data

/mob/living/simple_animal/god/ui_act(action, params)
	. = ..()
	if(action != "build")
		return

	var/build_path = text2path(params["path"])
	if(!build_path)
		return

	if(build_path == /obj/structure/divine/defensepylon && !free_pylon_used)
		free_pylon_used = TRUE
		var/obj/structure/divine/defensepylon/P = new(get_turf(src))
		P.assign_deity(src)
		to_chat(src, span_notice("You manifest a defense pylon! Future pylons will require construction."))
		. = TRUE
		return

	if(build_path == /obj/structure/divine/convertaltar && !free_conversion_altar_used)
		free_conversion_altar_used = TRUE
		var/obj/structure/divine/convertaltar/A = new(get_turf(src))
		A.assign_deity(src)
		to_chat(src, span_notice("You manifest a conversion altar! Future altars will require construction."))
		. = TRUE
		return

	if(!spend_faith(HOG_FAITH_COST_STRUCTURE))
		return
	var/obj/structure/divine/construction_holder/CH = new(get_turf(src))
	CH.assign_deity(src)
	CH.setup_construction(build_path)
	CH.visible_message(span_notice("A transparent, unfinished [CH.name] appears!"))
	. = TRUE

/mob/living/simple_animal/god/proc/place_trap()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_place_here(get_turf(src)))
		to_chat(src, span_warning("Your domain hasn't reached this area!"))
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

/mob/living/simple_animal/god/proc/smite_target()
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

/mob/living/simple_animal/god/proc/conjure_equipment()
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

/mob/living/simple_animal/god/proc/conjure_calamity()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_place_here(get_turf(src)))
		to_chat(src, span_warning("Your domain hasn't reached this area!"))
		return
	if(!can_afford(100))
		return
	var/picked_event = tgui_input_list(src, "Choose a calamity to unleash:", "Conjure Calamity", list(
		"Obsession Awakening",
		"Sentient Animals",
		"Revenant Spawn",
		"Portal Storm (Cult)",
		"Fugitives",
		"Mass Hallucination",
		"Disease Outbreak",
		"False Alarm",
		"Communications Blackout",
		"Camera Failure",
		"Electrical Storm",
		"Grid Check",
		"Anomaly: Energetic Flux",
		"Anomaly: Pyroclastic",
		"Anomaly: Gravitational",
		"Anomaly: Bluespace",
		"Anomaly: Vortex",
		"Radiation Storm",
	))
	if(!picked_event)
		return
	if(!spend_faith(100))
		return
	for(var/datum/round_event_control/E in SSevents.control)
		if(E.name == picked_event)
			E.preRunEvent()
			E.runEvent()
			SSevents.reschedule()
			to_chat(src, span_userdanger("You unleash [picked_event] upon the station!"))
			message_admins("[key_name(src)] has triggered [picked_event] via Conjure Calamity.")
			return
	to_chat(src, span_warning("Failed to trigger that event."))

/mob/living/simple_animal/god/proc/obfuscate_structure()
	if(!god_nexus)
		to_chat(src, span_warning("You must place your nexus first!"))
		return
	if(!can_afford(50))
		return
	if(!spend_faith(50))
		return
	for(var/obj/structure/divine/S in structures)
		if(istype(S, /obj/structure/divine/nexus))
			continue
		S.alpha = 15
		S.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		S.name = "mundane structure"
		S.desc = "Just a regular piece of station equipment."
		for(var/mob/M in GLOB.player_list)
			if(!M.client)
				continue
			if(IS_HOG_CULTIST(M))
				var/datum/antagonist/hog_cultist/C = M.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
				if(C?.cult_team?.team_colour == team_colour)
					M.client.images |= S
					continue
			if(IS_HOG_GOD(M))
				M.client.images |= S
				continue
			M.client.images -= S
	to_chat(src, span_notice("Your structures fade into near-invisibility, appearing as mundane objects to non-believers."))

/mob/living/simple_animal/god/proc/appoint_prophet()
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

/mob/living/simple_animal/god/proc/update_nexus_health_hud()
	if(!hud_used?.deity_health_display || !god_nexus)
		return
	var/health_percent = 100
	if(god_nexus.max_integrity > 0)
		health_percent = round((god_nexus.get_integrity() / god_nexus.max_integrity) * 100)
	hud_used.deity_health_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='lime'>[health_percent]%</font></div>")

/mob/living/simple_animal/god/proc/update_faith_hud()
	if(!hud_used?.deity_power_display)
		return
	hud_used.deity_power_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='cyan'>[faith]</font></div>")

/mob/living/simple_animal/god/proc/update_follower_hud()
	if(!hud_used?.deity_follower_display)
		return
	hud_used.deity_follower_display.maptext = MAPTEXT("<div align='center' valign='middle'><font color='red'>[alive_followers]</font></div>")

/mob/living/simple_animal/god/proc/update_all_huds()
	update_nexus_health_hud()
	update_faith_hud()
	update_follower_hud()

/mob/living/simple_animal/god/proc/refresh_followers()
	alive_followers = 0
	for(var/datum/mind/mind as anything in get_my_followers())
		if(mind.current && mind.current.stat != DEAD)
			alive_followers++
	max_faith = HOG_FAITH_MAX + (alive_followers * 20)
	update_follower_hud()

/mob/living/simple_animal/god/proc/check_death()
	if(!nexus_required)
		return
	if(!god_nexus && !alive_followers)
		to_chat(src, span_userdanger("Your nexus is destroyed and you have no followers left. Your existence fades away..."))
		qdel(src)

/mob/living/simple_animal/god/proc/add_faith(amount)
	faith = clamp(faith + amount, 0, max_faith)
	update_faith_hud()

/mob/living/simple_animal/god/say(message, bubble_type, list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	if(!message)
		return
	if(client)
		if(stat)
			return
		if(client.handle_spam_prevention(message, MUTE_IC))
			return
	god_speak(message)

/mob/living/simple_animal/god/proc/god_speak(msg)
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
			var/mob/living/simple_animal/god/other_god = M
			if(other_god.team_colour == team_colour)
				to_chat(M, rendered)
		else if(isobserver(M))
			to_chat(M, "[rendered]")

/mob/living/simple_animal/god/update_icons()
	icon_state = "marker-[team_colour]"

/mob/living/simple_animal/god/Login()
	. = ..()
	if(hud_used)
		hud_used.hoggod_hud(src)
	update_vision()

	// Only ask for a name on first login, not relogs
	if(name == initial(name) || name == "deity")
		pick_deity_name()

	// Give debug-level radio access (all channels including syndicate and centcom)
	var/obj/item/radio/headset/headset_cent/debug/god_radio = new(src)
	god_radio.set_frequency(FREQ_COMMON)
	god_radio.command = TRUE

	// Make the god's voice naturally loud (loudspeaker effect)
	ADD_TRAIT(src, TRAIT_SPEECH_BOOSTER, TRAIT_HOG)

	// Set up the Divine Transmission spell (HUD button handles activation)
	if(!transmission_spell)
		transmission_spell = new(src)

	to_chat(src, span_notice("You are a deity!"))
	to_chat(src, "You are worshipped by a cult. Use the buttons on your HUD to interact with the world.")
	to_chat(src, "Use Divine Transmission to speak through a mortal vessel. Use the Navigate button to jump to your nexus or followers.")

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
