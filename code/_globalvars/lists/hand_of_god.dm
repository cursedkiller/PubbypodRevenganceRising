/// Global lists for Hand of God structures and traps
/// Populated during initialization

GLOBAL_LIST_INIT(global_handofgod_traptypes, list())
GLOBAL_LIST_INIT(global_handofgod_structuretypes, list())

/// Populates the global structure and trap type lists
/proc/build_hog_construction_lists()
	// Structure types available to deities
	for(var/path in subtypesof(/obj/structure/divine))
		var/obj/structure/divive/D = path
		if(initial(D.is_trap))
			GLOB.global_handofgod_traptypes[initial(D.name)] = path
		else if(!initial(D.is_construction_holder))
			GLOB.global_handofgod_structuretypes[initial(D.name)] = path
