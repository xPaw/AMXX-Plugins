// FORWARDS
// ==================================================================================
public client_PreThink( id ) {
	new Float:flGameTime = get_gametime( );
	
	if( !is_user_alive( id ) ) {
		new iSpec = g_iSpectateId[ id ];
		
		if( iSpec && flGameTime >= g_flLastThink[ id ] ) {
			g_flLastThink[ id ] = flGameTime + 0.89;
			
			if( !g_flStartTime[ iSpec ] )
				return;
			
			static szTime[ 9 ];
			
			ClimbtimeToString( flGameTime - g_flStartTime[ iSpec ], szTime, 8 );
			
			UTIL_DirectorMessage(
				.index       = id, 
				.message     = szTime,
				.red         = 0,
				.green       = 60,
				.blue        = 0,
				.x           = -1.0,
				.y           = 0.8,
				.effect      = 0,
				.fxTime      = 0.0,
				.holdTime    = 0.9,
				.fadeInTime  = 0.0,
				.fadeOutTime = 0.0
			);
		}
		
		return;
	}
	
	HookThink( id );
	
	if( flGameTime >= g_flLastThink[ id ] ) {
		g_flLastThink[ id ] = flGameTime + 0.9;
		
		if( g_flStartTime[ id ] || g_flPaused[ id ] ) {
			new iTime = 1 + floatround( ( g_flPaused[ id ] ? g_flPaused[ id ] : ( flGameTime - g_flStartTime[ id ] ) ) );
			
			message_begin( MSG_ONE_UNRELIABLE, g_iMsgRoundTime, _, id );
			write_short( iTime );
			message_end( );
		}
		
		if( ( entity_get_int( id, EV_INT_movetype ) == MOVETYPE_NOCLIP ) )
			CheatDetect( id, "Noclip" );
		else if( ( entity_get_float( id, EV_FL_takedamage ) == DAMAGE_NO ) )
			CheatDetect( id, "Godmode" );
	}
}

public FwdImpulseFlashLight( const id ) {
	CmdNightVision( id );
	return PLUGIN_HANDLED;
}

public FwdGameDesc( ) {
	forward_return( FMV_STRING, GameName );
	
	return FMRES_SUPERCEDE;
}

public FwdHamTouchWeaponBox( iEntity )
	call_think( iEntity );

