#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < colorchat >

#pragma semicolon 1

#define PREFIX        "[XJ]"
#define MARKER_MODEL  "models/can.mdl"
#define ADMIN_LEVEL	  ADMIN_RESERVATION
#define MAX_MARKERS   1000

#define MARKER_KEYS	(1<<0) | (1<<1) | (1<<2) | (1<<3) | (1<<4) | (1<<5) | (1<<6) | (1<<7) | (1<<8) | (1<<9)

new g_iHudSync;
new g_iMarkersCount;
new g_iMarkerEnt[ MAX_MARKERS ];

new g_bIsAlive[ 33 ];
new g_szMarkersFile[ 64 ];
new g_szMarkersMenu[ 256 ];
new bool:g_bMarkersVisible;

new Float:g_flLastThink[ 33 ];
new Float:g_flMarkerPos[ MAX_MARKERS ][ 3 ];

public plugin_init( ) {
	register_plugin( "KZ Map Status", "1.0", "xPaw" );
	
	register_forward( FM_PlayerPreThink, "FwdPlayerPreThink" );
	
	// Events
	register_event( "ResetHUD", "Event_Health", "b" );
	register_event( "Health", "Event_Health", "b" );
	
	// Commands
	register_clcmd( "say /markers", "cmdMarkersMenu" );
	register_clcmd( "say /locs", "cmdMarkersMenu" );
	
	// Console commands
	register_concmd( "cup_setmarker", "cmdMarkersSet", ADMIN_LEVEL, "Create cup marker" );
	
	// Menus
	register_menucmd( register_menuid( "MarkersMenu" ), MARKER_KEYS, "handleMarkersMenu" );
	
	g_iHudSync	= CreateHudSyncObj( );
}

public plugin_precache( )
	precache_model( MARKER_MODEL );

public plugin_cfg( ) {
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r#kz.xPaw \wCup Markers Menu^n^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r1. \wSet a marker^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r2. \wDelete last cup marker^n^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r3. \wHide cup markers^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r4. \wShow cup markers^n^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r5. \wLoad cup markers^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r6. \wSave cup markers^n^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r9. \wShow nearest cup marker^n" );
	add( g_szMarkersMenu, charsmax( g_szMarkersMenu ), "\r0. \wExit" );
	
	new szDataDir[ 48 ], szMapname[ 32 ];
	get_localinfo( "amxx_datadir", szDataDir, charsmax( szDataDir ) );
	get_mapname( szMapname, charsmax( szMapname ) );
	
	format( g_szMarkersFile, charsmax( g_szMarkersFile ), "%s/kreedz/cup/%s.txt", szDataDir, szMapname );
	
	LoadMarkers( );
}

// THINK FORWARDS
/////////////////////////////////////////////
public FwdPlayerPreThink( id ) {
	if( g_bIsAlive[ id ] ) {
		static Float:flGameTime;
		flGameTime = get_gametime( );
		
		if( g_flLastThink[ id ] < flGameTime ) {
			new Float:iPercent, iMarker = GetNearestMarker( id );
			
			if( iMarker > 0 )
				iPercent = ( float( iMarker ) / float( g_iMarkersCount ) * 100.0 );
			
			set_hudmessage( 255, 100, 0, -1.0, 0.15, 0, 0.0, 1.1, 0.0, 0.0, 3 );
			ShowSyncHudMsg( id, g_iHudSync, "Map status: %i%s", floatround( iPercent ), "%%" );
			
			g_flLastThink[ id ] = flGameTime + 1.0;
		}
	}
}

// COMMANDS
/////////////////////////////////////////////
public cmdMarkersMenu( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL )
		show_menu( id, MARKER_KEYS, g_szMarkersMenu, -1, "MarkersMenu" );
	
	return PLUGIN_HANDLED;
}

// MENU HANDLES
/////////////////////////////////////////////
public handleMarkersMenu( id, iKey ) {
	switch( iKey ) {
		case 0: { cmdMarkersSet( id ); }
		case 1: { cmdMarkersRemove( id ); }
		case 2: { HideMarkers( ); }
		case 3: { ShowMarkers( ); }
		case 4: { LoadMarkers( id ); }
		case 5: { SaveMarkers( id ); }
		
		case 8: { cmdMarkersNearest( id ); }
		case 9: { return; }
	}
	
	cmdMarkersMenu( id );
}

