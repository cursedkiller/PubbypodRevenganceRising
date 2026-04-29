// Soul Trapped system - prevents revival and shows custom examine text
/mob/living/proc/set_soul_trapped()
	ADD_TRAIT(src, TRAIT_SOUL_TRAPPED, REF(src))

/mob/living/proc/clear_soul_trapped()
	REMOVE_TRAIT(src, TRAIT_SOUL_TRAPPED, REF(src))

/mob/living/proc/is_soul_trapped()
	return HAS_TRAIT(src, TRAIT_SOUL_TRAPPED)

/obj/structure/divine
	name = "divine structure"
	desc = "A structure built by the followers of a deity."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	light_range = 2
	light_color = null
	var/mob/living/simple_animal/god/deity = null
	var/is_trap = FALSE
	var/is_construction_holder = FALSE

/obj/structure/divine/proc/assign_deity(mob/living/simple_animal/god/G)
	deity = G
	if(G)
		LAZYADD(G.structures, src)
		update_icon()

/obj/structure/divine/Destroy()
	if(deity)
		LAZYREMOVE(deity.structures, src)
		deity = null
	return ..()

/obj/structure/divine/update_icon()
	if(!deity)
		return
	icon_state = "[initial(icon_state)]-[deity.team_colour]"
	if(deity.team_colour == HOG_TEAM_RED)
		light_color = LIGHT_COLOR_RED
	else
		light_color = LIGHT_COLOR_BLUE
	set_light(2)


// ============================================================
// NEXUS
// ============================================================

/obj/structure/divine/nexus
	name = "nexus"
	desc = "The anchor of a deity in this realm. A vessel bound here can be possessed by the god."
	icon_state = "nexus"
	max_integrity = HOG_NEXUS_MAX_INTEGRITY
	light_range = 4
	can_buckle = TRUE
	buckle_lying = 90
	dir = SOUTH

/obj/structure/divine/nexus/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(dir_changed))
	START_PROCESSING(SSobj, src)

/obj/structure/divine/nexus/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
	STOP_PROCESSING(SSobj, src)
	if(deity)
		deity.god_nexus = null
		to_chat(deity, span_userdanger("Your nexus has been destroyed!"))
		SEND_SIGNAL(src, COMSIG_HOG_NEXUS_DESTROYED, deity)
		deity.refresh_followers()
		deity.check_death()
	return ..()

/obj/structure/divine/nexus/proc/dir_changed(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	switch(new_dir)
		if(WEST, SOUTH)
			buckle_lying = 90
		if(EAST, NORTH)
			buckle_lying = 270

/obj/structure/divine/nexus/post_buckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_warning("[M] is pulled into the nexus, divine energy crackling around them!"), span_userdanger("You are bound to the nexus! Divine power courses through you..."))

/obj/structure/divine/nexus/post_unbuckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_notice("[M] is released from the nexus."), span_notice("The divine grip releases you."))

/obj/structure/divine/nexus/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(buckled_mob != user)
		buckled_mob.visible_message(
			span_danger("[user] tries to pull [buckled_mob] from the nexus!"),
			span_danger("You attempt to release [buckled_mob] from the nexus..."))
		if(!do_after(user, 10 SECONDS, buckled_mob))
			return FALSE
	return ..()