public FwdEmitSound( const id, const iChannel, const szSound[ ], Float:fVol, Float:fAttn, iFlags, iPitch ) {
	if( !is_user_alive( id ) )
		return FMRES_IGNORED;
	
	static szNewSound[ 26 ];
	
	if( TrieGetString( g_tSounds, szSound, szNewSound, 25 ) ) {
		if( szNewSound[ 0 ] )
			emit_sound( id, iChannel, szNewSound, fVol, fAttn, iFlags, iPitch );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdHamButtonUse( const iEntity, const id, const iActivator, const iUseType, const Float:flValue ) {
	if( iUseType != 2 || flValue != 1.0 || g_flPaused[ id ] || !is_user_alive( id ) )
		return;
	
	new szTarget[ 32 ], Float:flGameTime = get_gametime( );
	entity_get_string( iEntity, EV_SZ_target, szTarget, 31 );
	
	if( TrieKeyExists( g_tStarts, szTarget ) ) {
		if( g_flStartTime[ id ] + 1.0 > flGameTime )
			return;
		else if( g_bAfterHook[ id ] || g_bHook[ id ] ) {
			UTIL_StartFailed( id );
			ColorChat( id, Red, "%s^4 You can't start timer after using hook.", Prefix );
			return;
		}
		else if( entity_get_int( id, EV_INT_movetype ) == MOVETYPE_NOCLIP ) {
			UTIL_StartFailed( id );
			ColorChat( id, Red, "%s^4 You can't start timer while having noclip.", Prefix );
			return;
		}
		
		UTIL_ResetRoundTime( id );
		
		ColorChat( id, Red, "%s^1 You have %sstarted the timer!", Prefix, ( g_flStartTime[ id ] > 0.0 ? "re" : "" ) );
		
		static const Float:vEmpty[ 3 ] = { 0.0, 0.0, 0.0 };
		
		g_iGoChecks   [ id ] = 0;
		g_iCheckPoints[ id ] = 0;
		g_flLastThink [ id ] = 0.05;
		g_flStartTime [ id ] = flGameTime;
		g_bCpAlternate[ id ] = false;
		g_bProDisabled[ id ] = false;
		g_vCheckPoints[ id ][ 0 ] = vEmpty;
		g_vCheckAngles[ id ][ 0 ] = vEmpty;
		g_vCheckPoints[ id ][ 1 ] = vEmpty;
		g_vCheckAngles[ id ][ 1 ] = vEmpty;
		
		EventCurWeapon( id );
		
		if( IsPlayerOnGround( id ) ) {
			new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
			
			entity_get_vector( id, EV_VEC_origin, vOrigin );
			entity_get_vector( id, EV_VEC_v_angle, vAngles );
			
			vAngles[ 2 ] = entity_get_float( id, EV_FL_gravity );
			
			g_vUserStart[ id ] = vOrigin;
			g_vUserAngle[ id ] = vAngles;
			
			if( g_vStartOrigin[ 0 ] == 0.0 ) {
				g_vStartOrigin = vOrigin;
				g_vStartAngles = vAngles;
				
				new szData[ 136 ];
				
				new iFile = fopen( g_szStartFile, "at" );
				formatex( szData, 135, "%s %f %f %f %f %f %f^n", g_szMap, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ], vAngles[ 0 ], vAngles[ 1 ], vAngles[ 2 ] );
				fputs( iFile, szData );
				fclose( iFile );
			}
		}
		
	#if defined MPBHOP_FIX
		if( g_vUserStart[ id ][ 0 ] != 0.0 ) {
			mpbhop_set_user_jumpoff( id, g_vUserStart[ id ], g_vUserAngle[ id ] );
		}
		else if( g_vStartOrigin[ 0 ] != 0.0 ) {
			mpbhop_set_user_jumpoff( id, g_vStartOrigin, g_vStartAngles );
		}
	#endif
		
		// Call our forward
		new iReturn;
		ExecuteForward( g_iFwdTimerStart, iReturn, id );
	}
	else if( TrieKeyExists( g_tStops, szTarget ) ) {
		if( !g_flStartTime[ id ] )
			return;
		
		UTIL_ResetRoundTime( id );
		
		new Float:flTime = ( get_gametime( ) - g_flStartTime[ id ] ), szTime[ 9 ],
			szName[ 32 ], iCps = g_iCheckPoints[ id ], iGcs = g_iGoChecks[ id ];
		
		get_user_name( id, szName, 31 );
		ClimbtimeToString( flTime, szTime, 8 );
		
		g_flStartTime [ id ] = 0.0;
		
		if( iGcs > 0 )
			ColorChat( 0, Red, "%s^4 %s^1 has finished the map in^4 %s^1! (CP:^4 %i^1 - GC:^4 %i^1)", Prefix, szName, szTime, iCps, iGcs );
		else
			ColorChat( 0, Red, "%s^4 %s^1 has finished the map in^4 %s^1!", Prefix, szName, szTime );
		
		if( !g_bFinishedMap[ id ] ) {
			g_bFinishedMap[ id ] = true;
			ColorChat( id, Red, "%s^1 You unlocked access to use hook, godmode and noclip.", Prefix );
		}
		
		new bool:bNoob = bool:( g_bProDisabled[ id ] || g_iGoChecks[ id ] > 0 );
		
		new szSteamId[ 26 ];
		get_user_authid( id, szSteamId, 25 );
		
#if !defined SURF_BUILD
		if( flTime < g_flWRTime ) {
			new szMessage[ 128 ], szWRTime[ 9 ];
			ClimbtimeToString( g_flWRTime, szWRTime, 8 );
			formatex( szMessage, 127, "%s has broke world record with time %s!^nCurrent WR time is %s", szName, szTime, szWRTime );
			
			log_to_file( LogFile, "[WR]%s %s<%s> broke wr on map %s with time %s", bNoob ? "[NUB15]" : "", szName, szSteamId, g_szMap, szTime );
			
			if( !bNoob ) {
				UTIL_DirectorMessage(
					.index       = 0, 
					.message     = szMessage,
					.red         = 0,
					.green       = 100,
					.blue        = 255,
					.x           = -1.0,
					.y           = 0.7,
					.effect      = 0,
					.fxTime      = 4.0,
					.holdTime    = 4.0,
					.fadeInTime  = 0.5,
					.fadeOutTime = 0.5
				);
			}
		}
#endif
		
		// Update top15
		new szQuery[ 256 ], iData[ 5 ];
		formatex( szQuery, 255, "SELECT `Time` FROM `%s` WHERE `Map`='%s' AND `Type`='%i' AND `SteamId`='%s'", SqlTable, g_szMap, bNoob, szSteamId );
		
		iData[ 0 ] = id;
		iData[ 1 ] = iCps;
		iData[ 2 ] = iGcs;
		iData[ 3 ] = bNoob;
		iData[ 4 ] = _:flTime;
		
		SQL_ThreadQuery( g_hSqlTuple, "HandleSelectTime", szQuery, iData, 5 );
		
		// Call our forward
		new iReturn;
		ExecuteForward( g_iFwdTimerStop, iReturn, id, flTime );
	}
}

public FwdHamPlayerTakeDamage( const id, idInflictor, idAttacker, Float:flDamage, iDamageBits ) {
	if( iDamageBits & DMG_FALL && flDamage > 0.9 ) {
		new iDmg = floatround( flDamage );
		
		set_hudmessage( 200, 80, 20, -1.0, 0.90, 0, 2.0, 2.0, 0.1, 0.2, 3 );
		show_hudmessage( id, "Fall Dmg: %i - Health: %i", iDmg, get_user_health( id ) );
	}
}

public FwdHamPlayerResetSpeed( const id )
	return g_flPaused[ id ] ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamItemDeploy( const iEntity )
	set_pdata_float( iEntity, 46, 9999.0, 4 );

public FwdHamPlayerSpawnPre( const id )
	g_flLastCmd[ id ] = get_gametime( ) + 0.5;

public FwdHamPlayerSpawn( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	if( g_iLeet == id )
		SetLeetRender( id );
	
	if( !g_bBetaMsg[ id ] )
		set_task( 3.0, "TaskHud", id );
	
	g_iSpectateId[ id ] = 0;
	
	if( g_bAutoHeal )
		set_user_health( id, 50000 );
	
	set_pdata_int( id, m_iRadiosLeft, 0 );
	
	//cs_set_user_bpammo( id, CSW_USP, 100 );
	
	if( g_bAdmin[ id ] )
		cs_set_user_model( id, "vip" );
	
	if( g_flPaused[ id ] ) {
		Pause( id );
		
		entity_set_vector( id, EV_VEC_angles, g_vSavedAngles[ id ] );
		entity_set_int   ( id, EV_INT_fixangle, 1 );
		entity_set_origin( id, g_vSavedOrigin[ id ] );
	}
	else if( g_flStartTime[ id ] && g_iCheckPoints[ id ] && g_vCheckPoints[ id ][ 0 ][ 0 ] ) {
		GoCheck( id, !g_bCpAlternate[ id ] );
		
		set_hudmessage( 128, 128, 128, 0.01, 0.90, 0, 2.0, 2.0, 0.1, 0.2, 2 );
		ShowSyncHudMsg( id, g_iHudSync, "Gocheck #%i.", g_iGoChecks[ id ] );
	}
	
	if( g_bNightVision[ id ] ) {
		entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) | EF_BRIGHTLIGHT );
		
		UTIL_FlashLight( id, true );
	}
}

