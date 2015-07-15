#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <chatcolor>

new const g_szPrefix[ ] = "[ mY.RuN ]";
const FL_ONGROUND2 = ( FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER | FL_CONVEYOR | FL_FLOAT );
new g_iTransfer[ 33 ];
new bool:g_btransfered[ 33 ];

public plugin_init( ) {
	register_plugin( "Life Transfer", "1.0", "xPaw" );
	
	register_clcmd( "say", "CmdSay" );
	
	register_event( "HLTV", "EventRoundStart", "a", "1=0", "2=0" );
	
	set_task( 90.0, "fnAdvert", _, _, _, "b" );
}

public EventRoundStart( ) {
	arrayset( g_btransfered, false, 32 );
	arrayset( g_iTransfer, 0, 32 );
}

public fnAdvert( )
	ColorChat( 0, Red, "%s^1 If you want transfer your life to dead player, simply say^4 /transfer <nick>^1.", g_szPrefix);

public client_putinserver( id ) {
	g_btransfered[ id ] = false;
	g_iTransfer[ id ] = 0;
}

public CmdSay( id ) {
	new iArgs[ 42 ], iArg1[ 11 ], iArg2[ 32 ];
	read_args( iArgs, 41 );
	remove_quotes( iArgs );
	
	if( iArgs[ 0 ] != '/' )
		return PLUGIN_CONTINUE;
	
	parse( iArgs, iArg1, 10, iArg2, 32 );
	
	if( equal( iArg1, "/transfer" ) ) {
		if( !is_user_alive( id ) ) {
			ColorChat(id, Red, "%s^x01 You need to be alive to use transfer command!", g_szPrefix);
			
			return PLUGIN_CONTINUE;
		}
		if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) ) {
			ColorChat(id, Red, "%s^x01 You cannot be in the air.", g_szPrefix);
			
			return PLUGIN_CONTINUE;
		}
		
		if( g_btransfered[ id ] ) {
			ColorChat(id, Red, "%s^x01 You already used this command once.", g_szPrefix);
			
			return PLUGIN_CONTINUE;
		}
		
		new iPlayer = FindPlayer( id, iArg2 );
		
		if( iPlayer ) {
			new szName[32];
			get_user_name( iPlayer, szName, 31 );
			
			if( is_user_alive( iPlayer ) ) {
				ColorChat(id, Red, "%s^x04 %s^x01 is already alive :)", g_szPrefix, szName);
				
				return PLUGIN_CONTINUE;
			}
			else if( g_iTransfer[ iPlayer ] > 0 ) {
				ColorChat(id, Red, "%s^x01 Someone already asked to transfer life to^x04 %s^x01!", g_szPrefix, szName);
				
				return PLUGIN_CONTINUE;
			}
			else if( get_user_team( iPlayer ) != get_user_team( id ) ) {
				ColorChat(id, Red, "%s^x04 %s^x01 is not in one team with you!", g_szPrefix, szName);
				
				return PLUGIN_CONTINUE;
			}
			
			ColorChat(id, Red, "%s^x01 Request has been sent to^x04 %s^x01!", g_szPrefix, szName);
			
			new szTitle[ 64 ], szName2[ 32 ];
			get_user_name( id, szName2, 31 );
			formatex( szTitle, 63, "\rDo you want to transfer with\w %s\r?", szName2 );
			
			new iMenu = menu_create( szTitle, "HandleMenu" );
			menu_additem( iMenu, "Yes", "1", 0 );
			menu_additem( iMenu, "No", "2", 0 );
			
			menu_setprop( iMenu, MPROP_EXIT, MEXIT_NEVER );
			menu_display( iPlayer, iMenu, 0 );
			
			g_iTransfer[ iPlayer ] = id;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public HandleMenu( id, iMenu, iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		return PLUGIN_HANDLED;
	}
	
	new szData[ 10 ], szName[ 64 ], iAccess, iCallback;
	menu_item_getinfo( iMenu, iItem, iAccess, szData, 9, szName, 63, iCallback );
	new iKey = str_to_num( szData );
	
	switch( iKey ) {
		case 1: {
			if( !is_user_alive( id ) ) {
				if( is_user_alive( g_iTransfer[ id ] ) ) {
					new szName[ 32 ], szName2[ 32 ];
					get_user_name( id, szName, charsmax( szName ) );
					get_user_name( g_iTransfer[ id ], szName2, charsmax( szName2 ) );
					
					if( IsEnoughInTeam( g_iTransfer[ id ] ) >= 1 ) {
						ColorChat( g_iTransfer[ id ], Red, "%s^4 %s^1 accepted to be the transfered with you!", g_szPrefix, szName );
						
						new Float:flHealth, Float:vOrigin[ 3 ], Float:vAngle[ 3 ];
						pev( g_iTransfer[ id ], pev_origin, vOrigin );
						pev( g_iTransfer[ id ], pev_v_angle, vAngle );
						pev( g_iTransfer[ id ], pev_health, flHealth );
						
						new CsArmorType:iArmorType;
						new iArmor = cs_get_user_armor( g_iTransfer[ id ], iArmorType );
						
						message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
						write_byte( TE_TELEPORT );
						engfunc( EngFunc_WriteCoord, vOrigin[0] );
						engfunc( EngFunc_WriteCoord, vOrigin[1] );
						engfunc( EngFunc_WriteCoord, vOrigin[2] );
						message_end( );
						
						user_silentkill( g_iTransfer[ id ] );
						
						ExecuteHamB( Ham_CS_RoundRespawn, id );
						
						ForceDuck( id );
						fm_entity_set_origin( id, vOrigin );
						set_pev( id, pev_angles, vAngle );
						set_pev( id, pev_fixangle, 1 );
						set_pev( id, pev_velocity, Float:{ 0.0, 0.0, 0.0 } );
						set_pev( id, pev_health, flHealth );
						
						cs_set_user_armor( id, iArmor, iArmorType );
						
						g_btransfered[ g_iTransfer[ id ] ] = true;
						
						ColorChat( 0, Red, "%s^4 %s^1 transfered his life to^4 %s^1.", g_szPrefix, szName2, szName);
					} else {
						ColorChat( g_iTransfer[ id ], Red, "%s^4 %s^1 can`t be transfered with you, because you are last alive in your team!", g_szPrefix, szName );
						ColorChat( id, Red, "%s^4 %s^1 can`t be transfered with you, because he is last alive in his team!", g_szPrefix, szName2 );
					}
				} else
					ColorChat(id, Red, "%s^x01 Transfer man is die now :(", g_szPrefix);
			} else
				ColorChat(id, Red, "%s^x01 You already alive.", g_szPrefix);
			
			g_iTransfer[ id ] = 0;
		}
		case 2: {
			new szName[ 32 ];
			get_user_name( id, szName, charsmax( szName ) );
			
			ColorChat( g_iTransfer[ id ], Red, "%s^1 Unfortunately player^4 %s^1 is not accepted to transfer with you!", g_szPrefix, szName );
			
			g_iTransfer[ id ] = 0;
		}
	}
	
	return PLUGIN_HANDLED;
}

