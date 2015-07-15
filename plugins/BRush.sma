#include <amxmodx>
#include <fun>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat>

#pragma semicolon 1

enum {
	NONE,
	KNIFE,
	BRUSH,
	SELECTMATES
};

new g_iDied;
new g_iStatus;
new g_iRoundsLeft;
new g_iNeedCTs;
new g_iSelectedMates;
new g_iBombPlanter;
new g_iStripEnt;
new g_iSelector;

new bool:g_bAlreadySelected[ 33 ];
new bool:g_bTotalBlock;
new g_iNewCTs[ 3 ];
new g_iFrags[ 3 ];
new g_szRules[ 300 ];

new g_Cvar_MaxRounds;
new g_iMaxplayers;

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxplayers )

public plugin_init( ) {
	register_plugin( "B Rush", "1.0", "xPaw" );
	
	register_clcmd( "chooseteam",  "CmdJoinTeam" );
	register_clcmd( "jointeam",    "CmdJoinTeam" );
	
//	if( !find_ent_by_class( -1, "func_bomb_target" ) && !find_ent_by_class( -1, "info_bomb_target" ) )
//		pause( "a" );
	
	g_iMaxplayers = get_maxplayers( );
	g_iStatus = NONE;
	g_Cvar_MaxRounds = register_cvar( "brush_maxrounds", "10" );
	
	register_concmd( "brush_start", "cmdAdmin_StartBRush", ADMIN_KICK, "Starts the game of brush" );
	register_concmd( "brush_stop", "cmdAdmin_StopBRush", ADMIN_KICK, "Stops the game of brush" );
	
	register_message( get_user_msgid( "TextMsg" ), "msgTextMsg" );
	
	register_logevent( "EventBombPlanted", 3, "2=Planted_The_Bomb" );
	register_event( "23", "EventBombExplode", "a", "1=17", "6=-105", "7=17" );
	register_event( "SendAudio", "EventCTWin", "a", "2=%!MRAD_ctwin" );
	register_event( "HLTV", "EventRoundStart", "a", "1=0", "2=0" );
	register_event( "CurWeapon", "EventCurWeapon", "be", "1!0" );
	
	register_forward( FM_ClientKill, "FwdClientKill" );
	RegisterHam( Ham_Killed, "player", "fwdHamKilled_Player", 1 );
	RegisterHam( Ham_Spawn,	"player", "fwdHamSpawn_Player", 1 );
	
	// Create Menu
	new iSize = sizeof( g_szRules );
	add( g_szRules, iSize, "\rPrepare to play BRUSH!^n  \dPowered by xPaw^n^n" );
	add( g_szRules, iSize, "\wT's have 5Players And CT's have 3Players!^n" );
	add( g_szRules, iSize, "\wThe T's Have to Rush to B and take out the 3 CT's!^n" );
	add( g_szRules, iSize, "\wNO FLASHES CAN BE USED AT ANY TIME BY BOTH TEAMS!^n" );
	add( g_szRules, iSize, "\wThe CT's cannout rush until there is only 1T left!" );
	add( g_szRules, iSize, "^n^n\r0. \wFuck off, cunt" );
	
	register_menucmd( register_menuid( "BRushRules" ), ( 1 << 9 ), "handleRules" );
}