/obj/structure/divine/nexus/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!has_buckled_mobs() || !isliving(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/mob/living/buckled_person = pick(buckled_mobs)
	if(buckled_person)
		if(IS_HOG_CULTIST(user) || IS_HOG_GOD(user))
			unbuckle_mob(buckled_person)
		else
			user_unbuckle_mob(buckled_person, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/divine/nexus/MouseDrop_T(atom/dropped, mob/user)
	if(!ishuman(dropped))
		return
	if(!deity)
		return
	var/mob/living/carbon/human/target = dropped
	if(target.buckled)
		to_chat(user, span_warning("[target] is already buckled to something!"))
		return
	if(has_buckled_mobs())
		to_chat(user, span_warning("Someone is already bound to the nexus! Remove them first."))
		return
	if(user == target)
		user.visible_message(span_notice("[user] climbs onto the nexus..."), span_notice("You climb onto the nexus..."))
	else
		user.visible_message(span_warning("[user] starts dragging [target] onto the nexus..."), span_notice("You start binding [target] to the nexus..."))
	if(!do_after(user, 3 SECONDS, target))
		return
	target.forceMove(get_turf(src))
	if(!buckle_mob(target))
		to_chat(user, span_warning("Failed to bind [target] to the nexus."))
		return
	to_chat(user, span_notice("[target] is now bound to the nexus."))

/obj/structure/divine/nexus/process(delta_time)
	var/current_integrity = get_integrity()
	if(current_integrity < max_integrity)
		repair_damage(2)
		if(deity)
			deity.update_nexus_health_hud()

/obj/structure/divine/nexus/update_icon()
	if(!deity)
		return
	icon_state = "[initial(icon_state)]-[deity.team_colour]"
	if(deity.team_colour == HOG_TEAM_RED)
		light_color = LIGHT_COLOR_RED
	else
		light_color = LIGHT_COLOR_BLUE
	set_light(4)


// ============================================================
// DEFENSE PYLON
// ============================================================

/obj/structure/divine/defensepylon
	name = "defense pylon"
	desc = "A defensive structure that attacks non-believers. Click to toggle on/off."
	icon_state = "defensepylon"
	max_integrity = 200
	var/active = TRUE
	var/last_shot = 0
	var/cooldown = 1.5 SECONDS
	var/attacking = FALSE

/obj/structure/divine/defensepylon/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	update_icon()

/obj/structure/divine/defensepylon/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/divine/defensepylon/process(delta_time)
	if(!deity || !active || attacking)
		return
	if(world.time < last_shot + cooldown)
		return
	var/list/targets = list()
	for(var/mob/living/L in view(5, src))
		if(L.stat == DEAD)
			continue
		if(IS_HOG_GOD(L))
			continue
		if(isobserver(L))
			continue
		if(IS_HOG_CULTIST(L))
			var/datum/antagonist/hog_cultist/C = L.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
			if(C?.cult_team?.team_colour == deity.team_colour)
				continue
		if(L.invisibility > SEE_INVISIBLE_LIVING)
			continue
		targets += L
	if(!length(targets))
		return
	var/mob/living/target = pick(targets)
	attacking = TRUE
	last_shot = world.time
	update_icon()
	visible_message(span_warning("[src] fires a blast of divine energy at [target]!"))
	var/obj/projectile/divine_blast/bolt = new /obj/projectile/divine_blast(get_turf(src))
	bolt.firer = src
	bolt.light_color = deity.team_colour == HOG_TEAM_RED ? LIGHT_COLOR_RED : LIGHT_COLOR_BLUE
	bolt.preparePixelProjectile(target, src)
	bolt.fire()
	addtimer(CALLBACK(src, PROC_REF(reset_attack)), 0.5 SECONDS)

/obj/structure/divine/defensepylon/proc/reset_attack()
	attacking = FALSE
	update_icon()

/obj/structure/divine/defensepylon/update_icon()
	if(!deity)
		icon_state = "defensepylon"
		return
	if(attacking)
		icon_state = "defensepylonattack-[deity.team_colour]"
	else if(active)
		icon_state = "[initial(icon_state)]-[deity.team_colour]"
	else
		icon_state = initial(icon_state)

/obj/projectile/divine_blast
	name = "divine blast"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "divine_blast"
	damage = 17
	damage_type = BURN
	light_color = LIGHT_COLOR_RED
	light_range = 2
	speed = 0.8
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser

/obj/projectile/divine_blast/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.adjustFireLoss(5)


// ============================================================
// POWER PYLON
// ============================================================

/obj/structure/divine/powerpylon
	name = "power pylon"
	desc = "Generates faith for your deity and amplifies Smite power globally and locally."
	icon_state = "powerpylon"
	max_integrity = 150


// ============================================================
// TRANSLOCATOR
// ============================================================

/obj/structure/divine/translocator
	name = "translocator"
	desc = "A divine portal that allows instantaneous travel between linked translocators. Simply walk into it."
	icon_state = "translocator"
	max_integrity = 200
	density = TRUE
	anchored = TRUE
	light_range = 2
	var/list/obj/structure/divine/translocator/linked = list()
	var/list/mob/entering_mobs = list()
	var/list/mob/traveling_mobs = list()

/obj/structure/divine/translocator/Initialize(mapload)
	. = ..()
	update_icon()

/obj/structure/divine/translocator/Destroy()
	for(var/obj/structure/divine/translocator/T in linked)
		T.linked -= src
		T.update_icon()
		for(var/mob/living/L in range(2, get_turf(T)))
			L.Knockdown(5 SECONDS)
			to_chat(L, span_userdanger("The translocator violently destabilizes as its link is severed!"))
		playsound(T, 'sound/machines/terminal_off.ogg', 50, TRUE)
	visible_message(span_danger("[src] destabilizes and collapses in a violent explosion!"))
	explosion(src, light_impact_range = 2, flash_range = 5, flame_range = 4)
	linked.Cut()
	GLOB.all_translocators -= src
	return ..()

/obj/structure/divine/translocator/update_icon()
	if(!deity)
		icon_state = "translocator"
		return
	icon_state = "translocator-[deity.team_colour]"
	if(deity.team_colour == HOG_TEAM_RED)
		light_color = LIGHT_COLOR_RED
	else
		light_color = LIGHT_COLOR_BLUE
	set_light(2)

/obj/structure/divine/translocator/Bumped(atom/movable/AM)
	. = ..()
	if(!ishuman(AM))
		return
	if(!deity)
		return
	var/mob/living/carbon/human/H = AM
	if(H in entering_mobs)
		return
	if(H in traveling_mobs)
		return
	if(IS_HOG_CULTIST(H))
		var/datum/antagonist/hog_cultist/C = H.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour != deity.team_colour)
			to_chat(H, span_warning("The rival deity's translocator rejects you!"))
			return
	if(!length(linked))
		to_chat(H, span_warning("This translocator has no linked destinations."))
		return
	for(var/obj/structure/divine/translocator/T in linked)
		if(QDELETED(T))
			linked -= T
	if(!length(linked))
		to_chat(H, span_warning("This translocator has no linked destinations."))
		return
	var/list/destinations = list()
	for(var/obj/structure/divine/translocator/T in linked)
		var/turf/TT = get_turf(T)
		destinations["Translocator [get_area_name(T, TRUE)] ([TT.x],[TT.y])"] = T
	var/obj/structure/divine/translocator/target
	if(destinations.len == 1)
		target = destinations[destinations[1]]
	else
		var/chosen = tgui_input_list(H, "Select destination:", "Translocator", sort_list(destinations))
		if(!chosen)
			return
		target = destinations[chosen]
	if(!target || QDELETED(target))
		return
	entering_mobs += H
	var/job_name = H.mind?.assigned_role ? H.mind.assigned_role : "Unknown"
	to_chat(deity, span_boldnotice("[icon2html(src, deity)] [H] ([job_name]) begins entering the translocator to [get_area_name(target, TRUE)]."))
	H.visible_message(span_notice("[H] begins stepping into the translocator..."), span_notice("Reality begins to warp around you..."))
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)
	traveling_mobs += H
	to_chat(deity, span_boldnotice("[icon2html(src, deity)] [H] ([job_name]) is in transit to [get_area_name(target, TRUE)]. <a href='?src=[REF(deity)];eject_transit=[REF(H)]'>EJECT FROM TRANSIT</a>"))
	to_chat(H, span_notice("You feel yourself being pulled through the void..."))
	if(!do_after(H, 6 SECONDS, src))
		entering_mobs -= H
		traveling_mobs -= H
		to_chat(deity, span_warning("[H]'s transit was interrupted."))
		to_chat(H, span_warning("Your transit through the void was interrupted!"))
		return
	entering_mobs -= H
	if(!(H in traveling_mobs))
		return
	traveling_mobs -= H
	if(!target || QDELETED(target))
		to_chat(H, span_warning("The destination no longer exists!"))
		return
	H.visible_message(span_notice("[H] vanishes into the translocator!"), span_notice("Reality warps around you..."))
	var/turf/dest = get_turf(target)
	H.forceMove(dest)
	H.setDir(SOUTH)
	playsound(dest, 'sound/magic/blink.ogg', 50, TRUE)
	H.visible_message(span_notice("[H] materializes from thin air!"), span_notice("You arrive at your destination!"))
	to_chat(deity, span_notice("[H] successfully arrived at [get_area_name(target, TRUE)]."))

/obj/structure/divine/translocator/MouseDrop_T(atom/movable/dropped, mob/user)
	if(!ishuman(dropped) || !ishuman(user))
		return
	if(user == dropped)
		return
	if(!deity)
		return
	var/mob/living/carbon/human/target = dropped
	if(target in entering_mobs)
		return
	if(target in traveling_mobs)
		return
	if(IS_HOG_CULTIST(target))
		var/datum/antagonist/hog_cultist/C = target.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour != deity.team_colour)
			to_chat(user, span_warning("The rival deity's translocator rejects [target]!"))
			return
	if(!length(linked))
		to_chat(user, span_warning("This translocator has no linked destinations."))
		return
	for(var/obj/structure/divine/translocator/T in linked)
		if(QDELETED(T))
			linked -= T
	if(!length(linked))
		to_chat(user, span_warning("This translocator has no linked destinations."))
		return
	var/list/destinations = list()
	for(var/obj/structure/divine/translocator/T in linked)
		var/turf/TT = get_turf(T)
		destinations["Translocator [get_area_name(T, TRUE)] ([TT.x],[TT.y])"] = T
	var/obj/structure/divine/translocator/target_dest
	if(destinations.len == 1)
		target_dest = destinations[destinations[1]]
	else
		var/chosen = tgui_input_list(user, "Select destination for [target]:", "Translocator", sort_list(destinations))
		if(!chosen)
			return
		target_dest = destinations[chosen]
	if(!target_dest || QDELETED(target_dest))
		return
	user.visible_message(span_warning("[user] starts pushing [target] into the translocator..."), span_notice("You start pushing [target] into the translocator..."))
	to_chat(target, span_warning("[user] is trying to push you into the translocator!"))
	if(!do_after(user, 3 SECONDS, target))
		return
	entering_mobs += target
	var/job_name = target.mind?.assigned_role ? target.mind.assigned_role : "Unknown"
	to_chat(deity, span_boldnotice("[icon2html(src, deity)] [user] forces [target] ([job_name]) into the translocator to [get_area_name(target_dest, TRUE)]."))
	target.visible_message(span_notice("[target] is forced into the translocator!"), span_notice("Reality warps around you..."))
	playsound(src, 'sound/effects/phasein.ogg', 50, TRUE)
	traveling_mobs += target
	to_chat(deity, span_boldnotice("[icon2html(src, deity)] [target] ([job_name]) is in transit to [get_area_name(target_dest, TRUE)]. <a href='?src=[REF(deity)];eject_transit=[REF(target)]'>EJECT FROM TRANSIT</a>"))
	to_chat(target, span_notice("You feel yourself being pulled through the void..."))
	if(!do_after(target, 6 SECONDS, src))
		entering_mobs -= target
		traveling_mobs -= target
		to_chat(deity, span_warning("[target]'s transit was interrupted."))
		to_chat(target, span_warning("Your transit through the void was interrupted!"))
		return
	entering_mobs -= target
	if(!(target in traveling_mobs))
		return
	traveling_mobs -= target
	if(!target_dest || QDELETED(target_dest))
		to_chat(target, span_warning("The destination no longer exists!"))
		return
	target.visible_message(span_notice("[target] vanishes!"), span_notice("Reality warps around you..."))
	var/turf/dest = get_turf(target_dest)
	target.forceMove(dest)
	target.setDir(SOUTH)
	playsound(dest, 'sound/magic/blink.ogg', 50, TRUE)
	target.visible_message(span_notice("[target] materializes from thin air!"), span_notice("You arrive at your destination!"))
	to_chat(deity, span_notice("[target] successfully arrived at [get_area_name(target_dest, TRUE)]."))

