#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <chatcolor>

#define GH_ADMIN       ADMIN_RESERVATION
#define GH_TASK        1338
#define GH_MATCHROUND  15

new const g_szPrefix[] = "Console:";

enum {
	GH_NONE = 0,
	GH_KNIFE,
	GH_START,
	GH_FIRSTHALF,
	GH_ONLINE
}

new g_iMenu_NewAdmin;
new g_iCountdown;
new g_iOldAdmin;
new g_iStatus;
new g_iRounds;
new g_iPoints[ 33 ];

new g_szFilename[ 128 ];
new g_szTempFile[ 128 ];
new g_szReportFile[ 128 ];

new bool:g_bDemo[ 33 ];
new bool:g_bDefusing[ 33 ];

/*
	Skill points formula:
	
	New Skill = ( ( 9 * _GetOldSkill( id ) ) + ( ( 20 * g_iPoints[ id ] * 2 ) / g_iRounds ) ) / 10
*/

enum _:eScore {
	SCORE_T,
	SCORE_CT
}

enum _:eHalf {
	FIRST,
	LAST
}

new g_iHalf;
new g_iTeamScore[ eScore ][ eHalf ];

public plugin_init( ) {
	register_plugin( "Gather-Network", "1.0", "xPaw" );
	
	register_forward( FM_ClientUserInfoChanged, "FwdClientUserInfoChanged" );
	
	register_event( "SendAudio",   "EventWin_TS",       "a",   "2=%!MRAD_terwin" );
	register_event( "SendAudio",   "EventWin_CT",       "a",   "2=%!MRAD_ctwin" );
	register_event( "CurWeapon",   "EventCurWeapon",    "be",  "1=1", "2!29" );
	register_event( "DeathMsg",    "EventDeath",        "a" );
	register_event( "TeamScore",   "EventTeamScore",    "a" );
	
	register_logevent( "EventRoundEnd",     2, "1=Round_End" );
	register_logevent( "EventDefuse",       3, "2=Begin_Bomb_Defuse_Without_Kit", "2=Begin_Bomb_Defuse_With_Kit" );
	register_logevent( "EventBomb_Planted", 3, "2=Planted_The_Bomb" );
//	register_logevent( "EventBomb_SaveDef", 3, "2=Defused_The_Bomb" );
//	register_logevent( "EventBomb_SaveDef", 6, "3=Target_Saved" );
//	register_logevent( "EventBomb_Bombed",  6, "3=Target_Bombed" );
	
	register_clcmd( "say",             "CmdSay",      GH_ADMIN );
	
	register_clcmd( "say .warmup",     "CmdWarmup",   GH_ADMIN );
	register_clcmd( "say .ready",      "CmdReady",    GH_ADMIN );
	register_clcmd( "say .pass",       "CmdSayPass",  GH_ADMIN );
	register_clcmd( "say .start",      "CmdStart",    GH_ADMIN );
	register_clcmd( "say .stop",       "CmdStop",     GH_ADMIN );
	
	register_clcmd( "say .replaceme",  "CmdReplaceME" );
	register_clcmd( "say .score",      "CmdScore" );
//	register_clcmd( "say .teams",      "CmdTeams" );
	
	g_iStatus     = GH_NONE;
	
	g_iMenu_NewAdmin = menu_create( "\rDo you want to be an admin of match?", "HandleNewAdmin" );
	menu_additem( g_iMenu_NewAdmin, "Yes", "1", 0 );
	menu_additem( g_iMenu_NewAdmin, "No", "2", 0 );
	
	new szDataDir[ 64 ];
	get_localinfo( "amxx_datadir", szDataDir, charsmax( szDataDir ) );
	
	formatex( g_szFilename, charsmax( g_szFilename ), "%s/GatherNetwork.ini", szDataDir );
	formatex( g_szTempFile, charsmax( g_szTempFile ), "%s/GatherTemp.ini", szDataDir );
	formatex( g_szReportFile, charsmax( g_szReportFile ), "%s/GatherReports.txt", szDataDir );
}

