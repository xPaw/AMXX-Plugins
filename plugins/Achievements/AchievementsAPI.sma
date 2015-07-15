#include < amxmodx >
#include < sqlx >
#include < time >
#include < chatcolor >

// #define DEBUG
//#define USE_TUTOR
//#define SHOW_TUTOR_ON_SPAWN

#pragma semicolon 1

new const LogFile[ ]   = "Achievements.log";
new const MotdTitle[ ] = "[ mY.RuN ] Achievements by xPaw";
new const Prefix[ ]    = "[ mY.RuN Achievements ]";

new const TutorTask = 4562853;

#define IsPlayer(%1)         ( 1 <= %1 <= g_iMaxPlayers )
#define IsAchievement(%1)    ( 0 <= %1 <= g_iTotalAchievs )
#define IsUserAuthorized(%1) ( g_iConnected[ %1 ] & FULL_STATUS == FULL_STATUS )

#define SteamPlaytime formatex( szTime, 6, "%.1f", iPlayTime / 60.0 );

enum _:AchievementData {
	Achv_Name[ 32 ],
	Achv_NeededToGain,
	Achv_ProgressModule,
	Achv_SqlIndex
};

enum _:ProgressData {
	Progress_Num,
	Progress_Bits
};

enum _:Forwards {
	Fwd_Connect,
	Fwd_Unlock
};

enum ( <<= 1 ) {
	CONNECTED = 1,
	AUTHORIZED
};

const FULL_STATUS = CONNECTED|AUTHORIZED;

new Array:g_aAchievements;
new Array:g_aProgress[ 33 ];
new Trie:g_tSqlIndexes;

new Handle:g_hSqlConnection;
new Handle:g_hSqlTuple;

new g_iMaxPlayers;
new g_iTotalAchievs;
new g_szDummy[ 2 ];
new g_iPlayerId[ 33 ];
new g_iPlayTime[ 33 ];
new g_iConnected[ 33 ];
new g_iForwards[ Forwards ];

new TABLE_GLOBAL[ 32 ], TABLE_ACHIEVS[ 32 ], TABLE_PLAYERS[ 32 ], TABLE_PROGRESS[ 32 ];

new g_szHTML[ 364 ] = "<html><head><meta http-equiv='Refresh' content='0; URL=%link%'></head><body bgcolor=black><center><img src=http://my-run.de/l.png>";

#if defined USE_TUTOR
	enum TutorColors {
		TUTOR_GREEN  = 1, // Info
		TUTOR_RED    = 2, // Skull
		TUTOR_BLUE   = 4, // Skull
		TUTOR_YELLOW = 8  // Info
	};
	
	new g_iMsgTutorText, g_iMsgTutorClose;
	
	#include < hamsandwich >
#endif

public plugin_init( ) {
	register_plugin( "Achievements API", "3.0", "xPaw" );
	
	register_dictionary( "time.txt" );
	
#if defined USE_TUTOR
	g_iMsgTutorText  = get_user_msgid( "TutorText" );
	g_iMsgTutorClose = get_user_msgid( "TutorClose" );
	
	#if defined SHOW_TUTOR_ON_SPAWN
		RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	#endif
#endif
	
	// Read config file
	new szFile[ 256 ];
	get_localinfo( "amxx_configsdir", szFile, 127 );
	add( szFile, 127, "/achievements.cfg" );
	
	new iFile = fopen( szFile, "rt" );
	
	if( !iFile )
		SetFailState( "Failed to open config file." );
	
	new iPos, szHost[ 32 ], szUser[ 32 ], szPass[ 32 ], szDb[ 32 ], szStatsLink[ 128 ];
	
	while( !feof( iFile ) ) {
		fgets( iFile, szFile, 255 );
		trim( szFile );
		
		if( !szFile[ 0 ] || szFile[ 0 ] == ';' )
			continue;
		
		if( ( iPos = contain( szFile, "=" ) ) < 0 )
			continue;
		
		if( equal( szFile, "TABLE_ACHIEVS", 12 ) )
			copy( TABLE_ACHIEVS, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "TABLE_PLAYERS", 12 ) )
			copy( TABLE_PLAYERS, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "TABLE_PROGRESS", 13 ) )
			copy( TABLE_PROGRESS, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "TABLE_GLOBAL", 11 ) )
			copy( TABLE_GLOBAL, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "STATS_LINK", 9 ) )
			copy( szStatsLink, 127, szFile[ iPos + 2 ] );
		
		else if( equal( szFile, "SQL_HOST", 7 ) )
			copy( szHost, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "SQL_USER", 7 ) )
			copy( szUser, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "SQL_PASS", 7 ) )
			copy( szPass, 31, szFile[ iPos + 2 ] );
		else if( equal( szFile, "SQL_DB", 5 ) )
			copy( szDb, 31, szFile[ iPos + 2 ] );
	}
	
	fclose( iFile );
	
	// Open sql
	new szError[ 128 ], i;
	
	g_hSqlTuple      = SQL_MakeDbTuple( szHost, szUser, szPass, szDb );
	g_hSqlConnection = SQL_Connect( g_hSqlTuple, i, szError, 127 );
	
	if( g_hSqlConnection == Empty_Handle )
		SetFailState( szError );
	
	g_iMaxPlayers   = get_maxplayers( );
	g_aAchievements = ArrayCreate( AchievementData );
	g_tSqlIndexes   = TrieCreate( );
	
	for( i = 1; i <= g_iMaxPlayers; i++ )
		g_aProgress[ i ] = ArrayCreate( 2 );
	
	register_clcmd( "say",               "CmdSay" );
	register_clcmd( "say /ach",          "CmdAchievements" );
	register_clcmd( "say /played",       "CmdPlayedTime" );
	register_clcmd( "say /playtime",     "CmdPlayedTime" );
	register_clcmd( "say /achievements", "CmdAchievements" );
	
	// Forwards
	g_iForwards[ Fwd_Connect ] = CreateMultiForward( "Achv_Connect", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );
	g_iForwards[ Fwd_Unlock ]  = CreateMultiForward( "Achv_Unlock", ET_IGNORE, FP_CELL, FP_CELL );
	
	// Generate this
	replace( g_szHTML, 363, "%link%", szStatsLink );
	
	// Reset players
	SQL_QueryMe( "UPDATE `%s` SET `Status` = '0'", TABLE_PLAYERS );
}