GLOBAL_LIST_EMPTY(all_translocators)

/obj/structure/divine/translocator/assign_deity(mob/living/simple_animal/god/G)
	. = ..()
	GLOB.all_translocators += src

/obj/structure/divine/translocator/proc/god_link(mob/living/simple_animal/god/G)
	if(G.team_colour != deity?.team_colour)
		to_chat(G, span_warning("This translocator belongs to a different deity!"))
		return
	var/list/options = list()
	for(var/obj/structure/divine/translocator/T in G.structures)
		if(T == src)
			continue
		if(T in linked)
			continue
		var/turf/TT = get_turf(T)
		options["Translocator [get_area_name(T, TRUE)] ([TT.x],[TT.y])"] = T
	if(!length(options))
		to_chat(G, span_warning("You have no other translocators to link to!"))
		return
	var/action = tgui_alert(G, "Link or unlink?", "Translocator", list("Link", "Unlink"))
	if(!action)
		return
	if(action == "Link")
		var/chosen = tgui_input_list(G, "Link [src] to which translocator?", "Translocator Link", options)
		if(!chosen)
			return
		var/obj/structure/divine/translocator/target = options[chosen]
		linked += target
		target.linked += src
		update_icon()
		target.update_icon()
		to_chat(G, span_notice("You link [src] and [target] together."))
	else
		if(!length(linked))
			to_chat(G, span_warning("This translocator has no links to remove!"))
			return
		var/list/unlink_options = list()
		for(var/obj/structure/divine/translocator/T in linked)
			var/turf/TT = get_turf(T)
			unlink_options["Translocator [get_area_name(T, TRUE)] ([TT.x],[TT.y])"] = T
		var/chosen = tgui_input_list(G, "Unlink which translocator?", "Translocator Unlink", unlink_options)
		if(!chosen)
			return
		var/obj/structure/divine/translocator/target = unlink_options[chosen]
		linked -= target
		target.linked -= src
		update_icon()
		target.update_icon()
		to_chat(G, span_notice("You sever the link between [src] and [target]."))


// ============================================================
// FORGE
// ============================================================

/obj/structure/divine/forge
	name = "forge"
	desc = "Creates divine equipment for followers."
	icon_state = "forge"
	max_integrity = 300


// ============================================================
// CONVERSION ALTAR
// ============================================================

/obj/structure/divine/convertaltar
	name = "conversion altar"
	desc = "Used to convert crew members and rival cultists to your deity. Drag a target onto it to buckle them, then repeatedly use the altar to perform the ritual. Right-click to unbuckle."
	icon_state = "convert-altar"
	max_integrity = 250
	can_buckle = TRUE
	buckle_lying = 90
	dir = SOUTH
	var/converting = FALSE
	var/ritual_stage = 0
	var/max_stages = 3

/obj/structure/divine/convertaltar/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(dir_changed))

/obj/structure/divine/convertaltar/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/obj/structure/divine/convertaltar/proc/dir_changed(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	switch(new_dir)
		if(WEST, SOUTH)
			buckle_lying = 90
		if(EAST, NORTH)
			buckle_lying = 270

/obj/structure/divine/convertaltar/post_buckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_warning("[M] is bound to the conversion altar!"), span_userdanger("You are bound to the conversion altar!"))
	M.Paralyze(5 SECONDS)
	ritual_stage = 0

/obj/structure/divine/convertaltar/post_unbuckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_notice("[M] is released from the conversion altar."), span_notice("You are released from the conversion altar."))
	ritual_stage = 0

/obj/structure/divine/convertaltar/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(buckled_mob != user)
		buckled_mob.visible_message(
			span_danger("[user] tries to pull [buckled_mob] from the altar!"),
			span_danger("You attempt to release [buckled_mob] from the altar..."))
		if(!do_after(user, 8 SECONDS, buckled_mob))
			return FALSE
	return ..()

/obj/structure/divine/convertaltar/attackby(obj/item/I, mob/user, params)
	if(IS_HOG_CULTIST(user) && has_buckled_mobs())
		return perform_ritual(user, pick(buckled_mobs), I)
	return

/obj/structure/divine/convertaltar/attack_hand(mob/user)
	if(!ishuman(user))
		return ..()
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	if(!IS_HOG_CULTIST(user))
		to_chat(user, span_warning("You don't know how to use this!"))
		return
	if(converting)
		to_chat(user, span_warning("The altar is already in use!"))
		return
	if(!has_buckled_mobs())
		to_chat(user, span_warning("No one is bound to the altar! Drag a target onto it first."))
		return
	var/mob/living/carbon/human/target = locate() in buckled_mobs
	if(!target)
		to_chat(user, span_warning("No valid target on the altar!"))
		return
	perform_ritual(user, target)

