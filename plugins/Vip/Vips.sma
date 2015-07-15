#include < amxmodx >
#include < hamsandwich >
#include < chatcolor >
#include < geoip >
#include < sqlx >
#include < time >

const Float:TASK_DELAY = 120.0;

enum _:Fwd {
	Fwd_Connect,
	Fwd_Removed
}

new Handle:g_hSqlTuple;
new bool:g_bConnected[ 33 ];
new bool:g_bVip[ 33 ];
new g_iExpireTime[ 33 ];
new g_iForward[ Fwd ];

public plugin_init( ) {
	register_plugin( "VIP Manager", "1.0", "xPaw" );
	
	register_dictionary( "time.txt" );
	
	g_hSqlTuple = SQL_MakeDbTuple( "localhost", "root", "root", "achievements" );
	
	register_clcmd( "say /vip",  "CmdVips" );
	register_clcmd( "say /vips", "CmdVips" );
	
	g_iForward[ Fwd_Connect ] = CreateMultiForward( "vip_connected", ET_IGNORE, FP_CELL );
	g_iForward[ Fwd_Removed ] = CreateMultiForward( "vip_removed", ET_IGNORE, FP_CELL );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", true );
	
	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" );
	
	register_clcmd( "say", "CmdSay" );
	
	set_task( TASK_DELAY - 30.0, "TaskShowMessage" );
}

public plugin_end( )
	SQL_FreeHandle( g_hSqlTuple );

public plugin_natives( ) {
	register_library( "Vip" );
	
	register_native( "IsUserVip", "NativeIsUserVip" );
}

public TaskShowMessage( ) {
	set_task( TASK_DELAY, "TaskShowMessage" );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "c" );
	
	if( !iNum ) return;
	
	new i, iPlayer;
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( g_bVip[ iPlayer ] ) continue;
		
		ColorChat( iPlayer, Red, "[ mY.RuN ]^4 Do you want to become^3 VIP^4? Check this page:^1 http://my-run.de/vip/" );
	}
}

public client_disconnect( id ) {
	g_bVip[ id ]        = false;
	g_bConnected[ id ]  = false;
	g_iExpireTime[ id ] = 0;
}

public client_putinserver( id ) {
	g_bConnected[ id ] = true;
	
	new szAuthId[ 40 ], szQuery[ 128 ], szId[ 1 ]; szId[ 0 ] = id;
	get_user_authid( id, szAuthId, 39 );
	
	formatex( szQuery, 127, "SELECT `Id`, `VipSince`, `Time` FROM `Vips` WHERE `SteamId` = '%s'", szAuthId );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleCheckVip", szQuery, szId, 1 );
}

public HandleCheckVip( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) || !SQL_NumResults( hQuery ) )
		return;
	
	new id = szData[ 0 ],
		iSysTime = get_systime( ),
		iTime = SQL_ReadResult( hQuery, 2 );
	
	if( !g_bConnected[ id ] )
		return;
	
	if( iTime ) { // VIP is not infinite
		iTime += SQL_ReadResult( hQuery, 1 );
		
		g_iExpireTime[ id ] = iTime;
		
		if( iSysTime >= iTime )
			return;
	}
	
	g_bVip[ id ] = true;
	
	VipConnectMessage( id );
	
	remove_user_flags( id, ADMIN_USER );
	set_user_flags( id, ADMIN_RESERVATION | ADMIN_CHAT );
	
	ExecuteForward( g_iForward[ Fwd_Connect ], iTime, id );
	
	new szQuery[ 128 ];
	formatex( szQuery, 127, "UPDATE `Vips` SET `LastJoin` = '%i' WHERE `Id` = '%i'", iSysTime, SQL_ReadResult( hQuery, 0 ) );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery );
}

