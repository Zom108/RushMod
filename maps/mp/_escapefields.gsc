#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

escapeZones()
{
SetDvarIfUninitialized("scr_escapefields", "1" );

if(getdvarint("scr_escapefields") == 1 && !isdefined(level.escapefieldLoaded))
{
SetDvarIfUninitialized("scr_escapefieldTime", 5 );

level.EscapeFieldTime = getdvarint("scr_escapefieldTime");

escapeFields = getentarray("escapefield", "targetname");


foreach ( trigger in escapeFields )
{
trigger thread common_scripts\_dynamic_world::triggerTouchThink( ::playerEnterArea, ::playerLeaveArea );
}

level.escapefieldLoaded = 1;

thread PlayerConnectEscape();
}

}

PlayerConnectEscape()
{
	for ( ;; )
	{
		level waittill ( "connected", player );
		player thread CreateEscapeHud();
		player.numAreas = 0;
		player thread onPlayerSpawned();
	}
}


CreateEscapeHud()
{
	self.WarningText = createFontString( "HUDBIG", 0.8 );
	self.WarningText setPoint( "CENTER", "CENTER", 0, 0 );
	self.WarningText.alpha = 0;
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
		self setblurforplayer(0, 1);
		self.WarningText.alpha = 0;
	}
}

playerEnterArea( trigger )
{
	self.numAreas++;
		
	if ( self.numAreas == 1 )
	self warningMessage();
	
}


playerLeaveArea( trigger )
{
	self.numAreas--;
	assert( self.numAreas >= 0 );
	
	if ( self.numAreas != 0 )
		return;
	
	self.poison = 0;
	self notify( "backToMap");
	
	self.warningText fadeovertime( 3 );
	self.warningText.alpha = 0;	
	self setblurforplayer(0, 3);
}


warningMessage()
{
	self endon( "disconnect" );
	self endon( "game_ended" );
	self endon( "death" );
	self endon( "backToMap" );
		
	self.warningText.alpha = 1;
	self thread flashText(self.warningText);
			
	self setblurforplayer(20, level.EscapeFieldTime);
	
	
	for( i = level.EscapeFieldTime; i > 0; i--)
	{
	self.WarningText setText("Turn back! You are leaving the mission zone: " + i);	
	wait 1;
	}
	
	self setblurforplayer(0, 1);
	
	wait 0.5;
	
	self _suicide();
	self.WarningText.alpha = 0;	
}

flashText(text)
{
self endon("death");
self endon("backToMap");

time = 3;

for( i = 0; i <= level.EscapeFieldTime; i++)
{
text ChangeFontScaleOverTime( time/3 );
text.fontscale = 1.4;

text FadeOverTime( time/3 );  
text.alpha = 1;

wait (time/3);

text ChangeFontScaleOverTime( time/3 );
text.fontscale = 0.8;

text FadeOverTime( time/3 );  
text.alpha = 0;
wait (time/3);
}
}