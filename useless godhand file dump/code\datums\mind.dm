/datum/mind/proc/remove_hog_follower_prophet()
	ticker.mode.red_deity_followers -= src
	ticker.mode.red_deity_prophets -= src
	ticker.mode.blue_deity_prophets -= src
	ticker.mode.blue_deity_followers -= src
	ticker.mode.update_hog_icons_removed(src, "red")
	ticker.mode.update_hog_icons_removed(src, "blue")

  //idk what this is theres alot of space

  	/** HAND OF GOD **/
	text = "hand of god"
	if(ticker.mode.config_tag == "handofgod")
		text = uppertext(text)
	text = "<i><b>[text]</b></i>: "
	if(src in ticker.mode.red_deity_prophets)
		text += "<b>RED PROPHET</b>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet</a>|<a href='?src=\ref[src];handofgod=red god'>red god</a>|<a href='?src=\ref[src];handofgod=blue god'>blue god</a>"
	else if (src in ticker.mode.red_deity_followers)
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<b>RED FOLLOWER</b>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet</a>|<a href='?src=\ref[src];handofgod=red god'>red god</a>|<a href='?src=\ref[src];handofgod=blue god'>blue god</a>"
	else if (src in ticker.mode.blue_deity_followers)
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|BLUE FOLLOWER|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet|<a href='?src=\ref[src];handofgod=red god'>red god</a>|<a href='?src=\ref[src];handofgod=blue god'>blue god</a></a>"
	else if (src in ticker.mode.blue_deity_prophets)
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|BLUE PROPHET|<a href='?src=\ref[src];handofgod=red god'>red god</a>|<a href='?src=\ref[src];handofgod=blue god'>blue god</a>"
	else if (src in ticker.mode.red_deities)
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet</a>|RED GOD|<a href='?src=\ref[src];handofgod=blue god'>blue god</a>"
	else if (src in ticker.mode.blue_deities)
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<a href='?src=\ref[src];handofgod=clear'>employee</a>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet</a>|<a href='?src=\ref[src];handofgod=red god'>red god</a>|BLUE GOD"
	else
		text += "<a href='?src=\ref[src];handofgod=red prophet'>red prophet</a>|<a href='?src=\ref[src];handofgod=red follower'>red follower</a>|<b>EMPLOYEE</b>|<a href='?src=\ref[src];handofgod=blue follower'>blue follower</a>|<a href='?src=\ref[src];handofgod=blue prophet'>blue prophet</a>|<a href='?src=\ref[src];handofgod=red god'>red god</a>|<a href='?src=\ref[src];handofgod=blue god'>blue god</a>"

	if(current && current.client && (ROLE_HOG_GOD in current.client.prefs.be_special))
		text += "|HOG God Enabled in Prefs"
	else
		text += "|HOG God Disabled in Prefs"

	if(current && current.client && (ROLE_HOG_CULTIST in current.client.prefs.be_special))
		text += "|HOG Cultist Enabled in Prefs"
	else
		text += "|HOG Disabled in Prefs"

	sections["follower"] = text

  //**new objective defines**//
  
