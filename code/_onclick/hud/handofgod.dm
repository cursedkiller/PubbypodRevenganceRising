/atom/movable/screen/hog
	icon = 'icons/obj/hand_of_god_structures.dmi'
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/hog/MouseEntered(location, control, params)
	. = ..()
	openToolTip(usr, src, params, title = name, content = desc)

/atom/movable/screen/hog/MouseExited()
	closeToolTip(usr)

/atom/movable/screen/hog/PlaceNexus
	icon_state = "nexus-spawn"
	name = "Nexus"
	desc = "Place your nexus or jump to it."

/atom/movable/screen/hog/PlaceNexus/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		if(deity.god_nexus)
			deity.forceMove(get_turf(deity.god_nexus))
			to_chat(deity, span_notice("You return to your nexus."))
		else
			deity.place_nexus()

/atom/movable/screen/hog/GodSpeak
	icon_state = "God-Speak"
	name = "Divine Telepathy"
	desc = "Speak to all your followers."
/atom/movable/screen/hog
	icon = 'icons/obj/hand_of_god_structures.dmi'
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/hog/MouseEntered(location, control, params)
	. = ..()
	openToolTip(usr, src, params, title = name, content = desc)

/atom/movable/screen/hog/MouseExited()
	closeToolTip(usr)

/atom/movable/screen/hog/PlaceNexus
	icon_state = "nexus-spawn"
	name = "Navigate"
	desc = "Jump to your nexus or a follower. Place your nexus if you haven't yet."

/atom/movable/screen/hog/PlaceNexus/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		if(!deity.god_nexus)
			deity.place_nexus()
			return
		var/list/choices = list("Nexus" = "nexus")
		for(var/datum/mind/M in deity.get_my_followers())
			if(M.current && M.current.stat != DEAD)
				choices[M.current.name] = M.current
		var/chosen = tgui_input_list(deity, "Jump to:", "Navigate", choices)
		if(!chosen)
			return
		if(chosen == "Nexus")
			deity.loc = get_turf(deity.god_nexus)
			to_chat(deity, span_notice("You return to your nexus."))
		else
			var/mob/living/target = choices[chosen]
			deity.loc = get_turf(target)
			to_chat(deity, span_notice("You shift your gaze to [target]."))

/atom/movable/screen/hog/GodSpeak
	icon_state = "God-Speak"
	name = "Divine Telepathy"
	desc = "Speak to all your followers."

/atom/movable/screen/hog/GodSpeak/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.god_speak_input()

/atom/movable/screen/hog/BuildStructure
	icon_state = "Spawn Structure"
	name = "Spawn Structure"
	desc = "Begin construction of a divine structure."

/atom/movable/screen/hog/BuildStructure/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.build_structure()

/atom/movable/screen/hog/PlaceTrap
	icon_state = "Rune-Manifest"
	name = "Rune Manifest"
	desc = "Manifest a divine rune trap."

/atom/movable/screen/hog/PlaceTrap/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.place_trap()

/atom/movable/screen/hog/Smite
	icon_state = "Smite-Nerd"
	name = "Smite"
	desc = "Unleash divine wrath upon a non-believer."

/atom/movable/screen/hog/Smite/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.smite_target()

/atom/movable/screen/hog/ConjureEquipment
	icon_state = "Conjure Equipment"
	name = "Conjure Equipment"
	desc = "Grant weapons and armor to a chosen follower."

/atom/movable/screen/hog/ConjureEquipment/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.conjure_equipment()

/atom/movable/screen/hog/ConjureCalamity
	icon_state = "Conjure Calamity"
	name = "Conjure Calamity"
	desc = "Unleash a devastating calamity upon the station."

/atom/movable/screen/hog/ConjureCalamity/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.conjure_calamity()

/atom/movable/screen/hog/ObfuscateStructure
	icon_state = "obfuscate-structure"
	name = "Obfuscate Structure"
	desc = "Hide your structures from non-believers."

/atom/movable/screen/hog/ObfuscateStructure/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.obfuscate_structure()

/atom/movable/screen/hog/AppointProphet
	icon_state = "appoint-pope"
	name = "Appoint Prophet"
	desc = "Promote a loyal follower to become your prophet."

/atom/movable/screen/hog/AppointProphet/Click()
	if(istype(usr, /mob/living/simple_animal/god))
		var/mob/camera/god/deity = usr
		deity.appoint_prophet()

/datum/hud/proc/hoggod_hud(mob/living/simple_animal/god/deity)
	if(!deity)
		return

	deity_health_display = new /atom/movable/screen()
	deity_health_display.name = "Nexus Health"
	deity_health_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_health_display.icon_state = "deity_nexus"
	deity_health_display.screen_loc = ui_deityhealth
	infodisplay += deity_health_display

	deity_power_display = new /atom/movable/screen()
	deity_power_display.name = "Faith"
	deity_power_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_power_display.icon_state = "deity_power"
	deity_power_display.screen_loc = ui_deitypower
	infodisplay += deity_power_display

	deity_follower_display = new /atom/movable/screen()
	deity_follower_display.name = "Followers"
	deity_follower_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_follower_display.icon_state = "deity_followers"
	deity_follower_display.screen_loc = ui_deityfollowers
	infodisplay += deity_follower_display

	var/atom/movable/screen/hog/using

	using = new /atom/movable/screen/hog/GodSpeak(null, src)
	using.screen_loc = ui_inventory
	static_inventory += using

	using = new /atom/movable/screen/hog/PlaceNexus(null, src)
	using.screen_loc = ui_zonesel
	static_inventory += using

	using = new /atom/movable/screen/hog/BuildStructure(null, src)
	using.screen_loc = ui_belt
	static_inventory += using

	using = new /atom/movable/screen/hog/PlaceTrap(null, src)
	using.screen_loc = ui_back
	static_inventory += using

	using = new /atom/movable/screen/hog/Smite(null, src)
	using.screen_loc = ui_hand_position(1)
	static_inventory += using

	using = new /atom/movable/screen/hog/ConjureEquipment(null, src)
	using.screen_loc = ui_hand_position(2)
	static_inventory += using

	using = new /atom/movable/screen/hog/ConjureCalamity(null, src)
	using.screen_loc = ui_storage1
	static_inventory += using

	using = new /atom/movable/screen/hog/ObfuscateStructure(null, src)
	using.screen_loc = ui_storage2
	static_inventory += using

	using = new /atom/movable/screen/hog/AppointProphet(null, src)
	using.screen_loc = "CENTER-4:16,SOUTH:5"
	static_inventory += using

	if(mymob.client)
		mymob.client.screen |= list(deity_health_display, deity_power_display, deity_follower_display)
		mymob.client.screen |= static_inventory

	deity.update_all_huds()
