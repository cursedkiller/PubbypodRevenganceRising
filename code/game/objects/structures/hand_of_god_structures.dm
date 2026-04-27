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
	desc = "Generates faith for your deity."
	icon_state = "powerpylon"
	max_integrity = 150


// ============================================================
// TRANSLOCATOR
// ============================================================

/obj/structure/divine/translocator
	name = "translocator"
	desc = "Allows followers to teleport between translocators."
	icon_state = "translocator"
	max_integrity = 200


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
	desc = "Used to convert crew members and rival cultists to your deity. Drag a target onto it to begin."
	icon_state = "convert-altar"
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


// ============================================================
// SACRIFICE ALTAR
// ============================================================

/obj/structure/divine/sacrificealtar
	name = "sacrifice altar"
	desc = "Used to sacrifice beings for gems or faith. Drag a target onto it to begin."
	icon_state = "sacrifice-altar"
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


// ============================================================
// WARD
// ============================================================

/obj/structure/divine/ward
	name = "ward"
	desc = "A protective ward that damages non-believers nearby."
	icon_state = "ward"
	max_integrity = 100
	density = TRUE
	anchored = TRUE
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
	if(istype(user, /mob/living/simple_animal/god))
		var/mob/living/simple_animal/god/G = user
		if(G.team_colour != deity?.team_colour)
			to_chat(user, span_warning("This shrine belongs to a different deity!"))
			return
		if(mode_cooldown > world.time)
			to_chat(G, span_warning("The shrine's power is still settling. Wait [round((mode_cooldown - world.time)/10)] seconds."))
			return
		if(active_mode == "buff")
			active_mode = "debuff"
			visible_message(span_warning("[src]'s eyes darken as an oppressive aura emanates from it, weighing down the souls of the wicked."))
		else
			active_mode = "buff"
			visible_message(span_notice("[src]'s eyes glow warmly as a protective divine light radiates outward."))
		mode_cooldown = world.time + mode_cooldown_time
		return

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
	desc = "A blessed fountain that heals nearby followers."
	icon_state = "fountain"
	max_integrity = 200


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
	desc = "A divine mirror that allows users to scry on enemies and trap souls within. It seems to hold a deeper purpose..."
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
	var/datum/mind/selected_vessel = null

/obj/structure/divine/magic_mirror/update_icon()
	return

/obj/structure/divine/magic_mirror/Destroy()
	release_all_souls()
	if(scrying)
		stop_scrying()
	selected_vessel = null
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
	var/list/possible = list()
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(IS_HOG_CULTIST(H))
			continue
		if(IS_HOG_GOD(H))
			continue
		if(H.mind in trapped_souls)
			continue
		possible |= H

	if(!length(possible))
		to_chat(G, span_warning("No suitable vessels found for possession."))
		return

	var/mob/living/carbon/human/vessel = tgui_input_list(G, "Select a vessel for future possession:", "Find Vessel", sort_names(possible))
	if(!vessel)
		return

	selected_vessel = vessel.mind
	to_chat(G, span_notice("You have marked [vessel] as a potential vessel for possession."))
	to_chat(vessel, span_warning("You feel an ominous divine gaze fall upon you..."))

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
	ADD_TRAIT(victim, TRAIT_NO_SOUL, REF(src))

	victim.visible_message(span_danger("[victim] shudders as an eerie light leaves their body and flies into the mirror!"), span_userdanger("You feel a piece of yourself being torn away and trapped within a mirror! If you die... you may not return."))

	trap_cooldown = world.time + trap_cooldown_time
	to_chat(user, span_notice("[victim]'s soul is now bound to the mirror! If they die, they cannot be revived until the mirror is destroyed."))
	to_chat(deity, span_notice("[victim]'s soul has been trapped in a magic mirror by [user]."))

	if(selected_vessel == victim.mind)
		selected_vessel = null
		to_chat(deity, span_warning("[victim] was your chosen vessel — their soul is now trapped and unusable for possession."))

/obj/structure/divine/magic_mirror/proc/release_all_souls()
	for(var/datum/mind/M in trapped_souls)
		if(M.current)
			REMOVE_TRAIT(M.current, TRAIT_NO_SOUL, REF(src))
			to_chat(M.current, span_userdanger("You feel your soul return to you as the mirror shatters! You can be revived again."))
	trapped_souls = list()

/obj/structure/divine/magic_mirror/proc/GiveMirrorHint(mob/victim, mob/user, force=FALSE)
	if(prob(60) || force)
		var/way = dir2text(get_dir(victim, get_turf(src)))
		to_chat(victim, span_warning("You feel a dark presence watching you from the [way]..."))
	if(prob(30) || force)
		var/area/A = get_area(src)
		to_chat(victim, span_warning("The presence feels like it's coming from [A.name]..."))


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
