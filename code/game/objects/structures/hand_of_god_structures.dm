/obj/structure/divine
	name = "divine structure"
	desc = "A structure built by the followers of a deity."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	density = TRUE
	anchored = TRUE
	max_integrity = 200
	var/mob/camera/god/deity = null
	var/is_trap = FALSE
	var/is_construction_holder = FALSE

/obj/structure/divine/proc/assign_deity(mob/camera/god/G)
	deity = G
	if(G)
		LAZYADD(G.structures, src)
		update_icon()

/obj/structure/divine/Destroy()
	if(deity)
		LAZYREMOVE(deity.structures, src)
		deity = null
	return ..()

/obj/structure/divine/update_icon()
	if(!deity)
		return
	icon_state = "[initial(icon_state)]-[deity.team_colour]"

/obj/structure/divine/nexus
	name = "nexus"
	desc = "The anchor of a deity in this realm."
	icon_state = "nexus"
	max_integrity = HOG_NEXUS_MAX_INTEGRITY

/obj/structure/divine/nexus/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)

/obj/structure/divine/nexus/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(deity)
		deity.god_nexus = null
		to_chat(deity, span_userdanger("Your nexus has been destroyed!"))
		SEND_SIGNAL(src, COMSIG_HOG_NEXUS_DESTROYED, deity)
		deity.refresh_followers()
		deity.check_death()
	return ..()

/obj/structure/divine/nexus/process(delta_time)
	if(obj_integrity < max_integrity)
		obj_integrity = min(obj_integrity + 2, max_integrity)
		if(deity)
			deity.update_nexus_health_hud()

/obj/structure/divine/defensepylon
	name = "defense pylon"
	desc = "A defensive structure that attacks non-believers."
	icon_state = "defensepylon"
	max_integrity = 200

/obj/structure/divine/powerpylon
	name = "power pylon"
	desc = "Generates faith for your deity."
	icon_state = "powerpylon"
	max_integrity = 150

/obj/structure/divine/translocator
	name = "translocator"
	desc = "Allows followers to teleport between translocators."
	icon_state = "translocator"
	max_integrity = 200

/obj/structure/divine/forge
	name = "forge"
	desc = "Creates divine equipment for followers."
	icon_state = "forge"
	max_integrity = 300

/obj/structure/divine/sacrificealtar
	name = "sacrifice altar"
	desc = "Used for blood sacrifice to gain gems."
	icon_state = "sacrificealtar"
	max_integrity = 250

/obj/structure/divine/convertaltar
	name = "conversion altar"
	desc = "Used to convert crew members to your deity."
	icon_state = "convertaltar"
	max_integrity = 250

/obj/structure/divine/shrine
	name = "shrine"
	desc = "A holy shrine that boosts nearby followers."
	icon_state = "Shrine"
	max_integrity = 150

/obj/structure/divine/ward
	name = "ward"
	desc = "A protective ward that damages non-believers nearby."
	icon_state = "ward"
	max_integrity = 100
	is_trap = TRUE

/obj/structure/divine/fountain
	name = "fountain"
	desc = "A blessed fountain that heals nearby followers."
	icon_state = "fountain"
	max_integrity = 200

/obj/structure/divine/conduit
	name = "conduit"
	desc = "Channels divine energy, increasing faith generation."
	icon_state = "conduit"
	max_integrity = 150

/obj/structure/divine/lazarus
	name = "lazarus"
	desc = "Can revive a fallen follower once."
	icon_state = "lazarus"
	max_integrity = 100

/obj/structure/divine/construction_holder
	name = "unfinished structure"
	desc = "An unfinished divine structure. Requires iron, glass, or iron rods to complete."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	icon_state = "construction"
	density = FALSE
	max_integrity = 100
	is_construction_holder = TRUE
	var/obj/structure/divine/build_type = null
	var/materials_required = 10
	var/materials_inserted = 0

/obj/structure/divine/construction_holder/proc/setup_construction(obj/structure/divine/build_path)
	build_type = build_path
	name = "unfinished [initial(build_path.name)]"

/obj/structure/divine/construction_holder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/iron))
		var/obj/item/stack/sheet/iron/S = I
		add_material(S, user)
		return
	if(istype(I, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/G = I
		add_material(G, user)
		return
	if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = I
		add_material(R, user)
		return
	return ..()

/obj/structure/divine/construction_holder/proc/add_material(obj/item/stack/S, mob/user)
	var/needed = materials_required - materials_inserted
	if(needed <= 0)
		to_chat(user, span_warning("It doesn't need more materials!"))
		return
	var/to_use = min(S.amount, needed)
	S.use(to_use)
	materials_inserted += to_use
	to_chat(user, span_notice("You add [to_use] [S.name]. ([materials_inserted]/[materials_required])"))
	if(materials_inserted >= materials_required)
		finish_construction()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	visible_message(span_notice("[src] transforms into \a [initial(build_type.name)]!"))
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