/obj/structure/divine/convertaltar/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!has_buckled_mobs() || !isliving(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/mob/living/buckled_person = pick(buckled_mobs)
	if(buckled_person)
		if(IS_HOG_CULTIST(user) || IS_HOG_GOD(user))
			unbuckle_mob(buckled_person)
		else
			user_unbuckle_mob(buckled_person, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/divine/convertaltar/MouseDrop_T(atom/dropped, mob/user)
	if(!ishuman(dropped))
		return
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	var/mob/living/carbon/human/target = dropped
	if(target.buckled)
		to_chat(user, span_warning("[target] is already buckled to something!"))
		return
	if(has_buckled_mobs())
		to_chat(user, span_warning("Someone is already bound to the altar! Remove them first."))
		return
	if(user == target)
		user.visible_message(span_notice("[user] climbs onto the conversion altar..."), span_notice("You climb onto the conversion altar..."))
	else
		user.visible_message(span_warning("[user] starts dragging [target] onto the conversion altar..."), span_notice("You start binding [target] to the conversion altar..."))
	if(!do_after(user, 3 SECONDS, target))
		return
	target.forceMove(get_turf(src))
	if(!buckle_mob(target))
		to_chat(user, span_warning("Failed to bind [target] to the altar."))
		return
	to_chat(user, span_notice("[target] is now bound to the altar. Click the altar to perform the ritual."))

/obj/structure/divine/convertaltar/proc/perform_ritual(mob/living/user, mob/living/carbon/human/target, obj/item/held_item)
	if(!target || QDELETED(target))
		converting = FALSE
		return
	if(converting)
		return
	if(IS_HOG_PROPHET(target))
		to_chat(user, span_warning("A rival prophet's faith is too strong! They can only be sacrificed."))
		return
	if(IS_HOG_CULTIST(target))
		var/datum/antagonist/hog_cultist/C = target.mind.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour == deity.team_colour)
			to_chat(user, span_warning("[target] is already a follower of your deity!"))
			return
	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		to_chat(user, span_warning("[target] is protected by a mindshield!"))
		return
	if(target.stat == DEAD)
		to_chat(user, span_warning("[target] is dead and cannot be converted!"))
		return
	converting = TRUE
	var/brain_damage = target.getOrganLoss(ORGAN_SLOT_BRAIN)
	var/stage_time = 8 SECONDS
	if(brain_damage > 60)
		stage_time = 3 SECONDS
	else if(brain_damage > 30)
		stage_time = 5 SECONDS
	else if(brain_damage > 10)
		stage_time = 6 SECONDS
	var/list/stage_messages = list(
		"kneels beside [target] and begins to pray, voice low and steady...",
		"anoints [target]'s brow, the altar humming with quiet reverence...",
		"rests a hand upon [target]'s chest, eyes closed in solemn communion...",
	)
	var/ritual_message = stage_messages[min(ritual_stage + 1, length(stage_messages))]
	user.visible_message(
		span_notice("[user] [ritual_message]"),
		span_notice("You continue the conversion of [target]... (Stage [ritual_stage + 1]/[max_stages])"))
	to_chat(target, span_warning("A warm pressure settles over your thoughts. [user]'s voice is... soothing..."))
	playsound(src, 'sound/ambience/ambiholy.ogg', 30, TRUE)
	if(!do_after(user, stage_time, target))
		converting = FALSE
		to_chat(user, span_warning("The ritual was interrupted!"))
		return
	target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10 + (ritual_stage * 5))
	target.Paralyze(3 SECONDS)
	SEND_SIGNAL(target, COMSIG_ADD_MOOD_EVENT, "divine_conversion", /datum/mood_event/divine_conversion)
	if(brain_damage > 40)
		to_chat(target, span_warning("You feel so tired... the fight is draining out of you..."))
	else if(brain_damage > 20)
		to_chat(target, span_warning("The chanting echoes in your mind... it's getting harder to think."))
	ritual_stage++
	if(ritual_stage >= max_stages)
		complete_conversion(target, user)
	else
		to_chat(user, span_notice("Stage [ritual_stage]/[max_stages] complete. [target]'s will crumbles further."))
	converting = FALSE

/obj/structure/divine/convertaltar/proc/complete_conversion(mob/living/carbon/human/target, mob/living/user)
	if(!target || QDELETED(target))
		converting = FALSE
		return
	unbuckle_mob(target)
	if(IS_HOG_CULTIST(target))
		var/datum/antagonist/hog_cultist/C = target.mind.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour != deity.team_colour)
			target.mind.remove_antag_datum(/datum/antagonist/hog_cultist)
			target.visible_message(span_warning("[target] shudders, their former faith fading from their eyes..."), span_danger("Your old allegiances crumble to ash. You feel... empty."))
			sleep(2 SECONDS)
	target.mind.make_Handofgod_follower(deity.team_colour)
	target.visible_message(span_notice("[target]'s expression softens, a quiet peace settling over them."), span_danger("<B>A gentle warmth spreads through your chest. You understand now. The [deity.team_colour] light was always meant for you.</B>"))
	target.Paralyze(5 SECONDS)
	to_chat(user, span_notice("Conversion complete. [target] has found their way."))
	to_chat(deity, span_notice("[target] has been brought into your fold by [user]."))
	converting = FALSE


// ============================================================
// SACRIFICE ALTAR
// ============================================================

/obj/structure/divine/sacrificealtar
	name = "sacrifice altar"
	desc = "Used to sacrifice beings for gems or faith. Drag a target onto it to buckle them, then repeatedly use the altar to perform the ritual. Right-click to unbuckle."
	icon_state = "sacrifice-altar"
	max_integrity = 250
	can_buckle = TRUE
	buckle_lying = 90
	dir = SOUTH
	var/sacrificing = FALSE
	var/ritual_stage = 0
	var/max_stages = 3

/obj/structure/divine/sacrificealtar/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ATOM_DIR_CHANGE, PROC_REF(dir_changed))

/obj/structure/divine/sacrificealtar/Destroy()
	UnregisterSignal(src, COMSIG_ATOM_DIR_CHANGE)
	return ..()

/obj/structure/divine/sacrificealtar/proc/dir_changed(datum/source, old_dir, new_dir)
	SIGNAL_HANDLER
	switch(new_dir)
		if(WEST, SOUTH)
			buckle_lying = 90
		if(EAST, NORTH)
			buckle_lying = 270

/obj/structure/divine/sacrificealtar/post_buckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_warning("[M] is strapped to the sacrifice altar!"), span_userdanger("You are bound to the sacrifice altar!"))
	M.Paralyze(5 SECONDS)
	ritual_stage = 0

/obj/structure/divine/sacrificealtar/post_unbuckle_mob(mob/living/M)
	if(!M)
		return
	M.visible_message(span_notice("[M] is released from the sacrifice altar."), span_notice("You are released from the sacrifice altar."))
	ritual_stage = 0

/obj/structure/divine/sacrificealtar/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(buckled_mob != user)
		buckled_mob.visible_message(
			span_danger("[user] tries to pull [buckled_mob] from the altar!"),
			span_danger("You attempt to release [buckled_mob] from the altar..."))
		if(!do_after(user, 8 SECONDS, buckled_mob))
			return FALSE
	return ..()

/obj/structure/divine/sacrificealtar/attackby(obj/item/I, mob/user, params)
	if(IS_HOG_CULTIST(user) && has_buckled_mobs())
		return perform_ritual(user, pick(buckled_mobs), I)
	return

/obj/structure/divine/sacrificealtar/attack_hand(mob/user)
	if(!ishuman(user))
		return ..()
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	if(!IS_HOG_CULTIST(user))
		to_chat(user, span_warning("You don't know how to use this!"))
		return
	if(sacrificing)
		to_chat(user, span_warning("The altar is already in use!"))
		return
	if(!has_buckled_mobs())
		to_chat(user, span_warning("No one is bound to the altar! Drag a target onto it first."))
		return
	var/mob/living/carbon/human/target = locate() in buckled_mobs
	if(!target)
		to_chat(user, span_warning("No valid target on the altar!"))
		return
	perform_ritual(user, target)