public CmdWarmup( id ) {
	if( !( get_user_flags( id ) & GH_ADMIN ) )
		return PLUGIN_CONTINUE;
	
	if( g_iStatus != GH_NONE )
		return PLUGIN_CONTINUE;
	
	server_cmd( "mp_roundtime 3" );
	server_cmd( "mp_freezetime 0" );
	server_cmd( "mp_startmoney 16000" );
	server_cmd( "mp_friendlyfire 0" );
	server_cmd( "sv_restart 1" );
	
	set_hudmessage( 128, 128, 128, 0.02, 0.25, 0, 6.0, 3.0 );
	show_hudmessage( 0, "Warmup settings loaded !" );
	
	return PLUGIN_CONTINUE;
}

public CmdStart( id ) {
	if( !( get_user_flags( id ) & GH_ADMIN ) )
		return PLUGIN_CONTINUE;
	
	if( g_iStatus != GH_NONE )
		return PLUGIN_CONTINUE;
	
	g_iStatus = GH_START;
	g_iOldAdmin  = id;
	
	new iPlayers[ 32 ], iNum, iPlayer, szNick[ 20 ], szNewNick[ 32 ], szTag[ 6 ], CsTeams:iTeam;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		iTeam = cs_get_user_team( iPlayer );
		
		if( iTeam != CS_TEAM_T || iTeam != CS_TEAM_CT )
			continue;
		
		if( get_user_flags( iPlayer ) & GH_ADMIN )
			szTag = "<vip>";
		else if ( g_iOldAdmin == iPlayer )
			szTag = "<a>";
		
		get_user_name( iPlayer, szNick, charsmax( szNick ) );
		
		formatex( szNewNick, charsmax( szNewNick ), "%s.%s<%d>%s", iTeam == CS_TEAM_T ? "b" : "a", szNick, g_iPoints[ iPlayer ], szTag );
		
		client_cmd( iPlayer, "name ^"%s^"", szNewNick );
	}
	
	set_hudmessage( 128, 128, 128, 0.02, 0.25, 0, 6.0, 12.0 );
	show_hudmessage( 0, "The match will start when admin types ^".ready^"" );
	
	return PLUGIN_CONTINUE;
}

public CmdStop( id ) {
	if( !( get_user_flags( id ) & GH_ADMIN ) )
		return PLUGIN_CONTINUE;
	
	if( g_iStatus == GH_NONE )
		return PLUGIN_CONTINUE;
	
	new iScore_CT = g_iTeamScore[ SCORE_CT ][ FIRST ] + g_iTeamScore[ SCORE_CT ][ LAST ];
	new iScore_TS = g_iTeamScore[ SCORE_T ][ FIRST ] + g_iTeamScore[ SCORE_T ][ LAST ];
	
	if( iScore_TS > iScore_CT )
		ColorChat( 0, Red, "^4%s^3 Terrorists^1 won with score^4 %i:%i", g_szPrefix, iScore_TS, iScore_CT );
	else if( iScore_CT > iScore_TS )
		ColorChat( 0, Blue, "^4%s^3 Counter-Terrorists^1 won with score^4 %i:%i", g_szPrefix, iScore_CT, iScore_TS );
	else
		ColorChat( 0, DontChange, "%s^1 Draw, the score is^4 %i:%i", g_szPrefix, iScore_CT, iScore_TS );
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		// Add points for won team, around 40.
		
		if( g_bDemo[ iPlayer ] ) {
			ColorChat( 0, DontChange, "%s^1 Upload fucking demo please :)" );
		}
	}
	
	server_cmd( "sv_restart 1" );
	
//	set_task( 30.0, "KickAll" );
	
	return PLUGIN_CONTINUE;
}

public CmdReady( id ) {
	if( !( get_user_flags( id ) & GH_ADMIN ) )
		return PLUGIN_CONTINUE;
	
	if( g_iStatus != GH_START )
		return PLUGIN_CONTINUE;
	
	g_iHalf = FIRST;
	g_iCountdown = 6;
	
	set_hudmessage( 128, 128, 128, 0.02, 0.25, 0, 6.0, 3.0 );
	show_hudmessage( 0, "Starting !" );
	
	set_task( 1.0, "ReadyCountDown", GH_TASK, _, _, "b" );
	
	return PLUGIN_CONTINUE;
}

