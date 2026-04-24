/// Hand of God - Place Trap Power
/// Allows the deity to place a divine trap at their location

/datum/action/cooldown/hog/place_trap
	name = "Rune Manifest"
	desc = "Manifest a divine rune trap at your current location. Traps affect non-believers who step on them."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "Rune-Manifest"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	cooldown_time = 15 SECONDS

/datum/action/cooldown/hog/place_trap/New(Target)
	. = ..()
	if(!istype(Target, /mob/camera/god))
		qdel(src)
		return

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
			to_chat(deity, span_warning("Not enough faith! You need [HOG_FAITH_COST_TRAP] faith."))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/place_trap/Activate(atom/target)
	var/mob/camera/god/deity = owner

	var/list/trap_choices = list()
	for(var/name in GLOB.global_handofgod_traptypes)
		var/obj/structure/divine/path = GLOB.global_handofgod_traptypes[name]
		if(!isnull(path) && initial(path.is_trap))
			trap_choices[name] = path

	if(!length(trap_choices))
		to_chat(deity, span_warning("No traps are available to place!"))
		return

	var/chosen_name = tgui_input_list(deity, "Choose a trap to manifest:", "Rune Manifest", trap_choices)
	if(!chosen_name)
		return

	var/trap_path = trap_choices[chosen_name]
	if(!deity.spend_faith(HOG_FAITH_COST_TRAP))
		return

	new trap_path(get_turf(deity))
	to_chat(deity, span_notice("You manifest \a [chosen_name]."))
	StartCooldown()
