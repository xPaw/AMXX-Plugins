#include < amxmodx >
#include < amxmisc >
#include < chatcolor >

new g_iVotes[ 2 ];
new g_iPage[ 33 ];
new g_iKicking[ 33 ];
new g_iPlayers[ 33 ][ 32 ];
new g_szKickReason[ 24 ];
new g_szSteamId[ 40 ];
new bool:g_bVoteIsRunning;
new bool:g_bVoteIsBusy;
new Float:g_flLastVote;

public plugin_init( ) {
	register_plugin( "Vote KickBan", "1.0", "xPaw" );
	
	register_clcmd( "say /votekick",     "CmdOpenMenu" );
	register_clcmd( "say /voteban",      "CmdOpenMenu" );
	register_clcmd( "Enter_Kick_Reason", "CmdReasonHandler" );
	
	register_menucmd( register_menuid( "VK Vote" ), 515, "HandleVote" );
	register_menucmd( register_menuid( "VK YouSure" ), 3, "HandleYouSure" );
	register_menucmd( register_menuid( "VK PlayersMenu" ), 1023, "HandlePlayersMenu" );
}

public CmdReasonHandler( id ) {
	if( !is_user_connected( g_iKicking[ id ] ) )
		return PLUGIN_HANDLED;
	
	if( g_bVoteIsBusy )
		return PLUGIN_HANDLED;
	
	new szKickReason[ 28 ];
	read_args( szKickReason, 27 );
	remove_quotes( szKickReason );
	
	if( !szKickReason[ 4 ] ) {
		ColorChat( id, Red, "[mY.RuN]^4 Reason is too short. Please try again." );
		
		client_cmd( id, "messagemode Enter_Kick_Reason" );
		
		set_hudmessage( 0, 127, 255, -1.0, -1.0, 0, 0.0, 3.5, 0.3, 0.3, -1 );
		show_hudmessage( id, "Please type a valid votekick reason and press enter." );
		
		return PLUGIN_HANDLED;
	}
	else if( szKickReason[ 23 ] ) {
		ColorChat( id, Red, "[mY.RuN]^4 Reason is too long. Please try again." );
		
		client_cmd( id, "messagemode Enter_Kick_Reason" );
		
		set_hudmessage( 0, 127, 255, -1.0, -1.0, 0, 0.0, 3.5, 0.3, 0.3, -1 );
		show_hudmessage( id, "Please type a valid votekick reason and press enter." );
		
		return PLUGIN_HANDLED;
	}
	
	get_user_authid( g_iKicking[ id ], g_szSteamId, 39 );
	formatex( g_szKickReason, 23, szKickReason );
	
	StartVote( id, g_iKicking[ id ] );
	
	return PLUGIN_HANDLED;
}

public CmdOpenMenu( id ) {
	if( get_playersnum( ) < 3 ) {
		ColorChat( id, Red, "[mY.RuN]^1 Minimum of 3 players needed to votekick." );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bVoteIsBusy )
		ShowPlayersMenu( id, g_iPage[ id ] = 0 );
	else {
		new Float:flGametime = get_gametime( );
		
		if( g_flLastVote > flGametime )
			ColorChat( id, Red, "[mY.RuN]^1 You can't use votekick right now.^4 Please wait^3 %i^4 seconds.", floatround( g_flLastVote - flGametime ) );
		else
			g_bVoteIsBusy = false;
	}
	
	return PLUGIN_CONTINUE;
}

ShowPlayersMenu( id, iPage ) {
	if( iPage < 0 )
		return PLUGIN_CONTINUE;
	
	new szName[ 32 ], szMenu[ 256 ], iNum, iStart = iPage * 7, iEnd = iStart + 7;
	get_players( g_iPlayers[ id ], iNum );
	
	if( iStart > iNum ) iStart = iPage = g_iPage[ id ] = 0;
	if( iEnd > iNum ) iEnd = iNum;
	
	new bool:IsAdmin, iPlayer, iLen, iCurrentKey, iKeys = ( 1 << 9 );
	
	iLen = formatex( szMenu[ iLen ], 255, "\rmY.RuN\y - Vote kick^n^n" );
	
	for( new i = iStart; i < iEnd; i++ ) {
		iPlayer = g_iPlayers[ id ][ i ];
		IsAdmin = !!( get_user_flags( iPlayer ) & ADMIN_KICK );
		
		if( !IsAdmin )
			iKeys |= ( 1 << iCurrentKey++ );
		else
			iCurrentKey++
		
		get_user_name( iPlayer, szName, 31 );
		
		iLen += formatex( szMenu[ iLen ], 255 - iLen, "\r%i. %s%s%s^n", iCurrentKey, IsAdmin ? "\d" : "\w", szName, IsAdmin ? " \r[admin]" : "" );
	}
	
	if( iEnd != iNum ) {
		iLen += formatex( szMenu[ iLen ], 255 - iLen, "^n\r9. \wNext" );
		
		iKeys |= ( 1 << 8 );
	}
	
	iLen += formatex( szMenu[ iLen ], 255 - iLen, "^n\r0. \w%s", iPage ? "Back" : "Exit" );
	
	show_menu( id, iKeys, szMenu, -1, "VK PlayersMenu" );
	
	return PLUGIN_CONTINUE;
}

public HandlePlayersMenu( id, iKey ) {
	switch( iKey ) {
		case 8: ShowPlayersMenu( id, ++g_iPage[ id ] );
		case 9: ShowPlayersMenu( id, --g_iPage[ id ] );
		default: ShowMenuAreYouSure( id, g_iPlayers[ id ][ g_iPage[ id ] * 7 + iKey ] );
	}
	
	return PLUGIN_HANDLED;
}

