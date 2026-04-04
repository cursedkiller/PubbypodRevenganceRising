/datum/reagent/blood
			data = list("donor"=null,"viruses"=null,"blood_DNA"=null,"blood_type"=null,"resistances"=null,"trace_chem"=null,"mind"=null,"ckey"=null,"gender"=null,"real_name"=null,"cloneable"=null,"factions"=null)
			name = "Blood"
			id = "blood"
			color = "#C80000" // rgb: 200, 0, 0

/datum/reagent/blood/reaction_mob(mob/M, method=TOUCH, reac_volume)
	if(data && data["viruses"])
		for(var/datum/disease/D in data["viruses"])

			if(D.spread_flags & SPECIAL || D.spread_flags & NON_CONTAGIOUS)
				continue

			if(method == TOUCH || method == VAPOR)
				M.ContractDisease(D)
			else //ingest, patch or inject
				M.ForceContractDisease(D)

/datum/reagent/blood/on_new(list/data)
	if(istype(data))
		SetViruses(src, data)

/datum/reagent/blood/on_merge(list/mix_data)
	if(data && mix_data)
		data["cloneable"] = 0 //On mix, consider the genetic sampling unviable for pod cloning, or else we won't know who's even getting cloned, etc
		if(data["viruses"] || mix_data["viruses"])

			var/list/mix1 = data["viruses"]
			var/list/mix2 = mix_data["viruses"]

			// Stop issues with the list changing during mixing.
			var/list/to_mix = list()

			for(var/datum/disease/advance/AD in mix1)
				to_mix += AD
			for(var/datum/disease/advance/AD in mix2)
				to_mix += AD

			var/datum/disease/advance/AD = Advance_Mix(to_mix)
			if(AD)
				var/list/preserve = list(AD)
				for(var/D in data["viruses"])
					if(!istype(D, /datum/disease/advance))
						preserve += D
				data["viruses"] = preserve
	return 1

/datum/reagent/blood/reaction_turf(turf/simulated/T, reac_volume)//splash the blood all over the place
	if(!istype(T))
		return
	if(reac_volume < 3)
		return
	if(!data["donor"] || istype(data["donor"], /mob/living/carbon/human))
		var/obj/effect/decal/cleanable/blood/blood_prop = locate() in T //find some blood here
		if(!blood_prop) //first blood!
			blood_prop = new(T)
			blood_prop.blood_DNA[data["blood_DNA"]] = data["blood_type"]

		for(var/datum/disease/D in data["viruses"])
			var/datum/disease/newVirus = D.Copy(1)
			blood_prop.viruses += newVirus
			newVirus.holder = blood_prop


	else if(istype(data["donor"], /mob/living/carbon/monkey))
		var/obj/effect/decal/cleanable/blood/blood_prop = locate() in T
		if(!blood_prop)
			blood_prop = new(T)
			blood_prop.blood_DNA["Non-Human DNA"] = "A+"
		for(var/datum/disease/D in data["viruses"])
			var/datum/disease/newVirus = D.Copy(1)
			blood_prop.viruses += newVirus
			newVirus.holder = blood_prop

	else if(istype(data["donor"], /mob/living/carbon/alien))
		var/obj/effect/decal/cleanable/xenoblood/blood_prop = locate() in T
		if(!blood_prop)
			blood_prop = new(T)
			blood_prop.blood_DNA["UNKNOWN DNA STRUCTURE"] = "X*"
		for(var/datum/disease/D in data["viruses"])
			var/datum/disease/newVirus = D.Copy(1)
			blood_prop.viruses += newVirus
			newVirus.holder = blood_prop
	return

/datum/reagent/liquidgibs
	name = "Liquid gibs"
	id = "liquidgibs"
	color = "#FF9966"
	description = "You don't even want to think about what's in here."

/datum/reagent/vaccine
	//data must contain virus type
	name = "Vaccine"
	id = "vaccine"
	color = "#C81040" // rgb: 200, 16, 64

