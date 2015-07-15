#include < amxmodx >
#include < fun >
#include < cstrike >
#include < nvault >
#include < hamsandwich >

#define SetPlayerBits(%1,%2)    ( %1 |=    1 << ( %2 & 31 ) )
#define ClearPlayerBits(%1,%2)  ( %1 &= ~( 1 << ( %2 & 31 ) ) )
#define GetPlayerBits(%1,%2)    ( %1 &     1 << ( %2 & 31 ) )

new g_iFrags[ 33 ], g_iDeaths[ 33 ], g_szAuthId[ 33 ][ 40 ];
new g_iVault, g_iMsgScoreInfo, g_bConnected, g_bLoaded;

public plugin_init( ) {
	register_plugin( "Score Saver", "2.0", "xPaw" );
	
	register_event( "ScoreInfo", "EventScoreInfo", "a" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	
	g_iMsgScoreInfo = get_user_msgid( "ScoreInfo" );
	g_iVault        = nvault_open( "headcrab_scores" );
}

public plugin_end( )
	nvault_close( g_iVault );

public client_putinserver( id )
	if( !is_user_bot( id ) )
		SetPlayerBits( g_bConnected, id );

public client_authorized( id ) {
	if( !GetPlayerBits( g_bLoaded, id ) ) {
		SetPlayerBits( g_bLoaded, id );
		
		get_user_authid( id, g_szAuthId[ id ], 39 );
		
		new szData[ 16 ], szFrags[ 6 ], szDeaths[ 6 ];
		nvault_get( g_iVault, g_szAuthId[ id ], szData, 15 );
		parse( szData, szFrags, 5, szDeaths, 5 );
		
		g_iFrags[ id ]  = str_to_num( szFrags );
		g_iDeaths[ id ] = str_to_num( szDeaths );
		
		log_amx( "Loaded (%i frags - %i deaths) for %s", g_iFrags[ id ], g_iDeaths[ id ], g_szAuthId[ id ] );
	}
}

public client_disconnect( id ) {
	if( GetPlayerBits( g_bConnected, id ) && GetPlayerBits( g_bLoaded, id ) ) {
		new szData[ 16 ];
		formatex( szData, 15, "^"%i^" ^"%i^"", g_iFrags[ id ], g_iDeaths[ id ] );
		
		nvault_set( g_iVault, g_szAuthId[ id ], szData );
	}
	
	g_szAuthId[ id ][ 0 ] = 0;
	g_iDeaths[ id ]       = 0;
	g_iFrags[ id ]        = 0;
	
	ClearPlayerBits( g_bConnected, id );
	ClearPlayerBits( g_bLoaded, id );
	
	return PLUGIN_CONTINUE;
}

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) && GetPlayerBits( g_bConnected, id ) && GetPlayerBits( g_bLoaded, id ) ) {
		set_user_frags( id, g_iFrags[ id ] );
		cs_set_user_deaths( id, g_iDeaths[ id ] );
		
		UTIL_UpdateScoreBoard( id );
	}
}

public EventScoreInfo( ) {
	new id = read_data( 1 );
	
	if( !GetPlayerBits( g_bConnected, id ) )
		return;
	
	new iFrags = read_data( 2 ), iDeaths = read_data( 3 );
	
	if( !iFrags && g_iFrags[ id ] )
		set_user_frags( id, g_iFrags[ id ] );
	
	if( !iDeaths && g_iDeaths[ id ] )
		cs_set_user_deaths( id, g_iDeaths[ id ] );
	
	if( ( !iFrags && g_iFrags[ id ] ) || ( !iDeaths && g_iDeaths[ id ] ) )
		return;
	
	g_iFrags[ id ] = iFrags;
	g_iDeaths[ id ] = iDeaths;
}

UTIL_UpdateScoreBoard( const id ) {
	message_begin( MSG_BROADCAST, g_iMsgScoreInfo );
	write_byte( id );
	write_short( get_user_frags( id ) );
	write_short( get_user_deaths( id ) );
	write_short( 0 );
	write_short( get_user_team( id ) );
	message_end( );
}
