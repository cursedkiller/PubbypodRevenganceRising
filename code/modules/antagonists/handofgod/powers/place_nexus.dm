/// Hand of God - Place Nexus Power
/// Allows the deity to anchor themselves to the physical realm

/datum/action/cooldown/hog/place_nexus
	name = "Place Nexus"
	desc = "Anchor yourself to this realm by placing your nexus at your current location. If you don't place one within 15 minutes, it will be placed automatically."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "nexus"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	cooldown_time = 0 // Can only be used once
	/// Whether the nexus has been placed
	var/nexus_placed = FALSE

/datum/action/cooldown/hog/place_nexus/New(Target)
	. = ..()
	if(!istype(Target, /mob/camera/god))
		qdel(src)
		return

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
		to_chat(deity, span_notice("You have placed your nexus! You are now anchored to this realm."))
		Remove(deity)