public ReadyCountDown( ) {
	g_iCountdown--;
	
	switch( g_iCountdown ) {
		case 5: ColorChat( 0, DontChange, "%s^1 Starting match...", g_szPrefix );
		case 1..4: ColorChat( 0, DontChange, "%s^1 %i...", g_szPrefix, g_iCountdown );
		case 0: {
			g_iStatus = GH_ONLINE;
			g_iRounds = 0;
			arrayset( g_bDefusing, false, 32 );
			arrayset( g_bDemo, false, 32 );
			
			remove_task( GH_TASK );
			
			ReadySettings( );
			
			new szPassword[ 6 ];
			for( new i = 0; i < sizeof szPassword; i++ )
				szPassword[ i ] = random_num( 'a', 'z' );
			
			server_cmd( "sv_password ^"%s^"", szPassword );
			
			ColorChat( 0, Blue, "^4%s Ready!^1 The password on the server:^3 %s", g_szPrefix, szPassword );
			
			server_cmd( "sv_restart 1" );
		}
	}
}

public ReadySettings() {
	server_cmd( "sv_stepsize 18; mp_freezetime 7; mp_footsteps 1; mp_friendlyfire 1; mp_c4timer 35" );
	server_cmd( "mp_fadetoblack 0; mp_roundtime 1.75; mp_startmoney 800; mp_timelimit 0" );
	server_cmd( "mp_forcecamera 2; mp_forcechasecam 2" );
	
	set_task( 2.0, "ReadyHaveFun" );
	
	return PLUGIN_HANDLED;
}

public ReadyHaveFun( ) {
	set_hudmessage( 255, 170, 85, -1.0, 0.10, 0, 6.0, 5.0 );
	show_hudmessage( 0, "Have fun playing on Gather-Network" );
}

public CmdSayPass( id ) {
	if( !( get_user_flags( id ) & GH_ADMIN ) )
		return PLUGIN_CONTINUE;
	
	ColorChat( 0, Blue, "^4%s^1 The password on the server:^3 %s", g_szPrefix, get_cvar_num( "sv_password" ) );
	
	return PLUGIN_HANDLED;
}

