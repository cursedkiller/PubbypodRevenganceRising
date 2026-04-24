/datum/action/cooldown/hog/build_structure
	name = "Spawn Structure"
	desc = "Begin construction of a divine structure at your location."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "Spawn Structure"
	background_icon_state = "bg_demon"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/hog/build_structure/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/camera/god/deity = owner
	if(!deity.god_nexus)
		if(feedback)
			to_chat(deity, span_warning("You must place your nexus first!"))
		return FALSE
	if(!deity.can_afford(HOG_FAITH_COST_STRUCTURE))
		if(feedback)
			to_chat(deity, span_warning("Not enough faith!"))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/build_structure/Activate(atom/target)
	var/mob/camera/god/deity = owner

	var/list/choices = list("Defense Pylon" = /obj/structure/divine/defensepylon)

	var/chosen_name = tgui_input_list(deity, "Choose a structure:", "Build Structure", choices)
	if(!chosen_name)
		return

	var/build_path = choices[chosen_name]
	if(!deity.spend_faith(HOG_FAITH_COST_STRUCTURE))
		return

	var/obj/structure/divine/construction_holder/CH = new(get_turf(deity))
	CH.assign_deity(deity)
	CH.setup_construction(build_path)
	CH.visible_message(span_notice("A transparent, unfinished [chosen_name] appears!"))
	start_cooldown()
