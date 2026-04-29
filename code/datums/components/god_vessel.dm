/datum/component/god_vessel
	var/mob/living/simple_animal/god/god_ghost
	var/datum/mind/original_soul
	var/has_escaped = FALSE

/datum/component/god_vessel/Initialize(mob/living/simple_animal/god/_god_ghost, datum/mind/_original_soul)
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	god_ghost = _god_ghost
	original_soul = _original_soul
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(on_vessel_death))
	RegisterSignal(parent, COMSIG_MOB_STATCHANGE, PROC_REF(on_stat_change))

/datum/component/god_vessel/Destroy()
	UnregisterSignal(parent, list(COMSIG_LIVING_DEATH, COMSIG_MOB_STATCHANGE))
	god_ghost = null
	original_soul = null
	return ..()

/datum/component/god_vessel/proc/on_vessel_death(mob/living/vessel)
	SIGNAL_HANDLER
	if(has_escaped)
		return
	vessel.visible_message(span_danger("[vessel]'s body crumbles, the divine light fading..."))
	for(var/mob/camera/imaginary_friend/trapped/friend in GLOB.mob_list)
		if(friend.trauma?.owner == vessel && friend.client)
			friend.mind.transfer_to(vessel)
			vessel.revive(ADMIN_HEAL_ALL)
			to_chat(vessel, span_userdanger("You seize control of your body once more! [god_ghost.name] has been expelled!"))
			qdel(friend)
			if(god_ghost && !QDELETED(god_ghost))
				god_ghost.invisibility = initial(god_ghost.invisibility)
				god_ghost.update_icons()
				god_ghost.update_all_huds()
				god_ghost.update_vision()
				if(god_ghost.hud_used)
					god_ghost.hud_used.hoggod_hud(god_ghost)
				god_ghost.mind.purest_vessel = null
				to_chat(god_ghost, span_userdanger("[vessel]'s original soul has reclaimed their body! You have been cast out!"))
			has_escaped = TRUE
			qdel(src)
			return
	if(original_soul && !original_soul.current)
		var/choice = tgui_alert(original_soul, "The divine presence has left your body. Do you wish to return?", "BODY AVAILABLE", list("Return", "Remain as Ghost"), timeout = 10 SECONDS)
		if(choice == "Return")
			if(vessel.mind)
				vessel.mind.transfer_to(god_ghost)
				god_ghost.status_flags &= ~GOD_IS_INCARNATE
				god_ghost.invisibility = initial(god_ghost.invisibility)
				god_ghost.update_icons()
				god_ghost.update_all_huds()
				god_ghost.update_vision()
				if(god_ghost.hud_used)
					god_ghost.hud_used.hoggod_hud(god_ghost)
				for(var/obj/structure/divine/S in god_ghost.structures)
					S.deity = god_ghost
			original_soul.transfer_to(vessel)
			vessel.revive(ADMIN_HEAL_ALL)
			to_chat(vessel, span_userdanger("You return to your body!"))
			god_ghost.mind.purest_vessel = null
			to_chat(god_ghost, span_warning("[vessel]'s soul has reclaimed their body."))
			has_escaped = TRUE
			qdel(src)
			return
	vessel.visible_message(span_warning("[vessel]'s body remains still, the divine presence dormant..."))
	to_chat(god_ghost, span_warning("The original soul has abandoned this body. The vessel is yours permanently — simply revive it."))
	god_ghost.mind.purest_vessel = null
	has_escaped = TRUE
	qdel(src)

/datum/component/god_vessel/proc/on_stat_change(mob/living/vessel, new_stat)
	SIGNAL_HANDLER
	if(has_escaped)
		return
	if(new_stat > CONSCIOUS)
		return
	to_chat(vessel, span_userdanger("Your mortal form is failing! Use Toggle Incarnation to flee within 10 seconds, or die permanently!"))
	addtimer(CALLBACK(src, PROC_REF(check_still_dying), vessel), 10 SECONDS)

/datum/component/god_vessel/proc/check_still_dying(mob/living/vessel)
	if(has_escaped)
		return
	if(vessel.stat < DEAD)
		return
	to_chat(vessel, span_userdanger("Your spirit falters... Eternal oblivion claims you!"))
	vessel.mind?.remove_all_antag_datums()
	SEND_SIGNAL(god_ghost, COMSIG_HOG_DEITY_DEATH)
	for(var/mob/camera/imaginary_friend/trapped/friend in GLOB.mob_list)
		if(friend.trauma?.owner == vessel)
			friend.mind.transfer_to(vessel)
			vessel.revive(ADMIN_HEAL_ALL)
			to_chat(vessel, span_userdanger("[friend.name] rises to claim the empty vessel!"))
			qdel(friend)
			break
	if(god_ghost && !QDELETED(god_ghost))
		qdel(god_ghost)
	qdel(src)
	message_admins("[key_name(vessel)] died permanently while incarnated. The deity is no more.")
