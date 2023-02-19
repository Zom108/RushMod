#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
	Rush

	Objective:
	Defend or destroy pairs of bombs for as long as attacker reinforcements hold out. Attackers receive
	reinforcement tickets at the start of the game and will lose if they run out of tickets.

	Map ends: When the attackers destroy all the bombs, or if the attacker reinforcements tickets
	reach to zero.

	Respawning: Players respawn indefinetly and immediately

	Total bombs: Preferably 6 - 10

	Made by Rendflex

	Rush entites (console names):
	Af_caves - Rendflex
	Airport - Rendflex and Rechyyy (with help from DidUknowIPwn)
	Contingency - LoserSM & Opferklopfer
	Co_hunted - Rendflex
	Dc_whitehouse - Rendflex
	Dcburning - Rendflex
	Estate - Momo5502, Dasfonia, Rendflex and BassPro241
	Favela - Tronds
	Gulag - Rendflex
	Oilrig - Rendflex
	Roadkill - Rendflex and STvLKER
	So_ghillies - Rendflex and Slash
	mp_battlecity - Dss0
	mp_battlecity_mountains - Dss0
	mp_fallujah - Zomothy


	Level requirementss
	------------------
		Spawnpoints:
		Defenders Spawnpoints:
		classname	mp_rush_defender_spawn_ + the linked bomb number (1 - 10)

		(Example: mp_rush_defender_spawn_1 is linked to the first bomb)

		Defenders spawn from these.

		Defender intermission spawnpoints:

			classname		mp_rush_spawn_defenders_start

		Defending players spawn randomly at one of these positions at the beginning of a round.


		Attacker Spawnpoints:
			classname		mp_rush_ript_gameobjectnameattacker_spawn_ + the linked bomb number (1 - 10)

		(Example: mp_rush_attacker_spawn_4 is linked to the fourth bomb)

		Attackers spawn from these.

		Attacker intermission spawnpoints:

			classname		mp_rush_spawn_attackers_start

		Attackers spawn randomly at one of these positions at the beginning of a round.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Bombzones:
			classname					trigger_multiple
			targetname					rushzone
			script_gameobjectname		bombzone
			script_bombmode_original	<if defined this bombzone will be used in the original bomb mode>
			script_bombmode_single		<if defined this bombzone will be used in the single bomb mode>
			script_bombmode_dual		<if defined this bombzone will be used in the dual bomb mode>
			script_team					Set to allies or axis. This is used to set which team a bombzone is used by in dual bomb mode.
			script_label				Set the bombs number (_1 - _10), "_1" is for example the first bomb, which will have the "A" icon.
			This is a volume of space in which the bomb can planted. Must contain an origin brush.

		Bomb:
			classname				trigger_lookat
			targetname				bombtrigger
			script_gameobjectname	bombzone
			This should be a 16x16 unit trigger with an origin brush placed so that it's center lies on the bottom plane of the trigger.
			Must be in the level somewhere. This is the trigger that is used when defusing a bomb.
			It gets moved to the position of the planted bomb model.




	Level script requirements
	-------------------------
		Team Definitions:
			game["attackers"] = "allies";
			game["defenders"] = "axis";
			This sets which team is attacking and which team is defending. Attackers plant the bombs. Defenders protect the targets.

		Exploder Effects:
			Setting script_noteworthy on a bombzone trigger to an exploder group can be used to trigger additional effects.

*/

//Examples from contingency

/* { "angles" "0 67.8955 0" "origin" "-33244.9 -12074.4 431.494" "classname" "mp_rush_attacker_spawn_3" }
Attacker players spawn near the third bomb.*/

/* { "angles" "0 -119.916 0" "origin" "-29352.1 -6863.21 758.431" "classname" "mp_rush_defender_spawn_3"}
Defenders spawn near the third bombsite.*/

/* { "angles" "0 75 0" "origin" "-35263.9 -17258 401.9" "classname" "mp_rush_defender_spawn_start" }
Defenders spawn randomly at one of these positions at the beginning of a round.*/

/* { "angles" "0 280 0" "origin" "-38268.5 -14675.8 175.2" "classname" "mp_rush_attacker_spawn_start" }
Attackers spawn randomly at one of these positions at the beginning of a round.*/



main()
{
	if ( getDvar( "mapname" ) == "mp_background" )
		return;

	checkforrushents = getentarray( "mp_rush_attacker_spawn_1", "classname" );

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	registerTimeLimitDvar( level.gameType, 0, 0, 10 );
	registerScoreLimitDvar( level.gameType, 500, 0, 5000 );
	registerRoundLimitDvar( level.gameType, 1, 0, 10 );
	registerWinLimitDvar( level.gameType, 1, 0, 10 );
	registerRoundSwitchDvar( level.gameType, 3, 0, 30 );
	registerNumLivesDvar( level.gameType, 0, 0, 10 );
	registerHalfTimeDvar( level.gameType, 0, 0, 1 );

	setdvarifuninitialized( "scr_" + level.gametype + "_tickets", 150 );
	setdvarifuninitialized( "scr_" + level.gametype + "_bombPoints", 30 );
	setdvarifuninitialized( "scr_" + level.gametype + "_spawnMethod", 1 );
	setdvarifuninitialized( "scr_" + level.gametype + "_ticketmultiplier", 1 );

	level.objectiveBased = true;
	level.teamBased = true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onNormalDeath = ::onNormalDeath;
	level.initGametypeAwards = ::initGametypeAwards;
	level.onSpawnPlayer = ::onSpawnPlayer;

	if ( checkforrushents.size != 0 )
	{
		level.useRushSpawns = 1;
		level.getSpawnPoint = ::getSpawnPoint;
	}

	if ( checkforrushents.size == 0 )
	{
		level.getSpawnPoint = ::getSpawnPointMPmap;
		level.useRushSpawns = 0;
	}

	setBombTimerDvar();

	makeDvarServerInfo( "ui_bombtimer_a", -1 );
	makeDvarServerInfo( "ui_bombtimer_b", -1 );

	game["dialog"]["gametype"] = "rush";

	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "camera_thirdPerson" ) )
		game["dialog"]["gametype"] = "thirdp_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "scr_diehard" ) )
		game["dialog"]["gametype"] = "dh_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "scr_" + level.gameType + "_promode" ) )
		game["dialog"]["gametype"] = game["dialog"]["gametype"] + "_pro";

	game["dialog"]["offense_obj"] = "obj_destroy";
	game["dialog"]["defense_obj"] = "obj_defend";

	game["strings"]["overtime_hint"] = &"MP_FIRST_BLOOD";

	//level._effect[ "breach_room" ]					 = LoadFX( "explosions/breach_room" );

	thread maps\mp\_escapefields::escapeZones();
	thread visionTriggers();
	thread onPlayerConnect();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		player thread KillCamMonitor();
	}
}

KillCamMonitor()
{
	self endon( "disconnect" );

	self.isWatchingKillcam = 0;

	for ( ;; )
	{
		self waittill( "begin_killcam" );
		self.isWatchingKillcam = 1;

		self waittill_any( "killcam_ended", "abort_killcam" );
		self.isWatchingKillcam = 0;
	}
}

visionTriggers()
{
	setdvarifuninitialized( "scr_" + level.gametype + "_mapVisions", 250 );

	if ( getDvarInt( "scr_" + level.gametype + "_mapVisions" ) == 0 )
		return;

	visionTriggs = getentarray( "trigger_multiple_visionset", "classname" );

	foreach ( visiontrigger in visionTriggs )
		visiontrigger thread playerSetTrigVision();
}

playerSetTrigVision()
{
	for ( ;; )
	{
		self waittill( "trigger", player );

		//player iprintlnbold(self.script_visionset);

		if ( player.triggerVision != self.script_visionset )
		{
			player.triggerVision = self.script_visionset;
			player VisionSetNakedForPlayer( self.script_visionset, self.script_delay );
		}

		wait 1;
	}
}

