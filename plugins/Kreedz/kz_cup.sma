#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <colorchat>

#pragma semicolon 1

#define PREFIX "[XJ]"
#define ADMIN_LEVEL	ADMIN_RESERVATION
#define MARKER_MODEL	"models/can.mdl"
#define MAX_MARKERS	1000

#define MARKER_KEYS	(1<<0) | (1<<1) | (1<<2) | (1<<3) | (1<<4) | (1<<5) | (1<<6) | (1<<7) | (1<<8) | (1<<9)
#define ADMIN_KEYS (1<<0) | (1<<1) | (1<<2) | (1<<3) | (1<<4) | (1<<8) | (1<<9)

enum {
	CUP_NONE = 0,
	CUP_RUNNING,
	CUP_FINISHED
}

new gClimbers;			// The Number of climbers
new gClimber[33][33];		// The Climbers names
new gClimberIndex[33];
new Float:gClimbersPos[33][3];	// The Positions of climbers.

new gCupStatus;
new gCupTime;
new gAnnTime;
new gCountDown;
new gHudSync;
new gMaxPlayers;
new gMenuPos[ 33 ];

new gCupStartTime;
new iAnnouncments;

enum { N1, N2, N3, N4, N5, N6, N7, N8, N9, N0 };

new bool:gUserConnected[ 33 ];
new bool:gUserIsBOT[ 33 ];
new gUserIsAlive[ 33 ];
new gszMarkersMenu[ 256 ];
new gszCupMenuStart[ 128 ];
new gszCupMenuEnd[ 128 ];

new gMarkersCount;
new gszMarkersFile[ 64 ];
new gMarkerEnt[ MAX_MARKERS ];
new bool:gbMarkersVisible;
new Float:gflMarkerPos[ MAX_MARKERS ][ 3 ];

public plugin_init() {
	register_plugin( "KZ CUP", "1.0", "xPaw" );
	
	// Forwards
	register_think( "xpaw_cup_countdown", "fwdThink_Countdown" );
	register_think( "xpaw_cup_timer", "fwdThink_Timer" );
	
	// Events
	register_event( "ResetHUD", "Event_Health", "b" );
	register_event( "Health", "Event_Health", "b" );
	
	// Commands
	register_clcmd( "say /poscheck", "cmdPosMenu" );
	register_clcmd( "say /cup",	 "cmdAdminMenu" );
	register_clcmd( "say /cupmenu",	 "cmdAdminMenu" );
	register_clcmd( "say /markers", "cmdMarkersMenu" );
	register_clcmd( "say /locs", "cmdMarkersMenu" );
	
	// Console commands
	register_concmd( "cup_setmarker", "cmdMarkersSet", ADMIN_LEVEL, "Create cup marker" );
	register_concmd( "cup_nearestmarker", "cmdMarkersNearest", ADMIN_LEVEL, "Print nearest cup marker" );
	
	// Menus
	register_menucmd( register_menuid( "PosMenu" ), 1023, "handlePosMenu" );
	register_menucmd( register_menuid( "CupMenu" ), ADMIN_KEYS, "handleAdminMenu" );
	register_menucmd( register_menuid( "MarkersMenu" ), MARKER_KEYS, "handleMarkersMenu" );
	
	gHudSync	= CreateHudSyncObj();
	gMaxPlayers	= get_maxplayers();
	
	gCupStatus	= CUP_NONE;
	gCupTime	= 300;
	gAnnTime 	= 30;
	gCountDown 	= 10;
}

