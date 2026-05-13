/*
 * Revolver
 */
/obj/item/weapon/gun/projectile/revolver
	name = "revolver"
	desc = "The MarsTech HE Colt is a choice revolver for when you absolutely, positively need to put a hole in the other guy. Uses .357 rounds."
	description_fluff = "MarsTech first made their name in the Second Cold War as the 'Lunar Arms Company' providing home-grown arms to the Selene Federation, \
	but after the formation of the SCG rebranded and relocated to Mars where they remain based to this day. \
	The company was acquired by Hephaestus in the mid 23rd century, and its branding used to present an image of historical prestige and Solar unity for their latest product line. \
	MarsTech operates production facilities out of many of the SCG’s larger colonies."
	icon_state = "revolver"
	item_state = "revolver"
	caliber = ".357"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	max_shells = 6
	ammo_type = /obj/item/ammo_casing/a357
	projectile_type = /obj/item/projectile/bullet/pistol/strong
	var/chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round

/obj/item/weapon/gun/projectile/revolver/verb/spin_cylinder()
	set name = "Spin cylinder"
	set desc = "Fun when you're bored out of your skull."
	set category = "Object"

	chamber_offset = 0
	visible_message("<span class='warning'>\The [usr] spins the cylinder of \the [src]!</span>", \
	"<span class='notice'>You hear something metallic spin and click.</span>")
	playsound(src, 'sound/weapons/revolver_spin.ogg', 100, 1)
	loaded = shuffle(loaded)
	if(rand(1,max_shells) > loaded.len)
		chamber_offset = rand(0,max_shells - loaded.len)

/obj/item/weapon/gun/projectile/revolver/consume_next_projectile()
	if(chamber_offset)
		chamber_offset--
		return
	return ..()

/obj/item/weapon/gun/projectile/revolver/load_ammo(var/obj/item/A, mob/user)
	chamber_offset = 0
	return ..()

/obj/item/weapon/gun/projectile/revolver/stainless
	icon_state = "revolver_stainless"

/*
 * Detective Revolver
 */
/obj/item/weapon/gun/projectile/revolver/detective
	name = "revolver"
	desc = "A standard MarsTech R1 snubnose revolver, popular among some law enforcement agencies for its simple, long-lasting construction. Uses .38-Special rounds."
	description_fluff = "The leading civilian-sector high-quality small arms brand of Hephaestus Industries, MarsTech has been the provider of choice for law enforcement and security forces for over 300 years."
	icon_state = "detective"
	caliber = ".38"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a38

/obj/item/weapon/gun/projectile/revolver/detective/verb/rename_gun()
	set name = "Name Gun"
	set category = "Object"
	set desc = "Click to rename your gun. If you're the detective."

	var/mob/M = usr
	if(!M.mind)	return 0
	if(!M.mind.assigned_role == "Detective")
		to_chat(M, "<span class='notice'>You don't feel cool enough to name this gun, chump.</span>")
		return 0

	var/input = sanitizeSafe(input(usr, "What do you want to name the gun?", ,""), MAX_NAME_LEN)

	if(src && input && !M.stat && in_range(M,src))
		name = input
		to_chat(M, "You name the gun [input]. Say hello to your new friend.")
		return 1

/obj/item/weapon/gun/projectile/revolver/detective45
	name = ".45 revolver"
	desc = "A basic revolver, popular among some law enforcement agencies for its simple, long-lasting construction, modified for .45 rounds and a seven-shot cylinder."
	icon_state = "detective"
	caliber = ".45"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a45/rubber
	max_shells = 6

/obj/item/weapon/gun/projectile/revolver/detective45/verb/rename_gun()
	set name = "Name Gun"
	set category = "Object"
	set desc = "Rename your gun. If you're the Detective."

	var/mob/M = usr
	if(!M.mind)	return 0
	var/job = M.mind.assigned_role
	if(job != "Detective")
		to_chat(M, "<span class='notice'>You don't feel cool enough to name this gun, chump.</span>")
		return 0

	var/input = sanitizeSafe(input(usr, "What do you want to name the gun?", ,""), MAX_NAME_LEN)

	if(src && input && !M.stat && in_range(M,src))
		name = input
		to_chat(M, "You name the gun [input]. Say hello to your new friend.")
		return 1

