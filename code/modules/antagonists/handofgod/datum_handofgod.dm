/datum/antagonist/hog_god
	name = "Hand of God"
	roundend_category = "hand of god"
	antagpanel_category = "Hand of God"
	show_in_antagpanel = FALSE
	banning_key = ROLE_HOG_GOD
	required_living_playtime = 6
	var/datum/team/hog/cult_team

/datum/antagonist/hog_god/get_team()
	return cult_team

/datum/antagonist/hog_god/create_team(datum/team/hog/new_team)
	if(!new_team)
		for(var/datum/antagonist/hog_god/existing in GLOB.antagonists)
			if(!existing.owner)
				continue
			if(existing.cult_team)
				cult_team = existing.cult_team
				return
		cult_team = new /datum/team/hog()
		cult_team.setup_team()
		return
	cult_team = new_team

/datum/antagonist/hog_god/on_gain()
	. = ..()
	cult_team.add_member(owner)
	cult_team.set_deity(owner)
	add_hog_hud(owner.current, cult_team.team_colour, "god")

/datum/antagonist/hog_god/on_removal()
	remove_hog_hud(owner.current, cult_team.team_colour)
	if(cult_team)
		cult_team.remove_member(owner)
		cult_team.deity = null
	return ..()

/datum/antagonist/hog_god/greet()
	to_chat(owner, span_userdanger("You are a deity! You are worshipped by a cult!"))
	owner.announce_objectives()

/datum/antagonist/hog_cultist
	name = "Hand of God Cultist"
	roundend_category = "hand of god cultists"
	antagpanel_category = "Hand of God"
	banning_key = ROLE_HOG_CULTIST
	required_living_playtime = 4
	var/datum/team/hog/cult_team

/datum/antagonist/hog_cultist/get_team()
	return cult_team

/datum/antagonist/hog_cultist/create_team(datum/team/hog/new_team)
	if(!new_team)
		for(var/datum/antagonist/hog_god/god in GLOB.antagonists)
			if(!god.owner)
				continue
			if(god.cult_team)
				cult_team = god.cult_team
				return
		return
	cult_team = new_team

/datum/antagonist/hog_cultist/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	if(cult_team.team_colour == HOG_TEAM_RED)
		current.faction |= FACTION_RED_GOD
	else
		current.faction |= FACTION_BLUE_GOD
	ADD_TRAIT(current, TRAIT_HOG_CULTIST, TRAIT_HOG)
	cult_team.add_member(owner)
	add_hog_hud(current, cult_team.team_colour, "follower")

/datum/antagonist/hog_cultist/on_removal()
	var/mob/living/current = owner.current
	current.faction -= FACTION_RED_GOD
	current.faction -= FACTION_BLUE_GOD
	REMOVE_TRAIT(current, TRAIT_HOG_CULTIST, TRAIT_HOG)
	remove_hog_hud(current, cult_team.team_colour)
	if(cult_team)
		cult_team.remove_member(owner)
	if(!silent)
		to_chat(current, span_userdanger("Your connection to the deity has been severed!"))
	return ..()

/datum/antagonist/hog_cultist/greet()
	to_chat(owner, span_userdanger("You are a follower of the [cult_team.team_colour] deity!"))
	owner.announce_objectives()

/datum/antagonist/hog_cultist/proc/set_team(team_colour)
	if(cult_team && cult_team.team_colour == team_colour)
		return
	if(cult_team)
		cult_team.remove_member(owner)
	cult_team = new /datum/team/hog()
	cult_team.team_colour = team_colour
	cult_team.add_member(owner)

/datum/antagonist/hog_cultist/prophet
	name = "Hand of God Prophet"

/datum/antagonist/hog_cultist/prophet/on_gain()
	. = ..()
	ADD_TRAIT(owner.current, TRAIT_HOG_PROPHET, TRAIT_HOG)
	add_hog_hud(owner.current, cult_team.team_colour, "prophet")

/datum/antagonist/hog_cultist/prophet/on_removal()
	REMOVE_TRAIT(owner.current, TRAIT_HOG_PROPHET, TRAIT_HOG)
	return ..()

/datum/antagonist/hog_cultist/prophet/greet()
	to_chat(owner, span_userdanger("You are the PROPHET of the [cult_team.team_colour] deity!"))

/datum/team/hog
	name = "Hand of God Cult"
	var/team_colour = HOG_TEAM_RED
	var/datum/mind/deity

/datum/team/hog/proc/setup_team()
	name = "[capitalize(team_colour)] Cult"

/datum/team/hog/proc/set_deity(datum/mind/new_deity)
	deity = new_deity

/datum/team/hog/add_member(datum/mind/new_member)
	. = ..()
	SEND_SIGNAL(src, COMSIG_HOG_FOLLOWER_GAINED, new_member, team_colour)

/datum/team/hog/remove_member(datum/mind/removed_member)
	. = ..()
	SEND_SIGNAL(src, COMSIG_HOG_FOLLOWER_LOST, removed_member, team_colour)

GLOBAL_LIST_EMPTY(hog_teams)

/datum/team/hog/New()
	. = ..()
	GLOB.hog_teams += src

/datum/team/hog/Destroy()
	GLOB.hog_teams -= src
	return ..()
