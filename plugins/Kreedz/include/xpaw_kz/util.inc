// STOCKS AND OTHER
// ==================================================================================

RegisterCommand( const szCommand[ ], const szFunction[ ] ) {
	new szTemp[ 32 ];
	formatex( szTemp, 31, "say /%s", szCommand );
	register_clcmd( szTemp, szFunction, ADMIN_ALL );
	
//	szTemp[ 4 ] = '.';
//	register_clcmd( szTemp, szFunction );
}

GoCheck( const id, const bool:bAlternate ) {
	g_iGoChecks[ id ]++;
	
	entity_set_vector( id, EV_VEC_angles  , g_vCheckAngles[ id ][ bAlternate ] );
	entity_set_float ( id, EV_FL_gravity  , g_vCheckAngles[ id ][ bAlternate ][ 2 ] );
	entity_set_int   ( id, EV_INT_fixangle, 1 );
	entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
	entity_set_float ( id, EV_FL_fuser2   , 0.0 );
	ForceDuck( id );
	entity_set_origin( id, g_vCheckPoints[ id ][ bAlternate ] );
	
	GoCheckEffect( id, g_vCheckPoints[ id ][ bAlternate ] );
}

Pause( const id, bool:bPause = true, bool:bMovedSpec = false ) {
	if( bPause ) {
		if( !g_flPaused[ id ] ) {
			g_flPaused   [ id ] = ( get_gametime( ) - g_flStartTime[ id ] );
			g_flStartTime[ id ] = 0.0;
		}
		
		if( !bMovedSpec ) {
			set_user_maxspeed( id, 1.0 );
		}
		
		set_hudmessage( 250, 100, 0, -1.0, 0.80, 0, 2.0, 2.0, 0.1, 0.2, 3 );
		show_hudmessage( id, "TIMER PAUSED!%s", bMovedSpec ? "" : "^nSay /unpause to continue" );
	} else {
		g_flStartTime[ id ] = get_gametime( ) - g_flPaused[ id ];
		g_flPaused   [ id ] = 0.0;
		
		ExecuteHamB( Ham_Item_PreFrame, id );
		
		set_hudmessage( 250, 100, 0, -1.0, 0.80, 0, 2.0, 2.0, 0.1, 0.2, 3 );
		show_hudmessage( id, "TIMER UNPAUSED!" );
		
		EventCurWeapon( id );
	}
}

CheatDetect( const id, const szCheat[ ] ) {
	if( g_flPaused[ id ] )
		Pause( id, false );
	
	if( g_flStartTime[ id ] ) {
		ColorChat( id, Red, "%s^4 %s^1 detected. Your timer has been stopped!", Prefix, szCheat );
		
		g_flStartTime[ id ] = 0.0;
		
		UTIL_StartFailed( id, false );
		UTIL_ResetRoundTime( id );
		
		new iReturn;
		ExecuteForward( g_iFwdCheatDetected, iReturn, id );
	}
}

GoCheckEffect( const id, const Float:vOrigin[ 3 ] ) {
	new iOrigin[ 3 ];
	FVecIVec( vOrigin, iOrigin );
	
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id );
	write_byte( TE_BEAMCYLINDER );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] - 30 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] + 40 );
	write_short( g_iBeam );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 4 );
	write_byte( 6 );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 85 );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}

ForceDuck( const id ) {
	entity_set_int( id, EV_INT_flags, entity_get_int( id, EV_INT_flags ) | FL_DUCKING );
	entity_set_size( id, Float:{ -16.0, -16.0, -18.0 }, Float:{ 16.0,  16.0,  18.0 } );
}

ClimbtimeToString( const Float:flClimbTime, szOutPut[ ], const iLen ) {
	new iMinutes = floatround( flClimbTime / 60.0, floatround_floor );
	new iSeconds = floatround( flClimbTime - iMinutes * 60, floatround_floor );
	new iMiliSeconds = floatround( ( flClimbTime - ( iMinutes * 60 + iSeconds ) ) * 100, floatround_floor );
	
	formatex( szOutPut, iLen, "%02i:%02i.%02i", iMinutes, iSeconds, iMiliSeconds );
}

