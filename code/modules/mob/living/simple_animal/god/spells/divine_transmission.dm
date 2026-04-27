/datum/action/spell/pointed/divine_transmission
	name = "Divine Transmission"
	desc = "Speak through a target, forcing them to utter your words aloud."
	ranged_mousepointer = 'icons/effects/mouse_pointers/cult_target.dmi'

	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "God-Speak"
	background_icon_state = "God-Speak"

	school = SCHOOL_EVOCATION
	cooldown_time = 10 SECONDS
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	antimagic_flags = NONE

	cast_range = 7
	active_msg = "You reach out to speak through a mortal vessel..."
	deactive_msg = "You withdraw your divine presence."

	/// Ref back to the god who owns this spell
	var/mob/living/simple_animal/god/our_god

/datum/action/spell/pointed/divine_transmission/New(mob/living/simple_animal/god/god_ref)
	. = ..()
	our_god = god_ref
	update_icon_for_team()

/datum/action/spell/pointed/divine_transmission/proc/update_icon_for_team()
	if(!our_god)
		return
	if(our_god.team_colour == HOG_TEAM_BLUE)
		button_icon_state = "God-Speak-blue"
		background_icon_state = "God-Speak-blue"
	else
		button_icon_state = "God-Speak"
		background_icon_state = "God-Speak"
	var/atom/movable/screen/movable/action_button/button = viewers[our_god]
	if(button)
		button.update_icon()

/datum/action/spell/pointed/divine_transmission/is_valid_spell(mob/user, atom/target)
	if(!isliving(target))
		return FALSE
	var/mob/living/L = target
	if(L.stat == DEAD)
		return FALSE
	return TRUE

/datum/action/spell/pointed/divine_transmission/on_cast(mob/user, mob/living/target)
	. = ..()
	if(!our_god)
		return FALSE
	if(!our_god.god_nexus)
		to_chat(our_god, span_warning("You must place your nexus first!"))
		return FALSE
	if(!our_god.spend_faith(35))
		return FALSE

	var/msg = tgui_input_text(our_god, "What message to broadcast through [target]?", "Divine Transmission", "", MAX_MESSAGE_LEN, multiline = TRUE)
	if(!msg)
		our_god.add_faith(35)
		return FALSE

	target.say(msg, forced = "divine thought")
	to_chat(our_god, span_notice("Your voice echoes through [target]."))
	return TRUE