SetFailState( const szError[ ] ) {
	new iReturn, iForward = CreateMultiForward( "Achv_CoreGoneWrong", ET_IGNORE );
	
	ExecuteForward( iForward, iReturn );
	DestroyForward( iForward );
	set_fail_state( szError );
}

public plugin_precache( ) {
	precache_sound( "events/task_complete.wav" );
	
#if defined USE_TUTOR
	new const szTutorPrecache[ ][ ] = {
		"gfx/career/icon_!.tga",
		"gfx/career/icon_!-bigger.tga",
		"gfx/career/icon_i.tga",
		"gfx/career/icon_i-bigger.tga",
		"gfx/career/icon_skulls.tga",
		"gfx/career/round_corner_ne.tga",
		"gfx/career/round_corner_nw.tga",
		"gfx/career/round_corner_se.tga",
		"gfx/career/round_corner_sw.tga",
		"resource/TutorScheme.res",
		"resource/UI/TutorTextWindow.res"
	};
	
	for( new i; i < sizeof szTutorPrecache; i++ )
		precache_generic( szTutorPrecache[ i ] );
#endif
}

public plugin_end( ) {
	ArrayDestroy( g_aAchievements );
	TrieDestroy( g_tSqlIndexes );
	
	new i;
	for( i = 1; i <= g_iMaxPlayers; i++ )
		ArrayDestroy( g_aProgress[ i ] );
	
	for( i = 0; i < Forwards; i++ )
		DestroyForward( g_iForwards[ i ] );
	
	SQL_FreeHandle( g_hSqlTuple );
	SQL_FreeHandle( g_hSqlConnection );
}

public plugin_natives( ) {
	register_library( "Achievements" );
	
	register_native( "SetAchievementComponentBit", "NativeSetComponentBit" );
	register_native( "RegisterAchievement", "NativeRegisterAchievement" );
	register_native( "AchievementProgress", "NativeAchievementProgress" );
	register_native( "HaveAchievement",     "NativeHaveAchievement" );
	register_native( "GetProgress",         "NativeGetProgress" );
	register_native( "GetUnlocksCount",     "NativeGetUnlocksCount" );
	register_native( "SetLeaderBoard",      "NativeSetLeaderBoard" );
	register_native( "GetPlayerId",         "NativeGetPlayerId" );
}

public client_authorized( id )
	if( ( g_iConnected[ id ] |= AUTHORIZED ) & CONNECTED )
		UserHasBeenAuthorized( id );

public client_putinserver( id )
	if( !is_user_bot( id ) && ( g_iConnected[ id ] |= CONNECTED ) & AUTHORIZED )
		UserHasBeenAuthorized( id );

UserHasBeenAuthorized( const id ) {
	new szAuthid[ 40 ], EmptyProgress[ ProgressData ];
	get_user_authid( id, szAuthid, 39 );
	
	for( new i = 0; i < g_iTotalAchievs; i++ )
		ArraySetArray( g_aProgress[ id ], i, EmptyProgress );
	
	new szQuery[ 128 ], szId[ 1 ]; szId[ 0 ] = id;
	formatex( szQuery, 127, "SELECT `Id` FROM `GlobalPlayers` WHERE `SteamId` = '%s'", szAuthid );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerConnect", szQuery, szId, 1 );
}

