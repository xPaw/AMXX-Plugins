// COMMANDS
// ==================================================================================

public CmdSay( const id ) {
	new szMessage[ 42 ];
	read_args( szMessage, 41 );
	remove_quotes( szMessage );
	
	if( szMessage[ 0 ] != '/' )
		return PLUGIN_CONTINUE;
	
	new szCmd[ 9 ], szArg[ 32 ];
	parse( szMessage, szCmd, 8, szArg, 31 );
	
	if( equal( szCmd, "/weapon" ) ) {
#if defined XJ_BUILD
		if( kz_is_in_cup( id ) )
			return PLUGIN_CONTINUE;
#endif
		
		if( CheckFlood( id ) )
			return PLUGIN_CONTINUE;
		
		trim( szArg );
		strtolower( szArg );
		
		if( !is_user_alive( id ) ) {
			ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
			return PLUGIN_HANDLED;
		}
		else if( !szArg[ 0 ] ) {
			ColorChat( id, Red, "%s^1 Usage:^4 /weapon <weapon name>", Prefix );
			return PLUGIN_HANDLED;
		}
		else if( TrieKeyExists( g_tRestrictedWeapons, szArg ) ) {
			ColorChat( id, Red, "%s^1 Weapon^4 %s^1 is not allowed!", Prefix, szArg );
			return PLUGIN_HANDLED;
		}
		
		formatex( szMessage, 41, "weapon_%s", szArg );
		
		if( get_weaponid( szMessage ) ) {
			give_item( id, szMessage );
			return PLUGIN_HANDLED;
		} else {
			ColorChat( id, Red, "%s^1 Weapon^4 %s^1 is unknown.", Prefix, szArg );
			return PLUGIN_HANDLED;
		}
	}
	else if( equal( szCmd, "/tele" ) || equal( szCmd, "/tp" ) ) {
#if defined XJ_BUILD
		if( kz_is_in_cup( id ) )
			return PLUGIN_CONTINUE;
#endif
		
		if( CheckFlood( id ) )
			return PLUGIN_CONTINUE;
		
		if( !g_bAdmin[ id ] ) {
			ColorChat( id, Red, "%s^1 Only^4 VIPs^1 have access to this command.", Prefix );
			return PLUGIN_CONTINUE;
		}
		
		trim( szArg );
		
		if( !is_user_alive( id ) ) {
			ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
			return PLUGIN_HANDLED;
		}
		else if( !szArg[ 0 ] ) {
			ColorChat( id, Red, "%s^1 Usage:^4 /tele <player name>", Prefix );
			return PLUGIN_HANDLED;
		}
		
		new iPlayer = CommandTarget( id, szArg );
		
		if( iPlayer ) {
			if( iPlayer == id ) {
				ColorChat( id, Red, "%s^1 You can't teleport to yourself.", Prefix );
				return PLUGIN_HANDLED;
			}
			else if( !is_user_alive( id ) ) {
				ColorChat( id, Red, "%s^1 You can't teleport to dead player.", Prefix );
				return PLUGIN_HANDLED;
			}
			else if( is_user_bot( id ) ) {
				ColorChat( id, Red, "%s^1 You can't teleport to a bot.", Prefix );
				return PLUGIN_HANDLED;
			}
			
			new szName[ 32 ];
			get_user_name( iPlayer, szName, 31 );
			
			ColorChat( id, Red, "%s^1 You have been teleported to^3 %s^1.", Prefix, szName );
			CheatDetect( id, "Teleport" );
			
			// ---
			
			new Float:vOrigin[ 3 ], Float:flGravity = entity_get_float( iPlayer, EV_FL_gravity );
			entity_get_vector( iPlayer, EV_VEC_origin, vOrigin );
			
			entity_set_float ( id, EV_FL_gravity  , flGravity );
			entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
			ForceDuck( id );
			entity_set_origin( id, vOrigin );
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdBlock( const id )
	return PLUGIN_HANDLED;

#if defined XJ_BUILD
public CmdTop( const id )
	show_motd( id, g_szHTML, "XJ Top15" );
#else
public CmdTop( const id )
	show_motd( id, g_szHTML, "[ mY.RuN ] Kreedz Top by xPaw" );
#endif

public CmdScout( const id ) {
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) )
		return PLUGIN_HANDLED;
#endif
	
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	give_item( id, "weapon_scout" );
	
	ColorChat( id, Red, "%s^1 You've got an scout!", Prefix );
	
	return PLUGIN_CONTINUE;
}

public CmdSpectator( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	if( !is_user_alive( id ) ) // Just in case of bug....
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) == CS_TEAM_SPECTATOR ) {
		ColorChat( id, Red, "%s^1 You are already a^4 spectator^1, say '^3/ct^1' to change your team.", Prefix );
		
		return PLUGIN_HANDLED;
	}
	
	ExecuteHam( Ham_Item_PreFrame, id ); // speedfix
	
	if( g_flStartTime[ id ] ) {
		Pause( id, true, true );
		
		ColorChat( id, Red, "%s^1 You became a^4 spectator^1, your timer has been paused.", Prefix );
	} else
		ColorChat( id, Red, "%s^1 You became a^4 spectator^1.", Prefix );
	
	entity_get_vector( id, EV_VEC_v_angle, g_vSavedAngles[ id ] );
	entity_get_vector( id, EV_VEC_origin,  g_vSavedOrigin[ id ] );
	
	user_kill( id, 1 );
	entity_set_int( id, EV_INT_deadflag, DEAD_DISCARDBODY );
	
	SetUserTeam( id, CS_TEAM_SPECTATOR );
	
	emessage_begin( MSG_BROADCAST, g_iMsgTeamInfo );
	ewrite_byte( id );
	ewrite_string( "SPECTATOR" );
	emessage_end( );
	
	return PLUGIN_HANDLED;
}