/obj/structure/divine/sacrificealtar/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!has_buckled_mobs() || !isliving(user))
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	var/mob/living/buckled_person = pick(buckled_mobs)
	if(buckled_person)
		if(IS_HOG_CULTIST(user) || IS_HOG_GOD(user))
			unbuckle_mob(buckled_person)
		else
			user_unbuckle_mob(buckled_person, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/structure/divine/sacrificealtar/MouseDrop_T(atom/dropped, mob/user)
	if(!ishuman(dropped))
		return
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	var/mob/living/carbon/human/target = dropped
	if(target.buckled)
		to_chat(user, span_warning("[target] is already buckled to something!"))
		return
	if(has_buckled_mobs())
		to_chat(user, span_warning("Someone is already bound to the altar! Remove them first."))
		return
	if(user == target)
		user.visible_message(span_notice("[user] climbs onto the sacrifice altar..."), span_notice("You climb onto the sacrifice altar..."))
	else
		user.visible_message(span_warning("[user] starts dragging [target] onto the sacrifice altar..."), span_notice("You start binding [target] to the sacrifice altar..."))
	if(!do_after(user, 3 SECONDS, target))
		return
	target.forceMove(get_turf(src))
	if(!buckle_mob(target))
		to_chat(user, span_warning("Failed to bind [target] to the altar."))
		return
	to_chat(user, span_notice("[target] is now bound to the altar. Click the altar to perform the ritual."))

/obj/structure/divine/sacrificealtar/proc/perform_ritual(mob/living/user, mob/living/carbon/human/target, obj/item/held_item)
	if(!target || QDELETED(target) || target.stat == DEAD)
		complete_sacrifice(target, user)
		return
	if(sacrificing)
		return
	sacrificing = TRUE
	var/stage_time = 6 SECONDS
	var/item_bonus = 0
	if(held_item)
		stage_time -= held_item.force / 5
		item_bonus = held_item.sharpness ? 2 : 1
	stage_time = max(2 SECONDS, stage_time SECONDS)
	var/list/stage_messages = list(
		"utters dark prayers over [target]'s trembling form...",
		"carves ancient runes into [target]'s flesh...",
		"raises [user.p_their()] blade high as [target] screams in agony...",
	)
	var/message_index = min(ritual_stage + 1, length(stage_messages))
	var/ritual_message = stage_messages[message_index]
	user.visible_message(
		span_warning("[user] [ritual_message]"),
		span_danger("You perform the ritual on [target]... (Stage [ritual_stage + 1]/[max_stages])"))
	to_chat(target, span_userdanger("[user] performs a horrific ritual upon you!"))
	playsound(src, 'sound/magic/enter_blood.ogg', 40, TRUE)
	target.emote("scream")
	if(!do_after(user, stage_time, target))
		sacrificing = FALSE
		to_chat(user, span_warning("The ritual was interrupted!"))
		return
	var/brute_damage = 10 + (ritual_stage * 5) + item_bonus * 3
	var/burn_damage = 5 + (ritual_stage * 3) + item_bonus * 2
	target.apply_damage(brute_damage, BRUTE)
	target.apply_damage(burn_damage, BURN)
	target.adjustFireLoss(5)
	target.set_jitter_if_lower(10 SECONDS)
	ritual_stage++
	if(ritual_stage >= max_stages || target.stat == DEAD)
		complete_sacrifice(target, user)
	else
		to_chat(user, span_notice("Stage [ritual_stage]/[max_stages] complete. Click again to continue."))
	sacrificing = FALSE

/obj/structure/divine/sacrificealtar/proc/complete_sacrifice(mob/living/carbon/human/target, mob/living/user)
	if(!target || QDELETED(target))
		sacrificing = FALSE
		return
	unbuckle_mob(target)
	if(IS_HOG_PROPHET(target))
		new /obj/item/stack/sheet/greatergem(get_turf(src))
		target.visible_message(span_warning("[target] bursts into divine flames, collapsing into a husk!"), span_userdanger("Your body is consumed by divine fire!"))
		target.death()
		target.adjustFireLoss(200)
		target.update_body()
		to_chat(user, span_notice("A greater gem materializes from the rival prophet."))
		sacrificing = FALSE
		return
	if(IS_HOG_CULTIST(target))
		var/datum/antagonist/hog_cultist/C = target.mind.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour == deity.team_colour)
			target.visible_message(span_warning("[target]'s body ignites as they give themselves to their deity!"), span_userdanger("You give your life for your deity!"))
			target.death()
			target.adjustFireLoss(200)
			target.update_body()
			deity.add_faith(50)
			to_chat(user, span_notice("Sacrifice complete! Your deity gains 50 faith."))
			to_chat(deity, span_notice("[target] has been sacrificed in your name! You gain 50 faith."))
			sacrificing = FALSE
			return
		new /obj/item/stack/sheet/lessergem(get_turf(src))
		target.visible_message(span_warning("[target] bursts into flames on the altar!"), span_userdanger("You are consumed by divine fire!"))
		target.death()
		target.adjustFireLoss(200)
		target.update_body()
		to_chat(user, span_notice("A lesser gem materializes from the rival cultist."))
		sacrificing = FALSE
		return
	new /obj/item/stack/sheet/lessergem(get_turf(src))
	target.visible_message(span_warning("[target] bursts into flames on the altar!"), span_userdanger("You are sacrificed!"))
	target.death()
	target.adjustFireLoss(200)
	target.update_body()
	to_chat(user, span_notice("A lesser gem materializes."))
	sacrificing = FALSE


// ============================================================
// WARD
// ============================================================

/obj/structure/divine/ward
	name = "ward"
	desc = "A protective ward that damages non-believers nearby."
	icon_state = "ward"
	max_integrity = 100
	is_trap = TRUE


// ============================================================
// SHRINE (MOVE SPEED MODIFIERS + MOOD EVENTS)
// ============================================================

/datum/movespeed_modifier/shrine_buff
	multiplicative_slowdown = -0.5

/datum/movespeed_modifier/shrine_debuff
	multiplicative_slowdown = 0.5

/datum/mood_event/shrine_blessed
	description = "I feel the presence of my deity protecting me.\n"
	mood_change = 10
	timeout = 1 MINUTES

/datum/mood_event/shrine_dread
	description = "An oppressive divine presence weighs on my soul...\n"
	mood_change = -10
	timeout = 1 MINUTES

/datum/mood_event/divine_conversion
	description = "Someone is trying to tear apart my mind!\n"
	mood_change = -8
	timeout = 2 MINUTES


// ============================================================
// SHRINE
// ============================================================

/obj/structure/divine/shrine
	name = "shrine"
	desc = "A holy shrine that bolsters the faithful with divine protection and unnerves the wicked with oppressive dread."
	icon_state = "Shrine"
	max_integrity = 150
	var/aura_range = 5
	var/active_mode = "buff"
	var/mode_cooldown = 0
	var/mode_cooldown_time = 30 SECONDS
	var/prayer_cooldown = 0
	var/prayer_cooldown_time = 10 MINUTES

/obj/structure/divine/shrine/assign_deity(mob/living/simple_animal/god/G)
	. = ..()
	if(G)
		name = "Shrine of [G.name]"

/obj/structure/divine/shrine/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/divine/shrine/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/divine/shrine/process(delta_time)
	if(!deity)
		return
	for(var/mob/living/carbon/human/H in range(aura_range, src))
		if(H.stat == DEAD)
			continue
		if(active_mode == "buff" && IS_HOG_CULTIST(H))
			var/datum/antagonist/hog_cultist/C = H.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
			if(C?.cult_team?.team_colour == deity.team_colour)
				H.add_movespeed_modifier(/datum/movespeed_modifier/shrine_buff)
				H.physiology?.damage_resistance = max(H.physiology.damage_resistance, 10)
				H.physiology?.stamina_mod = max(H.physiology.stamina_mod, 0.8)
				H.physiology?.burn_mod = max(H.physiology.burn_mod, 0.8)
				SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "shrine_blessing", /datum/mood_event/shrine_blessed)
		else if(active_mode == "debuff" && !IS_HOG_CULTIST(H) && !IS_HOG_GOD(H))
			H.add_movespeed_modifier(/datum/movespeed_modifier/shrine_debuff)
			H.physiology?.damage_resistance = min(H.physiology.damage_resistance, -10)
			H.physiology?.stamina_mod = min(H.physiology.stamina_mod, 1.2)
			SEND_SIGNAL(H, COMSIG_ADD_MOOD_EVENT, "shrine_dread", /datum/mood_event/shrine_dread)