public HandlePlayerConnect( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
#if defined DEBUG
	log_amx( "[DEBUG] Query finished in %.2f seconds. (Player)", flQueueTime );
#endif
	
	new id = szData[ 0 ];
	
	if( !IsUserAuthorized( id ) )
		return;
	
	new szIp[ 16 ], szName[ 32 ], iSysTime = get_systime( 0 );
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIp, 15, 1 );
	
	if( !SQL_NumResults( hQuery ) ) { // This player doesnt have any entry in db
		new szQuery[ 256 ], szAuthid[ 40 ];
		get_user_authid( id, szAuthid, 39 );
		formatex( szQuery, 255, "INSERT INTO `%s` (`SteamId`, `Ip`, `Nick`, `FirstJoin`, `LastJoin`) \
			VALUES ('%s', '%s', ^"%s^", '%i', '%i')",
			TABLE_GLOBAL, szAuthid, szIp, szName, iSysTime, iSysTime );
		
		SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert", szQuery, szData, 1 );
		
		return;
	}
	
	g_iPlayerId[ id ] = SQL_ReadResult( hQuery, 0 );
	
	SQL_QueryMe( "UPDATE `%s` SET `Nick` = ^"%s^", `Ip` = '%s', `LastJoin` = '%i' WHERE `Id` = '%i'",
		TABLE_GLOBAL, szName, szIp, iSysTime, g_iPlayerId[ id ] );
	
	SQL_QueryMe( "INSERT INTO `%s` (`Id`,`Status`,`FirstJoin`,`LastJoin`,`Connects`) \
	VALUES ('%i','1','%i','%i','1') ON DUPLICATE KEY UPDATE `Connects`=`Connects`+1,`Status`='1',`LastJoin`='%i'",
		TABLE_PLAYERS, g_iPlayerId[ id ], iSysTime, iSysTime, iSysTime );
	
	// Select player progress
	hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT `Progress`, `Achievement`, `Bits` \
	FROM `%s` WHERE `Id` = '%i' ORDER BY `Achievement` ASC", TABLE_PROGRESS, g_iPlayerId[ id ] );
	
	if( !SQL_Execute( hQuery ) ) {
		new szQuery[ 256 ];
		SQL_QueryError( hQuery, szQuery, 255 );
		
		log_to_file( LogFile, "[Error] %s", szQuery );
		
		SQL_FreeHandle( hQuery );
		
		return;
	}
	
	if( SQL_NumResults( hQuery ) ) {
		new iAchievement, Progress[ ProgressData ];
		
		while( SQL_MoreResults( hQuery ) ) {
			iAchievement   = 0;
			g_szDummy[ 0 ] = SQL_ReadResult( hQuery, 1 );
			
			if( !TrieGetCell( g_tSqlIndexes, g_szDummy, iAchievement ) ) {
				SQL_NextRow( hQuery );
				continue;
			}
			
			Progress[ Progress_Num  ] = SQL_ReadResult( hQuery, 0 );
			Progress[ Progress_Bits ] = SQL_ReadResult( hQuery, 2 );
			
			ArraySetArray( g_aProgress[ id ], iAchievement, Progress );
			
			SQL_NextRow( hQuery );
		}
	}
	
	SQL_FreeHandle( hQuery );
	
	// Select player from server table
	hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT `PlayTime`, `Connects` FROM `%s` WHERE `Id` = '%i'", TABLE_PLAYERS, g_iPlayerId[ id ] );
	
	if( !SQL_Execute( hQuery ) ) {
		new szQuery[ 256 ];
		SQL_QueryError( hQuery, szQuery, 255 );
		
		log_to_file( LogFile, "[Error] %s", szQuery );
		
		SQL_FreeHandle( hQuery );
		
		return;
	}
	
	new iConnects;
	
	if( !SQL_NumResults( hQuery ) ) {
		g_iPlayTime[ id ] = 0;
	} else {
		g_iPlayTime[ id ] = SQL_ReadResult( hQuery, 0 );
		iConnects = SQL_ReadResult( hQuery, 1 );
	}
	
	SQL_FreeHandle( hQuery );
	
	new iReturn;
	ExecuteForward( g_iForwards[ Fwd_Connect ], iReturn, id, g_iPlayTime[ id ], iConnects );
}

public HandlePlayerInsert( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
#if defined DEBUG
	log_amx( "[DEBUG] Query finished in %.2f seconds. (Player Insert)", flQueueTime );
#endif
	
	new id = szData[ 0 ];
	
	if( !IsUserAuthorized( id ) )
		return;
	
	new szQuery[ 128 ], szAuthid[ 40 ], iReturn;
	get_user_authid( id, szAuthid, 39 );
	formatex( szQuery, 127, "SELECT `Id` FROM `GlobalPlayers` WHERE `SteamId` = '%s'", szAuthid );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandlePlayerInsert2", szQuery, szData, 1 );
	
	ExecuteForward( g_iForwards[ Fwd_Connect ], iReturn, id, 0, 0 );
}

