//Hand of God, god

#define ui_deityhealth "EAST-1:28,CENTER-2:13"
#define ui_deitypower	"EAST-1:28,CENTER-1:15"
#define ui_deityfollowers "EAST-1:28,CENTER:17"
  
	var/obj/screen/deity_health_display
	var/obj/screen/deity_power_display
	var/obj/screen/deity_follower_display

  else if(is_handofgod_god(mymob))
		hoggod_hud()

  	mymob.client.screen += mymob.client.void


/datum/hud/proc/hoggod_hud(ui_style = 'icons/mob/screen_midnight.dmi')
	deity_health_display = new /obj/screen()
	deity_health_display.name = "Nexus Health"
	deity_health_display.icon_state = "deity_nexus"
	deity_health_display.screen_loc = ui_deityhealth
	deity_health_display.layer = 20

	deity_power_display = new /obj/screen()
	deity_power_display.name = "Faith"
	deity_power_display.icon_state = "deity_power"
	deity_power_display.screen_loc = ui_deitypower
	deity_power_display.layer = 20

	deity_follower_display = new /obj/screen()
	deity_follower_display.name = "Followers"
	deity_follower_display.icon_state = "deity_followers"
	deity_follower_display.screen_loc = ui_deityfollowers
	deity_follower_display.layer = 20

	mymob.client.screen = null

	mymob.client.screen += list(deity_health_display, deity_power_display, deity_follower_display)
  /mob/camera/god/UnarmedAttack(atom/A)
	A.attack_god(src)

/mob/camera/god/RangedAttack(atom/A)
	A.attack_god(src)

/atom/proc/attack_god(mob/user)
	return