/obj/item/weapon/gun/projectile/revolver/detective45/verb/reskin_gun()
	set name = "Resprite gun"
	set category = "Object"
	set desc = "Click to choose a sprite for your gun."

	var/mob/M = usr
	var/list/options = list()
	options["MarsTech R1 Snubnose"] = "detective"
	options["MarsTech R1 Snubnose (Blued)"] = "detective_blued"
	options["MarsTech R1 Snubnose (Stainless)"] = "detective_stainless"
	options["MarsTech R1 Snubnose (Gold)"] = "detective_stainless"
	options["MarsTech R1 Snubnose (Leopard)"] = "detective_leopard"
	options["MarsTech Frontiersman Classic"] = "detective_peacemaker"
	options["MarsTech Frontiersman Shadow"] = "detective_peacemaker_dark"
	options["Jindal Duke"] = "detective_fitz"
	options["H-H M1895"] = "nagant"
	var/choice = tgui_input_list(M,"Choose your sprite!","Resprite Gun", options)
	if(src && choice && !M.stat && in_range(M,src))
		icon_state = options[choice]
		to_chat(M, "Your gun is now sprited as [choice]. Say hello to your new friend.")
		return 1

/*
 * Lombardi Revolvers
 * 		Use to be detective revolvers until seperated
 */
/obj/item/weapon/gun/projectile/revolver/lombardi
	name = "Lombardi Buzzard"
	desc = "A rugged revolver that is mostly used by small law enforcement agencies across the frontier as a cheap, reliable sidearm. Uses .357 rounds."
	icon_state = "lombardi_police"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)

/obj/item/weapon/gun/projectile/revolver/lombardi/panther
	name = "Lombardi Panther"
	icon_state = "lombardi_panther"

/obj/item/weapon/gun/projectile/revolver/lombardi/gold
	name = "Lombardi Deluxe 2502"
	desc = "A sweet looking revolver that is decorated with false gold and silver plating. Favored among by gamblers and criminals alike. Uses .357 rounds."
	icon_state = "lombardi_gold"

/*
 * Captain's Peacekeeper
 */
/obj/item/weapon/gun/projectile/revolver/cappeacekeeper
	name = "decorated peacekeeper"
	desc = "A MarsTech Frontiersman revolver that has been heavily modified. It has been decorated for personal use by command officers. Uses .44 rounds."
	description_fluff = "The leading civilian-sector high-quality small arms brand of Hephaestus Industries, \
	MarsTech has been the provider of choice for law enforcement and security forces for over 300 years."
	icon_state = "captains_peacemaker"
	caliber = ".44"
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a44

/*
 * Mateba
 */
/obj/item/weapon/gun/projectile/revolver/mateba
	name = "mateba"
	desc = "This unique looking handgun is named after an Italian company famous for the original manufacture of \
	these revolvers, and pasta kneading machines. Uses .357 rounds." // Yes I'm serious. -Spades
	icon_state = "mateba"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)

/*
 * Deckard (Blade Runner)
 */
/obj/item/weapon/gun/projectile/revolver/deckard
	name = "\improper \"Deckard\" .38"
	desc = "A custom-built revolver, based off the semi-popular Detective Special model. Uses .38-Special rounds."
	icon_state = "deckard-empty"
	caliber = ".38"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	ammo_type = /obj/item/ammo_casing/a38

/obj/item/weapon/gun/projectile/revolver/deckard/emp
	ammo_type = /obj/item/ammo_casing/a38/emp


/obj/item/weapon/gun/projectile/revolver/deckard/update_icon()
	..()
	if(loaded.len)
		icon_state = "deckard-loaded"
	else
		icon_state = "deckard-empty"

/obj/item/weapon/gun/projectile/revolver/deckard/load_ammo(var/obj/item/A, mob/user)
	if(istype(A, /obj/item/ammo_magazine))
		flick("deckard-reload",src)
	..()

/*
 * Judge
 */
