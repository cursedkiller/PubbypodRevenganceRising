/datum/action/cooldown/hog/god_speak
	name = "Divine Telepathy"
	desc = "Speak to all of your followers at once."
	button_icon = 'icons/obj/hand_of_god_structures.dmi'
	button_icon_state = "God-Speak"
	background_icon_state = "bg_demon"
	cooldown_time = 5 SECONDS

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
