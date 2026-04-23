/// Hand of God crafting materials
/// Gems obtained through blood sacrifice, used to build divine structures

/obj/item/stack/sheet/lessergem
	name = "lesser gems"
	desc = "Rare gems gained through blood sacrifice to minor deities. Used in crafting divine objects."
	singular_name = "lesser gem"
	icon_state = "sheet-lessergem"
	merge_type = /obj/item/stack/sheet/lessergem
	materials = list(MAT_DIAMOND = 500)

/obj/item/stack/sheet/greatergem
	name = "greater gems"
	desc = "Powerful gems gained through blood sacrifice to greater deities. Required for powerful divine structures."
	singular_name = "greater gem"
	icon_state = "sheet-greatergem"
	merge_type = /obj/item/stack/sheet/greatergem
	materials = list(MAT_DIAMOND = 2000)

/obj/item/stack/sheet/lessergem/ten
	amount = 10

/obj/item/stack/sheet/greatergem/five
	amount = 5
