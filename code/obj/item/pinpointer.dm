/obj/item/pinpointer
	name = "pinpointer"
	icon = 'icons/obj/items/pinpointers.dmi'
	icon_state = "disk_pinoff"
	flags = FPRINT | TABLEPASS| CONDUCT | ONBELT
	w_class = W_CLASS_SMALL
	item_state = "electronic"
	throw_speed = 4
	throw_range = 20
	m_amt = 500
	var/atom/target = null
	/// target type to search for in world
	var/target_criteria = null
	/// exact target reference
	var/target_ref = null
	var/active = 0
	var/icon_type = "disk"
	mats = 4
	desc = "An extremely advanced scanning device used to locate things. It displays this with an extremely technicalogically advanced arrow."
	stamina_damage = 0
	stamina_cost = 0
	stamina_crit_chance = 1
	var/image/arrow = null

	New()
		..()
		arrow = image('icons/obj/items/pinpointers.dmi', icon_state = "")

	attack_self(mob/user)
		if(!active)
			if (!(src.target_criteria || src.target_ref || src.target))
				user.show_text("No target criteria specified, cannot activate the pinpointer.", "red")
				return
			active = 1
			work()
			boutput(user, "<span class='notice'>You activate the pinpointer</span>")
		else
			active = 0
			ClearSpecificOverlays("arrow")
			boutput(user, "<span class='notice'>You deactivate the pinpointer</span>")

	proc/work(mob/user)
		if(!active) return
		if(!target)
			if (target_ref)
				target = locate(target_ref)
			else if (target_criteria)
				target = locate(target_criteria)
			if(!target || target.qdeled)
				active = 0
				ClearSpecificOverlays("arrow")
				return
		var/turf/ST = get_turf(src)
		var/turf/T = get_turf(target)
		if(!ST || !T || ST.z != T.z)
			active = 0
			ClearSpecificOverlays("arrow")
			boutput(user, "<span class='alert'>Pinpointer target out of range.</span>")
			return
		src.set_dir(get_dir(src,target))
		switch(get_dist(src,target))
			if(0)
				arrow.icon_state = "pinondirect"
			if(1 to 8)
				arrow.icon_state = "pinonclose"
			if(9 to 16)
				arrow.icon_state = "pinonmedium"
			if(16 to INFINITY)
				arrow.icon_state = "pinonfar"
		UpdateOverlays(arrow, "arrow")
		SPAWN_DBG(0.5 SECONDS) .(user)

/obj/item/pinpointer/category
	var/category = null
	var/thing_name = "trackable object"
	var/in_or_on = "in"

	attack_self(mob/user)
		if(!active)
			if(isnull(category))
				user.show_text("No tracking category, cannot activate the pinpointer.", "red")
				return
			var/list/trackable = by_cat[category]
			if(!length(trackable))
				user.show_text("No [thing_name]s available, cannot activate the pinpointer.", "red")
				return
			var/list/choices = list()
			for(var/atom/A in trackable)
				if(A.disposed || isnull(get_turf(A)))
					continue
				var/in_loc = ""
				if(!isturf(A.loc))
					in_loc = " [in_or_on] [A.loc]"
				choices["[A][in_loc] in [get_area(A)]"] = A
			var/choice = tgui_input_list(user, "Pick a [thing_name] to track.", "[src]", choices)
			if(isnull(choice))
				return
			target = choices[choice]
		. = ..()

/obj/item/pinpointer/category/spysticker
	name = "spy sticker tracker"
	category = TR_CAT_SPY_STICKERS_REGULAR
	thing_name = "spy sticker"
	in_or_on = "on"

/obj/item/pinpointer/category/spysticker/det
	category = TR_CAT_SPY_STICKERS_DET

/obj/item/pinpointer/nuke
	name = "pinpointer (nuclear bomb)"
	desc = "Points in the direction of the nuclear bomb."
	icon_state = "nuke_pinoff"
	icon_type = "nuke"
	target_criteria = /obj/machinery/nuclearbomb

/obj/item/pinpointer/disk
	name = "pinpointer (authentication disk)"
	desc = "Points in the direction of the authentication disk."
	icon_state = "disk_pinoff"
	icon_type = "disk"
	target_criteria = /obj/item/disk/data/floppy/read_only/authentication

/obj/item/pinpointer/teg_semi
	name = "pinpointer (prototype semiconductor)"
	desc = "Points in the direction of the NT Prototype Semiconductor."
	icon_state = "semi_pinoff"
	icon_type = "semi"
	target_criteria = /obj/item/teg_semiconductor