public HandlePlayerInsert2( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
#if defined DEBUG
	log_amx( "[DEBUG] Query finished in %.2f seconds. (Player Insert #2)", flQueueTime );
#endif
	
	new id = szData[ 0 ];
	
	if( !IsUserAuthorized( id ) )
		return;
	
	g_iPlayerId[ id ] = SQL_ReadResult( hQuery, 0 );
	
	new iSysTime = get_systime( 0 );
	
	SQL_QueryMe( "INSERT INTO `%s` (`Id`,`Status`,`FirstJoin`,`LastJoin`,`Connects`) \
	VALUES ('%i','1','%i','%i','1') ON DUPLICATE KEY UPDATE `Connects`=`Connects`+1,`Status`='1',`LastJoin`='%i'",
		TABLE_PLAYERS, g_iPlayerId[ id ], iSysTime, iSysTime, iSysTime );
}

public client_disconnect( id ) {
	g_iPlayTime[ id ]  = 0;
	g_iConnected[ id ] = 0;
	
	if( !g_iPlayerId[ id ] )
		return;
	
	new iPlayTime = ( get_user_time( id ) / 60 ),
		iSysTime  = get_systime( 0 );
	
	SQL_QueryMe( "UPDATE `%s` SET `Status` = '0', `LastJoin` = '%i', `PlayTime` = `PlayTime` + '%i' WHERE `Id` = '%i'",
		TABLE_PLAYERS, iSysTime, iPlayTime, g_iPlayerId[ id ] );
	
	SQL_QueryMe( "UPDATE `%s` SET `LastJoin` = '%i', `PlayTime` = `PlayTime` + '%i' WHERE `Id` = '%i'",
		TABLE_GLOBAL, iSysTime, iPlayTime, g_iPlayerId[ id ] );
	
	g_iPlayerId[ id ] = 0;
}

public client_infochanged( id ) {
	if( !g_iPlayerId[ id ] )
		return;
	
	new szOldName[ 32 ], szNewName[ 32 ];
	get_user_name( id, szOldName, 31 );
	get_user_info( id, "name", szNewName, 31 );
	
	if( !equali( szNewName, szOldName ) )
		SQL_QueryMe( "UPDATE `%s` SET `Nick` = ^"%s^" WHERE `Id` = '%i'", TABLE_GLOBAL, szNewName, g_iPlayerId[ id ] );
}

public NativeAchievementProgress( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "AchievementProgress: index out of bounds for id (%i)", id );
		return 0;
	}
	else if( !g_iPlayerId[ id ] )
		return 0;
	
	new iAchievement = get_param( 2 );
	
	if( !IsAchievement( iAchievement ) ) {
		log_error( AMX_ERR_BOUNDS, "AchievementProgress: index out of bounds for iAchievement (%i)", id );
		return 0;
	}
	
	new Achievement[ AchievementData ], Progress[ ProgressData ];
	ArrayGetArray( g_aAchievements, iAchievement, Achievement );
	ArrayGetArray( g_aProgress[ id ], iAchievement, Progress );
	
	// Lets check if he already has achievement
	if( Progress[ Progress_Num ] >= Achievement[ Achv_NeededToGain ] ) {
	#if defined DEBUG
		ColorChat( 0, Red, "^1Achievement progress for^3 #%i^1 -^4 ^"%s^" (%i)^1 -^3 Already unlocked!",
			id, Achievement[ Achv_Name ], Achievement[ Achv_SqlIndex ] );
	#endif
		
		return 1;
	}
	
	new iProgress = get_param( 3 );
	new iTotalProgress = iProgress + Progress[ Progress_Num ];
	
	if( iTotalProgress >= Achievement[ Achv_NeededToGain ] ) {
		iTotalProgress = Achievement[ Achv_NeededToGain ];
		
		AwardAchievement( id, iAchievement, Achievement );
	}
	else if( Achievement[ Achv_ProgressModule ] > 0 && ( iTotalProgress % Achievement[ Achv_ProgressModule ] ) == 0 ) {
		ShowProgressNotification( id, iTotalProgress, Achievement[ Achv_Name ], Achievement[ Achv_NeededToGain ] );
	}
	
	Progress[ Progress_Num ] = iTotalProgress;
	
	ArraySetArray( g_aProgress[ id ], iAchievement, Progress );
	
	UTIL_UpdateProgress( id, Achievement[ Achv_SqlIndex ], iProgress, Progress[ Progress_Bits ] );
	
#if defined DEBUG
	ColorChat( 0, Red, "^1Achievement progress for^3 #%i^1 -^4 ^"%s^" (%i)^1 - Progress:^4 %i^1 (%i/%i)",
		id, Achievement[ Achv_Name ], Achievement[ Achv_SqlIndex ], iProgress, iTotalProgress, Achievement[ Achv_NeededToGain ] );
#endif
	
	return 0;
}