public CmdSay( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_CONTINUE;
	
	new szSaid[ 160 ];
	read_args( szSaid, charsmax( szSaid ) );
	remove_quotes( szSaid );
	
	if( szSaid[ 0 ] != '.' )
		return PLUGIN_CONTINUE;
	
	new szCmd[ 10 ], szValue[ 32 ], szReason[ 118 ];
	parse( szSaid, szCmd, charsmax( szCmd ), szValue, charsmax( szValue ), szReason, charsmax( szReason ) );
	
	if( equal( szCmd, ".ff" ) ) {
		if( equal( szValue, "on" ) )
			server_cmd( "mp_friendlyfire 1" );
		else if( equal( szValue, "off" ) )
			server_cmd( "mp_friendlyfire 0" );
	}
	else if( equal( szCmd, ".kick" ) ) {
		new iPlayer = GHFindPlayer( id, szValue, true );
		
		if( !iPlayer )
			return PLUGIN_CONTINUE;
		
		if( get_user_flags( iPlayer ) & GH_ADMIN ) {
			ColorChat( id, DontChange, "%s^1 You can`t kick premium players!", g_szPrefix );
			
			return PLUGIN_CONTINUE;
		}
		
		new szAdmin[ 32 ], szNick[ 32 ], szDate[ 64 ];
		get_user_name( id, szAdmin, charsmax( szAdmin ) );
		get_user_name( iPlayer, szNick, charsmax( szNick ) );
		get_time( "%m.%d.%Y - %H:%M:%S", szDate, charsmax( szDate ) );
		
		server_cmd( "kick #%d", get_user_userid( iPlayer ) );
		
		log_amx( "Kick: ^"%s^" by ^"%s^" [ %s ]", szNick, szAdmin, szDate );
		
		return PLUGIN_CONTINUE;
	}
	else if( equal( szCmd, ".newadmin" ) ) {
		new iPlayer = GHFindPlayer( id, szValue );
		
		if( !iPlayer )
			return PLUGIN_CONTINUE;
		
		if( !( get_user_flags( iPlayer ) & GH_ADMIN ) ) {
			ColorChat( id, DontChange, "%s^1 This player can`t be gather admin, because he doesn`t have premium!", g_szPrefix );
			
			return PLUGIN_CONTINUE;
		}
		
		menu_display( iPlayer, g_iMenu_NewAdmin, 0 );
		
		g_iOldAdmin = id;
		
		return PLUGIN_CONTINUE;
	}
	else if( equal( szCmd, ".replace" ) ) {
		new iPlayer = GHFindPlayer( id, szValue );
		
		if( !iPlayer )
			return PLUGIN_CONTINUE;
		
		ColorChat( id, DontChange, "%s^1 Admin accepted your request to leave. he is searching for a replacer, wait...", g_szPrefix );
		
		set_hudmessage( 128, 128, 128, 0.02, 0.25, 0, 6.0, 12.0 );
		show_hudmessage( iPlayer, "Dont leave the server until new player joins^nThe bot will kick you automaticly..." );
		
		return PLUGIN_CONTINUE;
	}
	else if( equal( szCmd, ".demo" ) ) {
		if( g_iStatus != GH_ONLINE )
			return PLUGIN_CONTINUE;
		
		new iPlayer = GHFindPlayer( id, szValue );
		
		if( !iPlayer )
			return PLUGIN_CONTINUE;
		
		if( iPlayer == id ) {
			ColorChat( id, DontChange, "%s^1 You can`t record demo on yourself!", g_szPrefix );
			
			return PLUGIN_CONTINUE;
		}
		else if( get_user_flags( iPlayer ) & GH_ADMIN ) {
			ColorChat( id, DontChange, "%s^1 You can`t record demo on admin!", g_szPrefix );
			
			return PLUGIN_CONTINUE;
		}
		else if( g_bDemo[ iPlayer ] ) {	
			ColorChat( id, DontChange, "%s^1 Already recording demo on this player!", g_szPrefix );
			
			return PLUGIN_CONTINUE;
		}
		
		new szName[ 32 ], szIP[ 16 ], szSteamID[ 35 ], szDate[ 64 ], szSDate[ 11 ];
		get_user_name( iPlayer, szName, charsmax( szName ) );
		get_user_ip( iPlayer, szIP, charsmax( szIP ), 1 );
		get_user_authid( iPlayer, szSteamID, charsmax( szSteamID ) );
		
		get_time( "%m/%d/%Y - %H:%M:%S", szDate, charsmax( szDate ) );
		get_time( "%m_%d_%Y", szSDate, charsmax( szSDate ) );
		
		client_cmd( iPlayer, "stop; record ^"_Gather_%s^" ", szSDate );
		
		ColorChat( id, DontChange, "%s^1 Demo recording started on %s!", g_szPrefix, szName );
		ColorChat( iPlayer, DontChange, "%s^1 Admin started recording demo on you! Do not stop it, or you will get ban!", g_szPrefix );
		
		console_print( iPlayer, " " );
		console_print( iPlayer, "***************************" );
		console_print( iPlayer, "* Nick: %s", szName );
		console_print( iPlayer, "* SteamID: %s", szSteamID );
		console_print( iPlayer, "* IP: %s", szIP );
		console_print( iPlayer, "* Date: %s", szDate );
		console_print( iPlayer, "***************************" );
		console_print( iPlayer, " " );
		
		g_bDemo[ iPlayer ] = true;
		
		return PLUGIN_CONTINUE;
	}
	else if( equal( szCmd, ".report" ) ) {
		new iPlayer = GHFindPlayer( id, szValue );
		
		if( !iPlayer )
			return PLUGIN_CONTINUE;
		
		new szAdmin[ 32 ], szNick[ 32 ], szIP[ 16 ], szSteamID[ 35 ], szDate[ 64 ], szTemp[ 120 ];
		get_user_name( id, szAdmin, charsmax( szAdmin ) );
		get_user_name( iPlayer, szNick, charsmax( szNick ) );
		get_user_ip( iPlayer, szIP, charsmax( szIP ), 1 );
		get_user_authid( iPlayer, szSteamID, charsmax( szSteamID ) );
		get_time( "%m.%d.%Y - %H:%M:%S", szDate, charsmax( szDate ) );
		
		if( !file_exists( g_szReportFile ) ) {
			write_file( g_szReportFile, "   * Reported Players *", -1 );
			write_file( g_szReportFile, " * Gather Plugin by xPaw *", -1 );
			write_file( g_szReportFile, " ", -1 );
		}
		
		write_file( g_szReportFile, "**********************************", -1 );
		formatex( szTemp, charsmax( szTemp ), "* ^"%s^" reported by ^"%s^"", szNick, szAdmin );
		write_file( g_szReportFile, szTemp, -1 );
		
		formatex( szTemp, charsmax( szTemp ), "* Date: %s", szDate );
		write_file( g_szReportFile, szTemp, -1 );
		
		formatex( szTemp, charsmax( szTemp ), "* SteamID: %s", szSteamID );
		write_file( g_szReportFile, szTemp, -1 );
		
		formatex( szTemp, charsmax( szTemp ), "* IP: %s", szIP );
		write_file( g_szReportFile, szTemp, -1 );
		
		formatex( szTemp, charsmax( szTemp ), "* Reason: %s", szReason );
		write_file( g_szReportFile, szTemp, -1 );
		write_file( g_szReportFile, "**********************************", -1 );
		write_file( g_szReportFile, " ", -1 );
		
		ColorChat( id, DontChange, "%s %s^1 has been reported!", g_szPrefix, szNick );
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdReplaceME( id ) {
	if( g_iStatus == GH_NONE )
		return PLUGIN_CONTINUE;
	
	new szNick[ 32 ], iPlayers[ 32 ], iNum, iPlayer;
	get_user_name( id, szNick, charsmax( szNick ) );
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( get_user_flags( iPlayer ) & GH_ADMIN )
			ColorChat( iPlayer, Red, "^4%s %s^1 asked if he can leave the match. If you agree with that type^3 .replace %s", g_szPrefix, szNick, szNick );
	}
	
	return PLUGIN_CONTINUE;
}

public CmdScore( id ) {
	if( g_iStatus != GH_ONLINE )
		return PLUGIN_HANDLED;
	
	if( g_iHalf == FIRST ) {
		if( g_iTeamScore[ SCORE_T ][ FIRST ] > g_iTeamScore[ SCORE_CT ][ FIRST ] )
			ColorChat( id, Red, "^4%s^3 Terrorists^1 leading with score^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_T ][ FIRST ], g_iTeamScore[ SCORE_CT ][ FIRST ] );
		else if( g_iTeamScore[ SCORE_CT ][ FIRST ] > g_iTeamScore[ SCORE_T ][ FIRST ] )
			ColorChat( id, Blue, "^4%s^3 Counter-Terrorists^1 leading with score^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_CT ][ FIRST ], g_iTeamScore[ SCORE_T ][ FIRST ] );
		else
			ColorChat( id, DontChange, "%s^1 Teams are tied!^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_CT ][ FIRST ], g_iTeamScore[ SCORE_T ][ FIRST ] );
	} else {
		new iScore_CT = g_iTeamScore[ SCORE_CT ][ FIRST ] + g_iTeamScore[ SCORE_CT ][ LAST ];
		new iScore_TS = g_iTeamScore[ SCORE_T ][ FIRST ] + g_iTeamScore[ SCORE_T ][ LAST ];
		
		if( iScore_TS > iScore_CT )
			ColorChat( id, Red, "^4%s^3 Terrorists^1 leading with score^4 %i:%i", g_szPrefix, iScore_TS, iScore_CT );
		else if( iScore_CT > iScore_TS )
			ColorChat( id, Blue, "^4%s^3 Counter-Terrorists^1 leading with score^4 %i:%i", g_szPrefix, iScore_CT, iScore_TS );
		else
			ColorChat( id, DontChange, "%s^1 Teams are tied!^4 %i:%i", g_szPrefix, iScore_CT, iScore_TS );
	}
	
	return PLUGIN_HANDLED;
}

/*public CmdTeams( id ) {
	new szNames[ 2 ][ 196 ], szName[ 32 ], iPlayers[ 32 ], iNum, CsTeams:iTeam, iHere, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		iTeam = cs_get_user_team( iPlayer );
		
		if( iTeam != CS_TEAM_T || iTeam != CS_TEAM_CT )
			continue;
		
		switch( iTeam ) {
			case CS_TEAM_T: iHere = 0;
			case CS_TEAM_CT: iHere = 1;
		}
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		if( szNames[ iHere ][ 0 ] )
			formatex( szNames[ iHere ], charsmax( szNames[] ), "%s, %s", szNames[ iHere ], szName );
		else
			copy( szNames[ iHere ], charsmax( szNames[] ), szName );
	}
	
	client_print( id, print_chat, "Team TS: %s", szNames[ 0 ] );
	client_print( id, print_chat, "Team CT: %s", szNames[ 1 ] );
	
	return PLUGIN_HANDLED;
}*/

// FORWARDS 'n' EVENTS
////////////////////////////////////////////////////////////////////
public FwdClientUserInfoChanged( id, szBuffer ) {
	if( g_iStatus != GH_ONLINE )
		return FMRES_IGNORED;
	
	new szName[ 32 ], szOldName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	engfunc( EngFunc_InfoKeyValue, szBuffer, "name", szOldName, charsmax( szOldName ) );
	
	if( equali( szOldName, szName ) )
		return FMRES_IGNORED;
	
	engfunc( EngFunc_SetClientKeyValue, id, szBuffer, "name", szName );
	
	return FMRES_SUPERCEDE;
}

public EventWin_TS( ) {
	if( g_iStatus != GH_ONLINE )
		return PLUGIN_CONTINUE;
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) != CS_TEAM_T )
			continue;
		
		g_iPoints[ iPlayer ] += 20;
	}
	
	return PLUGIN_CONTINUE;
}

public EventWin_CT( ) {
	if( g_iStatus != GH_ONLINE )
		return PLUGIN_CONTINUE;
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) != CS_TEAM_CT )
			continue;
		
		g_iPoints[ iPlayer ] += 20;
	}
	
	return PLUGIN_CONTINUE;
}

