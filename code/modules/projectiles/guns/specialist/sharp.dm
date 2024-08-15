//-------------------------------------------------------
//P9 Sonic Harpoon Artillery Remote Projectile(SHARP) Rifle

/obj/item/weapon/gun/rifle/sharp
	name = "\improper P9 SHARP rifle"
	desc = "An experimental harpoon launcher rifle with an inbuilt magnetic harness manufactured by Armat Systems. It's specialized for specific ammo types out of a 10-round magazine, best used for area denial and disruption."
	icon_state = "sharprifle"
	item_state = "sharp"
	fire_sound = 'sound/weapons/gun_sharp.ogg'
	reload_sound = 'sound/weapons/handling/m41_reload.ogg'
	unload_sound = 'sound/weapons/handling/m41_unload.ogg'
	unacidable = TRUE
	indestructible = TRUE
	muzzle_flash = null

	current_mag = /obj/item/ammo_magazine/rifle/sharp/explosive
	attachable_allowed = list()
	auto_retrieval_slot = WEAR_J_STORE

	aim_slowdown = SLOWDOWN_ADS_SPECIALIST
	wield_delay = WIELD_DELAY_NORMAL
	flags_gun_features = GUN_SPECIALIST|GUN_WIELDED_FIRING_ONLY|GUN_CAN_POINTBLANK|GUN_AMMO_COUNTER

	flags_item = TWOHANDED|NO_CRYO_STORE
	map_specific_decoration = TRUE

	var/explosion_delay_sharp = TRUE


/obj/item/weapon/gun/rifle/sharp/set_gun_attachment_offsets()
	attachable_offset = list("muzzle_x" = 32, "muzzle_y" = 17,"rail_x" = 12, "rail_y" = 22, "under_x" = 23, "under_y" = 13, "stock_x" = 24, "stock_y" = 13)

/obj/item/weapon/gun/rifle/sharp/set_gun_config_values()
	..()
	set_burst_amount(BURST_AMOUNT_TIER_1)
	fire_delay = FIRE_DELAY_TIER_AMR
	accuracy_mult = BASE_ACCURACY_MULT
	scatter = SCATTER_AMOUNT_NONE
	damage_mult = BASE_BULLET_DAMAGE_MULT
	recoil = RECOIL_OFF


/obj/item/weapon/gun/rifle/sharp/unload_chamber(mob/user)
	if(!in_chamber)
		return
	var/found_handful
	for(var/obj/item/ammo_magazine/handful/H in user.loc)
		if(H.default_ammo == in_chamber.ammo.type && H.caliber == caliber && H.current_rounds < H.max_rounds)
			found_handful = TRUE
			H.current_rounds++
			H.update_icon()
			break
	if(!found_handful)
		var/obj/item/ammo_magazine/handful/new_handful = new(get_turf(src))
		new_handful.generate_handful(in_chamber.ammo.type, caliber, 5, 1, type)

/obj/item/weapon/gun/rifle/sharp/able_to_fire(mob/living/user)
	. = ..()
	if (. && istype(user))
		if(!skillcheck(user, SKILL_SPEC_WEAPONS, SKILL_SPEC_ALL) && user.skills.get_skill_level(SKILL_SPEC_WEAPONS) != SKILL_SPEC_GRENADIER)
			to_chat(user, SPAN_WARNING("You don't seem to know how to use \the [src]..."))
			return FALSE

//code for changing explosion delay on direct hits

/obj/item/weapon/gun/rifle/sharp/do_toggle_firemode(mob/user)
	. = ..()
	explosion_delay_sharp = !explosion_delay_sharp
	playsound(user, 'sound/weapons/handling/gun_burst_toggle.ogg', 15, 1)
	to_chat(user, SPAN_NOTICE("[icon2html(src, user)] You [explosion_delay_sharp ? SPAN_BOLD("enable") : SPAN_BOLD("disable")] [src]'s delayed fire mode. Explosive ammo will blow up in [explosion_delay_sharp ? SPAN_BOLD("five seconds") : SPAN_BOLD("one second")]."))

//code for changing flechette ammo rate of fire

