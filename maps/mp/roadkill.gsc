#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
        maps\createart\roadkill_art::main();
        maps\createfx\roadkill_fx::main();
        maps\mp\roadkill_fx::main();
        maps\mp\_load::main();

        game[ "attackers" ] = "allies";
        game[ "defenders" ] = "axis";

        maps\mp\_compass::setupMiniMap( "compass_map_roadkill" );
        setdvar( "r_specularcolorscale", "2.5" );
        setdvar( "r_lightGridEnableTweaks", 1 );
        setdvar( "r_lightGridIntensity", 1.11 );
        setdvar( "r_lightGridContrast", .9 );
        ambientPlay( "ambient_mp_invasion" );
		
}