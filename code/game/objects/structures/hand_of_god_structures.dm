/// Hand of God - Divine Structures
/// Structures placed by deities and built by followers

/obj/structure/divine
	name = "divine structure"
	desc = "A structure built by the followers of a deity."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	density = TRUE
	anchored = TRUE
	/// The deity that owns this structure
	var/mob/camera/god/deity = null
	/// Whether this is a trap (separate UI category)
	var/is_trap = FALSE
	/// Whether this is a construction holder
	var/is_construction_holder = FALSE

/obj/structure/divine/Initialize(mapload)
	. = ..()
	if(!mapload)
		build_hog_construction_lists()

/// Assign this structure to a deity
/obj/structure/divine/proc/assign_deity(mob/camera/god/G)
	deity = G
	if(G)
		LAZYADD(G.structures, src)

/obj/structure/divine/Destroy()
	if(deity)
		LAZYREMOVE(deity.structures, src)
		deity = null
	return ..()

/// Called when a follower attacks this structure with an item
/obj/structure/divine/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/lessergem))
		if(repair_structure(I, user))
			return
	return ..()

/// Attempt to repair the structure with gems
/obj/structure/divine/proc/repair_structure(obj/item/stack/sheet/lessergem/gems, mob/user)
	if(obj_integrity >= max_integrity)
		to_chat(user, span_warning("[src] is already at full integrity!"))
		return FALSE
	var/repair_amount = min(gems.amount * 50, max_integrity - obj_integrity)
	var/gems_used = ceil(repair_amount / 50)
	gems.use(gems_used)
	obj_integrity = min(obj_integrity + repair_amount, max_integrity)
	to_chat(user, span_notice("You repair [src] with [gems_used] lesser gems."))
	if(deity)
		deity.update_health_hud()
	return TRUE

/// The Nexus - the deity's anchor in the physical world
/obj/structure/divine/nexus
	name = "nexus"
	desc = "The anchor of a deity in this realm. Destroying it will banish the god."
	icon_state = "nexus"
	max_integrity = HOG_NEXUS_MAX_INTEGRITY

/obj/structure/divine/nexus/Destroy()
	if(deity)
		deity.god_nexus = null
		to_chat(deity, span_userdanger("Your nexus has been destroyed! You feel your connection to this realm fading..."))
		SEND_SIGNAL(src, COMSIG_HOG_NEXUS_DESTROYED, deity)
	return ..()

/obj/structure/divine/nexus/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/greatergem))
		var/obj/item/stack/sheet/greatergem/gems = I
		if(obj_integrity >= max_integrity)
			to_chat(user, span_warning("[src] is already at full integrity!"))
			return
		var/repair_amount = min(gems.amount * 200, max_integrity - obj_integrity)
		var/gems_used = ceil(repair_amount / 200)
		gems.use(gems_used)
		obj_integrity = min(obj_integrity + repair_amount, max_integrity)
		to_chat(user, span_notice("You repair [src] with [gems_used] greater gems."))
		if(deity)
			deity.update_health_hud()
		return
	return ..()

/// Defense Pylon - passively attacks non-believers
/obj/structure/divine/defensepylon
	name = "defense pylon"
	desc = "A defensive structure that attacks non-believers who come too close."
	icon_state = "pylon"
	max_integrity = 200
	is_trap = TRUE

/// Construction Holder - an unfinished structure that followers must complete
/obj/structure/divine/construction_holder
	name = "unfinished structure"
	desc = "An unfinished divine structure. Requires materials to complete."
	icon_state = "construction"
	density = FALSE
	max_integrity = 100
	is_construction_holder = TRUE
	/// The type of structure this will become when completed
	var/obj/structure/divine/build_type = null
	/// Gems required to complete
	var/gems_required = 2
	/// Gems currently inserted
	var/gems_inserted = 0

/obj/structure/divine/construction_holder/proc/setup_construction(obj/structure/divine/build_path)
	build_type = build_path
	name = "unfinished [initial(build_path.name)]"

/obj/structure/divine/construction_holder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/lessergem))
		var/obj/item/stack/sheet/lessergem/gems = I
		var/needed = gems_required - gems_inserted
		if(needed <= 0)
			to_chat(user, span_warning("[src] doesn't need any more gems!"))
			return
		var/to_use = min(gems.amount, needed)
		gems.use(to_use)
		gems_inserted += to_use
		to_chat(user, span_notice("You add [to_use] gems to [src]. ([gems_inserted]/[gems_required])"))
		if(gems_inserted >= gems_required)
			finish_construction()
		return
	return ..()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	visible_message(span_notice("[src] glows and transforms into \a [initial(build_type.name)]!"))
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