/obj/item/weapon/gun/rifle/sharp/reload(mob/user, obj/item/ammo_magazine/magazine)
	. = ..()
	if(magazine.type == /obj/item/ammo_magazine/rifle/sharp/flechette)
		set_fire_delay(FIRE_DELAY_TIER_SNIPER)
	else
		set_fire_delay(FIRE_DELAY_TIER_AMR)


/*
//========
					SHARP Dart Ammo
//========
*/
/datum/ammo/rifle/sharp
	name = "dart"
	ping = null //no bounce off.
	damage_type = BRUTE
	shrapnel_type = /obj/item/sharp
	flags_ammo_behavior = AMMO_SPECIAL_EMBED|AMMO_NO_DEFLECT|AMMO_STRIKES_SURFACE_ONLY|AMMO_HITS_TARGET_TURF
	icon_state = "sharp_explosive_dart"
	handful_state = "sharp_explosive"
	var/embed_object = /obj/item/sharp/explosive
	var/mine_level = 0

	shrapnel_chance = 100
	accuracy = HIT_ACCURACY_TIER_MAX
	accurate_range = 12
	max_range = 7
	damage = 35
	shell_speed = AMMO_SPEED_TIER_2

/datum/ammo/rifle/sharp/on_embed(mob/embedded_mob, obj/limb/target_organ)
	if(!ishuman(embedded_mob))
		return
	var/mob/living/carbon/human/humano = embedded_mob
	if(humano.species.flags & NO_SHRAPNEL)
		return
	if(istype(target_organ))
		target_organ.embed(new embed_object)

/datum/ammo/rifle/sharp/on_hit_obj(obj/O, obj/projectile/P)
	drop_dart(P.loc, P)

/datum/ammo/rifle/sharp/on_hit_turf(turf/T, obj/projectile/P)
	drop_dart(T, P)

/datum/ammo/rifle/sharp/do_at_max_range(obj/projectile/P)
	drop_dart(P.loc, P)

/datum/ammo/rifle/sharp/proc/drop_dart(loc, obj/projectile/P)
	new embed_object(loc, P.dir)

/datum/ammo/rifle/sharp/explosive
	name = "9X-E sticky explosive dart"

/datum/ammo/rifle/sharp/explosive/on_hit_mob(mob/living/M, obj/projectile/P)
	if(!M || M == P.firer) return
	var/mob/shooter = P.firer
	shake_camera(M, 2, 1)
	if(shooter && ismob(shooter))
		if(!M.get_target_lock(shooter.faction_group))
			var/obj/item/weapon/gun/rifle/sharp/weapon = P.shot_from
			playsound(get_turf(M), 'sound/weapons/gun_sharp_explode.ogg', 100)
			if(weapon && weapon.explosion_delay_sharp)
				addtimer(CALLBACK(src, PROC_REF(delayed_explosion), P, M, shooter), 5 SECONDS)
			else
				addtimer(CALLBACK(src, PROC_REF(delayed_explosion), P, M, shooter), 1 SECONDS)

/datum/ammo/rifle/sharp/explosive/drop_dart(loc, obj/projectile/P, mob/shooter)
	var/signal_explosion = FALSE
	if(locate(/obj/item/explosive/mine) in get_turf(loc))
		signal_explosion = TRUE
	var/obj/item/explosive/mine/sharp/dart = new /obj/item/explosive/mine/sharp(loc)
	// if no darts on tile, don't arm, explode instead.
	if(signal_explosion)
		INVOKE_ASYNC(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp, prime), shooter)
	else
		dart.anchored = TRUE
		addtimer(CALLBACK(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp, deploy_mine), shooter), 3 SECONDS, TIMER_DELETE_ME)
		addtimer(CALLBACK(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp, disarm)), 5 MINUTES, TIMER_DELETE_ME)

/datum/ammo/rifle/sharp/explosive/proc/delayed_explosion(obj/projectile/P, mob/M, mob/shooter)
	if(ismob(M))
		var/explosion_size = 50
		var/falloff_size = 50
		var/cause_data = create_cause_data("P9 SHARP Rifle", shooter)
		cell_explosion(get_turf(M), explosion_size, falloff_size, EXPLOSION_FALLOFF_SHAPE_LINEAR, P.dir, cause_data)