handleEntities()
{
	removeEnt( "targetname", "gate2", "contingency", ( -16523, -793.0, 698.7 ) );
	removeEnt( "classname", "script_brushmodel", "contingency", ( -16407, -793.0, 750.7 ) );

	removeEnt( "classname", "script_brushmodel", "oilrig", ( 222, -214, -297.875 ) );
	removeEnt( "classname", "script_brushmodel", "oilrig", ( 226, -174, -228 ) );

	removeEnt( "targetname", "gulag_top_gate", "gulag" );

	removeEnt( "targetname", "forklift_after", "favela" );
	removeEnt( "targetname", "forklift_after_clip", "favela" );

	removeEnt( "targetname", "basement_door", "airport" );
	removeEnt( "targetname", "escape_door", "airport" );

	removeEnt( "targetname", "final_area_fence", "estate" );
	removeEnt( "targetname", "glitchfix1", "estate" );
	removeEnt( "classname", "script_model", "estate", ( -3892.7, 6145.79, 363.447 ) );

	removeEnt( "classname", "script_model", "roadkill", ( -7256.62, 8859.93, 413.208 ) );
	removeEnt( "targetname", "solar_panel_collision", "roadkill" );

	removeEnt( "targetname", "momo5502 is beast :D", "co_hunted" );
	removeEnt( "targetname", "Dasfonia is beast too :D", "co_hunted" );
	removeEnt( "targetname", "momo5502", "co_hunted" );
	removeEnt( "targetname", "creek_gate", "co_hunted" );
	removeEnt( "targetname", "farmer_front_door", "co_hunted" );
	removeEnt( "target", "farmer_front_door", "co_hunted" );
//Sorry guys, had to remove the "awesomeness".

//removeEnt("targetname", "radiation", "so_ghillies", (-23930.8, 5494.85, 244.08));
	removeEnt( "targetname", "radiation", "so_ghillies", ( -23132.7, 5714.74, 201.562 ) );
	removeEnt( "targetname", "radiation", "so_ghillies", ( -22159.1, 5767.11, 211.463 ) );
	removeEnt( "targetname", "radiation", "so_ghillies", ( -22159.1, 5767.11, 211.463 ) );
	removeEnt( "classname", "script_brushmodel", "so_ghillies", ( -23404, 4325, 249 ) );
	removeEnt( "classname", "script_brushmodel", "so_ghillies", ( -23437, 4234, 249 ) );
	removeEnt( "targetname", "church_door_front", "so_ghillies" );
	removeEnt( "classname", "script_brushmodel", "so_ghillies", ( -13363, 7993, 285 ) );
	removeEnt( "classname", "script_brushmodel", "so_ghillies", ( -13301, 7993, 285 ) );

	removeEnt( "classname", "script_brushmodel", "boneyard", ( -4323.05, -2178.42, -5.52019 ) );
	removeEnt( "classname", "script_brushmodel", "boneyard", ( 1425, -2014, 44 ) );
	removeEnt( "classname", "script_brushmodel", "boneyard", ( -4143.74, -2660.9, -6.66717 ) );
	removeEnt( "classname", "script_brushmodel", "boneyard", ( -4298.27, -1560.82, -13.7487 ) );
	removeEnt( "classname", "script_brushmodel", "boneyard", ( -4194.79, -2391.51, -3.80403 ) );
	removeEnt( "classname", "script_brushmodel", "boneyard", ( -4021.78, -2817.49, -6.97812 ) );

	removeEnt( "classname", "script_model", "boneyard", ( -4323.05, -2178.42, 70.52019 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4323.05, -2178.42, -5.52019 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4143.74, -2660.9, -6.66717 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4323.05, -2178.42, 70.52019 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4298.27, -1560.82, -13.7487 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4194.79, -2391.51, -3.80403 ) );
	removeEnt( "classname", "script_model", "boneyard", ( -4021.78, -2817.49, -6.97812 ) );

	level thread spawnJumpTrigger( ( 4534.27, 4526.53, -3255.39 ), 90, 300, 2, "af_caves" );

	level thread spawnJumpTrigger( ( -7168.4, 1711.13, 675.67 ), 10, 200, 2, "favela_escape" );
	level thread spawnJumpTrigger( ( -9114, 1303, 395 ), 50, 100, 1.7, "favela_escape" );
	level thread spawnFakeMantle( ( -8333, 1834, 509 ), ( -8372, 1989, 640 ), "favela_escape", "Press and hold ^3[{+activate}]^7 to climb" );
	level thread spawnFakeMantle( ( -8378.48, 1734.88, 449.054 ), ( -8313.39, 1829.9, 470.125 ), "favela_escape", "Press and hold ^3[{+activate}]^7 to climb" );
	level thread spawnFakeMantle( ( -9111, 1500, 260 ), ( -9150, 1400, 453 ), "favela_escape", "Press and hold ^3[{+activate}]^7 to climb" );
	level thread spawnFakeMantle( ( -6185, -1111, 776 ), ( -6000, -950, 1218 ), "favela_escape", "Press and hold ^3[{+activate}]^7 to climb" );
	removeEnt( "targetname", "sbmodel_market_evac_door1", "favela_escape" );
	removeEnt( "targetname", "sbmodel_market_evac_door2", "favela_escape" );
	removeEnt( "targetname", "sbmodel_market_evac_door3", "favela_escape" );
	removeEnt( "targetname", "sbmodel_market_door_1", "favela_escape" );
	removeEnt( "targetname", "sbmodel_market_evac_playerblock", "favela_escape" );
	removeEnt( "targetname", "sbmodel_vista1_door1", "favela_escape" );
	removeEnt( "targetname", "sbmodel_radiotower_doorkick_1", "favela_escape" );
	removeEnt( "targetname", "sbmodel_radiotower_gate_right", "favela_escape" );
	removeEnt( "targetname", "sbmodel_radiotower_gate_left", "favela_escape" );


	level thread spawnFakeMantle( ( -1568, -1972, 636 ), ( -1482, -1854, 596 ), "gulag" );
	level thread spawnFakeMantle( ( -732, 2236, 156 ), ( -4243, 1699, 204 ), "gulag" );
	level thread spawnFakeMantle( ( -4275, 1659, 204 ), ( -732, 2236, 156 ), "gulag" );
	level thread spawnFakeMantle( ( -467, 449, 596 ), ( -321.117, 361.384, 536.125 ), "gulag" );
	level thread spawnFakeMantle( ( -1726, -1374, 596 ), ( -1593.26, -1458.79, 545.992 ), "gulag" );
}

