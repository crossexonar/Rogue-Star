/* RS FILE
 * rsh-12
 */
/obj/item/weapon/gun/projectile/revolver/rsh
	name = "RSH-12 Requiem"
	desc = "RSH-12 'Requiem', for when you need to put an even bigger hole through something big, an absolute cannon of a handgun,  Uses Custom made 12.7x55 rounds."
	icon = 'code/game/Rogue Star/icons/itemicons/borkmedigun.dmi'
	icon_state = "rsh"
	item_state = "rsh"
	caliber = "12.7x55"
	origin_tech = list(TECH_COMBAT = 2, TECH_MATERIAL = 2)
	handle_casings = CYCLE_CASINGS
	max_shells = 5
	ammo_type = /obj/item/ammo_casing/a357
	projectile_type = /obj/item/projectile/bullet/pistol/strong
	chamber_offset = 0 //how many empty chambers in the cylinder until you hit a round