public plugin_precache() {
	precache_sound( "SoUlFaThEr/zero.wav" );
	precache_sound( "SoUlFaThEr/one.wav" );
	precache_sound( "SoUlFaThEr/two.wav" );
	precache_sound( "SoUlFaThEr/three.wav" );
	precache_sound( "SoUlFaThEr/four.wav" );
	precache_sound( "SoUlFaThEr/five.wav" );
	precache_sound( "SoUlFaThEr/six.wav" );
	precache_sound( "SoUlFaThEr/seven.wav" );
	precache_sound( "SoUlFaThEr/eight.wav" );
	precache_sound( "SoUlFaThEr/nine.wav" );
	precache_sound( "SoUlFaThEr/ten.wav" );
	
	precache_sound( "SoUlFaThEr/fifty.wav" );
	precache_sound( "SoUlFaThEr/fifteen.wav" );
	precache_sound( "SoUlFaThEr/fourty.wav" );
	precache_sound( "SoUlFaThEr/thirty.wav" );
	
	precache_sound( "SoUlFaThEr/minutes.wav" );
	precache_sound( "SoUlFaThEr/seconds.wav" );
	precache_sound( "SoUlFaThEr/remaining.wav" );
	
	precache_model( MARKER_MODEL );
}

public plugin_cfg( ) {
	new iSize = sizeof( gszMarkersMenu );
	add( gszMarkersMenu, iSize, "\r#kz.xPaw \wCup Markers Menu^n^n" );
	add( gszMarkersMenu, iSize, "\r1. \wSet a marker^n" );
	add( gszMarkersMenu, iSize, "\r2. \wDelete last cup marker^n^n" );
	add( gszMarkersMenu, iSize, "\r3. \wHide cup markers^n" );
	add( gszMarkersMenu, iSize, "\r4. \wShow cup markers^n^n" );
	add( gszMarkersMenu, iSize, "\r5. \wLoad cup markers^n" );
	add( gszMarkersMenu, iSize, "\r6. \wSave cup markers^n^n" );
	add( gszMarkersMenu, iSize, "\r9. \wShow nearest cup marker^n" );
	add( gszMarkersMenu, iSize, "\r0. \wExit" );
	
	iSize = sizeof( gszCupMenuStart );
	add( gszCupMenuStart, iSize, "\r#kz.xPaw \wCup Admin Menu^n^n" );
	add( gszCupMenuStart, iSize, "\r1. \wStart Cup^n" );
	add( gszCupMenuStart, iSize, "\r2. \wStop Cup^n^n" );
	
	iSize = sizeof( gszCupMenuEnd );
	add( gszCupMenuEnd, iSize, "\r5. \wDelete finish positions^n^n" );
	add( gszCupMenuEnd, iSize, "\r9. \wGoto markers menu^n" );
	add( gszCupMenuEnd, iSize, "\r0. \wExit" );
	
	// Other Stuff
	new szDataDir[ 48 ], szMapname[ 32 ];
	get_localinfo( "amxx_datadir", szDataDir, charsmax( szDataDir ) );
	get_mapname( szMapname, charsmax( szMapname ) );
	
	format( gszMarkersFile, charsmax( gszMarkersFile ), "%s/kreedz/cup/%s.txt", szDataDir, szMapname );
	
	LoadMarkers( );
}