public CmdCounterTerrorist( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	if( cs_get_user_team( id ) == CS_TEAM_CT ) {
		ColorChat( id, Red, "%s^1 You are already a^4 counter-terrorist^1, say '^3/spec^1' to change your team.", Prefix );
		
		return PLUGIN_HANDLED;
	}
	
//	cs_set_user_team( id, CS_TEAM_CT );
	
	SetUserTeam( id, CS_TEAM_CT );
	
	emessage_begin( MSG_BROADCAST, g_iMsgTeamInfo );
	ewrite_byte( id );
	ewrite_string( "CT" );
	emessage_end( );
	
	ExecuteHamB( Ham_CS_RoundRespawn, id );
	
	if( !user_has_weapon( id, CSW_KNIFE ) )
		give_item( id, "weapon_knife" );
	
	if( !user_has_weapon( id, CSW_USP ) ) {
		give_item( id, "weapon_usp" );
		
		cs_set_user_bpammo( id, CSW_USP, 100 );
	}
	
	entity_set_vector( id, EV_VEC_angles, g_vSavedAngles[ id ] );
	entity_set_int   ( id, EV_INT_fixangle, 1 );
	entity_set_origin( id, g_vSavedOrigin[ id ] );
	GoCheckEffect( id, g_vSavedOrigin[ id ] );
	
	if( g_flPaused[ id ] ) {
		Pause( id );
		ColorChat( id, Red, "%s^1 You became a^4 counter-terrorist^1, your timer is paused. Say '^4/unpause^1' to continue.", Prefix );
	} else
		ColorChat( id, Red, "%s^1 You became a^4 counter-terrorist^1.", Prefix );
	
	return PLUGIN_HANDLED;
}

public CmdCheckPoint( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while in cup.", Prefix );
		return PLUGIN_HANDLED;
	}