UTIL_SetProgress( const id, const iSqlIndex, const iProgress, const iBits ) {
	new iSysTime = get_systime( 0 );
	SQL_QueryMe( "INSERT INTO `%s` VALUES('%i', '%i', '%i', '%i', '%i') ON DUPLICATE KEY UPDATE `Progress` = '%i', `Bits` = '%i', `Date` = '%i'",
		TABLE_PROGRESS, g_iPlayerId[ id ], iSqlIndex, iProgress, iBits, iSysTime, iProgress, iBits, iSysTime );
}

UTIL_UpdateProgress( const id, const iSqlIndex, const iProgress, const iBits ) {
	new iSysTime = get_systime( 0 );
	SQL_QueryMe( "INSERT INTO `%s` VALUES('%i', '%i', '%i', '%i', '%i') ON DUPLICATE KEY UPDATE `Progress` = `Progress` + '%i', `Bits` = '%i', `Date` = '%i'",
		TABLE_PROGRESS, g_iPlayerId[ id ], iSqlIndex, iProgress, iBits, iSysTime, iProgress, iBits, iSysTime );
}

ShowProgressNotification( const id, const iProgress, const szName[ ], const iNeededToGain ) {
	client_cmd( id, "spk ^"events/tutor_msg^"" );
	
#if defined USE_TUTOR
	UTIL_ShowTutor( id, TUTOR_RED, 6.0, "Achievement progress:^n%s (%i/%i)", szName, iProgress, iNeededToGain );
#else
	engclient_print( id, engprint_center, "^nAchievement Progress:^n%s (%i/%i)", szName, iProgress, iNeededToGain );
#endif
}

AwardAchievement( const id, const iAchievement, const Achievement[ AchievementData ] ) {
#if defined USE_TUTOR
	UTIL_ShowTutor( id, TUTOR_GREEN, 8.0, "Achievement unlocked:^n%s", Achievement[ Achv_Name ] );
#endif
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	ColorChat( 0, Red, "%s %s^1 has earned the achievement^4 %s^1.", Prefix, szName, Achievement[ Achv_Name ] );
	
	if( is_user_alive( id ) )
		emit_sound( id, CHAN_VOICE, "events/task_complete.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	else
		client_cmd( id, "spk ^"events/task_complete.wav^"" );
	
	new iReturn;
	ExecuteForward( g_iForwards[ Fwd_Unlock ], iReturn, id, iAchievement );
}

public NativeHaveAchievement( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	new iAchievement = get_param( 2 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "HaveAchievement: index out of bounds for id (%i)", id );
		return 0;
	}
	else if( !IsAchievement( iAchievement ) ) {
		log_error( AMX_ERR_BOUNDS, "HaveAchievement: index out of bounds for iAchievement (%i)", id );
		return 0;
	}
	
	new Achievement[ AchievementData ], Progress[ ProgressData ];
	ArrayGetArray( g_aAchievements, iAchievement, Achievement );
	ArrayGetArray( g_aProgress[ id ], iAchievement, Progress );
	
	return bool:( Progress[ Progress_Num ] >= Achievement[ Achv_NeededToGain ] );
}

public NativeSetLeaderBoard( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "SetLeaderBoard: index out of bounds for id (%i)", id );
		return 0;
	}
	else if( !g_iPlayerId[ id ] )
		return 0;
	
	log_to_file( LogFile, "[Warning] SetLeaderBoard called! This function is not implented yet!" );
	
//	new szName[ 32 ], iValue = get_param( 3 );
//	get_string( 2, szName, 31 );
	
//	SQL_QueryMe( "INSERT INTO `Leaderboard` VALUES ('%i','%s','%i') ON DUPLICATE KEY UPDATE `Value` = '%i'",
//		g_iPlayerId[ id ], szName, iValue, iValue );
	
	return 1;
}

public NativeGetPlayerId( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "GetPlayerId: index out of bounds for id (%i)", id );
		return 0;
	}
	
	return g_iPlayerId[ id ];
}

public NativeGetProgress( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	new iAchievement = get_param( 2 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "GetProgress: index out of bounds for id (%i)", id );
		return 0;
	}
	else if( !IsAchievement( iAchievement ) ) {
		log_error( AMX_ERR_BOUNDS, "GetProgress: index out of bounds for iAchievement (%i)", id );
		return 0;
	}
	
	new Progress[ ProgressData ];
	ArrayGetArray( g_aProgress[ id ], iAchievement, Progress );
	
	return Progress[ Progress_Num ];
}

public NativeGetUnlocksCount( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	
	if( id == 0 ) {
		return g_iTotalAchievs;
	}
	else if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "GetUnlocksCount: index out of bounds for id (%i)", id );
		return 0;
	}
	
	return UTIL_CountUnlocks( id );
}

