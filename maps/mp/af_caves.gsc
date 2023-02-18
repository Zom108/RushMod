#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
        maps\mp\_load::main();
		maps\mp\af_caves_fx::main();
		//maps\createart\af_caves_fog::main();
		
		//ambientplay("ambient_af_caves_ext");
		
		precachestring(&"AF_CAVES_RAPPEL_HINT");
		precachempanim("afgan_caves_player_rappel_hookup");
		
        game[ "attackers" ] = "axis";
        game[ "defenders" ] = "allies";

	// compass setup
        maps\mp\_compass::setupMiniMap( "compass_map_afghan_caves" );
        setdvar( "compassmaxrange", "4000" );
		
		thread createFakeSpawns();
		
		//thread testEnding();
		//thread endingExplosion();
		thread createRappel();
}

createRappel()
{

rappel1 = spawn("script_model", (2968, 11890, -1775));
rappel1 setmodel("com_plasticcase_friendly");
rappel1 hide();
//string = &"AF_CAVES_RAPPEL_HINT";
rappel1 thread maps\mp\gulag::RappelRopeUse((2384, 11714, -3723), 1948, undefined, 4, &"AF_CAVES_RAPPEL_HINT", "");

rappel2 = spawn("script_model", (4449.64, 4424.8, -3180.78));
rappel2 setmodel("com_plasticcase_friendly");
rappel2 hide();
rappel2 thread maps\mp\gulag::RappelRopeUse((4400, 4328, -2652), 1948, undefined, 3, &"AF_CAVES_RAPPEL_HINT", "");

thread triggerThingJump();
}

triggerThingJump()
{


jumptrigger = spawn("trigger_radius", (4534.27, 4526.53, -3255.39), 0, 90, 300);

while(1)
{

	jumpTrigger waittill("trigger", player);
	
	if(!isdefined(player.big_jump_triggerOff))
	{
	i = player getVelocity();
	player setVelocity(i * 2);
	player iprintlnbold("jump");
	player thread setCannotjump();
	}
	wait 0.05;
}


}

setCannotjump()
{
self.big_jump_triggerOff = 1;

wait 3;
self.big_jump_triggerOff = undefined;
}



endingExplosion()
{

	

	rock_rubble1 = GetEnt( "rock_rubble1", "targetname" );

			
		foreach(player in level.players)
		{
			
			if(distance(player.origin, rock_rubble1.origin) <= 700)
			{
			player shellshock("default", 4);
			player PlayRumbleOnEntity( "damage_heavy" );
			Earthquake( .4, 1.75, player.origin, 1000 );
			}
		}
		
		wait 3;
		//startPoint = level.ac130 getTagOrigin( "tag_player" );
		pathStart = (10856, 8704, -2866);
		//pathStart = startPoint + ( (randomfloat(2) - 1)*100, (randomfloat(2) - 1)*100, 0 );
		uavRig = spawnPlane( level.players[randomint(level.players.size)], "script_model", pathStart, "compass_objpoint_ac130_friendly", "compass_objpoint_ac130_enemy" );
		
		magicbullet("ac130_105mm_mp", bullettrace(rock_rubble1.origin + (51521, 513513, 5131), rock_rubble1.origin, false, false)["position"], rock_rubble1.origin);
		wait 0.3;
		rock_rubble1 playSound("af_caves_selfdestruct");	
		PlayFX( level._effect[ "cave_explosion_exit" ], rock_rubble1.origin );
		Earthquake( 1, 1, rock_rubble1.origin, 600 );
		magicbullet("ac130_105mm_mp", pathStart, rock_rubble1.origin);
		wait 0.1;
		rock_rubble1 delete();
		uavRig delete();
}

	

CreateFakeSpawns()
{
/*
createSpawnpoint( "mp_tdm_spawn_allies_start", (1441, 3676, -5235), 50 );
createSpawnpoint( "mp_tdm_spawn_axis_start", (1441, 3676, -5235), 50 );
createSpawnpoint( "mp_tdm_spawn", (1441, 3676, -5235), 50 );
createSpawnpoint( "mp_global_intermission", (1441, 3676, -5235), 50 );
*/

thing2 = getentarray("info_player_start", "classname");

foreach(thing in thing2)
{

createSpawnpoint( "mp_tdm_spawn_allies_start", thing.origin, 50 );
createSpawnpoint( "mp_tdm_spawn_axis_start", thing.origin, 50 );
createSpawnpoint( "mp_tdm_spawn", thing.origin, 50 );
createSpawnpoint( "mp_global_intermission", thing.origin, 50 );
createSpawnpoint( "mp_dm_spawn", thing.origin, 50 );
}
}

createSpawnpoint( classname, origin, yaw )
{
	spawnpoint = spawn( "script_origin", origin );
	spawnpoint.angles = (0,yaw,0);
	
	if ( !isdefined( level.extraspawnpoints ) )
		level.extraspawnpoints = [];
	if ( !isdefined( level.extraspawnpoints[classname] ) )
		level.extraspawnpoints[classname] = [];
	level.extraspawnpoints[classname][ level.extraspawnpoints[classname].size ] = spawnpoint;
}