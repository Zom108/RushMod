#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	maps\mp\_load::main();

	/*      
	createSpawnpoint( "mp_tdm_spawn_axis_start", (-1465, -2051, 1870), 0.0 );
	createSpawnpoint( "mp_tdm_spawn_allies_start", (-2667, 1136, 1869), 0.0 );
	createSpawnpoint( "mp_tdm_spawn", (-2667, 1136, 1869), 0.0 );
	createSpawnpoint( "mp_tdm_spawn", (-1576, -1922, 1869), 0.0 ); 
	*/

	maps\mp\gulag_fx::main();
	maps\createfx\gulag_fx::main();

	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";

	maps\mp\_compass::setupMiniMap( "compass_map_gulag" );
	setdvar( "compassmaxrange", "4000" );

	array_thread( getentarray( "breach_solid", "targetname" ), ::self_delete );

	array_thread( getentarray( "compassTriggers", "targetname" ), ::compass_triggers_think );
	thread explodingTower();

	precachestring( &"GULAG_HOLD_1_TO_RAPPEL" );

	precachemodel( "gulag_rappel_rope_player_60ft" );
	precachemodel( "gulag_escape_rope_100ft" );

	precachempanim( "gulag_rappel_player_rope_60ft" );
	precachempanim( "rappel_start" );
	precachempanim( "gulag_rappel_player" );
	precachempanim( "gulag_escape_rope" );
	thread spawn_rappel_rope();
}

explodingTower()
{
	wait 220;
	wait( 1.5 );
	exploder( "tower_explosion_fx" );
	wait( 0.15 );
	exploder( "tower_explosion" );
	wait( .15 );
	exploder( "tower_explosion_fx" );
	wait 1;
	exploder( "main_building" );
	wait 0.5;

	for ( i = 0; i < 41; i++ )
	{
		exploder( i );
		earthquake( 0.2, 5 );
		//iprintln(i);
		wait 0.1;
	}

	/*
	exploder("39");
	exploder("38");
	exploder("37");
	exploder("boat_attack");
	*/
}

self_delete()
{
	self delete();
}

compass_triggers_think()
{
	assertex( isdefined( self.script_noteworthy ), "compassTrigger at " + self.origin + " needs to have a script_noteworthy with the name of the minimap to use" );

	for ( ;; )
	{
		wait( 1 );
		self waittill( "trigger" );
		maps\mp\_compass::setupMiniMap( self.script_noteworthy );
	}
}

createSpawnpoint( classname, origin, yaw )
{
	spawnpoint = spawn( "script_origin", origin );
	spawnpoint.angles = ( 0, yaw, 0 );

	if ( !isdefined( level.extraspawnpoints ) )
		level.extraspawnpoints = [];

	if ( !isdefined( level.extraspawnpoints[classname] ) )
		level.extraspawnpoints[classname] = [];

	level.extraspawnpoints[classname][ level.extraspawnpoints[classname].size ] = spawnpoint;
}


CreateRappelRope( rappelEnt, endEnt, model, speed )
{
	if ( !isdefined( level.rappel_rope ) )
		level.rappel_rope[0] = "";

	level.rappel_rope++;
	/*
		level.rappel_rope[level.rappel_rope.size] = spawn( "script_model", rappelEnt.origin );
		level.rappel_rope[level.rappel_rope.size] setmodel(model);
		level.rappel_rope[level.rappel_rope.size].angles = rappelEnt.angles;
		level.rappel_rope[level.rappel_rope.size] scriptmodelplayanim(model);
	*/
	level.rappel_rope[0] = spawn( "script_model", rappelEnt.origin );
	level.rappel_rope[0] setmodel( model );
	level.rappel_rope[0].angles = rappelEnt.angles;
	level.rappel_rope[0] scriptmodelplayanim( model );

	wait 0.4;

	//thread RappelRopeUse(rappelEnt, endEnt, model, speed);
}

playerRappelArea( trigger )
{
	self endon( "left_trigger" );

	self.rappelTriggers++;

	if ( self.rappelTriggers == 1 )
	{
		self setLowerMessage( "1", &"GULAG_HOLD_1_TO_RAPPEL" );

		for ( ;; )
		{
			if ( self usebuttonpressed() )
			{
				self setorigin( trigger.origin );
				trigger.player = self;
				self iprintlnbold( "test" );
				trigger notify( "someone_touched" );
			}

			wait 0.5;
		}
	}

}

playerLeaveRappel( trigger )
{
	self notify( "left_trigger" );
	self clearlowermessage( "1", 0.4 );
	self.rappelTriggers = 0;
}