var/new_obj_type = input("Select objective type:", "Objective type", def_value) as null|anything in list("assassinate", "maroon", "debrain", "protect", "destroy", "prevent", "hijack", "escape", "survive", "martyr", "steal", "download", "nuclear", "capture", "absorb", "custom","follower block (HOG)","build (HOG)","deicide (HOG)", "follower escape (HOG)", "sacrifice prophet (HOG)")

  // **more objective defines**//

  			if("follower block (HOG)")
				new_objective = new /datum/objective/follower_block
				new_objective.owner = src
			if("build (HOG)")
				new_objective = new /datum/objective/build
				new_objective.owner = src
			if("deicide (HOG)")
				new_objective = new /datum/objective/deicide
				new_objective.owner = src
			if("follower escape (HOG)")
				new_objective = new /datum/objective/escape_followers
				new_objective.owner = src
			if("sacrifice prophet (HOG)")
				new_objective = new /datum/objective/sacrifice_prophet
				new_objective.owner = src

  //**admin stuff**//
  else if (href_list["handofgod"])
		switch(href_list["handofgod"])
			if("clear") //wipe handofgod status
				if((src in ticker.mode.red_deity_followers) || (src in ticker.mode.blue_deity_followers) || (src in ticker.mode.red_deity_prophets) || (src in ticker.mode.blue_deity_prophets))
					remove_hog_follower_prophet()
					current << "<span class='danger'><B>You have been brainwashed... again! Your faith is no more!</B></span>"
					message_admins("[key_name_admin(usr)] has de-hand of god'ed [current].")
					log_admin("[key_name(usr)] has de-hand of god'ed [current].")

			if("red follower")
				make_Handofgod_follower("red")
				message_admins("[key_name_admin(usr)] has red follower'ed [current].")
				log_admin("[key_name(usr)] has red follower'ed [current].")

			if("red prophet")
				make_Handofgod_prophet("red")
				message_admins("[key_name_admin(usr)] has red prophet'ed [current].")
				log_admin("[key_name(usr)] has red prophet'ed [current].")

			if("blue follower")
				make_Handofgod_follower("blue")
				message_admins("[key_name_admin(usr)] has blue follower'ed [current].")
				log_admin("[key_name(usr)] has blue follower'ed [current].")

			if("blue prophet")
				make_Handofgod_prophet("blue")
				message_admins("[key_name_admin(usr)] has blue prophet'ed [current].")
				log_admin("[key_name(usr)] has blue prophet'ed [current].")

			if("red god")
				make_Handofgod_god("red")
				message_admins("[key_name_admin(usr)] has red god'ed [current].")
				log_admin("[key_name(usr)] has red god'ed [current].")

			if("blue god")
				make_Handofgod_god("blue")
				message_admins("[key_name_admin(usr)] has blue god'ed [current].")
				log_admin("[key_name(usr)] has blue god'ed [current].")

  //** more admin stuff **//

  /datum/mind/proc/make_Handofgod_follower(colour)
	. = 0
	switch(colour)
		if("red")
			//Remove old allegiances
			if(src in ticker.mode.blue_deity_followers || src in ticker.mode.blue_deity_prophets)
				current << "<span class='danger'><B>You are no longer a member of the Blue cult!<B></span>"

			ticker.mode.blue_deity_followers -= src
			ticker.mode.blue_deity_prophets -= src
			current.faction |= "red god"
			current.faction -= "blue god"

			if(src in ticker.mode.red_deity_prophets)
				current << "<span class='danger'><B>You have lost the connection with your deity, but you still believe in their grand design, You are no longer a prophet!</b></span>"
				ticker.mode.red_deity_prophets -= src

			ticker.mode.red_deity_followers |= src
			current << "<span class='danger'><B>You are now a follower of the red cult's god!</b></span>"

			special_role = "Hand of God: Red Follower"
			. = 1
		if("blue")
			//Remove old allegiances
			if(src in ticker.mode.red_deity_followers || src in ticker.mode.red_deity_prophets)
				current << "<span class='danger'><B>You are no longer a member of the Red cult!<B></span>"

			ticker.mode.red_deity_followers -= src
			ticker.mode.red_deity_prophets -= src
			current.faction -= "red god"
			current.faction |= "blue god"

			if(src in ticker.mode.blue_deity_prophets)
				current << "<span class='danger'><B>You have lost the connection with your deity, but you still believe in their grand design, You are no longer a prophet!</b></span>"
				ticker.mode.blue_deity_prophets -= src

			ticker.mode.blue_deity_followers |= src
			current << "<span class='danger'><B>You are now a follower of the blue cult's god!</b></span>"

			special_role = "Hand of God: Blue Follower"
			. = 1
		else
			return 0

	ticker.mode.update_hog_icons_removed(src,"red")
	ticker.mode.update_hog_icons_removed(src,"blue")
	//ticker.mode.greet_hog_follower(src,colour)
	ticker.mode.update_hog_icons_added(src, colour)

/datum/mind/proc/make_Handofgod_prophet(colour)
	. = 0
	switch(colour)
		if("red")
			//Remove old allegiances

			if(src in ticker.mode.blue_deity_followers || src in ticker.mode.blue_deity_prophets)
				current << "<span class='danger'><B>You are no longer a member of the Blue cult!<B></span>"
				current.faction -= "blue god"
			current.faction |= "red god"

			ticker.mode.blue_deity_followers -= src
			ticker.mode.blue_deity_prophets -= src
			ticker.mode.red_deity_followers -= src

			ticker.mode.red_deity_prophets |= src
			current << "<span class='danger'><B>You are now a prophet of the red cult's god!</b></span>"

			special_role = "Hand of God: Red Prophet"
			. = 1
		if("blue")
			//Remove old allegiances

			if(src in ticker.mode.red_deity_followers || src in ticker.mode.red_deity_prophets)
				current << "<span class='danger'><B>You are no longer a member of the Red cult!<B></span>"
				current.faction -= "red god"
			current.faction |= "blue god"

			ticker.mode.red_deity_followers -= src
			ticker.mode.red_deity_prophets -= src
			ticker.mode.blue_deity_followers -= src

			ticker.mode.blue_deity_prophets |= src
			current << "<span class='danger'><B>You are now a prophet of the blue cult's god!</b></span>"

			special_role = "Hand of God: Blue Prophet"
			. = 1

		else
			return 0

	ticker.mode.update_hog_icons_removed(src,"red")
	ticker.mode.update_hog_icons_removed(src,"blue")
	ticker.mode.greet_hog_follower(src,colour)
	ticker.mode.update_hog_icons_added(src, colour)


/datum/mind/proc/make_Handofgod_god(colour)
	switch(colour)
		if("red")
			current.become_god("red")
			ticker.mode.add_god(src,"red")
		if("blue")
			current.become_god("blue")
			ticker.mode.add_god(src,"blue")
		else
			return 0
	ticker.mode.forge_deity_objectives(src)
	ticker.mode.remove_hog_follower(src,0)
	ticker.mode.update_hog_icons_added(src, colour)
//	ticker.mode.greet_hog_follower(src,colour)
	return 1