/datum/reagent/vaccine/reaction_mob(mob/M, method=TOUCH, reac_volume)
	if(islist(data) && (method == INGEST || method == INJECT))
		for(var/datum/disease/D in M.viruses)
			if(D.GetDiseaseID() in data)
				D.cure()
		M.resistances |= data

/datum/reagent/vaccine/on_merge(list/data)
	if(istype(data))
		src.data |= data.Copy()

/datum/reagent/water
	name = "Water"
	id = "water"
	description = "A ubiquitous chemical substance that is composed of hydrogen and oxygen."
	color = "#AAAAAA77" // rgb: 170, 170, 170, 77 (alpha)
	var/cooling_temperature = 2

/*
 *	Water reaction to turf
 */

/datum/reagent/water/reaction_turf(turf/simulated/T, reac_volume)
	if (!istype(T)) return
	var/CT = cooling_temperature
	if(reac_volume >= 10)
		T.MakeSlippery()

	for(var/mob/living/simple_animal/slime/M in T)
		M.apply_water()

	var/obj/effect/hotspot/hotspot = (locate(/obj/effect/hotspot) in T)
	if(hotspot && !istype(T, /turf/space))
		if(T.air)
			var/datum/gas_mixture/G = T.air
			G.temperature = max(min(G.temperature-(CT*1000),G.temperature/CT),0)
			G.react()
			qdel(hotspot)
	return

/*
 *	Water reaction to an object
 */

/datum/reagent/water/reaction_obj(obj/O, reac_volume)
	if(istype(O,/obj/item))
		var/obj/item/Item = O
		Item.extinguish()

	// Monkey cube
	if(istype(O,/obj/item/weapon/reagent_containers/food/snacks/monkeycube))
		var/obj/item/weapon/reagent_containers/food/snacks/monkeycube/cube = O
		if(!cube.wrapped)
			cube.Expand()

	// Dehydrated carp
	else if(istype(O,/obj/item/toy/carpplushie/dehy_carp))
		var/obj/item/toy/carpplushie/dehy_carp/dehy = O
		dehy.Swell() // Makes a carp

	return

/*
 *	Water reaction to a mob
 */

/datum/reagent/water/reaction_mob(mob/living/M, method=TOUCH, reac_volume)//Splashing people with water can help put them out!
	if(!istype(M, /mob/living))
		return
	if(method == TOUCH)
		M.adjust_fire_stacks(-(reac_volume / 10))
	..()

/datum/reagent/water/holywater
	name = "Holy Water"
	id = "holywater"
	description = "Water blessed by some deity."
	color = "#E0E8EF" // rgb: 224, 232, 239

/datum/reagent/water/holywater/on_mob_life(mob/living/M)
	if(!data) data = 1
	data++
	M.jitteriness = max(M.jitteriness-5,0)
	if(data >= 30)		// 12 units, 54 seconds @ metabolism 0.4 units & tick rate 1.8 sec
		if (!M.stuttering) M.stuttering = 1
		M.stuttering += 4
		M.Dizzy(5)
		if(iscultist(M) && prob(5))
			M.say(pick("Av'te Nar'sie","Pa'lid Mors","INO INO ORA ANA","SAT ANA!","Daim'niodeis Arc'iai Le'eones","Egkau'haom'nai en Chaous","Ho Diak'nos tou Ap'iron","R'ge Na'sie","Diabo us Vo'iscum","Si gn'um Co'nu"))
	if(data >= 75 && prob(33))	// 30 units, 135 seconds
		if (!M.confused) M.confused = 1
		M.confused += 3




		if(iscultist(M) || (is_handofgod_cultist(M) && !is_handofgod_prophet(M)))
			ticker.mode.remove_cultist(M.mind)
			ticker.mode.remove_hog_follower(M.mind)
			holder.remove_reagent(src.id, src.volume)	// maybe this is a little too perfect and a max() cap on the statuses would be better??
			M.jitteriness = 0
			M.stuttering = 0
			M.confused = 0
			return
	holder.remove_reagent(src.id, 0.4)	//fixed consumption to prevent balancing going out of whack
	return