bool:CheckFlood( const id ) {
	new Float:flGametime = get_gametime( );
	
	if( g_flLastCmd[ id ] < flGametime ) {
		g_flLastCmd[ id ] = flGametime + 0.15;
		
		return false;
	}
	
	return true;
}

UTIL_StartFailed( const id, bool:bStart = true ) {
	#define FFADE_IN 0x0000
	
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, id );
	write_short( ( 2 << 12 ) );
	write_short( 0 );
	write_short( FFADE_IN );
	write_byte( 255 );
	write_byte( 30 );
	write_byte( 0 );
	write_byte( 80 );
	message_end( );
	
	set_hudmessage( 250, 50, 0, -1.0, 0.6, 0, 1.7, 1.7, 0.1, 0.3, 3 );
	show_hudmessage( id, bStart ? "** FAILED TO START TIMER **" : "** CHEAT DETECTED **" );
}

UTIL_DeathMSG( const id ) {
	static const szWeapon[ ] = "worldspawn";
	
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgDeathMsg, _, id );
	write_byte( id );
	write_byte( id );
	write_byte( 0 );
	write_string( szWeapon );
	message_end( );
}

UTIL_ResetRoundTime( const id ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgRoundTime, _, id );
	write_short( 1 );
	message_end( );
}

UTIL_FlashLight( const id, const iStatus ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgFlashLight, _, id );
	write_byte( iStatus );
	write_byte( 100 );
	message_end( );
}

UTIL_SetRendering( iEntity, iFX, Float:iColor[ 3 ], iRender, Float:iAmount ) {
	entity_set_int( iEntity, EV_INT_renderfx, iFX );
	entity_set_int( iEntity, EV_INT_rendermode, iRender );
	entity_set_float( iEntity, EV_FL_renderamt, iAmount );
	entity_set_vector( iEntity, EV_VEC_rendercolor, iColor );
}

stock UTIL_DirectorMessage( const index, const message[], const red = 0, const green = 160, const blue = 0, 
					  const Float:x = -1.0, const Float:y = 0.65, const effect = 2, const Float:fxTime = 6.0, 
					  const Float:holdTime = 3.0, const Float:fadeInTime = 0.1, const Float:fadeOutTime = 1.5 ) {
	#define pack_color(%0,%1,%2) ( %2 + ( %1 << 8 ) + ( %0 << 16 ) )
	#define write_float(%0) write_long( _:%0 )
	
	message_begin( index ? MSG_ONE : MSG_BROADCAST, SVC_DIRECTOR, .player = index );
	{
		write_byte( strlen( message ) + 31 ); // size of write_*
		write_byte( DRC_CMD_MESSAGE );
		write_byte( effect );
		write_long( pack_color( red, green, blue ) );
		write_float( x );
		write_float( y );
		write_float( fadeInTime );
		write_float( fadeOutTime );
		write_float( holdTime );
		write_float( fxTime );
		write_string( message );
	}
	message_end( );
}


// Structured Query Language :-)
// ==================================================================================
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

public HandleSelectLeet( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( !SQL_IsFail( iFailState, iError, szError ) && SQL_NumResults( hQuery ) ) {
		SQL_ReadResult( hQuery, 0, g_flLeetTime );
		SQL_ReadResult( hQuery, 1, g_szLeetName, 31 );
		SQL_ReadResult( hQuery, 2, g_szLeetSteamId, 29 );
		
		new id = find_player( "c", g_szLeetSteamId );
		
		if( id ) {
			g_iLeet = id;
			
			if( is_user_alive( id ) )
				SetLeetRender( id );
		}
	}
}