/obj/structure/divine/shrine/attack_hand(mob/user)
	if(ishuman(user) && IS_HOG_CULTIST(user))
		var/datum/antagonist/hog_cultist/C = user.mind?.has_antag_datum(/datum/antagonist/hog_cultist)
		if(!C || C?.cult_team?.team_colour != deity?.team_colour)
			to_chat(user, span_warning("This shrine belongs to a different deity!"))
			return
		if(prayer_cooldown > world.time)
			to_chat(user, span_warning("The shrine has already received prayers recently. Wait [round((prayer_cooldown - world.time)/10)] seconds."))
			return
		user.visible_message(span_notice("[user] kneels before the shrine and begins to pray..."), span_notice("You kneel before the shrine and begin to pray..."))
		if(!do_after(user, 30 SECONDS, src))
			return
		if(!deity)
			return
		deity.add_faith(5)
		prayer_cooldown = world.time + prayer_cooldown_time
		to_chat(user, span_notice("Your prayers have been heard! Your deity gains faith."))
		to_chat(deity, span_notice("[user]'s prayers at a shrine grant you 5 faith."))
		return
	to_chat(user, span_warning("You don't know how to use this!"))


// ============================================================
// FOUNTAIN
// ============================================================

/obj/structure/divine/fountain
	name = "fountain"
	desc = "A blessed fountain that can dispense the waters of life or death."
	icon_state = "fountain"
	max_integrity = 200
	var/active_mode = "life"
	var/mode_cooldown = 0
	var/mode_cooldown_time = 30 SECONDS
	var/recharging = FALSE
	var/recharge_time = 10 MINUTES
	var/uses_remaining = 1

/obj/structure/divine/fountain/Initialize(mapload)
	. = ..()
	create_reagents(1000, TRANSPARENT)
	refill_reagents()

/obj/structure/divine/fountain/update_icon()
	if(!deity)
		icon_state = "fountain"
		return
	if(recharging)
		icon_state = "fountain-empty-water"
		return
	if(active_mode == "death")
		icon_state = "fountain-red-water"
		light_color = LIGHT_COLOR_RED
	else
		icon_state = "fountain-blue-water"
		light_color = LIGHT_COLOR_BLUE
	set_light(2)

/obj/structure/divine/fountain/proc/refill_reagents()
	if(!reagents)
		return
	reagents.clear_reagents()
	if(active_mode == "life")
		reagents.add_reagent(/datum/reagent/water_of_life, 1000)
	else
		reagents.add_reagent(/datum/reagent/water_of_death, 1000)
	uses_remaining = 1

/obj/structure/divine/fountain/proc/use_fountain()
	if(recharging || uses_remaining <= 0)
		return FALSE
	uses_remaining--
	if(uses_remaining <= 0)
		recharging = TRUE
		update_icon()
		addtimer(CALLBACK(src, PROC_REF(end_recharge)), recharge_time)
	return TRUE

/obj/structure/divine/fountain/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers))
		if(recharging || uses_remaining <= 0)
			to_chat(user, span_warning("The fountain's waters have been depleted."))
			return
		var/obj/item/reagent_containers/container = I
		if(!container.reagents || container.reagents.total_volume >= container.volume)
			to_chat(user, span_warning("[container] is full!"))
			return
		if(!reagents || !reagents.total_volume)
			to_chat(user, span_warning("The fountain is empty!"))
			return
		var/amount = min(10, container.volume - container.reagents.total_volume, reagents.total_volume)
		reagents.trans_to(container, amount)
		to_chat(user, span_notice("You fill [container] with [amount] units from the fountain."))
		use_fountain()
		return
	return ..()

/obj/structure/divine/fountain/attack_hand(mob/user)
	if(recharging || uses_remaining <= 0)
		to_chat(user, span_warning("The fountain's waters have been depleted."))
		return
	if(active_mode == "life")
		if(!isliving(user) || user.stat == DEAD)
			to_chat(user, span_warning("The waters of life cannot help the dead."))
			return
		if(!use_fountain())
			return
		var/mob/living/L = user
		user.visible_message(span_notice("[user] drinks from the fountain and is bathed in a brilliant light!"), span_notice("You drink the waters of life! You feel invigorated and protected from death!"))
		L.revive(full_heal = FALSE)
		L.adjustBruteLoss(-50)
		L.adjustFireLoss(-50)
		L.adjustStaminaLoss(-100)
		L.SetUnconscious(0)
		L.SetParalyzed(0)
		L.SetKnockdown(0)
		L.setStaminaLoss(0)
		L.reagents?.add_reagent(/datum/reagent/water_of_life, 10)
	else
		if(isliving(user))
			var/mob/living/L = user
			if(L.stat == DEAD)
				if(!use_fountain())
					return
				user.visible_message(span_warning("[user] is touched by the dark waters..."), span_userdanger("The waters of death pull you back from the void!"))
				L.notify_ghost_cloning(source = src)
				L.do_jitter_animation(10)
				addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, revive), ADMIN_HEAL_ALL), 4 SECONDS)
				L.reagents?.add_reagent(/datum/reagent/water_of_death, 10)
				ADD_TRAIT(L, TRAIT_NODEATH, REF(src))
				addtimer(CALLBACK(src, PROC_REF(remove_revive_protection), L), 30 SECONDS)
			else
				if(!use_fountain())
					return
				user.visible_message(span_danger("[user] touches the dark waters and clutches their chest in agony!"), span_userdanger("The waters of death ravage your body and stop your heart!"))
				L.adjustBruteLoss(10)
				L.adjustFireLoss(10)
				L.adjustToxLoss(10)
				L.adjustOxyLoss(10)
				L.reagents?.add_reagent(/datum/reagent/water_of_death, 10)

/obj/structure/divine/fountain/MouseDrop_T(atom/movable/dropped, mob/user)
	if(!ishuman(dropped) || !ishuman(user))
		return
	if(user == dropped)
		return
	if(recharging || uses_remaining <= 0)
		to_chat(user, span_warning("The fountain's waters have been depleted."))
		return
	var/mob/living/carbon/human/target = dropped
	if(active_mode == "death")
		user.visible_message(span_notice("[user] drags [target] to the dark waters..."), span_notice("You bring [target] to the dark waters..."))
		if(!do_after(user, 5 SECONDS, target))
			return
		if(recharging || uses_remaining <= 0 || active_mode != "death")
			return
		if(!use_fountain())
			return
		if(target.stat == DEAD)
			target.visible_message(span_notice("[target] is touched by the dark waters and gasps back to life!"), span_userdanger("The waters of death pull you back from the void!"))
			target.notify_ghost_cloning(source = src)
			target.do_jitter_animation(10)
			addtimer(CALLBACK(target, TYPE_PROC_REF(/mob/living, revive), ADMIN_HEAL_ALL), 4 SECONDS)
			target.reagents?.add_reagent(/datum/reagent/water_of_death, 10)
			ADD_TRAIT(target, TRAIT_NODEATH, REF(src))
			addtimer(CALLBACK(src, PROC_REF(remove_revive_protection), target), 30 SECONDS)
		else
			target.visible_message(span_danger("[user] forces [target] to touch the dark waters!"), span_userdanger("[user] forces you to touch the dark waters! Your heart seizes!"))
			target.adjustBruteLoss(10)
			target.adjustFireLoss(10)
			target.adjustToxLoss(10)
			target.adjustOxyLoss(10)
			target.reagents?.add_reagent(/datum/reagent/water_of_death, 10)
		return
	if(active_mode == "life")
		user.visible_message(span_notice("[user] helps [target] drink from the fountain..."), span_notice("You help [target] drink the waters of life."))
		if(!do_after(user, 3 SECONDS, target))
			return
		if(recharging || uses_remaining <= 0 || active_mode != "life")
			return
		if(!use_fountain())
			return
		if(target.stat == DEAD)
			to_chat(user, span_warning("The waters of life cannot help the dead."))
			return
		target.revive(full_heal = FALSE)
		target.adjustBruteLoss(-50)
		target.adjustFireLoss(-50)
		target.adjustStaminaLoss(-100)
		target.SetUnconscious(0)
		target.SetParalyzed(0)
		target.SetKnockdown(0)
		target.setStaminaLoss(0)
		target.reagents?.add_reagent(/datum/reagent/water_of_life, 10)
		to_chat(target, span_notice("You feel the waters of life flow through you! You feel invincible..."))
		return