/obj/item/weapon/gun/projectile/revolver/judge
	name = "\"The Judge\""
	desc = "A revolving hand-shotgun by Jindal Arms that packs the power of a 12 guage in the palm of your hand (if you don't break your wrist). Uses 12g rounds."
	description_fluff = "While wholly owned by Hephaestus Industries, the Jindal Arms brand does not appear \
	prominently in most company catalogues (Perhaps owing to its less than prestigious image), \
	instead being sold almost exclusively through retailers and advertising platforms targeting the \
	'independent roughneck' demographic."
	icon_state = "judge"
	caliber = "12g"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2, TECH_ILLEGAL = 4)
	max_shells = 5
	recoil = 2 // ow my fucking hand
	accuracy = -15
	ammo_type = /obj/item/ammo_casing/a12g
	projectile_type = /obj/item/projectile/bullet/shotgun
	// ToDo: Remove accuracy debuf in exchange for slightly injuring your hand every time you fire it.

/*
 * Mako
 */
/obj/item/weapon/gun/projectile/revolver/lemat
	name = "Mako revolver"
	desc = "The Bishamonten P100 Mako is a 9 shot revolver with a secondary firing barrel loading shotgun shells. For when you really need something dead. A rare yet deadly collector's item. Uses .38-Special and 12g rounds depending on the barrel."
	description_fluff = "The Bishamonten Company operated from roughly 2150-2280 - the height of the first extrasolar colonisation boom - before filing for bankruptcy and selling off its assets to various companies that would go on to become today’s TSCs. \
	Focused on sleek ‘futurist’ designs which have largely fallen out of fashion but remain popular with collectors and people hoping to make some quick thalers from replica weapons. \
	Bishamonten weapons tended to be form over function - despite their flashy looks, most were completely unremarkable one way or another as weapons, and used very standard firing mechanisms - \
	the Mako was a notable exception, so original examples are much sought after."
	icon_state = "combatrevolver"
	item_state = "revolver"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	max_shells = 9
	caliber = ".38"
	ammo_type = /obj/item/ammo_casing/a38
	projectile_type = /obj/item/projectile/bullet/pistol
	var/secondary_max_shells = 1
	var/secondary_caliber = "12g"
	var/secondary_ammo_type = /obj/item/ammo_casing/a12g
	var/flipped_firing = 0
	var/list/secondary_loaded = list()
	var/list/tertiary_loaded = list()


/obj/item/weapon/gun/projectile/revolver/lemat/New()
	for(var/i in 1 to secondary_max_shells)
		secondary_loaded += new secondary_ammo_type(src)
	..()

/obj/item/weapon/gun/projectile/revolver/lemat/verb/swap_firingmode()
	set name = "Swap Firing Mode"
	set category = "Object"
	set desc = "Click to swap from one method of firing to another."

	var/mob/living/carbon/human/M = usr
	if(!M.mind)
		return 0

	to_chat(M, "<span class='notice'>You change the firing mode on \the [src].</span>")
	if(!flipped_firing)
		if(max_shells && secondary_max_shells)
			max_shells = secondary_max_shells

		if(caliber && secondary_caliber)
			caliber = secondary_caliber

		if(ammo_type && secondary_ammo_type)
			ammo_type = secondary_ammo_type

		if(secondary_loaded)
			tertiary_loaded = loaded.Copy()
			loaded = secondary_loaded

		flipped_firing = 1

	else
		if(max_shells)
			max_shells = initial(max_shells)

		if(caliber && secondary_caliber)
			caliber = initial(caliber)

		if(ammo_type && secondary_ammo_type)
			ammo_type = initial(ammo_type)

		if(tertiary_loaded)
			secondary_loaded = loaded.Copy()
			loaded = tertiary_loaded

		flipped_firing = 0

/obj/item/weapon/gun/projectile/revolver/lemat/spin_cylinder()
	set name = "Spin cylinder"
	set desc = "Fun when you're bored out of your skull."
	set category = "Object"

	chamber_offset = 0
	visible_message("<span class='warning'>\The [usr] spins the cylinder of \the [src]!</span>", \
	"<span class='notice'>You hear something metallic spin and click.</span>")
	playsound(src, 'sound/weapons/revolver_spin.ogg', 100, 1)
	if(!flipped_firing)
		loaded = shuffle(loaded)
		if(rand(1,max_shells) > loaded.len)
			chamber_offset = rand(0,max_shells - loaded.len)

