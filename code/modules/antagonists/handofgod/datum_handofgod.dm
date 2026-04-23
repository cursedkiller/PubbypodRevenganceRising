/// Hand of God - Deity Antagonist Datum
/// The god player who oversees their cult

/datum/antagonist/hog_god
	name = "Hand of God"
	roundend_category = "hand of god"
	antagpanel_category = "Hand of God"
	show_in_antagpanel = FALSE // The god uses a custom camera mob, not shown in panel normally
	banning_key = ROLE_HOG_GOD
	required_living_playtime = 6
	/// The team this god belongs to
	var/datum/team/hog/cult_team

/datum/antagonist/hog_god/get_team()
	return cult_team

/datum/antagonist/hog_god/create_team(datum/team/hog/new_team)
	if(!new_team)
		// Find existing team or create new one
		for(var/datum/antagonist/hog_god/existing in GLOB.antagonists)
			if(!existing.owner)
				continue
			if(existing.cult_team)
				cult_team = existing.cult_team
				return
		cult_team = new /datum/team/hog()
		cult_team.setup_team()
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	cult_team = new_team

/datum/antagonist/hog_god/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	cult_team.add_member(owner)
	cult_team.set_deity(owner)
	add_hog_hud(current, cult_team.team_colour, "god")
	current.log_message("has become a Hand of God deity!", LOG_ATTACK, color="#960000")

/datum/antagonist/hog_god/on_removal()
	remove_hog_hud(owner.current, cult_team.team_colour)
	if(cult_team)
		cult_team.remove_member(owner)
		cult_team.deity = null
	return ..()

/datum/antagonist/hog_god/greet()
	to_chat(owner, span_userdanger("You are a deity! You are worshipped by a cult!"))
	to_chat(owner, "You are a divine being overseeing your followers. Place your Nexus to anchor yourself to this realm.")
	owner.announce_objectives()

/datum/antagonist/hog_god/admin_add(datum/mind/new_owner, mob/admin)
	var/mob/living/carbon/human/H = new_owner.current
	if(!istype(H))
		to_chat(admin, span_warning("This only works on humans."))
		return
	new_owner.make_Handofgod_god(HOG_TEAM_RED)
	message_admins("[key_name_admin(admin)] has made [key_name_admin(new_owner)] a Hand of God deity.")
	log_admin("[key_name(admin)] has made [key_name(new_owner)] a Hand of God deity.")

/// Hand of God - Cultist Antagonist Datum
/// Followers and prophets of the deity

/datum/antagonist/hog_cultist
	name = "Hand of God Cultist"
	roundend_category = "hand of god cultists"
	antagpanel_category = "Hand of God"
	banning_key = ROLE_HOG_CULTIST
	required_living_playtime = 4
	/// The team this cultist belongs to
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
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	cult_team = new_team

/datum/antagonist/hog_cultist/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	current.faction |= (cult_team.team_colour == HOG_TEAM_RED ? FACTION_RED_GOD : FACTION_BLUE_GOD)
	ADD_TRAIT(current, TRAIT_HOG_CULTIST, TRAIT_HOG)
	cult_team.add_member(owner)
	add_hog_hud(current, cult_team.team_colour, "follower")
	current.log_message("has joined the [cult_team.team_colour] cult!", LOG_ATTACK, color="#960000")

/datum/antagonist/hog_cultist/on_removal()
	var/mob/living/current = owner.current
	current.faction -= FACTION_RED_GOD
	current.faction -= FACTION_BLUE_GOD
	REMOVE_TRAIT(current, TRAIT_HOG_CULTIST, TRAIT_HOG)
	remove_hog_hud(current, cult_team.team_colour)
	if(cult_team)
		cult_team.remove_member(owner)
	if(!silent)
		to_chat(current, span_userdanger("Your connection to the [cult_team.team_colour] deity has been severed!"))
		current.log_message("has renounced the [cult_team.team_colour] cult!", LOG_ATTACK, color="#960000")
	return ..()

/datum/antagonist/hog_cultist/greet()
	to_chat(owner, span_userdanger("You are a follower of the [cult_team.team_colour] deity!"))
	to_chat(owner, "Serve your deity well. Convert others to your cause and help complete your god's objectives.")
	owner.announce_objectives()

