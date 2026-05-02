// ============================================================
// DIVINE SCROLL ITEMS
// Crafted at the Scribing Table by drawing sacred runes
// ============================================================

/obj/item/scroll
	name = "divine scroll"
	desc = "A parchment inscribed with glowing divine runes. The power within awaits release."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "scroll"
	w_class = WEIGHT_CLASS_TINY
	var/uses = 1
	var/scroll_quality = "adequate"

/obj/item/scroll/examine(mob/user)
	. = ..()
	if(uses > 0)
		. += span_notice("Quality: <b>[scroll_quality]</b>. Uses remaining: <b>[uses]</b>.")
	else
		. += span_warning("The runes have faded completely. It's just blank parchment now.")

/obj/item/scroll/attack_self(mob/user)
	if(uses <= 0)
		to_chat(user, span_warning("The scroll crumbles to dust in your hands!"))
		qdel(src)
		return

	uses--
	user.visible_message(span_notice("[user] unfurls a scroll and reads aloud..."), span_notice("You read the sacred runes and unleash their power!"))
	playsound(user, 'sound/magic/castsummon.ogg', 50, TRUE)
	activate(user)

	if(uses <= 0)
		to_chat(user, span_warning("The scroll crumbles to dust after its final use."))
		icon_state = "scroll-complete"
		addtimer(CALLBACK(src, PROC_REF(turn_to_dust)), 2 SECONDS)

/obj/item/scroll/proc/activate(mob/user)
	return

/obj/item/scroll/proc/turn_to_dust()
	new /obj/effect/decal/cleanable/ash(get_turf(src))
	qdel(src)


// ============================================================
// SMITE SCROLL
// ============================================================

/obj/item/scroll/smite
	name = "Scroll of Smiting"
	desc = "A scroll inscribed with a searing bolt of divine fury. Those who oppose the faith shall be struck down."
	icon_state = "scroll-smite"

/obj/item/scroll/smite/activate(mob/user)
	var/mob/living/target = null
	for(var/mob/living/L in view(7, user))
		if(L == user)
			continue
		if(IS_HOG_CULTIST(L))
			continue
		if(L.stat == DEAD)
			continue
		target = L
		break

	if(!target)
		to_chat(user, span_warning("No valid target in range! The divine energy dissipates."))
		return

	user.visible_message(
		span_danger("[user] points the scroll at [target], unleashing a bolt of divine lightning!"),
		span_danger("You unleash divine fury upon [target]!"))
	target.visible_message(
		span_danger("[target] is struck by a bolt of divine lightning!"),
		span_userdanger("A bolt of divine lightning strikes you from above!"))

	switch(scroll_quality)
		if("perfect")
			target.adjustFireLoss(40)
			target.adjustBruteLoss(25)
			target.Knockdown(5 SECONDS)
		if("adequate")
			target.adjustFireLoss(25)
			target.adjustBruteLoss(15)
			target.Knockdown(3 SECONDS)
		if("flawed")
			target.adjustFireLoss(15)
			target.adjustBruteLoss(8)

	playsound(target, 'sound/magic/lightningshock.ogg', 60, TRUE)
	new /obj/effect/temp_visual/cult/sparks(get_turf(target))


// ============================================================
// WARD SCROLL
// ============================================================

/obj/item/scroll/ward
	name = "Scroll of Warding"
	desc = "A scroll inscribed with a protective diamond pattern. Creates a shimmering barrier around the caster."
	icon_state = "scroll-ward"

/obj/item/scroll/ward/activate(mob/user)
	var/duration = 20 SECONDS
	var/resistance = 0.5

	switch(scroll_quality)
		if("perfect")
			duration = 45 SECONDS
			resistance = 0.2
		if("adequate")
			duration = 30 SECONDS
			resistance = 0.4
		if("flawed")
			duration = 15 SECONDS
			resistance = 0.6

	user.apply_status_effect(/datum/status_effect/divine_ward, duration, resistance)
	user.visible_message(
		span_notice("[user] is surrounded by a shimmering divine barrier!"),
		span_notice("A protective barrier forms around you!"))


// ============================================================
// HEAL SCROLL
// ============================================================

