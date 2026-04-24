/datum/hud/proc/hoggod_hud(mob/camera/god/deity)
	if(!deity)
		return

	deity_health_display = new /atom/movable/screen()
	deity_health_display.name = "Nexus Health"
	deity_health_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_health_display.icon_state = "deity_nexus"
	deity_health_display.screen_loc = ui_deityhealth

	deity_power_display = new /atom/movable/screen()
	deity_power_display.name = "Faith"
	deity_power_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_power_display.icon_state = "deity_power"
	deity_power_display.screen_loc = ui_deitypower

	deity_follower_display = new /atom/movable/screen()
	deity_follower_display.name = "Followers"
	deity_follower_display.icon = 'icons/obj/hand_of_god_structures.dmi'
	deity_follower_display.icon_state = "deity_followers"
	deity_follower_display.screen_loc = ui_deityfollowers

	infodisplay += deity_health_display
	infodisplay += deity_power_display
	infodisplay += deity_follower_display

	if(mymob.client)
		mymob.client.screen |= list(deity_health_display, deity_power_display, deity_follower_display)

	deity.update_all_huds()
