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

/obj/structure/divine/Destroy()
	if(deity)
		LAZYREMOVE(deity.structures, src)
		deity = null
	return ..()

/obj/structure/divine/nexus
	name = "nexus"
	desc = "The anchor of a deity in this realm."
	icon_state = "nexus"
	max_integrity = HOG_NEXUS_MAX_INTEGRITY

/obj/structure/divine/nexus/Destroy()
	if(deity)
		deity.god_nexus = null
		to_chat(deity, span_userdanger("Your nexus has been destroyed!"))
		SEND_SIGNAL(src, COMSIG_HOG_NEXUS_DESTROYED, deity)
	return ..()

/obj/structure/divine/defensepylon
	name = "defense pylon"
	desc = "A defensive structure."
	icon_state = "pylon"
	max_integrity = 200
	is_trap = TRUE

/obj/structure/divine/construction_holder
	name = "unfinished structure"
	desc = "An unfinished divine structure. Requires gems to complete."
	icon_state = "construction"
	density = FALSE
	max_integrity = 100
	is_construction_holder = TRUE
	var/obj/structure/divine/build_type = null
	var/gems_required = 2
	var/gems_inserted = 0

/obj/structure/divine/construction_holder/proc/setup_construction(obj/structure/divine/build_path)
	build_type = build_path
	name = "unfinished [initial(build_path.name)]"

/obj/structure/divine/construction_holder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/lessergem))
		var/obj/item/stack/sheet/lessergem/gems = I
		var/needed = gems_required - gems_inserted
		if(needed <= 0)
			to_chat(user, span_warning("It doesn't need more gems!"))
			return
		var/to_use = min(gems.amount, needed)
		gems.use(to_use)
		gems_inserted += to_use
		to_chat(user, span_notice("You add [to_use] gems. ([gems_inserted]/[gems_required])"))
		if(gems_inserted >= gems_required)
			finish_construction()
		return
	return ..()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	visible_message(span_notice("[src] transforms!"))
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