public NativeRegisterAchievement( const iPlugin, const iParams ) {
	new Achievement[ AchievementData ], iPos = ArraySize( g_aAchievements );
	
	new szName[ 64 ];
	get_string( 1, Achievement[ Achv_Name ], 31 );
	SQL_QuoteString( g_hSqlConnection, szName, 63, Achievement[ Achv_Name ] );
	
	new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT `Id`, `NeededToGain`, `ProgressModule` \
	FROM `%s` WHERE `Name` = '%s'", TABLE_ACHIEVS, szName );
	
	if( !SQL_Execute( hQuery ) ) {
		new szQuery[ 256 ];
		SQL_QueryError( hQuery, szQuery, 255 );
		
		log_to_file( LogFile, "[Error] %s", szQuery );
		
		SQL_FreeHandle( hQuery );
		
		return -1;
	}
	
	if( !SQL_NumResults( hQuery ) ) {
		Achievement[ Achv_NeededToGain ]   = get_param( 3 );
		Achievement[ Achv_ProgressModule ] = CalcProgressMsgIncrement( Achievement[ Achv_NeededToGain ] );
		
		new szDesc[ 128 ];
		get_string( 2, szDesc, 127 );
		SQL_QuoteString( g_hSqlConnection, szDesc, 127, szDesc );
		
		hQuery = SQL_PrepareQuery( g_hSqlConnection, "INSERT INTO `%s` (`Name`, `Description`, `NeededToGain`, `ProgressModule`) VALUES ('%s', '%s', '%i', '%i')",
			TABLE_ACHIEVS, szName, szDesc, Achievement[ Achv_NeededToGain ], Achievement[ Achv_ProgressModule ] );
		
		if( !SQL_Execute( hQuery ) ) {
			new szQuery[ 256 ];
			SQL_QueryError( hQuery, szQuery, 255 );
			
			log_to_file( LogFile, "[Error] %s", szQuery );
			
			SQL_FreeHandle( hQuery );
			
			return -1;
		}
		
		hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT `Id` FROM `%s` WHERE `Name` = '%s'", TABLE_ACHIEVS, szName );
		
		if( !SQL_Execute( hQuery ) ) {
			new szQuery[ 256 ];
			SQL_QueryError( hQuery, szQuery, 255 );
			
			log_to_file( LogFile, "[Error] %s", szQuery );
			
			SQL_FreeHandle( hQuery );
			
			return -1;
		}
		
		new szPlugin[ 32 ];
		get_plugin( iPlugin, szPlugin, 31 );
		
		log_to_file( LogFile, "[%s] Registering new achievement: %s", szPlugin, Achievement[ Achv_Name ] );
	} else {
		Achievement[ Achv_NeededToGain ]   = SQL_ReadResult( hQuery, 1 );
		Achievement[ Achv_ProgressModule ] = SQL_ReadResult( hQuery, 2 );
	}
	
	g_szDummy[ 0 ] = Achievement[ Achv_SqlIndex ] = SQL_ReadResult( hQuery, 0 );
	
	SQL_FreeHandle( hQuery );
	TrieSetCell( g_tSqlIndexes, g_szDummy, iPos );
	ArrayPushArray( g_aAchievements, Achievement );
	
	new EmptyProgress[ ProgressData ];
	
	for( new i = 1; i <= g_iMaxPlayers; i++ )
		ArrayPushArray( g_aProgress[ i ], EmptyProgress );
	
	g_iTotalAchievs++; // g_iTotalAchievs = iPos + 1;
	
	return iPos;
}

public CmdPlayedTime( const id ) {
	new szTime[ 128 ], iPlayTime = ( get_user_time( id ) / 60 ) + g_iPlayTime[ id ];
	
	get_time_length( id, iPlayTime, timeunit_minutes, szTime, 127 );
	
	if( !szTime[ 0 ] )
		szTime = "...";
	
	ColorChat( id, Red, "%s^1 You have played for^4 %s", Prefix, szTime );
}

public CmdAchievements( const id ) {
	new szAuthId[ 30 ], szLink[ 364 ];
	get_user_authid( id, szAuthId, 39 );
	
	format( szAuthId, 355, "%s&r=%i", szAuthId, random_num( 1000, 9999 ) ); // Avoid stupid IE caching
	
	copy( szLink, 363, g_szHTML );
	replace( szLink, 363, "%steam%", szAuthId );
	
	show_motd( id, szLink, MotdTitle );
}