// THINK FORWARDS
/////////////////////////////////////////////
public fwdThink_Countdown( iEntity ) {
	fnShowTimeRemining( gCountDown, 1 );
	
	gCountDown--;
	
	if( gCountDown <= -1 ) {
		engfunc( EngFunc_RemoveEntity, iEntity );
		
		for( new i = 1; i < gMaxPlayers; i++ ) {
			if( gUserIsAlive[i] && !gUserIsBOT[ i ] )
				set_pev( i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN );
			else if( gUserConnected[ i ] && !gUserIsAlive[i] )
				set_pev( i, pev_flags, pev(i, pev_flags) & ~FL_FROZEN );
		}
		
		gCupStartTime	=  floatround(get_gametime());
		gCupStatus	= CUP_RUNNING;
		gCountDown	= 10;
		
		new iEntityTimer = engfunc( EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") );
		set_pev( iEntityTimer, pev_classname, "xpaw_cup_timer" );
		set_pev( iEntityTimer, pev_nextthink, get_gametime() + 1.0 );
	} else
		set_pev( iEntity, pev_nextthink, get_gametime() + 1.0 );
}

public fwdThink_Timer( iEntity ) {
	static iClimbTime, iLeftTime;
	iClimbTime	= floatround( get_gametime() ) - gCupStartTime;
	iLeftTime	= gCupTime - iClimbTime;
	
	if( (gAnnTime * iAnnouncments) <= iClimbTime ) {
		iAnnouncments++;
		
		fnShowTimeRemining( iLeftTime, 0 );
	}
	
	// Map status start
	static i, szName[ 32 ], szFormat[ 40 ], iMarker, Float:iPercent;
	new szHud[ 512 ];
	
	new szCreators[ 32 ][ 32 ], iCreated[ 32 ][ 2 ];
	for( i = 0; i < sizeof iCreated; i++ ) {
		iCreated[ i ][ 1 ] = i;
	}
	
	for( i = 1; i <= gMaxPlayers; i++ ) {
		if( !gUserIsAlive[ i ] || gUserIsBOT[ i ] )
			continue;
		
		iMarker = GetNearestMarker( i );
		
		if( iMarker > 0 ) {
			iPercent = float( iMarker ) / float( gMarkersCount ) * 100.0;
			
			get_user_name( i, szName, charsmax( szName ) ); // todo - store nicks in global array...
			format( szCreators[ i ], sizeof( szCreators ), szName );
			
			iCreated[ i ][ 0 ] = floatround( iPercent );
		}
	}
	
	SortCustom2D( iCreated, sizeof iCreated, "ComparePercent" );
	
	static iIndex;
	for( i = 0; i < sizeof( szCreators ); i++ ) {
		iIndex = iCreated[ i ][ 1 ];
		
		if( gUserIsAlive[ iIndex ] ) {
			format( szFormat, charsmax( szFormat ), "(%i%s)  %s^n", iCreated[ i ][ 0 ], "%%", szCreators[ iIndex ] );
			add( szHud, charsmax( szHud ), szFormat );
		}
	}
	
	set_hudmessage( 255, 100, 0, 0.02, 0.2, 0, 0.0, 1.1, 0.0, 0.0, 3 );
	show_hudmessage( 0, szHud );
	// Map status end
	
	if( iLeftTime < 11 )
		fnShowTimeRemining( iLeftTime, 0 );
	
	if( iLeftTime <= 0 )
		fnFinishCup();
	
	if( pev_valid( iEntity ) )
		set_pev( iEntity, pev_nextthink, get_gametime() + 1.0 );
}

public ComparePercent( const iElem1[], const iElem2[], const iArray[], szData[], iSize ) {
	if( iElem1[ 0 ] < iElem2[ 0 ] ) {
		return 1;
	}
	else if( iElem1[ 0 ] > iElem2[ 0 ] ) {
		return -1;
	}
	
	return 0;
}

// COMMANDS
/////////////////////////////////////////////
public cmdPosMenu( id ) {
	fnPositionsMenu( id, gMenuPos[id] = 0 );
	
	return PLUGIN_CONTINUE;
}

public cmdMarkersMenu( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL )
		show_menu( id, MARKER_KEYS, gszMarkersMenu, -1, "MarkersMenu" );
	
	return PLUGIN_HANDLED;
}

public cmdAdminMenu( id ) {
	if ( get_user_flags( id ) & ADMIN_LEVEL ) {
		new szMenu[ 512 ], szGay[ 64 ];
		add( szMenu, charsmax( szMenu ), gszCupMenuStart );
		formatex( szGay, charsmax( szGay ), "\r3. \wTime of cup: \d%d minutes^n", ( gCupTime / 60 ) );
		add( szMenu, charsmax( szMenu ), szGay );
		formatex( szGay, charsmax( szGay ), "\r4. \wAnnouncement interval of time: \d%d seconds^n^n", gAnnTime );
		add( szMenu, charsmax( szMenu ), szGay );
		add( szMenu, charsmax( szMenu ), gszCupMenuEnd );
		
		show_menu( id, ADMIN_KEYS, szMenu, -1, "CupMenu" );
	}
	
	return PLUGIN_HANDLED;
}

