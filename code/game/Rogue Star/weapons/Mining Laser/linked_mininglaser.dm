/obj/item/device/new_cmlaser/linked
	var/obj/item/device/continuous_cmlaser/cmlaser_base_unit
	var/myicon = "medbeam_basic"
	var/mycolor = "#037ffc"
	var/datum/beam/scan_beam
	var/list/box_segments
	var/lastdir
	var/excavation_amount = 200
	var/warmup = 25
	var/turf/lastmined
	var/storedname

/obj/item/device/new_cmlaser/linked/Initialize(mapload, var/obj/item/device/continuous_cmlaser/backpack)
	. = ..()
	cmlaser_base_unit = backpack
	RegisterSignal(src,COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	if(!cmlaser_base_unit.is_twohanded())
		icon_state = "medblaster-compact"
		base_icon_state = "medblaster-compact"
		wielded_item_state = ""
		update_icon()

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
	var/mob/player = loc
	to_chat(player, span_notice("lastname = [lastmined.name]"))
	for(var/atom/X as anything in orange(beam_range-2, lastmined))
		if(!X.simulated)
			continue
		if(isturf(X))
			var/turf/simulated/mineral/target_turf = X
			to_chat(player, span_notice("X is [target_turf.name]"))
			if(target_turf.density && istype(target_turf,/turf/simulated/mineral))
				if(target_turf.excavation_level < 200)
					if(target_turf.name == storedname)
						to_chat(player, span_notice("Rock Found"))
						update_icon()
						scan_beam = player.Beam(target_turf, icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', icon_state = myicon, time = 6000)
						box_segments = list()
						if(player.client)
							box_segments = draw_box(target_turf, beam_range, player.client)
							color_box(box_segments, mycolor, 5)
						process_cmlaser(target_turf, player)
						break

	return


/*
/obj/item/device/new_cmlaser/linked/proc/process_mining(var/turf/iteration)
	var/mob/player = loc
	iteration = get_turf(player)
	var/turf/center = iteration
	var/i = beam_range+1
	var/m = 0
	while(m < i)
		var/turf/simulated/mineral/target_turf = center
		if(target_turf.density && istype(target_turf,/turf/simulated/mineral))
			if(target_turf.excavation_level < 200)
				to_chat(player, span_notice("Rock Found"))
				update_icon()
				scan_beam = player.Beam(target_turf, icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', icon_state = myicon, time = 6000)
				box_segments = list()
				if(player.client)
					box_segments = draw_box(target_turf, beam_range, player.client)
					color_box(box_segments, mycolor, 5)
				process_cmlaser(target_turf, player)
				break
		else
			if(target_turf.density)
				break
			center = get_step(center, player.dir) //Advance in the given direction
			to_chat(player, span_notice("No rock found [center] m = [m]"))
			m++
*/
/obj/item/device/new_cmlaser/linked/proc/should_stop(var/turf/simulated/mineral/target, var/mob/living/user, var/active_hand)
	if((!target ) || !user /*|| (!active_hand && cmlaser_base_unit.is_twohanded())*/ || !isturf(target) || !istype(user) || busy < MEDIGUN_BUSY)
		return TRUE
	if(target.excavation_level >= 200)
		update_icon()
		sleep(1)
		QDEL_NULL(scan_beam)
		movetotile(target, user)
		sleep(1)
		if(user.client) // If for some reason they logged out mid-scan the box will be gone anyways.
			delete_box(box_segments, user.client)
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

	if(!(target in range(beam_range, user)) || (!(target in view(10, user)) && !(cmlaser_base_unit.smodule.get_rating() >= 5)))
		to_chat(user, span_warning("You are too far away from \the [target] to affect it/them, Or they are not in view. Get closer."))
		return TRUE

	if(/*!isliving(target) && */!isturf(target))
		return TRUE

	return FALSE

/obj/item/device/new_cmlaser/linked/afterattack(atom/target, mob/user, proximity_flag)
	// Things that invalidate the scan immediately.
	if(isturf(target))
		var/turf/simulated/mineral/target_turf = target
		if(target_turf.excavation_level >= 200 || !target_turf.density || !(istype(target_turf,/turf/simulated/mineral)))
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
	if(get_dist(target, user) > beam_range)
		to_chat(user, span_warning("You are too far away from \the [target] to affect it. Get closer."))
		return

	if(target == current_target && busy)
		busy = MEDIGUN_CANCELLED
		return
	if(target == user)
		return
	if(!(target in range(beam_range, user)) || (!(target in view(10, user)) && !cmlaser_base_unit.smodule))
		to_chat(user, span_warning("You are too far away from \the [target] to affect it/them, Or it/they are not in view. Get closer."))
		return
	current_target = target
	busy = MEDIGUN_BUSY
	update_icon()
	lastmined = target
	storedname = target.name
	scan_beam = user.Beam(target, icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi', icon_state = myicon, time = 6000)
	box_segments = list()
	playsound(src, 'sound/weapons/wave.ogg', 50)
	var/H = target
	if(user.client)
		box_segments = draw_box(target, beam_range, user.client)
		color_box(box_segments, mycolor, 5)
	process_cmlaser(H, user)

	action_cancelled = FALSE
	busy = MEDIGUN_IDLE
	current_target = null

	// Now clean up the effects.
	update_icon()
	sleep(1)
	QDEL_NULL(scan_beam)
	sleep(1)
	if(user.client) // If for some reason they logged out mid-scan the box will be gone anyways.
		delete_box(box_segments, user.client)

/obj/item/device/new_cmlaser/linked/proc/process_cmlaser(turf/H, mob/user, filter, isactive = FALSE)
	if(should_stop(H, user, user.get_active_hand()))
		return

	if(do_after(user, warmup, ignore_movement = TRUE, needhand = cmlaser_base_unit.is_twohanded()))
		isactive = FALSE // The default is 'we didn't heal this cycle'
		if(!checked_use(5))
			to_chat(user, span_warning("\The [src] doesn't have enough charge left to do that."))
			return
		if(isturf(H))
			var/turf/simulated/mineral/target_turf = H
			if(istype(target_turf,/turf/simulated/mineral))
				target_turf.cmlaser_act(excavation_amount)

		process_cmlaser(H, user, filter, isactive)



/obj/item/device/new_cmlaser/linked/proc/movetotile(turf/T as turf, mob/user as mob)
	for(var/obj/item/weapon/ore/O in T) //Only ever grabs ores. Doesn't do any extraneous checks, as all ore is the same size. Tons of checks means it causes hanging for up to three seconds.

		var/obj/item/weapon/ore/ore = O
		if(istype(user.pulling, /obj/structure/ore_box))
			var/obj/structure/ore_box/OB = user.pulling
			OB.stored_ore[ore.material]++	// Add the ore to the box
			qdel(ore)
		else
			O.forceMove(get_turf(user))
