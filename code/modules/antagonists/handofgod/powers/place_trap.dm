/datum/action/cooldown/hog/place_trap
	name = "Rune Manifest"
	desc = "Manifest a divine rune trap at your current location."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "Rune-Manifest"
	background_icon_state = "bg_demon"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/hog/place_trap/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/camera/god/deity = owner
	if(!deity.god_nexus)
		if(feedback)
			to_chat(deity, span_warning("You must place your nexus first!"))
		return FALSE
	if(!deity.can_afford(HOG_FAITH_COST_TRAP))
		if(feedback)
			to_chat(deity, span_warning("Not enough faith!"))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/place_trap/Activate(atom/target)
	var/mob/camera/god/deity = owner
	if(!deity.spend_faith(HOG_FAITH_COST_TRAP))
		return

	new /obj/structure/divine/defensepylon(get_turf(deity))
	to_chat(deity, span_notice("You manifest a defense pylon."))
	start_cooldown()
