/datum/action/spell/pointed/divine_transmission
	name = "Divine Transmission"
	desc = "Speak through a target, forcing them to utter your words aloud."
	ranged_mousepointer = 'icons/effects/mouse_pointers/cult_target.dmi'

	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "God-Speak"
	background_icon_state = "God-Speak"

	school = SCHOOL_EVOCATION
	cooldown_time = 0
	invocation_type = INVOCATION_NONE
	spell_requirements = NONE
	antimagic_flags = NONE

	cast_range = 7
	active_msg = "You reach out to speak through a mortal vessel..."
	deactive_msg = "You withdraw your divine presence."

	var/mob/living/simple_animal/god/our_god

/datum/action/spell/pointed/divine_transmission/New(mob/living/simple_animal/god/god_ref)
	. = ..()
	our_god = god_ref
	button_icon_state = ""
	background_icon_state = ""

/datum/action/spell/pointed/divine_transmission/Grant(mob/grant_to)
	. = ..()
	var/atom/movable/screen/movable/action_button/button = viewers[grant_to]
	if(button)
		button.alpha = 0
		button.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		button.icon = null
		button.icon_state = ""
		button.cut_overlays()

/datum/action/spell/pointed/divine_transmission/update_button(atom/movable/screen/movable/action_button/button, status_only = FALSE, force = FALSE)
	. = ..()
	if(button)
		button.alpha = 0
		button.mouse_opacity = MOUSE_OPACITY_TRANSPARENT
		button.icon = null
		button.icon_state = ""
		button.cut_overlays()

/datum/action/spell/pointed/divine_transmission/on_activation(mob/on_who)
	. = ..()
	if(our_god)
		our_god.transmitting = TRUE

/datum/action/spell/pointed/divine_transmission/on_deactivation(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(our_god)
		our_god.transmitting = FALSE

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
	our_god.transmitting = FALSE
	if(!our_god.god_nexus)
		to_chat(our_god, span_warning("You must place your nexus first!"))
		return FALSE

	var/msg = tgui_input_text(our_god, "What message to broadcast through [target]?", "Divine Transmission", "", MAX_MESSAGE_LEN, multiline = TRUE)
	if(!msg)
		return FALSE

	if(!our_god.spend_faith(35))
		return FALSE

	target.say(msg, forced = "divine thought")
	to_chat(our_god, span_notice("Your voice echoes through [target]."))
	return TRUE
