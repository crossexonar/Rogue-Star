////////////////////////////////////////////////////////////////////////////////////////////////////
//overmap node
/obj/effect/overmap/visitable/sector/centaur944november
	name = "944 November"
	desc = "Home to ice, snow, and more ice."
	scanner_desc = @{"[i]Stellar Body[/i]: 944 November
[i]Class[/i]: Centaur
[i]Habitability[/i]: Low (Extreme Low Temperature)
[b]Notice[/b]: Arctic survival gear is recommended. Contact traffic control for weather advisories."}
	icon_state = "frozen"
	in_space = 0
	initial_generic_waypoints = list("november_surface_e", "november_surface_e")
//	extra_z_levels = list("Z_LEVEL_GLACIER")
	known = TRUE

////////////////////////////////////////////////////////////////////////////////////////////////////
//oregen
//This is a special subtype of the thing that generates ores on a map
//It will generate more rich ores because of the lower numbers than the normal one
/datum/random_map/noise/ore/snowbasemine
	descriptor = "snowbase mine ore distribution map"
	deep_val = 0.6 //More riches, normal is 0.7 and 0.8
	rare_val = 0.5

////////////////////////////////////////////////////////////////////////////////////////////////////
//cold turfs
/turf/simulated/floor/outdoors/snow/snowbase
	temperature = "243.15"

/turf/simulated/floor/outdoors/ice/snowbase
	temperature = "243.15"

/turf/simulated/mineral/crystal/snowbase
	temperature = "243.15"

/turf/simulated/mineral/crystal_shiny/snowbase
	temperature = "243.15"

////////////////////////////////////////////////////////////////////////////////////////////////////
//areas
/area/tether_away/snowbase/
	name = "Away Mission - Snowbase"
	icon_state = "away"
	lightswitch = FALSE
	base_turf = /turf/simulated/floor/outdoors/snow/snowbase

/area/tether_away/snowbase/outside
	name = "Snowbase - Outside"
	ambience = list('sound/music/main.ogg', 'sound/ambience/maintenance/maintenance4.ogg', 'sound/ambience/sif/sif1.ogg', 'sound/ambience/ruins/ruins1.ogg')

/area/tether_away/snowbase/outside/unexplored

/area/tether_away/snowbase/hall
	name = "Snowbase - Hallway"
	lightswitch = 1

/area/tether_away/snowbase/mess
	name = "Snowbase - Mess hall"
	lightswitch = 1

/area/tether_away/snowbase/kitchen
	name = "Snowbase - Kitchen"

/area/tether_away/snowbase/medbay
	name = "Snowbase - Medbay"
	lightswitch = 1

/area/tether_away/snowbase/morgue
	name = "Snowbase - Morgue"

/area/tether_away/snowbase/surgery
	name = "Snowbase - Surgical Suite"

/area/tether_away/snowbase/research
	name = "Snowbase - Research"

/area/tether_away/snowbase/security
	name = "Snowbase - Security"
	lightswitch = 1

/area/tether_away/snowbase/armory
	name = "Snowbase - Armory"

/area/tether_away/snowbase/closet
	name = "Snowbase - Emergency Storage"

/area/tether_away/snowbase/fuelstorage
	name = "Snowbase - Fuel Storage"

/area/tether_away/snowbase/multipurposeroom
	name = "Snowbase - Multipurpose Room"
	lightswitch = 1

/area/tether_away/snowbase/engineering
	name = "Snowbase - Engineering Bay"
	lightswitch = 1

/area/tether_away/snowbase/reactor
	name = "Snowbase - Reactor Room"

/area/tether_away/snowbase/atmospherics
	name = "Snowbase - Atmospherics"

/area/tether_away/snowbase/janitor
	name = "Snowbase - Janitorial"

/area/tether_away/snowbase/mining
	name = "Snowbase - Refinery"

////////////////////////////////////////////////////////////////////////////////////////////////////
//oregen
