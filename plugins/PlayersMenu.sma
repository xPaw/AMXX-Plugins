#include < amxmodx >
#include < fakemeta >
#include < geoip >

new Float:g_flMSec[ 33 ];
new g_szCountyCode[ 33 ][ 5 ];

public plugin_init( ) {
	register_plugin( "Players menu", "1.0", "xPaw" );
	
	register_clcmd( "say /fps", "CmdMenu" );
	register_clcmd( "say /country", "CmdMenu" );
	
	register_forward( FM_CmdStart, "FwdCmdStart" );
}

public client_putinserver( id ) {
	new szIP[ 16 ], szCode[ 3 ];
	get_user_ip( id, szIP, 15, 1 );
	
	if( equal( szIP, "loopback" ) )
		get_user_ip( 0, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) ) {
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	g_szCountyCode[ id ][ 0 ] = '[';
	g_szCountyCode[ id ][ 1 ] = szCode[ 0 ];
	g_szCountyCode[ id ][ 2 ] = szCode[ 1 ];
	g_szCountyCode[ id ][ 3 ] = ']';
}

public FwdCmdStart( id, iHandle )
	g_flMSec[ id ] = get_uc( iHandle, UC_Msec );
//	g_iFps[ id ] = floatround( 1 / ( get_uc( iHandle, UC_Msec ) * 0.001 ) );

public CmdMenu( id ) {
	ShowMenu( id );
	set_task( 0.2, "ShowMenu", id, _, _, "b" );
	
	return PLUGIN_CONTINUE;
}

public ShowMenu( id ) {
	new iMenu = menu_create( "\yPlayers\r\RFPS", "HandlePlayersMenu" );
	
	new szName[ 32 ], iPlayers[ 32 ], szSubj[ 64 ], iNum, iTarget;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iTarget = iPlayers[ i ];
		
		get_user_name( iTarget, szName, 31 );
		
		formatex( szSubj, 63, "\y%s \w%s\r\R%i", g_szCountyCode[ iTarget ], szName, floatround( 1 / ( g_flMSec[ iTarget ] * 0.001 ) ) );
		
		menu_additem( iMenu, szSubj, "Hi", 0 );
	}
	
	menu_display( id, iMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public HandlePlayersMenu( id, iMenu, iItem ) {
	if( iItem == MENU_EXIT )
		remove_task( id );
	else
		ShowMenu( id );
	
	menu_destroy( iMenu );
	
	return PLUGIN_HANDLED;
}
