#include < amxmodx >
#include < sqlx >

//
// This plugin is only for use if not using main achievements plugin!
//

new Handle:g_hSqlTuple;
new bool:g_bConnected[ 33 ];
new g_iPlayerId[ 33 ];

public plugin_init( )
{
	register_plugin( "Achv Global Stats", "3.0", "xPaw" );
	
	if( LibraryExists( "Achievements", LibType_Library ) )
	{
		set_fail_state( "Main achievements plugin is running!" );
	}
	
	g_hSqlTuple = SQL_MakeDbTuple( "localhost", "root", "root", "achievements" );
}

public plugin_end( )
{
	SQL_FreeHandle( g_hSqlTuple );
}

public client_putinserver( id )
{
	g_bConnected[ id ] = bool:!is_user_bot( id );
	
	if( g_iPlayerId[ id ] || !g_bConnected[ id ] )
	{
		return;
	}
	
	new szAuthid[ 40 ];
	get_user_authid( id, szAuthid, 39 );
	
	if( szAuthid[ 9 ] != 'P' ) // STEAM_ID_PENDING
	{
		UserHasBeenAuthorized( id, szAuthid );
	}
}

public client_authorized( id )
{
	if( g_bConnected[ id ] && !g_iPlayerId[ id ] )
	{
		new szAuthid[ 40 ];
		get_user_authid( id, szAuthid, 39 );
		
		UserHasBeenAuthorized( id, szAuthid );
	}
}

UserHasBeenAuthorized( const id, const szAuthid[ 40 ] )
{
	new szQuery[ 128 ], sz[ 1 ]; sz[ 0 ] = id;
	formatex( szQuery, 127, "SELECT `Id` FROM `GlobalPlayers` WHERE `SteamId` = '%s'", szAuthid );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, sz, 1 );
}

public client_disconnect( id )
{
	if( !g_bConnected[ id ] )
	{
		g_iPlayerId[ id ] = 0; // Just-in-case?
		
		return;
	}
	
	SQL_QueryMe( "UPDATE `GlobalPlayers` SET `LastJoin` = '%i', `PlayTime` = `PlayTime` + '%i' WHERE `Id` = '%i'",
		get_systime( 0 ), ( get_user_time( id ) / 60 ), g_iPlayerId[ id ] );
	
	g_iPlayerId[ id ]  = 0;
	g_bConnected[ id ] = false;
}

public client_infochanged( id )
{
	if( !g_iPlayerId[ id ] )
	{
		return;
	}
	
	new szOldName[ 32 ], szNewName[ 32 ];
	get_user_name( id, szOldName, 31 );
	get_user_info( id, "name", szNewName, 31 );
	
	if( !equali( szNewName, szOldName ) )
	{
		SQL_QueryMe( "UPDATE `GlobalPlayers` SET `Nick` = ^"%s^" WHERE `Id` = '%i'", szNewName, g_iPlayerId[ id ] );
	}
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
{
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		return;
	}
	
	new id = szData[ 0 ];
	
	if( !g_bConnected[ id ] )
	{
		return;
	}
	
	new szIp[ 16 ], szName[ 32 ], iSysTime = get_systime( 0 );
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIp, 15, 1 );
	
	if( !SQL_NumResults( hQuery ) ) // This player doesnt have any entry in db
	{
		new szQuery[ 256 ], szAuthid[ 40 ];
		get_user_authid( id, szAuthid, 39 );
		formatex( szQuery, 255, "INSERT INTO `GlobalPlayers` (`SteamId`, `Ip`, `Nick`, `FirstJoin`, `LastJoin`) VALUES ('%s', '%s', ^"%s^", '%i', '%i')",
			szAuthid, szIp, szName, iSysTime, iSysTime );
		
		SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert", szQuery, szData, 1 );
		
		return;
	}
	
	g_iPlayerId[ id ] = SQL_ReadResult( hQuery, 0 );
	
	SQL_QueryMe( "UPDATE `GlobalPlayers` SET `Nick` = ^"%s^", `Ip` = '%s', `LastJoin` = '%i' WHERE `Id` = '%i'", szName, szIp, iSysTime, g_iPlayerId[ id ] );
}

public HandlePlayerInsert( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
{
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		return;
	}
	
	new id = szData[ 0 ];
	
	if( g_bConnected[ id ] )
	{
		new szQuery[ 128 ], szAuthid[ 40 ];
		get_user_authid( id, szAuthid, 39 );
		
		formatex( szQuery, 127, "SELECT `Id` FROM `GlobalPlayers` WHERE `SteamId` = '%s'", szAuthid );
		
		SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, szData, 1 );
	}
}

public HandleQuery( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
{
	SQL_IsFail( iFailState, iError, szError );
}

SQL_QueryMe( const szQuery[ ], any:... )
{
	new szMessage[ 256 ];
	vformat( szMessage, 255, szQuery, 2 );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleQuery", szMessage );
}

SQL_IsFail( const iFailState, const iError, const szError[ ] )
{
	if( iFailState == TQUERY_CONNECT_FAILED )
	{
		log_to_file( "Achievements.log", "[Error] Could not connect to SQL database." );
		return true;
	}
	else if( iFailState == TQUERY_QUERY_FAILED )
	{
		log_to_file( "Achievements.log", "[Error] Query failed: %s", szError );
		return true;
	}
	else if( iError )
	{
		log_to_file( "Achievements.log", "[Error] Error on query: %s", szError );
		return true;
	}
	
	return false;
}
