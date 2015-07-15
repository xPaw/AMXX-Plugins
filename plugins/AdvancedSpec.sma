#include < amxmodx >
#include < amxmisc >
#include < fun >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

new HamHook:g_iFhTraceAttack;
new HamHook:g_iFhKilled;
new HamHook:g_iFhSpawn;
new g_iFhAddToFullPack;
new g_iMaxPlayers;
new g_iMsgSayText;

new g_iTeamBefore[ 33 ];
new bool:g_bAdmin[ 33 ];
new bool:g_bSpec[ 33 ];
new bool:g_bWasAlive[ 33 ];

public plugin_init( ) {
	register_plugin( "Advanced Spectate", "1.0", "xPaw" );
	
	register_concmd( "amx_aspec",  "CmdSpecTarget", ADMIN_RCON, "<nick> - Forces Player To Advanced Spectate" );
	register_clcmd( "say /aspec",  "CmdSpec",       ADMIN_RCON );
	register_clcmd( "say /nc",     "CmdNoClip",     ADMIN_RCON );
	register_clcmd( "say /noclip", "CmdNoClip",     ADMIN_RCON );
	
	g_iMaxPlayers = get_maxplayers( );
	g_iMsgSayText = get_user_msgid( "SayText" );
	
	DisableHamForward( g_iFhTraceAttack = RegisterHam( Ham_TraceAttack, "player", "FwdHamTraceAttack" ) );
	DisableHamForward( g_iFhKilled      = RegisterHam( Ham_Killed, "player", "FwdHamPlayerKilled" ) );
	DisableHamForward( g_iFhSpawn       = RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 ) );
}

public client_authorized( id )
	g_bAdmin[ id ] = bool:( get_user_flags( id ) & ADMIN_RCON );

public client_disconnect( id ) {
	if( g_bSpec[ id ] ) {
		g_bSpec[ id ] = false;
		
		DisableForwards( );
	}
	
	g_bWasAlive[ id ]   = false;
	g_iTeamBefore[ id ] = 0;
}

public CmdNoClip( id ) {
	if( !g_bAdmin[ id ] ) {
		if( g_bSpec[ id ] )
			GreenPrint( id, "You are not admin." );
		
		return PLUGIN_CONTINUE;
	}
	
	if( !g_bSpec[ id ] ) {
		GreenPrint( id, "You are not advanced spectator." );
		
		return PLUGIN_HANDLED;
	}
	
	if( is_user_alive( id ) )
		set_pev( id, pev_movetype, ( pev( id, pev_movetype ) == MOVETYPE_NOCLIP ) ? MOVETYPE_WALK : MOVETYPE_NOCLIP );
	
	return PLUGIN_HANDLED;
}

public CmdSpecTarget( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szTarget[ 16 ], iPlayer;
	read_argv( 1, szTarget, 15 );
	
	iPlayer = find_player( "bl", szTarget, CMDTARGET_NO_BOTS );
	
	if( iPlayer )
		AdvancedSpec( iPlayer, id );
	else
		console_print( id, "Client with that name not found." );
	
	return PLUGIN_HANDLED;
}

public CmdSpec( id ) {
	if( !g_bAdmin[ id ] )
		if( !g_bSpec[ id ] )
			return PLUGIN_CONTINUE;
	
	AdvancedSpec( id, id );
	
	return PLUGIN_HANDLED;
}