/obj/item/weapon/gun/projectile/revolver/lemat/examine(mob/user)
	. = ..()
	if(secondary_loaded)
		var/to_print
		for(var/round in secondary_loaded)
			to_print += round
		. += "It has a secondary barrel loaded with \a [to_print]"
	else
		. += "It has a secondary barrel that is empty."


/*
 * Webley (Bay Port)
 */
/obj/item/weapon/gun/projectile/revolver/webley
	name = "patrol revolver"
	desc = "A rugged top break revolver commonly issued to planetary law enforcement offices. Uses .44 magnum rounds."
	description_fluff = "The Heberg-Hammarstrom Althing is a simple, head-wearing revolver made with an anti-corrosive alloy. \
	The Althing is advertised as being 'able to survive six months on the bottom of a frozen river and emerge full ready to \
	save a life'. Issued as standard sidearms to SifGuard frontier patrol."
	icon_state = "webley2"
	item_state = "webley2"
	caliber = ".44"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	ammo_type = /obj/item/ammo_casing/a44

/*
 * Webley (Eris Port)
 */
/obj/item/weapon/gun/projectile/revolver/consul
	name = "\improper \"Consul\" Revolver"
	desc = "Are you feeling lucky, punk? Uses .44 rounds."
	icon_state = "inspector"
	item_state = "revolver"
	caliber = ".44"
	origin_tech = list(TECH_COMBAT = 3, TECH_MATERIAL = 3)
	handle_casings = CYCLE_CASINGS
	ammo_type = /obj/item/ammo_casing/a44/rubber

/obj/item/weapon/gun/projectile/revolver/consul/proc/update_charge()
	cut_overlays()
	if(loaded.len==0)
		add_overlay("inspector_off")
	else
		add_overlay("inspector_on")

/obj/item/weapon/gun/projectile/revolver/consul/update_icon()
	update_charge()

//RS Add RSH12 Sari Bork
/obj/item/weapon/gun/projectile/revolver/rsh
	name = "RSH-12 Requiem"
	desc = "RSH-12 'Requiem', for when you need to put an even bigger hole through something big, an absolute cannon of a handgun,  Uses Custom made 12.7x55 rounds."
	icon = 'code/game/Rogue Star/icons/itemicons/rsh.dmi'
	icon_state = "rsh"
	item_state = "rsh"
	caliber = "12.7x55"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	load_method = SINGLE_CASING|SPEEDLOADER
	max_shells = 5
	recoil = 3 // ow my fucking hand
	ammo_type = /obj/item/ammo_casing/a127x54r
	projectile_type = /obj/item/projectile/bullet/pistol/stronger/hp
	chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round
	fire_sound = 'sound/weapons/Gunshot_deagle.ogg'
	var/recentpump = 0 			//To prevent spammage
	var/busy = FALSE //Reload spam fix
	var/cocked = FALSE
	var/action_sound = 'sound/weapons/revolvercock.ogg'
	var/opened = FALSE
	var/empty_sprite = 0 		//This is just a dirty var so it doesn't fudge up.
	var/pump_animation = "rsh-cock"	//You put the reference to the animation in question here. Frees up namming. Ex: "shotgun_old_pump" or "sniper_cycle"
	reload_time = 10
	can_flashlight = TRUE
	gun_light = FALSE
	var/doubleaction = FALSE

/obj/item/weapon/gun/projectile/revolver/rsh/CtrlClick(mob/user)
	..()
	if(can_flashlight && ishuman(user) && src.loc == usr && !user.incapacitated(INCAPACITATION_ALL))
		if(gun_light)
			add_overlay("light")
		else
			cut_overlays()


/obj/item/weapon/gun/projectile/revolver/rsh/attack_self(mob/living/user as mob)
	if(loc == user)
		if(opened)
			rsh_close(user)
		else
			rsh_open(user)
			dump_ammo(user)
	else
		..()

/obj/item/weapon/gun/projectile/revolver/rsh/consume_next_projectile()
	if(chambered && !opened)
		return chambered.BB
	return null

