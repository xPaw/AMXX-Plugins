#include < amxmodx >
#include < sqlx >
#include < chatcolor >

new const MOTD_HTML [ ] = "<html><head><meta http-equiv='Refresh' content='0; URL=http://my-run.de/game/surfski2_top.php?ingame'></head><body bgcolor=black><center><img src=http://my-run.de/l.png>";
new const MOTD_TITLE[ ] = "[ mY.RuN ] Surf Ski 2 Top";

#define IsUserAuthorized(%1) ( g_iPlayerData[ %1 ][ DATA_STATUS ] & FULL_STATUS == FULL_STATUS )

enum ( <<= 1 )
{
	CONNECTED = 1,
	AUTHORIZED
};

enum _:PLR_DATA
{
	DATA_INDEX,
	DATA_STATUS
};

const FULL_STATUS = CONNECTED | AUTHORIZED;

new g_iPlayerData[ 33 ][ PLR_DATA ];
new Handle:g_hSqlTuple;

public plugin_init( )
{
	register_plugin( "surf_ski_2: Top15", "1.1", "xPaw" );
	
	register_clcmd( "say /rank" , "CmdRank" );
	register_clcmd( "say /top"  , "CmdTop" );
	register_clcmd( "say /top10", "CmdTop" );
	register_clcmd( "say /top15", "CmdTop" );
	
	register_event( "DeathMsg", "EventDeathMsg", "a" );
	
	g_hSqlTuple = SQL_MakeDbTuple( "localhost", "root", "root", "root" );
}

public plugin_end( )
{
	SQL_FreeHandle( g_hSqlTuple );
}

// Client Related
// ====================================
public client_disconnect( id )
{
	g_iPlayerData[ id ][ DATA_INDEX  ] = 0;
	g_iPlayerData[ id ][ DATA_STATUS ] = 0;
}

public client_authorized( id )
{
	if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= AUTHORIZED ) & CONNECTED )
	{
		UserHasBeenAuthorized( id );
	}
}

public client_putinserver( id )
{
	if( ( g_iPlayerData[ id ][ DATA_STATUS ] |= CONNECTED ) & AUTHORIZED && !is_user_bot( id ) )
	{
		UserHasBeenAuthorized( id );
	}
}

// Commands
// ====================================
public CmdTop( const id )
{
	show_motd( id, MOTD_HTML, MOTD_TITLE );
}

public CmdRank( const id )
{
	if( !g_iPlayerData[ id ][ DATA_INDEX ] )
	{
		ColorChat( id, Red, "^3[ mY.RuN Rank ]^4 Whooops." );
		
		return;
	}
	
	new szQuery[ 256 ];
	formatex( szQuery, charsmax( szQuery ), "SELECT `Kills` as a, (SELECT COUNT(Kills)+1 FROM `surfski2top` WHERE `Kills` > a) as b, \
		(SELECT COUNT(*) FROM `surfski2top`) as c FROM `surfski2top` WHERE `Id` = '%i'", g_iPlayerData[ id ][ DATA_INDEX ] );
	
	new szData[ 1 ];
	szData[ 0 ] = id;
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleSelectRank", szQuery, szData, 1 );
}

// Events
// ====================================
public EventDeathMsg( )
{
	new iVictim = read_data( 2 );
	new iKiller = read_data( 1 );
	
	if( iVictim == iKiller || !is_user_connected( iKiller ) || get_user_team( iVictim ) == get_user_team( iKiller ) )
	{
		return;
	}
	
	new szQuery[ 128 ];
	formatex( szQuery, charsmax( szQuery ), "UPDATE `surfski2top` SET `Kills` = `Kills` + 1 WHERE `Id` = '%i'", g_iPlayerData[ iKiller ][ DATA_INDEX ] );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleNullRoute", szQuery );
}

// SQL Related
// ====================================
UserHasBeenAuthorized( const id )
{
	new szAuthID[ 32 ], szQuery[ 128 ];
	get_user_authid( id, szAuthID, 31 );
	formatex( szQuery, charsmax( szQuery ), "SELECT `Id` FROM `surfski2top` WHERE `SteamID` = '%s'", szAuthID );
	
	new iData[ 1 ];
	iData[ 0 ] = id;
	
	SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, iData, 1 );
}

public HandleNullRoute( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
	SQL_IsFail( iFailState, iError, szError );
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		return;
	}
	
	new id = iData[ 0 ];
	
	if( !IsUserAuthorized( id ) )
	{
		return;
	}
	
	if( SQL_NumResults( hQuery ) )
	{
		g_iPlayerData[ id ][ DATA_INDEX ] = SQL_ReadResult( hQuery, 0 );
	}
	else
	{
		new szAuthID[ 32 ], szQuery[ 128 ];
		get_user_authid( id, szAuthID, 31 );
		formatex( szQuery, charsmax( szQuery ), "INSERT INTO `surfski2top` (`SteamID`) VALUES ('%s')", szAuthID );
		
		SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert", szQuery, iData, 1 );
	}
}

public HandlePlayerInsert( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		return;
	}
	
	new id = iData[ 0 ];
	
	if( IsUserAuthorized( id ) )
	{
		g_iPlayerData[ id ][ DATA_INDEX ] = SQL_GetInsertId( hQuery );
	}
}

public HandleSelectRank( iFailState, Handle:hQuery, szError[ ], iError, iData[ ], iSize, Float:flQueueTime )
{
	new id = iData[ 0 ];
	
	if( !IsUserAuthorized( id ) )
	{
		return;
	}
	
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		ColorChat( id, Red, "^3[ mY.RuN Rank ]^4 Whooops." );
		
		return;
	}
	
	new iKills = SQL_ReadResult( hQuery, 0 );
	
	if( !iKills )
	{
		ColorChat( id, Red, "^3[ mY.RuN Rank ]^1 You are not ranked yet." );
		
		return;
	}
	
	new iRank  = SQL_ReadResult( hQuery, 1 );
	new iTotal = SQL_ReadResult( hQuery, 2 );
	
	ColorChat( id, Red, "^3[ mY.RuN Rank ]^1 You rank is^4 %i^1 out of^4 %i^1 with^4 %i^1 kill^4%s^1.", iRank, iTotal, iKills, ( iKills == 1 ) ? "" : "s" );
}

stock bool:SQL_IsFail( const iFailState, const iError, const szError[ ] )
{
	if( iFailState == TQUERY_CONNECT_FAILED )
	{
		log_amx( "[SS2TOP] Could not connect to SQL database: %s", szError );
		return true;
	}
	else if( iFailState == TQUERY_QUERY_FAILED )
	{
		log_amx( "[SS2TOP] Query failed: (%i) %s", iError, szError );
		return true;
	}
	
	return false;
}