public AdvancedSpec( id, iByWho ) {
	if( g_bSpec[ id ] ) {
		g_bSpec[ id ] = false;
		
		DisableForwards( );
		
		if( id != iByWho ) {
			new szName[ 32 ];
			get_user_name( iByWho, szName, 31 );
			
			GreenPrint( id, "You have returned to a normal team by admin^3 %s^1.", szName );
		} else
			GreenPrint( id, "You have returned to a normal team." );
		
		switch( g_iTeamBefore[ id ] ) {
			case 1 : cs_set_user_team( id, CS_TEAM_T, CS_T_LEET );
			default: cs_set_user_team( id, CS_TEAM_CT, CS_CT_GIGN );
		}
		
		user_silentkill( id );
		set_pev( id, pev_takedamage, DAMAGE_AIM );
		
		if( g_bWasAlive[ id ] )
			RespawnPlayer( id, 0 );
		
		return PLUGIN_HANDLED;
	} else {
		if( !g_iFhAddToFullPack )
			g_iFhAddToFullPack = register_forward( FM_AddToFullPack, "FwdAddToFullPack", true );
		
		EnableHamForward( g_iFhTraceAttack );
		EnableHamForward( g_iFhKilled );
		EnableHamForward( g_iFhSpawn );
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		if( id != iByWho ) {
			new szName2[ 32 ];
			get_user_name( iByWho, szName2, 31 );
			
			PrintToAdmins( "^3'%s'^1 is now advanced spectator by admin ^3'%s'^1.", szName, szName2 );
			GreenPrint( id, "Admin^3 %s^1 forced you in advanced spectate mode. Say^4 /aspec^1 to go back.", szName2 );
		} else {
			PrintToAdmins( "^3'%s'^1 is now advanced spectator. Say^4 /aspec^1 if you want too.", szName );
			GreenPrint( id, "You have gone in Advanced Spectate. Say^4 /aspec^1 to go back,^4 /nc^1 to toggle noclip." );
		}
		
		g_bSpec[ id ] = true;
		g_bWasAlive[ id ] = bool:is_user_alive( id );
		g_iTeamBefore[ id ] = _:cs_get_user_team( id );
		
		cs_set_user_team( id, CS_TEAM_SPECTATOR, CS_CT_VIP );
		
		if( !g_bWasAlive[ id ] ) {
			set_pev( id, pev_deadflag, DEAD_DISCARDBODY );
			
			RespawnPlayer( id, 1 );
		} else {
			Weapons( id );
			
			set_pev( id, pev_takedamage, DAMAGE_NO );
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

public FwdAddToFullPack( iEsHandle, e, ent, host, hostflags, iPlayer, pSet ) {
	if( !iPlayer || host == ent ) // TODO: Ignore trigger_hurt
		return FMRES_IGNORED;
	
	if( !g_bSpec[ ent ] ) {
		if( g_bSpec[ host ] )
			set_es( iEsHandle, ES_Solid, SOLID_NOT );
		
		return FMRES_IGNORED;
	}
	
	if( !g_bSpec[ host ] ) {
		static const Float:vOrigin[ 3 ] = { 0.0, 0.0, -9999.0 };
		
	//	set_es( iEsHandle, ES_Solid, SOLID_NOT );
		set_es( iEsHandle, ES_Origin, vOrigin );
		set_es( iEsHandle, ES_Effects, EF_NODRAW );
	}
	
	return FMRES_IGNORED;
}

public FwdHamTraceAttack( const id, const iAttacker )
	return ( 1 <= iAttacker <= g_iMaxPlayers && id != iAttacker && g_bSpec[ iAttacker ] ) ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamPlayerKilled( const id, const iAttacker, const iShouldGib ) {
	if( g_bSpec[ id ] ) {
		RespawnPlayer( id, 1 );
		
		GreenPrint( id, "You're in Advanced Spectate mode. Say^4 /aspec^1 to go back in normal team." );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public FwdHamPlayerSpawn( id ) {
	if( g_bSpec[ id ] &&is_user_alive( id ) ) {
		if( cs_get_user_team( id ) != CS_TEAM_SPECTATOR ) {
			cs_set_user_team( id, CS_TEAM_SPECTATOR );
			
			Weapons( id );
			
			set_pev( id, pev_takedamage, DAMAGE_NO );
		}
	}
}

public RespawnPlayer( id, iSpec ) {
	ExecuteHamB( Ham_CS_RoundRespawn, id );
	
	if( iSpec ) {
		MoveToRandomSpawn( id );
		
		Weapons( id );
		
		set_pev( id, pev_takedamage, DAMAGE_NO );
	} else {
		if( !user_has_weapon( id, CSW_KNIFE ) )
			give_item( id, "weapon_knife" );
	}
}

public MoveToRandomSpawn( id ) {
	new iEntity, iCount, iSpawns[ 15 ], Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
	
	while( ( iEntity = engfunc( EngFunc_FindEntityByString, iEntity, "classname", "info_player_start" ) ) > 0 ) {
		if( iCount > 14 )
			break;
		
		iSpawns[ iCount ] = iEntity;
		
		iCount++;
	}
	
	iEntity = iSpawns[ random( iCount ) ];
	
	pev( iEntity, pev_origin, vOrigin );
	pev( iEntity, pev_angles, vAngles );
	
	set_pev( id, pev_origin, vOrigin );
	set_pev( id, pev_angles, vAngles );
	set_pev( id, pev_fixangle, 1 );
}

public Weapons( id ) {
	strip_user_weapons( id );
	give_item( id, "weapon_knife" );
	give_item( id, "weapon_usp" );
	cs_set_user_bpammo( id, CSW_USP, 100 );
	
	set_pdata_int( id, 116, 0 ); // Primary weapon pickup fix
}

public DisableForwards( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ )
		if( g_bSpec[ iPlayers[ i ] ] )
			return PLUGIN_CONTINUE;
	
	DisableHamForward( g_iFhSpawn );
	DisableHamForward( g_iFhKilled );
	DisableHamForward( g_iFhTraceAttack );
	
	if( g_iFhAddToFullPack ) {
		unregister_forward( FM_AddToFullPack, g_iFhAddToFullPack, true );
		
		g_iFhAddToFullPack = 0;
	}
	
	return PLUGIN_CONTINUE;
}

PrintToAdmins( szMsg[ ], any:... ) {
	new szMessage[ 128 ], iPlayers[ 32 ], iNum, id;
	vformat( szMessage, 127, szMsg, 2 );
	get_players( iPlayers, iNum, "ch" );
	
	for( new i; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		if( g_bAdmin[ id ] )
			GreenPrint( id, szMessage );
	}
}

GreenPrint( id, const message[ ], any:... ) {
	new szMessage[ 192 ];
	formatex( szMessage, 191, "^4[Advanced Spec]^1 " );
	vformat( szMessage[ 18 ], 185, message, 3 );
	
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgSayText, _, id );
	write_byte( id );
	write_string( szMessage );
	message_end( );
}
