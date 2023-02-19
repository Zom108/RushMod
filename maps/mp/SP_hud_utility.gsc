#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

add_hint_string( name, string, optionalFunc )
{
	if ( !isdefined( level.trigger_hint_string ) )
	{
		level.trigger_hint_string = [];
		level.trigger_hint_func = [];
	}

	AssertEx( IsDefined( name ), "Set a name for the hint string. This should be the same as the script_hint on the trigger_hint." );
	AssertEx( IsDefined( string ), "Set a string for the hint string. This is the string you want to appear when the trigger is hit." );
	AssertEx( !isdefined( level.trigger_hint_string[ name ] ), "Tried to redefine hint " + name );

	level.trigger_hint_string[ name ] = string;
	PreCacheString( string );

	if ( IsDefined( optionalFunc ) )
		level.trigger_hint_func[ name ] = optionalFunc;
}

/*
=============
///ScriptDocBegin
"Name: display_hint( <hint> )"
"Summary: Displays a hint created with add_hint_string."
"Module: Utility"
"MandatoryArg: <hint> : The hint reference created with add_hint_string."
"Example: display_hint( "huzzah" )"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
display_hint( hint, parm1, parm2, parm3 )
{
	player = self;

	// hint triggers have an optional function they can boolean off of to determine if the hint will occur
	// such as not doing the NVG hint if the player is using NVGs already
	if ( IsDefined( level.trigger_hint_func[ hint ] ) )
	{
		if ( player [[ level.trigger_hint_func[ hint ] ]]() )
			return;

		player thread HintPrint( level.trigger_hint_string[ hint ], level.trigger_hint_func[ hint ], parm1, parm2, parm3, 30 );
	}
	else
		player thread HintPrint( level.trigger_hint_string[ hint ], undefined, undefined, undefined, undefined, 30 );
}


HintPrint( string, breakfunc, parm1, parm2, parm3, timeout )
{
	Assert( IsPlayer( self ) );

	if ( !isalive( self ) )
		return;

	MYFADEINTIME = 1.0;
	MYFLASHTIME = 0.75;
	MYALPHAHIGH = 0.95;
	MYALPHALOW = 0.4;

	if ( isdefined( self.current_global_hint ) )
	{
		if ( self.current_global_hint == string )
			return;
	}

	//ent_flag_waitopen( "global_hint_in_use" );
	if ( isdefined( self.current_global_hint ) )
	{
		if ( self.current_global_hint == string )
			return;
	}

	//ent_flag_set( "global_hint_in_use" );

	self.current_global_hint = string;

	Hint = createFontString( "default", 2 );

	//thread destroy_hint_on_friendlyfire( hint );
	//level endon( "friendlyfire_mission_fail" );

	//Hint.color = ( 1, 1, .5 ); //remove color so that color highlighting on PC can show up.
	Hint.alpha = 0.9;
	Hint.x = 0;
	Hint.y = -68;
	Hint.alignx = "center";
	Hint.aligny = "middle";
	Hint.horzAlign = "center";
	Hint.vertAlign = "middle";
	Hint.foreground = false;
	Hint.hidewhendead = true;
	Hint.hidewheninmenu = true;

	Hint SetText( string );

	Hint.alpha = 0;
	Hint FadeOverTime( MYFADEINTIME );
	Hint.alpha = MYALPHAHIGH;
	HintPrintWait( MYFADEINTIME, breakfunc );

	parms = 0;

	if ( IsDefined( parm3 ) )
		parms = 3;
	else if ( IsDefined( parm2 ) )
		parms = 2;
	else if ( IsDefined( parm1 ) )
		parms = 1;

	timeout_ent = SpawnStruct();
	timeout_ent.timed_out = false;

	if ( IsDefined( timeout ) )
		timeout_ent thread hint_timeout( timeout );

	if ( IsDefined( breakfunc ) )
	{
		for ( ;; )
		{
			Hint FadeOverTime( MYFLASHTIME );
			Hint.alpha = MYALPHALOW;
			HintPrintWait( MYFLASHTIME, breakfunc );

			if ( parms == 3 )
			{
				if ( [[ breakfunc ]]( parm1, parm2, parm3 ) )
					break;
			}
			else if ( parms == 2 )
			{
				if ( [[ breakfunc ]]( parm1, parm2 ) )
					break;
			}
			else if ( parms == 1 )
			{
				if ( [[ breakfunc ]]( parm1 ) )
					break;
			}
			else
			{
				if ( [[ breakfunc ]]() )
					break;
			}

			Hint FadeOverTime( MYFLASHTIME );
			Hint.alpha = MYALPHAHIGH;
			HintPrintWait( MYFLASHTIME, breakfunc );

			if ( timeout_ent.timed_out )
				break;

			if ( parms == 3 )
			{
				if ( [[ breakfunc ]]( parm1, parm2, parm3 ) )
					break;
			}
			else if ( parms == 2 )
			{
				if ( [[ breakfunc ]]( parm1, parm2 ) )
					break;
			}
			else if ( parms == 1 )
			{
				if ( [[ breakfunc ]]( parm1 ) )
					break;
			}
			else
			{
				if ( [[ breakfunc ]]() )
					break;
			}
		}
	}
	else
	{
		for ( i = 0; i < 1; i++ )
		{
			Hint FadeOverTime( MYFLASHTIME );
			Hint.alpha = MYALPHALOW;
			HintPrintWait( MYFLASHTIME, breakfunc );

			Hint FadeOverTime( MYFLASHTIME );
			Hint.alpha = MYALPHAHIGH;
			HintPrintWait( MYFLASHTIME, breakfunc );
		}
	}

	hint notify( "destroying" );
	self.current_global_hint = undefined;
	Hint Destroy();
	//ent_flag_clear( "global_hint_in_use" );
}

hintPrintWait( length, breakfunc )
{
	if ( !isdefined( breakfunc ) )
	{
		wait( length );
		return;
	}

	timer = length * 20;

	for ( i = 0; i < timer; i++ )
	{
		if ( [[ breakfunc ]]() )
			break;

		wait( 0.05 );
	}
}

hint_timeout( timeout )
{
	wait( timeout );
	self.timed_out = true;
}