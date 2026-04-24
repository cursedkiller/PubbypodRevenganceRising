/// Hand of God - Build Structure Power
/// Allows the deity to begin construction of a divine structure

/datum/action/cooldown/hog/build_structure
	name = "Spawn Structure"
	desc = "Begin construction of a divine structure at your location. Your followers will need to complete it with gems."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "Spawn Structure"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	cooldown_time = 30 SECONDS

/datum/action/cooldown/hog/build_structure/New(Target)
	. = ..()
	if(!istype(Target, /mob/camera/god))
		qdel(src)
		return

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
			to_chat(deity, span_warning("Not enough faith! You need [HOG_FAITH_COST_STRUCTURE] faith."))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/build_structure/Activate(atom/target)
	var/mob/camera/god/deity = owner

	var/list/structure_choices = list()
	for(var/name in GLOB.global_handofgod_structuretypes)
		var/obj/structure/divine/path = GLOB.global_handofgod_structuretypes[name]
		if(!isnull(path) && !initial(path.is_trap) && !initial(path.is_construction_holder))
			structure_choices[name] = path

	if(!length(structure_choices))
		to_chat(deity, span_warning("No structures are available to build!"))
		return

	var/chosen_name = tgui_input_list(deity, "Choose a structure to build:", "Build Structure", structure_choices)
	if(!chosen_name)
		return

	var/build_path = structure_choices[chosen_name]
	if(!deity.spend_faith(HOG_FAITH_COST_STRUCTURE))
		return

	var/obj/structure/divine/construction_holder/CH = new(get_turf(deity))
	CH.assign_deity(deity)
	CH.setup_construction(build_path)
	CH.visible_message(span_notice("A transparent, unfinished [chosen_name] appears! It can be completed by adding gems."))
	to_chat(deity, span_boldnotice("You may click your construction site to cancel it, but only faith is refunded."))
	StartCooldown()
