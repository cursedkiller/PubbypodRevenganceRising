/atom/movable/screen/hog
	icon = 'icons/obj/hand_of_god_structures.dmi'
	mouse_over_pointer = MOUSE_HAND_POINTER

/atom/movable/screen/hog/MouseEntered(location, control, params)
	. = ..()
	openToolTip(usr, src, params, title = name, content = desc)

/atom/movable/screen/hog/MouseExited()
	closeToolTip(usr)

/atom/movable/screen/hog/PlaceNexus
	icon_state = "nexus"
	name = "Place Nexus"
	desc = "Anchor yourself to this realm."

/atom/movable/screen/hog/PlaceNexus/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.place_nexus()

/atom/movable/screen/hog/GodSpeak
	icon_state = "God-Speak"
	name = "Divine Telepathy"
	desc = "Speak to all your followers."

/atom/movable/screen/hog/GodSpeak/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.god_speak_input()

/atom/movable/screen/hog/BuildStructure
	icon_state = "Spawn Structure"
	name = "Spawn Structure"
	desc = "Begin construction of a divine structure."

/atom/movable/screen/hog/BuildStructure/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.build_structure()

/atom/movable/screen/hog/PlaceTrap
	icon_state = "Rune-Manifest"
	name = "Rune Manifest"
	desc = "Manifest a divine rune trap."

/atom/movable/screen/hog/PlaceTrap/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.place_trap()

/atom/movable/screen/hog/Smite
	icon_state = "Smite-Nerd"
	name = "Smite"
	desc = "Unleash divine wrath upon a non-believer."

/atom/movable/screen/hog/Smite/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.smite_target()

/atom/movable/screen/hog/ConjureEquipment
	icon_state = "Conkure Equipment"
	name = "Conjure Equipment"
	desc = "Grant weapons and armor to a chosen follower."

/atom/movable/screen/hog/ConjureEquipment/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.conjure_equipment()

/atom/movable/screen/hog/ConjureCalamity
	icon_state = "Conjure Calamity"
	name = "Conjure Calamity"
	desc = "Unleash a devastating calamity upon the station."

/atom/movable/screen/hog/ConjureCalamity/Click()
	if(istype(usr, /mob/camera/god))
		var/mob/camera/god/deity = usr
		deity.conjure_calamity()

/datum/hud/proc/hoggod_hud(mob/camera/god/deity)
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
	using.screen_loc = ui_storage1
	static_inventory += using

	using = new /atom/movable/screen/hog/ConjureCalamity(null, src)
	using.screen_loc = ui_storage2
	static_inventory += using

	if(mymob.client)
		mymob.client.screen |= list(deity_health_display, deity_power_display, deity_follower_display)
		mymob.client.screen |= static_inventory

	deity.update_all_huds()