public fnPositionsMenu( id, pos ) {
	if( pos < 0 )
		return PLUGIN_CONTINUE;
	
	if( gCupStatus != CUP_FINISHED ) {
		ColorChat(id, BLUE, "^x04%s^x01 Cup-menu is only available when the climb cup has finished.", PREFIX );
		
		return PLUGIN_CONTINUE;
	}
	
	new iPage = pos + 1, iKeys = (1<<9), iKey, szMenu[512];
	new iPages = (gClimbers / 8) + ( (gClimbers % 8) ? 1 : 0 );
	new iLen = format(szMenu, 511, "\r#kz.xPaw \wPositions check menu\R \d%d/%d^n\w^n", iPage, iPages );
	
	new iMarker, Float:iPercent;
	for( new i = pos * 8; i < gMaxPlayers; i++ ) {
		if( !equal( gClimber[i], "" ) && iKey < 8 ) {
			if( gClimbersPos[i][0] != 0 && gClimbersPos[i][1] != 0 && gClimbersPos[i][2] != 0 ) {
				gClimberIndex[iKey] = i;
				iKeys |= (1<<iKey);
				iKey++;
				
				iMarker = GetNearestMarkerByOrigin( gClimbersPos[i] );
				if( iMarker > 0 ) {
					iPercent = float( iMarker ) / float( gMarkersCount ) * 100.0;
					
					iLen += format( szMenu[iLen], 511 - iLen, "\r%d.\w %s \r\R %i%%^n", iKey, gClimber[i], floatround( iPercent ) );
				} else
					iLen += format( szMenu[iLen], 511 - iLen, "\r%d.\w %s^n", iKey, gClimber[i] );
			} else {
				gClimberIndex[iKey] = i;
				iKey++;
				
				iLen += format( szMenu[iLen], 511 - iLen, "\r%d.\d %s^n", iKey, gClimber[i] );
			}
		}
	}
	
	if( iPage != iPages ) {
		iLen += format( szMenu[iLen], 511 - iLen, "^n\r9. \wNext...^n\r0. \wBack" );
		
		iKeys |= (1<<8);
	} else
		iLen += format( szMenu[iLen], 511 - iLen, "^n\r0. \wExit" );
	
	show_menu( id, iKeys, szMenu, -1, "PosMenu" );
	
	return PLUGIN_CONTINUE;
}

// MENU HANDLES
/////////////////////////////////////////////
public handleMarkersMenu( id, iKey ) {
	switch( iKey ) {
		case N1: { cmdMarkersSet( id ); }
		case N2: { cmdMarkersRemove( id ); }
		case N3: { HideMarkers( ); }
		case N4: { ShowMarkers( ); }
		case N5: { LoadMarkers( id ); }
		case N6: { SaveMarkers( id ); }
		
		case N9: { cmdMarkersNearest( id ); }
		case N0: { return; }
	}
	
	cmdMarkersMenu( id );
}

public handlePosMenu( id, key ) {
	if( gCupStatus != CUP_FINISHED )
		return PLUGIN_HANDLED;
	
	switch( key ) {
		case 8: fnPositionsMenu( id, ++gMenuPos[id] );
		case 9: fnPositionsMenu( id, --gMenuPos[id] );
		default: {
			ForceDuck( id );
			engfunc( EngFunc_SetOrigin, id, gClimbersPos[gMenuPos[id] * 8 + gClimberIndex[key]] );
			ColorChat(id, RED, "%s^x01 You have been teleported to the finish position of climber^x03 %s^x01.", PREFIX, gClimber[gMenuPos[id] * 8 + gClimberIndex[key]] );
			
			fnPositionsMenu( id, gMenuPos[id] );
		}
	}
	
	return PLUGIN_HANDLED;
}