// COMMANDS
//////////////////////////////////////////////////
public cmdMarkersSet( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL ) {
		new Float:vOrigin[ 3 ];
		GetPlayerOrigin( id, vOrigin );
		
		g_iMarkerEnt[ g_iMarkersCount ] = CreateMarker( vOrigin );
		g_flMarkerPos[ g_iMarkersCount ] = vOrigin;
		g_iMarkersCount++;
		
		ColorChat( id, RED, "%s^x01 Set cup marker (^x04%f %f %f^x01).", PREFIX, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
	}
	
	return PLUGIN_HANDLED;
}

public cmdMarkersRemove( id ) {
	if( get_user_flags( id ) & ADMIN_LEVEL ) {
		new iOldMarker = g_iMarkersCount - 1;
		
		if( iOldMarker >= 0 ) {
			if( pev_valid( g_iMarkerEnt[ iOldMarker ] ) )
				remove_entity( g_iMarkerEnt[ iOldMarker ] );
			
			--g_iMarkersCount;
			
			ColorChat( id, RED, "%s^x01 Removed cup marker^x04 #%i^x01 (^x04%f %f %f^x01).", PREFIX, iOldMarker + 1, g_flMarkerPos[ iOldMarker ][ 0 ], g_flMarkerPos[ iOldMarker ][ 1 ], g_flMarkerPos[ iOldMarker ][ 2 ] );
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
	static iNum; iNum = 0;
	
	if( g_iMarkersCount > 0 ) {
		static Float:vOrigin[ 3 ], Float:flDistance, Float:flNearest, i;
		pev( id, pev_origin, vOrigin );
		
		flDistance = 0.0;
		flNearest = vector_distance( vOrigin, g_flMarkerPos[ 0 ] );
		iNum = 1;
		
		for( i = 0; i < g_iMarkersCount; i++ ) {
			flDistance = vector_distance( vOrigin, g_flMarkerPos[ i ] );
			
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
	if( !g_bMarkersVisible ) {
		for( new i = 0; i < g_iMarkersCount; i++ )
			g_iMarkerEnt[ i ] = CreateMarker( g_flMarkerPos[ i ] );
	
		g_bMarkersVisible = true;
	}
}

HideMarkers( ) {
	new iEntity = FM_NULLENT;
	
	while( ( iEntity = find_ent_by_class( iEntity, "xpaw_cup_marker" ) ) )
		remove_entity( iEntity );
	
	g_bMarkersVisible = false;
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
	g_iMarkersCount = 0;
	
	if( file_exists( g_szMarkersFile ) ) {
		new iLenght, iLineNum, szX[ 12 ], szY[ 12 ], szZ[ 12 ], szData[ 128 ], iSize = charsmax( szX );
		
		do {
			iLineNum = read_file( g_szMarkersFile, iLineNum, szData, charsmax( szData ), iLenght );
			parse( szData, szX, iSize, szY, iSize, szZ, iSize );
			
			g_flMarkerPos[ g_iMarkersCount ][ 0 ] = str_to_float( szX );
			g_flMarkerPos[ g_iMarkersCount ][ 1 ] = str_to_float( szY );
			g_flMarkerPos[ g_iMarkersCount ][ 2 ] = str_to_float( szZ );
			
			g_iMarkersCount++;
		} while( iLineNum > 0 );
		
		if( id > 0 )
			ColorChat( id, RED, "%s^x01 Loaded^x04 %i^x01 cup markers.", PREFIX, g_iMarkersCount );
	} else {
		if( id > 0 )
			ColorChat( id, RED, "%s^x04 %s^x01 does not exist.", PREFIX, g_szMarkersFile );
	}
}

// SAVE MARKERS
//////////////////////////////////////////////////
SaveMarkers( id ) {
	if( file_exists( g_szMarkersFile ) )
		delete_file( g_szMarkersFile );
	
	new szLine[ 128 ];
	for( new i = 0; i < g_iMarkersCount; i++ ) {
		format( szLine, charsmax( szLine ), "%f %f %f", g_flMarkerPos[ i ][ 0 ], g_flMarkerPos[ i ][ 1 ], g_flMarkerPos[ i ][ 2 ] );
		write_file( g_szMarkersFile, szLine );
	}
	
	ColorChat( id, RED, "%s^x01 Saved^x04 %i^x01 cup markers.", PREFIX, g_iMarkersCount );
}

// ALIVE SHIT
/////////////////////////////////////////////
public client_putinserver( id ) g_bIsAlive[ id ] = false;
public client_disconnect( id ) g_bIsAlive[ id ] = false;
public Event_Health( id ) g_bIsAlive[ id ] = is_user_alive( id );