public TaskHud( const id ) {
	if( g_bBetaMsg[ id ] || !is_user_connected( id ) )
		return;
	
	g_bBetaMsg[ id ] = true;
	
#if defined XJ_BUILD
	new const BetaMessage[ ] = "Kreedz plugin by xPaw^nwww.xtreme-jumps.eu^nwww.xpaw.ru";
#else
	#if defined SURF_BUILD
		new const BetaMessage[ ] = "Surf plugin by xPaw^nwww.my-run.de^nwww.xpaw.ru";
	#else
		new const BetaMessage[ ] = "Kreedz plugin by xPaw^nwww.my-run.de^nwww.xpaw.ru";
	#endif
#endif

	UTIL_DirectorMessage(
		.index       = id,
		.message     = BetaMessage,
		.red         = 0,
		.green       = 100,
		.blue        = 255,
		.x           = -1.0,
		.y           = 0.6,
		.effect      = 0,
		.fxTime      = 5.0,
		.holdTime    = 5.0,
		.fadeInTime  = 0.5,
		.fadeOutTime = 0.5
	);
}

public FwdHamPlayerKilled( const id ) {
	CmdHookOff( id );
	UTIL_DeathMSG( id );
	
	if( cs_get_user_team( id ) == CS_TEAM_CT ) {
		if( !g_iCheckPoints[ id ] )
			CheatDetect( id, "Death" );
		
		entity_set_int( id, EV_INT_deadflag, DEAD_RESPAWNABLE );
	}
	
	// Semiclip fix
	get_players( g_iPlayers, g_iNum, "a" );
	
	for( new i = 0; i < g_iNum; i++ )
		set_pev( g_iPlayers[ i ], pev_solid, SOLID_BBOX );
}