public HandleNullRoute( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;

public CmdVips( const id ) {
	new szMessage[ 192 ], szNicks[ 33 ][ 25 ], iPlayers[ 32 ], iNum, iCount, i, iLen;
	get_players( iPlayers, iNum );
	
	for( i = 0; i < iNum; i++ )
		if( g_bVip[ iPlayers[ i ] ] )
			get_user_name( iPlayers[ i ], szNicks[ iCount++ ], 24 );
	
	iLen = formatex( szMessage, 191, "^3[ mY.RuN ]^4 Online VIP's:^3 " );
	
	if( iCount > 0 ) {
		for( i = 0; i < iCount; i++ ) {
			iLen += formatex( szMessage[ iLen ], 191, "%s%s ", szNicks[ i ], i < ( iCount - 1 ) ? "^1,^3 " : "" );
			
			if( iLen > 96 ) {
				ColorChat( id, Red, szMessage );
				iLen = formatex( szMessage, 191, "^3[ mY.RuN ] " );
			}
		}
		ColorChat( id, Red, szMessage );
	} else {
		iLen += formatex( szMessage[ iLen ], 191, "None" );
		
		ColorChat( id, Red, szMessage );
	}
}

public FwdHamPlayerSpawn( const id ) {
	if( g_bVip[ id ] && is_user_alive( id ) ) {
		new iTime = g_iExpireTime[ id ];
		
		if( iTime ) {
			iTime -= get_systime( );
			
			if( iTime <= 0 ) {
				ExecuteForward( g_iForward[ Fwd_Removed ], iTime, id );
				
				g_bVip[ id ] = false;
				
				ColorChat( id, Red, "[ mY.RuN ]^4 Your VIP has just expired! If you want to extend your VIP, you can donate again and it will be reactivated shortly." );
				
				remove_user_flags( id, ADMIN_RESERVATION | ADMIN_CHAT );
				
				if( !get_user_flags( id ) )
					set_user_flags( id, ADMIN_USER );
				
				return;
			}
			
			new szTimeLeft[ 128 ];
			get_time_length( id, iTime, timeunit_seconds, szTimeLeft, 127 );
			
			ColorChat( id, Red, "[ mY.RuN ]^1 Your VIP status is^4 OK^1. Time left:^4 %s", szTimeLeft );
		} else
			ColorChat( id, Red, "[ mY.RuN ]^1 Your VIP status is^4 AWESOME^1.^4 It's infinite^4 ;)" );
		
		if( ~get_user_flags( id ) & ADMIN_RESERVATION )
			set_user_flags( id, ADMIN_RESERVATION | ADMIN_CHAT );
	}
}

public NativeIsUserVip( const iPlugin, const iParams )
	return bool:g_bVip[ get_param( 1 ) ];

public MessageScoreAttrib( )
	if( g_bVip[ get_msg_arg_int( 1 ) ] && !get_msg_arg_int( 2 ) )
		set_msg_arg_int( 2, ARG_BYTE, ( 1 << 2 ) );

public CmdSay( const id ) {
	if( !g_bVip[ id ] )
		return;
	
	new szSaid[ 50 ];
	read_args( szSaid, 49 );
	remove_quotes( szSaid );
	
	if( szSaid[ 0 ] == '/' || szSaid[ 0 ] == '.' ) {
		new szCmd[ 8 ], szNick[ 32 ];
		parse( szSaid, szCmd, 8, szNick, 31 );
		
		if( equali( szCmd[ 1 ], "country" ) ) {
			new iPlayer;
			
			if( szNick[ 0 ] && !( iPlayer = FindPlayer( id, szNick ) ) )
				return;
			
			new szName[ 32 ], szIP[ 17 ], szCountry[ 45 ];
			get_user_name( iPlayer, szName, 31 );
			get_user_ip( iPlayer, szIP, 16, 1 );
			geoip_country( szIP, szCountry, 44 );
			
			ColorChat( id, Red, "[ mY.RuN ]^4 %s^1 is from^3 %s^1.", szName, szCountry );
		}
	}
}

FindPlayer( id, const szArg[ ] ) {
	new iPlayer = find_player( "bl", szArg );
	
	if( iPlayer ) {
		if( iPlayer != find_player( "blj", szArg ) ) {
			ColorChat( id, Red, "[ mY.RuN ]^1 There are more clients matching to your argument." );
			
			return 0;
		}
	}
	else if( szArg[ 0 ] == '#' && szArg[ 1 ] ) {
		iPlayer = find_player( "k", str_to_num( szArg[ 1 ] ) );
	}
	
	if( !iPlayer ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 Player with that name or userid not found." );
		
		return 0;
	}
	
	return iPlayer;
}

SQL_IsFail( const iFailState, const iError, const szError[ ] ) {
	if( iFailState == TQUERY_CONNECT_FAILED ) {
		log_to_file( "Achievements.log", "[Error][VIP] Could not connect to SQL database." );
		return true;
	}
	else if( iFailState == TQUERY_QUERY_FAILED ) {
		log_to_file( "Achievements.log", "[Error][VIP] Query failed: %s", szError );
		return true;
	}
	else if( iError ) {
		log_to_file( "Achievements.log", "[Error][VIP] Error on query: %s", szError );
		return true;
	}
	
	return false;
}

VipConnectMessage( const id )
	set_task( 5.0, "TaskPrintVip", id );

public TaskPrintVip( const id ) {
	if( !g_bConnected[ id ] )
		return;
	
	new szName[ 33 ];
	get_user_name( id, szName, 32 );
	
	set_hudmessage( 255, 120, 0, -1.0, 0.85, 0, 0.0, 5.0, 0.3, 0.3, -1 );
	show_hudmessage( 0, "VIP %s has joined the server!", szName );
	client_cmd( 0, "spk buttons/blip2" );
}