public CmdJoinTeam( id ) {
	if( g_iStatus != NONE && 0 < get_user_team( id ) < 3 )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public msgTextMsg( ) {
	new szTextMsg[ 15 ];
	get_msg_arg_string( 2, szTextMsg, charsmax( szTextMsg ) );
	
	if( equal( szTextMsg, "#Target_Bombed" ) )
		set_msg_arg_string( 2, "#Terrorists_Win" );
	else if( equal( szTextMsg, "#Target_Saved" ) )
		set_msg_arg_string( 2, "#CTs_Win" );
	
	return PLUGIN_CONTINUE;
}

public plugin_cfg( )
	if( file_exists( "brush.cfg" ) )
		server_cmd( "exec brush.cfg" );

public plugin_precache( ) {
	g_iStripEnt = create_entity( "player_weaponstrip" );
	
	if( is_valid_ent( g_iStripEnt ) )
		DispatchSpawn( g_iStripEnt );
}

// EVENTS
/////////////////////////////////////////////////////////////////////
public EventBombExplode( ) {
	if( g_iStatus != NONE ) {
		g_bTotalBlock = true;
		
		MoveAllTs( );
		
		new szNewCTs[ 3 ][ 32 ], iFragger, bool:AnyCTAndSelect, iCTs;
		for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
			if( is_user_connected( g_iNewCTs[ i ] ) ) {
				get_user_name( g_iNewCTs[ i ], szNewCTs[ i ], charsmax( szNewCTs[] ) );
				MoveCT( g_iNewCTs[ i ] );
				
				iCTs++;
				
				if( g_iFrags[ i ] > 0 ) {
					AnyCTAndSelect = true;
					iFragger = g_iNewCTs[ i ];
				}
				
				g_iNewCTs[ i ] = 0;
			}
		}
		
		g_iNeedCTs = 3 - iCTs;
		
		if( g_iNeedCTs > 0 ) {
			if( !AnyCTAndSelect )
				iFragger = g_iBombPlanter;
			
			ShowSelectMenu( iFragger );
			
			new szName[ 32 ];
			get_user_name( iFragger, szName, 31 );
			ColorChat( 0, RED, "[BRUSH]^4 %s^1 is choosing a player!", szName );
			
			g_iStatus = SELECTMATES;
		} else
			ColorChat( 0, RED, "[BRUSH]^x01 New CTs Are:^x04 %s^x01, ^x04 %s^x01 and^x04 %s", szNewCTs[ 0 ], szNewCTs[ 1 ], szNewCTs[ 2 ] );
		
		g_iRoundsLeft = get_pcvar_num( g_Cvar_MaxRounds );
	}
}

public EventBombPlanted( ) {
	if( g_iStatus != NONE ) {
		new szLogUser[ 80 ], szName[ 32 ];
		read_logargv( 0, szLogUser, charsmax( szLogUser ) );
		parse_loguser( szLogUser, szName, charsmax( szName ) );
		g_iBombPlanter = get_user_index( szName );
		
		for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
			if( g_iNewCTs[ i ] == 0 && !g_bAlreadySelected[ g_iBombPlanter ] ) {
				g_iNewCTs[ i ] = g_iBombPlanter;
				
				g_bAlreadySelected[ g_iBombPlanter ] = true;
				
				break;
			}
		}
	}
}

public EventCurWeapon( id ) {
	if( g_iStatus != NONE ) {
		static iWeapon;
		iWeapon = read_data( 2 );
		
		if( ( g_iStatus == KNIFE && iWeapon != CSW_KNIFE ) || iWeapon == CSW_FLASHBANG )
			engclient_cmd( id, "weapon_knife" );
	}
}

public EventCTWin( )
	if( g_iStatus == BRUSH )
		g_iRoundsLeft--;

public EventRoundStart( ) {
	g_iDied = 0;
	
	if( !g_bTotalBlock ) {
		arrayset( g_iFrags, 0, 2 );
		arrayset( g_iNewCTs, 0, 2 );
		
		if( g_iStatus != SELECTMATES )
			arrayset( g_bAlreadySelected, false, 32 );
		
		if( g_iStatus == KNIFE )
			ColorChat( 0, RED, "[BRUSH]^x01 Its knife round!" );
		else if( g_iStatus == BRUSH )
			ColorChat( 0, RED, "[BRUSH]^x01 CTs need^x04 %i^x01 more round%s to win!", g_iRoundsLeft, g_iRoundsLeft == 1 ? "" : "s" );
	}
}

// ADMIN COMMANDS
/////////////////////////////////////////////////////////////////////
public cmdAdmin_StartBRush( id ) {
	if( !( get_user_flags( id ) & ADMIN_KICK ) )
		return PLUGIN_HANDLED;
	
	if( get_playersnum() != 8 ) {
		console_print( id, "* Need 8 players to start BRush!" );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iStatus != NONE ) {
		console_print( id, "* BRush is already running!" );
		
		return PLUGIN_HANDLED;
	}
	
	console_print( id, "* BRush started!" );
	
	g_iStatus = KNIFE;
	g_bTotalBlock = false;
	
	plugin_cfg( );
	RestartRound( );
	
	return PLUGIN_HANDLED;
}

