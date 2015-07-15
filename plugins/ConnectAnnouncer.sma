#include < amxmodx >
#include < geoip >
#include < chatcolor >

#define IsUserAdmin(%1) ( get_user_flags( %1 ) & ADMIN_KICK )

public plugin_init( ) {
	register_plugin( "Connect Announcer", "1.0", "xPaw" );
	
	register_message( get_user_msgid( "TextMsg" ), "MessageTextMsg" );
}

public client_putinserver( id )
	ShowClientMessage( id, "has connected" );

public client_disconnect( id )
	ShowClientMessage( id, "has disconnected" );

public MessageTextMsg( const iMsgId, const iMsgDest, const id ) {
	new szMsg[ 17 ];
	get_msg_arg_string( 2, szMsg, 16 );
	
	if( equal( szMsg, "#Game_connected" ) ) {
		new szIP[ 16 ], szCountry[ 46 ];
		get_user_ip( id, szIP, 15, 1 );
	
		if( szIP[ 0 ] == 'l' ) // loopback
			get_user_ip( 0, szIP, 15, 1 );
		
		geoip_country( szIP, szCountry, 45 );
		
		if( szCountry[ 0 ] == 'e' && szCountry[ 1 ] == 'r' && szCountry[ 3 ] == 'o' )
			return;
		
		new szMsg[ 80 ];
		formatex( szMsg, 79, "%%s has connected from %s.^n", szCountry );
		
		set_msg_arg_string( 2, szMsg );
	}
}

ShowClientMessage( const id, const szAction[ ] ) {
	new szNick[ 32 ], szIP[ 16 ], szCode[ 3 ], szCountry[ 46 ];
	get_user_name( id, szNick, 31 );
	get_user_ip( id, szIP, 15, 1 );
	
	if( szIP[ 0 ] == 'l' ) // loopback
		get_user_ip( 0, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) ) {
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	geoip_country( szIP, szCountry, 45 );
	
	if( szCountry[ 0 ] == 'e' && szCountry[ 1 ] == 'r' && szCountry[ 3 ] == 'o' )
		szCountry = "Unknown Country";
	
	ColorChat( 0, Red, "[ mY.RuN ]^1 %s^4 %s^1 %s.^3 [ %s ]^4 %s^1.", IsUserAdmin( id ) ? "Admin" : "Player", szNick, szAction, szCode, szCountry );
}
