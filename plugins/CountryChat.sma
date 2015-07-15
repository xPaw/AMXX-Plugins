#include < amxmodx >
#include < cstrike >
#include < geoip >
#include < fakemeta >

forward vip_connected( const id );

#define ANTI_FLOOD    // Uncomment this if you want enable ANTI_FLOOD system
#define COLORED_RADIO // Uncomment this if you want radio messages to be colored
#define ADMIN_SEE_ALL // Uncomment this if you want admins to see all team-chats

new const g_szTeams[ 3 ][ ] = {
	"Spectator",
	"Terrorist",
	"Counter-Terrorist"
};

new g_szCountryCode[ 33 ][ 11 ];
new bool:g_bAdmin[ 33 ];
new g_iMsgSayText;

#if defined ANTI_FLOOD
	new Float:g_flLastMsg[ 33 ];
	new Float:g_flFlooding[ 33 ];
	new g_iFloodCount[ 33 ];
#endif

public plugin_init( ) {
	register_plugin( "Country Chat", "1.1", "xPaw" );
	
#if defined ANTI_FLOOD
	register_dictionary( "antiflood.txt" );
#endif
	
#if defined COLORED_RADIO
	register_message( get_user_msgid( "TextMsg" ), "MessageTextMsg" );
#endif
	
	register_clcmd( "say",		"CmdSay" );
	register_clcmd( "say_team",	"CmdTeamSay" );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
}

public client_authorized( id )
	g_bAdmin[ id ] = bool:( get_user_flags( id ) & ADMIN_RCON );

public client_disconnect( id )
	g_bAdmin[ id ] = false;

public vip_connected( const id )
	add( g_szCountryCode[ id ], 10, "^4[VIP]" );
	
public client_putinserver( id ) {
	new szIP[ 16 ], szCode[ 3 ];
	get_user_ip( id, szIP, 15, 1 );
	
	if( szIP[ 0 ] == 'l' )
		get_user_ip( 0, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) ) {
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	formatex( g_szCountryCode[ id ], 10, "[%s]", szCode );
	
#if defined ANTI_FLOOD
	g_iFloodCount[ id ] = 0;
#endif
}

public CmdSay( id ) {
#if defined ANTI_FLOOD
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
#endif
	
	new szSaid[ 192 ];
	read_args( szSaid, 191 );
	remove_quotes( szSaid );
	
	new i, x, iTeam = strlen( szSaid );
	
	if( !iTeam ) return PLUGIN_HANDLED;
	
	for( i = 0; i < iTeam; i++ ) {
		if( szSaid[ i ] != ' ' ) {
			x = 1;
			break;
		}
	}
	
	if( !x ) return PLUGIN_HANDLED;
	
	new szName[ 32 ], szMessage[ 191 ];
	
	for( i = 0; i < iTeam; i++ )
		for( x = '^1'; x <= '^4'; x++ )
			if( szSaid[ i ] == x )
				szSaid[ i ] = ' ';
	
	replace_all( szSaid, 190, "%s", " s" );
	
	get_user_name( id, szName, 31 );
	
	new szTeam[ 2 ];
	get_user_team( id, szTeam, 1 );
	switch( szTeam[ 0 ] ) {
		case 'T': iTeam = 1;
		case 'C': iTeam = 2;
		default: iTeam = 0;
	}
	
	new szTag[ 8 ];
	
	if( !iTeam )
		szTag = "*SPEC* ";
	else if( !is_user_alive( id ) )
		szTag = "*DEAD* ";
	
	formatex( szMessage, 190, "^3%s^1 %s^3%s^1:%s %s", g_szCountryCode[ id ], szTag, szName, g_bAdmin[ id ] ? "^4" : "", szSaid );
	szMessage[ 189 ] = '^0';
	
	SendMessage( MSG_BROADCAST, id, 0, szMessage );
	
	// Logs
	get_user_authid( id, szMessage, 40 );
	log_message( "^"%s<0><%s><%c>^" say ^"%s^"", szName, szMessage, szTeam[ 0 ], szSaid );
	
	return PLUGIN_HANDLED;
}