public EventTeamScore( ) {
	if( g_iStatus != GH_ONLINE )
		return PLUGIN_CONTINUE;
	
	new szTeam[ 2 ];
	read_data( 1, szTeam, 1 );
	
	if( szTeam[ 0 ] == 'T' )
		g_iTeamScore[ SCORE_T ][ g_iHalf ] = read_data( 2 );
	else
		g_iTeamScore[ SCORE_CT ][ g_iHalf ] = read_data( 2 );
	
	return PLUGIN_CONTINUE;
}

public EventRoundEnd( ) {
	if( g_iStatus != GH_ONLINE )
		return PLUGIN_CONTINUE;
	
	arrayset( g_bDefusing, false, 32 );
	
	g_iRounds++;
	
	if( g_iHalf == LAST ) {
		new iScore_CT = g_iTeamScore[ SCORE_CT ][ FIRST ] + g_iTeamScore[ SCORE_CT ][ LAST ];
		new iScore_TS = g_iTeamScore[ SCORE_T ][ FIRST ] + g_iTeamScore[ SCORE_T ][ LAST ];
		
		if( iScore_CT >= GH_MATCHROUND + 1 ) {
			// ct win
		}
		else if( iScore_TS >= GH_MATCHROUND + 1 ) {
			// t win
		} else {
			// draw
		}
	}
	
	if( g_iRounds >= GH_MATCHROUND ) {
		g_iStatus = GH_FIRSTHALF;
		g_iHalf = LAST;
		g_iRounds = 0;
		
		if( g_iTeamScore[ SCORE_T ][ FIRST ] > g_iTeamScore[ SCORE_CT ][ FIRST ] )
			ColorChat( 0, Red, "%s^3 Terrorists^1 leading with score^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_T ][ FIRST ], g_iTeamScore[ SCORE_CT ][ FIRST ] );
		else if( g_iTeamScore[ SCORE_CT ][ FIRST ] > g_iTeamScore[ SCORE_T ][ FIRST ] )
			ColorChat( 0, Blue, "%s^3 Counter-Terrorists^1 leading with score^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_CT ][ FIRST ], g_iTeamScore[ SCORE_T ][ FIRST ] );
		else
			ColorChat( 0, DontChange, "%s^1 Teams are tied!^4 %i:%i", g_szPrefix, g_iTeamScore[ SCORE_CT ][ FIRST ], g_iTeamScore[ SCORE_T ][ FIRST ] );
		
		new iPlayers[ 32 ], iNum, iPlayer, iPoints, iOldPoints, szSteamID[ 35 ], szData[ 6 ];
		get_players( iPlayers, iNum );
		
		for( new i; i < iNum; i++ ) {
			iPlayer = iPlayers[ i ];
			
			switch( cs_get_user_team( iPlayer ) ) {
				case CS_TEAM_T: cs_set_user_team( iPlayer, CS_TEAM_CT );
				case CS_TEAM_CT: cs_set_user_team( iPlayer, CS_TEAM_T );
				default: continue;
			}
			
			get_user_authid( iPlayer, szSteamID, charsmax( szSteamID ) );
			
			iOldPoints = _GetOldSkill( iPlayer );
			iPoints = ( ( 9 * iOldPoints ) + ( ( 20 * g_iPoints[ iPlayer ] * 2 ) / g_iRounds ) ) / 10;
			g_iPoints[ iPlayer ] = iPoints;
			
			num_to_str( iPoints, szData, charsmax( szData ) );
			
			VaultSetData( szSteamID, szData );
		}
		
		server_cmd( "sv_restart 1" );
		
		client_print( 0, print_chat, "%i rounds passed!", GH_MATCHROUND );
	}
	
	return PLUGIN_CONTINUE;
}

public EventCurWeapon( id )
	if( g_iStatus == GH_KNIFE )
		engclient_cmd( id, "weapon_knife" );

public EventDeath( ) {
	if( g_iStatus != GH_ONLINE )
		return;
	
	new iKiller = read_data( 1 );
	new iVictim = read_data( 2 );
	
	if( iKiller == iVictim )
		RemovePoints( iKiller, 20 );
	else {
		if( cs_get_user_team( iKiller ) == cs_get_user_team( iVictim ) )
			RemovePoints( iKiller, 30 );
		else
			g_iPoints[ iKiller ] += 10;
	}
}

public EventBomb_Planted( ) {
	if( g_iStatus != GH_ONLINE )
		return;
	
	new id = GetLogUserIndex( );
	
	if( id > 0 ) {
		g_iPoints[ id ] += 13;
		
		new iPlayers[ 32 ], iNum, iPlayer;
		get_players( iPlayers, iNum );
		
		for( new i; i < iNum; i++ ) {
			iPlayer = iPlayers[ i ];
			
			if( id == iPlayer )
				continue;
			
			if( cs_get_user_team( iPlayer ) != CS_TEAM_T )
				continue;
			
			g_iPoints[ iPlayer ] += 5;
		}
	}
}

public EventDefuse( ) {
	if( g_iStatus != GH_ONLINE )
		return;
	
	new id = GetLogUserIndex( );
	
	if( id > 0 && !g_bDefusing[ id ] ) {
		g_bDefusing[ id ] = true;
		g_iPoints[ id ] += 8;
	}
}

// STUFF
////////////////////////////////////////////////////////////////////
public HandleNewAdmin( id, iMenu, iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		return PLUGIN_HANDLED;
	}
	
	new szData[ 10 ], szName[ 64 ], iAccess, iCallback;
	menu_item_getinfo( iMenu, iItem, iAccess, szData, 9, szName, 63, iCallback );
	new iKey = str_to_num( szData );
	
	switch( iKey ) {
		case 1: {
			new szName[ 32 ];
			get_user_name( id, szName, charsmax( szName ) );
			
			ColorChat( g_iOldAdmin, DontChange, "%s^4 %s^1 accepted to be the new admin of the gather!", g_szPrefix, szName );
			
			g_iOldAdmin = id;
		}
		case 2: {
			new szName[ 32 ];
			get_user_name( id, szName, charsmax( szName ) );
			
			ColorChat( g_iOldAdmin, DontChange, "%s^1 Unfortunately player^4 %s^1 is not accepted to be gather`s admin!", g_szPrefix, szName );
			
		}
	}
	
	return PLUGIN_HANDLED;
}

stock GHFindPlayer( id, const szArg[ ], bool:bIgnoreBots = false ) {
	new iPlayer = find_player( "bl", szArg );
	
	if( iPlayer ) {
		if( iPlayer != find_player( "blj", szArg ) ) {
			ColorChat( id, DontChange, "%s^1 There are more clients matching to your argument.", g_szPrefix );
			
			return 0;
		}
	}
	else if( szArg[ 0 ] == '#' && szArg[ 1 ] ) {
		iPlayer = find_player( "k", str_to_num( szArg[ 1 ] ) );
	}
	
	if( !iPlayer ) {
		ColorChat( id, DontChange, "%s^1 Client with that name or userid not found.", g_szPrefix );
		
		return 0;
	}
	if( is_user_bot( iPlayer ) && !bIgnoreBots ) {
		ColorChat( id, DontChange, "%s^1 That action can't be performed on bot.", g_szPrefix );
		
		return 0;
	}
	
	return iPlayer;
}

stock GetLogUserIndex( ) {
	new szLogUser[ 80 ], szName[ 32 ];
	read_logargv( 0, szLogUser, charsmax( szLogUser ) );
	parse_loguser( szLogUser, szName, charsmax( szName ) );
	
	return get_user_index( szName );
}

// POINTS STUFF
////////////////////////////////////////////////////////////////////
public client_authorized( id )
	if( !is_user_bot( id ) )
		_LoadPoints( id );

public client_disconnect( id )
	if( !is_user_bot( id ) )
		_SavePoints( id );

stock RemovePoints( id, iRemove ) {
	new iPoints = g_iPoints[ id ];
	new iNew = iPoints - iRemove;
	
	if( iNew < 0 )
		g_iPoints[ id ] = 0;
	else
		g_iPoints[ id ] = iNew;
}

public _GetOldSkill( id ) {
	new szSteamID[ 35 ], szData[ 6 ];
	get_user_authid( id, szSteamID, charsmax( szSteamID ) );
	
	if( VaultGetData( szSteamID, szData, charsmax( szData ) ) )
		return str_to_num( szData );
	
	return 0;
}

public _LoadPoints( id ) {
	new szSteamID[ 35 ], szData[ 6 ];
	get_user_authid( id, szSteamID, charsmax( szSteamID ) );
	
	if( VaultGetData( szSteamID, szData, charsmax( szData ) ) )
		g_iPoints[ id ] = str_to_num( szData );
	else
		g_iPoints[ id ] = 0;
}

public _SavePoints( id ) {
	new szSteamID[ 35 ], szData[ 6 ];
	get_user_authid( id, szSteamID, charsmax( szSteamID ) );
	
	num_to_str( g_iPoints[ id ], szData, charsmax( szData ) );
	
	VaultSetData( szSteamID, szData );
}

stock VaultGetData( const key[], data[], len ) {
	new vault = fopen(g_szFilename, "rt");
	new _data[512], _key[64];
	
	while( !feof(vault) ) {
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1, data, len);
		
		if( equal(_key, key) ) {
			fclose(vault);
			
			return 1;
		}
	}
	
	fclose(vault);
	
	copy(data, len, "");
	
	return 0;
}