#if !defined SURF_BUILD
public HandleSelectWR( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) || !SQL_NumResults( hQuery ) ) {
		formatex( g_szWR, charsmax( g_szWR ), "World Record of %s:^n   No record found.", g_szMap );
		return;
	}
	
	new szName[ 32 ], szRoute[ 16 ], szTime[ 9 ];
	SQL_ReadResult( hQuery, 0, g_flWRTime );
	SQL_ReadResult( hQuery, 1, szName, 31 );
	SQL_ReadResult( hQuery, 2, szRoute, 15 );
	ClimbtimeToString( g_flWRTime, szTime, 8 );
	
	if( equal( g_szMap, "ae_strafers_heaven" )
	||  equal( g_szMap, "tx_twiscape" )
	||  equal( g_szMap, "kzarg_challenge_bhop" )
	||  equal( g_szMap, "deathrun_roadoffear_rc" ) )
		g_flWRTime = 0.0;
	
	if( szRoute[ 0 ] )
		formatex( g_szWR, charsmax( g_szWR ), "World Record of %s:^n   [%s] %s (%s)", g_szMap, szRoute, szName, szTime );
	else
		formatex( g_szWR, charsmax( g_szWR ), "World Record of %s:^n   %s (%s)", g_szMap, szName, szTime );
}
#endif

public HandleUpdateTime( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
	new szQuery[ 300 ], bool:bNoob = bool:szData[ 29 ], id = szData[ 30 ];
	szData[ 29 ] = 0;
	
	formatex( szQuery, 299, "SELECT Time as a, (SELECT count(Time)+1 from %s where Time<a AND Map='%s' \
	AND Type=%i ) as b, Type, Name from %s WHERE SteamID='%s' AND Map='%s' AND Type=%i", SqlTable, g_szMap,
		bNoob, SqlTable, szData, g_szMap, bNoob );
	
	szData[ 29 ] = id;
	SQL_ThreadQuery( g_hSqlTuple, "HandleGetRank", szQuery, szData, 30 );
}

