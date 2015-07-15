#include < amxmodx >
#include < sqlx >

const MENU_KEYS = ( 1 << 0 ) | ( 1 << 1 ) | ( 1 << 2 ) | ( 1 << 3 ) | ( 1 << 4 ) | ( 1 << 9 );

new const MENU_STRING[ ] = "\yRate this map\
		^n^t^t\wMap: \r%s\
		^n^t^t\wAverage Rating: \r%.2f \y(%i vote%s)^n\
		^n\r1. \wExcellent\
		^n\r2. \wGood\
		^n\r3. \wAverage\
		^n\r4. \wPoor\
		^n\r5. \wTerrible\
		^n^n\r0. \wExit";

new Handle:g_hSqlTuple;
new g_szMapName[ 33 ];
new g_iVoteTimer = -1;

public plugin_init( )
{
	register_plugin( "Map Rate", "1.0", "xPaw" );
	
	register_menucmd( register_menuid( "RateMenu" ), MENU_KEYS, "HandleRateMenu" );
	
	get_mapname( g_szMapName, 32 );
	strtolower( g_szMapName );
	
//	g_hSqlTuple   = SQL_MakeStdTuple( );
	g_hSqlTuple   = SQL_MakeDbTuple( "localhost", "root", "root", "root" );
	
	//register_clcmd( "say /rate", "TaskPrepareRateMap" );
	
	set_task( 600.0, "TaskPrepareRateMap" );
	
	//SQL_QueryMe( _, "CREATE TABLE IF NOT EXISTS `MapRating` (SteamID VARCHAR(24), Map VARCHAR(32), Rating TINYINT(1), Rated DATETIME, UNIQUE KEY (Map, SteamID))" );
}

public plugin_end( )
{
	SQL_FreeHandle( g_hSqlTuple );
}

public TaskPrepareRateMap( )
{
	if( g_iVoteTimer == -1 )
	{
		g_iVoteTimer = 5;
		
		set_hudmessage( 0, 100, 255, -1.0, 0.2, 0, _, 4.0, 0.5, 0.5, 4 );
		show_hudmessage( 0, "You are going to rate this map in 10 seconds" );
		
		set_task( 5.0, "TaskPrepareRateMap" );
	}
	else if( g_iVoteTimer == 0 )
	{
		set_hudmessage( 255, 100, 0, -1.0, 0.2, 0, _, 0.5, 0.5, 0.5, 4 );
		show_hudmessage( 0, "Rate this map!", g_iVoteTimer );
		
		SQL_QueryMe( "HandleSelectRate", "SELECT COUNT(*), AVG(Rating) FROM `MapRating` WHERE `Map` = '%s'", g_szMapName );
		
		g_iVoteTimer = -1;
	}
	else
	{
		set_hudmessage( 0, 200, 0, -1.0, 0.2, 0, _, 1.0, 0.5, 0.5, 4 );
		show_hudmessage( 0, "Map rating will begin in %i...", g_iVoteTimer );
		
		--g_iVoteTimer;
		
		set_task( 1.0, "TaskPrepareRateMap" );
	}
}

public HandleRateMenu( const id, iKey )
{
	if( !( 0 <= iKey <= 4 ) )
	{
		return;
	}
	
	set_hudmessage( 0, 100, 255, -1.0, 0.2, 0, _, 1.0, 0.5, 0.5, 4 );
	show_hudmessage( 0, "Thank you for your rating!" );
	
	iKey = 5 - iKey;
	
	new szSteamID[ 25 ];
	get_user_authid( id, szSteamID, 24 );
	
	SQL_QueryMe( _, "INSERT INTO `MapRating` VALUES('%s', '%s', '%i', NOW()) ON DUPLICATE KEY UPDATE `Rating`='%i', `Rated`=NOW()",
		szSteamID, g_szMapName, iKey, iKey );
}

public HandleSelectRate( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
{
	if( SQL_IsFail( iFailState, iError, szError ) )
	{
		set_hudmessage( 0, 100, 255, -1.0, 0.2, 0, _, 1.0, 0.5, 0.5, 4 );
		show_hudmessage( 0, "Voting failed" );
		
		return;
	}
	
	set_task( 600.0, "TaskPrepareRateMap" );
	
	new szMenu[ 256 ], Float:flAverage, iVotes = SQL_ReadResult( hQuery, 0 );
	SQL_ReadResult( hQuery, 1, flAverage );
	
	formatex( szMenu, 255, MENU_STRING, g_szMapName, flAverage, iVotes, iVotes == 1 ? "" : "s" );
	
	new iPlayers[ 32 ], iCount, iTrash, id;
	get_players( iPlayers, iCount, "ch" );
	
	for( new i; i < iCount; i++ )
	{
		id = iPlayers[ i ];
		
		if( !player_menu_info( id, iTrash, iTrash ) )
		{
			show_menu( id, MENU_KEYS, szMenu, -1, "RateMenu" );
		}
	}
}

public HandleQuery( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime )
{
	SQL_IsFail( iFailState, iError, szError );
}

SQL_QueryMe( szHandle[ ] = "HandleQuery", const szQuery[ ], any:... )
{
	new szMessage[ 256 ];
	vformat( szMessage, 255, szQuery, 3 );
	
	SQL_ThreadQuery( g_hSqlTuple, szHandle, szMessage );
}

SQL_IsFail( const iFailState, const iError, const szError[ ] )
{
	if( iFailState == TQUERY_CONNECT_FAILED )
	{
		log_to_file( "Achievements.log", "[Error] Could not connect to SQL database: %s", szError );
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
