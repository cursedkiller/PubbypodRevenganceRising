/datum/action/spell/pointed/divine_transmission
	name = "Divine Transmission"
	desc = "Speak through a target, forcing them to utter your words aloud."
	ranged_mousepointer = 'icons/effects/mouse_pointers/cult_target.dmi'
	background_icon_state = "bg_demon"
	button_icon_state = "bg_demon_border"

	button_icon = 'icons/hud/actions/actions_cult.dmi'
	button_icon_state = "abyssal_gaze"

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