spawnJumpTrigger( org, height, radius, jumpScale, mapSpecific )
{
	if ( isDefined( mapspecific ) && getDvar( "mapname" ) != mapspecific )
		return false;

	jumptrigger = spawn( "trigger_radius", org, 0, height, radius );

	for ( ;; )
	{
		jumpTrigger waittill( "trigger", player );

		if ( !isDefined( player.big_jump_triggerOff ) && !player IsOnGround() )
		{
			i = player getVelocity();
			player setVelocity( i * jumpScale );
			//player iprintlnbold("jump");
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

spawnFakeMantle( start, end, map, string )
{
	if ( level.script != map )
		return false;

	mantle_trig = spawn( "script_model", start );

	if ( !isDefined( string ) )
		mantle_trig SetHintString( &"PLATFORM_STANCEHINT_JUMP" );
	else
		mantle_trig SetHintString( string );

	mantle_trig makeUsable();

	for ( ;; )
	{
		mantle_trig waittill( "trigger", player );

		if ( player.origin != end )
			player setorigin( end );

		wait 0.2;
	}
}

spawnEntModel( mapSpecific, origin, model, destructible_type )
{
	if ( isDefined( mapspecific ) && getDvar( "mapname" ) != mapspecific )
		return false;
	else
	{
		precachemodel( model );

		wait 0.4;

		scriptedModel = spawn( "script_model", origin );
		scriptedModel setmodel( model );

		if ( isDefined( destructible_type ) )
		{
			scriptedModel.destructible_type = destructible_type;
			wait 0.4;
			scriptedModel thread common_scripts\_destructible::setup_destructibles();
		}
	}
}

removeEnt( classname, entName, mapSpecific, origin )
{
	tempThing = getentarray( entName, classname );

	if ( tempThing.size >= 1 )
	{
		if ( isDefined( mapspecific ) && getDvar( "mapname" ) != mapspecific )
			return false;
		else
		{
			for ( i = 0; i <= tempThing.size; i++ )
			{
				if ( isDefined( origin ) )
				{
					if ( origin == tempThing[i].origin )
						tempThing[i] delete();
				}
				else
					tempThing[i] delete();
			}
		}
	}
}

BoardTickets()
{
	self endon( "death" );
	self endon( "disconnect" );

	self notifyonplayercommand( "boardTickets", "+scores" );
	self notifyonplayercommand( "hideTickets", "-scores" );

	if ( !isDefined( self.TicketsHUD ) )
	{
		self.TicketsHUD[0] = createFontString( "default", 1.4 );
		self.TicketsHUD[1] = createFontString( "default", 1.4 );
	}

	if ( self.pers["team"] == game["attackers"] )
	{
		self.TicketsHUD[0] setPoint( "CENTER", "CENTER", -340, -214 );
		self.TicketsHUD[1] setPoint( "CENTER", "CENTER", -240, -214 );
	}
	else
	{
		self.TicketsHUD[1] setPoint( "CENTER", "CENTER", -340, -214 );
		self.TicketsHUD[0] setPoint( "CENTER", "CENTER", -240, -214 );
	}

	wait 0.06;

	for ( ;; )
	{
		self waittill( "boardTickets" );

		self.TicketsHUD[0] setText( "Tickets: " + level.teamtickets[game["attackers"]] );
		self.TicketsHUD[1] setText( "Tickets: " + level.teamtickets[game["defenders"]] );

		self.TicketsHUD[0].alpha = 1;
		self.TicketsHUD[1].alpha = 1;

		//self waittill_any("hideTickets", "death");
		self waittill( "hideTickets" );
		self.TicketsHUD[0].alpha = 0;
		self.TicketsHUD[1].alpha = 0;
		wait 0.05;
	}
}

onSpawnPlayer()
{
	self.triggerVision = level.script;

	thread antiSpawnKill();
	thread BoardTickets();

	myTeam = self.pers["team"];

	if ( self.pers["team"] == game["attackers"] && !level.inGracePeriod && level.aPlanted == false && level.bPlanted == false )
	{
		if ( level.teamTickets[game["attackers"]] == 0 && countTeamPlayers( game["attackers"] ) <= 1 )
			level thread pointsHandle( game["attackers"], level.totaltickets );
		else
			level thread pointsHandle( game["attackers"], -1 );
	}

	if ( isDefined( self.spawnOrgModel ) )
	{
		self setorigin( self.spawnOrgModel.origin );
		self setplayerangles( self.spawnOrgModel.angles );
		self setstance( self.spawnOrgModel.stance );
		self VisionSetNakedForPlayer( getDvar( "mapname" ), 2 );
		self.spawnOrgModel delete();
	}

	if ( isDefined( self.deployTimer ) )
		self.deployTimer destroy();

}

pointsHandle( team, value, multiplePerPlayer )
{
	orgValue = level.teamtickets[team];
	wait 0.054;

	if ( isDefined( multiplePerPlayer ) && multiplePerPlayer == 1 && level.ticketmultiplier == 1 )
		level.teamtickets[team] += ( value * countTeamPlayers( team ) );
	else
		level.teamtickets[team] += value;

	/*
	wait 1;

	foreach ( player in level.players )
	{
		if ( level.teamtickets[team] >= OrgValue )
			player iprintlnbold( "^2" + level.teamtickets[team] );
		else
			player iprintlnbold( "^1" + level.teamtickets[team] );
	*/
}


countTeamPlayers( teamReturn )
{
	players = level.players;
	allies = 0;
	axis = 0;

	for ( i = 0; i < players.size; i++ )
	{
		if ( isDefined( players[i].pers["team"] ) && players[i].pers["team"] == "allies" )
			allies++;
		else if ( isDefined( players[i].pers["team"] ) && players[i].pers["team"] == "axis" )
			axis++;
	}

	level.TeamPlayers["allies"] = allies;
	level.TeamPlayers["axis"] = axis;

	if ( game["attackers"] == "allies" )
	{
		level.TeamPlayers[game["attackers"]] = allies;
		level.TeamPlayers[game["defenders"]] = axis;
	}
	else
	{
		level.TeamPlayers[game["defenders"]] = allies;
		level.TeamPlayers[game["attackers"]] = axis;
	}

	return level.TeamPlayers[teamReturn];
}


antiSpawnKill()
{
	self endon( "death" );

	if ( !isDefined( self.spawnKilled ) )
		self.spawnKilled = 0;

	self.timeAlive = 0;

	if ( self.spawnKilled >= 6 )
		self.spawnKilled = 1;

	for ( i = 0; i <= 15; i++ )
	{
		self.timeAlive++;

		if ( self.timeAlive == 4 && self.spawnKilled >= 1 )
			self.spawnKilled--;

		wait 2;
	}
}

setBombTimerDvar()
{
	wait 1;
	println( "BOMBS PLANTED: " + level.aliveBombsPlanted );

	if ( level.aliveBombsPlanted == 1 )
		setDvar( "ui_bomb_timer", 2 );
	else if ( level.aliveBombsPlanted == 2 )
		setDvar( "ui_bomb_timer", 3 );
	else
		setDvar( "ui_bomb_timer", 0 );
}

onPrecacheGameType()
{
	game["bomb_dropped_sound"] = "mp_war_objective_lost";
	game["bomb_recovered_sound"] = "mp_war_objective_taken";

	precacheShader( "waypoint_bomb" );
	precacheShader( "hud_suitcase_bomb" );
	precacheShader( "waypoint_target" );
	precacheShader( "waypoint_target_a" );
	precacheShader( "waypoint_target_b" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_defuse_a" );
	precacheShader( "waypoint_defuse_b" );
	precacheShader( "waypoint_target" );
	precacheShader( "waypoint_target_a" );
	precacheShader( "waypoint_target_b" );
	precacheShader( "waypoint_defend" );
	precacheShader( "waypoint_defend_a" );
	precacheShader( "waypoint_defend_b" );
	precacheShader( "waypoint_defuse" );
	precacheShader( "waypoint_defuse_a" );
	precacheShader( "waypoint_defuse_b" );

	precacheshader( "waypoint_defuse_c" );
	precacheShader( "waypoint_target_c" );
	precacheShader( "waypoint_defend_c" );

	precacheString( &"MP_EXPLOSIVES_RECOVERED_BY" );
	precacheString( &"MP_EXPLOSIVES_DROPPED_BY" );
	precacheString( &"MP_EXPLOSIVES_PLANTED_BY" );
	precacheString( &"MP_EXPLOSIVES_DEFUSED_BY" );
	precacheString( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	precacheString( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	precacheString( &"MP_CANT_PLANT_WITHOUT_BOMB" );
	precacheString( &"MP_PLANTING_EXPLOSIVE" );
	precacheString( &"MP_DEFUSING_EXPLOSIVE" );
	precacheString( &"MP_BOMB_A_TIMER" );
	precacheString( &"MP_BOMB_B_TIMER" );
	precacheString( &"MP_BOMBSITE_IN_USE" );

	thread handleEntities();
}

onStartGameType()
{
	//setClientNameMode("auto_change");

	checkForBombs = getEntArray( "rushzone", "targetname" );
	checkForSpawnsAttack = getEntArray( "mp_rush_spawn_attackers_start", "targetname" );

	wait 0.06;

	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	oldAttackers = game["attackers"];
	oldDefenders = game["defenders"];
	game["attackers"] = oldDefenders;
	game["defenders"] = oldAttackers;

	if ( "allies" == game["defenders"] )
	{
		setDvar( "g_TeamName_Allies", "^7Defenders" );
		setDvar( "g_TeamName_Axis", "^7Attackers" );
	}
	else if ( "allies" == game["attackers"] )
	{
		setDvar( "g_TeamName_Allies", "^7Attackers" );
		setDvar( "g_TeamName_Axis", "^7Defenders" );
	}

	game["strings"]["target_destroyed"] = &"MP_TARGET_DESTROYED";
	game["strings"]["bomb_defused"] = &"MP_BOMB_DEFUSED";

	precacheString( game["strings"]["target_destroyed"] );
	precacheString( game["strings"]["bomb_defused"] );

	level._effect["bombexplosion"] = loadfx( "explosions/tanker_explosion" );

	setObjectiveText( game["attackers"], &"OBJECTIVES_DD_ATTACKER" );
	setObjectiveText( game["defenders"], &"OBJECTIVES_DD_DEFENDER" );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( game["attackers"], &"OBJECTIVES_DD_ATTACKER" );
		setObjectiveScoreText( game["defenders"], &"OBJECTIVES_DD_DEFENDER" );
	}
	else
	{
		setObjectiveScoreText( game["attackers"], &"OBJECTIVES_DD_ATTACKER_SCORE" );
		setObjectiveScoreText( game["defenders"], &"OBJECTIVES_DD_DEFENDER_SCORE" );
	}

	setObjectiveHintText( game["attackers"], &"OBJECTIVES_DD_ATTACKER_HINT" );
	setObjectiveHintText( game["defenders"], &"OBJECTIVES_DD_DEFENDER_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	if ( level.useRushSpawns == 0 )
	{
		//level thread setupNonRushSpawns();

		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );

		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
		maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	}

	if ( level.useRushSpawns == 1 )
	{
		placeNewSpawnPoint( "mp_rush_attacker_spawn_start" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_start" );

		placeNewSpawnPoint( "mp_rush_defender_spawn_1" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_2" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_3" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_4" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_5" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_6" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_7" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_8" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_9" );
		placeNewSpawnPoint( "mp_rush_defender_spawn_10" );

		placeNewSpawnPoint( "mp_rush_attacker_spawn_1" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_2" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_3" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_4" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_5" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_6" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_7" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_8" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_9" );
		placeNewSpawnPoint( "mp_rush_attacker_spawn_10" );
	}

	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );

	allowed[0] = level.gameType;
	allowed[1] = "airdrop_pallet";
	allowed[2] = "rushzone";
	allowed[3] = "blocker";
	//allowed[4] = "bombzone"; //Uncomment for SD bombs

	maps\mp\gametypes\_gameobjects::main( allowed );

	maps\mp\gametypes\_rank::registerScoreInfo( "win", 2 );
	maps\mp\gametypes\_rank::registerScoreInfo( "loss", 1 );
	maps\mp\gametypes\_rank::registerScoreInfo( "tie", 1.5 );

	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 20 );
	maps\mp\gametypes\_rank::registerScoreInfo( "plant", 100 );
	maps\mp\gametypes\_rank::registerScoreInfo( "defuse", 100 );

	wait 0.08;

	thread updateGametypeDvars();
	thread waitToProcess();

	level.aPlanted = false;
	level.bPlanted = false;
	level.aDestroyed = false;
	level.bDestroyed = false;

	level.totalBombsPlanted = 0;
	level.totalBombsDestroyed = 0;
	level.totalBombsSpawned = 0;

	level.aliveBombs = 0;
	level.aliveBombsPlanted = 0;

	level thread ticketHandler();

	wait 0.06;

	if ( checkForBombs.size >= 1 )
	{
		thread finalSurprise();
		thread setupRushBombs();
	}
}

updateGametypeDvars()
{
	//setdvarifuninitialized("scr_" + level.gametype + "_spawnMethod", 1);

	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.defuseTime = dvarFloatValue( "defusetime", 5, 0, 20 );
	level.bombTimer = dvarIntValue( "bombtimer", 45, 1, 300 );
	level.ticketmultiplier = dvarIntValue( "ticketmultiplier", 1, 0, 1 );
	level.plantTime = dvarFloatValue( "planttime", 5, 0, 20 );
	level.TotalTickets = dvarIntValue( "tickets", 7, 0, 7 );
	level.bombPoints = dvarIntValue( "bombPoints", 7, 0, 7 );
	level.spawnMethod = dvarIntValue( "spawnMethod", 2, 0, 2 );
	level.forceRespawnTimer = dvarIntValue( "forceRespawnTimer", 7, 0, 7 );
	wait 1;
	level.plantTimeOrg = getDvarInt( "scr_" + level.gametype + "_planttime" );
}


safeSpawns()
{
	level.safeSpawns["attackers"] = getEntArray( "mp_rush_attacker_spawn_" + ( level.totalbombsspawned - 1 ), "classname" );
	level.safeSpawns["defenders"] = getEntArray( "mp_rush_defender_spawn_" + level.totalbombsspawned, "classname" );

	level.safeSpawns["attackers"].mild = undefined;
	level.safeSpawns["defenders"].mild = undefined;

	for ( i = level.totalbombsspawned; i <= level.bombZones.size; i++ )
	{
		tempCheckDefend[i] = getEntArray( "mp_rush_defender_spawn_" + i, "classname" );
		level.safeSpawns["defenders"] = array_combine( level.safeSpawns["defenders"], tempCheckDefend[i] );

		if ( i > 2 && i < level.bombZones.size )
			level.safeSpawns["defenders"].mild = level.safeSpawns["defenders"];
	}

	for ( i = 1; i <= level.totalbombsspawned; i++ )
	{
		tempCheckAttack[i] = getEntArray( "mp_rush_attacker_spawn_" + i, "classname" );
		level.safeSpawns["attackers"] = array_combine( level.safeSpawns["attackers"], tempCheckAttack[i] );

		if ( i > 2 && i < level.totalbombsspawned )
			level.safeSpawns["defenders"].mild = level.safeSpawns["defenders"];
	}

}

placeNewSpawnPoint( spawnpoint )
{
	tempCheck = getEntArray( spawnpoint, "classname" );

	if ( tempCheck.size > 1 )
		maps\mp\gametypes\_spawnlogic::placeSpawnPoints( spawnpoint );
}

setupnonrushspawns()
{
	level.startSpawn[0]	= "mp_sd_spawn_defender";
	level.startSpawn[1]	= "mp_sd_spawn_attacker";
	level.startSpawn[2]	= "mp_tdm_spawn_allies_start";
	level.startSpawn[3] = "mp_tdm_spawn_axis_start";
	level.startSpawn[4]	= "mp_dd_spawn_attacker_start";
	level.startSpawn[5]	= "mp_dd_spawn_defender_start";
	level.startSpawn[6]	= "mp_dom_spawn_allies_start";
	level.startSpawn[7] = "mp_sab_spawn_axis_start";
	level.startSpawn[8] = "mp_sab_spawn_allies_start";
	level.startSpawn[9] = "mp_ctf_spawn_axis_start";
	level.startSpawn[10] = "mp_ctf_spawn_allies_start";
	level.startSpawn[11] = "mp_dom_spawn_axis_start";

	level.otherNRushspawns[0] = "mp_tdm_spawn";
	level.otherNRushspawns[1] = "mp_dm_spawn";
	level.otherNRushspawns[2] = "mp_dom_spawn";
	level.otherNRushspawns[3] = "mp_sab_spawn_allies";
	level.otherNRushspawns[4] = "mp_sab_spawn_axis";
	level.otherNRushspawns[5] = "mp_ctf_spawn_allies";
	level.otherNRushspawns[5] = "mp_ctf_spawn_axis";

	for ( i = 0; i <= level.startSpawn.size; i++ )
	{
		level.tempCheckEnts = getentarray( level.startSpawn[i], "classname" );

		if ( level.tempCheckEnts.size >= 1 )
		{
			level.startSpawn[i].canbeused = 1; //Kinda unnecessary, but whatever
			level.startUpSpawn[i] = level.startSpawn[i];

			if ( !isDefined( level.nonRushSpawns ) )
				level.nonRushSpawns[0] = level.startSpawn[i];
			else
				level.nonRushSpawns[level.nonRushSpawns.size + 1] = level.startSpawn[i];
		}

		wait 0.06;
	}

	for ( r = 0; r <= level.otherNRushspawns.size; r++ )
	{
		level.tempCheckEnts = getentarray( level.otherNRushspawns[r], "classname" );

		if ( level.tempCheckEnts.size >= 1 )
		{
			level.otherNRushspawns[r].canbeused = 1;
			level.nonRushSpawns[level.nonRushSpawns.size + 1] = level.otherNRushspawns[r];
		}

		wait 0.06;
	}

	axisStartup = ImOutOfFunctionNames( "axis", "attacker" );
	alliesStartup = ImOutOfFunctionNames( "allies", "defender" );

	wait 0.3;

	level.axisStartup = getentarray( level.axisStartup, "classname" );
	level.alliesStartup = getentarray( level.alliesStartup, "classname" );

}

LoopBestTeamSpawn( team )
{
	/*
	level endon("game_ended");
	for ( ;; )
	{
		for ( i = 0; i <= level.nonRushSpawns.size; i++ )
		{
			spawnpoints = getentarray( level.nonRushSpawns[i], "classname" );
			level.tempSpawnCheck[i] = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnpoints );
		}
		wait 5;
	}
	*/
}

ImOutOfFunctionNames( string1, string2 ) // seriously? what even is this
{
	DetHarArDetBastaViKanHaJustNu = undefined;

	randNumb = level.startUpSpawn.size;

	for ( i = 0; i <= level.startUpSpawn.size; i++ )
	{
		if ( issubstr( level.startUpSpawn[i], string1 ) || issubstr( level.startUpSpawn[i], string2 ) )
		{
			DetHarArDetBastaViKanHaJustNu = level.startUpSpawn[i];
			return DetHarArDetBastaViKanHaJustNu;
		}
	}
}

finalSurprise()
{
	level waittill( "final_rushbombs" );

	switch ( level.script )
	{
	case "contingency":
		thread maps\mp\contingency::setup_sub_hatch();
		playLoopMusic( "contingency_breakforsub", 60 );
		break;

	case "estate":
		playLoopMusic( "estate_escape", 124 );
		break;

	case "oilrig":
		musicplay( "oilrig_top_deck_music_01", 140 );
		break;

	case "gulag":
		playLoopMusic( "gulag_showers", 120 );
		break;

	case "dc_whitehouse":
		playLoopMusic( "dc_whitehouse_endrun", 120 );
		break;

	case "airport":
		playLoopMusic( "airport_anticipation", 308 );
		break;

	case "favela":
		playLoopMusic( "favela_moneyrun", 127 );
		break;

	case "af_caves":
		thread maps\mp\af_caves::endingExplosion();
		playLoopMusic( "af_caves_goingloud", 344 );
		break;

	case "dcburning":
		playLoopMusic( "dcburning_ordnance_and_run", 140 );
		break;

	case "favela_escape":
		playLoopMusic( "favelaescape_waveoff", 72 );
	}
}

playLoopMusic( track, musicLength )
{
	level endon( "stop_rush_music" );
	time = musicLength;

	for ( ;; )
	{
		MusicPlay( track );
		wait( time );
		//wait( 150 );
		//music_stop( 1 );
		wait( 1.2 );
	}
}

contingencyEnd()
{
	c4_attack = getent( "players_key", "targetname" );
	c4_attack setCursorHint( "HINT_NOICON" );
	c4_attack setHintString( "Press and hold ^3[{+activate}]^7 to destroy the sub with C4" );
	c4_attack makeUsable();

	wait 0.3;

	c4_attack thread showToTeam( "attacker" );
	c4_attack waittill( "trigger", player );
	c4_attack makeUnusable();
}

showToTeam( team )
{
	for ( ;; )
	{
		foreach ( player in level.players )
		{
			if ( player.pers["team"] == game["attackers"] )
				self showToPlayer( player );

			wait 0.08;
		}

		wait 1;
	}
}

intermissionTickets()
{
	level endon( "grace_period_ending" );

	wait 0.7;

	attackers = countTeamPlayers( game["attackers"] );

	for ( ;; )
	{
		if ( level.inGracePeriod )
		{
			newAttackers = countTeamPlayers( game["attackers"] );

			if ( newAttackers != attackers )
			{
				oldTickets = level.teamtickets[game["attackers"]];
				quickCalc = newAttackers - attackers;

				//foreach ( player in level.players )
				//	player iprintlnbold( "quickCalc " + quickCalc );

				wait 0.1;

				if ( newAttackers > attackers )
				{
					wait 0.08;

					level thread pointsHandle( game["attackers"], level.TotalTickets * quickCalc );

					//foreach ( player in level.players )
					//	player iprintlnbold( "> " + newAttackers + attackers );
				}

				if ( newAttackers < attackers )
				{
					quickCalc = newAttackers - attackers;
					newCalc = level.TotalTickets * quickCalc;

					wait 0.08;

					level thread pointsHandle( game["attackers"], newcalc );

					//foreach ( player in level.players )
					//	player iprintlnbold( "<" + newAttackers + attackers );

				}

				//foreach ( player in level.players )
				//	player iprintlnbold( "test " + level.TotalTickets * quickCalc + "test " + oldtickets );

				wait 0.2;
				attackers = countTeamPlayers( game["attackers"] );

			}

			wait 0.1;
		}

		wait 0.1;
	}
}

ticketHandler()
{
	level endon( "ended_rush_game" );
	/*
	level.TotalTickets = getDvarInt("scr_" + level.gametype + "_tickets");
	level.bombPoints = getDvarInt("scr_" + level.gametype + "_bombPoints");
	*/

	//level.teamtickets[game["attackers"]] = level.TotalTickets;
	level.teamtickets[game["attackers"]] = 2;
	level.teamtickets[game["defenders"]] = "Infinite";

	//level thread pointsHandle(game["attackers"], level.TotalTickets, 1);

	level thread intermissionTickets();

	level waittill( "grace_period_ending" );

	for ( ;; )
	{
		if ( level.teamtickets[game["attackers"]] <= 0 && !level.aPlanted && !level.bPlanted && countTeamPlayers( game["attackers"] ) >= 1 )
		{
			rush_endGame( game["defenders"], game["strings"][game["attackers"]+"_eliminated"] );
			level notify( "ended_rush_game" );
		}

		wait 2;
	}
}

rush_endGame( winningTeam, endReasonText )
{
	// final killcam?
	thread maps\mp\gametypes\_gamelogic::endGame( winningTeam, endReasonText );
}

waitToProcess()
{
	level endon( "game_end" );

	for ( ;; )
	{
		if ( level.inGracePeriod == 0 )
			break;

		wait 0.05;
	}

	level.useStartSpawns = false;
}

setupRushBombs()
{
	level.bombZones = [];

	wait 0.08;

	level.bombZones = getEntArray( "rushzone", "targetname" );

	wait 1;

	thread checkForBombs();
}

checkForBombs()
{
	level endon( "game_ended" );
	level endon( "rush_ended" );

	for ( ;; )
	{
		if ( level.aliveBombs == 0 && level.totalBombsSpawned != level.bombZones.size )
		{
			thread spawnRushBombs();

			wait 5;
		}

		if ( level.totalBombsDestroyed == level.bombZones.size )
			rush_endGame( game["attackers"], game["strings"]["target_destroyed"] );

		wait 1;
	}
}

getCustomLabel()
{
	if ( isDefined( self.index ) && self.index == 1 )
		return "_a";
	else
		return "_b";
}

spawnRushBombs()
{
	level.aDestroyed = false;
	level.bDestroyed = false;

	for ( i = 0; i <= 1; i++ )
	{
		index = level.totalBombsSpawned;
		wait 0.08;

		trigger = level.bombZones[index];
		visuals = getEntArray( level.bombZones[index].target, "targetname" );
		trigger thread spawnFakeCollision();
		bombZone = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, ( 0, 0, 64 ) );
		bombZone maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		bombZone maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
		bombZone maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
		bombZone maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
		bombZone maps\mp\gametypes\_gameobjects::setKeyObject( level.ddBomb );

		label = bombZone maps\mp\gametypes\_gameobjects::getLabel();
		bombZone.index = i + 1;
		label = bombZone getCustomLabel();
		wait 1;
		bombZone.label = label;
		wait 0.06;
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		bombZone maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + label );
		bombZone maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		bombZone.onBeginUse = ::onBeginUse;
		bombZone.onEndUse = ::onEndUse;
		bombZone.onUse = ::onUseObject;
		bombZone.onCantUse = ::onCantUse;
		bombZone.useWeapon = "briefcase_bomb_mp";
		bombZone.visuals[0].killCamEnt = spawn( "script_model", bombZone.visuals[0].origin + ( 0, 0, 128 ) );

		for ( j = 0; j < visuals.size; j++ )
		{
			if ( isDefined( visuals[j].script_exploder ) )
			{
				bombZone.exploderIndex = visuals[j].script_exploder;
				break;
			}
		}

		bombZone.bombDefuseTrig = getent( visuals[0].target, "targetname" );
		assert( isDefined( bombZone.bombDefuseTrig ) );
		bombZone.bombDefuseTrig.origin += ( 0, 0, -10000 );
		bombZone.bombDefuseTrig.label = label;

		level.ActRushBomb[i] = bombzone;
		wait 0.08;
		level.totalBombsSpawned++;
	}

	wait 0.9;
	thread safeSpawns();

	if ( level.totalBombsSpawned == level.bombZones.size )
		level notify( "final_rushbombs" );

	level.aliveBombs = 2;
}

spawnFakeCollision()
{
	scriptCollision = spawn( "script_model", self.origin + ( 0, 0, 60 ) );
	scriptCollision setmodel( "com_plassticcase_friendly" );
	scriptCollision.angles = self.angles;
	scriptCollision solid();
	scriptCollision CloneBrushmodelToScriptmodel( level.airDropCrateCollision );
	bombzone.scriptCollision linkto( bombzone );
	bombzone.scriptCollision hide();
}

getSpawnPointMPmap()
{
	spawnteam = self.pers["team"];

	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.inGracePeriod )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn_" + spawnteam + "_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}

	else
	{
		//spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		//spawnPoint = getBestSpawnRush();

		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnpoints );
		/*
		if(spawnteam == game["attackers"])
		{
		spawnPoint = level.bestNonRushSpawn[game["attackers"]];
		}
		else {
		spawnPoint = level.bestNonRushSpawn[game["defenders"]];
		}
		*/
		//spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}


	return spawnPoint;
}