public cmdAdmin_StopBRush( id ) {
	if( !( get_user_flags( id ) & ADMIN_KICK ) )
		return PLUGIN_HANDLED;
	
	if( g_iStatus == NONE ) {
		console_print( id, "* BRush is not running!" );
		
		return PLUGIN_HANDLED;
	}
	
	console_print( id, "* BRush stopped!" );
	
	ColorChat( 0, RED, "[BRUSH]^x01 Admin forced to stop B Rush!" );
	
	g_bTotalBlock = false;
	g_iStatus = NONE;
	
	RestartRound( );
	
	return PLUGIN_HANDLED;
}

// FORWARDS
/////////////////////////////////////////////////////////////////////
public FwdClientKill( id ) {
	if( !is_user_alive( id ) || g_iStatus == NONE )
		return FMRES_IGNORED;
	
	if( g_iStatus == BRUSH && cs_get_user_team( id ) != CS_TEAM_CT )
		return FMRES_IGNORED;
	
	console_print( id, "You can`t suicide!" );
	
	return FMRES_SUPERCEDE;
}

public fwdHamSpawn_Player( id ) {
	if( is_user_alive( id ) ) {
		if( g_iStatus == KNIFE ) {
		//	strip_user_weapons( id );
			force_use( id, g_iStripEnt );
			give_item( id, "weapon_knife" );
		}
		else if( g_iStatus == SELECTMATES ) {
			force_use( id, g_iStripEnt );
			
			if( g_iSelector == id )
				ShowSelectMenu( id );
		}
	}
}

public fwdHamKilled_Player( id, idAttacker, shouldgib ) {
	if( !IsPlayer( id ) || !IsPlayer( idAttacker ) || g_bTotalBlock )
		return HAM_IGNORED;
	
	new szNewCTs[ 3 ][ 32 ];
	if( g_iStatus == KNIFE ) {
		if( id == idAttacker )
			return HAM_IGNORED;
		
		if( !g_bAlreadySelected[ idAttacker ] ) {
			new bool:bAdded;
			for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
				if( g_iNewCTs[ i ] == 0 ) {
					g_iNewCTs[ g_iDied ] = idAttacker;
					
					g_bAlreadySelected[ idAttacker ] = true;
					
					bAdded = true;
					
					break;
				}
			}
			
			if( bAdded )
				g_iDied++;
		}
		
		if( g_iDied == 3 ) {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum );
			
			for( new i; i < iNum; i++ ) {
				cmdRules( iPlayers[ i ] );
				
				if( cs_get_user_team( iPlayers[ i ] ) == CS_TEAM_CT )
					cs_set_user_team( iPlayers[ i ], CS_TEAM_T );
			}
			
			for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
				if( is_user_connected( g_iNewCTs[ i ] ) ) {
					get_user_name( g_iNewCTs[ i ], szNewCTs[ i ], charsmax( szNewCTs[] ) );
					MoveCT( g_iNewCTs[ i ] );
					
					g_iNewCTs[ i ] = 0;
				}
			}
			
			ColorChat( 0, RED, "[BRUSH]^1 New CTs Are:^4 %s^1 -^4 %s^1 -^4 %s", szNewCTs[ 0 ],  szNewCTs[ 1 ], szNewCTs[ 2 ] );
			
			g_iDied = 0;
			g_iStatus = BRUSH;
			g_iRoundsLeft = get_pcvar_num( g_Cvar_MaxRounds );
			
			RestartRound( );
		}
	}
	else if( g_iStatus == BRUSH ) {
		if( cs_get_user_team( id ) == CS_TEAM_CT ) {
			if( cs_get_user_team( idAttacker ) == CS_TEAM_T ) {
				for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
					if( g_iNewCTs[ i ] == 0 && !g_bAlreadySelected[ idAttacker ] ) {
						g_iNewCTs[ i ] = idAttacker;
						
						g_bAlreadySelected[ idAttacker ] = true;
						
						break;
					} else {
						if( g_iNewCTs[ i ] == idAttacker ) {
							g_iFrags[ i ]++;
							
							break;
						}
					}
				}
			}
			
			g_iDied++;
		}
		
		if( g_iDied == 3 ) {
			g_iDied = 0;
			
			MoveAllTs( );
			
			new iFragger, iFrags;
			for( new i = 0; i < sizeof g_iNewCTs; i++ ) {
				if( is_user_connected( g_iNewCTs[ i ] ) ) {
					get_user_name( g_iNewCTs[ i ], szNewCTs[ i ], charsmax( szNewCTs[] ) );
					MoveCT( g_iNewCTs[ i ] );
					
					if( g_iFrags[ i ] > 0 ) {
						iFragger = g_iNewCTs[ i ];
						iFrags = g_iFrags[ i ];
					}
					
					g_iNewCTs[ i ] = 0;
				}
			}
			
			if( iFragger > 0 ) {
			//	ShowSelectMenu( iFragger );
				
				g_iNeedCTs = iFrags;
				g_iStatus = SELECTMATES;
				g_iSelector = iFragger;
			} else
				ColorChat( 0, RED, "[BRUSH]^x01 New CTs Are:^x04 %s^x01, ^x04 %s^x01 and^x04 %s", szNewCTs[ 0 ], szNewCTs[ 1 ], szNewCTs[ 2 ] );
			
			g_iRoundsLeft = get_pcvar_num( g_Cvar_MaxRounds );
			
			RestartRound( );
		}
	}
	
	return HAM_IGNORED;
}

