#include < amxmodx >
#include < sqlx >

// #pragma reqlib Ricochet

forward Rc_PlayerDeath( const id, const iKiller, bool:bDecapitate, bool:bTeleported );

new Handle:g_hSqlConnection, g_iSqlId[ 33 ];

public plugin_init( ) {
	register_plugin( "Ricochet: Stats", "1.0", "xPaw" );
	
	set_task( 1.0, "Task_ConnectSQL" );
}

public plugin_end( )
	SQL_FreeHandle( g_hSqlConnection );

public client_disconnect( id )
	g_iSqlId[ id ] = 0;

public client_putinserver( id ) {
	new szSteamId[ 40 ], szIp[ 16 ], szName[ 64 ], szQuery[ 128 ], iSysTime = get_systime( 0 );
	get_user_authid( id, szSteamId, 39 );
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIp, 15, 1 );
	SQL_QuoteString( g_hSqlConnection, szName, 63, szName );
	
	if( szSteamId[ 9 ] == 'P' ) // sanity check
		return;
	
	formatex( szQuery, 255, "SELECT `Id` FROM `RicochetStats` WHERE `SteamId` = '%s'", szSteamId );
	
	new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, szQuery );
	
	if( SQL_Execute( hQuery ) && SQL_NumResults( hQuery ) ) {
		g_iSqlId[ id ] = SQL_ReadResult( hQuery, 0 );
		
		SQL_FreeHandle( hQuery );
		
		formatex( szQuery, 255, "UPDATE `RicochetStats` SET `Name` = '%s', `Ip` = '%s', `LastJoin` = '%i' WHERE `Id` = '%i'",
			szName, szIp, iSysTime, g_iSqlId[ id ] );
	} else {
		formatex( szQuery, 255, "INSERT INTO `RicochetStats` (`SteamId`, `Name`, `Ip`, `LastJoin`, `FirstJoin`) VALUES ('%s', '%s', '%s', '%i', '%i')",
			szSteamId, szName, szIp, iSysTime, iSysTime );
	}
	
	SQL_ExecuteQuery( szQuery );
}

public client_infochanged( id ) {
	if( !g_iSqlId[ id ] )
		return;
	
	new szOldName[ 32 ], szNewName[ 32 ];
	get_user_name( id, szOldName, 31 );
	get_user_info( id, "name", szNewName, 31 );
	
	if( !equali( szNewName, szOldName ) ) {
		new szName[ 64 ], szQuery[ 128 ];
		SQL_QuoteString( g_hSqlConnection, szName, 63, szNewName );
		
		formatex( szQuery, 127, "UPDATE `RicochetStats` SET `Name` = '%s' WHERE `Id` = '%i'", szName, g_iSqlId[ id ] );
		
		SQL_ExecuteQuery( szQuery );
	}
}

public Rc_PlayerDeath( const id, const iKiller, bool:bDecapitate, bool:bTeleported ) {
	new szQuery[ 256 ];
	
	if( g_iSqlId[ id ] ) {
		formatex( szQuery, 255, "UPDATE `RicochetStats` SET `Deaths` = `Deaths` + 1 WHERE `Id` = '%i'", g_iSqlId[ id ] );
		
		SQL_ExecuteQuery( szQuery );
	}
	
	if( g_iSqlId[ iKiller ] ) {
		formatex( szQuery, 255, "UPDATE `RicochetStats` SET `Kills` = `Kills` + 1%s%s WHERE `Id` = '%i'",
			( bDecapitate ? ", `Decapitated` = `Decapitated` + 1" : "" ),
			( bTeleported ? ", `Teleported` = `Teleported` + 1" : "" ), g_iSqlId[ iKiller ] );
		
		SQL_ExecuteQuery( szQuery );
	}
}

public Task_ConnectSQL( ) {
	new szError[ 128 ], iErrorCode;
	
//	new Handle:hSqlTuple = SQL_MakeStdTuple( );
	new Handle:hSqlTuple = SQL_MakeDbTuple( "localhost", "root", "root", "root" );
	g_hSqlConnection = SQL_Connect( hSqlTuple, iErrorCode, szError, 127 );
	
	SQL_FreeHandle( hSqlTuple );
	
	if( g_hSqlConnection == Empty_Handle )
		set_fail_state( szError );
}

bool:SQL_ExecuteQuery( const szQuery[ ] ) { // Just to avoid copypasting ;)
	new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, szQuery );
	
	if( !SQL_Execute( hQuery ) ) {
		new szError[ 256 ];
		SQL_QueryError( hQuery, szError, 255 );
		
		log_to_file( "Ricochet.log", "[SQL] %s", szError );
		
		return false;
	}
	
	SQL_FreeHandle( hQuery );
	
	return true;
}
