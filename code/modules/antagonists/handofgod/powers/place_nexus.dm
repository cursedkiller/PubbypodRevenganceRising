/datum/action/cooldown/hog/place_nexus
	name = "Place Nexus"
	desc = "Anchor yourself to this realm by placing your nexus at your current location."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "nexus"
	background_icon_state = "bg_demon"
	cooldown_time = 0
	var/nexus_placed = FALSE

/datum/action/cooldown/hog/place_nexus/Grant(mob/grant_to)
	. = ..()
	var/mob/camera/god/deity = grant_to
	if(deity.god_nexus)
		nexus_placed = TRUE

/datum/action/cooldown/hog/place_nexus/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	if(nexus_placed)
		return FALSE
	var/mob/camera/god/deity = owner
	if(deity.god_nexus)
		if(feedback)
			to_chat(deity, span_warning("You already have a nexus!"))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/place_nexus/Activate(atom/target)
	var/mob/camera/god/deity = owner
	if(deity.place_nexus())
		nexus_placed = TRUE
		to_chat(deity, span_notice("You have placed your nexus!"))
		Remove(deity)