public CmdTeamSay( id ) {
#if defined ANTI_FLOOD
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
#endif
	
	new szSaid[ 192 ];
	read_args( szSaid, 191 );
	remove_quotes( szSaid );
	
	new i, x, iTeam = strlen( szSaid );
	
	if( !iTeam ) return PLUGIN_HANDLED;
	
	for( i = 0; i < iTeam; i++ ) {
		if( szSaid[ i ] != ' ' ) {
			x = 1;
			break;
		}
	}
	
	if( !x ) return PLUGIN_HANDLED;
	
	new szName[ 32 ], szMessage[ 191 ];
	
	for( i = 0; i < iTeam; i++ )
		for( x = '^1'; x <= '^4'; x++ )
			if( szSaid[ i ] == x )
				szSaid[ i ] = ' ';
	
	replace_all( szSaid, 190, "%s", " s" );
	
	new iPlayer, iPlayers[ 32 ], iNum;
	get_user_name( id, szName, 31 );
	get_players( iPlayers, iNum, "ch" );
	
	new szTeam[ 2 ];
	get_user_team( id, szTeam, 1 );
	switch( szTeam[ 0 ] ) {
		case 'T': iTeam = 1;
		case 'C': iTeam = 2;
		default: iTeam = 0;
	}
	
	formatex( szMessage, 190, "^3%s^1 %s(%s)^3 %s^1:%s %s", g_szCountryCode[ id ], ( iTeam && !is_user_alive( id ) ) ? "*DEAD* " : "", g_szTeams[ iTeam ], szName, g_bAdmin[ id ] ? "^4" : "", szSaid );
	szMessage[ 189 ] = '^0';
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
#if defined ADMIN_SEE_ALL
		if( get_user_team( iPlayer ) == iTeam || g_bAdmin[ iPlayer ] )
#else
		if( get_user_team( iPlayer ) == iTeam )
#endif
			SendMessage( MSG_ONE_UNRELIABLE, id, iPlayer, szMessage );
	}
	
	// Logs
	get_user_authid( id, szMessage, 40 );
	log_message( "^"%s<0><%s><%c>^" say_team ^"%s^"", szName, szMessage, szTeam[ 0 ], szSaid );
	
	return PLUGIN_HANDLED;
}

#if defined ANTI_FLOOD
	public CheckFlood( id ) {
		new Float:flGametime = get_gametime( );
		
		if( g_flLastMsg[ id ] + 0.25 > flGametime )
			return true;
		
		g_flLastMsg[ id ] = flGametime;
		
		if( g_flFlooding[ id ] > flGametime ) {
			if( g_iFloodCount[ id ] >= 3 ) {
				client_print( id, print_notify, "** %L **", id, "STOP_FLOOD" );
				client_print( id, print_center, "** %L **", id, "STOP_FLOOD" );
				
				g_flFlooding[ id ] = flGametime + 3.75;
				
				return true;
			}
			
			g_iFloodCount[ id ]++;
		}
		else if( g_iFloodCount[ id ] )
			g_iFloodCount[ id ]--;
		
		g_flFlooding[ id ] = flGametime + 0.75;
		
		return false;
	}
#endif

#if defined COLORED_RADIO
	public MessageTextMsg( ) {
		if( get_msg_args( ) != 5 || get_msg_arg_int( 1 ) != 5 )
			return PLUGIN_CONTINUE;
		
		static szMessage[ 33 ];
		get_msg_arg_string( 3, szMessage, 32 );
		
		if( equal( szMessage, "#Game_radio" ) ) {
			get_msg_arg_string( 5, szMessage, 32 );
			
			if( equal( szMessage, "#Fire_in_the_hole" ) ) {
				get_msg_arg_string( 2, szMessage, 3 );
				
				switch( get_user_weapon( str_to_num( szMessage ) ) ) {
					case CSW_HEGRENADE:    szMessage = "%s1 (RADIO): %s2 [explosive]";
					case CSW_SMOKEGRENADE: szMessage = "%s1 (RADIO): %s2 [smokegren]";
					case CSW_FLASHBANG:    szMessage = "%s1 (RADIO): %s2 [flashbang]";
					default:               szMessage = "%s1 (RADIO): %s2";
				}
			} else
				szMessage = "%s1 (RADIO): %s2";
			
			set_msg_arg_string( 3, szMessage );
		}
		
		return PLUGIN_CONTINUE;
	}
#endif

SendMessage( const iType, const iSender, const id, const szMessage[ ] ) {
	message_begin( iType, g_iMsgSayText, _, id );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
}