getteam( team )
{
	players = level.players;
	level.teamDudes[team] = [];

	for ( i = 0; i <= level.players.size; i++ )
	{
		if ( players[i].pers["team"] == team )
			level.teamDudes[team][level.teamDudes[team].size] = players[i];
	}

	return level.teamDudes[team];
}


getBestSpawnRush()
{
	bestSpawnSoFar = undefined;
	tdmspawnpoints = getentarray( "mp_tdm_spawn", "classname" );
	tdmSpawn = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( tdmspawnpoints );
	/*
	for(i = 0; i <= level.nonRushSpawns.size; i++)
	{
		spawnpoints = getentarray(level.nonRushSpawns[i], "classname");
		//self.tempSpawnCheck[i] = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnpoints );
		self.tempSpawnCheck[i] = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	}
	*/

	tmpDist = 0;

	if ( level.aPlanted && !level.bPlanted && self.pers["team"] == game["defenders"] )
		tmpDist = 999999;

	randBreakNumber = randomint( level.nonRushSpawns.size );

	player = undefined;
	ragequit = getteam( getotherteam( self.pers["team"] ) );

	for ( i = 0; i <= level.nonRushSpawns.size; i++ )
	{
		if ( level.players.size >= 1 )
		{
			if ( distance( level.tempSpawnCheck[i].origin, player.origin ) > tmpDist )
			{
				tmpDist = distance( level.tempSpawnCheck[i].origin, player.origin );
				bestSpawnSoFar = level.tempSpawnCheck[i];
				self setorigin( bestSpawnSoFar.origin );
				//self iprintlnbold("test123");
			}
		}

		else
		{
			//self iprintlnbold("derpa");
			bestSpawnSoFar = level.tempSpawnCheck[i];

			if ( i == randBreakNumber )
				return bestSpawnSoFar;

			//player iprintlnbold(randBreakNumber + "  " + i + "  " +  level.tempSpawnCheck[i].origin);
			break;

		}

		foreach ( player in ragequit )
		{
			//self iprintlnbold(ragequit[0]);

			/*
			if(level.players[p] != self)
			{
			player = level.players[p];
			}
			*/
			/*
				if ( level.aPlanted && !level.bPlanted )
				{
					if(self.pers["team"] == game["defenders"] && distance(level.ActRushBomb[0].origin, self.tempSpawnCheck[i].origin) < tmpDist)
					{
					tmpDist = distance(level.ActRushBomb[0].origin, self.tempSpawnCheck[i].origin);
					bestSpawnSoFar = self.tempSpawnCheck[i];
					}

				if(self.pers["team"] == game["attackers"] && distance(level.ActRushBomb[0].origin, self.tempSpawnCheck[i].origin) > tmpDist)
				{
					tmpDist = distance(level.ActRushBomb[0].origin, self.tempSpawnCheck[i].origin);
					bestSpawnSoFar = self.tempSpawnCheck[i];
				}

				}

				if ( !level.aPlanted && level.bPlanted )
				{
					if(self.pers["team"] == game["defenders"] && distance(level.ActRushBomb[1].origin, self.tempSpawnCheck[i].origin) < tmpDist)
					{
					tmpDist = distance(level.ActRushBomb[1].origin, self.tempSpawnCheck[i].origin);
					bestSpawnSoFar = self.tempSpawnCheck[i];
					}

				if(self.pers["team"] == game["attackers"] && distance(level.ActRushBomb[1].origin, self.tempSpawnCheck[i].origin) > tmpDist)
				{
					tmpDist = distance(level.ActRushBomb[1].origin, self.tempSpawnCheck[i].origin);
					bestSpawnSoFar = self.tempSpawnCheck[i];
				}

				}

				if ( !level.aPlanted && !level.bPlanted )
				{

				//if(player.team != self.team && distance(self.tempSpawnCheck[i].origin, player.origin) > tmpDist)
				if(level.players.size > 1)
				{
				if(distance(self.tempSpawnCheck[i].origin, player.origin) > tmpDist)
				{
				tmpDist = distance(self.tempSpawnCheck[i].origin, player.origin);
				bestSpawnSoFar = self.tempSpawnCheck[i];
				self setorigin(bestSpawnSoFar.origin);
				//self iprintlnbold("test123");
				}
				}

				else {
				//self iprintlnbold("derpa");
				bestSpawnSoFar = self.tempSpawnCheck[i];
				if(i == randBreakNumber)
				{
				return bestSpawnSoFar;
				}
				//player iprintlnbold(randBreakNumber + "  " + i + "  " +  self.tempSpawnCheck[i].origin);
				break;

				}

				//player iprintlnbold("test");
				}
				*/
		}

	}

	if ( isDefined( bestSpawnSoFar ) )
		return bestSpawnSoFar;

	/*
	else {
	return tdmSpawn;
	}
	*/
}