/obj/structure/divine/fountain/proc/remove_revive_protection(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_NODEATH, REF(src))

/obj/structure/divine/fountain/proc/end_recharge()
	recharging = FALSE
	uses_remaining = 1
	refill_reagents()
	update_icon()
	if(deity)
		to_chat(deity, span_notice("Your fountain's waters have replenished."))


// ============================================================
// CONDUIT
// ============================================================

/obj/structure/divine/conduit
	name = "conduit"
	desc = "Channels divine energy, increasing faith generation and expanding the god's domain."
	icon_state = "conduit"
	max_integrity = 150


// ============================================================
// MAGIC MIRROR (MIRROR ACTIONS)
// ============================================================

/datum/action/mirror_cancel
	name = "Stop Scrying"
	desc = "Return your vision to your body."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "God-Speak"
	background_icon_state = "God-Speak"
	var/obj/structure/divine/magic_mirror/mirror

/datum/action/mirror_cancel/New(obj/structure/divine/magic_mirror/M)
	. = ..()
	mirror = M

/datum/action/mirror_cancel/on_activate(trigger_flags)
	if(!mirror)
		return
	mirror.stop_scrying()
	to_chat(owner, span_notice("You stop scrying."))

/datum/action/mirror_trap_soul
	name = "Trap Soul"
	desc = "Attempt to trap the scryed target's soul in the mirror. 20 second chant."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "soul_trap"
	background_icon_state = "soul_trap"
	var/obj/structure/divine/magic_mirror/mirror

/datum/action/mirror_trap_soul/New(obj/structure/divine/magic_mirror/M)
	. = ..()
	mirror = M

/datum/action/mirror_trap_soul/on_activate(trigger_flags)
	if(!mirror)
		return
	if(!mirror.scry_target || mirror.scry_target.stat == DEAD)
		to_chat(owner, span_warning("Your target is no longer valid!"))
		return
	if(mirror.trap_cooldown > world.time)
		to_chat(owner, span_warning("The mirror's trapping power hasn't recharged yet."))
		return
	mirror.attempt_soul_trap(owner)


// ============================================================
// MAGIC MIRROR
// ============================================================

/obj/structure/divine/magic_mirror
	name = "magic mirror"
	desc = "A divine mirror that allows users to scry on enemies and trap souls within. A deity can use it to select their purest Vessel — a permanent, irreversible choice."
	icon = 'icons/obj/hand_of_god_secondary.dmi'
	icon_state = "mirror_mirror"
	max_integrity = 200
	var/mob/living/carbon/human/scry_target = null
	var/mob/living/scrying_user = null
	var/cooldown = 0
	var/cooldown_time = 5 SECONDS
	var/trap_cooldown = 0
	var/trap_cooldown_time = 15 MINUTES
	var/scrying = FALSE
	var/list/trapped_souls = list()

/obj/structure/divine/magic_mirror/update_icon()
	return

/obj/structure/divine/magic_mirror/Destroy()
	release_all_souls()
	if(scrying)
		stop_scrying()
	scrying_user = null
	return ..()

/obj/structure/divine/magic_mirror/attack_hand(mob/user)
	if(!ishuman(user) && !IS_HOG_GOD(user))
		to_chat(user, span_warning("You don't know how to use this!"))
		return
	if(IS_HOG_GOD(user))
		var/mob/living/simple_animal/god/G = user
		if(G.team_colour != deity?.team_colour)
			to_chat(user, span_warning("The rival deity's mirror rejects you!"))
			return
		god_interact(G)
		return
	if(scrying)
		return
	var/list/possible = list()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H == user)
			continue
		if(IS_HOG_GOD(H))
			continue
		if(H.mind in trapped_souls)
			continue
		possible |= H
	if(!length(possible))
		to_chat(user, span_warning("No valid targets found!"))
		return
	scry_target = tgui_input_list(user, "Select a target to scry upon:", "Magic Mirror", sort_names(possible))
	if(!scry_target)
		return
	start_scrying(user)

/obj/structure/divine/magic_mirror/proc/god_interact(mob/living/simple_animal/god/G)
	var/datum/mind/vessel_mind = G.mind?.purest_vessel
	if(vessel_mind)
		if(!vessel_mind.current || vessel_mind.current.stat == DEAD)
			to_chat(G, span_warning("The mirror reflects the lifeless image of [vessel_mind.name] — your purest Vessel. Their body is dead but still bound to you. No new Vessel can ever be chosen."))
			return
		if(vessel_mind.current.is_soul_trapped())
			to_chat(G, span_warning("The mirror shows [vessel_mind.name] — your Vessel's soul is trapped within a mirror. They cannot be possessed until the mirror holding their soul is destroyed. No new Vessel can ever be chosen."))
			return
		to_chat(G, span_notice("The mirror reflects an image of [vessel_mind.name] — the purest Vessel. They are already yours. This choice is PERMANENT and can never be undone or changed."))
		return
	var/list/possible = list()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(IS_HOG_CULTIST(H))
			continue
		if(IS_HOG_GOD(H))
			continue
		if(!H.mind)
			continue
		if(H.mind in trapped_souls)
			continue
		possible |= H
	if(!length(possible))
		to_chat(G, span_warning("The mirror's surface swirls, searching the mortal realm for the purest Vessel... but none are found."))
		return
	to_chat(G, span_notice("The mirror scans the mortal realm, searching for the purest Vessel..."))
	var/mob/living/carbon/human/vessel = pick(possible)
	G.mind.purest_vessel = vessel.mind
	if(!G.mind.purest_vessel)
		stack_trace("Selected vessel [vessel] has no mind despite mind check!")
		return
	to_chat(G, span_notice("The mirror focuses on [vessel], branding [vessel.p_them()] as the purest Vessel. They are now yours to possess when the time comes."))
	to_chat(G, span_userdanger("THIS CHOICE IS PERMANENT. No other Vessel can ever be chosen. Protect them well."))
	to_chat(vessel, span_userdanger("You feel an overwhelming divine presence crash down upon you! The mirror has marked you as the purest Vessel. Something ancient has claimed your body."))
	log_game("[key_name(G)] has permanently selected [key_name(vessel)] as their purest Vessel via magic mirror.")

/obj/structure/divine/magic_mirror/proc/start_scrying(mob/user)
	if(!scry_target)
		return
	scrying = TRUE
	scrying_user = user
	user.visible_message(span_notice("[user] stares into the mirror, their eyes glazing over..."), span_notice("You gaze into the mirror and see through [scry_target]'s eyes..."))
	user.set_machine(src)
	user.reset_perspective(scry_target)
	to_chat(scry_target, span_warning("You feel an unsettling presence watching you from somewhere..."))
	GiveMirrorHint(scry_target, user)
	var/datum/action/mirror_cancel/cancel_action = new(src)
	cancel_action.Grant(user)
	var/datum/action/mirror_trap_soul/trap_action = new(src)
	trap_action.Grant(user)
	addtimer(CALLBACK(src, PROC_REF(auto_stop_scrying), user), 30 SECONDS)