stock VaultSetData( const key[], const data[] ) {
	new file = fopen(g_szTempFile, "wt");
	new vault = fopen(g_szFilename, "rt");
	new _data[512], _key[64], _other[3];
	new bool:replaced = false;
	
	while( !feof(vault) ) {
		fgets(vault, _data, sizeof(_data) - 1);
		parse(_data, _key, sizeof(_key) - 1, _other, sizeof(_other) - 1);
		
		if( equal(_key, key) && !replaced ) {
			fprintf(file, "^"%s^" ^"%s^"^n", key, data);
			
			replaced = true;
		} else {
			fputs(file, _data);
		}
	}
	
	if( !replaced )
		fprintf(file, "^"%s^" ^"%s^"^n", key, data);
	
	fclose(file);
	fclose(vault);
	
	delete_file(g_szFilename);
	
	while( !rename_file( g_szTempFile, g_szFilename, 1 ) ) { }
}

/*
public knife_cmd(id,level,cid)
{
	if(!cmd_access(id,level,cid,1))
		return PLUGIN_HANDLED;
	server_cmd("sv_restart 1");
	g_WarmUp = true;
	set_task(1.0,"ShowCountDown",1234,_,_,"b",_);
	return PLUGIN_HANDLED;
}
public ShowCountDown()
{
	set_hudmessage(255, 255, 255, 0.03, 0.20, 0, 6.0, 12.0);
	show_hudmessage(0, "Knives only: %d seconds",g_Seconds);
	g_Seconds--;
	
	if(g_Seconds <= 0)
	{
		if(task_exists(1234))
			remove_task(1234);
		g_WarmUp = false;
		g_Finish = true;
		server_cmd("sv_restart 1");
		return;
	}
}
*/