IsEnoughInTeam( id ) {
	new iCount, iTeam = get_user_team( id );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "a" );
	
	for( new i; i < iNum; i++ )
		if( get_user_team( iPlayers[ i ] ) == iTeam && iPlayers[ i ] != id )
			iCount++;
	
	return iCount;
}

ForceDuck( id ) {
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING );
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0,  16.0,  18.0 } );
}

stock fm_entity_set_origin( index, const Float:origin[3] ) {
	new Float:mins[3], Float:maxs[3];
	pev( index, pev_mins, mins );
	pev( index, pev_maxs, maxs );
	engfunc( EngFunc_SetSize, index, mins, maxs );

	return engfunc( EngFunc_SetOrigin, index, origin );
}

stock FindPlayer( id, const szArg[ ] ) {
	new iPlayer = find_player( "bl", szArg );
	
	if( iPlayer ) {
		if( iPlayer != find_player( "blj", szArg ) ) {
			ColorChat( id, Red, "%s^1 There are more clients matching to your argument.", g_szPrefix );
			
			return 0;
		}
	}
	else if( szArg[ 0 ] == '#' && szArg[ 1 ] ) {
		iPlayer = find_player( "k", str_to_num( szArg[ 1 ] ) );
	}
	
	if( !iPlayer ) {
		ColorChat( id, Red, "%s^1 Client with that name or userid not found.", g_szPrefix );
		
		return 0;
	}
	if( iPlayer == id ) {
		ColorChat( id, Red, "%s^1 That action can't be performed on yourself.", g_szPrefix );
		
		return 0;
	}
	if( is_user_bot( iPlayer ) ) {
		ColorChat( id, Red, "%s^1 That action can't be performed on bot.", g_szPrefix );
		
		return 0;
	}
	
	return iPlayer;
}
