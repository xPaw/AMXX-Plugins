#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >

#define KICK_TIME     60
#define ANNOUNCE_TIME 45

#define SetAfkOnce(%1)   ( g_bWasAfkOnce |=    1 << ( %1 & 31 ) )
#define ClearAfkOnce(%1) ( g_bWasAfkOnce &= ~( 1 << ( %1 & 31 ) ) )
#define WasAfkOnce(%1)   ( g_bWasAfkOnce &     1 << ( %1 & 31 ) )

#define UpdateUserLastActivity(%1)	set_pdata_float( %1, 124, get_gametime( ), 5 )
// cs_set_user_lastactivity( %1, get_gametime( ) )
#define IsInTeam(%1)    ( CS_TEAM_T <= cs_get_user_team( %1 ) <= CS_TEAM_CT )
#define IsUserAdmin(%1) ( get_user_flags( %1 ) & ADMIN_KICK )

new Float:g_vAngles[ 33 ][ 3 ];
new g_iThinkingEnt, g_iHudSync, g_iIgnoreFirst, g_bWasAfkOnce;
new Trie:g_tAutoCmds;

public plugin_init( ) {
	register_plugin( "AFK", "1.0", "xPaw" );
	
	g_iHudSync = CreateHudSyncObj( );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	
	new szClassName[ 2 ];
	g_iThinkingEnt = get_maxplayers( ) + 1;
	
	while( pev_valid( g_iThinkingEnt ) && g_iThinkingEnt < 100 ) {
		pev( g_iThinkingEnt, pev_classname, szClassName, 1 );
		
		if( szClassName[ 0 ] == 0 )
			break;
		
		g_iThinkingEnt++;
	}
	
	RegisterHamFromEntity( Ham_Think, g_iThinkingEnt, "FwdThink", 1 );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	
	g_tAutoCmds = TrieCreate( );
	
	TrieSetCell( g_tAutoCmds, "vban", 1 );
	TrieSetCell( g_tAutoCmds, "specmode", 1 );
	TrieSetCell( g_tAutoCmds, "spec_set_ad", 1 );
	TrieSetCell( g_tAutoCmds, "VModEnable", 1 );
	TrieSetCell( g_tAutoCmds, "client_buy_close", 1 );
}

public plugin_end( )
	TrieDestroy( g_tAutoCmds );

public client_putinserver( id ) {
	UpdateUserLastActivity( id );
	ClearAfkOnce( id );
}

public client_command( id ) {
	new szCommand[ 13 ];
	read_argv( 0, szCommand, 12 );
	
	if( !TrieKeyExists( g_tAutoCmds, szCommand ) )
		UpdateUserLastActivity( id );
}

public EventNewRound( )
	g_iIgnoreFirst = 16; // ~5 seconds

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {
		pev( id, pev_v_angle, g_vAngles[ id ] );
		
		UpdateUserLastActivity( id );
	}
}

public FwdThink( const iEntity ) {
	if( iEntity != g_iThinkingEnt || g_iIgnoreFirst-- > 0 )
		return;
	
	static Float:flGametime, Float:flLastCheck; flGametime = get_gametime( );
	
	if( flLastCheck > flGametime )
		return;
	
	flLastCheck = flGametime + 1.0;
	
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ach" );
	
//	if( iNum < 6 )
//		return;
	
	static i, id, Float:flLastActivity, Float:vAngles[ 3 ];
	
	for( i = 0; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		if( !IsInTeam( id ) )
			continue;
		
		pev( id, pev_v_angle, vAngles );
		
		if( vAngles[ 0 ] != g_vAngles[ id ][ 0 ] || vAngles[ 1 ] != g_vAngles[ id ][ 1 ] ) {
			UpdateUserLastActivity( id );
			g_vAngles[ id ][ 0 ] = vAngles[ 0 ];
			g_vAngles[ id ][ 1 ] = vAngles[ 1 ];
			
			continue;
		}
		
		flLastActivity = ( flGametime - cs_get_user_lastactivity( id ) );
		
		if( flLastActivity >= KICK_TIME )
			PunishPlayer( id );
		else if( flLastActivity >= ANNOUNCE_TIME ) {
			set_hudmessage( 0, 100, 255, -1.0, 0.4, 0, 0.0, 1.0, 0.1, 0.1 );
			ShowSyncHudMsg( id, g_iHudSync, "You have %i seconds to move", floatround( KICK_TIME - flLastActivity ) );
		}
	}
}

PunishPlayer( const id ) {
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	if( !WasAfkOnce( g_bWasAfkOnce, id ) ) {
		SetAfkOnce( id );
		
		user_kill( id );
		
		set_hudmessage( 0, 100, 255, -1.0, 0.4, 0, 0.0, 3.5, 0.1, 0.4 );
		ShowSyncHudMsg( id, g_iHudSync, "You have been killed for being away from keyboard" );
		
		ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has been killed for being away from keyboard.", szName );
	} else {
		if( IsUserAdmin( id ) ) {
			user_kill( id );
			cs_set_user_team( id, CS_TEAM_SPECTATOR );
		} else {
			server_cmd( "kick #%i You has been kicked for being away from keyboard", get_user_userid( id ) );
			
			ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has been kicked from the server for being away from keyboard.", szName );
		}
	}
}
