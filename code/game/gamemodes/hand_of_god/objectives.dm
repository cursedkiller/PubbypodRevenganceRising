/// Hand of God custom objectives

/datum/objective/deicide
	name = "deicide"
	explanation_text = "Kill the opposing deity."
	var/target_role = "Deity"

/datum/objective/deicide/check_completion()
	if(!target)
		return FALSE
	if(!target.current)
		return TRUE // They're gone
	return target.current.stat == DEAD

/datum/objective/deicide/find_target()
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
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
	explanation_text = "Have your followers sacrifice the opposing prophet."

/datum/objective/sacrifice_prophet/check_completion()
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	
	var/mob/camera/god/G = owner?.current
	if(!G)
		return FALSE
	
	return G.prophets_sacrificed_in_name > 0

/datum/objective/build
	name = "build structures"
	explanation_text = "Have your followers build divine structures."
	var/target_amount = 5

/datum/objective/build/check_completion()
	var/mob/camera/god/G = owner?.current
	if(!G)
		return FALSE
	
	return length(G.structures) >= target_amount

/datum/objective/build/find_target()
	target_amount = rand(4, 8)
	update_explanation_text()

/datum/objective/build/update_explanation_text()
	explanation_text = "Ensure [target_amount] divine structures are built."

/datum/objective/follower_block
	name = "follower block"
	explanation_text = "Prevent the enemy from gaining too many followers."
	var/max_enemy_followers = 4

/datum/objective/follower_block/check_completion()
	var/datum/game_mode/hand_of_god/mode = SSticker.mode
	if(!istype(mode))
		return FALSE
	
	var/enemy_count = 0
	if(owner in mode.red_deities)
		enemy_count = length(mode.blue_deity_followers) + length(mode.blue_deity_prophets)
	else
		enemy_count = length(mode.red_deity_followers) + length(mode.red_deity_prophets)
	
	return enemy_count <= max_enemy_followers

/datum/objective/escape_followers
	name = "follower escape"
	explanation_text = "Ensure your followers escape on the shuttle."
	var/target_amount = 5

/datum/objective/escape_followers/check_completion()
	// This is checked during round end
	return TRUE // Placeholder - actual logic goes in shuttle code

/datum/objective/escape_followers/find_target()
	target_amount = rand(3, 6)
	update_explanation_text()

/datum/objective/escape_followers/update_explanation_text()
	explanation_text = "Ensure at least [target_amount] of your followers escape on the shuttle or pod."