public CmdSay( const id ) {
	new szSaid[ 50 ];
	read_args( szSaid, 49 );
	remove_quotes( szSaid );
	
	if( szSaid[ 0 ] == '/' || szSaid[ 0 ] == '.' )
	{
		new szCmd[ 8 ], szNick[ 32 ];
		parse( szSaid, szCmd, 7, szNick, 31 );
		
		if( equali( szCmd[ 1 ], "stats" ) ) {
			new iPlayer;
			
			if( szNick[ 0 ] && !( iPlayer = FindPlayer( id, szNick ) ) )
				return;
			
			if( !iPlayer ) iPlayer = id;
			
			if( !g_iPlayerId[ iPlayer ] ) {
				ColorChat( id, Red, "%s^1 You can't view stats of this player.", Prefix );
				return;
			}
			
			new szAuthId[ 30 ], szLink[ 364 ];
			get_user_authid( iPlayer, szAuthId, 39 );
			
			format( szAuthId, 355, "%s&r=%i", szAuthId, random_num( 1000, 9999 ) ); // Avoid stupid IE caching
			
			copy( szLink, 363, g_szHTML );
			replace( szLink, 363, "%steam%", szAuthId );
			
			show_motd( id, szLink, MotdTitle );
		}
		else if( equali( szCmd[ 1 ], "rank" ) ) {
			if( !g_iTotalAchievs ) {	
				ColorChat( id, Red, "%s^1 There are no achievements.", Prefix );
				return;
			}
			
			new iPlayer;
			
			if( szNick[ 0 ] && !( iPlayer = FindPlayer( id, szNick ) ) )
				return;
			
			if( !iPlayer ) iPlayer = id;
			
			if( !g_iPlayerId[ iPlayer ] ) {
				ColorChat( id, Red, "%s^1 You can't view rank of this player.", Prefix );
				return;
			}
			
			new iCount    = UTIL_CountUnlocks( iPlayer ),
				iPercent  = iCount * 100 / g_iTotalAchievs, szTime[ 7 ],
				iPlayTime = ( get_user_time( iPlayer ) / 60 ) + g_iPlayTime[ iPlayer ];
			
			SteamPlaytime
			
			if( iPlayer != id ) {
				new szName[ 32 ];
				get_user_name( iPlayer, szName, 31 );
				
				ColorChat( id, Red, "%s %s^1 : Achievements earned:^4 %i/%i^1.^3 (%i%%).^1 Play Time:^4 %s hours^1.",
					Prefix, szName, iCount, g_iTotalAchievs, iPercent, szTime );
			} else
				ColorChat( id, Red, "%s^1 Achievements earned:^4 %i/%i^1.^3 (%i%%).^1 Play Time:^4 %s hours^1.",
					Prefix, iCount, g_iTotalAchievs, iPercent, szTime );
		}
	}
}

FindPlayer( id, const szArg[ ] ) {
	new iPlayer = find_player( "bl", szArg );
	
	if( iPlayer ) {
		if( iPlayer != find_player( "blj", szArg ) ) {
			ColorChat( id, Red, "%s^1 There are more clients matching to your argument.", Prefix );
			
			return 0;
		}
	}
	else if( szArg[ 0 ] == '#' && szArg[ 1 ] ) {
		iPlayer = find_player( "k", str_to_num( szArg[ 1 ] ) );
	}
	
	if( !iPlayer ) {
		ColorChat( id, Red, "%s^1 Player with that name or userid not found.", Prefix );
		
		return 0;
	}
	
	if( !g_iPlayerId[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't see rank of this player.", Prefix );
		
		return 0;
	}
	
	return iPlayer;
}

#if defined USE_TUTOR
#if defined SHOW_TUTOR_ON_SPAWN
public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {
		if( !g_iPlayerId[ id ] ) {
			return;
		}
		
		new szTime[ 7 ], iPlayTime = ( get_user_time( id ) / 60 ) + g_iPlayTime[ id ];
		
		SteamPlaytime
		
		UTIL_ShowTutor( id, TUTOR_BLUE, 7.0, "You have played %s hours^nYou have %i of %i achievements^n^nVisit us at www.my-run.de",
			szTime, UTIL_CountUnlocks( id ), g_iTotalAchievs );
	}
}
#endif // SHOW_TUTOR_ON_SPAWN

public TaskCloseTutor( id ) {
	id -= TutorTask;
	
	if( g_iPlayerId[ id ] ) {
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgTutorClose, _, id );
		message_end( );
	}
}

UTIL_ShowTutor( const id, const TutorColors:iColor, const Float:flStayTime = 5.0, const szText[ ], any:... ) {
	remove_task( id + TutorTask );
	
	new szMessage[ 128 ];
	vformat( szMessage, 127, szText, 5 );
	
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgTutorText, _, id );
	write_string( szMessage );
	write_byte( 0 );
	write_short( -1 );
	write_short( 0 ); // id && !is_user_alive(id)
	write_short( _:iColor );
	message_end( );
	
	set_task( flStayTime, "TaskCloseTutor", id + TutorTask );
}
#endif // USE_TUTOR

SQL_QueryMe( const szQuery[ ], any:... ) {
	new szMessage[ 256 ];
	vformat( szMessage, 255, szQuery, 2 );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleQuery", szMessage );
}

SQL_IsFail( const iFailState, const iError, const szError[ ] ) {
	if( iFailState == TQUERY_CONNECT_FAILED ) {
		log_to_file( LogFile, "[Error] Could not connect to SQL database: %s", szError );
		return true;
	}
	else if( iFailState == TQUERY_QUERY_FAILED ) {
		log_to_file( LogFile, "[Error] Query failed: %s", szError );
		return true;
	}
	else if( iError ) {
		log_to_file( LogFile, "[Error] Error on query: %s", szError );
		return true;
	}
	
	return false;
}

public HandleQuery( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	SQL_IsFail( iFailState, iError, szError );
}

