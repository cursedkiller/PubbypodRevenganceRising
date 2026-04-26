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


//NEXUS rah!!!//

/obj/structure/divine/nexus
	name = "nexus"
	desc = "The anchor of a deity in this realm."
	icon_state = "nexus"
	max_integrity = HOG_NEXUS_MAX_INTEGRITY
	light_range = 4

/obj/structure/divine/nexus/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/divine/nexus/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(deity)
		deity.god_nexus = null
		to_chat(deity, span_userdanger("Your nexus has been destroyed!"))
		SEND_SIGNAL(src, COMSIG_HOG_NEXUS_DESTROYED, deity)
		deity.refresh_followers()
		deity.check_death()
	return ..()

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


//Defense Pylon rah!!!//


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

/obj/structure/divine/defensepylon/attack_hand(mob/user)
	if(!IS_HOG_GOD(user))
		to_chat(user, span_warning("Only your deity can control this!"))
		return
	var/mob/living/simple_animal/god/G = user
	if(G.team_colour != deity?.team_colour)
		to_chat(user, span_warning("This pylon belongs to a different deity!"))
		return
	active = !active
	attacking = FALSE
	if(active)
		visible_message(span_notice("[src] hums to life."))
	else
		visible_message(span_notice("[src] powers down."))
	update_icon()

/obj/structure/divine/defensepylon/attack_ghost(mob/user)
	if(!IS_HOG_GOD(user))
		return
	attack_hand(user)

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
	var/obj/projectile/beam/pylon/bolt = new /obj/projectile/beam/pylon(get_turf(src))
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

/obj/projectile/beam/pylon
	name = "divine blast"
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "divine_blast"
	damage = 17
	damage_type = BURN
	light_color = LIGHT_COLOR_RED
	impact_effect_type = /obj/effect/temp_visual/impact_effect/red_laser

/obj/projectile/beam/pylon/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.adjustFireLoss(5)

//Power Pylon rah!!!//

/obj/structure/divine/powerpylon
	name = "power pylon"
	desc = "Generates faith for your deity."
	icon_state = "powerpylon"
	max_integrity = 150

/obj/structure/divine/translocator
	name = "translocator"
	desc = "Allows followers to teleport between translocators."
	icon_state = "translocator"
	max_integrity = 200

/obj/structure/divine/forge
	name = "forge"
	desc = "Creates divine equipment for followers."
	icon_state = "forge"
	max_integrity = 300

/obj/structure/divine/convertaltar
	name = "conversion altar"
	desc = "Used to convert crew members and rival cultists to your deity. Drag a target onto it to begin."
	icon_state = "convertaltar"
	max_integrity = 250
	var/converting = FALSE

/obj/structure/divine/convertaltar/attackby(obj/item/I, mob/user, params)
	return

/obj/structure/divine/convertaltar/MouseDrop_T(atom/dropped, mob/user)
	if(!ishuman(dropped) || !ishuman(user))
		return
	if(user == dropped)
		return
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	if(!IS_HOG_CULTIST(user))
		to_chat(user, span_warning("You don't know how to use this!"))
		return
	if(converting)
		to_chat(user, span_warning("The altar is already in use!"))
		return

	var/mob/living/carbon/human/target = dropped
	INVOKE_ASYNC(src, PROC_REF(convert_target), target, user)

