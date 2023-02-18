#include common_scripts\utility;
 
main()
{
        maps\mp\_load::main();
		
		maps\createart\favela_art::main();
		maps\mp\favela_fx::main();
 
        game[ "attackers" ] = "axis";
        game[ "defenders" ] = "allies";
	
		ambientplay("ambient_favela_ext0");
		
        maps\mp\_compass::setupMiniMap( "compass_map_favela" );
        setdvar( "compassmaxrange", "4000" );
        createSpawnpoint( "mp_tdm_spawn_axis_start", (4658, 161, 1107), 0.0 );
        createSpawnpoint( "mp_tdm_spawn_allies_start", (4658, 161, 1107), 0.0 );
        createSpawnpoint( "mp_tdm_spawn", (4658, 161, 1107), 0.0 );		
}

 
self_delete()
{
        self delete();
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

