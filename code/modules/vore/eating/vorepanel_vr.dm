//
// Vore management panel for players
//

#define BELLIES_MAX 40
#define BELLIES_NAME_MIN 2
#define BELLIES_NAME_MAX 40
#define BELLIES_DESC_MAX 4096
#define FLAVOR_MAX 400

//INSERT COLORIZE-ONLY STOMACHS HERE
var/global/list/belly_colorable_only_fullscreens = list("a_synth_flesh_mono",
														"a_synth_flesh_mono_hole",
														"a_anim_belly",
														"multi_layer_test_tummy",
														"gematically_angular",
														"entrance_to_a_tumby",
														"passage_to_a_tumby",
														"destination_tumby",
														"destination_tumby_fluidless",
														"post_tumby_passage",
														"post_tumby_passage_fluidless",
														"not_quite_tumby",
														"could_it_be_a_tumby")

/mob
	var/datum/vore_look/vorePanel

/mob/proc/insidePanel()
	set name = "Vore Panel"
	set category = "IC"

	if(SSticker.current_state == GAME_STATE_INIT)
		return

	if(!isliving(src))
		init_vore()

	if(!vorePanel)
		if(!isnewplayer(src))
			log_debug("[src] ([type], \ref[src]) didn't have a vorePanel and tried to use the verb.")
		vorePanel = new(src)

	vorePanel.tgui_interact(src)

/mob/proc/updateVRPanel() //Panel popup update call from belly events.
	if(vorePanel)
		SStgui.update_uis(vorePanel)

//
// Callback Handler for the Inside form
//
/datum/vore_look
	var/mob/host // Note, we do this in case we ever want to allow people to view others vore panels
	var/unsaved_changes = FALSE
	var/show_pictures = TRUE

/datum/vore_look/New(mob/new_host)
	if(istype(new_host))
		host = new_host
	. = ..()

/datum/vore_look/Destroy()
	host = null
	. = ..()

/datum/vore_look/ui_assets(mob/user)
	. = ..()
	. += get_asset_datum(/datum/asset/spritesheet/vore)
	. += get_asset_datum(/datum/asset/spritesheet/vore_colorized) //Either this isn't working or my cache is corrupted and won't show them.

/datum/vore_look/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "VorePanel", "Vore Panel")
		ui.open()
		ui.set_autoupdate(FALSE)

// This looks weird, but all tgui_host is used for is state checking
// So this allows us to use the self_state just fine.
/datum/vore_look/tgui_host(mob/user)
	return host

// Note, in order to allow others to look at others vore panels, this state would need
// to be modified.
/datum/vore_look/tgui_state(mob/user)
	return GLOB.tgui_vorepanel_state

/datum/vore_look/var/static/list/nom_icons
/datum/vore_look/proc/cached_nom_icon(atom/target)
	LAZYINITLIST(nom_icons)

	var/key = ""
	if(isobj(target))
		key = "[target.type]"
	else if(ismob(target))
		var/mob/M = target
		key = "\ref[target][M.real_name]"
	if(nom_icons[key])
		. = nom_icons[key]
	else
		. = icon2base64(getFlatIcon(target,defdir=SOUTH,no_anim=TRUE))
		nom_icons[key] = .


/datum/vore_look/tgui_data(mob/user)
	var/list/data = list()

	if(!host)
		return data

	data["unsaved_changes"] = unsaved_changes
	data["show_pictures"] = show_pictures

	var/atom/hostloc = host.loc
	var/list/inside = list()
	if(isbelly(hostloc))
		var/obj/belly/inside_belly = hostloc
		var/mob/living/pred = inside_belly.owner

		var/inside_desc = "No description."
		if(host.absorbed && inside_belly.absorbed_desc)
			inside_desc = inside_belly.absorbed_desc
		else if(inside_belly.desc)
			inside_desc = inside_belly.desc

		//I'd rather not copy-paste this code twice into the previous if-statement
		//Technically we could just format the text anyway, but IDK how demanding unnecessary text-replacements are
		if((host.absorbed && inside_belly.absorbed_desc) || (inside_belly.desc))
			var/formatted_desc
			formatted_desc = replacetext(inside_desc, "%belly", lowertext(inside_belly.name)) //replace with this belly's name
			formatted_desc = replacetext(formatted_desc, "%pred", pred) //replace with the pred of this belly
			formatted_desc = replacetext(formatted_desc, "%prey", host) //replace with whoever's reading this
			inside_desc = formatted_desc

		inside = list(
			"absorbed" = host.absorbed,
			"belly_name" = inside_belly.name,
			"belly_mode" = inside_belly.digest_mode,
			"desc" = inside_desc,
			"pred" = pred,
			"ref" = "\ref[inside_belly]",
		)

		var/list/inside_contents = list()
		for(var/atom/movable/O in inside_belly)
			if(O == host)
				continue

			var/list/info = list(
				"name" = "[O]",
				"absorbed" = FALSE,
				"stat" = 0,
				"ref" = "\ref[O]",
				"outside" = FALSE,
			)
			if(show_pictures)
				info["icon"] = cached_nom_icon(O)
			if(isliving(O))
				var/mob/living/M = O
				info["stat"] = M.stat
				if(M.absorbed)
					info["absorbed"] = TRUE
			inside_contents.Add(list(info))
		inside["contents"] = inside_contents
	data["inside"] = inside

	var/is_cyborg = FALSE
	var/is_vore_simple_mob = FALSE
	if(isrobot(host))
		is_cyborg = TRUE
	else if(istype(host, /mob/living/simple_mob/vore))	//So far, this does nothing. But, creating this for future belly work
		is_vore_simple_mob = TRUE
	data["host_mobtype"] = list(
		"is_cyborg" = is_cyborg,
		"is_vore_simple_mob" = is_vore_simple_mob
	)

	var/list/our_bellies = list()
	for(var/obj/belly/B as anything in host.vore_organs)
		our_bellies.Add(list(list(
			"selected" = (B == host.vore_selected),
			"name" = B.name,
			"ref" = "\ref[B]",
			"digest_mode" = B.digest_mode,
			"contents" = LAZYLEN(B.contents),
		)))
	data["our_bellies"] = our_bellies

	var/list/selected_list = null
	if(host.vore_selected)
		var/obj/belly/selected = host.vore_selected
		selected_list = list(
			"belly_name" = selected.name,
			"is_wet" = selected.is_wet,
			"wet_loop" = selected.wet_loop,
			"mode" = selected.digest_mode,
			"item_mode" = selected.item_digest_mode,
			"verb" = selected.vore_verb,
			"release_verb" = selected.release_verb,
			"desc" = selected.desc,
			"absorbed_desc" = selected.absorbed_desc,
			"fancy" = selected.fancy_vore,
			"sound" = selected.vore_sound,
			"release_sound" = selected.release_sound,
			// "messages" // TODO
			"can_taste" = selected.can_taste,
			"egg_type" = selected.egg_type,
			"nutrition_percent" = selected.nutrition_percent,
			"digest_brute" = selected.digest_brute,
			"digest_burn" = selected.digest_burn,
			"digest_oxy" = selected.digest_oxy,
			"digest_tox" = selected.digest_tox,
			"digest_clone" = selected.digest_clone,
			"bulge_size" = selected.bulge_size,
			"save_digest_mode" = selected.save_digest_mode,
			"display_absorbed_examine" = selected.display_absorbed_examine,
			"shrink_grow_size" = selected.shrink_grow_size,
			"emote_time" = selected.emote_time,
			"emote_active" = selected.emote_active,
			"selective_preference" = selected.selective_preference,
			"nutrition_ex" = host.nutrition_message_visible,
			"weight_ex" = host.weight_message_visible,
			"belly_fullscreen" = selected.belly_fullscreen,
			"belly_fullscreen_color" = selected.belly_fullscreen_color,
			"belly_fullscreen_color_secondary" = selected.belly_fullscreen_color_secondary,
			"belly_fullscreen_color_trinary" = selected.belly_fullscreen_color_trinary,
			"colorization_enabled" = selected.colorization_enabled,
			"belly_healthbar_overlay_theme" = selected.belly_healthbar_overlay_theme,	//RS ADD
			"belly_healthbar_overlay_color" = selected.belly_healthbar_overlay_color,	//RS ADD
			"eating_privacy_local" = selected.eating_privacy_local,
			"silicon_belly_overlay_preference"	= selected.silicon_belly_overlay_preference,
			"visible_belly_minimum_prey"	= selected.visible_belly_minimum_prey,
			"overlay_min_prey_size"	= selected.overlay_min_prey_size,
			"override_min_prey_size" = selected.override_min_prey_size,
			"override_min_prey_num"	= selected.override_min_prey_num,
			// Begin RS edit
			"affects_voresprite" = selected.affects_vore_sprites,
			"absorbed_voresprite" = selected.count_absorbed_prey_for_sprite,
			"absorbed_multiplier" = selected.absorbed_multiplier,
			"item_voresprite" = selected.count_items_for_sprite,
			"item_multiplier" = selected.item_multiplier,
			"health_voresprite" = selected.health_impacts_size,
			"resist_animation" = selected.resist_triggers_animation,
			"voresprite_size_factor" = selected.size_factor_for_sprite,
			"belly_sprite_to_affect" = selected.belly_sprite_to_affect,
			"belly_sprite_option_shown" = istype(host, /mob/living) ? (LAZYLEN(host:vore_icon_bellies) >= 1 ? TRUE : FALSE) : FALSE, // TODO: FIX THIS
			"tail_option_shown" = istype(host, /mob/living/carbon/human),
			"tail_to_change_to" = selected.tail_to_change_to,
			"tail_colouration" = selected.tail_colouration,
			"tail_extra_overlay" = selected.tail_extra_overlay,
			"tail_extra_overlay2" = selected.tail_extra_overlay2,
			"drainmode" = selected.drainmode, //RS Edit || Ports VOREStation PR15876
			// End RS edit
			"show_liq" = selected.show_liquids, // Begin reagent bellies || RS Add || Chomp Port
			"show_liq_fullness" = selected.show_fullness_messages,
			"liquid_voresprite" = selected.count_liquid_for_sprite,
			"liquid_multiplier" = selected.liquid_multiplier,
			"custom_reagentcolor" = selected.custom_reagentcolor,
			"custom_reagentalpha" = selected.custom_reagentalpha,
			"liquid_overlay" = selected.liquid_overlay,
			"max_liquid_level" = selected.max_liquid_level,
			"reagent_touches" = selected.reagent_touches,
			"mush_overlay" = selected.mush_overlay,
			"mush_color" = selected.mush_color,
			"mush_alpha" = selected.mush_alpha,
			"max_mush" = selected.max_mush,
			"min_mush" = selected.min_mush,
			 // End reagent bellies
		)

		var/list/addons = list()
		for(var/flag_name in selected.mode_flag_list)
			if(selected.mode_flags & selected.mode_flag_list[flag_name])
				addons.Add(flag_name)
		selected_list["addons"] = addons

		// Begin RS edit
		var/list/vs_flags = list()
		for(var/flag_name in selected.vore_sprite_flag_list)
			if(selected.vore_sprite_flags & selected.vore_sprite_flag_list[flag_name])
				vs_flags.Add(flag_name)
		selected_list["vore_sprite_flags"] = vs_flags
		// End RS edit

		// Reagent bellies || RS Add || Chomp Port
		var/list/liq_interacts = list()
		if(selected.show_liquids)
			liq_interacts["liq_reagent_gen"] = selected.reagentbellymode
			liq_interacts["liq_reagent_type"] = selected.reagent_chosen
			liq_interacts["liq_reagent_name"] = selected.reagent_name
			liq_interacts["liq_reagent_nutri_rate"] = selected.gen_time
			liq_interacts["liq_reagent_capacity"] = selected.custom_max_volume
			liq_interacts["liq_sloshing"] = selected.vorefootsteps_sounds
			liq_interacts["liq_reagent_addons"] = list()
			liq_interacts["custom_reagentcolor"] = selected.custom_reagentcolor ? selected.custom_reagentcolor : selected.reagentcolor
			liq_interacts["custom_reagentalpha"] = selected.custom_reagentalpha ? selected.custom_reagentalpha : "Default"
			liq_interacts["liquid_overlay"] = selected.liquid_overlay
			liq_interacts["max_liquid_level"] = selected.max_liquid_level
			liq_interacts["reagent_touches"] = selected.reagent_touches
			liq_interacts["mush_overlay"] = selected.mush_overlay
			liq_interacts["mush_color"] = selected.mush_color
			liq_interacts["mush_alpha"] = selected.mush_alpha
			liq_interacts["max_mush"] = selected.max_mush
			liq_interacts["min_mush"] = selected.min_mush
			var/list/liq_regs = list()
			for(var/flag_name in selected.reagent_mode_flag_list)
				if(selected.reagent_mode_flags & selected.reagent_mode_flag_list[flag_name])
					liq_regs.Add(flag_name)
			liq_interacts["liq_reagent_addons"] = liq_regs

		selected_list["liq_interacts"] = liq_interacts

		var/list/liq_messages = list()
		if(selected.show_fullness_messages)
			liq_messages["liq_msg_toggle1"] = selected.liquid_fullness1_messages
			liq_messages["liq_msg_toggle2"] = selected.liquid_fullness2_messages
			liq_messages["liq_msg_toggle3"] = selected.liquid_fullness3_messages
			liq_messages["liq_msg_toggle4"] = selected.liquid_fullness4_messages
			liq_messages["liq_msg_toggle5"] = selected.liquid_fullness5_messages

			liq_messages["liq_msg1"] = selected.liquid_fullness1_messages
			liq_messages["liq_msg2"] = selected.liquid_fullness2_messages
			liq_messages["liq_msg3"] = selected.liquid_fullness3_messages
			liq_messages["liq_msg4"] = selected.liquid_fullness4_messages
			liq_messages["liq_msg5"] = selected.liquid_fullness5_messages // End reagent bellies

		selected_list["liq_messages"] = liq_messages

		selected_list["egg_type"] = selected.egg_type
		selected_list["contaminates"] = selected.contaminates
		selected_list["contaminate_flavor"] = null
		selected_list["contaminate_color"] = null
		if(selected.contaminates)
			selected_list["contaminate_flavor"] = selected.contamination_flavor
			selected_list["contaminate_color"] = selected.contamination_color

		selected_list["escapable"] = selected.escapable
		selected_list["interacts"] = list()
		if(selected.escapable)
			selected_list["interacts"]["escapechance"] = selected.escapechance
			selected_list["interacts"]["escapetime"] = selected.escapetime
			selected_list["interacts"]["transferchance"] = selected.transferchance
			selected_list["interacts"]["transferlocation"] = selected.transferlocation
			selected_list["interacts"]["transferchance_secondary"] = selected.transferchance_secondary
			selected_list["interacts"]["transferlocation_secondary"] = selected.transferlocation_secondary
			selected_list["interacts"]["absorbchance"] = selected.absorbchance
			selected_list["interacts"]["digestchance"] = selected.digestchance


		selected_list["autotransfer_enabled"] = selected.autotransfer_enabled  //RS Add Start || Chomp Port 2821, 3194, 6155
		selected_list["autotransfer"] = list()
		if(selected.autotransfer_enabled)
			selected_list["autotransfer"]["autotransferchance"] = selected.autotransferchance
			selected_list["autotransfer"]["autotransferwait"] = selected.autotransferwait
			selected_list["autotransfer"]["autotransferlocation"] = selected.autotransferlocation
			selected_list["autotransfer"]["autotransferchance_secondary"] = selected.autotransferchance_secondary
			selected_list["autotransfer"]["autotransferlocation_secondary"] = selected.autotransferlocation_secondary
			selected_list["autotransfer"]["autotransfer_min_amount"] = selected.autotransfer_min_amount
			selected_list["autotransfer"]["autotransfer_max_amount"] = selected.autotransfer_max_amount//RS Add End

		selected_list["disable_hud"] = selected.disable_hud
		selected_list["colorization_enabled"] = selected.colorization_enabled
		selected_list["belly_healthbar_overlay_theme"] = selected.belly_healthbar_overlay_theme	//RS ADD
		selected_list["belly_healthbar_overlay_color"] = selected.belly_healthbar_overlay_color	//RS ADD
		selected_list["belly_fullscreen_color"] = selected.belly_fullscreen_color
		selected_list["belly_fullscreen_color_secondary"] = selected.belly_fullscreen_color_secondary
		selected_list["belly_fullscreen_color_trinary"] = selected.belly_fullscreen_color_trinary

		if(selected.colorization_enabled)
			selected_list["possible_fullscreens"] = icon_states('icons/mob/screen_full_colorized_vore.dmi') //Makes any icons inside of here selectable.
		else
			selected_list["possible_fullscreens"] = icon_states('icons/mob/screen_full_vore.dmi') //Where all stomachs - colorable and not - are stored.
			//INSERT COLORIZE-ONLY STOMACHS HERE.
			//This manually removed color-only stomachs from the above list.
			//For some reason, colorized stomachs have to be added to both colorized_vore(to be selected) and full_vore (to show the preview in tgui)
			//Why? I have no flipping clue. As you can see above, vore_colorized is included in the assets but isn't working. It makes no sense.
			//I can only imagine this is a BYOND/TGUI issue with the cache. If you can figure out how to fix this and make it so you only need to
			//include things in full_colorized_vore, that would be great. For now, this is the only workaround that I could get to work.
			selected_list["possible_fullscreens"] -= belly_colorable_only_fullscreens

		var/list/selected_contents = list()
		for(var/O in selected)
			var/list/info = list(
				"name" = "[O]",
				"absorbed" = FALSE,
				"stat" = 0,
				"ref" = "\ref[O]",
				"outside" = TRUE,
			)
			if(show_pictures)
				info["icon"] = cached_nom_icon(O)
			if(isliving(O))
				var/mob/living/M = O
				info["stat"] = M.stat
				if(M.absorbed)
					info["absorbed"] = TRUE
			selected_contents.Add(list(info))
		selected_list["contents"] = selected_contents

	data["selected"] = selected_list
	data["prefs"] = list(
		"digestable" = host.digestable,
		"devourable" = host.devourable,
		"resizable" = host.resizable,
		"feeding" = host.feeding,
		"absorbable" = host.absorbable,
		"digest_leave_remains" = host.digest_leave_remains,
		"allowmobvore" = host.allowmobvore,
		"permit_healbelly" = host.permit_healbelly,
		"show_vore_fx" = host.show_vore_fx,
		"can_be_drop_prey" = host.can_be_drop_prey,
		"can_be_drop_pred" = host.can_be_drop_pred,
		"allow_inbelly_spawning" = host.allow_inbelly_spawning,
		"allow_spontaneous_tf" = host.allow_spontaneous_tf,
		"step_mechanics_active" = host.step_mechanics_pref,
		"pickup_mechanics_active" = host.pickup_pref,
		"noisy" = host.noisy,
		"drop_vore" = host.drop_vore,
		"slip_vore" = host.slip_vore,
		"stumble_vore" = host.stumble_vore,
		"throw_vore" = host.throw_vore,
		"food_vore" = host.food_vore,
		"nutrition_message_visible" = host.nutrition_message_visible,
		"nutrition_messages" = host.nutrition_messages,
		"weight_message_visible" = host.weight_message_visible,
		"weight_messages" = host.weight_messages,
		"eating_privacy_global" = host.eating_privacy_global,
		"vore_sprite_color" = istype(host, /mob/living/carbon/human) ? host:vore_sprite_color : "#FFFFFF", // RS edit
		"allowcontamination" = istype(host, /mob/living/carbon/human) ? host:allow_contaminate : TRUE, // RS edit
		"allowstripping" = istype(host, /mob/living/carbon/human) ? host:allow_stripping : TRUE, // RS edit
		"allowssdvore" = host.ssd_vore, // RS edit
		"glowing_belly"  = host.glowy_belly,
		"autotransferable" = host.autotransferable, //RS Add || Port Chomp 3200
	)

	return data