// SELECT CTS MENU
/////////////////////////////////////////////////////////////////////
public handle_SelectMenu( id, menu, item ) {
	if( item == MENU_EXIT ) {
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	new data[6], iName[64], access, callback;
	menu_item_getinfo(menu, item, access, data, 5, iName, 63, callback);
	new key = str_to_num( data );
	
	AnnouncePlayer( id, key );
	
	return PLUGIN_HANDLED;
}

ShowSelectMenu( id ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new szMenu = menu_create("\r[BRUSH] \wSelect your teammates!\R", "handle_SelectMenu");
	new szName[ 32 ], szNum[ 3 ], iPlayer;
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) == CS_TEAM_T && !g_bAlreadySelected[ iPlayer ] ) {
			get_user_name( iPlayer, szName, charsmax( szName ) );
			
			num_to_str( iPlayer, szNum, charsmax( szNum ) );
			
			menu_additem( szMenu, szName, szNum, 0 );
		}
	}
	
	menu_setprop( szMenu, MPROP_EXIT, MEXIT_NEVER );
	menu_display( id, szMenu, 0 );
	
	if( is_user_bot( id ) )
		set_task( random_float( 0.3, 1.2 ), "SelectRandomPlayer", id );
	else
		set_task( 10.0, "SelectRandomPlayer", id );
}

public SelectRandomPlayer( id )
	AnnouncePlayer( id, GetRandomPlayer( id ) );

GetRandomPlayer( iBlocked ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	new iRandom;
	if( iNum > 0 ) {
		iRandom = iPlayers[ random( iNum ) ];
		
		while( ( iRandom == iBlocked || g_bAlreadySelected[ iRandom ] ) ) {
			iRandom = iPlayers[ random( iNum ) ];
		}
	} else
		iRandom = 0;
	
	return iRandom;
}

public AnnouncePlayer( id, key ) {
	if( g_iSelectedMates <= g_iNeedCTs ) {
		if( IsPlayer( key ) ) {
			remove_task( id );
			
			new szName[ 32 ];
			get_user_name( key, szName, charsmax( szName ) );
			
			ColorChat( 0, RED, "[BRUSH]^x04 %s^x01 has been selected as CT!", szName );
			
			g_bAlreadySelected[ key ] = true;
			
			cs_set_user_team( key, CS_TEAM_CT );
			
			g_iSelectedMates++;
			
			if( g_iSelectedMates < g_iNeedCTs ) {
				ShowSelectMenu( id );
			} else {
				g_iStatus = BRUSH;
				
				ColorChat( 0, RED, "[BRUSH]^x01 CT's are selected! Prepare to the next round!" );
				RestartRound( );
			}
		} else {
			ShowSelectMenu( id );
		}
	}
}

// OTHER STUFF
/////////////////////////////////////////////////////////////////////
MoveAllTs( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ )
		if( cs_get_user_team( iPlayers[ i ] ) == CS_TEAM_CT )
			cs_set_user_team( iPlayers[ i ], CS_TEAM_T );
}

MoveCT( index )
	cs_set_user_team( index, CS_TEAM_CT );

RestartRound( )
	server_cmd( "sv_restart 1" );

public handleRules( id, iKey ) {
	return PLUGIN_HANDLED;
}

public cmdRules( id ) {
	show_menu( id, ( 1 << 9 ), g_szRules, -1, "BRushRules" );
	
	return PLUGIN_HANDLED;
}
