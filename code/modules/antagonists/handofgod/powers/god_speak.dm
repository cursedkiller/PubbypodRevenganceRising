/// Hand of God - God Speak Power
/// Allows the deity to telepathically communicate with all followers at once

/datum/action/cooldown/hog/god_speak
	name = "Divine Telepathy"
	desc = "Speak to all of your followers at once. Your voice will echo in their minds."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "God-Speak"
	background_icon_state = "bg_demon"
	overlay_icon_state = "bg_demon_border"
	cooldown_time = 5 SECONDS

/datum/action/cooldown/hog/god_speak/New(Target)
	. = ..()
	if(!istype(Target, /mob/camera/god))
		qdel(src)
		return

/datum/action/cooldown/hog/god_speak/IsAvailable(feedback = FALSE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/camera/god/deity = owner
	if(!deity.alive_followers)
		if(feedback)
			to_chat(deity, span_warning("You have no followers to speak to!"))
		return FALSE
	return TRUE

/datum/action/cooldown/hog/god_speak/Activate(atom/target)
	var/mob/camera/god/deity = owner
	var/msg = tgui_input_text(deity, "What message do you wish to send to your followers?", "Divine Telepathy", "", MAX_MESSAGE_LEN, multiline = TRUE)
	if(!msg)
		return
	deity.god_speak(msg)
	StartCooldown()