/obj/structure/divine/magic_mirror/proc/stop_scrying()
	scrying = FALSE
	scry_target = null
	if(scrying_user)
		var/datum/action/mirror_cancel/cancel_action = locate() in scrying_user.actions
		if(cancel_action)
			cancel_action.Remove(scrying_user)
		var/datum/action/mirror_trap_soul/trap_action = locate() in scrying_user.actions
		if(trap_action)
			trap_action.Remove(scrying_user)
		if(scrying_user.machine == src)
			scrying_user.reset_perspective(null)
			scrying_user.unset_machine()
		scrying_user = null

/obj/structure/divine/magic_mirror/proc/auto_stop_scrying(mob/user)
	if(scrying && scrying_user == user)
		stop_scrying()
		to_chat(user, span_notice("The mirror's vision fades..."))

/obj/structure/divine/magic_mirror/proc/attempt_soul_trap(mob/user)
	if(!scry_target || scry_target.stat == DEAD)
		return
	user.visible_message(span_warning("[user] begins chanting as the mirror's surface swirls violently!"), span_danger("You begin trapping [scry_target]'s soul in the mirror..."))
	to_chat(scry_target, span_userdanger("You feel an overwhelming force trying to claim your soul!"))
	GiveMirrorHint(scry_target, user, force=TRUE)
	if(!do_after(user, 20 SECONDS, src))
		to_chat(user, span_warning("The soul trap was interrupted!"))
		return
	if(!scry_target || scry_target.stat == DEAD)
		to_chat(user, span_warning("The target is no longer valid!"))
		return
	var/mob/living/carbon/human/victim = scry_target
	scry_target = null
	stop_scrying()
	trapped_souls += victim.mind
	victim.set_soul_trapped()
	var/mob/living/simple_animal/god/G = deity
	if(G?.mind?.purest_vessel == victim.mind)
		to_chat(G, span_userdanger("[victim] was your purest Vessel — their soul is now trapped within the mirror! You can never choose another. Destroy the mirror to free them, or find another way..."))
	victim.visible_message(span_danger("[victim] shudders as an eerie light leaves their body and flies into the mirror!"), span_userdanger("You feel a piece of yourself being torn away and trapped within a mirror! If you die... you may not return."))
	trap_cooldown = world.time + trap_cooldown_time
	to_chat(user, span_notice("[victim]'s soul is now bound to the mirror! If they die, they cannot be revived until the mirror is destroyed."))
	to_chat(deity, span_notice("[victim]'s soul has been trapped in a magic mirror by [user]."))

/obj/structure/divine/magic_mirror/proc/release_all_souls()
	for(var/datum/mind/M in trapped_souls)
		if(M.current)
			var/mob/living/L = M.current
			L.clear_soul_trapped()
			to_chat(L, span_userdanger("You feel your soul return to you as the mirror shatters! You can be revived again."))
		var/mob/living/simple_animal/god/G = deity
		if(G?.mind?.purest_vessel == M)
			to_chat(G, span_userdanger("The mirror holding your Vessel's soul has been destroyed! [M.name]'s soul is free once more."))
	trapped_souls = list()

/obj/structure/divine/magic_mirror/proc/GiveMirrorHint(mob/victim, mob/user, force=FALSE)
	if(prob(60) || force)
		var/way = dir2text(get_dir(victim, get_turf(src)))
		to_chat(victim, span_warning("You feel a dark presence watching you from the [way]..."))
	if(prob(30) || force)
		var/area/A = get_area(src)
		to_chat(victim, span_warning("The presence feels like it's coming from [A.name]..."))


// ============================================================
// SCRIBING TABLE
// ============================================================

/obj/structure/divine/scribing_table
	name = "scribing table"
	desc = "A divine workstation for crafting relics and imbuing items with holy power."
	icon_state = "scribing-table"
	max_integrity = 200

/obj/structure/divine/scribing_table/update_icon()
	if(!deity)
		icon_state = "scribing-table"
		return
	icon_state = "scribing-table-[deity.team_colour]"


// ============================================================
// CONSTRUCTION HOLDER
// ============================================================

/obj/structure/divine/construction_holder
	name = "unfinished structure"
	desc = "An unfinished divine structure. Requires materials to complete."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "construction"
	density = FALSE
	max_integrity = 100
	is_construction_holder = TRUE
	var/obj/structure/divine/build_type = null
	var/iron_required = 0
	var/glass_required = 0
	var/rods_required = 0
	var/gem_required = 0
	var/iron_inserted = 0
	var/glass_inserted = 0
	var/rods_inserted = 0
	var/gem_inserted = 0

/obj/structure/divine/construction_holder/proc/setup_construction(obj/structure/divine/build_path)
	build_type = build_path
	name = "unfinished [initial(build_path.name)]"
	switch(build_path)
		if(/obj/structure/divine/convertaltar)
			rods_required = 25
			glass_required = 10
		if(/obj/structure/divine/sacrificealtar)
			iron_required = 25
			glass_required = 10
		if(/obj/structure/divine/defensepylon)
			iron_required = 25
			glass_required = 5
		if(/obj/structure/divine/magic_mirror)
			iron_required = 5
			glass_required = 30
			gem_required = 1
		if(/obj/structure/divine/conduit)
			iron_required = 10
			rods_required = 15
		if(/obj/structure/divine/shrine)
			iron_required = 25
		else
			iron_required = 10

/obj/structure/divine/construction_holder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/iron))
		var/obj/item/stack/sheet/iron/S = I
		var/needed = iron_required - iron_inserted
		if(needed <= 0)
			to_chat(user, span_warning("It doesn't need more iron!"))
			return
		var/to_use = min(S.amount, needed)
		S.use(to_use)
		iron_inserted += to_use
		to_chat(user, span_notice("You add [to_use] iron. ([iron_inserted]/[iron_required])"))
		check_completion()
		return
	if(istype(I, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/G = I
		var/needed = glass_required - glass_inserted
		if(needed <= 0)
			to_chat(user, span_warning("It doesn't need more glass!"))
			return
		var/to_use = min(G.amount, needed)
		G.use(to_use)
		glass_inserted += to_use
		to_chat(user, span_notice("You add [to_use] glass. ([glass_inserted]/[glass_required])"))
		check_completion()
		return
	if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = I
		var/needed = rods_required - rods_inserted
		if(needed <= 0)
			to_chat(user, span_warning("It doesn't need more rods!"))
			return
		var/to_use = min(R.amount, needed)
		R.use(to_use)
		rods_inserted += to_use
		to_chat(user, span_notice("You add [to_use] rods. ([rods_inserted]/[rods_required])"))
		check_completion()
		return
	if(istype(I, /obj/item/stack/sheet/lessergem))
		var/obj/item/stack/sheet/lessergem/G = I
		var/needed = gem_required - gem_inserted
		if(needed <= 0)
			to_chat(user, span_warning("It doesn't need more gems!"))
			return
		var/to_use = min(G.amount, needed)
		G.use(to_use)
		gem_inserted += to_use
		to_chat(user, span_notice("You add [to_use] lesser gem. ([gem_inserted]/[gem_required])"))
		check_completion()
		return
	return ..()

/obj/structure/divine/construction_holder/proc/check_completion()
	if(iron_inserted >= iron_required && glass_inserted >= glass_required && rods_inserted >= rods_required && gem_inserted >= gem_required)
		finish_construction()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	visible_message(span_notice("[src] transforms into \a [initial(build_type.name)]!"))
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