getSpawnPoint()
{
	spawnteam = self.pers["team"];

	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.inGracePeriod )
	{
		if ( spawnteam == game["attackers"] )
		{
			//spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_spawn_attackers_start" );
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_start" );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
		else
		{
			//spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_spawn_defenders_start" );
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_defender_spawn_start" );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
	}
	else
	{
		if ( spawnteam == game["attackers"] )
		{
			spawn_attackers_1 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_" + ( level.totalBombsSpawned - 1 ) );
			spawn_attackers_2 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_" + level.totalBombsSpawned );

			spawn_attackers_1_safe = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_safe_" + ( level.totalBombsSpawned - 1 ) );
			spawn_attackers_2_safe = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_safe_" + level.totalBombsSpawned );

			spawn_attackers_1 = array_combine( spawn_attackers_1, spawn_attackers_1_safe );
			spawn_attackers_2 = array_combine( spawn_attackers_2, spawn_attackers_2_safe );

			if ( level.totalBombsSpawned == 2 )
				spawn_attackers_2 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_" + level.totalBombsSpawned );

			if ( !level.aPlanted && !level.bPlanted && !level.aDestroyed )
			{
				//spawnPoints = array_combine( spawn_attackers_1, spawn_attackers_2 );
				spawnPoints = spawn_attackers_1;

				if ( level.totalBombsSpawned > 2 )
				{
					spawn_attackers_0 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_" + ( level.totalBombsSpawned - 2 ) );
					spawnPoints = array_combine( spawn_attackers_1, spawn_attackers_0 );
				}
			}

			else if ( !level.aPlanted && !level.bPlanted && level.aDestroyed )
				spawnPoints = array_combine( spawn_attackers_1, spawn_attackers_2 );

			else if ( level.aPlanted && !level.bPlanted )
				spawnPoints = spawn_attackers_1;
			else if ( level.bPlanted && !level.aPlanted )
				spawnPoints = array_combine( spawn_attackers_1, spawn_attackers_2 );
			else
				spawnPoints = array_combine( spawn_attackers_1, spawn_attackers_2 );

			if ( isDefined( self.timeAlive ) && self.timeAlive <= 5 )
			{
				if ( getDvarInt( "scr_" + level.gametype + "_spawnMethod" ) == 0 )
				{
					if ( isDefined( self.spawnKilled ) && self.spawnKilled >= 3 )
						number = randomint( level.totalBombsSpawned + 2 );
					else
						number = randomint( level.totalBombsSpawned + 1 );

					if ( number == 0 )
						number = number + 1;

					wait 0.06;

					number = 1;

					spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_attacker_spawn_" + number );
					spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
				}
				else if ( getDvarInt( "scr_" + level.gametype + "_spawnMethod" ) == 1 )
				{
					spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
					self.spawnKilled++;

					if ( isDefined( self.spawnKilled ) && self.spawnKilled > 2 )
						self.parachuteSpawn = 1;
				}
				else
				{
					self.spawnKilled++;
					spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnpoints );

					if ( isDefined( level.safeSpawns["attackers"].mild ) )
						spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.safeSpawns["attackers"].mild );

					if ( isDefined( self.spawnKilled ) && self.spawnKilled > 2 )
						spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.safeSpawns["attackers"] );
				}
			}
			else
				spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
		}
		else
		{
			spawn_defenders_1 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_defender_spawn_" + ( level.totalBombsSpawned - 1 ) );
			spawn_defenders_2 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_defender_spawn_" + level.totalBombsSpawned );
			spawn_defenders_3 = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_defender_spawn_" + ( level.totalBombsSpawned + 1 ) );

			if ( !level.aPlanted && !level.bPlanted && !level.bDestroyed && !level.aDestroyed )
				spawnPoints = array_combine( spawn_defenders_1, spawn_defenders_2 );

			else if ( level.aPlanted && !level.bPlanted )
				spawnPoints = spawn_defenders_1;
			else if ( level.bPlanted && !level.aPlanted )
				spawnPoints = spawn_defenders_2;
			else if ( level.aDestroyed && !level.bDestroyed && !level.bPlanted && level.totalBombsSpawned <= level.bombzones.size )
				spawnPoints = array_combine( spawn_defenders_2, spawn_defenders_3 );
			else
				spawnPoints = array_combine( spawn_defenders_1, spawn_defenders_2 );

			if ( isDefined( self.timeAlive ) && self.timeAlive <= 4 )
			{
				if ( getDvarInt( "scr_" + level.gametype + "_spawnMethod" ) == 0 )
				{
					if ( isDefined( self.spawnKilled ) && self.spawnKilled >= 3 )
						number = randomint( level.totalBombsSpawned + ( self.spawnKilled - 1 ) );
					else
						number = randomint( level.totalBombsSpawned + 1 );

					if ( number == 0 )
						number = number + 1;

					spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_rush_defender_spawn_" + number );
					self.spawnKilled++;
				}

				if ( getDvarInt( "scr_" + level.gametype + "_spawnMethod" ) == 1 )
				{
					spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
					self.spawnKilled++;

					if ( isDefined( self.spawnKilled ) && self.spawnKilled > 2 )
						self.parachuteSpawn = 1;
				}
				else
				{
					self.spawnKilled++;
					spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnpoints );

					if ( isDefined( level.safeSpawns["defenders"].mild ) )
						spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.safeSpawns["defenders"].mild );

					if ( isDefined( self.spawnKilled ) && self.spawnKilled > 2 )
						spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( level.safeSpawns["defenders"] );
				}
			}
		}

		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_NearTeam( spawnPoints );
	}

	return spawnPoint;
}


