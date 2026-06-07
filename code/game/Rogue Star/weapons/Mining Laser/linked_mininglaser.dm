/datum/looping_sound/mininglaser
	start_sound = 'sound/rogue-star/MiningLaser/laserstart.ogg'
	start_length = 10
	mid_sounds = list('sound/rogue-star/MiningLaser/laserloop.ogg' = 1)
	mid_length = 9.5
	end_sound = 'sound/rogue-star/MiningLaser/laserstop.ogg'
	volume = 15

/obj/item/device/new_cmlaser/linked
	var/obj/item/device/continuous_cmlaser/cmlaser_base_unit
	var/filter = filter(type = "outline", size = 1, color = "#00FF00")
	var/list/highlighted  = list()
	var/datum/beam/scan_beam
	var/lastdir
	var/excavation_amount = 200
	var/warmup = 25
	var/turf/lastmined
	var/storedname
	var/datum/looping_sound/mininglaser/soundloop
	var/bumpmine

/obj/item/device/new_cmlaser/linked/Initialize(mapload, var/obj/item/device/continuous_cmlaser/backpack)
	. = ..()
	cmlaser_base_unit = backpack
	RegisterSignal(src,COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	icon_state = "mlaser"
	base_icon_state = "mlaser"
	update_icon()
	soundloop = new(list(src), FALSE)

/obj/item/device/new_cmlaser/linked/Destroy()
	UnregisterSignal(src,COMSIG_MOVABLE_MOVED)
	if(cmlaser_base_unit)
		//ensure the base unit's icon updates
		if(cmlaser_base_unit.cmlaser == src)
			cmlaser_base_unit.cmlaser = null
			cmlaser_base_unit.replace_icon()
			if(ismob(loc))
				var/mob/user = loc
				user.update_inv_back()
		cmlaser_base_unit = null
	return ..()

/obj/item/device/new_cmlaser/linked/proc/on_moved(atom/movable/source, atom/old_loc, atom/new_loc)
	SIGNAL_HANDLER
	if(!cmlaser_base_unit)
		return
	if(old_loc == cmlaser_base_unit.loc)
		lastloc = old_loc
	if(loc != cmlaser_base_unit.loc && loc != cmlaser_base_unit)
		var/mob/user = cmlaser_base_unit.loc
		if(lastloc)
			user.put_in_hands(src) //Detach the cmlaser into the user's hands
			lastloc = null
			cmlaser_base_unit.containsgun = 0
			cmlaser_base_unit.reattach_cmlaser(user)
		else
			forceMove(cmlaser_base_unit)
			cmlaser_base_unit.reattach_cmlaser(user)
		return

/obj/item/device/new_cmlaser/linked/proc/check_charge(var/charge_amt)
	return (cmlaser_base_unit.bcell && cmlaser_base_unit.bcell.check_charge(charge_amt))

/obj/item/device/new_cmlaser/linked/proc/checked_use(var/charge_amt)
	return (cmlaser_base_unit.bcell && cmlaser_base_unit.bcell.checked_use(charge_amt))

/obj/item/device/new_cmlaser/linked/attack_self(mob/living/user)
	if(cmlaser_base_unit.is_twohanded())
		update_twohanding()
	if(busy)
		busy = MEDIGUN_CANCELLED


/obj/item/device/new_cmlaser/linked/proc/process_mining(var/turf/iteration)
	var/mob/user = loc
	for(var/atom/X as anything in orange(1, lastmined))
		if(!X.simulated)
			continue
		if(isturf(X))
			if(!(X in range(beam_range, user)) || (!(X in view(beam_range, user))))
				continue
			var/turf/simulated/mineral/target_turf = X
			//to_chat(user, span_notice("X is [target_turf.name]"))
			if(target_turf.density && istype(target_turf,/turf/simulated/mineral))
				if(target_turf.excavation_level < 200)
					if(target_turf.name == storedname)
						to_chat(user, span_notice("Ore Found"))
						update_icon()
						scan_beam = user.Beam(target_turf, icon = 'code/game/Rogue Star/icons/itemicons/MiningLaser.dmi', icon_state = "mlaser-beam-ore", time = 6000)

						process_cmlaser(target_turf, user)
						break
	if(!bumpmine)
		for(var/atom/A as anything in highlighted)
			if(QDELETED(A))
				continue
			A.filters -= filter
		highlighted.Cut()
		//to_chat(user, span_notice("Normal Cleanup"))
		soundloop.stop()
	return


/obj/item/device/new_cmlaser/linked/proc/should_stop(var/turf/simulated/mineral/target, var/mob/living/user, var/active_hand)
	if((!target ) || !user /*|| (!active_hand && cmlaser_base_unit.is_twohanded())*/ || !isturf(target) || !istype(user) || busy < MEDIGUN_BUSY)
		return TRUE
	if(target.excavation_level >= 200)
		update_icon()
		sleep(1)
		QDEL_NULL(scan_beam)
		movetotile(target, user)
		sleep(1)
		//for(var/obj/effect/mineral/M in target.contents)
		//	M.filters -= filter
		//highlighted -= target

		if(storedname != "rock" && !bumpmine)
			process_mining(lastmined)

		return TRUE
	/*if((user.get_active_hand() != active_hand || wielded == 0) && cmlaser_base_unit.is_twohanded())
		to_chat(user, span_warning("Please keep your hands free!"))
		return TRUE*/

	if(user.is_incorporeal()) // mlem shadekins
		return TRUE

	if(user.incapacitated(INCAPACITATION_DEFAULT | INCAPACITATION_KNOCKDOWN | INCAPACITATION_DISABLED | INCAPACITATION_KNOCKOUT | INCAPACITATION_STUNNED | INCAPACITATION_RESTRAINED))
		return TRUE

	if(user.stat)
		return TRUE

	if(!(target in range(beam_range, user)) || (!(target in view(beam_range, user))))
		to_chat(user, span_warning("You are too far away from \the [target] to affect it/them, Or they are not in view. Get closer."))
		return TRUE

	if(/*!isliving(target) && */!isturf(target))
		return TRUE

	return FALSE

/obj/item/device/new_cmlaser/linked/afterattack(atom/target, mob/user, proximity_flag)
	// Things that invalidate the scan immediately.
	bumpmine = proximity_flag
	if(!(target in range(beam_range, user)) || (!(target in view(beam_range, user))))
		to_chat(user, span_warning("Range Debug."))
		return
	if(isturf(target))
		var/turf/simulated/mineral/target_turf = target
		if(!istype(target_turf,/turf/simulated/mineral))
			return
		if(target_turf.excavation_level >= 200 || !target_turf.density)
			return
		target = target_turf

	if(busy && !(target == current_target) && isturf(target))
		to_chat(user, span_warning("\The [src] is already targeting something."))
		return
	if(!isturf(target))
		return
	if(!cmlaser_base_unit.smanipulator)
		to_chat(user, span_warning("\The [src] Blinks a red error light, Manipulator missing."))
		return
	if(!cmlaser_base_unit.scapacitor)
		to_chat(user, span_warning("\The [src] Blinks a blue error light, capacitor missing."))
		return
	if(!cmlaser_base_unit.slaser)
		to_chat(user, span_warning("\The [src] Blinks an orange error light, laser missing."))
		return
	if(!cmlaser_base_unit.smodule)
		to_chat(user, span_warning("\The [src] Blinks a pink error light, scanning module missing."))
		return
	if(!check_charge(5))
		to_chat(user, span_warning("\The [src] doesn't have enough charge left to do that."))
		return
	if(target == current_target && busy)
		busy = MEDIGUN_CANCELLED
		return
	if(target == user)
		return
	current_target = target
	busy = MEDIGUN_BUSY
	update_icon()
	lastmined = target
	storedname = target.name
	if(target.name == "rock" || bumpmine)
		if(!bumpmine)scan_beam = user.Beam(target, icon = 'code/game/Rogue Star/icons/itemicons/MiningLaser.dmi', icon_state = "mlaser-beam", time = 6000)
		playsound(src, 'sound/rogue-star/MiningLaser/laserstart.ogg', 15, 1)
		warmup = 7.5
	else
		soundloop.start()
		scan_beam = user.Beam(target, icon = 'code/game/Rogue Star/icons/itemicons/MiningLaser.dmi', icon_state = "mlaser-beam-ore", time = 6000)

		for(var/obj/effect/mineral/M in target.contents)
			highlighted += M
		for(var/atom/X as anything in orange(2, target))
			if(!X.simulated)
				continue
			if(isturf(X))
				if(X.name == storedname)
					for(var/obj/effect/mineral/M in X.contents)
						highlighted += M
		for(var/atom/A as anything in highlighted)
			A.filters += filter
		warmup = 25
	process_cmlaser(target, user)

	action_cancelled = FALSE
	busy = MEDIGUN_IDLE
	current_target = null

	// Now clean up the effects.
	update_icon()
	sleep(1)
	QDEL_NULL(scan_beam)
	sleep(1)

/obj/item/device/new_cmlaser/linked/proc/process_cmlaser(turf/T, mob/user, isactive = FALSE)
	if(should_stop(T, user, user.get_active_hand()))
		return

	if(do_after(user, warmup, ignore_movement = FALSE))
		isactive = FALSE // The default is 'we didn't heal this cycle'
		if(!checked_use(5))
			to_chat(user, span_warning("\The [src] doesn't have enough charge left to do that."))
			return
		if(isturf(T))
			var/turf/simulated/mineral/target_turf = T
			if(istype(target_turf,/turf/simulated/mineral))
				target_turf.cmlaser_act(excavation_amount)

		process_cmlaser(T, user, isactive)
	if(!bumpmine)
		for(var/atom/A as anything in highlighted)

			if(QDELETED(A))
				continue
			to_chat(user, span_notice("list [A]"))
			A.filters -= filter
		highlighted.Cut()
		//to_chat(user, span_notice("Moved"))

		soundloop.stop()


/obj/item/device/new_cmlaser/linked/proc/movetotile(turf/T as turf, mob/user as mob)
	for(var/obj/item/weapon/ore/O in T) //Only ever grabs ores. Doesn't do any extraneous checks, as all ore is the same size. Tons of checks means it causes hanging for up to three seconds.

		var/obj/item/weapon/ore/ore = O
		if(istype(user.pulling, /obj/structure/ore_box))
			var/obj/structure/ore_box/OB = user.pulling
			OB.stored_ore[ore.material]++	// Add the ore to the box
			qdel(ore)
		else
			var/center = get_turf(user)
			O.forceMove(get_step(center,user.dir))
