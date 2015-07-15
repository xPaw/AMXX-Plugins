#include < amxmodx >
#include < engine >
#include < cstrike >
#include < chatcolor >

#define RED   0 // Use random( 256 ) for random color
#define GREEN 127
#define BLUE  255

new g_szName[ 33 ][ 26 ];
new bool:g_bToggle[ 33 ];

public plugin_init( ) {
	register_plugin( "Speclist", "1.5", "xPaw" );
	
	register_clcmd( "say /speclist", "CmdSpecList" );
	
	new iEntity = create_entity( "info_target" );
	
	if( !is_valid_ent( iEntity ) )
		return;
	
	entity_set_string( iEntity, EV_SZ_classname, "xpaw_speclist" );
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 4.0 );
	
	register_think( "xpaw_speclist", "FwdThinkSpecList" );
}

public CmdSpecList( id ) {
	if( g_bToggle[ id ] ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You will no longer see who's spectating you." );
		
		g_bToggle[ id ] = false;
	} else {
		ColorChat( id, Red, "[ mY.RuN ]^1 You will now see who's spectating you." );
		
		g_bToggle[ id ] = true;
	}
}

public FwdThinkSpecList( iEntity ) {
	static szHud[ 1102 ], szName[ 32 ], bool:bSendTo[ 33 ], bool:bSend;
	static iPlayers[ 32 ], iNum, iDead, id, i, i2;
	
	get_players( iPlayers, iNum, "ch" );
	
	for( i = 0; i < iNum; i++ ) {
		arrayset( bSendTo, false, 33 );
		
		id = iPlayers[ i ];
		
		if( !is_user_alive( id ) )
			continue;
		
		bSend = false;
		if( g_bToggle[ id ] ) bSendTo[ id ] = true;
		
		formatex( szHud, 250, "Spectating %s:^nHP: %i%s | Money: %i$^n^n", g_szName[ id ], get_user_health( id ), "%%", cs_get_user_money( id ) );
		
		for( i2 = 0; i2 < iNum; i2++ ) {
			iDead = iPlayers[ i2 ];
			
			if( is_user_alive( iDead ) )
				continue;
			
			if( entity_get_int( iDead, EV_INT_iuser2 ) == id ) {
				formatex( szName, 31, "%s^n", g_szName[ iDead ] );
				add( szHud, 1101, szName, 0 );
				
				if( g_bToggle[ iDead ] ) bSendTo[ iDead ] = true;
				if( !bSend ) bSend = true;
			}
		}
		
		if( bSend ) {
			for( i2 = 0; i2 < iNum; i2++ ) {
				id = iPlayers[ i2 ];
				
				if( bSendTo[ id ] ) {
					set_hudmessage( 0, 127, 255, 0.75, 0.15, 0, 0.0, 1.1, 0.0, 0.0, 4 );
					show_hudmessage( id, szHud );
				}
			}
		}
	}
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	
	return PLUGIN_CONTINUE;
}

public client_infochanged( id )
	get_user_info( id, "name", g_szName[ id ], 25 );

public client_putinserver( id )
	g_bToggle[ id ] = true;
