/// Hand of God divine structures

/obj/structure/divine
	name = "divine structure"
	desc = "A structure built by the followers of a deity."
	icon = 'icons/obj/hand_of_god_structures.dmi'
	density = TRUE
	anchored = TRUE
	var/mob/camera/god/deity = null

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
	desc = "The anchor of a deity in this realm. Destroying it will banish the god."
	icon_state = "nexus"
	max_integrity = 500

/obj/structure/divine/nexus/Destroy()
	if(deity)
		deity.god_nexus = null
		to_chat(deity, "<span class='userdanger'>Your nexus has been destroyed!</span>")
	return ..()

/obj/structure/divine/defensepylon
	name = "defense pylon"
	desc = "A defensive structure that attacks non-believers."
	icon_state = "pylon"

/obj/structure/divine/construction_holder
	name = "unfinished structure"
	desc = "An unfinished divine structure. Requires materials to complete."
	icon_state = "construction"
	var/obj/structure/divine/build_type = null

/obj/structure/divine/construction_holder/proc/setup_construction(obj/structure/divine/type)
	build_type = type

/obj/structure/divine/construction_holder/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/stack/sheet/lessergem))
		var/obj/item/stack/sheet/lessergem/G = I
		if(G.amount >= 2)
			G.use(2)
			finish_construction()
			return
	return ..()

/obj/structure/divine/construction_holder/proc/finish_construction()
	if(!build_type)
		return
	var/obj/structure/divine/S = new build_type(get_turf(src))
	S.assign_deity(deity)
	qdel(src)