/datum/vore_look/tgui_act(action, params)
	if(..())
		return TRUE

	switch(action)
		if("show_pictures")
			show_pictures = !show_pictures
			return TRUE
		if("int_help")
			tgui_alert(usr, "These control how your belly responds to someone using 'resist' while inside you. The percent chance to trigger each is listed below, \
					and you can change them to whatever you see fit. Setting them to 0% will disable the possibility of that interaction. \
					These only function as long as interactions are turned on in general. Keep in mind, the 'belly mode' interactions (digest/absorb) \
					will affect all prey in that belly, if one resists and triggers digestion/absorption. If multiple trigger at the same time, \
					only the first in the order of 'Escape > Transfer > Absorb > Digest' will occur.","Interactions Help")
			return TRUE

		// Host is inside someone else, and is trying to interact with something else inside that person.
		if("pick_from_inside")
			return pick_from_inside(usr, params)

		// Host is trying to interact with something in host's belly.
		if("pick_from_outside")
			return pick_from_outside(usr, params)

		if("newbelly")
			if(host.vore_organs.len >= BELLIES_MAX)
				return FALSE

			var/new_name = html_encode(tgui_input_text(usr,"New belly's name:","New Belly"))

			var/failure_msg
			if(length(new_name) > BELLIES_NAME_MAX || length(new_name) < BELLIES_NAME_MIN)
				failure_msg = "Entered belly name length invalid (must be longer than [BELLIES_NAME_MIN], no more than than [BELLIES_NAME_MAX])."
			// else if(whatever) //Next test here.
			else
				for(var/obj/belly/B as anything in host.vore_organs)
					if(lowertext(new_name) == lowertext(B.name))
						failure_msg = "No duplicate belly names, please."
						break

			if(failure_msg) //Something went wrong.
				tgui_alert_async(usr, failure_msg, "Error!")
				return TRUE

			var/obj/belly/NB = new(host)
			NB.name = new_name
			host.vore_selected = NB
			unsaved_changes = TRUE
			return TRUE

