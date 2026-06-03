/obj/item/device/continuous_cmlaser/verb/toggle_cmlaser()
	set name = "Toggle cmlaser"
	set category = "Object"

	var/mob/living/carbon/human/user = usr
	if(maintenance)
		to_chat(user, span_warning("Please close the maintenance hatch with a screwdriver first, or to remove components, use a crowbar."))
		return

	if(!cmlaser)
		to_chat(user, span_warning("The cmlaser is missing!"))
		return

	if(cmlaser.loc != src)
		reattach_cmlaser(user) //Remove from their hands and back onto the cmlaser unit
		return

	if(!slot_check())
		to_chat(user, span_warning("You need to equip [src] before taking out [cmlaser]."))
	else
		if(!user.put_in_hands(cmlaser)) //Detach the cmlaser into the user's hands
			to_chat(user, span_warning("You need a free hand to hold the cmlaser!"))
		else
			containsgun = 0
			replace_icon(TRUE)
			if(is_twohanded())
				cmlaser.update_twohanding()
			user.update_inv_back()