#endif
	
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !IsPlayerOnGround( id ) && entity_get_int( id, EV_INT_movetype ) != MOVETYPE_FLY ) {
		ColorChat( id, Red, "%s^1 You must be on the ground to do this.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	g_iCheckPoints[ id ]++;
	
	new bool:bAlternate = g_bCpAlternate[ id ];
	
	entity_get_vector( id, EV_VEC_origin , g_vCheckPoints[ id ][ bAlternate ] );
	entity_get_vector( id, EV_VEC_v_angle, g_vCheckAngles[ id ][ bAlternate ] );
	g_vCheckAngles[ id ][ bAlternate ][ 2 ] = entity_get_float( id, EV_FL_gravity );
	g_bCpAlternate[ id ] = !bAlternate;
	
	set_hudmessage( 128, 128, 128, 0.01, 0.90, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	ShowSyncHudMsg( id, g_iHudSync, "Checkpoint #%i saved.", g_iCheckPoints[ id ] );
	
	set_hudmessage( 128, 128, 128, 0.01, 0.70, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	
	FindPlayers // Spectator message
		ShowSyncHudMsg( iPlayer, g_iHudSync, "Checkpoint #%i saved.", g_iCheckPoints[ id ] );
	EndPlayers
	
	return PLUGIN_HANDLED;
}

public CmdGoCheck( id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while in cup.", Prefix );
		return PLUGIN_HANDLED;
	}
#endif
	
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !g_vCheckPoints[ id ][ 0 ][ 0 ] ) {
		ColorChat( id, Red, "%s^1 You don't have any checkpoints.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	GoCheck( id, !g_bCpAlternate[ id ] );
	
	set_hudmessage( 128, 128, 128, 0.01, 0.90, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	
	if( g_iGoChecks[ id ] == 1 && !g_bProDisabled[ id ] && g_flStartTime[ id ] ) {
		ShowSyncHudMsg( id, g_iHudSync, "Gocheck #%i. Pro15 has been disabled.", g_iGoChecks[ id ] );
	} else
		ShowSyncHudMsg( id, g_iHudSync, "Gocheck #%i.", g_iGoChecks[ id ] );
	
	set_hudmessage( 128, 128, 128, 0.01, 0.70, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	
	FindPlayers // Spectator message
		ShowSyncHudMsg( iPlayer, g_iHudSync, "Gocheck #%i.", g_iGoChecks[ id ] );
	EndPlayers
	
	return PLUGIN_HANDLED;
}

public CmdStuck( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while in cup.", Prefix );
		return PLUGIN_HANDLED;
	}
#endif
	
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_iCheckPoints[ id ] < 2 || !g_vCheckPoints[ id ][ 0 ][ 0 ] || !g_vCheckPoints[ id ][ 1 ][ 0 ] ) {
		ColorChat( id, Red, "%s^1 You must have at least^4 2^1 checkpoints to do this.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	new bool:bAlternate = g_bCpAlternate[ id ];
	g_bCpAlternate[ id ] = !bAlternate;
	GoCheck( id, bAlternate );
	
	set_hudmessage( 128, 128, 128, 0.01, 0.90, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	ShowSyncHudMsg( id, g_iHudSync, "Previous checkpoint loaded." );
	
	set_hudmessage( 128, 128, 128, 0.01, 0.70, 0, 2.0, 2.0, 0.1, 0.2, 2 );
	
	FindPlayers // Spectator message
		ShowSyncHudMsg( iPlayer, g_iHudSync, "Previous checkpoint loaded." );
	EndPlayers
	
	return PLUGIN_HANDLED;
}

public CmdPause( const id ) {
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 Your timer is paused already. Say '^4/unpause^1' to continue.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !g_flStartTime[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't pause without having timer running.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !IsPlayerOnGround( id ) && entity_get_int( id, EV_INT_movetype ) != MOVETYPE_FLY ) {
		ColorChat( id, Red, "%s^1 You must be on the ground to do this.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	entity_get_vector( id, EV_VEC_v_angle, g_vSavedAngles[ id ] );
	entity_get_vector( id, EV_VEC_origin , g_vSavedOrigin[ id ] );
	
	Pause( id, true );
	
	return PLUGIN_HANDLED;
}

public CmdUnPause( const id ) {
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 Your timer is not paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	Pause( id, false );
	
	entity_set_vector( id, EV_VEC_angles, g_vSavedAngles[ id ] );
	entity_set_int   ( id, EV_INT_fixangle, 1 );
	entity_set_origin( id, g_vSavedOrigin[ id ] );
	
	return PLUGIN_HANDLED;
}

public CmdStart( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
	
	vOrigin = g_vUserStart[ id ];
	vAngles = g_vUserAngle[ id ];
	
	if( vOrigin[ 0 ] == 0.0 ) {
		vOrigin = g_vStartOrigin;
		vAngles = g_vStartAngles;
		
		if( vOrigin[ 0 ] == 0.0 ) {
			ColorChat( id, Red, "%s^4 We're sorry.^1 No start is set for this map yet.", Prefix );
			return PLUGIN_HANDLED;
		}
	}
	
	entity_set_vector( id, EV_VEC_angles  , vAngles );
	entity_set_float ( id, EV_FL_gravity  , vAngles[ 2 ] );
	entity_set_int   ( id, EV_INT_fixangle, 1 );
	entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
	entity_set_float ( id, EV_FL_fuser2   , 0.0 );
	ForceDuck( id );
	entity_set_origin( id, vOrigin );
	
	GoCheckEffect( id, vOrigin );
	
	if( entity_get_float( id, EV_FL_health ) < 100.0 )
		entity_set_float( id, EV_FL_health, 100.0 );
	
	ColorChat( id, Red, "%s^1 You have been teleported to the start position.", Prefix );
	
	g_flStartTime[ id ] = 0.0;
	UTIL_ResetRoundTime( id );
	
	return PLUGIN_HANDLED;
}

public CmdNoclip( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while in cup.", Prefix );
		return PLUGIN_HANDLED;
	}
#endif
	
	if( !g_bFinishedMap[ id ] ) {
		ColorChat( id, Red, "%s^1 You have no access to^4 noclip^1. Finish map once to gain the access.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	if( entity_get_int( id, EV_INT_movetype ) == MOVETYPE_WALK ) {
		entity_set_int( id, EV_INT_movetype, MOVETYPE_NOCLIP );
		
		ColorChat( id, Red, "%s^1 Noclip has been^4 enabled^1.", Prefix );
		
		CheatDetect( id, "Noclip" );
	} else {
		entity_set_int( id, EV_INT_movetype, MOVETYPE_WALK );
		
		ColorChat( id, Red, "%s^1 Noclip has been^4 disabled^1.", Prefix );
	}
	
	return PLUGIN_HANDLED;
}

public CmdGodmode( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while in cup.", Prefix );
		return PLUGIN_HANDLED;
	}
#endif
	
	if( !g_bFinishedMap[ id ] ) {
		ColorChat( id, Red, "%s^1 You have no access to^4 godmode^1. Finish map once to gain the access.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "%s^1 You can't do that while dead.", Prefix );
		return PLUGIN_HANDLED;
	}
	else if( g_flPaused[ id ] ) {
		ColorChat( id, Red, "%s^1 You can't do that while paused.", Prefix );
		return PLUGIN_HANDLED;
	}
	
	if( entity_get_float( id, EV_FL_takedamage ) == DAMAGE_AIM ) {
		entity_set_float( id, EV_FL_takedamage, DAMAGE_NO );
		
		ColorChat( id, Red, "%s^1 Godmode has been^4 enabled^1.", Prefix );
		
		CheatDetect( id, "Godmode" );
	} else {
		entity_set_float( id, EV_FL_takedamage, DAMAGE_AIM );
		
		ColorChat( id, Red, "%s^1 Godmode has been^4 disabled^1.", Prefix );
	}
	
	return PLUGIN_HANDLED;
}

public CmdMyBest( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	new szQuery[ 300 ], szSteamId[ 31 ], szData[ 1 ];
	get_user_authid( id, szSteamId, 30 );
	
	formatex( szQuery, 299, "SELECT Time as a, (SELECT count(Time)+1 from %s where Time<a AND Map='%s' \
	AND Type=0 ) as b from %s WHERE SteamID='%s' AND Map='%s' AND Type=0", SqlTable, g_szMap, SqlTable, szSteamId, g_szMap );
	
	szData[ 0 ] = id;
	SQL_ThreadQuery( g_hSqlTuple, "HandleSelectMyBest", szQuery, szData, 1 );
	
	return PLUGIN_CONTINUE;
}

public CmdLeet( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	if( !g_flLeetTime ) {
		ColorChat( id, Red, "%s^4 There is no leet-climber yet.", Prefix );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_iLeet )
		get_user_name( g_iLeet, g_szLeetName, 31 );
	
	new szTime[ 9 ];
	ClimbtimeToString( g_flLeetTime, szTime, 8 );
	
	ColorChat( id, Red, "%s^3 %s^1 is the leet-climber with time^4 %s^1.", Prefix, g_szLeetName, szTime );
	
	return PLUGIN_CONTINUE;
}

public CmdMenu( const id ) {
//	if( CheckFlood( id ) )
//		return PLUGIN_HANDLED;
	
	new hMenu = menu_create( "\rThe Kreedz Menu\w By xPaw\r\R", "HandleKzMenu" );
	
	new szCP[ 22 ], szGC[ 22 ];
	
	if( g_iCheckPoints[ id ] ) {
		formatex( szCP, 21, "Checkpoint \r[%i]", g_iCheckPoints[ id ] );
		
		if( g_iGoChecks[ id ] )
			formatex( szGC, 21, "Gocheck \r[%i]", g_iGoChecks[ id ] );
		else
			formatex( szGC, 21, "Gocheck" );
	} else {
		formatex( szCP, 21, "Checkpoint" );
		formatex( szGC, 21, "Gocheck" );
	}
	
	menu_additem( hMenu, szCP,            "1" );
	menu_additem( hMenu, szGC,            "2" );
	menu_additem( hMenu, "Stuck^n",       "3" );
	menu_additem( hMenu, g_flPaused[ id ] ? "UnPause" : "Pause", "4" );
	menu_additem( hMenu, "Move to Start", "5" );
	menu_additem( hMenu, "Top15^n",       "6" );
	menu_additem( hMenu, ( cs_get_user_team( id ) == CS_TEAM_SPECTATOR ) ? "Move to CT" : "Move to Spectators", "7" );
	menu_additem( hMenu, "Measuring Tool", "8" );
	menu_additem( hMenu, "Invisibility",   "9" );
	menu_additem( hMenu, "Exit", "*" );
	menu_setprop( hMenu, MPROP_PERPAGE, 0 );
	menu_display( id, hMenu, 0 );
	
	return PLUGIN_CONTINUE;
}

public HandleKzMenu( const id, const hMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( hMenu );
		return;
	}
	
	new szData[ 6 ], iKey;
	menu_item_getinfo( hMenu, iItem, iKey, szData, 5, "", 0, iKey );
//	menu_destroy( hMenu );
	
	iKey = str_to_num( szData );
	
	switch( iKey ) {
		case 1: {
			CmdCheckPoint( id );
			CmdMenu( id );
		}
		case 2: {
			CmdGoCheck( id );
			CmdMenu( id );
		}
		case 3: {
			CmdStuck( id );
			CmdMenu( id );
		}
		case 4: {
			if( g_flPaused[ id ] ) {
				entity_set_vector( id, EV_VEC_angles, g_vSavedAngles[ id ] );
				entity_set_int   ( id, EV_INT_fixangle, 1 );
				entity_set_origin( id, g_vSavedOrigin[ id ] );
			} else {
				if( !IsPlayerOnGround( id ) && entity_get_int( id, EV_INT_movetype ) != MOVETYPE_FLY ) {
					ColorChat( id, Red, "%s^1 You must be on the ground to do this.", Prefix );
					menu_display( id, hMenu, 0 );
					return;
				}
				
				entity_get_vector( id, EV_VEC_v_angle, g_vSavedAngles[ id ] );
				entity_get_vector( id, EV_VEC_origin , g_vSavedOrigin[ id ] );
			}
			
			Pause( id, !g_flPaused[ id ] );
			menu_display( id, hMenu, 0 );
		}
		case 5: {
			CmdStart( id );
			menu_display( id, hMenu, 0 );
		}
		case 6: CmdTop( id );
		case 7: {
			if( cs_get_user_team( id ) == CS_TEAM_SPECTATOR )
				CmdCounterTerrorist( id );
			else
				CmdSpectator( id );
		}
		case 8: {
			if( callfunc_begin( "cmdMeasure", "kz_measure.amxx" ) == 1 ) {
				callfunc_push_int( id );
				callfunc_end( );
			} else {
				ColorChat( id, Red, "%s^4 The measuring tool is currently unavailable.", Prefix );
				CmdMenu( id );
			}
		}
		case 9: CmdInvisibility( id );
	}
	
	if( iKey != 4 && iKey != 5 )
		menu_destroy( hMenu );
}

public CmdNightVision( const id ) {
	if( CheckFlood( id ) )
		return;
	
	new bool:bNv = g_bNightVision[ id ] = !g_bNightVision[ id ];
	
	if( bNv )
		entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) | EF_BRIGHTLIGHT );
	else
		entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) & ~EF_BRIGHTLIGHT );
	
	UTIL_FlashLight( id, bNv );
}

#if !defined SURF_BUILD
public CmdWorldRecord( const id ) {
	if( CheckFlood( id ) )
		return PLUGIN_HANDLED;
	
	set_hudmessage( 0, 127, 255, 0.01, 0.2, _, _, 3.5, _, _, 3 );
	show_hudmessage( id, g_szWR );
	
	return PLUGIN_CONTINUE;
}
#endif

public CmdInvisibility( const id ) {
//	if( CheckFlood( id ) )
//		return PLUGIN_HANDLED;
	
	new szMenu[ 90 ];
	formatex( szMenu, 89, "\rKreedz Invisibility^n^n\r1. \wPlayers: \y%s^n\r2. \wWater: %s^n^n\r0. \wExit",
		g_bInvisPlayers[ id ] ? "ON" : "OFF", g_tWaterEntities ? ( g_bInvisWater[ id ] ? "\yON" : "\yOFF" ) : "\dNo water" );
	
	show_menu( id, ( 1 << 0 | 1 << 1 | 1 << 9 ), szMenu, -1, "Invisibility" );
	
	return PLUGIN_HANDLED;
}

public HandleInvisMenu( const id, const iKey ) {
	switch( iKey ) {
		case 0: {
			g_bInvisPlayers[ id ] = !g_bInvisPlayers[ id ];
			
			ColorChat( id, Red, "%s^1 Players are now^4 %svisible^1.", Prefix, g_bInvisPlayers[ id ] ? "in" : "" );
			
			CmdInvisibility( id );
		}
		case 1: {
			if( g_tWaterEntities ) {
				g_bInvisWater[ id ] = !g_bInvisWater[ id ];
				
				ColorChat( id, Red, "%s^1 Water is now^4 %svisible^1.", Prefix, g_bInvisWater[ id ] ? "in" : "" );
			}
			
			CmdInvisibility( id );
		}
		default: return;
	}
}