public handleAdminMenu( id, key ) {
	switch( key ) {
		case 0: fnStartCup( id );
		case 1: fnStopCup( id );
		case 2: {
			gCupTime += 60;
			
			if( gCupTime > 600 )
				gCupTime = 60;
			
			cmdAdminMenu( id );
		}
		case 3: {
			gAnnTime += 15;
			
			if( gAnnTime > 45 )
				gAnnTime = 15;
			
			cmdAdminMenu( id );
		}
		case 4: {
			for( new i = 0; i < gMaxPlayers; i++ ) {
				gClimbersPos[i][0] = 0.0;
				gClimbersPos[i][1] = 0.0;
				gClimbersPos[i][2] = 0.0;
				gClimber[i] = "";
				gClimberIndex[i] = 0;
			}
			
			gClimbers = 0;
			gCupStatus = CUP_NONE;
			ColorChat(id, RED, "%s^x01 Deleted all positions of players.", PREFIX);
			
			cmdAdminMenu( id );
		}
		case 8: cmdMarkersMenu( id );
		default: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

// START & STOP
/////////////////////////////////////////////
public fnStartCup( id ) {
	for( new i = 1; i < gMaxPlayers; i++ ) {
		gClimbersPos[i][0] = 0.0;
		gClimbersPos[i][1] = 0.0;
		gClimbersPos[i][2] = 0.0;
		gClimber[i] = "";
		gClimberIndex[i] = 0;
	}
	
	server_cmd( "xj_checkpoints 0" );
	
	gCountDown	= 10;
	iAnnouncments	= 0;
	gClimbers = 0;
	
	new iEntityTimer = engfunc( EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target") );
	set_pev( iEntityTimer, pev_classname, "xpaw_cup_countdown" );
	set_pev( iEntityTimer, pev_nextthink, get_gametime() + 1.0 );
	
	new Float:vOrigin[3];
	pev( id, pev_origin, vOrigin );
	
	for( new i = 1; i < gMaxPlayers; i++ ) {
		if( gUserIsAlive[i] && !gUserIsBOT[i] ) {
			set_pev( i, pev_origin, vOrigin );
			set_pev( i, pev_flags, pev(i, pev_flags) | FL_FROZEN );
		}
	}
	
	set_hudmessage(0, 100, 255, -1.0, 0.87, 0, 0.0, 8.0, 0.4, 0.4, 2);
	show_hudmessage(0, "* Countdown voice by SoUlFaThEr *" );
	
	new szAdminName[32];
	get_user_name( id, szAdminName, 31 );
	ColorChat(0, RED, "%s^x04 Jump Cup has been started!^x01 Admin:^x04 %s^x01.", PREFIX, szAdminName );
	
	return PLUGIN_HANDLED;
}

public fnStopCup( id ) {
	new iEntityTimer = -1;
	while( ( iEntityTimer = engfunc(EngFunc_FindEntityByString, iEntityTimer, "classname", "xpaw_cup_timer" ) ) )
		engfunc( EngFunc_RemoveEntity, iEntityTimer );
	
	iEntityTimer = -1;
	while( ( iEntityTimer = engfunc(EngFunc_FindEntityByString, iEntityTimer, "classname", "xpaw_cup_countdown" ) ) )
		engfunc( EngFunc_RemoveEntity, iEntityTimer );
	
	for( new i = 1; i < gMaxPlayers; i++ ) {
		if( gUserConnected[ i ] && !gUserIsBOT[ i ] ) {
			if( gUserIsAlive[i] ) {
				pev( i, pev_origin, gClimbersPos[i] );
				
				Splash( i );
			}
			
			get_user_name( i, gClimber[i], 32 );
			gClimbers++;
		}
	}
	
	gCupStatus = CUP_FINISHED;
	
	server_cmd( "sv_restart 1" );
	server_cmd( "xj_checkpoints 1" );
	
	new szAdminName[32];
	get_user_name( id, szAdminName, 31 );
	ColorChat(0, RED, "%s^x01 Admin^x04 %s^x01 forced to finish Jump Cup.", PREFIX, szAdminName );
}

public fnFinishCup() {
	new iEntityTimer = -1;
	while( ( iEntityTimer = engfunc(EngFunc_FindEntityByString, iEntityTimer, "classname", "xpaw_cup_timer" ) ) )
		engfunc( EngFunc_RemoveEntity, iEntityTimer ); 
	
	for( new i = 1; i < gMaxPlayers; i++ ) {
		if( gUserConnected[ i ] && !gUserIsBOT[ i ] ) {
			if( gUserIsAlive[i] ) {
				pev( i, pev_origin, gClimbersPos[i] );
				
				Splash( i );
			}
			
			get_user_name( i, gClimber[i], 32 );
			gClimbers++;
		}
	}
	
	gCupStatus = CUP_FINISHED;
	
	server_cmd( "sv_restart 1" );
	server_cmd( "xj_checkpoints 1" );
	
	ColorChat(0, RED, "%s^x04 Jump Cup has ended.^x01 Say^x03 /poscheck^x01 to check the finish positions.", PREFIX );
}

// TIME STUFF
/////////////////////////////////////////////
public fnShowTimeRemining( iTime, iType ) {
	if( iTime < 0 )
		return PLUGIN_CONTINUE;
	
	new szMessage[128], iSeconds = iTime % 60, iMinutes = iTime / 60;
	
	if( iTime < 11 ) {
		set_hudmessage(128, 128, 128, -1.0, 0.9, 0, 0.0, 1.1, 0.1, 0.5, 1);
		
		if( iType )
			ShowSyncHudMsg( 0, gHudSync, "The round will start in %d seconds.", iSeconds );
		else
			ShowSyncHudMsg( 0, gHudSync, "The round will end in %d seconds.", iSeconds );
		
		new iSecondsString[32];
		num_to_word( iSeconds, iSecondsString, 31 );
		
		format( szMessage, 127, "%s", iSecondsString );
	} else {
		set_hudmessage( 128, 128, 128, -1.0, 0.9, 0, 0.0, 2.0, 0.5, 0.5, 2 );
		
		if( iMinutes != 0 && iSeconds != 0 )
			ShowSyncHudMsg( 0, gHudSync, "%d minutes %d seconds remaining", iMinutes, iSeconds );
		else if( iMinutes!= 0 && iSeconds == 0 )
			ShowSyncHudMsg( 0, gHudSync, "%d minutes remaining", iMinutes );
		else if( iMinutes == 0 && iSeconds != 0 )
			ShowSyncHudMsg( 0, gHudSync, "%d seconds remaining", iSeconds );
		
		new iSecondsString[32];
		num_to_word( iSeconds, iSecondsString, 31 );
		
		if( iMinutes != 0 ) {
			new iMinutesString[32];
			num_to_word( iMinutes, iMinutesString, 31 );
			
			if( iSeconds != 0 )
				format( szMessage, 127, "%sminutes %sseconds remaining", iMinutesString, iSecondsString );
			else
				format( szMessage, 127, "%sminutes remaining", iMinutesString);
		} else
			format( szMessage, 127, "%sseconds remaining", iSecondsString );
	}
	
	client_cmd( 0, "spk ^"SoUlFaThEr/%s^" ", szMessage );
	
	return PLUGIN_CONTINUE;
	
}

// COMMANDS
//////////////////////////////////////////////////
public cmdMarkersSet( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL ) {
		new Float:vOrigin[ 3 ];
		GetPlayerOrigin( id, vOrigin );
		
		gMarkerEnt[ gMarkersCount ] = CreateMarker( vOrigin );
		gflMarkerPos[ gMarkersCount ] = vOrigin;
		gMarkersCount++;
		
		ColorChat( id, RED, "%s^x01 Set cup marker (^x04%f %f %f^x01).", PREFIX, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
	}
	
	return PLUGIN_HANDLED;
}

public cmdMarkersRemove( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL ) {
		new iOldMarker = gMarkersCount - 1;
		
		if( iOldMarker >= 0 ) {
			if( pev_valid( gMarkerEnt[ iOldMarker ] ) )
				remove_entity( gMarkerEnt[ iOldMarker ] );
			
			--gMarkersCount;
			
			ColorChat( id, RED, "%s^x01 Removed cup marker^x04 #%i^x01 (^x04%f %f %f^x01).", PREFIX, iOldMarker + 1, gflMarkerPos[ iOldMarker ][ 0 ], gflMarkerPos[ iOldMarker ][ 1 ], gflMarkerPos[ iOldMarker ][ 2 ] );
		} else
			ColorChat( id, RED, "%s^x01 There are no cup markers.", PREFIX );
	}
	
	return PLUGIN_HANDLED;
}

public cmdMarkersNearest( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL ) {
		new iMarker = GetNearestMarker( id );
		
		if( iMarker > 0 )
			ColorChat( id, RED, "%s^x01 Nearest marker:^x04 %i^x01.", PREFIX, iMarker );
		else
			ColorChat( id, RED, "%s^x01 There are no cup markers.", PREFIX );
	}
	
	return PLUGIN_HANDLED;
}

// GET PLAYERS ORIGIN TO FLOOR
//////////////////////////////////////////////////
GetPlayerOrigin( id, Float:vOrigin[ 3 ] ) {
	pev( id, pev_origin, vOrigin );
	
	vOrigin[ 2 ] -= 30;
	
	if( pev( id, pev_flags ) & FL_DUCKING )
		vOrigin[ 2 ] += 18;
}

// GET NEAREST MARKER TO PLAYER
//////////////////////////////////////////////////
GetNearestMarker( id ) {
	static iNum;
	iNum = 0;
	
	if( gMarkersCount > 0 ) {
		static Float:vOrigin[ 3 ], Float:flDistance, Float:flNearest, i;
		pev( id, pev_origin, vOrigin );
		
		flDistance = 0.0;
		flNearest = vector_distance( vOrigin, gflMarkerPos[ 0 ] );
		iNum = 1;
		
		for( i = 0; i < gMarkersCount; i++ ) {
			flDistance = vector_distance( vOrigin, gflMarkerPos[ i ] );
			
			if( flDistance < flNearest ) {
				flNearest = flDistance;
				iNum = i + 1;
			}
		}
	}
	
	return iNum;
}

GetNearestMarkerByOrigin( Float:vOrigin[ 3 ] ) {
	static iNum;
	iNum = 0;
	
	if( gMarkersCount > 0 ) {
		static Float:flDistance, Float:flNearest, i;
		
		flDistance = 0.0;
		flNearest = vector_distance( vOrigin, gflMarkerPos[ 0 ] );
		iNum = 1;
		
		for( i = 0; i < gMarkersCount; i++ ) {
			flDistance = vector_distance( vOrigin, gflMarkerPos[ i ] );
			
			if( flDistance < flNearest ) {
				flNearest = flDistance;
				iNum = i + 1;
			}
		}
	}
	
	return iNum;
}

// SHOW / HIDE MARKERS
//////////////////////////////////////////////////
ShowMarkers( ) {
	if( !gbMarkersVisible ) {
		for( new i = 0; i < gMarkersCount; i++ )
			gMarkerEnt[ i ] = CreateMarker( gflMarkerPos[ i ] );
	
		gbMarkersVisible = true;
	}
}

HideMarkers( ) {
	new iEntity = FM_NULLENT;
	
	while( ( iEntity = find_ent_by_class( iEntity, "xpaw_cup_marker" ) ) )
		remove_entity( iEntity );
	
	gbMarkersVisible = false;
}

// CREATE FAKE MARKER
//////////////////////////////////////////////////
CreateMarker( Float:vOrigin[ 3 ] ) {
	new iEntity = create_entity( "info_target" );
	
	if( !pev_valid( iEntity ) )
		return 0;
	
	set_pev( iEntity, pev_classname, "xpaw_cup_marker" );
	entity_set_model( iEntity, MARKER_MODEL );
	entity_set_origin( iEntity, vOrigin );
	set_pev( iEntity, pev_angles, { 90.0, 0.0, 0.0 } );
	
	return iEntity;
}

// LOAD MARKERS
//////////////////////////////////////////////////
LoadMarkers( id = 0 ) {
	gMarkersCount = 0;
	
	if( file_exists( gszMarkersFile ) ) {
		new iLenght, iLineNum, szX[ 12 ], szY[ 12 ], szZ[ 12 ], szData[ 128 ], iSize = charsmax( szX );
		
		do {
			iLineNum = read_file( gszMarkersFile, iLineNum, szData, charsmax( szData ), iLenght );
			parse( szData, szX, iSize, szY, iSize, szZ, iSize );
			
			gflMarkerPos[ gMarkersCount ][ 0 ] = str_to_float( szX );
			gflMarkerPos[ gMarkersCount ][ 1 ] = str_to_float( szY );
			gflMarkerPos[ gMarkersCount ][ 2 ] = str_to_float( szZ );
			
			gMarkersCount++;
		} while( iLineNum > 0 );
		
		if( id > 0 )
			ColorChat( id, RED, "%s^x01 Loaded^x04 %i^x01 cup markers.", PREFIX, gMarkersCount );
	} else {
		if( id > 0 )
			ColorChat( id, RED, "%s^x04 %s^x01 does not exist.", PREFIX, gszMarkersFile );
	}
}

// SAVE MARKERS
//////////////////////////////////////////////////
SaveMarkers( id ) {
	if( file_exists( gszMarkersFile ) )
		delete_file( gszMarkersFile );
	
	new szLine[ 128 ];
	for( new i = 0; i < gMarkersCount; i++ ) {
		format( szLine, charsmax( szLine ), "%f %f %f", gflMarkerPos[ i ][ 0 ], gflMarkerPos[ i ][ 1 ], gflMarkerPos[ i ][ 2 ] );
		write_file( gszMarkersFile, szLine );
	}
	
	ColorChat( id, RED, "%s^x01 Saved^x04 %i^x01 cup markers.", PREFIX, gMarkersCount );
}

// OTHER STUFF
/////////////////////////////////////////////
ForceDuck( id ) {
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING );
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  18.0 } );
}

Splash( id ) {
	if( gUserConnected[ id ] ) {
		new Float:vOrigin[3];
		pev( id, pev_origin, vOrigin );
		
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_TELEPORT );
		engfunc( EngFunc_WriteCoord, vOrigin[0] );
		engfunc( EngFunc_WriteCoord, vOrigin[1] );
		engfunc( EngFunc_WriteCoord, vOrigin[2] );
		message_end( );
	}
}

// ALIVE SHIT
/////////////////////////////////////////////
public client_putinserver( id ) {
	gUserConnected[ id ] = true;
	gUserIsAlive[ id ] = false;
	gUserIsBOT[ id ] = bool:( is_user_bot( id ) );
}

public client_disconnect( id ) {
	gUserConnected[ id ] = false;
	gUserIsAlive[ id ] = false;
	gUserIsBOT[ id ] = false;
}

public Event_Health( id ) gUserIsAlive[ id ] = is_user_alive( id );