/obj/item/weapon/gun/projectile/revolver/rsh/Fire(atom/target, mob/living/user, clickparams, pointblank=0, reflex=0)
	if(opened)
		return
	if((!doubleaction) && (!cocked) && (world.time > next_fire_time) && (world.time > recentpump + 10))
		recentpump = world.time
		to_chat(user, "<span class='notice'>cocked = [cocked] pumptime?</span>")
		pump(user)
		return
	if(doubleaction && (world.time > next_fire_time))
		chambered = null
		if(loaded.len)
			var/obj/item/ammo_casing/AC = loaded[1] // Load next casing.
			loaded -= AC // Remove casing from loaded list.
			chambered = AC
			//M.hud_used.update_ammo_hud(M, src) // TGMC Ammo HUD Port
			cocked = TRUE
		if(pump_animation) // This affects all bolt action and shotguns.
			//playsound(src, action_sound, 60, 1)
			flick("[pump_animation]", src) // This plays any pumping
	if(cocked && (world.time > recentpump + 5))
		..()
		cocked = FALSE



/obj/item/weapon/gun/projectile/revolver/rsh/proc/rsh_open(mob/m as mob)
	opened = TRUE
	to_chat(m, "<span class='notice'>You swing open the cylinder on the [src]</span>")
	playsound(src, 'sound/weapons/flipblade.ogg', 25, 1)
	icon_state = "rsh-open"
	item_state = "rsh-open"
	update_icon()
	//return

/obj/item/weapon/gun/projectile/revolver/rsh/proc/rsh_close(mob/m as mob)
	opened = FALSE
	to_chat(m, "<span class='notice'>You swing shut the cylinder on the [src]</span>")
	icon_state = "rsh"
	item_state = "rsh"
	update_icon()
	//return

/obj/item/weapon/gun/projectile/revolver/rsh/proc/dump_ammo(mob/user as mob)
	var/count = 0
	var/turf/T = get_turf(user)
	if(!busy)
		if(T)
			cocked = FALSE
			to_chat(user, "<span class='notice'>chambered test 1 [chambered]</span>")
			if(chambered && !chambered.BB)
				to_chat(user, "<span class='notice'>chambered test 2 [chambered]</span>")
				busy = TRUE
				if(do_after(user, reload_time, ignore_movement = TRUE))
					chambered.loc = get_turf(src) // Eject casing
					chambered = null
					count++
			for(var/obj/item/ammo_casing/C in loaded)
				if(!C.BB)
					busy = TRUE
					if(do_after(user, reload_time, ignore_movement = TRUE))
						T = get_turf(user)
						if(loc != user)
							busy = FALSE
							break
						C.loc = T
						count++
						loaded-= C
						playsound(src, "casing_sound", 50, 1)

		if(count)
			busy = FALSE
			user.visible_message("[user] unloads [src].", "<span class='notice'>You unload [count] round\s from [src].</span>")
			user.hud_used.update_ammo_hud(user, src) // TGMC Ammo HUD Port
			//playsound(src, 'sound/weapons/empty.ogg', 50, 1)
		else
			busy = FALSE
			return
/obj/item/weapon/gun/projectile/revolver/rsh/proc/pump(mob/M as mob)
	if(opened)
		rsh_close()
		//return
	// We have a shell in the chamber & revolver not cocked
	to_chat(M, "<span class='notice'>cocked = [cocked] chambered = [chambered]</span>")
	if((!cocked))
		// Load next shell
		cocked = TRUE
		chambered = null
		if(loaded.len)
			var/obj/item/ammo_casing/AC = loaded[1] // Load next casing.
			loaded -= AC // Remove casing from loaded list.
			chambered = AC
			M.hud_used.update_ammo_hud(M, src) // TGMC Ammo HUD Port

		if(pump_animation) // This affects all bolt action and shotguns.
			playsound(src, action_sound, 60, 1)
			flick("[pump_animation]", src) // This plays any pumping

	update_icon()


//Below added due to unique reloading type, weh.