RappelRopeUse( endEnt, height, trigger, speed, string, animation )
{
	if ( isdefined( trigger ) )
		trigger_ent = GetEnt( trigger, "targetname" );
	else
	{
		trigger_ent = spawn( "script_model", self.origin );
		/*
		trigger_ent = spawn( "trigger_radius", self.origin, 0, 40, 10 );
		trigger_ent common_scripts\_dynamic_world::triggerTouchThink( ::playerRappelArea, ::playerLeaveRappel );
		*/
		//trigger_ent setmodel("com_plasticcase_enemy");
	}

	if ( !isdefined( speed ) )
		speed = 4;

	if ( !isdefined( string ) )
		string = &"GULAG_HOLD_1_TO_RAPPEL";

	// Press and hold^3 &&1 ^7to rappel.
	trigger_ent setcursorhint( "HINT_ACTIVATE" );
	trigger_ent SetHintString( string );
	trigger_ent makeUsable();

	for ( ;; )
	{
		/*
		if(isdefined(trigger))
			trigger_ent waittill( "trigger", player );
		else
			trigger_ent waittill("someone_touched", player);

		trigger_ent waittill("someone_touched");
		player = trigger_ent.player;
		*/
		trigger_ent waittill( "trigger", player );

		start = endEnt + ( 0, 0, height );

		if ( getdvar( "mapname" ) == "af_caves" )
			start = self.origin;

		player playsound( "rappel_liftrope_clipin_plr" );
		player disableweapons();
		player setstance( "stand" );
		rappelObj = spawn( "script_model", start );

		if ( isdefined( animation ) )
		{
			rappelObj setmodel( player getviewmodel() );
			rappelObj scriptmodelplayanim( animation );
		}
		else
		{
			rappelObj setmodel( "com_plasticcase_friendly" );
			rappelObj hide();
		}

		rappelObj hide();
		//rappelObj.angles = (0, 90, 0);
		//player setplayerangles( vectortoangles( endEnt ) );
		//rappelObj rotateto( vectortoangles( start ), 0.1 );
		//rappelObj hide();
		trigger_ent makeUnUsable();
		player playerlinktoblend( rappelObj, "", 0.1, 0.1, 0.1 );
		//player playerlinktodelta(rappelObj);

		wait 1;
		rappelObj showtoplayer( player );
		rappelObj moveto( endEnt, speed );
		wait 0.1;
		self playsound( "rappel_pushoff_initial_plr" );
		rappelObj waittill( "movedone" );
		/*
		wait 0.2;
		self playsound("rappel_pushoff_repeat_plr");
		wait 0.8;
		self playsound("rappel_pushoff_repeat_plr");
		*/
		trigger_ent makeUsable();
		wait 0.2;
		player playsound( "rappel_clipout_plr" );
		player unlink();
		player enableweapons();
		rappelObj delete();
	}
}

spawn_rappel_rope()
{
	level.cellblock_rope_ai = spawn( "script_model", ( -2320.1, -48.8096, 1230 ) );
	level.cellblock_rope_ai setmodel( "gulag_rappel_rope_player_60ft" );
	level.cellblock_rope_ai.angles = ( 0, 235.5, 0 );
	level.cellblock_rope_ai scriptmodelplayanim( "gulag_rappel_player_rope_60ft" );
	level.cellblock_rope_ai thread RappelRopeUse( ( -2362, -97, 824 ), 450, undefined, 1, undefined, "" );

	level.cellblock_rope_player = spawn( "script_model", ( -2297.98, -64.2961, 1230 ) );
	level.cellblock_rope_player setmodel( "gulag_rappel_rope_player_60ft" );
	level.cellblock_rope_player.angles = ( 0, 233.4, 0 );
	level.cellblock_rope_player scriptmodelplayanim( "gulag_rappel_player_rope_60ft" );
	level.cellblock_rope_ai thread RappelRopeUse( ( -2339, -109, 828 ), 450, undefined, 1, undefined, "" );

	level.hook_rope = spawn( "script_model", ( -4602, -976, 1876 ) );
	level.hook_rope setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope.angles = ( 0, 0, 90 );
	level.hook_rope thread RappelRopeUse( ( -4602, -976, 316 ), 1500 );

	level.hook_rope_2 = spawn( "script_model", ( -4645, -1080, 1882 ) );
	level.hook_rope_2 setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope_2.angles = ( 0, 0, 90 );
	level.hook_rope_2 thread RappelRopeUse( ( -4645, -1080, 499 ), 1200 );

	level.hook_rope_3 = spawn( "script_model", ( -4594, -1073, 1888 ) );
	level.hook_rope_3 setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope_3.angles = ( 0, 0, 90 );
	level.hook_rope_3 thread RappelRopeUse( ( -4594, -1073, 318 ), 1530 );

	level.hook_rope_ext = spawn( "script_model", ( -4602, -976, 572 ) );
	level.hook_rope_ext setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope_ext.angles = ( 0, 0, 90 );

	level.hook_rope_ext_2 = spawn( "script_model", ( -4645, -1080, 699 ) );
	level.hook_rope_ext_2 setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope_ext_2.angles = ( 0, 0, 90 );

	level.hook_rope_ext_3 = spawn( "script_model", ( -4594, -1073, 699 ) );
	level.hook_rope_ext_3 setmodel( "gulag_escape_rope_100ft" );
	level.hook_rope_ext_3.angles = ( 0, 0, 90 );
}