/obj/structure/divine/convertaltar/proc/convert_target(mob/living/carbon/human/target, mob/living/carbon/human/user)
	converting = TRUE

	if(IS_HOG_PROPHET(target))
		to_chat(user, span_warning("A rival prophet's faith is too strong! They can only be sacrificed."))
		converting = FALSE
		return

	if(IS_HOG_CULTIST(target))
		var/datum/antagonist/hog_cultist/C = target.mind.has_antag_datum(/datum/antagonist/hog_cultist)
		if(C?.cult_team?.team_colour == deity.team_colour)
			to_chat(user, span_warning("[target] is already a follower of your deity!"))
			converting = FALSE
			return

		user.visible_message(span_warning("[user] begins purging [target]'s faith at the altar..."), span_notice("You begin purging [target]'s faith..."))
		if(!do_after(user, 15 SECONDS, target))
			converting = FALSE
			return
		target.mind.remove_antag_datum(/datum/antagonist/hog_cultist)
		target.visible_message(span_warning("[target]'s faith has been stripped away!"), span_userdanger("Your faith has been purged!"))

		user.visible_message(span_warning("[user] begins converting [target] to a new faith..."), span_notice("You begin converting [target] to your deity..."))
		if(!do_after(user, 10 SECONDS, target))
			converting = FALSE
			return
		target.mind.make_Handofgod_follower(deity.team_colour)
		target.visible_message(span_warning("[target]'s eyes glow as they embrace a new faith!"), span_danger("<B>You have been converted to the [deity.team_colour] deity!</B>"))
		to_chat(user, span_notice("Conversion complete!"))
		converting = FALSE
		return

	if(HAS_TRAIT(target, TRAIT_MINDSHIELD))
		to_chat(user, span_warning("[target] is protected by a mindshield!"))
		converting = FALSE
		return

	if(target.stat == DEAD)
		to_chat(user, span_warning("[target] is dead and cannot be converted!"))
		converting = FALSE
		return

	user.visible_message(span_warning("[user] begins converting [target] at the altar..."), span_notice("You begin converting [target] to your deity..."))
	if(!do_after(user, 10 SECONDS, target))
		converting = FALSE
		return

	target.mind.make_Handofgod_follower(deity.team_colour)
	target.visible_message(span_warning("[target]'s eyes glow as they are converted!"), span_danger("<B>You have been converted to the [deity.team_colour] deity!</B>"))
	to_chat(user, span_notice("Conversion complete!"))
	converting = FALSE

/obj/structure/divine/sacrificealtar
	name = "sacrifice altar"
	desc = "Used to sacrifice beings for gems or faith. Drag a target onto it to begin."
	icon_state = "sacrificealtar"
	max_integrity = 250
	var/sacrificing = FALSE

/obj/structure/divine/sacrificealtar/attackby(obj/item/I, mob/user, params)
	return

/obj/structure/divine/sacrificealtar/MouseDrop_T(atom/dropped, mob/user)
	if(!ishuman(dropped) || !ishuman(user))
		return
	if(user == dropped)
		return
	if(!deity)
		to_chat(user, span_warning("This altar is not connected to a deity!"))
		return
	if(!IS_HOG_CULTIST(user))
		to_chat(user, span_warning("You don't know how to use this!"))
		return
	if(sacrificing)
		to_chat(user, span_warning("The altar is already in use!"))
		return

	var/mob/living/carbon/human/target = dropped
	INVOKE_ASYNC(src, PROC_REF(sacrifice_target), target, user)

/obj/structure/divine/sacrificealtar/proc/sacrifice_target(mob/living/carbon/human/target, mob/living/carbon/human/user)
	sacrificing = TRUE

	user.visible_message(span_warning("[user] drags [target] onto the sacrifice altar!"), span_danger("You begin sacrificing [target]..."))
	if(!do_after(user, 8 SECONDS, target))
		sacrificing = FALSE
		return

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

/obj/structure/divine/shrine
	name = "shrine"
	desc = "A holy shrine that boosts nearby followers."
	icon_state = "Shrine"
	max_integrity = 150

/obj/structure/divine/ward
	name = "ward"
	desc = "A protective ward that damages non-believers nearby."
	icon_state = "ward"
	max_integrity = 100
	is_trap = TRUE

/obj/structure/divine/fountain
	name = "fountain"
	desc = "A blessed fountain that heals nearby followers."
	icon_state = "fountain"
	max_integrity = 200

/obj/structure/divine/conduit
	name = "conduit"
	desc = "Channels divine energy, increasing faith generation."
	icon_state = "conduit"
	max_integrity = 150

/obj/structure/divine/lazarus
	name = "lazarus"
	desc = "Can revive a fallen follower once."
	icon_state = "lazarus"
	max_integrity = 100

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
	var/iron_inserted = 0
	var/glass_inserted = 0
	var/rods_inserted = 0

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
	return ..()

/obj/structure/divine/construction_holder/proc/check_completion()
	if(iron_inserted >= iron_required && glass_inserted >= glass_required && rods_inserted >= rods_required)
		finish_construction()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	visible_message(span_notice("[src] transforms into \a [initial(build_type.name)]!"))
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