//-----------------------------------------------------------------------------
// Purpose: calculates at how many steps we should show a progress notification
// Function was found in Steam API :-)
//-----------------------------------------------------------------------------
CalcProgressMsgIncrement( const iGoal ) {
	// by default, show progress at every 25%
	new iIncrement = iGoal / 4;
	// if goal is not evenly divisible by 4, try some other values
	if( 0 != ( iGoal % 4 ) ) {
		if( 0 == ( iGoal % 3 ) ) {
			iIncrement = iGoal / 3;
		}
		else if( 0 == ( iGoal % 5 ) ) {
			iIncrement = iGoal / 5;
		}
		// otherwise stick with divided by 4, rounded off
	}
	
	// don't show progress notifications for less than 5 things
	return ( iIncrement < 5 ? 0 : iIncrement );
}

//-----------------------------------------------------------------------------
// Purpose: sets the specified component bit # if it is not already.
//			If it does get set, evaluate if this satisfies an achievement
// Function was found in Steam API :-)
//-----------------------------------------------------------------------------
public NativeSetComponentBit( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	new iAchievement = get_param( 2 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "SetAchievementComponentBit: index out of bounds for id (%i)", id );
		return;
	}
	else if( !IsAchievement( iAchievement ) ) {
		log_error( AMX_ERR_BOUNDS, "SetAchievementComponentBit: index out of bounds for iAchievement (%i)", id );
		return;
	}
	
	new Achievement[ AchievementData ], Progress[ ProgressData ];
	ArrayGetArray( g_aAchievements, iAchievement, Achievement );
	ArrayGetArray( g_aProgress[ id ], iAchievement, Progress );
	
	// check if we already have this achievement...
	if( Progress[ Progress_Num ] >= Achievement[ Achv_NeededToGain ] )
		return;
	
	if( get_playersnum( ) <= 2 ) {
		UTIL_ShowTutor( id, TUTOR_RED, 4.0, "Ignoring achievement progress^ndue to lack of players." );
		
		return;
	}
	
	// calculate which bit this component corresponds to
	new iBitMask = ( 1 << get_param( 3 ) );
	
	// see if we already have gotten this component
	if( 0 == ( iBitMask & Progress[ Progress_Bits ] ) ) {
		// new component, set the bit and increment the count
		Progress[ Progress_Bits ] |= iBitMask;
		
		new iCount = Progress[ Progress_Num ] = UTIL_CountNumBitsSet( Progress[ Progress_Bits ] );
		
		if( iCount == Achievement[ Achv_NeededToGain ] ) {
			AwardAchievement( id, iAchievement, Achievement );
		} else {
#if defined DEBUG
			ColorChat( 0, Red, "^1Component^4 %d^1 for achievement^3 %s^1 found. (plr: %i)", iBitMask, Achievement[ Achv_Name ], id );
#endif
			
			ShowProgressNotification( id, iCount, Achievement[ Achv_Name ], Achievement[ Achv_NeededToGain ] );
		}
		
		ArraySetArray( g_aProgress[ id ], iAchievement, Progress );
		
		UTIL_SetProgress( id, Achievement[ Achv_SqlIndex ], iCount, Progress[ Progress_Bits ] );
	}
#if defined DEBUG
	else
		ColorChat( 0, Red, "^1Component^4 %d^1 for achievement^3 %s^1 found, but already had that component. (plr: %i)",
			iBitMask, Achievement[ Achv_Name ], id );
#endif
}

UTIL_CountNumBitsSet( nVar ) { // C++ Convert
	new const gNumBitsInNibble[ 16 ] = {
		0, // 0000 = 0
		1, // 0001 = 1
		1, // 0010 = 2
		2, // 0011 = 3
		1, // 0100 = 4
		2, // 0101 = 5
		2, // 0110 = 6
		3, // 0111 = 7
		1, // 1000 = 8
		2, // 1001 = 9
		2, // 1010 = 10
		3, // 1011 = 11
		2, // 1100 = 12
		3, // 1101 = 13
		3, // 1110 = 14
		4, // 1111 = 15
	};
	
	new nNumBits;

	while( nVar > 0 ) {
		// Look up and add in bits in the bottom nibble
		nNumBits += gNumBitsInNibble[ nVar & 0x0f ];
		
		// Shift one nibble to the right
		nVar >>= 4;
	}
	
	return nNumBits;
}

UTIL_CountUnlocks( const id ) {
	if( !g_iPlayerId[ id ] )
		return 0;
	
	new iCount, Achievement[ AchievementData ], Progress[ ProgressData ];
	
	for( new i; i < g_iTotalAchievs; i++ ) {
		ArrayGetArray( g_aAchievements, i, Achievement );
		ArrayGetArray( g_aProgress[ id ], i, Progress );
		
		if( Progress[ Progress_Num ] >= Achievement[ Achv_NeededToGain ] )
			iCount++;
	}
	
	return iCount;
}
