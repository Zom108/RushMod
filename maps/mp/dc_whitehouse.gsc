#include common_scripts\utility;
 
main()
{
	maps\mp\_load::main();

	ambientplay("ambient_dcemp_light_rain");

		maps\mp\dc_whitehouse_fx::main();
		
        game[ "attackers" ] = "axis";
        game[ "defenders" ] = "allies";

        createSpawnpoint( "mp_tdm_spawn_axis_start", (0, 0, 0), 0.0 );
        createSpawnpoint( "mp_tdm_spawn_allies_start", (0, 0, 0), 0.0 );
        createSpawnpoint( "mp_tdm_spawn", (0, 0, 0), 0.0 );
 
        maps\mp\_compass::setupMiniMap( "compass_map_dc_whitehouse" );
        setdvar( "compassmaxrange", "4000" );
  
        array_thread( getentarray( "compassTriggers", "targetname" ), ::compass_triggers_think );

		//playerWeather();
}

playerWeather()
{
	player = getentarray( "player", "classname" )[ 0 ];
	for ( ;; )
	{
		playfx( level._effect[ "rain_7" ], player.origin + ( 0, 0, 650 ), player.origin + ( 0, 0, 680 ) );
		wait( 0.3 );
	}
}
 
  
compass_triggers_think()
{
        assertex( isdefined( self.script_noteworthy ), "compassTrigger at " + self.origin + " needs to have a script_noteworthy with the name of the minimap to use" );
        while( true )
        {
                wait( 1 );
                self waittill( "trigger" );
                maps\mp\_compass::setupMiniMap( self.script_noteworthy );
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