onNormalDeath( victim, attacker, lifeId )
{
	score = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );
	assert( isDefined( score ) );

	attacker maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( attacker.pers["team"], score );

	if ( game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]] )
		attacker.finalKill = true;
}

onTimeLimit()
{
}


dropBombModel( player, site )
{
	trace = bulletTrace( player.origin + ( 0, 0, 20 ), player.origin - ( 0, 0, 2000 ), false, player );

	tempAngle = randomfloat( 360 );
	forward = ( cos( tempAngle ), sin( tempAngle ), 0 );
	forward = vectornormalize( forward - common_scripts\utility::vector_multiply( trace["normal"], vectordot( forward, trace["normal"] ) ) );
	dropAngles = vectortoangles( forward );

	level.ddBombModel[ site ] = spawn( "script_model", trace["position"] );
	level.ddBombModel[ site ].angles = dropAngles;
	level.ddBombModel[ site ] setModel( "prop_suitcase_bomb" );
}

playDemolitionTickingSound( site )
{
	self endon( "death" );
	self endon( "stopTicking" );
	level endon( "game_ended" );

	for ( ;; )
	{
		self playSound( "ui_mp_suitcasebomb_timer" );

		if ( !isDefined( site.waitTime ) || site.waitTime > 10 )
			wait 1.0;
		else if ( isDefined( site.waitTime ) && site.waitTime > 5 )
			wait 0.5;
		else
			wait 0.25;

		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}

bombPlanted( destroyedObj, player )
{
	destroyedObj endon( "defused" );

	level.aliveBombsPlanted += 1;
	self setBombTimerDvar();
	maps\mp\gametypes\_gamelogic::pauseTimer();
	level.timePauseStart = getTime();
	level.timeLimitOverride = true;

	level.bombPlanted = true;
	level.destroyedObject = destroyedObj;

	if ( level.destroyedObject.label == "_a" )
		level.aPlanted = true;
	else
		level.bPlanted = true;

	level.destroyedObject.bombPlanted = true;

	destroyedObj.visuals[0] thread playDemolitionTickingSound( destroyedObj );
	level.tickingObject = destroyedObj.visuals[0];

	self dropBombModel( player, destroyedObj.label );
	destroyedObj.bombDefused = false;
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	destroyedObj setUpForDefusing();

	destroyedObj BombTimerWait( destroyedObj ); //waits for bomb to explode!

	destroyedObj thread bombHandler( player, "explode" );
}

BombTimerWait( siteLoc )
{
	level endon( "game_ended" );
	level endon( "bomb_defused" + siteLoc.label );

	siteLoc.waitTime = level.bombTimer;

	while ( siteLoc.waitTime >= 0 )
	{
		siteLoc.waitTime--;
		setDvar( "ui_bombtimer" + siteLoc.label, siteLoc.waitTime );

		//self maps\mp\gametypes\_gameobjects::updateTimer( waitTime, true );

		if ( siteLoc.waitTime >= 0 )
			wait 1;

		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}


onUseObject( player )
{
	team = player.pers["team"];
	otherTeam = level.otherTeam[team];

	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player notify( "bomb_planted" );
		player playSound( "mp_bomb_plant" );

		thread teamPlayerCardSplash( "callout_bombplanted", player );
		//iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );
		leaderDialog( "bomb_planted" );

		player thread maps\mp\gametypes\_hud_message::SplashNotify( "plant", maps\mp\gametypes\_rank::getScoreInfoValue( "plant" ) );
		player thread maps\mp\gametypes\_rank::giveRankXP( "plant" );
		maps\mp\gametypes\_gamescore::givePlayerScore( "plant", player );
		player incPlayerStat( "bombsplanted", 1 );
		player thread maps\mp\_matchdata::logGameEvent( "plant", player.origin );
		player.bombPlantedTime = getTime();

		level thread bombPlanted( self, player );

		level.bombOwner = player;
		self.useWeapon = "briefcase_bomb_defuse_mp";
		self setUpForDefusing();
	}
	else // defused the bomb
		self thread bombHandler( player, "defused" );
}

restartTimer()
{
	if ( level.aliveBombsPlanted <= 0 )
	{
		maps\mp\gametypes\_gamelogic::resumeTimer();
		level.timePaused = ( getTime() - level.timePauseStart ) ;
		level.timeLimitOverride = false;
	}
}

bombHandler( player, destType )
{
	self.visuals[0] notify( "stopTicking" );
	level.aliveBombsPlanted -= 1;

	self.bombPlanted = 0;

	self restartTimer();
	self setBombTimerDvar();

	setDvar( "ui_bombtimer" + self.label, -1 );
	self maps\mp\gametypes\_gameobjects::updateTimer( 0, false );

	if ( level.gameEnded )
		return;

	if ( destType == "explode" )
	{
		level.bombExploded += 1;
		//level thread pointsHandle(game["attackers"], level.bombPoints);

		level.teamtickets[game["attackers"]] = ( level.bombPoints * countTeamPlayers( game["attackers"] ) );
		//level thread pointsHandle(game["attackers"], level.bombPoints, 1);

		wait 0.09;

		if ( self.label == "_a" )
			level.aPlanted = false;
		else
			level.bPlanted = false;

		explosionOrigin = self.curorigin;
		level.ddBombModel[ self.label ] Delete();

		if ( isDefined( player ) )
		{
			self.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
			player incPlayerStat( "targetsdestroyed", 1 );
		}
		else
			self.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );

		rot = randomfloat( 360 );
		explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + ( 0, 0, 50 ), ( 0, 0, 1 ), ( cos( rot ), sin( rot ), 0 ) );
		triggerFx( explosionEffect );

		PlayRumbleOnPosition( "grenade_rumble", explosionOrigin );
		earthquake( 0.75, 2.0, explosionOrigin, 2000 );

		thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );

		if ( isDefined( self.exploderIndex ) )
			exploder( self.exploderIndex );

		self maps\mp\gametypes\_gameobjects::disableObject();

		if ( self.label == "_a" )
			level.aDestroyed = true;
		else
			level.bDestroyed = true;

		wait 0.6;

		level.aliveBombs--;
		level.totalBombsDestroyed++;
	}
	else //defused
	{
		player notify( "bomb_defused" );
		self notify( "defused" );

		if ( self.label == "_a" )
			level.aPlanted = false;
		else
			level.bPlanted = false;

//		if ( !level.hardcoreMode )
//			iPrintLn( &"MP_EXPLOSIVES_DEFUSED_BY", player );

		leaderDialog( "bomb_defused" );

		level thread teamPlayerCardSplash( "callout_bombdefused", player );

		level thread bombDefused( self );
		self resetBombzone();

		if ( isDefined( level.bombOwner ) && ( level.bombOwner.bombPlantedTime + 4000 + ( level.defuseTime*1000 ) ) > getTime() && isReallyAlive( level.bombOwner ) )
			player thread maps\mp\gametypes\_hud_message::SplashNotify( "ninja_defuse", ( maps\mp\gametypes\_rank::getScoreInfoValue( "defuse" ) ) );
		else
			player thread maps\mp\gametypes\_hud_message::SplashNotify( "defuse", maps\mp\gametypes\_rank::getScoreInfoValue( "defuse" ) );

		player thread maps\mp\gametypes\_rank::giveRankXP( "defuse" );
		maps\mp\gametypes\_gamescore::givePlayerScore( "defuse", player );
		player incPlayerStat( "bombsdefused", 1 );
		player thread maps\mp\_matchdata::logGameEvent( "defuse", player.origIn );
	}

}