/obj/item/pinpointer/trench
	name = "pinpointer (sea elevator)"
	desc = "Points in the direction of the sea elevator."
	icon_state = "trench_pinoff"
	icon_type = "trench"
	var/target_area = /area/shuttle/sea_elevator/lower

	attack_self(mob/user)
		if (!active)
			var/area/A = locate(target_area)
			var/turf/T = A.find_middle()
			var/turf/ST = get_turf(user)
			if (ST.z != T.z)
				boutput(user, "<span class='notice'>You must be in the trench to use this pinpointer.</span>")
				return
			target_ref = "\ref[A.find_middle()]"
		. = ..()

/obj/item/idtracker
	name = "ID tracker"
	icon = 'icons/obj/items/pinpointers.dmi'
	icon_state = "id_pinoff"
	flags = FPRINT | TABLEPASS| CONDUCT | ONBELT
	w_class = W_CLASS_SMALL
	item_state = "electronic"
	throw_speed = 4
	throw_range = 20
	m_amt = 500
	var/active = 0
	var/mob/owner = null
	var/list/targets = list()
	var/target = null
	is_syndicate = 1
	mats = 4
	desc = "This little bad-boy has been pre-programmed to display the general direction of any assassination target you choose."
	contraband = 3
	var/image/arrow = null

	New()
		..()
		arrow = image('icons/obj/items/pinpointers.dmi', icon_state = "")

	attack_self(mob/user)
		if(!active)
			if (!src.owner || !src.owner.mind)
				boutput(user, "<span class='alert'>The target locator emits a sorrowful ping!</span>")
				return
			active = 1
			for_by_tcl(I, /obj/item/card/id)
				if(!I)
					continue // the ID can get deleted in the lagcheck
				for(var/datum/objective/regular/assassinate/A in src.owner.mind.objectives)
					if(I.registered == null) continue
					if(ckey(I.registered) == ckey(A.targetname))
						targets[I] = I
				LAGCHECK(LAG_LOW)
			target = null
			target = input(user, "Which ID do you wish to track?", "Target Locator", null) in targets
			work()
			if(!target)
				boutput(user, "<span class='notice'>You activate the target locator. No available targets!</span>")
				active = 0
			else
				boutput(user, "<span class='notice'>You activate the target locator. Tracking [target]</span>")
		else
			active = 0
			arrow.icon_state = ""
			UpdateOverlays(arrow, "arrow")
			boutput(user, "<span class='notice'>You deactivate the target locator</span>")
			target = null

	proc/work()
		if(!active) return
		if(!target)
			arrow.icon_state = "pinonnull"
			UpdateOverlays(arrow, "arrow")
			return
		src.set_dir(get_dir(src,target))
		switch(get_dist(src,target))
			if(0)
				arrow.icon_state = "pinondirect"
			if(1 to 8)
				arrow.icon_state = "pinonclose"
			if(9 to 16)
				arrow.icon_state = "pinonmedium"
			if(16 to INFINITY)
				arrow.icon_state = "pinonfar"
		UpdateOverlays(arrow, "arrow")
		SPAWN_DBG(0.5 SECONDS) .()

/obj/item/idtracker/spy
	attack_hand(mob/user as mob)
		..(user)
		if (!user.mind || user.mind.special_role != ROLE_SPY_THIEF)
			boutput(user, "<span class='alert'>The target locator emits a sorrowful ping!</span>")

			//B LARGHHHHJHH
			active = 0
			arrow.icon_state = ""
			UpdateOverlays(arrow, "arrow")
			target = null
			return

	attack_self(mob/user)
		if(!active)
			if (!src.owner || !src.owner.mind || src.owner.mind.special_role != ROLE_SPY_THIEF)
				boutput(user, "<span class='alert'>The target locator emits a sorrowful ping!</span>")
				return
			active = 1

			for_by_tcl(I, /obj/item/card/id)
				if(I.registered == null) continue
				for (var/datum/mind/M in ticker.mode.traitors)
					if (src.owner.mind == M)
						continue
					if (ckey(I.registered) == ckey(M.current.real_name))
						targets[I] = I

			target = null
			target = input(user, "Which ID do you wish to track?", "Target Locator", null) in targets
			work()
			if(!target)
				boutput(user, "<span class='notice'>You activate the target locator. No available targets!</span>")
				active = 0
			else
				boutput(user, "<span class='notice'>You activate the target locator. Tracking [target]</span>")
		else
			active = 0
			arrow.icon_state = ""
			UpdateOverlays(arrow, "arrow")
			boutput(user, "<span class='notice'>You deactivate the target locator</span>")
			target = null