public HandleGetRank( iFailState, Handle:hQuery, szError[ ], iError, szName[ 32 ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
	if( !SQL_NumResults( hQuery ) ) return; // rare case? is it even needed...
	
	client_cmd( 0, "spk fvox/bell" );
	
	new szSteamId[ 30 ], id = szName[ 29 ];
	szName[ 29 ] = 0;
	
	copy( szSteamId, 29, szName );
	
	new iRank = SQL_ReadResult( hQuery, 1 ),
		bNoob = SQL_ReadResult( hQuery, 2 );
	
	SQL_ReadResult( hQuery, 3, szName, 31 );
	
	if( !bNoob && iRank == 1 ) {
		ColorChat( 0, Red, "%s^4 %s^1 is new leet climber in^4 Pro15^1.", Prefix, szName );
		
		new szMessage[ 60 ];
		formatex( szMessage, 59, "%s is the new 1337-climber!", szName );
		
		UTIL_DirectorMessage(
			.index       = 0, 
			.message     = szMessage,
			.red         = 200,
			.green       = 80,
			.blue        = 20,
			.x           = -1.0,
			.y           = 0.1,
			.effect      = 0,
			.fxTime      = 4.0,
			.holdTime    = 4.0,
			.fadeInTime  = 0.5,
			.fadeOutTime = 0.5
		);
		
		copy( g_szLeetName, 31, szName );
		copy( g_szLeetSteamId, 31, szSteamId );
		
		if( g_iLeet != id ) {
			if( g_iLeet ) {
				SQL_ReadResult( hQuery, 0, g_flLeetTime );
				
				ClimbtimeToString( g_flLeetTime, szSteamId, 8 );
				
				ColorChat( g_iLeet, Red, "%s^1 Your leet record was broken by^3 %s^1 with new time^4 %s^3.", Prefix, szName, szSteamId );
				
				if( is_user_alive( g_iLeet ) )
					UTIL_SetRendering( id, kRenderFxNone, Float:{ 0.0, 0.0, 0.0 }, kRenderNormal, 16.0 );
			}
			
			if( is_user_connected( id ) ) {
				g_iLeet = id;
				
			//	if( is_user_alive( id ) )
				SetLeetRender( id );
			} else
				g_iLeet = 0;
		}
	} else {
		ColorChat( 0, Red, "%s^4 %s^1 is now ranked^3 #%i^1 in the^4 %s15^1.", Prefix, szName, iRank, ( bNoob ? "Nub" : "Pro" ) );
	}
}

public HandleSelectMyBest( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
	new id = szData[ 0 ];
	if( !is_user_connected( id ) ) return; // lol
	
	if( !SQL_NumResults( hQuery ) ) {
		ColorChat( id, Red, "%s^1 You do not have any Pro15 record.", Prefix );
	} else {
		new szTime[ 9 ], Float:flTime, iRank = SQL_ReadResult( hQuery, 1 );
		SQL_ReadResult( hQuery, 0, flTime );
		
		ClimbtimeToString( flTime, szTime, 8 );
		
		ColorChat( id, Red, "%s^1 Your best time on this map is^4 %s^1 and you are ranked^3 #%i^1.", Prefix, szTime, iRank );
	}
}

public HandleSelectTime( iFailState, Handle:hQuery, szError[ ], iError, szData[ ], iSize, Float:flQueueTime ) {
	if( SQL_IsFail( iFailState, iError, szError ) )
		return;
	
	new id = szData[ 0 ];
	if( !is_user_connected( id ) ) return; // lol
	
	new iSysTime = get_systime( 0 ), Float:flNewTime = Float:szData[ 4 ];
	new szName[ 32 ], szSteamId[ 31 ], szIp[ 16 ], szWeapon[ 20 ];
	get_user_name( id, szName, 31 );
	get_user_authid( id, szSteamId, 29 );
	get_user_ip( id, szIp, 15, true );
	
	if( g_bProDisabled[ id ] ) {
		szWeapon = "scout";
	} else {
		get_weaponname( get_user_weapon( id ), szWeapon, 19 );
		replace( szWeapon, 19, "weapon_", "" );
	}
	
	if( !SQL_NumResults( hQuery ) ) {
		new szQuery[ 256 ];
		formatex( szQuery, 255, "INSERT INTO `%s` VALUES('','%s','%i',^"%s^",'%s','%f','%s','n-a','%i','%s','%i','%i')",
			SqlTable, g_szMap, szData[ 3 ], szName, szSteamId, flNewTime, szIp, iSysTime, szWeapon, szData[ 1 ], szData[ 2 ] );
		
		szSteamId[ 29 ] = szData[ 3 ];
		szSteamId[ 30 ] = id;
		SQL_ThreadQuery( g_hSqlTuple, "HandleUpdateTime", szQuery, szSteamId, 31 );
	} else {
		new szTime[ 9 ], Float:flTime;
		SQL_ReadResult( hQuery, 0, flTime );
		
		if( flNewTime >= flTime ) {
			ClimbtimeToString( ( flNewTime - flTime ), szTime, 8 );
			ColorChat( id, Red, "%s^1 You were slower than your better time by^4 %s^1.", Prefix, szTime );
		} else {
			ClimbtimeToString( ( flTime - flNewTime ), szTime, 8 );
			ColorChat( id, Red, "%s^1 You have improved your old time by^4 %s^1.", Prefix, szTime );
			
			new szQuery[ 300 ];
			formatex( szQuery, 299, "UPDATE `%s` SET `Name`=^"%s^",`Time`='%f',`Date`='%i',`Ip`='%s',`Country`='n-a',`Weapon`='%s',`Cps`='%i',`Gcs`='%i' WHERE `Map`='%s' AND `Type`='%i' AND `SteamId`='%s'",
				SqlTable, szName, flNewTime, iSysTime, szIp, szWeapon, szData[ 1 ], szData[ 2 ], g_szMap, szData[ 3 ], szSteamId );
			
			szSteamId[ 29 ] = szData[ 3 ];
			szSteamId[ 30 ] = id;
			SQL_ThreadQuery( g_hSqlTuple, "HandleUpdateTime", szQuery, szSteamId, 31 );
		}
	}
}

stock CommandTarget( const id, const szArg[ ] ) {
	new iPlayer = find_player( "bl", szArg );
	
	if( iPlayer ) {
		if( iPlayer != find_player( "blj", szArg ) ) {
			ColorChat( id, Red, "%s^1 There is more than one client matching your argument.", Prefix );
			return 0;
		}
	}
	else if( ( iPlayer = find_player( "c", szArg ) ) == 0 && szArg[ 0 ] == '#' && szArg[ 1 ] ) {
		iPlayer = find_player( "k", str_to_num( szArg[ 1 ] ) );
	}
	
	if( !iPlayer ) {
		ColorChat( id, Red, "%s^1 Player with that name or userid not found.", Prefix );
		return 0;
	}
	
	return iPlayer;
}