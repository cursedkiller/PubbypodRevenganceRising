/// Hand of God objectives

/datum/objective/deicide
	name = "deicide"
	explanation_text = "Destroy the opposing deity."

/datum/objective/deicide/check_completion()
	if(!target)
		return FALSE
	if(!target.current)
		return TRUE
	return target.current.stat == DEAD

/datum/objective/deicide/find_target()
	var/datum/game_mode/mode = SSticker.mode
	if(!istype(mode))
		return
	var/list/candidates = list()
	if(owner in mode.red_deities)
		candidates = mode.blue_deities
	else if(owner in mode.blue_deities)
		candidates = mode.red_deities
	if(length(candidates))
		target = pick(candidates)
		update_explanation_text()

/datum/objective/deicide/update_explanation_text()
	if(target?.current)
		explanation_text = "Ensure [target.current.real_name], the opposing deity, is destroyed."
	else
		explanation_text = "The opposing deity has been eliminated."

/datum/objective/sacrifice_prophet
	name = "sacrifice prophet"
	explanation_text = "Have the opposing prophet sacrificed."

/datum/objective/sacrifice_prophet/check_completion()
	var/mob/camera/god/G = owner?.current
	if(!G)
		return FALSE
	return G.prophets_sacrificed_in_name > 0

/datum/objective/build_deity
	name = "build structures"
	explanation_text = "Have divine structures built."
	var/structures_target = 5

/datum/objective/build_deity/check_completion()
	var/mob/camera/god/G = owner?.current
	if(!G)
		return FALSE
	return length(G.structures) >= structures_target

/datum/objective/build_deity/find_target()
	structures_target = rand(4, 8)
	update_explanation_text()

/datum/objective/build_deity/update_explanation_text()
	explanation_text = "Ensure [structures_target] divine structures are built."

/datum/objective/follower_block
	name = "follower block"
	explanation_text = "Prevent the enemy from gaining too many followers."
	var/follower_max = 4

/datum/objective/follower_block/check_completion()
	var/datum/game_mode/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	var/enemy_count = 0
	if(owner in mode.red_deities)
		enemy_count = length(mode.blue_deity_followers) + length(mode.blue_deity_prophets)
	else
		enemy_count = length(mode.red_deity_followers) + length(mode.red_deity_prophets)
	return enemy_count <= follower_max

/datum/objective/escape_followers
	name = "follower escape"
	explanation_text = "Ensure followers escape on the shuttle."
	var/follower_escape_target = 5

/datum/objective/escape_followers/check_completion()
	return TRUE

/datum/objective/escape_followers/find_target()
	follower_escape_target = rand(3, 6)
	update_explanation_text()

/datum/objective/escape_followers/update_explanation_text()
	explanation_text = "Ensure at least [follower_escape_target] followers escape on the shuttle or pod."