/datum/ammo/rifle/sharp/incendiary
	name = "9X-T sticky incendiary dart"
	icon_state = "sharp_incendiary_dart"
	handful_state = "sharp_incendiary"
	embed_object = /obj/item/sharp/incendiary

/datum/ammo/rifle/sharp/incendiary/on_hit_mob(mob/living/M, obj/projectile/P)
	if(!M || M == P.firer) return
	var/mob/shooter = P.firer
	shake_camera(M, 2, 1)
	if(shooter && ismob(shooter))
		if(!M.get_target_lock(shooter.faction_group))
			var/obj/item/weapon/gun/rifle/sharp/weapon = P.shot_from
			playsound(get_turf(M), 'sound/weapons/gun_sharp_explode.ogg', 100)
			if(weapon && weapon.explosion_delay_sharp)
				addtimer(CALLBACK(src, PROC_REF(delayed_fire), P, M, shooter), 5 SECONDS)
			else
				addtimer(CALLBACK(src, PROC_REF(delayed_fire), P, M, shooter), 1 SECONDS)

/datum/ammo/rifle/sharp/incendiary/drop_dart(loc, obj/projectile/P, mob/shooter)
	var/signal_explosion = FALSE
	if(locate(/obj/item/explosive/mine) in get_turf(loc))
		signal_explosion = TRUE
	var/obj/item/explosive/mine/sharp/incendiary/dart = new /obj/item/explosive/mine/sharp/incendiary(loc)
	// if no darts on tile, don't arm, explode instead.
	if(signal_explosion)
		INVOKE_ASYNC(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp/incendiary, prime), shooter)
	else
		dart.anchored = TRUE
		addtimer(CALLBACK(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp, deploy_mine), shooter), 3 SECONDS, TIMER_DELETE_ME)
		addtimer(CALLBACK(dart, TYPE_PROC_REF(/obj/item/explosive/mine/sharp, disarm)), 5 MINUTES, TIMER_DELETE_ME)

/datum/ammo/rifle/sharp/incendiary/proc/delayed_fire(obj/projectile/P, mob/M, mob/shooter)
	if(ismob(M))
		var/datum/effect_system/smoke_spread/phosphorus/smoke = new /datum/effect_system/smoke_spread/phosphorus/sharp
		var/smoke_radius = 2
		smoke.set_up(smoke_radius, 0, get_turf(M))
		smoke.start()

/datum/ammo/rifle/sharp/flechette
	name = "9X-F flechette dart"
	icon_state = "sharp_flechette_dart"
	handful_state = "sharp_flechette"
	embed_object = /obj/item/sharp/flechette
	shrapnel_type = /datum/ammo/bullet/shotgun/flechette_spread

/datum/ammo/rifle/sharp/flechette/on_hit_mob(mob/living/M, obj/projectile/P)
	if(!M || M == P.firer) return
	var/mob/shooter = P.firer
	shake_camera(M, 2, 1)
	if(shooter && ismob(shooter))
		if(!M.get_target_lock(shooter.faction_group))
			create_flechette(M.loc, P)

/datum/ammo/rifle/sharp/flechette/on_pointblank(mob/living/M, obj/projectile/P)
	if(!M) return
	P.dir = get_dir(P.firer, M)

/datum/ammo/rifle/sharp/flechette/on_hit_obj(obj/O, obj/projectile/P)
	create_flechette(O.loc, P)

/datum/ammo/rifle/sharp/flechette/on_hit_turf(turf/T, obj/projectile/P)
	create_flechette(T, P)

/datum/ammo/rifle/sharp/flechette/do_at_max_range(obj/projectile/P)
	create_flechette(P.loc, P)

/datum/ammo/rifle/sharp/flechette/proc/create_flechette(loc, obj/projectile/P)
	var/shrapnel_count = 6
	var/dispersion_angle = 20
	create_shrapnel(loc, shrapnel_count, P.dir, dispersion_angle, shrapnel_type, P.weapon_cause_data, FALSE, 1)
	apply_explosion_overlay(loc)

/datum/ammo/rifle/sharp/flechette/proc/apply_explosion_overlay(turf/loc)
	var/obj/effect/overlay/O = new /obj/effect/overlay(loc)
	O.name = "grenade"
	O.icon = 'icons/effects/explosion.dmi'
	flick("grenade", O)
	QDEL_IN(O, 7)