// MESSAGE HOOKS
// ==================================================================================
public MessageTextMsg( ) {
	static const GameScoring[ ] = "#Game_scoring";
	static const SpecMode[ ] = "#Spec_Mode";
	
	new szTextMsg[ 14 ];
	get_msg_arg_string( 2, szTextMsg, 13 );
	
	if( equal( szTextMsg, GameScoring ) || equal( szTextMsg, SpecMode ) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public MessageScoreInfo( ) {
	set_msg_arg_int( 2, ARG_SHORT, 0 );
	set_msg_arg_int( 3, ARG_SHORT, 0 );
}

public MessageHealth( )
	if( get_msg_arg_int( 1 ) >= 200 )
		set_msg_arg_int( 1, ARG_BYTE, 200 );

public MessageRoundTime( )
	set_msg_arg_int( 1, ARG_SHORT, 0 );

public MessageStatusText( )
#if defined SURF_BUILD
	set_msg_arg_string( 2, "1 Surfer : %p2" );
#else
	set_msg_arg_string( 2, "1 Climber : %p2" );
#endif

// EVENTS
// ==================================================================================
public EventSpecHealth( const id )
	g_iSpectateId[ id ] = read_data( 2 );
	
public EventCurWeapon( const id ) {
	if( g_flStartTime[ id ] > 0.0 && !g_bProDisabled[ id ] ) {
		new Float:flMaxSpeed = entity_get_float( id, EV_FL_maxspeed );
		
		if( flMaxSpeed > 250.0 ) {
			g_bProDisabled[ id ] = true;
			
			ColorChat( id, Red, "%s^1 You used scout! Pro15 has been disabled for you!", Prefix );
			
			set_hudmessage( 250, 100, 0, -1.0, 0.80, 0, 2.0, 2.0, 0.1, 0.2, 3 );
			show_hudmessage( id, "Pro15 has been disabled for you!" );
		}
	}
}