/obj/item/scroll/heal
	name = "Scroll of Healing"
	desc = "A scroll inscribed with a restorative cross. Mends the wounds of the faithful."
	icon_state = "scroll-heal"

/obj/item/scroll/heal/activate(mob/user)
	var/heal_amount = 25
	var/range = 3

	switch(scroll_quality)
		if("perfect")
			heal_amount = 50
			range = 5
		if("adequate")
			heal_amount = 35
			range = 4
		if("flawed")
			heal_amount = 20
			range = 2

	user.visible_message(
		span_notice("[user]'s scroll emits a warm, healing light!"),
		span_notice("Warm divine light washes over the area, mending wounds."))

	for(var/mob/living/L in range(range, user))
		if(IS_HOG_CULTIST(L) || L == user)
			L.adjustBruteLoss(-heal_amount)
			L.adjustFireLoss(-heal_amount)
			L.adjustToxLoss(-heal_amount * 0.5)
			L.adjustOxyLoss(-heal_amount * 0.5)

	playsound(user, 'sound/magic/staff_healing.ogg', 50, TRUE)


// ============================================================
// TRANSLOCATION SCROLL
// ============================================================

/obj/item/scroll/teleport
	name = "Scroll of Translocation"
	desc = "A scroll inscribed with a spiraling teleportation rune. Tears through space itself."
	icon_state = "scroll-teleport"

/obj/item/scroll/teleport/activate(mob/user)
	var/teleport_range = 7
	var/teleport_accuracy = "safe" // "safe", "scattered", "wild"

	switch(scroll_quality)
		if("perfect")
			teleport_range = 12
			teleport_accuracy = "safe"
		if("adequate")
			teleport_range = 8
			teleport_accuracy = "scattered"
		if("flawed")
			teleport_range = 5
			teleport_accuracy = "wild"

	var/list/turfs = list()
	for(var/turf/open/floor/F in range(teleport_range, user))
		if(!F.is_blocked_turf())
			turfs += F

	if(!length(turfs))
		to_chat(user, span_warning("The scroll fizzles... nowhere safe to teleport!"))
		return

	var/turf/dest = null
	switch(teleport_accuracy)
		if("safe")
			// Pick a safe, open location
			var/list/safe_turfs = list()
			for(var/turf/T in turfs)
				var/safe = TRUE
				for(var/mob/living/L in T)
					safe = FALSE
					break
				if(safe)
					safe_turfs += T
			if(length(safe_turfs))
				dest = pick(safe_turfs)
			else
				dest = pick(turfs)
		if("scattered")
			dest = pick(turfs)
			user.adjustBruteLoss(5) // rough landing
		if("wild")
			dest = pick(turfs)
			user.adjustBruteLoss(10)
			user.Paralyze(2 SECONDS)
			user.set_confusion(5 SECONDS)

	if(dest)
		playsound(user, 'sound/magic/blink.ogg', 50, TRUE)
		do_teleport(user, dest, 0, channel = TELEPORT_CHANNEL_BLUESPACE)
		user.visible_message(
			span_warning("[user] vanishes in a flash of light!"),
			span_notice("Space warps around you as you teleport!"))


// ============================================================
// DIVINE WARD STATUS EFFECT
// ============================================================

/datum/status_effect/divine_ward
	id = "divine_ward"
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/divine_ward
	var/resistance_multiplier = 0.5

/datum/status_effect/divine_ward/on_creation(mob/living/new_owner, duration, resistance)
	src.duration = duration
	src.resistance_multiplier = resistance
	return ..()

/datum/status_effect/divine_ward/on_apply()
	owner.physiology.brute_mod *= resistance_multiplier
	owner.physiology.burn_mod *= resistance_multiplier
	owner.add_atom_colour("#44ccff", TEMPORARY_COLOUR_PRIORITY)
	return TRUE

/datum/status_effect/divine_ward/on_remove()
	owner.physiology.brute_mod /= resistance_multiplier
	owner.physiology.burn_mod /= resistance_multiplier
	owner.remove_atom_colour(TEMPORARY_COLOUR_PRIORITY, "#44ccff")

/atom/movable/screen/alert/status_effect/divine_ward
	name = "Divine Ward"
	desc = "You are protected by a shimmering divine barrier."
	icon_state = "ward"