/datum/antagonist/hog_cultist/proc/set_team(team_colour)
	if(cult_team && cult_team.team_colour == team_colour)
		return
	if(cult_team)
		cult_team.remove_member(owner)
	cult_team = new /datum/team/hog()
	cult_team.team_colour = team_colour
	cult_team.add_member(owner)

/// Prophet sub-type - has additional abilities and communication with the deity
/datum/antagonist/hog_cultist/prophet
	name = "Hand of God Prophet"

/datum/antagonist/hog_cultist/prophet/on_gain()
	. = ..()
	var/mob/living/current = owner.current
	ADD_TRAIT(current, TRAIT_HOG_PROPHET, TRAIT_HOG)
	add_hog_hud(current, cult_team.team_colour, "prophet")

/datum/antagonist/hog_cultist/prophet/on_removal()
	var/mob/living/current = owner.current
	REMOVE_TRAIT(current, TRAIT_HOG_PROPHET, TRAIT_HOG)
	return ..()

/datum/antagonist/hog_cultist/prophet/greet()
	to_chat(owner, span_userdanger("You are the PROPHET of the [cult_team.team_colour] deity!"))
	to_chat(owner, "You alone can hear your god's voice and lead the cult to victory.")

/// Hand of God - Team Datum
/// Manages the team of followers for one deity

/datum/team/hog
	name = "Hand of God Cult"
	/// "red" or "blue"
	var/team_colour = HOG_TEAM_RED
	/// The deity leading this team
	var/datum/mind/deity

/datum/team/hog/proc/setup_team()
	name = "[capitalize(team_colour)] Cult"
	generate_objectives()

/datum/team/hog/proc/set_deity(datum/mind/new_deity)
	deity = new_deity

/datum/team/hog/add_member(datum/mind/new_member)
	. = ..()
	SEND_SIGNAL(src, COMSIG_HOG_FOLLOWER_GAINED, new_member, team_colour)

/datum/team/hog/remove_member(datum/mind/removed_member)
	. = ..()
	SEND_SIGNAL(src, COMSIG_HOG_FOLLOWER_LOST, removed_member, team_colour)

/// Generate objectives for this deity
/datum/team/hog/proc/generate_objectives()
	var/list/objective_types = list(
		/datum/objective/deicide,
		/datum/objective/sacrifice_prophet,
		/datum/objective/build_deity,
		/datum/objective/follower_block,
		/datum/objective/escape_followers,
	)

	var/num_objectives = pick(1, 1, 2, 2)
	for(var/i in 1 to num_objectives)
		var/obj_type = pick(objective_types)
		var/datum/objective/O = new obj_type
		O.owner = deity
		O.find_target()
		objectives += O
		if(deity)
			deity.objectives += O
		log_game("[key_name(deity)] has been given Hand of God objective: [O.explanation_text]")

/datum/team/hog/roundend_report()
	var/list/parts = list()

	parts += span_header("[capitalize(team_colour)] Cult:")

	if(deity)
		parts += "<b>Deity:</b> [deity.name] ([deity.key]) - "
		if(deity.current && deity.current.stat != DEAD)
			parts += span_greentext("Survived")
		else
			parts += span_redtext("Destroyed")
	else
		parts += span_redtext("No deity!")

	parts += "<b>Followers:</b> [length(members)]"
	for(var/datum/mind/member in members)
		parts += "    [member.name] ([member.key])"

	if(length(objectives))
		parts += "<b>Objectives:</b>"
		var/count = 1
		for(var/datum/objective/objective in objectives)
			parts += "<b>Objective #[count]</b>: [objective.get_completion_message()]"
			count++

	return "<div class='panel redborder'>[parts.Join("<br>")]</div>"

/// Global list of all HoG teams for roundend reporting
GLOBAL_LIST_EMPTY(hog_teams)

/datum/team/hog/New()
	. = ..()
	GLOB.hog_teams += src

/datum/team/hog/Destroy()
	GLOB.hog_teams -= src
	return ..()