cellblock_rappel_player()
{
	ent = SpawnStruct();
	ent.rope = level.cellblock_rope_player;
	ent.flag_name = "player_rappels";
	ent.rope_ent = GetEnt( "rappel_player_ent", "targetname" );
	ent.scene = "rappel_start";
	ent.unlink_time = 5.35;
	player_rappels( ent );

	wait( 1.8 );
}

player_rappels( ent )
{
	//trigger_ent = GetEnt( "rappel_trigger", "script_noteworthy" );
	trigger_ent = GetEnt( "rappel_key", "targetname" );
	level.players[level.players.size] setorigin( trigger_ent.origin );
	trigger_ent setcursorhint( "HINT_ACTIVATE" );
	// Press and hold^3 &&1 ^7to rappel.
	trigger_ent SetHintString( "GULAG_HOLD_1_TO_RAPPEL" );

	trigger_ent makeUsable();

	//trigger_ent waittill( "trigger", player );

	player = GetHost();
	player iprintlnbold( "derp" );

	if ( player GetStance() != "stand" )
	{
		player SetStance( "stand" );
		wait( 0.4 );
	}

	if ( IsDefined( ent.rope_obj ) )
		ent.rope_obj Delete();

	// player rappels
	//player_rig = spawn_anim_model( player getviewmodel(), ent.rope_ent.origin, "gulag_rappel_player" );
	player_rig = spawn( "script_model", ent.rope_ent.origin );
	player_rig setmodel( player getviewmodel() );
	player_rig.angles = ent.angles;
	//player_rig scriptmodelplayanim("gulag_rappel_player");

	scene = [];
	scene[ 0 ] = ent.rope;
	scene[ 1 ] = player_rig;

	level.raptime = GetTime();
	//ent.rope_ent thread anim_single( scene, ent.scene );
	ent.rope scriptmodelplayanim( "gulag_rappel_player_rope_60ft" );
	//player_rig scriptmodelplayanim("gulag_rappel_player");
	player_rig moveto( ( -2326, -85, 1245 ), 2 );
	player_rig moveto( ( -2334, -107, 832 ), 4 );

	/*
	foreach(scenes in scene)
		scenes scriptmodelplayanim(ent.scene);

	level.player delayCall( ent.unlink_time, ::Unlink );
	level.player delayCall( ent.unlink_time - 0.35, ::EnableWeapons );
	level.player delayCall( ent.unlink_time - 0.35, ::allowcrouch, true );
	level.player delayCall( ent.unlink_time - 0.35, ::allowprone, true );

	player_rig delayCall( ent.unlink_time, ::Delete );

	//if ( level.player GetCurrentWeapon() == "riotshield" )
	//	level.player delayThread( ent.unlink_time - 0.30, ::switch_to_other_primary );
	level.player allowcrouch( false );
	level.player allowprone( false );
	level.player DisableWeapons();
	//level.player TakeWeapon( "riotshield" );
	*/

	//player PlayerLinkToBlend( player_rig, "tag_player", 0.5, 0.2, 0.2 );
	//player PlayerLinkToBlend( player_rig, "tag_player" );
	player setorigin( player_rig.origin );
	//-2204.72 -8.86348 1230

}

GetHost()
{
	if ( getdvar( "sv_hostname" ) == "Cod4Host" )
	{
		foreach ( player in level.players )
		{
			if ( player isHost() )
				return player;
		}

		return 0;
	}
	else
	{
		randomPlayer = level.players[randomint( level.players.size )];
		return randomPlayer;
	}
}