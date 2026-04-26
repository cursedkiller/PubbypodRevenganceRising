/datum/tgui/deity_structures
	tgui_id = "DeityStructures"

/datum/tgui/deity_structures/ui_data(mob/user)
	var/list/data = list()
	var/mob/living/simple_animal/god/deity = user

	data["faith"] = deity.faith
	data["max_faith"] = deity.max_faith
	data["team_colour"] = deity.team_colour

	var/list/structures = list()
	var/list/available = list(
		"Power Pylon" = list(/obj/structure/divine/powerpylon, "powerpylon-red", "Generates faith for your deity."),
		"Translocator" = list(/obj/structure/divine/translocator, "translocator-red", "Allows followers to teleport between translocators."),
		"Forge" = list(/obj/structure/divine/forge, "forge-red", "Creates divine equipment for followers."),
		"Sacrifice Altar" = list(/obj/structure/divine/sacrificealtar, "sacrificealtar-red", "Sacrifice beings for gems or faith."),
		"Conversion Altar" = list(/obj/structure/divine/convertaltar, "convertaltar-red", "Convert crew to your deity."),
		"Shrine" = list(/obj/structure/divine/shrine, "Shrine-red", "Boosts nearby followers."),
		"Fountain" = list(/obj/structure/divine/fountain, "fountain-red", "Heals nearby followers."),
		"Conduit" = list(/obj/structure/divine/conduit, "conduit-red", "Increases faith generation and extends domain."),
		"Lazarus" = list(/obj/structure/divine/lazarus, "lazarus-r", "Revives a fallen follower once."),
		"Defense Pylon" = list(/obj/structure/divine/defensepylon, "defensepylon-red", "Attacks non-believers automatically."),
	)

	for(var/name in available)
		var/list/info = available[name]
		structures += list(list(
			"name" = name,
			"path" = "[info[1]]",
			"icon" = info[2],
			"desc" = info[3],
			"cost" = HOG_FAITH_COST_STRUCTURE,
		))

	data["structures"] = structures
	return data

/datum/tgui/deity_structures/ui_act(action, params)
	. = ..()
	if(action == "build")
		var/mob/living/simple_animal/god/deity = usr
		if(!istype(deity))
			return
		if(!deity.god_nexus)
			to_chat(deity, span_warning("You must place your nexus first!"))
			return
		if(!deity.can_place_here(get_turf(deity)))
			to_chat(deity, span_warning("Your domain hasn't reached this area!"))
			return
		if(!deity.can_afford(HOG_FAITH_COST_STRUCTURE))
			return

		var/build_path = text2path(params["path"])
		if(!build_path)
			return

		if(build_path == /obj/structure/divine/defensepylon && !deity.free_pylon_used)
			deity.free_pylon_used = TRUE
			var/obj/structure/divine/defensepylon/P = new(get_turf(deity))
			P.assign_deity(deity)
			to_chat(deity, span_notice("You manifest a defense pylon! Future pylons will require construction."))
			. = TRUE
			return

		if(build_path == /obj/structure/divine/convertaltar && !deity.free_conversion_altar_used)
			deity.free_conversion_altar_used = TRUE
			var/obj/structure/divine/convertaltar/A = new(get_turf(deity))
			A.assign_deity(deity)
			to_chat(deity, span_notice("You manifest a conversion altar! Future altars will require construction."))
			. = TRUE
			return

		if(!deity.spend_faith(HOG_FAITH_COST_STRUCTURE))
			return
		var/obj/structure/divine/construction_holder/CH = new(get_turf(deity))
		CH.assign_deity(deity)
		CH.setup_construction(build_path)
		CH.visible_message(span_notice("A transparent, unfinished [initial(build_path.name)] appears!"))
		. = TRUE
		return

	if(action == "close")
		. = TRUE
		return
