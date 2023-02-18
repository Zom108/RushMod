#include common_scripts\utility;
 
main()
{ 
        maps\mp\_load::main();
		maps\mp\dcburning_fx::main();
		
		setexpfog( 4430, 11791, 0.0992, 0.0791, 0.0711, 0.366379, 0);		
		
        game[ "attackers" ] = "allies";
        game[ "defenders" ] = "axis";

		// compass setup
        maps\mp\_compass::setupMiniMap( "compass_map_dcburning" );
        setdvar( "compassmaxrange", "4000" );
		
		thread createFakeSpawns();
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