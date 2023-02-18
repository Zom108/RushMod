#include common_scripts\utility;
 
main()
{	

	maps\mp\_load::main();
	maps\mp\favela_escape_fx::main();
	
	game[ "attackers" ] = "axis";
	game[ "defenders" ] = "allies";

	maps\mp\_compass::setupMiniMap( "compass_map_favela_escape" );
	setdvar( "compassmaxrange", "4000" );
	
	ambientPlay("ambient_favela_escape_ext0");
	
		
	thread createFakeSpawns();
		
		
}

CreateFakeSpawns()
{

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