/obj/item/weapon/gun/projectile/revolver/rsh/load_ammo(var/obj/item/A, mob/user)
	if(istype(A, /obj/item/ammo_magazine) && !busy)
		var/obj/item/ammo_magazine/AM = A
		if(!(load_method & AM.mag_type) || caliber != AM.caliber || allowed_magazines && !is_type_in_list(A, allowed_magazines))
			to_chat(user, "<span class='warning'>[AM] won't load into [src]!</span>")
			return
		//if(loaded.len >= max_shells)
		dump_ammo(user)
			//if(opened)
			//	rsh_close()
			//to_chat(user, "<span class='warning'>[src] is full!</span>")
			//return
		var/count = 0
		for(var/obj/item/ammo_casing/C in AM.stored_ammo)
			if(loaded.len >= max_shells)
				break
			if(C.caliber == caliber)
				busy = TRUE
				if(do_after(user, reload_time, ignore_movement = TRUE))
					if(AM.loc != src.loc)
						busy = FALSE
						break
					C.loc = src
					loaded += C
					AM.stored_ammo -= C //should probably go inside an ammo_magazine proc, but I guess less proc calls this way...
					count++
					user.hud_used.update_ammo_hud(user, src)
					//user.visible_message("[user] inserts \a [C] into [src].", "<span class='notice'>You insert \a [C] into [src].</span>")
					user.hud_used.update_ammo_hud(user, src)
					flick("rsh-open-spin",src)
					playsound(src, 'sound/weapons/empty.ogg', 50, 1)
		user.visible_message("[user] reloads [src].", "<span class='notice'>You load [count] round\s into [src].</span>")
		busy = FALSE
		if(opened)
			rsh_close()
		AM.update_icon()
	else if(istype(A, /obj/item/ammo_casing))
		var/obj/item/ammo_casing/C = A
		if(!(load_method & SINGLE_CASING) || caliber != C.caliber)
			return //incompatible
		if(loaded.len >= max_shells)
			to_chat(user, "<span class='warning'>[src] is full.</span>")
			return
		if(!busy)
			if(do_after(user, reload_time * C.w_class))
				user.remove_from_mob(C)
				C.loc = src
				loaded.Insert(1, C) //add to the head of the list
				user.visible_message("[user] inserts \a [C] into [src].", "<span class='notice'>You insert \a [C] into [src].</span>")
				flick("rsh-open-spin",src)
				playsound(src, 'sound/weapons/empty.ogg', 50, 1)
				busy = FALSE

	else if(istype(A, /obj/item/weapon/storage))
		var/obj/item/weapon/storage/storage = A
		if(!(load_method & SINGLE_CASING))
			return //incompatible

		to_chat(user, "<span class='notice'>You start loading \the [src].</span>")
		sleep(1 SECOND)
		for(var/obj/item/ammo_casing/ammo in storage.contents)
			if(caliber != ammo.caliber)
				continue

			load_ammo(ammo, user)

			if(loaded.len >= max_shells)
				to_chat(user, "<span class='warning'>[src] is full.</span>")
				break
			sleep(2 SECOND)

	update_icon()
	user.hud_used.update_ammo_hud(user, src)

//attempts to unload src. If allow_dump is set to 0, the speedloader unloading method will be disabled
/obj/item/weapon/gun/projectile/revolver/rsh/unload_ammo(mob/user, var/allow_dump=1)
	if(loaded.len)
		if(load_method & SINGLE_CASING)
			var/obj/item/ammo_casing/C = loaded[loaded.len]
			loaded.len--
			user.put_in_hands(C)
			user.visible_message("[user] removes \a [C] from [src].", "<span class='notice'>You remove \a [C] from [src].</span>")
		playsound(src, 'sound/weapons/empty.ogg', 50, 1)
		user.hud_used.update_ammo_hud(user, src)
	else
		if(chambered)
			chambered.loc = get_turf(src) // Eject casing
			chambered = null
			cocked = FALSE
			playsound(src, 'sound/weapons/empty.ogg', 50, 1)
		else
			to_chat(user, "<span class='warning'>[src] is empty.</span>")
	update_icon()
	user.hud_used.update_ammo_hud(user, src)

/obj/item/weapon/gun/projectile/revolver/rsh/attackby(var/obj/item/A as obj, mob/user as mob)
	if(loc == user)
		if(opened)
			load_ammo(A, user)
		else
			//to_chat(user, "<span class='warning'>You must open the revolver to load [A].</span>")
			rsh_open(user)
			load_ammo(A, user)

	else
		..()

/obj/item/weapon/gun/projectile/revolver/rsh/attack_hand(mob/user as mob)

	if(loc == user)
		if(opened)
			if(user.get_inactive_hand() == src)
				unload_ammo(user, allow_dump=0)
			else
				..()
		else
			rsh_open(user)
	else
		..()



//RS Add END Rsh-12