bombDefused( siteDefused )
{
	level.tickingObject maps\mp\gametypes\_gamelogic::stopTickingSound();
	siteDefused.bombDefused = true;
	self setBombTimerDvar();

	setDvar( "ui_bombtimer" + siteDefused.label, -1 );

	level notify( "bomb_defused" + siteDefused.label );
}

resetBombZone()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.plantTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_PLANTING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_PLANT_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( level.ddBomb );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_target" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_target" + self.label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self.useWeapon = "briefcase_bomb_mp";

	if ( self.label == "_a" )
		level.aPlanted = false;
	else
		level.bPlanted = false;

}

setUpForDefusing()
{
	self maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	self maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	self maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	self maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	self maps\mp\gametypes\_gameobjects::setKeyObject( undefined );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defuse" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + self.label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	self thread fixThreeBombsGlitch();
}

fixThreeBombsGlitch()
{
	level endon( "bomb_defused" + self.label );
	self endon( "bomb_notdefused" );

	for ( ;; )
	{
		if ( isDefined( self.waitTime ) && self.waitTime < level.defusetime )
		{
			self maps\mp\gametypes\_gameobjects::allowUse( "none" );
			self notify( "bomb_notdefused" );
		}

		wait 0.5;
	}
}

onBeginUse( player )
{
	label = self maps\mp\gametypes\_gameobjects::getLabel();

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		player playSound( "mp_bomb_defuse" );
		player.isDefusing = true;
		self.defusingPlayer = player;

		bestDistance = 9000000;
		closestBomb = undefined;

		if ( isDefined( level.ddBombModel ) )
		{
			foreach ( bomb in level.ddBombModel )
			{
				if ( !isDefined( bomb ) )
					continue;

				dist = distanceSquared( player.origin, bomb.origin );

				if ( dist < bestDistance )
				{
					bestDistance = dist;
					closestBomb = bomb;
				}
			}

			assert( isDefined( closestBomb ) );
			player.defusing = closestBomb;
			closestBomb hide();
		}
	}
	else
		player.isPlanting = true;
}

onEndUse( team, player, result )
{
	if ( !isDefined( player ) )
		return;

	if ( isAlive( player ) )
	{
		player.isDefusing = false;
		player.isPlanting = false;
	}

	if ( self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		if ( isDefined( player.defusing ) && !result )
			player.defusing show();
	}
}

onCantUse( player )
{
	player iPrintLnBold( &"MP_BOMBSITE_IN_USE" );
}

onReset()
{
}

initGametypeAwards()
{
	maps\mp\_awards::initStatAward( "targetsdestroyed", 0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "bombsplanted", 0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "bombsdefused", 0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "bombcarrierkills", 0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "bombscarried", 0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "killsasbombcarrier", 0, maps\mp\_awards::highestWins );
}