//RS ADD START: Adds vorebelly importation from CHOMPStation PR6177
		if("importpanel")
			var/panel_choice = tgui_input_list(usr, "Belly Import", "Pick an option", list("Import all bellies from VRDB","Import one belly from VRDB"))
			if(!panel_choice) return
			var/pickOne = FALSE
			if(panel_choice == "Import one belly from VRDB")
				pickOne = TRUE
			var/input_file = input(usr,"Please choose a valid VRDB file to import from.","Belly Import") as file
			var/input_data
			try
				input_data = json_decode(file2text(input_file))
			catch(var/exception/e)
				tgui_alert_async(usr, "The supplied file contains errors: [e]", "Error!")
				return FALSE

			if(!islist(input_data))
				tgui_alert_async(usr, "The supplied file was not a valid VRDB file.", "Error!")
				return FALSE

			var/list/valid_names = list()
			var/list/valid_lists = list()
			var/list/updated = list()

			for(var/list/raw_list in input_data)
				if(length(valid_names) >= BELLIES_MAX) //check if there are too many bellies in this list
					tgui_alert_async(usr, "The supplied VRDB file contains TOO MANY bellies.", "Error!") //Supply error message to the user
					break
				if(!islist(raw_list)) //Verify the list is not empty, or initialized correctly
					continue
				if(!istext(raw_list["name"])) //Verify the list has a name to set the vorebelly as
					continue
				if(length(raw_list["name"]) > BELLIES_NAME_MAX || length(raw_list["name"]) < BELLIES_NAME_MIN) //Ensure each belly's name fits the length limits
					continue
				if(raw_list["name"] in valid_names)
					continue
				for(var/obj/belly/B in host.vore_organs)
					if(lowertext(B.name) == lowertext(raw_list["name"]))
						updated += raw_list["name"]
						break
				if(!pickOne && length(host.vore_organs)+length(valid_names)-length(updated) >= BELLIES_MAX)
					continue
				valid_names += raw_list["name"]
				valid_lists += list(raw_list)

			if(length(valid_names) <= 0)
				tgui_alert_async(usr, "The supplied VRDB file does not contain any valid bellies.", "Error!")
				return FALSE

			if(pickOne) //Choose one vorebelly in the list
				var/picked = tgui_input_list(usr, "Belly Import", "Which belly?", valid_names)
				if(!picked) return
				for(var/B in valid_lists)
					if(lowertext(picked) == lowertext(B["name"]))
						valid_names = list(picked)
						valid_lists = list(B)
						break
				if(picked in updated)
					updated = list(picked)
				else
					updated = list()

			var/list/alert_msg = list()
			if(length(valid_names)-length(updated) > 0)
				alert_msg += "add [length(valid_names)-length(updated)] new bell[length(valid_names)-length(updated) == 1 ? "y" : "ies"]"
			if(length(updated) > 0)
				alert_msg += "update [length(updated)] existing bell[length(updated) == 1 ? "y" : "ies"]. Please make sure you have saved a copy of your existing bellies"

			var/confirm = tgui_alert(host, "WARNING: This will [jointext(alert_msg," and ")]. You can revert the import by using the Reload Prefs button under Preferences as long as you don't Save Prefs. Are you sure?","Import bellies?",list("Yes","Cancel"))
			if(confirm != "Yes") return FALSE

			for(var/list/belly_data in valid_lists)
				var/obj/belly/new_belly
				for(var/obj/belly/existing_belly in host.vore_organs)
					if(lowertext(existing_belly.name) == lowertext(belly_data["name"]))
						new_belly = existing_belly
						break
				if(!new_belly && length(host.vore_organs) < BELLIES_MAX)
					new_belly = new(host)
					new_belly.name = belly_data["name"]
				if(!new_belly) continue

				// Controls
				if(istext(belly_data["mode"])) //Set the mode of the vorebelly
					var/new_mode = html_encode(belly_data["mode"])
					if(new_mode in new_belly.digest_modes)
						new_belly.digest_mode = new_mode

				if(istext(belly_data["item_mode"])) //set the item mode of the vorebelly
					var/new_item_mode = html_encode(belly_data["item_mode"])
					if(new_item_mode in new_belly.item_digest_modes)
						new_belly.item_digest_mode = new_item_mode

				if(islist(belly_data["addons"]))
					new_belly.mode_flags = 0
					//new_belly.slow_digestion = FALSE
					STOP_PROCESSING(SSbellies, new_belly)
					STOP_PROCESSING(SSobj, new_belly)
					START_PROCESSING(SSbellies, new_belly)
					for(var/addon in belly_data["addons"])
						new_belly.mode_flags += new_belly.mode_flag_list[addon]
						//switch(addon) // Intent for future update; but does not currently exist in RS
							//if("Slow Body Digestion")
								//new_belly.slow_digestion = TRUE

				// Descriptions
				if(istext(belly_data["desc"]))
					var/new_desc = html_encode(belly_data["desc"])
					if(new_desc)
						new_desc = readd_quotes(new_desc)
					if(length(new_desc) > 0 && length(new_desc) <= BELLIES_DESC_MAX)
						new_belly.desc = new_desc
					else if(length(new_desc) > 0 && length(new_desc) >= BELLIES_DESC_MAX)
						tgui_alert_async(usr, "Invalid description for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(istext(belly_data["absorbed_desc"]))
					var/new_absorbed_desc = html_encode(belly_data["absorbed_desc"])
					if(new_absorbed_desc)
						new_absorbed_desc = readd_quotes(new_absorbed_desc)
					if(length(new_absorbed_desc) > 0 && length(new_absorbed_desc) <= BELLIES_DESC_MAX) //ensure belly description is within a valid length
						new_belly.absorbed_desc = new_absorbed_desc
					else if(length(new_absorbed_desc) > 0 && length(new_absorbed_desc) >= BELLIES_DESC_MAX) //if the description is too long and likely got truncated
						tgui_alert_async(usr, "Invalid absorbed description. It is likely too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(istext(belly_data["vore_verb"]))
					var/new_vore_verb = html_encode(belly_data["vore_verb"])
					if(new_vore_verb)
						new_vore_verb = readd_quotes(new_vore_verb)
					if(length(new_vore_verb) >= BELLIES_NAME_MIN && length(new_vore_verb) <= BELLIES_NAME_MAX)
						new_belly.vore_verb = new_vore_verb
					else if(length(new_vore_verb) >= BELLIES_NAME_MIN && length(new_vore_verb) >= BELLIES_NAME_MAX) //if it's too long
						tgui_alert_async(usr, "Invalid vore verb for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(istext(belly_data["release_verb"]))
					var/new_release_verb = html_encode(belly_data["release_verb"])
					if(new_release_verb)
						new_release_verb = readd_quotes(new_release_verb)
					if(length(new_release_verb) >= BELLIES_NAME_MIN && length(new_release_verb) <= BELLIES_NAME_MAX)
						new_belly.release_verb = new_release_verb
					else if(length(new_release_verb) >= BELLIES_NAME_MIN && length(new_release_verb) >= BELLIES_NAME_MAX) //if it it's too long
						tgui_alert_async(usr, "Invalid release verb for the " + belly_data["name"] + " vorebelly! It is likely too long. The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["digest_messages_prey"]))
					var/new_digest_messages_prey = sanitize(jointext(belly_data["digest_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_digest_messages_prey)
						new_belly.set_messages(new_digest_messages_prey,"dmp")
					else if(length(new_digest_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid prey digest messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["digest_messages_owner"]))
					var/new_digest_messages_owner = sanitize(jointext(belly_data["digest_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_digest_messages_owner)
						new_belly.set_messages(new_digest_messages_owner,"dmo")
					else if(length(new_digest_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid pred digest messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["absorb_messages_prey"]))
					var/new_absorb_messages_prey = sanitize(jointext(belly_data["absorb_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_absorb_messages_prey)
						new_belly.set_messages(new_absorb_messages_prey,"amp")
					else if(length(new_absorb_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid prey absorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["absorb_messages_owner"]))
					var/new_absorb_messages_owner = sanitize(jointext(belly_data["absorb_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_absorb_messages_owner)
						new_belly.set_messages(new_absorb_messages_owner,"amo")
					else if(length(new_absorb_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid prey absorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["unabsorb_messages_prey"]))
					var/new_unabsorb_messages_prey = sanitize(jointext(belly_data["unabsorb_messages_prey"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_unabsorb_messages_prey)
						new_belly.set_messages(new_unabsorb_messages_prey,"uamp")
					else if(length(new_unabsorb_messages_prey) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid prey unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["unabsorb_messages_owner"]))
					var/new_unabsorb_messages_owner = sanitize(jointext(belly_data["unabsorb_messages_owner"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_unabsorb_messages_owner)
						new_belly.set_messages(new_unabsorb_messages_owner,"uamo")
					else if(length(new_unabsorb_messages_owner) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid pred unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["struggle_messages_outside"]))
					var/new_struggle_messages_outside = sanitize(jointext(belly_data["struggle_messages_outside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_struggle_messages_outside)
						new_belly.set_messages(new_struggle_messages_outside,"smo")
					else if(length(new_struggle_messages_outside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid outside struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["struggle_messages_inside"]))
					var/new_struggle_messages_inside = sanitize(jointext(belly_data["struggle_messages_inside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_struggle_messages_inside)
						new_belly.set_messages(new_struggle_messages_inside,"smi")
					else if(length(new_struggle_messages_inside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid inside struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["absorbed_struggle_messages_outside"]))
					var/new_absorbed_struggle_messages_outside = sanitize(jointext(belly_data["absorbed_struggle_messages_outside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_absorbed_struggle_messages_outside)
						new_belly.set_messages(new_absorbed_struggle_messages_outside,"asmo")
					else if(length(new_absorbed_struggle_messages_outside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid outside absorbed struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["absorbed_struggle_messages_inside"]))
					var/new_absorbed_struggle_messages_inside = sanitize(jointext(belly_data["absorbed_struggle_messages_inside"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_absorbed_struggle_messages_inside)
						new_belly.set_messages(new_absorbed_struggle_messages_inside,"asmi")
					else if(length(new_absorbed_struggle_messages_inside) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid inside absorbed struggle messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["examine_messages"]))
					var/new_examine_messages = sanitize(jointext(belly_data["examine_messages"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_examine_messages)
						new_belly.set_messages(new_examine_messages,"em")
					else if(length(new_examine_messages) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid examine messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["examine_messages_absorbed"]))
					var/new_examine_messages_absorbed = sanitize(jointext(belly_data["examine_messages_absorbed"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_examine_messages_absorbed)
						new_belly.set_messages(new_examine_messages_absorbed,"ema")
					else if(length(new_examine_messages_absorbed) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid absorbed examine messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_digest"]))
					var/new_emotes_digest = sanitize(jointext(belly_data["emotes_digest"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_digest)
						new_belly.set_messages(new_emotes_digest,"im_digest")
					else if(length(new_emotes_digest) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid digestion messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_hold"]))
					var/new_emotes_hold = sanitize(jointext(belly_data["emotes_hold"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_hold)
						new_belly.set_messages(new_emotes_hold,"im_hold")
					else if(length(new_emotes_hold) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid holding messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_holdabsorbed"]))
					var/new_emotes_holdabsorbed = sanitize(jointext(belly_data["emotes_holdabsorbed"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_holdabsorbed)
						new_belly.set_messages(new_emotes_holdabsorbed,"im_holdabsorbed")
					else if(length(new_emotes_holdabsorbed) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid absorbed-holding messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_absorb"]))
					var/new_emotes_absorb = sanitize(jointext(belly_data["emotes_absorb"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_absorb)
						new_belly.set_messages(new_emotes_absorb,"im_absorb")
					else if(length(new_emotes_absorb) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid absorbing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_heal"]))
					var/new_emotes_heal = sanitize(jointext(belly_data["emotes_heal"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_heal)
						new_belly.set_messages(new_emotes_heal,"im_heal")
					else if(length(new_emotes_heal) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid healing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_drain"]))
					var/new_emotes_drain = sanitize(jointext(belly_data["emotes_drain"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_drain)
						new_belly.set_messages(new_emotes_drain,"im_drain")
					else if(length(new_emotes_drain) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid draining messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_steal"]))
					var/new_emotes_steal = sanitize(jointext(belly_data["emotes_steal"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_steal)
						new_belly.set_messages(new_emotes_steal,"im_steal")
					else if(length(new_emotes_steal) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid size stealing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_egg"]))
					var/new_emotes_egg = sanitize(jointext(belly_data["emotes_egg"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_egg)
						new_belly.set_messages(new_emotes_egg,"im_egg")
					else if(length(new_emotes_egg) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid egg messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_shrink"]))
					var/new_emotes_shrink = sanitize(jointext(belly_data["emotes_shrink"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_shrink)
						new_belly.set_messages(new_emotes_shrink,"im_shrink")
					else if(length(new_emotes_shrink) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid shrinking messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_grow"]))
					var/new_emotes_grow = sanitize(jointext(belly_data["emotes_grow"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_grow)
						new_belly.set_messages(new_emotes_grow,"im_grow")
					else if(length(new_emotes_grow) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid growing messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				if(islist(belly_data["emotes_unabsorb"]))
					var/new_emotes_unabsorb = sanitize(jointext(belly_data["emotes_unabsorb"],"\n\n"),MAX_MESSAGE_LEN,0,0,0)
					if(new_emotes_unabsorb)
						new_belly.set_messages(new_emotes_unabsorb,"im_unabsorb")
					else if(length(new_emotes_unabsorb) == MAX_MESSAGE_LEN) //if it's too long and likely got truncated
						tgui_alert_async(usr, "Invalid unabsorb messages. They are likely are too long for the " + belly_data["name"] + " vorebelly! The limit is 4096 characters.", "Error!") //Supply error message to the user

				// Options
				if(isnum(belly_data["can_taste"]))
					var/new_can_taste = belly_data["can_taste"]
					if(new_can_taste == 0)
						new_belly.can_taste = FALSE
					if(new_can_taste == 1)
						new_belly.can_taste = TRUE

				if(isnum(belly_data["contaminates"]))
					var/new_contaminates = belly_data["contaminates"]
					if(new_contaminates == 0)
						new_belly.contaminates = FALSE
					if(new_contaminates == 1)
						new_belly.contaminates = TRUE

				if(istext(belly_data["contamination_flavor"]))
					var/new_contamination_flavor = sanitize(belly_data["contamination_flavor"],MAX_MESSAGE_LEN,0,0,0)
					if(new_contamination_flavor)
						if(new_contamination_flavor in contamination_flavors)
							new_belly.contamination_flavor = new_contamination_flavor

				if(istext(belly_data["contamination_color"]))
					var/new_contamination_color = sanitize(belly_data["contamination_color"],MAX_MESSAGE_LEN,0,0,0)
					if(new_contamination_color)
						if(new_contamination_color in contamination_colors)
							new_belly.contamination_color = new_contamination_color

				if(isnum(belly_data["nutrition_percent"]))
					var/new_nutrition_percent = belly_data["nutrition_percent"]
					new_belly.nutrition_percent = CLAMP(new_nutrition_percent,0.01,100)

				if(isnum(belly_data["bulge_size"]))
					var/new_bulge_size = belly_data["bulge_size"]
					if(new_bulge_size == 0)
						new_belly.bulge_size = 0
					else
						new_belly.bulge_size = CLAMP(new_bulge_size,0.25,2)

				if(isnum(belly_data["display_absorbed_examine"]))
					var/new_display_absorbed_examine = belly_data["display_absorbed_examine"]
					if(new_display_absorbed_examine == 0)
						new_belly.display_absorbed_examine = FALSE
					if(new_display_absorbed_examine == 1)
						new_belly.display_absorbed_examine = TRUE

				if(isnum(belly_data["save_digest_mode"]))
					var/new_save_digest_mode = belly_data["save_digest_mode"]
					if(new_save_digest_mode == 0)
						new_belly.save_digest_mode = FALSE
					if(new_save_digest_mode == 1)
						new_belly.save_digest_mode = TRUE

				if(isnum(belly_data["emote_active"]))
					var/new_emote_active = belly_data["emote_active"]
					if(new_emote_active == 0)
						new_belly.emote_active = FALSE
					if(new_emote_active == 1)
						new_belly.emote_active = TRUE

				if(isnum(belly_data["emote_time"]))
					var/new_emote_time = belly_data["emote_time"]
					new_belly.emote_time = CLAMP(new_emote_time, 60, 600)

				if(isnum(belly_data["digest_brute"]))
					var/new_digest_brute = belly_data["digest_brute"]
					new_belly.digest_brute = CLAMP(new_digest_brute, 0, 6)

				if(isnum(belly_data["digest_burn"]))
					var/new_digest_burn = belly_data["digest_burn"]
					new_belly.digest_burn = CLAMP(new_digest_burn, 0, 6)

				if(isnum(belly_data["digest_oxy"]))
					var/new_digest_oxy = belly_data["digest_oxy"]
					new_belly.digest_oxy = CLAMP(new_digest_oxy, 0, 12)

				if(isnum(belly_data["digest_tox"]))
					var/new_digest_tox = belly_data["digest_tox"]
					new_belly.digest_tox = CLAMP(new_digest_tox, 0, 6)

				if(isnum(belly_data["digest_clone"]))
					var/new_digest_clone = belly_data["digest_clone"]
					new_belly.digest_clone = CLAMP(new_digest_clone, 0, 6)

				if(isnum(belly_data["shrink_grow_size"]))
					var/new_shrink_grow_size = belly_data["shrink_grow_size"]
					new_belly.shrink_grow_size = CLAMP(new_shrink_grow_size, 0.25, 2)

				if(istext(belly_data["egg_type"]))
					var/new_egg_type = sanitize(belly_data["egg_type"],MAX_MESSAGE_LEN,0,0,0)
					if(new_egg_type)
						if(new_egg_type in global_vore_egg_types)
							new_belly.egg_type = new_egg_type

				if(istext(belly_data["selective_preference"]))
					var/new_selective_preference = belly_data["selective_preference"]
					if(new_selective_preference == "Digest")
						new_belly.selective_preference = DM_DIGEST
					if(new_selective_preference == "Absorb")
						new_belly.selective_preference = DM_ABSORB

				// Sounds
				if(isnum(belly_data["is_wet"]))
					var/new_is_wet = belly_data["is_wet"]
					if(new_is_wet == 0)
						new_belly.is_wet = FALSE
					if(new_is_wet == 1)
						new_belly.is_wet = TRUE

				if(isnum(belly_data["wet_loop"]))
					var/new_wet_loop = belly_data["wet_loop"]
					if(new_wet_loop == 0)
						new_belly.wet_loop = FALSE
					if(new_wet_loop == 1)
						new_belly.wet_loop = TRUE

				if(isnum(belly_data["fancy_vore"]))
					var/new_fancy_vore = belly_data["fancy_vore"]
					if(new_fancy_vore == 0)
						new_belly.fancy_vore = FALSE
					if(new_fancy_vore == 1)
						new_belly.fancy_vore = TRUE

				//Set vore sounds, if they exist. Otherwise set to default gulp/splatter for insert/release
				if(new_belly.fancy_vore)
					if(!(new_belly.vore_sound in fancy_vore_sounds))
						new_belly.vore_sound = "Gulp"
					if(!(new_belly.release_sound in fancy_vore_sounds))
						new_belly.release_sound = "Splatter"
				else
					if(!(new_belly.vore_sound in classic_vore_sounds))
						new_belly.vore_sound = "Gulp"
					if(!(new_belly.release_sound in classic_vore_sounds))
						new_belly.release_sound = "Splatter"

				if(istext(belly_data["vore_sound"]))
					var/new_vore_sound = sanitize(belly_data["vore_sound"],MAX_MESSAGE_LEN,0,0,0)
					if(new_vore_sound)
						if (new_belly.fancy_vore && (new_vore_sound in fancy_vore_sounds))
							new_belly.vore_sound = new_vore_sound
						if (!new_belly.fancy_vore && (new_vore_sound in classic_vore_sounds))
							new_belly.vore_sound = new_vore_sound

				if(istext(belly_data["release_sound"]))
					var/new_release_sound = sanitize(belly_data["release_sound"],MAX_MESSAGE_LEN,0,0,0)
					if(new_release_sound)
						if (new_belly.fancy_vore && (new_release_sound in fancy_release_sounds))
							new_belly.release_sound = new_release_sound
						if (!new_belly.fancy_vore && (new_release_sound in classic_release_sounds))
							new_belly.release_sound = new_release_sound

				// Visuals
				if(isnum(belly_data["affects_vore_sprites"]))
					var/new_affects_vore_sprites = belly_data["affects_vore_sprites"]
					if(new_affects_vore_sprites == 0)
						new_belly.affects_vore_sprites = FALSE
					if(new_affects_vore_sprites == 1)
						new_belly.affects_vore_sprites = TRUE

				if(isnum(belly_data["count_absorbed_prey_for_sprite"]))
					var/new_count_absorbed_prey_for_sprite = belly_data["count_absorbed_prey_for_sprite"]
					if(new_count_absorbed_prey_for_sprite == 0)
						new_belly.count_absorbed_prey_for_sprite = FALSE
					if(new_count_absorbed_prey_for_sprite == 1)
						new_belly.count_absorbed_prey_for_sprite = TRUE

				if(isnum(belly_data["absorbed_multiplier"]))
					var/new_absorbed_multiplier = belly_data["absorbed_multiplier"]
					new_belly.absorbed_multiplier = CLAMP(new_absorbed_multiplier, 0.1, 3)

				if(isnum(belly_data["count_liquid_for_sprite"]))
					var/new_count_liquid_for_sprite = belly_data["count_liquid_for_sprite"]
					if(new_count_liquid_for_sprite == 0)
						new_belly.count_liquid_for_sprite = FALSE
					if(new_count_liquid_for_sprite == 1)
						new_belly.count_liquid_for_sprite = TRUE

				if(isnum(belly_data["liquid_multiplier"]))
					var/new_liquid_multiplier = belly_data["liquid_multiplier"]
					new_belly.liquid_multiplier = CLAMP(new_liquid_multiplier, 0.1, 10)

				if(isnum(belly_data["reagent_touches"])) //Reagent bellies || RS Add || Chomp Port
					var/new_reagent_touches = belly_data["reagent_touches"]
					if(new_reagent_touches == 0)
						new_belly.reagent_touches = FALSE
					if(new_reagent_touches == 1)
						new_belly.reagent_touches = TRUE

				if(isnum(belly_data["count_items_for_sprite"]))
					var/new_count_items_for_sprite = belly_data["count_items_for_sprite"]
					if(new_count_items_for_sprite == 0)
						new_belly.count_items_for_sprite = FALSE
					if(new_count_items_for_sprite == 1)
						new_belly.count_items_for_sprite = TRUE

				if(isnum(belly_data["item_multiplier"]))
					var/new_item_multiplier = belly_data["item_multiplier"]
					new_belly.item_multiplier = CLAMP(new_item_multiplier, 0.1, 10)

				if(isnum(belly_data["health_impacts_size"]))
					var/new_health_impacts_size = belly_data["health_impacts_size"]
					if(new_health_impacts_size == 0)
						new_belly.health_impacts_size = FALSE
					if(new_health_impacts_size == 1)
						new_belly.health_impacts_size = TRUE

				if(isnum(belly_data["resist_triggers_animation"]))
					var/new_resist_triggers_animation = belly_data["resist_triggers_animation"]
					if(new_resist_triggers_animation == 0)
						new_belly.resist_triggers_animation = FALSE
					if(new_resist_triggers_animation == 1)
						new_belly.resist_triggers_animation = TRUE

				if(isnum(belly_data["size_factor_for_sprite"])) //how large the vore-sprite is
					var/new_size_factor_for_sprite = belly_data["size_factor_for_sprite"]
					new_belly.size_factor_for_sprite = CLAMP(new_size_factor_for_sprite, 0.1, 3)

				if(istext(belly_data["belly_sprite_to_affect"]))
					var/new_belly_sprite_to_affect = sanitize(belly_data["belly_sprite_to_affect"],MAX_MESSAGE_LEN,0,0,0)
					if(istype(host, /mob/living/carbon/human)) //workaround for vore belly sprites
						var/mob/living/carbon/human/hhost = host
						if(new_belly_sprite_to_affect)
							if(new_belly_sprite_to_affect in hhost.vore_icon_bellies) //determine if it is normal or taur belly
								new_belly.belly_sprite_to_affect = new_belly_sprite_to_affect

				//determine if the HUD is to be disabled for the person inside or not
				if(isnum(belly_data["disable_hud"]))
					var/new_disable_hud = belly_data["disable_hud"]
					if(new_disable_hud == 0)
						new_belly.disable_hud = FALSE
					if(new_disable_hud == 1)
						new_belly.disable_hud = TRUE

				//set the vore belly overlay
				var/possible_fullscreens = icon_states('icons/mob/screen_full_colorized_vore.dmi')
				if(!new_belly.colorization_enabled)
					possible_fullscreens = icon_states('icons/mob/screen_full_vore.dmi')
					possible_fullscreens -= "a_synth_flesh_mono"
					possible_fullscreens -= "a_synth_flesh_mono_hole"
					possible_fullscreens -= "a_anim_belly"
				if(!(new_belly.belly_fullscreen in possible_fullscreens))
					new_belly.belly_fullscreen = ""
				else
					tgui_alert_async(usr, "Invalid vorebelly overlay for the " + belly_data["name"] + " vorebelly!", "Error!") //Supply error message to the us

				// Interactions
				if(isnum(belly_data["escapable"]))
					var/new_escapable = belly_data["escapable"]
					if(new_escapable == 0)
						new_belly.escapable = FALSE
					if(new_escapable == 1)
						new_belly.escapable = TRUE

				if(isnum(belly_data["escapechance"]))
					var/new_escapechance = belly_data["escapechance"]
					new_belly.escapechance = sanitize_integer(new_escapechance, 0, 100, initial(new_belly.escapechance))

				if(isnum(belly_data["escapetime"]))
					var/new_escapetime = belly_data["escapetime"]
					new_belly.escapetime = sanitize_integer(new_escapetime*10, 10, 600, initial(new_belly.escapetime))

				if(isnum(belly_data["transferchance"]))
					var/new_transferchance = belly_data["transferchance"]
					new_belly.transferchance = sanitize_integer(new_transferchance, 0, 100, initial(new_belly.transferchance))

				if(istext(belly_data["transferlocation"]))
					var/new_transferlocation = sanitize(belly_data["transferlocation"],MAX_MESSAGE_LEN,0,0,0)
					if(new_transferlocation)
						for(var/obj/belly/existing_belly in host.vore_organs) //if the transfer location currently exists
							if(existing_belly.name == new_transferlocation)
								new_belly.transferlocation = new_transferlocation
								break
						if(new_transferlocation in valid_names)
							new_belly.transferlocation = new_transferlocation
						if(new_transferlocation == new_belly.name) //if the transfer location is to this belly
							new_belly.transferlocation = null

				if(isnum(belly_data["transferchance_secondary"]))
					var/new_transferchance_secondary = belly_data["transferchance_secondary"]
					new_belly.transferchance_secondary = sanitize_integer(new_transferchance_secondary, 0, 100, initial(new_belly.transferchance_secondary))

				if(istext(belly_data["transferlocation_secondary"]))
					var/new_transferlocation_secondary = sanitize(belly_data["transferlocation_secondary"],MAX_MESSAGE_LEN,0,0,0)
					if(new_transferlocation_secondary)
						for(var/obj/belly/existing_belly in host.vore_organs)
							if(existing_belly.name == new_transferlocation_secondary)
								new_belly.transferlocation_secondary = new_transferlocation_secondary
								break
						if(new_transferlocation_secondary in valid_names)
							new_belly.transferlocation_secondary = new_transferlocation_secondary
						if(new_transferlocation_secondary == new_belly.name)
							new_belly.transferlocation_secondary = null

				if(isnum(belly_data["absorbchance"]))
					var/new_absorbchance = belly_data["absorbchance"]
					new_belly.absorbchance = sanitize_integer(new_absorbchance, 0, 100, initial(new_belly.absorbchance))

				if(isnum(belly_data["digestchance"]))
					var/new_digestchance = belly_data["digestchance"]
					new_belly.digestchance = sanitize_integer(new_digestchance, 0, 100, initial(new_belly.digestchance))

				if(istext(belly_data["custom_reagentcolor"])) // Liquid bellies || RS Add || Chomp Port
					var/custom_reagentcolor = sanitize_hexcolor(belly_data["custom_reagentcolor"],new_belly.custom_reagentcolor)
					new_belly.custom_reagentcolor = custom_reagentcolor

				if(istext(belly_data["mush_color"]))
					var/mush_color = sanitize_hexcolor(belly_data["mush_color"],new_belly.mush_color)
					new_belly.mush_color = mush_color

				if(istext(belly_data["mush_alpha"]))
					var/new_mush_alpha = sanitize_integer(belly_data["mush_alpha"],0,255,initial(new_belly.mush_alpha))
					new_belly.mush_alpha = new_mush_alpha

				if(isnum(belly_data["max_mush"]))
					var/max_mush = belly_data["max_mush"]
					new_belly.max_mush = CLAMP(max_mush, 0, 6000)

				if(isnum(belly_data["min_mush"]))
					var/min_mush = belly_data["min_mush"]
					new_belly.min_mush = CLAMP(min_mush, 0, 100)

				if(isnum(belly_data["liquid_overlay"]))
					var/new_liquid_overlay = belly_data["liquid_overlay"]
					if(new_liquid_overlay == 0)
						new_belly.liquid_overlay = FALSE
					if(new_liquid_overlay == 1)
						new_belly.liquid_overlay = TRUE

				if(isnum(belly_data["max_liquid_level"]))
					var/max_liquid_level = belly_data["max_liquid_level"]
					new_belly.max_liquid_level = CLAMP(max_liquid_level, 0, 100)

				if(isnum(belly_data["mush_overlay"]))
					var/new_mush_overlay = belly_data["mush_overlay"]
					if(new_mush_overlay == 0)
						new_belly.mush_overlay = FALSE
					if(new_mush_overlay == 1)
						new_belly.mush_overlay = TRUE // End liquid bellies

				// After import updates
				new_belly.items_preserved.Cut()

			if(istype(host, /mob/living/carbon/human))
				var/mob/living/carbon/human/hhost = host
				hhost.update_fullness()
			host.updateVRPanel()
			unsaved_changes = TRUE
			return TRUE

//RS ADD END

		if("bellypick")
			host.vore_selected = locate(params["bellypick"])
			return TRUE
		if("move_belly")
			var/dir = text2num(params["dir"])
			if(LAZYLEN(host.vore_organs) <= 1)
				to_chat(usr, "<span class='warning'>You can't sort bellies with only one belly to sort...</span>")
				return TRUE

			var/current_index = host.vore_organs.Find(host.vore_selected)
			if(current_index)
				var/new_index = clamp(current_index + dir, 1, LAZYLEN(host.vore_organs))
				host.vore_organs.Swap(current_index, new_index)
				unsaved_changes = TRUE
			return TRUE

		if("set_attribute")
			return set_attr(usr, params)

		if("saveprefs")
			if(isnewplayer(host))
				var/choice = tgui_alert(usr, "Warning: Saving your vore panel while in the lobby will save it to the CURRENTLY LOADED character slot, and potentially overwrite it. Are you SURE you want to overwrite your current slot with these vore bellies?", "WARNING!", list("No, abort!", "Yes, save."))
				if(choice != "Yes, save.")
					return TRUE
			else if(host.real_name != host.client.prefs.real_name || (!ishuman(host) && !issilicon(host)))
				var/choice = tgui_alert(usr, "Warning: Saving your vore panel while playing what is very-likely not your normal character will overwrite whatever character you have loaded in character setup. Maybe this is your 'playing a simple mob' slot, though. Are you SURE you want to overwrite your current slot with these vore bellies?", "WARNING!", list("No, abort!", "Yes, save."))
				if(choice != "Yes, save.")
					return TRUE
			if(!host.save_vore_prefs())
				tgui_alert_async(usr, "ERROR: Virgo-specific preferences failed to save!","Error")
			else
				to_chat(usr, "<span class='notice'>Virgo-specific preferences saved!</span>")
				unsaved_changes = FALSE
			return TRUE
		if("reloadprefs")
			var/alert = tgui_alert(usr, "Are you sure you want to reload character slot preferences? This will remove your current vore organs and eject their contents.","Confirmation",list("Reload","Cancel"))
			if(alert != "Reload")
				return FALSE
			if(!host.apply_vore_prefs())
				tgui_alert_async(usr, "ERROR: Virgo-specific preferences failed to apply!","Error")
			else
				to_chat(usr,"<span class='notice'>Virgo-specific preferences applied from active slot!</span>")
				unsaved_changes = FALSE
			return TRUE
		if("exportpanel")
			var/mob/living/user = usr
			if(!user)
				to_chat(usr,"<span class='notice'>Mob undefined: [user]</span>")
				return FALSE

			var/datum/vore_look/export_panel/exportPanel
			if(!exportPanel)
				exportPanel = new(usr)

			if(!exportPanel)
				to_chat(user,"<span class='notice'>Export panel undefined: [exportPanel]</span>")
				return FALSE

			exportPanel.open_export_panel(user)

			return TRUE
		if("setflavor")
			var/new_flavor = html_encode(tgui_input_text(usr,"What your character tastes like (400ch limit). This text will be printed to the pred after 'X tastes of...' so just put something like 'strawberries and cream':","Character Flavor",host.vore_taste))
			if(!new_flavor)
				return FALSE

			new_flavor = readd_quotes(new_flavor)
			if(length(new_flavor) > FLAVOR_MAX)
				tgui_alert_async(usr, "Entered flavor/taste text too long. [FLAVOR_MAX] character limit.","Error!")
				return FALSE
			host.vore_taste = new_flavor
			unsaved_changes = TRUE
			return TRUE
		if("setsmell")
			var/new_smell = html_encode(tgui_input_text(usr,"What your character smells like (400ch limit). This text will be printed to the pred after 'X smells of...' so just put something like 'strawberries and cream':","Character Smell",host.vore_smell))
			if(!new_smell)
				return FALSE

			new_smell = readd_quotes(new_smell)
			if(length(new_smell) > FLAVOR_MAX)
				tgui_alert_async(usr, "Entered perfume/smell text too long. [FLAVOR_MAX] character limit.","Error!")
				return FALSE
			host.vore_smell = new_smell
			unsaved_changes = TRUE
			return TRUE
		if("toggle_dropnom_pred")
			host.can_be_drop_pred = !host.can_be_drop_pred
			if(host.client.prefs_vr)
				host.client.prefs_vr.can_be_drop_pred = host.can_be_drop_pred
			unsaved_changes = TRUE
			return TRUE
		if("toggle_dropnom_prey")
			host.can_be_drop_prey = !host.can_be_drop_prey
			if(host.client.prefs_vr)
				host.client.prefs_vr.can_be_drop_prey = host.can_be_drop_prey
			unsaved_changes = TRUE
			return TRUE
		if("toggle_allow_inbelly_spawning")
			host.allow_inbelly_spawning = !host.allow_inbelly_spawning
			if(host.client.prefs_vr)
				host.client.prefs_vr.allow_inbelly_spawning = host.allow_inbelly_spawning
			unsaved_changes = TRUE
			return TRUE
		if("toggle_allow_spontaneous_tf")
			host.allow_spontaneous_tf = !host.allow_spontaneous_tf
			if(host.client.prefs_vr)
				host.client.prefs_vr.allow_spontaneous_tf = host.allow_spontaneous_tf
			unsaved_changes = TRUE
			return TRUE
		if("toggle_digest")
			host.digestable = !host.digestable
			if(host.client.prefs_vr)
				host.client.prefs_vr.digestable = host.digestable
			unsaved_changes = TRUE
			return TRUE
		if("toggle_global_privacy")
			host.eating_privacy_global = !host.eating_privacy_global
			if(host.client.prefs_vr)
				host.eating_privacy_global = host.eating_privacy_global
			unsaved_changes = TRUE
			return TRUE
		if("toggle_devour")
			host.devourable = !host.devourable
			if(host.client.prefs_vr)
				host.client.prefs_vr.devourable = host.devourable
			unsaved_changes = TRUE
			return TRUE
		if("toggle_resize")
			host.resizable = !host.resizable
			if(host.client.prefs_vr)
				host.client.prefs_vr.resizable = host.resizable
			unsaved_changes = TRUE
			return TRUE
		if("toggle_feed")
			host.feeding = !host.feeding
			if(host.client.prefs_vr)
				host.client.prefs_vr.feeding = host.feeding
			unsaved_changes = TRUE
			return TRUE
		if("toggle_absorbable")
			host.absorbable = !host.absorbable
			if(host.client.prefs_vr)
				host.client.prefs_vr.absorbable = host.absorbable
			unsaved_changes = TRUE
			return TRUE
		if("toggle_leaveremains")
			host.digest_leave_remains = !host.digest_leave_remains
			if(host.client.prefs_vr)
				host.client.prefs_vr.digest_leave_remains = host.digest_leave_remains
			unsaved_changes = TRUE
			return TRUE
		if("toggle_mobvore")
			host.allowmobvore = !host.allowmobvore
			if(host.client.prefs_vr)
				host.client.prefs_vr.allowmobvore = host.allowmobvore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_steppref")
			host.step_mechanics_pref = !host.step_mechanics_pref
			if(host.client.prefs_vr)
				host.client.prefs_vr.step_mechanics_pref = host.step_mechanics_pref
			unsaved_changes = TRUE
			return TRUE
		if("toggle_pickuppref")
			host.pickup_pref = !host.pickup_pref
			if(host.client.prefs_vr)
				host.client.prefs_vr.pickup_pref = host.pickup_pref
			unsaved_changes = TRUE
			return TRUE
		if("toggle_healbelly")
			host.permit_healbelly = !host.permit_healbelly
			if(host.client.prefs_vr)
				host.client.prefs_vr.permit_healbelly = host.permit_healbelly
			unsaved_changes = TRUE
			return TRUE
		if("toggle_fx")
			host.show_vore_fx = !host.show_vore_fx
			if(host.client.prefs_vr)
				host.client.prefs_vr.show_vore_fx = host.show_vore_fx
			if(!host.show_vore_fx)
				host.clear_fullscreen("belly")
				host.clear_fullscreen("belly2")
				host.clear_fullscreen("belly3")
				host.clear_fullscreen("belly4")
				host.clear_fullscreen("belly5") // Reagent bellies || RS Add || Chomp Port
				if(!host.hud_used.hud_shown)
					host.toggle_hud_vis()
			unsaved_changes = TRUE
			return TRUE
		if("toggle_noisy")
			host.noisy = !host.noisy
			unsaved_changes = TRUE
			return TRUE
		// Begin reagent bellies || RS Add || Chomp Port
		if("liq_set_attribute")
			return liq_set_attr(usr, params)
		if("liq_set_messages")
			return liq_set_msg(usr, params)
		// End reagent bellies
		if("toggle_autotransferable") //RS Add Start || Port Chomp 3200
			host.autotransferable = !host.autotransferable
			if(host.client.prefs_vr)
				host.client.prefs_vr.autotransferable = host.autotransferable
			unsaved_changes = TRUE
			return TRUE //RS Add End
		if("toggle_drop_vore")
			host.drop_vore = !host.drop_vore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_slip_vore")
			host.slip_vore = !host.slip_vore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_stumble_vore")
			host.stumble_vore = !host.stumble_vore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_throw_vore")
			host.throw_vore = !host.throw_vore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_food_vore")
			host.food_vore = !host.food_vore
			unsaved_changes = TRUE
			return TRUE
		if("switch_selective_mode_pref")
			host.selective_preference = tgui_input_list(usr, "What would you prefer happen to you with selective bellymode?","Selective Bellymode", list(DM_DEFAULT, DM_DIGEST, DM_ABSORB, DM_DRAIN))
			if(!(host.selective_preference))
				host.selective_preference = DM_DEFAULT
			if(host.client.prefs_vr)
				host.client.prefs_vr.selective_preference = host.selective_preference
			unsaved_changes = TRUE
			return TRUE
		if("toggle_nutrition_ex")
			host.nutrition_message_visible = !host.nutrition_message_visible
			unsaved_changes = TRUE
			return TRUE
		if("toggle_weight_ex")
			host.weight_message_visible = !host.weight_message_visible
			unsaved_changes = TRUE
			return TRUE
		// Begin RS edit
		if("set_vs_color")
			if (istype(host, /mob/living/carbon/human))
				var/mob/living/carbon/human/hhost = host
				var/belly_choice = tgui_input_list(usr, "Which vore sprite are you going to edit the color of?", "Vore Sprite Color", hhost.vore_icon_bellies)
				var/newcolor = input(usr, "Choose a color.", "", hhost.vore_sprite_color[belly_choice]) as color|null
				if(newcolor)
					hhost.vore_sprite_color[belly_choice] = newcolor
					hhost.update_icons_body()
				return TRUE
		if("toggle_allowcontamination")
			if (istype(host, /mob/living/carbon/human))
				var/mob/living/carbon/human/hhost = host
				hhost.allow_contaminate = !hhost.allow_contaminate
				if(host.client.prefs_vr)
					host.client.prefs_vr.allow_contaminate = hhost.allow_contaminate
				unsaved_changes = TRUE
				return TRUE
		if("toggle_allowstripping")
			if (istype(host, /mob/living/carbon/human))
				var/mob/living/carbon/human/hhost = host
				hhost.allow_stripping = !hhost.allow_stripping
				if(host.client.prefs_vr)
					host.client.prefs_vr.allow_stripping = hhost.allow_stripping
				unsaved_changes = TRUE
				return TRUE
		if("toggle_allowssdvore")
			host.ssd_vore = !host.ssd_vore
			if(host.client.prefs_vr)
				host.client.prefs_vr.ssd_vore = host.ssd_vore
			unsaved_changes = TRUE
			return TRUE
		if("toggle_glow")
			host.glowy_belly = !host.glowy_belly
			if(host.client.prefs_vr)
				host.client.prefs_vr.glowy_belly = host.client.prefs_vr.glowy_belly
			unsaved_changes = TRUE
			host.update_icon()
			if(istype(host, /mob/living/carbon/human))
				var/mob/living/carbon/human/our_owner = host
				our_owner.update_vore_belly_sprite()
				our_owner.update_vore_tail_sprite()
			return TRUE
		// End RS edit

/datum/vore_look/proc/pick_from_inside(mob/user, params)
	var/atom/movable/target = locate(params["pick"])
	var/obj/belly/OB = locate(params["belly"])

	if(!(target in OB))
		return TRUE // Aren't here anymore, need to update menu

	var/intent = "Examine"
	if(isliving(target))
		intent = tgui_alert(usr, "What do you want to do to them?","Query",list("Examine","Healthbar","Help Out","Devour"))	//RS EDIT

	else if(istype(target, /obj/item))
		intent = tgui_alert(usr, "What do you want to do to that?","Query",list("Examine","Use Hand"))

	switch(intent)
		if("Examine") //Examine a mob inside another mob
			var/list/results = target.examine(host)
			if(!results || !results.len)
				results = list("You were unable to examine that. Tell a developer!")
			to_chat(user, jointext(results, "<br>"))
			return TRUE

		if("Use Hand")
			if(host.stat)
				to_chat(user, "<span class='warning'>You can't do that in your state!</span>")
				return TRUE

			host.ClickOn(target)
			return TRUE

	if(!isliving(target))
		return

	var/mob/living/M = target
	switch(intent)
		if("Help Out") //Help the inside-mob out
			if(host.stat || host.absorbed || M.absorbed)
				to_chat(user, "<span class='warning'>You can't do that in your state!</span>")
				return TRUE

			to_chat(user,"<font color='green'>You begin to push [M] to freedom!</font>")
			to_chat(M,"[host] begins to push you to freedom!")
			to_chat(OB.owner,"<span class='warning'>Someone is trying to escape from inside you!</span>")
			sleep(50)
			if(prob(33))
				OB.release_specific_contents(M)
				to_chat(user,"<font color='green'>You manage to help [M] to safety!</font>")
				to_chat(M,"<font color='green'>[host] pushes you free!</font>")
				to_chat(OB.owner,"<span class='alert'>[M] forces free of the confines of your body!</span>")
			else
				to_chat(user,"<span class='alert'>[M] slips back down inside despite your efforts.</span>")
				to_chat(M,"<span class='alert'> Even with [host]'s help, you slip back inside again.</span>")
				to_chat(OB.owner,"<font color='green'>Your body efficiently shoves [M] back where they belong.</font>")
			return TRUE

		if("Devour") //Eat the inside mob
			if(host.absorbed || host.stat)
				to_chat(user,"<span class='warning'>You can't do that in your state!</span>")
				return TRUE

			if(!host.vore_selected)
				to_chat(user,"<span class='warning'>Pick a belly on yourself first!</span>")
				return TRUE

			var/obj/belly/TB = host.vore_selected
			to_chat(user,"<span class='warning'>You begin to [lowertext(TB.vore_verb)] [M] into your [lowertext(TB.name)]!</span>")
			to_chat(M,"<span class='warning'>[host] begins to [lowertext(TB.vore_verb)] you into their [lowertext(TB.name)]!</span>")
			to_chat(OB.owner,"<span class='warning'>Someone inside you is eating someone else!</span>")

			sleep(TB.nonhuman_prey_swallow_time) //Can't do after, in a stomach, weird things abound.
			if((host in OB) && (M in OB)) //Make sure they're still here.
				to_chat(user,"<span class='warning'>You manage to [lowertext(TB.vore_verb)] [M] into your [lowertext(TB.name)]!</span>")
				to_chat(M,"<span class='warning'>[host] manages to [lowertext(TB.vore_verb)] you into their [lowertext(TB.name)]!</span>")
				to_chat(OB.owner,"<span class='warning'>Someone inside you has eaten someone else!</span>")
				if(M.absorbed)
					M.absorbed = FALSE
					OB.handle_absorb_langs(M, OB.owner)
				TB.nom_mob(M)
		if("Healthbar")			//RS ADD
			new /obj/screen/movable/rs_ui/healthbar(user,target,user)	//RS ADD

/datum/vore_look/proc/pick_from_outside(mob/user, params)
	var/intent

	if(params["pickall"])
		intent = tgui_alert(user, "You are affecting all [lowertext(host.vore_selected)] contents with this choice.","[uppertext(host.vore_selected)] contents management",list("Eject all","Move all","Advance all","Cancel"))
		switch(intent)
			if("Cancel")
				return TRUE

			if("Eject all")
				if(host.stat)
					to_chat(user,"<span class='warning'>You can't do that in your state!</span>")
					return TRUE
				//RS ADD START
				var/bones_detected = FALSE
				var/bone_time = FALSE
				for(var/thing in host.vore_selected.contents)
					if(istype(thing, /obj/item/weapon/digestion_remains))
						bones_detected = TRUE
						break
				if(bones_detected)
					if(tgui_alert(user, "Do you want to include the remains that are inside your [lowertext(host.vore_selected)]?","",list("Yes","No")) == "Yes")
						bone_time = TRUE
				//RS ADD END

				host.vore_selected.release_all_contents(include_bones = bone_time)	//RS EDIT
				return TRUE

			if("Move all")
				if(host.stat)
					to_chat(user,"<span class='warning'>You can't do that in your state!</span>")
					return TRUE

				var/obj/belly/choice = tgui_input_list(user, "Move all where?","Select Belly", host.vore_organs)
				if(!choice)
					return FALSE

				for(var/atom/movable/target in host.vore_selected)
					to_chat(target,"<span class='warning'>You're squished from [host]'s [host.vore_selected] to their [lowertext(choice.name)]!</span>")
					host.vore_selected.transfer_contents(target, choice, 1)
				return TRUE
			//RS ADD START
			if("Advance all")
				if(host.stat)
					to_chat(user,"<span class='warning'>You can't do that in your state!</span>")
					return TRUE
				var/list/choices = list()
				var/obj/belly/choice
				for(var/obj/belly/b in host.vore_organs)
					if(b.name == host.vore_selected.transferlocation || b.name == host.vore_selected.transferlocation_secondary)
						choices += b
				if(!choices.len)
					to_chat(user,"<span class='warning'>You haven't configured any transfer locations for your [lowertext(host.vore_selected)]. Please configure at least one transfer location in order to advance your [lowertext(host.vore_selected)]'s contents.</span>")
				else
					choice = tgui_input_list(user, "Advance your [lowertext(host.vore_selected)]'s contents to which belly?","Select Belly", choices)

				if(!choice)
					return TRUE

				for(var/atom/movable/target in host.vore_selected)
					to_chat(target,"<span class='warning'>You're squished from [host]'s [lowertext(host.vore_selected)] to their [lowertext(choice.name)]!</span>")
					host.vore_selected.transfer_contents(target, choice, 1)
				return TRUE
			//RS ADD END
		return

	var/atom/movable/target = locate(params["pick"])
	if(!(target in host.vore_selected))
		return TRUE // Not in our X anymore, update UI
	var/list/available_options = list("Examine", "Eject", "Move", "Advance", "Transfer")	//RS EDIT
	if(ishuman(target))
		available_options += "Transform"
	if(isliving(target))
		var/mob/living/datarget = target
		available_options += "Health Bar"	//RS ADD
		available_options += "Print Health Bar"	//RS ADD
		if(datarget.client)
			available_options += "Process"
	intent = tgui_input_list(user, "What would you like to do with [target]?", "Vore Pick", available_options)
	switch(intent)
		if("Examine")	//RS EDIT START - Generalized BABY
			host.vore_selected.examine_target(target,user)
			return TRUE
		if("Eject")
			host.vore_selected.eject_target(target)
			return TRUE
		if("Move")
			host.vore_selected.move_target(target)
			return TRUE
		if("Transfer")
			host.vore_selected.transfer_target(target)
			return TRUE
		if("Transform")
			host.vore_selected.transform_target(target)
			return TRUE
		if("Process")
			host.vore_selected.process_target(target)
			return TRUE
		if("Advance")
			host.vore_selected.advance_target(target)
			return TRUE
		if("Health Bar")
			if(isliving(target))
				host.vore_selected.healthbar_target(target)
			return TRUE
		if("Print Health Bar")
			if(isliving(target))
				var/mob/living/L = target
				L.chat_healthbar(host)
			return TRUE
		//RS EDIT END

/datum/vore_look/proc/set_attr(mob/user, params)
	if(!host.vore_selected)
		tgui_alert_async(usr, "No belly selected to modify.")
		return FALSE

	var/attr = params["attribute"]
	switch(attr)
		if("b_name")
			var/new_name = html_encode(tgui_input_text(usr,"Belly's new name:","New Name"))

			var/failure_msg
			if(length(new_name) > BELLIES_NAME_MAX || length(new_name) < BELLIES_NAME_MIN)
				failure_msg = "Entered belly name length invalid (must be longer than [BELLIES_NAME_MIN], no more than than [BELLIES_NAME_MAX])."
			// else if(whatever) //Next test here.
			else
				for(var/obj/belly/B as anything in host.vore_organs)
					if(lowertext(new_name) == lowertext(B.name))
						failure_msg = "No duplicate belly names, please."
						break

			if(failure_msg) //Something went wrong.
				tgui_alert_async(user,failure_msg,"Error!")
				return FALSE

			host.vore_selected.name = new_name
			. = TRUE
		if("b_wetness")
			host.vore_selected.is_wet = !host.vore_selected.is_wet
			. = TRUE
		if("b_wetloop")
			host.vore_selected.wet_loop = !host.vore_selected.wet_loop
			. = TRUE
		if("b_mode")
			var/list/menu_list = host.vore_selected.digest_modes.Copy()
			var/new_mode = tgui_input_list(usr, "Choose Mode (currently [host.vore_selected.digest_mode])", "Mode Choice", menu_list)
			if(!new_mode)
				return FALSE

			host.vore_selected.digest_mode = new_mode
			host.vore_selected.updateVRPanels()
			. = TRUE
		if("b_addons")
			var/list/menu_list = host.vore_selected.mode_flag_list.Copy()
			var/toggle_addon = tgui_input_list(usr, "Toggle Addon", "Addon Choice", menu_list)
			if(!toggle_addon)
				return FALSE
			host.vore_selected.mode_flags ^= host.vore_selected.mode_flag_list[toggle_addon]
			host.vore_selected.items_preserved.Cut() //Re-evaltuate all items in belly on
			host.vore_selected.slow_digestion = FALSE //RS edit start
			host.vore_selected.slow_brutal = FALSE
			if(host.vore_selected.mode_flags & DM_FLAG_SLOWBODY) //Ports CHOMPStation PR 5184
				host.vore_selected.slow_digestion = TRUE //CHOMPStation PR 5184 port end
			if(host.vore_selected.mode_flags & DM_FLAG_SLOWBRUTAL)
				host.vore_selected.slow_brutal = TRUE
				host.vore_selected.slow_digestion = TRUE //RS edit end
			. = TRUE
		if("b_item_mode")
			var/list/menu_list = host.vore_selected.item_digest_modes.Copy()

			var/new_mode = tgui_input_list(usr, "Choose Mode (currently [host.vore_selected.item_digest_mode])", "Mode Choice", menu_list)
			if(!new_mode)
				return FALSE

			host.vore_selected.item_digest_mode = new_mode
			host.vore_selected.items_preserved.Cut() //Re-evaltuate all items in belly on belly-mode change
			. = TRUE
		if("b_contaminate")
			host.vore_selected.contaminates = !host.vore_selected.contaminates
			. = TRUE
		if("b_contamination_flavor")
			var/list/menu_list = contamination_flavors.Copy()
			var/new_flavor = tgui_input_list(usr, "Choose Contamination Flavor Text Type (currently [host.vore_selected.contamination_flavor])", "Flavor Choice", menu_list)
			if(!new_flavor)
				return FALSE
			host.vore_selected.contamination_flavor = new_flavor
			. = TRUE
		if("b_contamination_color")
			var/list/menu_list = contamination_colors.Copy()
			var/new_color = tgui_input_list(usr, "Choose Contamination Color (currently [host.vore_selected.contamination_color])", "Color Choice", menu_list)
			if(!new_color)
				return FALSE
			host.vore_selected.contamination_color = new_color
			host.vore_selected.items_preserved.Cut() //To re-contaminate for new color
			. = TRUE
		if("b_egg_type")
			var/list/menu_list = global_vore_egg_types.Copy()
			var/new_egg_type = tgui_input_list(usr, "Choose Egg Type (currently [host.vore_selected.egg_type])", "Egg Choice", menu_list)
			if(!new_egg_type)
				return FALSE
			host.vore_selected.egg_type = new_egg_type
			. = TRUE
		if("b_desc")
			var/new_desc = html_encode(tgui_input_text(usr,"Belly Description, '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name. ([BELLIES_DESC_MAX] char limit):","New Description",host.vore_selected.desc, multiline = TRUE, prevent_enter = TRUE))

			if(new_desc)
				new_desc = readd_quotes(new_desc)
				if(length(new_desc) > BELLIES_DESC_MAX)
					tgui_alert_async(usr, "Entered belly desc too long. [BELLIES_DESC_MAX] character limit.","Error")
					return FALSE
				host.vore_selected.desc = new_desc
				. = TRUE
		if("b_absorbed_desc")
			var/new_desc = html_encode(tgui_input_text(usr,"Belly Description for absorbed prey, '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name. ([BELLIES_DESC_MAX] char limit):","New Description",host.vore_selected.absorbed_desc, multiline = TRUE, prevent_enter = TRUE))

			if(new_desc)
				new_desc = readd_quotes(new_desc)
				if(length(new_desc) > BELLIES_DESC_MAX)
					tgui_alert_async(usr, "Entered belly desc too long. [BELLIES_DESC_MAX] character limit.","Error")
					return FALSE
				host.vore_selected.absorbed_desc = new_desc
				. = TRUE
		if("b_msgs")
			tgui_alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message (250 for examines, 500 for idle messages), max 10 messages per topic.","Really, don't.") // Should remain tgui_alert() (blocking)
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name. '%count' will be replaced with the number of anything in your belly. '%countprey' will be replaced with the number of living prey in your belly."
			switch(params["msgtype"])
				if("dmp")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey when they expire. Write them in 2nd person ('you feel X'). Avoid using %prey in this type."+help,"Digest Message (to prey)",host.vore_selected.get_messages("dmp"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"dmp")

				if("dmo")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to you when prey expires in you. Write them in 2nd person ('you feel X'). Avoid using %pred in this type."+help,"Digest Message (to you)",host.vore_selected.get_messages("dmo"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"dmo")

				if("amp")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey when their absorption finishes. Write them in 2nd person ('you feel X'). Avoid using %prey in this type. %count will not work for this type, and %countprey will only count absorbed victims."+help,"Digest Message (to prey)",host.vore_selected.get_messages("amp"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"amp")

				if("amo")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to you when prey's absorption finishes. Write them in 2nd person ('you feel X'). Avoid using %pred in this type. %count will not work for this type, and %countprey will only count absorbed victims."+help,"Digest Message (to you)",host.vore_selected.get_messages("amo"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"amo")

				if("uamp")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey when their unnabsorption finishes. Write them in 2nd person ('you feel X'). Avoid using %prey in this type. %count will not work for this type, and %countprey will only count absorbed victims."+help,"Digest Message (to prey)",host.vore_selected.get_messages("uamp"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"uamp")

				if("uamo")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to you when prey's unabsorption finishes. Write them in 2nd person ('you feel X'). Avoid using %pred in this type. %count will not work for this type, and %countprey will only count absorbed victims."+help,"Digest Message (to you)",host.vore_selected.get_messages("uamo"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"uamo")

				if("smo")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to those nearby when prey struggles. Write them in 3rd person ('X's Y bulges')."+help,"Struggle Message (outside)",host.vore_selected.get_messages("smo"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"smo")

				if("smi")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey when they struggle. Write them in 2nd person ('you feel X'). Avoid using %prey in this type."+help,"Struggle Message (inside)",host.vore_selected.get_messages("smi"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"smi")

				if("asmo")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to those nearby when absorbed prey struggles. Write them in 3rd person ('X's Y bulges'). %count will not work for this type, and %countprey will only count absorbed victims."+help,"Struggle Message (outside)",host.vore_selected.get_messages("asmo"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"asmo")

				if("asmi")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to absorbed prey when they struggle. Write them in 2nd person ('you feel X'). Avoid using %prey in this type. %count will not work for this type, and %countprey will only count absorbed victims."+help,"Struggle Message (inside)",host.vore_selected.get_messages("asmi"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"asmi")

				if("em")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to people who examine you when this belly has contents. Write them in 3rd person ('Their %belly is bulging')."+help,"Examine Message (when full)",host.vore_selected.get_messages("em"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"em")

				if("ema")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to people who examine you when this belly has absorbed victims. Write them in 3rd person ('Their %belly is larger'). %count will not work for this type, and %countprey will only count absorbed victims."+help,"Examine Message (with absorbed victims)",host.vore_selected.get_messages("ema"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"ema")

				if("en")
					var/list/indices = list(1,2,3,4,5,6,7,8,9,10)
					var/index = tgui_input_list(user,"Select a message to edit:","Select Message", indices)
					if(index && index <= 10)
						var/alert = tgui_alert(user, "What do you wish to do with this message?","Selection",list("Edit","Clear","Cancel"))
						switch(alert)
							if("Clear")
								host.nutrition_messages[index] = ""
							if("Edit")
								var/new_message = sanitize(tgui_input_text(user, "Input a message", "Input", host.nutrition_messages[index], multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
								if(new_message)
									host.nutrition_messages[index] = new_message

				if("ew")
					var/list/indices = list(1,2,3,4,5,6,7,8,9,10)
					var/index = tgui_input_list(user,"Select a message to edit:","Select Message", indices)
					if(index && index <= 10)
						var/alert = tgui_alert(user, "What do you wish to do with this message?","Selection",list("Edit","Clear","Cancel"))
						switch(alert)
							if("Clear")
								host.weight_messages[index] = ""
							if("Edit")
								var/new_message = sanitize(tgui_input_text(user, "Input a message", "Input", host.weight_messages[index], multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
								if(new_message)
									host.weight_messages[index] = new_message

				if("im_digest")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Digest mode. Write them in 2nd person ('%pred's %belly squishes down on you.')."+help,"Idle Message (Digest)",host.vore_selected.get_messages("im_digest"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_digest")

				if("im_hold")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Hold mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Hold)",host.vore_selected.get_messages("im_hold"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_hold")

				if("im_holdabsorbed")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are absorbed. Write them in 2nd person ('%pred's %belly squishes down on you.') %count will not work for this type, and %countprey will only count absorbed victims."+help,"Idle Message (Hold Absorbed)",host.vore_selected.get_messages("im_holdabsorbed"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_holdabsorbed")

				if("im_absorb")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Absorb mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Absorb)",host.vore_selected.get_messages("im_absorb"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_absorb")

				if("im_heal")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Heal mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Heal)",host.vore_selected.get_messages("im_heal"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_heal")

				if("im_drain")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Drain mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Drain)",host.vore_selected.get_messages("im_drain"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_drain")

				if("im_steal")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Size Steal mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Size Steal)",host.vore_selected.get_messages("im_steal"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_steal")

				if("im_egg")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Encase In Egg mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Encase In Egg)",host.vore_selected.get_messages("im_egg"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_egg")

				if("im_shrink")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Shrink mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Shrink)",host.vore_selected.get_messages("im_shrink"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_shrink")

				if("im_grow")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Grow mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Grow)",host.vore_selected.get_messages("im_grow"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_grow")

				if("im_unabsorb")
					var/new_message = sanitize(tgui_input_text(user,"These are sent to prey every minute when you are on Unabsorb mode. Write them in 2nd person ('%pred's %belly squishes down on you.')"+help,"Idle Message (Unabsorb)",host.vore_selected.get_messages("im_unabsorb"), multiline = TRUE, prevent_enter = TRUE),MAX_MESSAGE_LEN,0,0,0)
					if(new_message)
						host.vore_selected.set_messages(new_message,"im_unabsorb")

				if("reset")
					var/confirm = tgui_alert(user,"This will delete any custom messages. Are you sure?","Confirmation",list("Cancel","DELETE"))
					if(confirm == "DELETE")
						host.vore_selected.digest_messages_prey = initial(host.vore_selected.digest_messages_prey)
						host.vore_selected.digest_messages_owner = initial(host.vore_selected.digest_messages_owner)
						host.vore_selected.absorb_messages_prey = initial(host.vore_selected.absorb_messages_prey)
						host.vore_selected.absorb_messages_owner = initial(host.vore_selected.absorb_messages_owner)
						host.vore_selected.unabsorb_messages_prey = initial(host.vore_selected.unabsorb_messages_prey)
						host.vore_selected.unabsorb_messages_owner = initial(host.vore_selected.unabsorb_messages_owner)
						host.vore_selected.struggle_messages_outside = initial(host.vore_selected.struggle_messages_outside)
						host.vore_selected.struggle_messages_inside = initial(host.vore_selected.struggle_messages_inside)
						host.vore_selected.absorbed_struggle_messages_outside = initial(host.vore_selected.absorbed_struggle_messages_outside)
						host.vore_selected.absorbed_struggle_messages_inside = initial(host.vore_selected.absorbed_struggle_messages_inside)
						host.vore_selected.examine_messages = initial(host.vore_selected.examine_messages)
						host.vore_selected.examine_messages_absorbed = initial(host.vore_selected.examine_messages_absorbed)
						host.vore_selected.emote_lists = initial(host.vore_selected.emote_lists)
			. = TRUE
		if("b_verb")
			var/new_verb = html_encode(tgui_input_text(usr,"New verb when eating (infinitive tense, e.g. nom or swallow):","New Verb"))

			if(length(new_verb) > BELLIES_NAME_MAX || length(new_verb) < BELLIES_NAME_MIN)
				tgui_alert_async(usr, "Entered verb length invalid (must be longer than [BELLIES_NAME_MIN], no longer than [BELLIES_NAME_MAX]).","Error")
				return FALSE

			host.vore_selected.vore_verb = new_verb
			. = TRUE
		if("b_release_verb")
			var/new_release_verb = html_encode(tgui_input_text(usr,"New verb when releasing from stomach (e.g. expels or coughs or drops):","New Release Verb"))

			if(length(new_release_verb) > BELLIES_NAME_MAX || length(new_release_verb) < BELLIES_NAME_MIN)
				tgui_alert_async(usr, "Entered verb length invalid (must be longer than [BELLIES_NAME_MIN], no longer than [BELLIES_NAME_MAX]).","Error")
				return FALSE

			host.vore_selected.release_verb = new_release_verb
			. = TRUE
		if("b_eating_privacy")
			var/privacy_choice = tgui_input_list(usr, "Choose your belly-specific preference. Default uses global preference!", "Eating message privacy", list("default", "subtle", "loud"), "default")
			if(privacy_choice == null)
				return FALSE
			host.vore_selected.eating_privacy_local = privacy_choice
			. = TRUE
		if("b_silicon_belly")
			var/belly_choice = tgui_alert(usr, "Choose whether you'd like your belly overlay to show from sleepers \
			or from normal vore bellies. NOTE: This ONLY applies to silicons, not human mobs!", "Belly Overlay Preference",
			list("Sleeper", "Vorebelly", "Both"))
			if(belly_choice == null)
				return FALSE
			//RS Edit Start //CHOMPEdit Start, changed to sync the setting among all sleepers for multibelly support
			for (var/belly in host.vore_organs)
				var/obj/belly/B = belly
				B.silicon_belly_overlay_preference = belly_choice
			//RS Edit End
			host.update_icon()
			. = TRUE
		if("b_min_belly_number_flat")
			var/new_min_belly = tgui_input_number(user, "Choose the amount of prey your belly must contain \
			at absolute minimum (should be lower or equal to minimum prey override if prey override is ON)",
			"Set minimum prey amount", host.vore_selected.visible_belly_minimum_prey, max_value = 100, min_value = 1)
			if(new_min_belly == null)
				return FALSE
			var/new_new_min_belly = CLAMP(new_min_belly, 1, 100)	//Clamping at 100 rather than infinity. Should be close to infinity tho.
			host.vore_selected.visible_belly_minimum_prey = new_new_min_belly
			host.update_icon()
			. = TRUE
		if("b_min_belly_prey_size")
			var/new_belly_size = tgui_input_number(user, "Choose the required size prey must be to trigger belly overlay, \
			ranging from 25% to 200%. Set to 0 to disable size checks", "Set Belly Examine Size.", max_value = 200, min_value = 0)
			if(new_belly_size == null)
				return FALSE
			else if(new_belly_size == 0)
				host.vore_selected.overlay_min_prey_size = 0
			else
				var/new_new_belly_size = CLAMP(new_belly_size, 25, 200)
				host.vore_selected.overlay_min_prey_size = (new_new_belly_size/100)
			host.update_icon()
			. = TRUE
		if("b_override_min_belly_prey_size")
			host.vore_selected.override_min_prey_size = !host.vore_selected.override_min_prey_size
			host.update_icon()
			. = TRUE
		if("b_min_belly_number_override")
			var/new_min_prey = tgui_input_number(user, "Choose the amount of prey your belly must contain to override min prey size \
			to show belly overlay ignoring prey size requirement. Toggle Prey Override MUST be ON to work",
			"Set minimum prey amount", host.vore_selected.override_min_prey_num, max_value = 100, min_value = 1)
			if(new_min_prey == null)
				return FALSE
			var/new_new_min_prey = CLAMP(new_min_prey, 1, 100)	//Clamping at 100 rather than infinity. Should be close to infinity tho.
			host.vore_selected.override_min_prey_num = new_new_min_prey
			host.update_icon()
			. = TRUE
		if("b_fancy_sound")
			host.vore_selected.fancy_vore = !host.vore_selected.fancy_vore
			host.vore_selected.vore_sound = "Gulp"
			host.vore_selected.release_sound = "Splatter"
			// defaults as to avoid potential bugs
			. = TRUE
		if("b_release")
			var/choice
			if(host.vore_selected.fancy_vore)
				choice = tgui_input_list(user,"Currently set to [host.vore_selected.release_sound]","Select Sound", fancy_release_sounds)
			else
				choice = tgui_input_list(user,"Currently set to [host.vore_selected.release_sound]","Select Sound", classic_release_sounds)

			if(!choice)
				return FALSE

			host.vore_selected.release_sound = choice
			. = TRUE
		if("b_releasesoundtest")
			var/sound/releasetest
			if(host.vore_selected.fancy_vore)
				releasetest = fancy_release_sounds[host.vore_selected.release_sound]
			else
				releasetest = classic_release_sounds[host.vore_selected.release_sound]

			if(releasetest)
				SEND_SOUND(user, releasetest)
			. = TRUE
		if("b_sound")
			var/choice
			if(host.vore_selected.fancy_vore)
				choice = tgui_input_list(user,"Currently set to [host.vore_selected.vore_sound]","Select Sound", fancy_vore_sounds)
			else
				choice = tgui_input_list(user,"Currently set to [host.vore_selected.vore_sound]","Select Sound", classic_vore_sounds)

			if(!choice)
				return FALSE

			host.vore_selected.vore_sound = choice
			. = TRUE
		if("b_soundtest")
			var/sound/voretest
			if(host.vore_selected.fancy_vore)
				voretest = fancy_vore_sounds[host.vore_selected.vore_sound]
			else
				voretest = classic_vore_sounds[host.vore_selected.vore_sound]
			if(voretest)
				SEND_SOUND(user, voretest)
			. = TRUE
		if("b_tastes")
			host.vore_selected.can_taste = !host.vore_selected.can_taste
			. = TRUE
		if("b_bulge_size")
			var/new_bulge = tgui_input_number(user, "Choose the required size prey must be to show up on examine, ranging from 25% to 200% Set this to 0 for no text on examine.", "Set Belly Examine Size.", max_value = 200, min_value = 0)
			if(new_bulge == null)
				return FALSE
			if(new_bulge == 0) //Disable.
				host.vore_selected.bulge_size = 0
				to_chat(user,"<span class='notice'>Your stomach will not be seen on examine.</span>")
			else if (!ISINRANGE(new_bulge,25,200))
				host.vore_selected.bulge_size = 0.25 //Set it to the default.
				to_chat(user,"<span class='notice'>Invalid size.</span>")
			else if(new_bulge)
				host.vore_selected.bulge_size = (new_bulge/100)
			. = TRUE
		if("b_display_absorbed_examine")
			host.vore_selected.display_absorbed_examine = !host.vore_selected.display_absorbed_examine
			. = TRUE
		if("b_grow_shrink")
			var/new_grow = tgui_input_number(user, "Choose the size that prey will be grown/shrunk to, ranging from 25% to 200%", "Set Growth Shrink Size.", host.vore_selected.shrink_grow_size, 200, 25)
			if (new_grow == null)
				return FALSE
			if (!ISINRANGE(new_grow,25,200))
				host.vore_selected.shrink_grow_size = 1 //Set it to the default
				to_chat(user,"<span class='notice'>Invalid size.</span>")
			else if(new_grow)
				host.vore_selected.shrink_grow_size = (new_grow*0.01)
			. = TRUE
		if("b_nutritionpercent")
			var/new_nutrition = tgui_input_number(user, "Choose the nutrition gain percentage you will receive per tick from prey. Ranges from 0.01 to 100.", "Set Nutrition Gain Percentage.", host.vore_selected.nutrition_percent, 100, 0.01)
			if(new_nutrition == null)
				return FALSE
			var/new_new_nutrition = CLAMP(new_nutrition, 0.01, 100)
			host.vore_selected.nutrition_percent = new_new_nutrition
			. = TRUE
		if("b_burn_dmg")
			var/new_damage = tgui_input_number(user, "Choose the amount of burn damage prey will take per tick. Ranges from 0 to 6.", "Set Belly Burn Damage.", host.vore_selected.digest_burn, 6, 0)
			if(new_damage == null)
				return FALSE
			var/new_new_damage = CLAMP(new_damage, 0, 6)
			host.vore_selected.digest_burn = new_new_damage
			. = TRUE
		if("b_brute_dmg")
			var/new_damage = tgui_input_number(user, "Choose the amount of brute damage prey will take per tick. Ranges from 0 to 6", "Set Belly Brute Damage.", host.vore_selected.digest_brute, 6, 0)
			if(new_damage == null)
				return FALSE
			var/new_new_damage = CLAMP(new_damage, 0, 6)
			host.vore_selected.digest_brute = new_new_damage
			. = TRUE
		if("b_oxy_dmg")
			var/new_damage = tgui_input_number(user, "Choose the amount of suffocation damage prey will take per tick. Ranges from 0 to 12.", "Set Belly Suffocation Damage.", host.vore_selected.digest_oxy, 12, 0)
			if(new_damage == null)
				return FALSE
			var/new_new_damage = CLAMP(new_damage, 0, 12)
			host.vore_selected.digest_oxy = new_new_damage
			. = TRUE
		if("b_tox_dmg")
			var/new_damage = tgui_input_number(user, "Choose the amount of toxins damage prey will take per tick. Ranges from 0 to 6", "Set Belly Toxins Damage.", host.vore_selected.digest_tox, 6, 0)
			if(new_damage == null)
				return FALSE
			var/new_new_damage = CLAMP(new_damage, 0, 6)
			host.vore_selected.digest_tox = new_new_damage
			. = TRUE
		if("b_clone_dmg")
			var/new_damage = tgui_input_number(user, "Choose the amount of brute DNA damage (clone) prey will take per tick. Ranges from 0 to 6", "Set Belly Clone Damage.", host.vore_selected.digest_clone, 6, 0)
			if(new_damage == null)
				return FALSE
			var/new_new_damage = CLAMP(new_damage, 0, 6)
			host.vore_selected.digest_clone = new_new_damage
			. = TRUE
		//RS Edit || Ports VOREStation PR15876
		if("b_drainmode")
			var/list/menu_list = host.vore_selected.drainmodes.Copy()
			var/new_drainmode = tgui_input_list(usr, "Choose Mode (currently [host.vore_selected.digest_mode])", "Mode Choice", menu_list)
			if(!new_drainmode)
				return FALSE
		//RS Edit || Ports VOREStation PR15876

			host.vore_selected.drainmode = new_drainmode
			host.vore_selected.updateVRPanels()

		if("b_emoteactive")
			host.vore_selected.emote_active = !host.vore_selected.emote_active
			. = TRUE
		if("b_selective_mode_pref_toggle")
			if(host.vore_selected.selective_preference == DM_DIGEST)
				host.vore_selected.selective_preference = DM_ABSORB
			else
				host.vore_selected.selective_preference = DM_DIGEST
			. = TRUE
		if("b_emotetime")
			var/new_time = tgui_input_number(user, "Choose the period it takes for idle belly emotes to be shown to prey. Measured in seconds, Minimum 1 minute, Maximum 10 minutes.", "Set Belly Emote Delay.", host.vore_selected.digest_brute, 600, 60)
			if(new_time == null)
				return FALSE
			var/new_new_time = CLAMP(new_time, 60, 600)
			host.vore_selected.emote_time = new_new_time
			. = TRUE
		if("b_escapable")
			if(host.vore_selected.escapable == 0) //Possibly escapable and special interactions.
				host.vore_selected.escapable = 1
				to_chat(usr,"<span class='warning'>Prey now have special interactions with your [lowertext(host.vore_selected.name)] depending on your settings.</span>")
			else if(host.vore_selected.escapable == 1) //Never escapable.
				host.vore_selected.escapable = 0
				to_chat(usr,"<span class='warning'>Prey will not be able to have special interactions with your [lowertext(host.vore_selected.name)].</span>")
			else
				tgui_alert_async(usr, "Something went wrong. Your stomach will now not have special interactions. Press the button enable them again and tell a dev.","Error") //If they somehow have a varable that's not 0 or 1
				host.vore_selected.escapable = 0
			. = TRUE
		if("b_escapechance")
			var/escape_chance_input = tgui_input_number(user, "Set prey escape chance on resist (as %)", "Prey Escape Chance", null, 100, 0)
			if(!isnull(escape_chance_input)) //These have to be 'null' because both cancel and 0 are valid, separate options
				host.vore_selected.escapechance = sanitize_integer(escape_chance_input, 0, 100, initial(host.vore_selected.escapechance))
			. = TRUE
		if("b_escapetime")
			var/escape_time_input = tgui_input_number(user, "Set number of seconds for prey to escape on resist (1-60)", "Prey Escape Time", null, 60, 1)
			if(!isnull(escape_time_input))
				host.vore_selected.escapetime = sanitize_integer(escape_time_input*10, 10, 600, initial(host.vore_selected.escapetime))
			. = TRUE
		if("b_transferchance")
			var/transfer_chance_input = tgui_input_number(user, "Set belly transfer chance on resist (as %). You must also set the location for this to have any effect.", "Prey Escape Time", null, 100, 0)
			if(!isnull(transfer_chance_input))
				host.vore_selected.transferchance = sanitize_integer(transfer_chance_input, 0, 100, initial(host.vore_selected.transferchance))
			. = TRUE
		if("b_transferlocation")
			var/obj/belly/choice = tgui_input_list(usr, "Where do you want your [lowertext(host.vore_selected.name)] to lead if prey resists?","Select Belly", (host.vore_organs + "None - Remove" - host.vore_selected))

			if(!choice) //They cancelled, no changes
				return FALSE
			else if(choice == "None - Remove")
				host.vore_selected.transferlocation = null
			else
				host.vore_selected.transferlocation = choice.name
			. = TRUE
		if("b_transferchance_secondary")
			var/transfer_secondary_chance_input = tgui_input_number(user, "Set secondary belly transfer chance on resist (as %). You must also set the location for this to have any effect.", "Prey Escape Time", null, 100, 0)
			if(!isnull(transfer_secondary_chance_input))
				host.vore_selected.transferchance_secondary = sanitize_integer(transfer_secondary_chance_input, 0, 100, initial(host.vore_selected.transferchance_secondary))
			. = TRUE
		if("b_transferlocation_secondary")
			var/obj/belly/choice_secondary = tgui_input_list(usr, "Where do you want your [lowertext(host.vore_selected.name)] to alternately lead if prey resists?","Select Belly", (host.vore_organs + "None - Remove" - host.vore_selected))

			if(!choice_secondary) //They cancelled, no changes
				return FALSE
			else if(choice_secondary == "None - Remove")
				host.vore_selected.transferlocation_secondary = null
			else
				host.vore_selected.transferlocation_secondary = choice_secondary.name
			. = TRUE
		if("b_absorbchance")
			var/absorb_chance_input = tgui_input_number(user, "Set belly absorb mode chance on resist (as %)", "Prey Absorb Chance", null, 100, 0)
			if(!isnull(absorb_chance_input))
				host.vore_selected.absorbchance = sanitize_integer(absorb_chance_input, 0, 100, initial(host.vore_selected.absorbchance))
			. = TRUE
		if("b_digestchance")
			var/digest_chance_input = tgui_input_number(user, "Set belly digest mode chance on resist (as %)", "Prey Digest Chance", null, 100, 0)
			if(!isnull(digest_chance_input))
				host.vore_selected.digestchance = sanitize_integer(digest_chance_input, 0, 100, initial(host.vore_selected.digestchance))
			. = TRUE
		if("b_autotransferchance") //RS Add Start || Port Chomp 2821, 2934, 6155
			var/autotransferchance_input = input(user, "Set belly auto-transfer chance (as %). You must also set the location for this to have any effect.", "Auto-Transfer Chance") as num|null
			if(!isnull(autotransferchance_input))
				host.vore_selected.autotransferchance = sanitize_integer(autotransferchance_input, 0, 100, initial(host.vore_selected.autotransferchance))
			. = TRUE
		if("b_autotransferwait")
			var/autotransferwait_input = input(user, "Set minimum number of seconds for auto-transfer wait delay.", "Auto-Transfer Time") as num|null //Wiggle room for rougher time resolution in process cycles.
			if(!isnull(autotransferwait_input))
				host.vore_selected.autotransferwait = sanitize_integer(autotransferwait_input*10, 10, 18000, initial(host.vore_selected.autotransferwait))
			. = TRUE
		if("b_autotransferlocation")
			var/obj/belly/choice = tgui_input_list(usr, "Where do you want your [lowertext(host.vore_selected.name)] auto-transfer to?","Select Belly", (host.vore_organs + "None - Remove" - host.vore_selected))
			if(!choice) //They cancelled, no changes
				return FALSE
			else if(choice == "None - Remove")
				host.vore_selected.autotransferlocation = null
			else
				host.vore_selected.autotransferlocation = choice.name
			. = TRUE
		if("b_autotransferchance_secondary")
			var/autotransferchance_secondary_input = input(user, "Set secondary belly auto-transfer chance (as %). You must also set the location for this to have any effect.", "Secondary Auto-Transfer Chance") as num|null
			if(!isnull(autotransferchance_secondary_input))
				host.vore_selected.autotransferchance_secondary = sanitize_integer(autotransferchance_secondary_input, 0, 100, initial(host.vore_selected.autotransferchance_secondary))
			. = TRUE
		if("b_autotransferlocation_secondary")
			var/obj/belly/choice = tgui_input_list(usr, "Where do you want your secondary [lowertext(host.vore_selected.name)] auto-transfer to?","Select Belly", (host.vore_organs + "None - Remove" - host.vore_selected))
			if(!choice) //They cancelled, no changes
				return FALSE
			else if(choice == "None - Remove")
				host.vore_selected.autotransferlocation_secondary = null
			else
				host.vore_selected.autotransferlocation_secondary = choice.name
			. = TRUE
		if("b_autotransfer_min_amount")
			var/autotransfer_min_amount_input = input(user, "Set the minimum amount of items your belly can belly auto-transfer at once. Set to 0 for no limit.", "Auto-Transfer Min Amount") as num|null
			if(!isnull(autotransfer_min_amount_input))
				host.vore_selected.autotransfer_min_amount = sanitize_integer(autotransfer_min_amount_input, 0, 100, initial(host.vore_selected.autotransfer_min_amount))
			. = TRUE
		if("b_autotransfer_max_amount")
			var/autotransfer_max_amount_input = input(user, "Set the maximum amount of items your belly can belly auto-transfer at once. Set to 0 for no limit.", "Auto-Transfer Max Amount") as num|null
			if(!isnull(autotransfer_max_amount_input))
				host.vore_selected.autotransfer_max_amount = sanitize_integer(autotransfer_max_amount_input, 0, 100, initial(host.vore_selected.autotransfer_max_amount))
			. = TRUE
		if("b_autotransfer_enabled")
			host.vore_selected.autotransfer_enabled = !host.vore_selected.autotransfer_enabled
			. = TRUE //RS Add End
		if("b_fullscreen")
			host.vore_selected.belly_fullscreen = params["val"]
			. = TRUE
		if("b_disable_hud")
			host.vore_selected.disable_hud = !host.vore_selected.disable_hud
			. = TRUE
		if("b_colorization_enabled") //ALLOWS COLORIZATION.
			host.vore_selected.colorization_enabled = !host.vore_selected.colorization_enabled
			host.vore_selected.belly_fullscreen = "dark" //This prevents you from selecting a belly that is not meant to be colored and then turning colorization on.
			. = TRUE
		if("b_preview_belly")
			host.vore_selected.vore_preview(host) //Gives them the stomach overlay. It fades away after ~2 seconds as human/life.dm removes the overlay if not in a gut.
			. = TRUE
		if("b_clear_preview")
			host.vore_selected.clear_preview(host) //Clears the stomach overlay. This is a failsafe but shouldn't occur.
			. = TRUE
		if("b_fullscreen_color")
			var/newcolor = input(usr, "Choose a color.", "", host.vore_selected.belly_fullscreen_color) as color|null
			if(newcolor)
				host.vore_selected.belly_fullscreen_color = newcolor
			. = TRUE
		if("b_fullscreen_color_secondary")
			var/newcolor = input(usr, "Choose a color.", "", host.vore_selected.belly_fullscreen_color_secondary) as color|null
			if(newcolor)
				host.vore_selected.belly_fullscreen_color_secondary = newcolor
			. = TRUE
		if("b_fullscreen_color_trinary")
			var/newcolor = input(usr, "Choose a color.", "", host.vore_selected.belly_fullscreen_color_trinary) as color|null
			if(newcolor)
				host.vore_selected.belly_fullscreen_color_trinary = newcolor
			. = TRUE
		if("b_save_digest_mode")
			host.vore_selected.save_digest_mode = !host.vore_selected.save_digest_mode
			. = TRUE
		if("b_del")
			var/alert = tgui_alert(usr, "Are you sure you want to delete your [lowertext(host.vore_selected.name)]?","Confirmation",list("Cancel","Delete"))
			if(!(alert == "Delete"))
				return FALSE

			var/failure_msg = ""

			var/dest_for //Check to see if it's the destination of another vore organ.
			for(var/obj/belly/B as anything in host.vore_organs)
				if(B.transferlocation == host.vore_selected)
					dest_for = B.name
					failure_msg += "This is the destiantion for at least '[dest_for]' belly transfers. Remove it as the destination from any bellies before deleting it. "
					break
				if(B.transferlocation_secondary == host.vore_selected)
					dest_for = B.name
					failure_msg += "This is the destiantion for at least '[dest_for]' secondary belly transfers. Remove it as the destination from any bellies before deleting it. "
					break

			if(host.vore_selected.contents.len)
				failure_msg += "You cannot delete bellies with contents! " //These end with spaces, to be nice looking. Make sure you do the same.
			if(host.vore_selected.immutable)
				failure_msg += "This belly is marked as undeletable. "
			if(host.vore_organs.len == 1)
				failure_msg += "You must have at least one belly. "

			if(failure_msg)
				tgui_alert_async(user,failure_msg,"Error!")
				return FALSE

			qdel(host.vore_selected)
			host.vore_selected = host.vore_organs[1]
			. = TRUE
		// Begin RS edit
		if("b_belly_sprite_to_affect")
			var/belly_choice = tgui_input_list(usr, "Which belly sprite do you want your [lowertext(host.vore_selected.name)] to affect?","Select Region", host:vore_icon_bellies)
			if(!belly_choice) //They cancelled, no changes
				return FALSE
			else
				host.vore_selected.belly_sprite_to_affect = belly_choice
				host:update_fullness()
			. = TRUE
		if("b_silicon_belly") //RS Edit Start
			var/belly_choice = tgui_alert(user, "Choose whether you'd like your belly overlay to show from sleepers, \
			normal vore bellies, or an average of the two. NOTE: This ONLY applies to silicons, not human mobs!", "Belly Overlay \
			Preference",
			list("Sleeper", "Vorebelly", "Both"))
			if(belly_choice == null)
				return FALSE
			//CHOMPEdit Start, changed to sync the setting among all sleepers for multibelly support
			for (var/belly in host.vore_organs)
				var/obj/belly/B = belly
				B.silicon_belly_overlay_preference = belly_choice
			//CHOMPEdit End
			host.update_icon()
			. = TRUE //RS Edit End
		if("b_affects_vore_sprites")
			host.vore_selected.affects_vore_sprites = !host.vore_selected.affects_vore_sprites
			host:update_fullness()
			. = TRUE
		if("b_count_absorbed_prey_for_sprites")
			host.vore_selected.count_absorbed_prey_for_sprite = !host.vore_selected.count_absorbed_prey_for_sprite
			host:update_fullness()
			. = TRUE
		if("b_absorbed_multiplier")
			var/absorbed_multiplier_input = input(user, "Set the impact absorbed prey's size have on your vore sprite. 1 means no scaling, 0.5 means absorbed prey count half as much, 2 means absorbed prey count double. (Range from 0.1 - 3)", "Absorbed Multiplier") as num|null
			if(!isnull(absorbed_multiplier_input))
				host.vore_selected.absorbed_multiplier = CLAMP(absorbed_multiplier_input, 0.1, 3)
				host:update_fullness()
			. = TRUE
		if("b_count_liquid_for_sprites") //Reagent bellies || Chomp Port
			host.vore_selected.count_liquid_for_sprite = !host.vore_selected.count_liquid_for_sprite
			host:update_fullness()
			. = TRUE
		if("b_liquid_multiplier") //Reagent bellies || Chomp Port
			var/liquid_multiplier_input = input(user, "Set the impact amount of liquid reagents will have on your vore sprite. 1 means a belly with 100 reagents of fluid will count as 1 normal sized prey-thing's worth, 0.5 means liquid counts half as much, 2 means liquid counts double. (Range from 0.1 - 10)", "Liquid Multiplier") as num|null
			if(!isnull(liquid_multiplier_input))
				host.vore_selected.liquid_multiplier = CLAMP(liquid_multiplier_input, 0.1, 10)
				host:update_fullness()
			. = TRUE
		if("b_count_items_for_sprites")
			host.vore_selected.count_items_for_sprite = !host.vore_selected.count_items_for_sprite
			host:update_fullness()
			. = TRUE
		if("b_item_multiplier")
			var/item_multiplier_input = input(user, "Set the impact items will have on your vore sprite. 1 means a belly with 8 normal-sized items will count as 1 normal sized prey-thing's worth, 0.5 means items count half as much, 2 means items count double. (Range from 0.1 - 10)", "Item Multiplier") as num|null
			if(!isnull(item_multiplier_input))
				host.vore_selected.item_multiplier = CLAMP(item_multiplier_input, 0.1, 10)
				host:update_fullness()
			. = TRUE
		if("b_health_impacts_size")
			host.vore_selected.health_impacts_size = !host.vore_selected.health_impacts_size
			host:update_fullness()
			. = TRUE
		if("b_resist_animation")
			host.vore_selected.resist_triggers_animation = !host.vore_selected.resist_triggers_animation
			. = TRUE
		if("b_size_factor_sprites")
			var/size_factor_input = input(user, "Set the impact all belly content's collective size has on your vore sprite. 1 means no scaling, 0.5 means content counts half as much, 2 means contents count double. (Range from 0.1 - 3)", "Size Factor") as num|null
			if(!isnull(size_factor_input))
				host.vore_selected.size_factor_for_sprite = CLAMP(size_factor_input, 0.1, 3)
				host:update_fullness()
			. = TRUE
		if("b_tail_to_change_to")
			if (istype(host, /mob/living/carbon/human))
				var/tail_choice = tgui_input_list(usr, "Which tail sprite do you want to use when your [lowertext(host.vore_selected.name)] is filled?","Select Sprite", global.tail_styles_list)
				if(!tail_choice) //They cancelled, no changes
					return FALSE
				else
					host.vore_selected.tail_to_change_to = tail_choice
				. = TRUE
		if("b_tail_color")
			if (istype(host, /mob/living/carbon/human))
				var/newcolor = input(usr, "Choose tail color.", "", host.vore_selected.tail_colouration) as color|null
				if(newcolor)
					host.vore_selected.tail_colouration = newcolor
				. = TRUE
		if("b_tail_color2")
			if (istype(host, /mob/living/carbon/human))
				var/newcolor = input(usr, "Choose tail secondary color.", "", host.vore_selected.tail_extra_overlay) as color|null
				if(newcolor)
					host.vore_selected.tail_extra_overlay = newcolor
				. = TRUE
		if("b_tail_color3")
			if (istype(host, /mob/living/carbon/human))
				var/newcolor = input(usr, "Choose tail tertiary color.", "", host.vore_selected.tail_extra_overlay2) as color|null
				if(newcolor)
					host.vore_selected.tail_extra_overlay2 = newcolor
				. = TRUE
		// End RS edit
	if(.)
		unsaved_changes = TRUE

// Begin reagent bellies || RS Add || Chomp Port
/datum/vore_look/proc/liq_set_attr(mob/user, params)
	if(!host.vore_selected)
		alert("No belly selected to modify.")
		return FALSE

	var/attr = params["liq_attribute"]
	switch(attr)
		if("b_show_liq")
			if(!host.vore_selected.show_liquids)
				host.vore_selected.show_liquids = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] now has liquid options.</span>")
			else
				host.vore_selected.show_liquids = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] no longer has liquid options.</span>")
			. = TRUE
		if("b_liq_reagent_gen")
			if(!host.vore_selected.reagentbellymode) //liquid container adjustments and interactions.
				host.vore_selected.reagentbellymode = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] now has interactions which can produce liquids.</span>")
			else //Doesnt produce liquids
				host.vore_selected.reagentbellymode = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] wont produce liquids, liquids already in your [lowertext(host.vore_selected.name)] must be emptied out or removed with purge.</span>")
			. = TRUE
		if("b_liq_reagent_type")
			var/list/menu_list = host.vore_selected.reagent_choices.Copy() //Useful if we want to make certain races, synths, borgs, and other things result in additional reagents to produce - Jack
			var/new_reagent = input("Choose Reagent (currently [host.vore_selected.reagent_chosen])") as null|anything in menu_list
			if(!new_reagent)
				return FALSE

			host.vore_selected.reagent_chosen = new_reagent
			host.vore_selected.ReagentSwitch() // For changing variables when a new reagent is chosen
			. = TRUE
		if("b_liq_reagent_name")
			var/new_name = html_encode(input(usr,"New name for liquid shown when transfering and dumping on floor (The actual liquid's name is still the same):","New Name") as text|null)

			if(length(new_name) > BELLIES_NAME_MAX || length(new_name) < BELLIES_NAME_MIN)
				alert("Entered name length invalid (must be longer than [BELLIES_NAME_MIN], no longer than [BELLIES_NAME_MAX]).","Error")
				return FALSE

			host.vore_selected.reagent_name = new_name
			. = TRUE
		if("b_liq_reagent_nutri_rate")
			host.vore_selected.gen_time_display = input(user, "Choose the time it takes to fill the belly from empty state using nutrition.", "Set Liquid Production Time.")  in list("10 minutes","30 minutes","1 hour","3 hours","6 hours","12 hours","24 hours")|null
			switch(host.vore_selected.gen_time_display)
				if("10 minutes")
					host.vore_selected.gen_time = 0
				if("30 minutes")
					host.vore_selected.gen_time = 2
				if("1 hour")
					host.vore_selected.gen_time = 5
				if("3 hours")
					host.vore_selected.gen_time = 17
				if("6 hours")
					host.vore_selected.gen_time = 35
				if("12 hours")
					host.vore_selected.gen_time = 71
				if("24 hours")
					host.vore_selected.gen_time = 143
				if(null)
					return FALSE
			. = TRUE
		if("b_liq_reagent_capacity")
			var/new_custom_vol = input(user, "Choose the amount of liquid the belly can contain at most. Ranges from 0 to 300.", "Set Custom Belly Capacity.", host.vore_selected.custom_max_volume) as num|null
			if(new_custom_vol == null)
				return FALSE
			var/new_new_custom_vol = CLAMP(new_custom_vol, 10, 300)
			host.vore_selected.custom_max_volume = new_new_custom_vol
			. = TRUE
		if("b_liq_sloshing")
			if(!host.vore_selected.vorefootsteps_sounds)
				host.vore_selected.vorefootsteps_sounds = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] can now make sounds when you walk around depending on how full you are.</span>")
			else
				host.vore_selected.vorefootsteps_sounds = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] wont make any liquid sounds no matter how full it is.</span>")
			. = TRUE
		if("b_liq_reagent_addons")
			var/list/menu_list = host.vore_selected.reagent_mode_flag_list.Copy()
			var/reagent_toggle_addon = input("Toggle Addon") as null|anything in menu_list
			if(!reagent_toggle_addon)
				return FALSE
			host.vore_selected.reagent_mode_flags ^= host.vore_selected.reagent_mode_flag_list[reagent_toggle_addon]
			. = TRUE
		if("b_liq_purge")
			var/alert = alert("Are you sure you want to delete the liquids in your [lowertext(host.vore_selected.name)]?","Confirmation","Delete","Cancel")
			if(!(alert == "Delete"))
				return FALSE
			else
				host.vore_selected.reagents.clear_reagents()
			if (istype(host, /mob/living/carbon/human))
				host:update_fullness()
			. = TRUE
		if("b_reagent_touches")
			if(!host.vore_selected.reagent_touches)
				host.vore_selected.reagent_touches = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] will now apply reagents to creatures when digesting.</span>")
			else
				host.vore_selected.reagent_touches = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] will no longer apply reagents to creatures when digesting.</span>")
			. = TRUE
		if("b_liquid_overlay")
			if(!host.vore_selected.liquid_overlay)
				host.vore_selected.liquid_overlay = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] now has liquid overlay enabled.</span>")
			else
				host.vore_selected.liquid_overlay = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] no longer has liquid overlay enabled.</span>")
			. = TRUE
		if("b_max_liquid_level")
			var/new_max_liquid_level = input(user, "Set custom maximum liquid level. 0-100%", "Set Custom Max Level.", host.vore_selected.max_liquid_level) as num|null
			if(new_max_liquid_level == null)
				return FALSE
			var/new_new_max_liquid_level = CLAMP(new_max_liquid_level, 0, 100)
			host.vore_selected.max_liquid_level = new_new_max_liquid_level
			// host.vore_selected.update_internal_overlay()
			. = TRUE
		if("b_custom_reagentcolor")
			var/newcolor = input(usr, "Choose custom color for liquid overlay. Cancel for normal reagent color.", "", host.vore_selected.custom_reagentcolor) as color|null
			if(newcolor)
				host.vore_selected.custom_reagentcolor = newcolor
			else
				host.vore_selected.custom_reagentcolor = null
			. = TRUE
		if("b_custom_reagentalpha")
			var/newalpha = tgui_input_number(usr, "Set alpha transparency between 0-255. Leave blank to use capacity based alpha.", "Custom Liquid Alpha",255,255,0,0,1)
			if(newalpha != null)
				host.vore_selected.custom_reagentalpha = newalpha
			else
				host.vore_selected.custom_reagentalpha = null
			. = TRUE
		if("b_mush_overlay")
			if(!host.vore_selected.mush_overlay)
				host.vore_selected.mush_overlay = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] now has fullness overlay enabled.</span>")
			else
				host.vore_selected.mush_overlay = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] no longer has fullness overlay enabled.</span>")
			. = TRUE
		if("b_mush_color")
			var/newcolor = input(usr, "Choose custom color for mush overlay.", "", host.vore_selected.mush_color) as color|null
			if(newcolor)
				host.vore_selected.mush_color = newcolor
			. = TRUE
		if("b_mush_alpha")
			var/newalpha = tgui_input_number(usr, "Set alpha transparency between 0-255", "Mush Alpha",255,255,0,0,1)
			if(newalpha != null)
				host.vore_selected.mush_alpha = newalpha
			. = TRUE
		if("b_max_mush")
			var/new_max_mush = input(user, "Choose the amount of nutrition required for full mush overlay. Ranges from 0 to 6000. Default 500.", "Set Fullness Overlay Scaling.", host.vore_selected.max_mush) as num|null
			if(new_max_mush == null)
				return FALSE
			var/new_new_max_mush = CLAMP(new_max_mush, 0, 6000)
			host.vore_selected.max_mush = new_new_max_mush
			. = TRUE
		if("b_min_mush")
			var/new_min_mush = input(user, "Set custom minimum mush level. 0-100%", "Set Custom Minimum.", host.vore_selected.min_mush) as num|null
			if(new_min_mush == null)
				return FALSE
			var/new_new_min_mush = CLAMP(new_min_mush, 0, 100)
			host.vore_selected.min_mush = new_new_min_mush
			. = TRUE

/datum/vore_look/proc/liq_set_msg(mob/user, params)
	if(!host.vore_selected)
		alert("No belly selected to modify.")
		return FALSE

	var/attr = params["liq_messages"]
	switch(attr)
		if("b_show_liq_fullness")
			if(!host.vore_selected.show_fullness_messages)
				host.vore_selected.show_fullness_messages = 1
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] now has liquid examination options.</span>")
			else
				host.vore_selected.show_fullness_messages = 0
				to_chat(usr,"<span class='warning'>Your [lowertext(host.vore_selected.name)] no longer has liquid examination options.</span>")
			. = TRUE
		if("b_liq_msg_toggle1")
			host.vore_selected.liquid_fullness1_messages = !host.vore_selected.liquid_fullness1_messages
			. = TRUE
		if("b_liq_msg_toggle2")
			host.vore_selected.liquid_fullness2_messages = !host.vore_selected.liquid_fullness2_messages
			. = TRUE
		if("b_liq_msg_toggle3")
			host.vore_selected.liquid_fullness3_messages = !host.vore_selected.liquid_fullness3_messages
			. = TRUE
		if("b_liq_msg_toggle4")
			host.vore_selected.liquid_fullness4_messages = !host.vore_selected.liquid_fullness4_messages
			. = TRUE
		if("b_liq_msg_toggle5")
			host.vore_selected.liquid_fullness5_messages = !host.vore_selected.liquid_fullness5_messages
			. = TRUE
		if("b_liq_msg1")
			alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message, max 10 messages per topic.","Really, don't.")
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name."

			var/new_message = input(user,"These are sent to people who examine you when this belly is 0 to 20% full. Write them in 3rd person ('Their %belly is bulging')."+help,"Liquid Examine Message (0 - 20%)",host.vore_selected.get_reagent_messages("full1")) as message
			if(new_message)
				host.vore_selected.set_reagent_messages(new_message,"full1")
			. = TRUE
		if("b_liq_msg2")
			alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message, max 10 messages per topic.","Really, don't.")
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name."

			var/new_message = input(user,"These are sent to people who examine you when this belly is 20 to 40% full. Write them in 3rd person ('Their %belly is bulging')."+help,"Liquid Examine Message (20 - 40%)",host.vore_selected.get_reagent_messages("full2")) as message
			if(new_message)
				host.vore_selected.set_reagent_messages(new_message,"full2")
			. = TRUE
		if("b_liq_msg3")
			alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message, max 10 messages per topic.","Really, don't.")
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name."

			var/new_message = input(user,"These are sent to people who examine you when this belly is 40 to 60% full. Write them in 3rd person ('Their %belly is bulging')."+help,"Liquid Examine Message (40 - 60%)",host.vore_selected.get_reagent_messages("full3")) as message
			if(new_message)
				host.vore_selected.set_reagent_messages(new_message,"full3")
			. = TRUE
		if("b_liq_msg4")
			alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message, max 10 messages per topic.","Really, don't.")
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name."

			var/new_message = input(user,"These are sent to people who examine you when this belly is 60 to 80% full. Write them in 3rd person ('Their %belly is bulging')."+help,"Liquid Examine Message (60 - 80%)",host.vore_selected.get_reagent_messages("full4")) as message
			if(new_message)
				host.vore_selected.set_reagent_messages(new_message,"full4")
			. = TRUE
		if("b_liq_msg5")
			alert(user,"Setting abusive or deceptive messages will result in a ban. Consider this your warning. Max 150 characters per message, max 10 messages per topic.","Really, don't.")
			var/help = " Press enter twice to separate messages. '%pred' will be replaced with your name. '%prey' will be replaced with the prey's name. '%belly' will be replaced with your belly's name."

			var/new_message = input(user,"These are sent to people who examine you when this belly is 80 to 100% full. Write them in 3rd person ('Their %belly is bulging')."+help,"Liquid Examine Message (80 - 100%)",host.vore_selected.get_reagent_messages("full5")) as message
			if(new_message)
				host.vore_selected.set_reagent_messages(new_message,"full5")
			. = TRUE
// End reagent bellies