public ShowMenuAreYouSure( id, iKickId ) {
	if( g_bVoteIsBusy )
		return PLUGIN_HANDLED;
	
	if( !is_user_connected( iKickId ) ) {
		ShowPlayersMenu( id, g_iPage[ id ] );
		
		ColorChat( id, Red, "[mY.RuN]^1 This user is not connected anymore." );
		
		return PLUGIN_HANDLED;
	}
	
	if( id == iKickId ) {
		ShowPlayersMenu( id, g_iPage[ id ] );
		
		ColorChat( id, Red, "[mY.RuN]^1 You can't start votekick against yourself." );
		
		return PLUGIN_HANDLED;
	}
	
	if( get_user_flags( iKickId ) & ADMIN_KICK ) {
		ShowPlayersMenu( id, g_iPage[ id ] );
		
		ColorChat( id, Red, "[mY.RuN]^1 You can't start votekick against admin." );
		
		return PLUGIN_HANDLED;
	}
	
	g_iKicking[ id ] = iKickId;
	
	new szName[ 32 ], szMenu[ 256 ];
	get_user_name( iKickId, szName, 31 );
	
	formatex( szMenu, 255, "\yAre you sure you want to votekick:^n\r      %s^n^n\r1. \wYes^n\r2. \wNo", szName );
	
	show_menu( id, ( MENU_KEY_1 + MENU_KEY_2 ), szMenu, -1, "VK YouSure" );
	
	return PLUGIN_HANDLED;
}

public HandleYouSure( id, iKey ) {
	if( iKey != 0 )
		return PLUGIN_HANDLED;
	
	if( g_bVoteIsBusy )
		return PLUGIN_HANDLED;
	
	new iPlayer = g_iKicking[ id ];
	
	if( !is_user_connected( iPlayer ) ) {
		ShowPlayersMenu( id, g_iPage[ id ] );
		
		ColorChat( id, Red, "[mY.RuN]^1 This user is not connected anymore." );
		
		return PLUGIN_HANDLED;
	}
	
	client_cmd( id, "messagemode Enter_Kick_Reason" );
	
	set_hudmessage( 0, 127, 255, -1.0, -1.0, 0, 0.0, 3.5, 0.3, 0.3, -1 );
	show_hudmessage( id, "Please type a valid votekick reason and press enter." );
	
	return PLUGIN_HANDLED;
}

public StartVote( id, iKickId ) {
	g_bVoteIsBusy = true;
	g_bVoteIsRunning = true;
	
	new szName[ 2 ][ 32 ];
	get_user_name( id, szName[ 0 ], 31 );
	get_user_name( iKickId, szName[ 1 ], 31 );
	
	ColorChat( id, Red, "[mY.RuN]^4 %s^1 started a votekick against^4 %s^1, with reason:^4 %s^1.", szName[ 0 ], szName[ 1 ], g_szKickReason );
	
	g_iVotes[ 0 ] = 0;
	g_iVotes[ 1 ] = 0;
	
	new szMenu[ 256 ];
	formatex( szMenu, 255, "\y%s started a votekick!^nDo you want to votekick\r %s\y?^nReason:\w %s^n^n\r1. \wYes^n\r2. \wNo^n^n\r0. \wI do not want to vote!", szName[ 0 ], szName[ 1 ], g_szKickReason );
	
	show_menu( 0, ( MENU_KEY_1 + MENU_KEY_2 + MENU_KEY_0 ), szMenu, -1, "VK Vote" );
	
	g_flLastVote = get_gametime( ) + 180.0;
	
	set_task( 20.0, "VoteEnd", id );
	set_task( 180.0, "AllowVote" );
}

public HandleVote( id, iKey ) {
	if( !g_bVoteIsRunning )
		return PLUGIN_HANDLED;
	
	if( iKey == 0 || iKey == 1 ) {
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		g_iVotes[ iKey ]++;
		
		ColorChat( 0, Red, "[mY.RuN]^4 %s^1 voted %s.", szName, iKey == 1 ? "against" : "for" );
	}
	
	return PLUGIN_HANDLED;
}

public VoteEnd( id ) {
	g_bVoteIsRunning = false;
	
	new Float:TotalVotes = float( g_iVotes[ 0 ] + g_iVotes[ 1 ] );
	
	if( TotalVotes < 3.0 ) {
		ColorChat( 0, Red, "[mY.RuN]^4 Votekick results:^1 Less than 3 people voted, vote cancelled." );
		
		return PLUGIN_HANDLED;
	}
	
	new Percent = floatround( ( g_iVotes[ 0 ] / TotalVotes * 100.0 ) );
	
	ColorChat( 0, Red, "[mY.RuN]^4 Votekick results:^1 Yes (%i) No (%i) Total (%i) Percentage (%i)", g_iVotes[ 0 ], g_iVotes[ 1 ], floatround( TotalVotes ), Percent );
	
	if( Percent <= 40 ) {
		if( is_user_connected( id ) )
			server_cmd( "kick #%i", get_user_userid( id ) );
		
		ColorChat( 0, Red, "[mY.RuN]^4 Votekick results:^1 Less than^4 40^1 percents voted for. Votekicker has been kicked." );
	}
	else if( Percent >= 60 ) {
		ColorChat( 0, Red, "[mY.RuN]^4 Votekick results:^1 More than^4 60^1 percents voted for. User has been banned for^3 10^1 minutes." );
		
		server_cmd( "amx_ban 10 ^"%s^" Votekick: %s", g_szSteamId, g_szKickReason );
	}
	
	return PLUGIN_HANDLED;
}

public AllowVote( ) g_bVoteIsBusy = false;
