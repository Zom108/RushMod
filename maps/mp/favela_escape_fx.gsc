#include common_scripts\utility;

main()
{
	level._effect[ "technical_gate_shatter" ] = LoadFX( "explosions/wood_explosion_1" );

	level._effect[ "bird_takeoff_pm" ] = LoadFX( "misc/bird_takeoff_pm" );

	level._effect[ "headshot" ] = LoadFX( "impacts/flesh_hit_head_fatal_exit" );
	level._effect[ "bodyshot" ]	= LoadFX( "impacts/flesh_hit" );

	// ambient level fx
	level._effect[ "insects_carcass_runner" ] 	= LoadFX( "misc/insects_carcass_runner" );
	level._effect[ "firelp_med_pm" ] 			= LoadFX( "fire/firelp_med_pm" );
	level._effect[ "firelp_small_pm_a" ] 		= LoadFX( "fire/firelp_small_pm_a" );
	level._effect[ "dust_wind_fast" ] 			= LoadFX( "dust/dust_wind_fast" );
	level._effect[ "dust_wind_fast_light" ] 	= LoadFX( "dust/dust_wind_fast_light" );
	level._effect[ "trash_spiral_runner" ] 		= LoadFX( "misc/trash_spiral_runner" );
	level._effect[ "trash_spiral_runner_far" ] 	= LoadFX( "misc/trash_spiral_runner_far" );
	level._effect[ "leaves_fall_gentlewind" ] 	= LoadFX( "misc/leaves_fall_gentlewind" );
	level._effect[ "leaves_ground_gentlewind" ] = LoadFX( "misc/leaves_ground_gentlewind" );
	level._effect[ "hallway_smoke_light" ] 		= LoadFX( "smoke/hallway_smoke_light" );
	level._effect[ "battlefield_smokebank_S" ] 	= LoadFX( "smoke/battlefield_smokebank_S" );
	level._effect[ "room_smoke_200" ] 			= LoadFX( "smoke/room_smoke_200" );
	level._effect[ "room_smoke_200_fast_far" ] 	= LoadFX( "smoke/room_smoke_200_fast_far" );
	level._effect[ "insect_trail_runner_icbm" ] = LoadFX( "misc/insect_trail_runner_icbm" );
	level._effect[ "moth_runner" ] 				= LoadFX( "misc/moth_runner" );
	level._effect[ "insects_light_invasion" ] 	= LoadFX( "misc/insects_light_invasion" );
	level._effect[ "chimney_small" ] 			= LoadFX( "smoke/chimney_small" );
	level._effect[ "chimney_large" ] 			= LoadFX( "smoke/chimney_large" );
	level._effect[ "roof_slide" ] 				= LoadFX( "misc/roof_slide" );

	// airliner exhaust
	level._effect[ "airliner_exhaust" ]			= LoadFX( "fire/jet_engine_anatov_constant" );
	level._effect[ "airliner_wingtip_left" ]	= LoadFX( "misc/aircraft_light_wingtip_green" );
	level._effect[ "airliner_wingtip_right" ]	= LoadFX( "misc/aircraft_light_wingtip_red" );
	level._effect[ "airliner_tail" ]			= LoadFX( "misc/aircraft_light_white_blink" );
	level._effect[ "airliner_belly" ]			= LoadFX( "misc/aircraft_light_red_blink" );

	// fake chopper shellejects
	level._effect[ "hind_fake_shelleject" ] = LoadFX( "shellejects/20mm_cargoship" );

	// fake rotor wash dust
	level._effect[ "hind_fake_rotorwash_dust" ] = LoadFX( "treadfx/heli_dust_icbm" );

	// chopper flares
	level.flare_fx[ "pavelow" ] = LoadFX( "misc/flares_cobra" );

	// fake explosions for the chopper owning
	level._effect[ "hind_fake_explosion_1" ] = LoadFX( "explosions/grenadeexp_metal" );
	level._effect[ "hind_fake_explosion_2" ] = LoadFX( "explosions/circuit_breaker" );
	level._effect[ "hind_fake_explosion_3" ] = LoadFX( "explosions/pillar_explosion_brick_invasion" );

	// fx for player falling
	level._effect[ "playerfall_impact" ] = LoadFX( "impacts/bodyfall_dust_large" );
	level._effect[ "playerfall_residual" ] = LoadFX( "explosions/breach_room_residual" );

	// fake squibs around player
	level._effect[ "squib_plaster" ] = LoadFX( "impacts/large_plaster" );


	level._effect[ "flashlight" ] = LoadFX( "misc/gulag_cafe_spotlight" );

	maps\createart\favela_escape_art::main();
	maps\createfx\favela_escape_fx::main();

	//levelstart_fx_setup();
}

bird_startle_trigs()
{
	trigs = GetEntArray( "trig_bird_startle", "targetname" );
	array_thread( trigs, ::bird_startle_trig_think );
}

bird_startle_trig_think()
{
	ASSERT( IsDefined( self.script_exploder ), "Bird startle trigger at origin " + self.origin + " doesn't have script_exploder set." );
	exploderName = self.script_exploder;

	self waittill( "trigger" );
	level thread exploder( exploderName );

	self Delete();
}

levelstart_fx_setup()
{
	lights = GetEntArray( "flickerlight_fire", "script_noteworthy" );
	array_thread( lights, ::flickerlight_fire );
}

flickerlight_fire()
{
	wait( RandomFloatRange( .05, .5 ) );

	intensity = self GetLightIntensity();

	for ( ;; )
	{
		self SetLightIntensity( intensity * RandomFloatRange( 1.2, 2.2 ) );
		wait( RandomFloatRange( .05, 1 ) );
	}
}