/obj/item/bloodtracker
	name = "BloodTrak"
	icon = 'icons/obj/items/pinpointers.dmi'
	icon_state = "blood_pinoff"
	flags = FPRINT | TABLEPASS| CONDUCT | ONBELT
	w_class = W_CLASS_SMALL
	item_state = "electronic"
	throw_speed = 4
	throw_range = 20
	m_amt = 500
	var/active = 0
	var/target = null
	mats = 4
	desc = "Tracks down people from their blood puddles!"
	var/blood_timer = 0
	var/image/arrow = null

	New()
		..()
		arrow = image('icons/obj/items/pinpointers.dmi', icon_state = "")

	afterattack(atom/A as mob|obj|turf|area, mob/user as mob)
		if(!active && istype(A, /obj/decal/cleanable/blood))
			var/obj/decal/cleanable/blood/B = A
			if(B.dry > 0) //Fresh blood is -1
				boutput(user, "<span class='alert'>Targeted blood is too dry to be useful!</span>")
				return
			for(var/mob/living/carbon/human/H in mobs)
				if(B.blood_DNA == H.bioHolder.Uid)
					target = H
					blood_timer = TIME + (B.dry==-1?8 MINUTES:4 MINUTES)
					break
			active = 1
			work()
			user.visible_message("<span class='notice'><b>[user]</b> scans [A] with [src]!</span>",\
			"<span class='notice'>You scan [A] with [src]!</span>")

	proc/work(var/turf/T, mob/user)
		if(!active) return
		if(!T)
			T = get_turf(src)
		if(TIME > blood_timer)
			arrow.icon_state = ""
			UpdateOverlays(arrow, "arrow")
			active = 0
			boutput(user, "<span class='alert'>[src] shuts down because the blood in it became too dry!</span>")
			return
		if(!target)
			arrow.icon_state = "pinonnull"
			UpdateOverlays(arrow, "arrow")
			active = 0
			boutput(user, "<span class='alert'>No target found!</span>")
			return
		src.set_dir(get_dir(src,target))
		switch(get_dist(src,target))
			if(0)
				arrow.icon_state = "pinondirect"
			if(1 to 8)
				arrow.icon_state = "pinonclose"
			if(9 to 16)
				arrow.icon_state = "pinonmedium"
			if(16 to INFINITY)
				arrow.icon_state = "pinonfar"
		UpdateOverlays(arrow, "arrow")
		SPAWN_DBG(0.5 SECONDS)
			.(T)



/obj/item/pinpointer/secweapons
	name = "security weapon pinpointer"
	icon_state = "sec_pinoff"
	icon_type = "sec"
	var/list/itemrefs
	var/list/accepted_types
	mats = null
	desc = "An extremely advanced scanning device used to locate lost security tools. It displays this with an extremely technicalogically advanced arrow."

	proc/track(var/list/L)
		itemrefs = list()
		accepted_types = list()
		for(var/atom/A in L)
			itemrefs += ref(A)
			accepted_types += A.type

	attack_self(mob/user)
		if(!active)

			var/list/choices = list()
			for (var/x in itemrefs)
				var/atom/A = locate(x)
				if (A && (A.type in accepted_types) && !A.qdeled && !A.disposed)
					choices += A

			if (!length(choices))
				user.show_text("No track targets exist - possibly destroyed. Cannot activate pinpointer", "red")
				return

			target = input("Select a card to deal.", "Choose Card") as null|anything in choices

			if (!target)
				user.show_text("No target specified. Cannot activate pinpointer.", "red")
				return

			active = 1
			work()
			boutput(user, "<span class='notice'>You activate the pinpointer</span>")
		else
			active = 0
			arrow.icon_state = ""
			UpdateOverlays(arrow, "arrow")
			boutput(user, "<span class='notice'>You deactivate the pinpointer</span>")


// gimmick pinpointers because I feel like adding them now that I made the by_cat pinpointer base version

/obj/item/pinpointer/category/pets
	name = "pet tracker"
	category = TR_CAT_PETS
	thing_name = "pet"

/obj/item/pinpointer/category/pwpets // pod wars
	name = "pet tracker"
	category = TR_CAT_PW_PETS
	thing_name = "pet"

/obj/item/pinpointer/category/critters
	name = "critter tracker"
	category = TR_CAT_CRITTERS
	thing_name = "critter"

/obj/item/pinpointer/category/pods
	name = "pod tracker"
	category = TR_CAT_PODS_AND_CRUISERS
	thing_name = "pod"

/obj/item/pinpointer/category/teleport_jammers
	name = "teleport jammer tracker"
	category = TR_CAT_TELEPORT_JAMMERS
	thing_name = "teleport jammer"

/obj/item/pinpointer/category/radio_jammers
	name = "radio jammer tracker"
	category = TR_CAT_RADIO_JAMMERS
	thing_name = "radio jammer"

/obj/item/pinpointer/category/burning_mobs
	name = "burning mob tracker"
	category = TR_CAT_BURNING_MOBS
	thing_name = "burning mob"

/obj/item/pinpointer/category/burning_items
	name = "burning item tracker"
	category = TR_CAT_BURNING_ITEMS
	thing_name = "burning item"

/obj/item/pinpointer/category/chaplains
	name = "chaplain tracker"
	category = TR_CAT_CHAPLAINS
	thing_name = "chaplain"
