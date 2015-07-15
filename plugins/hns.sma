#include < amxmodx >
#include < amxmisc >
#include < geoip >
#include < fun >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

const m_pPlayer    = 41;
const m_fPainShock = 108;
const m_iHideHUD   = 361;

new const g_szGamename[ ] = "HideNSeek";

new g_iMaxPlayers;
new g_iMsgSayText;
new g_iMsgScreenFade;
new g_iMsgSendAudio;
new g_iMsgStatusText;
new g_iMsgStatusValue;

new g_iSprSmoke;
new g_iNubSlash;
new g_iTimer;
new g_iTimerEntity;
new g_iMenuNewGrenades;
new g_iSendAudioMessage;

new Float:g_flRoundStartTime;
new Trie:g_tRoundStartSounds;

new bool:g_bStart;
new bool:g_bNewGrens;
new bool:g_bAlive[ 33 ];
new bool:g_bSolid[ 33 ];
new bool:g_bRestore[ 33 ];
new bool:g_bSawPlayer[ 33 ];
new Float:g_flLastAimDetail[ 33 ];
new CsTeams:g_iTeam[ 33 ];
new g_iSpawnCount[ 33 ];
new g_szCountry[ 33 ][ 46 ];

new g_bScrim, g_bChanged, g_iScores[ 2 ], g_szNames[ 2 ][ 32 ];

#define HUD_MONEY    ( 1 << 5 )
#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )

public plugin_init( ) {
	register_plugin( "HideNSeek", "1.0", "xPaw" );
	
	register_clcmd( "hns_scrim",   "CmdScrim", ADMIN_KICK, "<team1 (T)> <team2 (CT)> - Start scrim" );
	register_clcmd( "say /wins",   "CmdScore" );
	register_clcmd( "say /score",  "CmdScore" );
	register_clcmd( "chooseteam",  "CmdJoinTeam" );
	register_clcmd( "jointeam",    "CmdJoinTeam" );
	
	g_iMsgScreenFade  = get_user_msgid( "ScreenFade" );
	g_iMsgSendAudio   = get_user_msgid( "SendAudio" );
	g_iMsgSayText     = get_user_msgid( "SayText" );
	g_iMsgStatusText  = get_user_msgid( "StatusText" );
	g_iMsgStatusValue = get_user_msgid( "StatusValue" );
	g_iMaxPlayers     = get_maxplayers( );
	
	g_iTimerEntity    = create_entity( "info_target" );
	set_pev( g_iTimerEntity, pev_classname, "hns_timer" );
	
	register_logevent( "EventRoundStart", 2, "0=World triggered", "1=Round_Start" );
	
	register_event( "HLTV",       "EventNewRound",   "a", "1=0", "2=0" );
	register_event( "TextMsg",    "EventRestart",    "a", "2&#Game_C", "2&#Game_w" );
	register_event( "SendAudio",  "EventWin_TS",     "a", "2=%!MRAD_terwin" );
	register_event( "SendAudio",  "EventWin_CT",     "a", "2=%!MRAD_ctwin" );
	register_event( "TeamInfo",   "EventTeamInfo",   "a" );
	register_event( "DeathMsg",   "EventDeathMsg",   "a" );
	register_event( "HideWeapon", "EventHideWeapon", "b" );
	register_event( "ResetHUD",   "EventResetHUD",   "b" );
	register_event( "Money",      "EventMoney",      "b" );
	
	register_message( get_user_msgid( "StatusIcon" ), "MsgStatusIcon" );
	register_message( get_user_msgid( "TextMsg" ),    "MsgTextMsg" );
	register_message( g_iMsgScreenFade,               "MsgScreenFade" );
	
	register_forward( FM_AddToFullPack,      "FwdAddToFullPack", 1 );
	register_forward( FM_PlayerPreThink,     "FwdPlayerPreThink" );
	register_forward( FM_PlayerPostThink,    "FwdPlayerPostThink" );
	register_forward( FM_GetGameDescription, "FwdGameDesc" );
	register_forward( FM_EmitSound,          "FwdEmitSound" );
	register_forward( FM_ClientKill,         "FwdClientKill" );
	register_think( "hns_timer",             "FwdThinkTimer" );
	
	RegisterHam( Ham_Weapon_PrimaryAttack,   "weapon_knife", "FwdHamKnifePrimaryAttack" );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "FwdHamKnifeSecondaryAttack" );
	
	RegisterHam( Ham_Spawn,  "grenade",   "FwdHamSpawn_Grenade",   1 );
	RegisterHam( Ham_Spawn,  "weaponbox", "FwdHamSpawn_Weaponbox", 1 );
	RegisterHam( Ham_Spawn,  "player",    "FwdHamSpawn_Player",    1 );
	RegisterHam( Ham_Killed, "player",    "FwdHamKilled_Player",   1 );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamTakeDamage",     1 );
	
	set_msg_block( get_user_msgid( "WeapPickup" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "AmmoPickup" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "HostagePos" ), BLOCK_SET );
	
	new const szStartRadios[ ][ ] = { "%!MRAD_GO", "%!MRAD_LOCKNLOAD", "%!MRAD_LETSGO", "%!MRAD_MOVEOUT" };
	g_tRoundStartSounds = TrieCreate( );
	
	for( new i; i < sizeof szStartRadios; i++ )
		TrieSetCell( g_tRoundStartSounds, szStartRadios[ i ], 1 );
	
	// Remove unneeded entities
	new const szRemoveEntities[ ][ ] = {
		"func_hostage_rescue", "info_hostage_rescue", "game_player_equip",
		"func_bomb_target", "info_bomb_target", "hostage_entity",
		"info_vip_start", "func_vip_safetyzone", "func_escapezone",
		"info_map_parameters", "player_weaponstrip", "func_buyzone", "armoury_entity"
	};
	
	for( new i; i < sizeof szRemoveEntities; i++ )
		remove_entity_name( szRemoveEntities[ i ] );
	
	// Create fake hostage
	new iHostage = create_entity( "hostage_entity" );
	engfunc( EngFunc_SetOrigin, iHostage, { 0.0, 0.0, -55000.0 } );
	engfunc( EngFunc_SetSize, iHostage, { -1.0, -1.0, -1.0 }, { 1.0, 1.0, 1.0 } );
	dllfunc( DLLFunc_Spawn, iHostage );
	
	// Generate New grens menu
	g_iMenuNewGrenades = menu_create( "\rNew Grenades ?", "HandleNewGrenades" );
	
	menu_additem( g_iMenuNewGrenades, "Yes", "1", 0 );
	menu_additem( g_iMenuNewGrenades, "No", "1", 0 );
	menu_setprop( g_iMenuNewGrenades, MPROP_EXIT, MEXIT_NEVER );
	
	server_cmd( "sv_restart 1" );
}

public plugin_precache( ) {
	g_iSprSmoke = precache_model( "sprites/smoke.spr" );
	
	precache_sound( "items/smallmedkit1.wav" );
	precache_sound( "SoUlFaThEr/one.wav" );
	precache_sound( "SoUlFaThEr/two.wav" );
	precache_sound( "SoUlFaThEr/three.wav" );
	precache_sound( "SoUlFaThEr/four.wav" );
	precache_sound( "SoUlFaThEr/five.wav" );
	precache_sound( "SoUlFaThEr/six.wav" );
	precache_sound( "SoUlFaThEr/seven.wav" );
	precache_sound( "SoUlFaThEr/eight.wav" );
	precache_sound( "SoUlFaThEr/nine.wav" );
	precache_sound( "SoUlFaThEr/ten.wav" );
}

public CmdScrim( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	if( g_bScrim ) {
		console_print( id, "[HideNSeek] Scrim is already running! ^"%s^" vs ^"%s^"", g_szNames[ 0 ], g_szNames[ 1 ] );
		return PLUGIN_HANDLED;
	}
	
	read_argv( 1, g_szNames[ 0 ], 31 );
	read_argv( 2, g_szNames[ 1 ], 31 );
	
	if( equali( g_szNames[ 0 ], g_szNames[ 1 ] ) ) {
		console_print( id, "[HideNSeek] Both team names equal to each other! Please fix it!" );
		return PLUGIN_HANDLED;
	}
	
	g_bScrim       = true;
	g_bChanged     = false;
	g_iScores[ 0 ] = g_iScores[ 1 ] = 0;
	
	GreenPrint( 0, "Scrim has been started!^4 5^1 rounds will be played in each team!" );
	GreenPrint( 0, "^3'%s'^1 vs ^3'%s'^1 ! Good luck teams!", g_szNames[ 0 ], g_szNames[ 1 ] );
	GreenPrint( 0, "Say^4 /wins^1,^4 /score^1 to see the current score! Plugin by xPaw." );
	
	server_cmd( "mp_forcecamera 2" );
	server_cmd( "mp_forcechasecam 2" );
	server_cmd( "sv_restart 1" );
	
	return PLUGIN_HANDLED;
}

public CmdScore( id ) {
	if( !g_bScrim ) {
		GreenPrint( id, "No scrim is running at the moment!" );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_iScores[ 0 ] > g_iScores[ 1 ] ) {
		GreenPrint( 0, "Team^4 %s^1 is leading with score^4 %i-%i^1.", g_szNames[ 0 ], g_iScores[ 0 ], g_iScores[ 1 ] );
	} else if( g_iScores[ 1 ] > g_iScores[ 0 ] ) {
		GreenPrint( 0, "Team^4 %s^1 is leading with score^4 %i-%i^1.", g_szNames[ 1 ], g_iScores[ 1 ], g_iScores[ 0 ] );
	} else
		GreenPrint( 0, "Teams are tied!^4 %i-%i^1.", g_iScores[ 0 ], g_iScores[ 1 ] );
	
	return PLUGIN_CONTINUE;
}

public EventWin_TS( ) {
	if( g_bStart ) {
		for( new id = 1; id <= g_iMaxPlayers; id++ ) {
			if( g_bAlive[ id ] && g_iTeam[ id ] == CS_TEAM_T ) {
				if( !g_bScrim )
					GreenPrint( id, "You received^4 1^1 frag for surviving the round!" );
				
				set_user_frags( id, get_user_frags( id ) + 1 );
			}
		}
		
		if( g_bScrim )
			ScrimAddScore( 0 );
		else // Dont allow nubslash in scrims
			g_iNubSlash++;
	}
}

public EventWin_CT( ) {
	if( g_bStart ) {
		if( g_bScrim )
			ScrimAddScore( 1 );
		else {
			set_task( 0.1, "Task_TeamSwap" );
			
			set_hudmessage( 0, 100, 255, -1.0, 0.82, 0, 0.0, 2.0, 0.2, 0.2, 1 );
			show_hudmessage( 0, "Switching teams!" );
			
			g_iNubSlash = 0;
		}
	}
}

public EventNewRound( ) {
	g_bNewGrens = false;
	
	if( CheckPlayers( 0 ) )
		g_bStart = true;
}

public EventRestart( ) {
	g_iNubSlash = 0;
	g_iTimer = 0;
}

public EventRoundStart( ) {
	set_task( 3.0, "BreakStuff" );
	
	if( g_bStart ) {
		if( g_iNubSlash == 3 )
			GreenPrint( 0, "Seekers can now use^4 nubslash^1 after losing^3 3^1 rounds in a row!" );
		
		g_iTimer = 10;
		set_pev( g_iTimerEntity, pev_nextthink, get_gametime( ) );
		
		g_flRoundStartTime = get_gametime( );
		if( !g_iSendAudioMessage )
			g_iSendAudioMessage = register_message( g_iMsgSendAudio, "MsgSendAudio" );
	}
	
	return PLUGIN_CONTINUE;
}

public EventDeathMsg( ) {
	new iVictim = read_data( 2 );
	
	if( g_iTimer && g_iTeam[ iVictim ] == CS_TEAM_CT ) {
		MakeScreenFade( iVictim );
		set_pev( iVictim, pev_flags, pev( iVictim, pev_flags ) & ~FL_FROZEN );
	}
	
	return PLUGIN_CONTINUE;
}

public EventTeamInfo( ) {
	new szTeamInfo[ 2 ], id = read_data( 1 );
	read_data( 2, szTeamInfo, 1 );
	
	switch( szTeamInfo[ 0 ] ) {
		case 'T': g_iTeam[ id ] = CS_TEAM_T;
		case 'C': g_iTeam[ id ] = CS_TEAM_CT;
		case 'S': g_iTeam[ id ] = CS_TEAM_SPECTATOR;
		default : g_iTeam[ id ] = CS_TEAM_UNASSIGNED;
	}
}

public EventMoney( id ) {
	set_pdata_int( id, m_iHideHUD, HUD_MONEY );
	set_pdata_int( id, 115, 0 );
}

public EventResetHUD( id )
	set_pdata_int( id, m_iHideHUD, HUD_MONEY );

public EventHideWeapon( id )
	set_pdata_int( id, m_iHideHUD, read_data( 1 ) | HUD_MONEY );

public MsgTextMsg( msgid, dest, id ) {
	static const TerroristMsg[ ] = "#Terrorists_Win";
	static const HostageMsg  [ ] = "#Hostages_Not_Rescued";
	static const CTMsg       [ ] = "#CTs_Win";
	
	new szMsg[ 33 ];
	get_msg_arg_string( 2, szMsg, 32 );
	
	if( equal( szMsg, TerroristMsg ) || equal( szMsg, HostageMsg ) )
		set_msg_arg_string( 2, "Hiders win!" );
	else if( equal( szMsg, CTMsg ) )
		set_msg_arg_string( 2, "Seekers win!" );
}

public MsgStatusIcon( msgid, msgdest, id ) {
	static szMsg[ 8 ];
	get_msg_arg_string( 2, szMsg, 7 );
	
	if( equal( szMsg, "buyzone" ) && get_msg_arg_int( 1 ) ) {
		set_pdata_int( id, 235, get_pdata_int( id, 235 ) & ~( 1 << 0 ) );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public MsgScreenFade( msgid, msgdest, id ) {
	if( get_msg_arg_int( 4 ) == 255 && get_msg_arg_int( 5 ) == 255 && get_msg_arg_int( 6 ) == 255 )
		if( ( g_iTeam[ id ] == CS_TEAM_CT && g_iTimer ) || g_iTeam[ id ] == CS_TEAM_T )
			return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public MsgSendAudio( iMsgId, iMsgDest, iMsgEnt ) {
	if( get_gametime( ) > g_flRoundStartTime ) {
		unregister_message( g_iMsgSendAudio, g_iSendAudioMessage );
		g_iSendAudioMessage = 0;
		return PLUGIN_CONTINUE;
	}
	
	if( iMsgEnt ) {
		new szAudioString[ 17 ];
		get_msg_arg_string( 2, szAudioString, 16 );
		
		if( TrieKeyExists( g_tRoundStartSounds, szAudioString ) )
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public FwdHamTakeDamage( id, iInflictor, iAttacker )
	if( IsPlayer( iAttacker ) )
		set_pdata_float( id, m_fPainShock, 1.0 );

public FwdHamKnifeSecondaryAttack( iKnife ) {
	if( !g_bStart )
		return HAM_IGNORED;
	
	if( g_iTeam[ get_pdata_cbase( iKnife, m_pPlayer, 4 ) ] == CS_TEAM_T )
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public FwdHamKnifePrimaryAttack( iKnife ) {
	if( !g_bStart )
		return HAM_IGNORED;
	
	if( g_iTeam[ get_pdata_cbase( iKnife, m_pPlayer, 4 ) ] == CS_TEAM_T )
		return HAM_SUPERCEDE;
	
	if( g_iNubSlash >= 3 )
		return HAM_IGNORED;
	
	ExecuteHam( Ham_Weapon_SecondaryAttack, iKnife );
	
	return HAM_SUPERCEDE;
}

public FwdAddToFullPack( es, e, ent, host, hostflags, player, pSet )
	if( player )
		if( g_iTeam[ host ] == g_iTeam[ ent ] )
			if( g_bSolid[ host ] && g_bSolid[ ent ] )
				set_es( es, ES_Solid, SOLID_NOT );

public FwdPlayerPreThink( id ) {
	if( g_bAlive[ id ] ) {
		static Float:flGametime; flGametime = get_gametime( );
		
		if( g_flLastAimDetail[ id ] < flGametime ) {
			static iTgt, iBody;
			get_user_aiming( id, iTgt, iBody, 3500 );
			
			if( is_user_alive( iTgt ) ) {
				static szMessage[ 256 ];
				
				if( g_iTeam[ iTgt ] == g_iTeam[ id ] )
					formatex( szMessage, 255, "Friend: %%p2 - %s - Health: %i%s", g_szCountry[ iTgt ], get_user_health( iTgt ), "%%" );
				else
					formatex( szMessage, 255, "Enemy: %%p2 - %s", g_szCountry[ iTgt ] );
				
				message_begin( MSG_ONE_UNRELIABLE, g_iMsgStatusValue, _, id );
				write_byte( 2 );
				write_short( iTgt );
				message_end( );
				
				message_begin( MSG_ONE_UNRELIABLE, g_iMsgStatusText, _, id );
				write_byte( 0 );
				write_string( szMessage );
				message_end( );
				
				g_bSawPlayer[ id ] = true;
			} else {
				if( g_bSawPlayer[ id ] ) {
					g_bSawPlayer[ id ] = false;
					
					message_begin( MSG_ONE_UNRELIABLE, g_iMsgStatusText, _, id );
					write_byte( 0 );
					write_string( " " );
					message_end( );
				}
			}
			
			g_flLastAimDetail[ id ] = flGametime + 0.2;
		}
	}
	
	static i, iLastThink;
	
	if( iLastThink > id ) {
		for( i = 1; i <= g_iMaxPlayers; i++ ) {
			if( !g_bAlive[ i ] ) {
				g_bSolid[ i ] = false;
				
				continue;
			}
			
			g_bSolid[ i ] = pev( i, pev_solid ) == SOLID_SLIDEBOX ? true : false;
		}
	}
	
	iLastThink = id;
	
	if( !g_bSolid[ id ] )
		return;
	
	for( i = 1; i <= g_iMaxPlayers; i++ ) {
		if( !g_bSolid[ i ] || id == i )
			continue;
		
		if( g_iTeam[ id ] == g_iTeam[ i ] ) {
			set_pev( i, pev_solid, SOLID_NOT );
			g_bRestore[ i ] = true;
		}
	}
}

public FwdPlayerPostThink( id ) {
	static i, Float:flGravity;
	
	for( i = 1; i <= g_iMaxPlayers; i++ ) {
		if( g_bRestore[ i ] ) {
			pev( i, pev_gravity, flGravity );
			set_pev( i, pev_solid, SOLID_SLIDEBOX );
			g_bRestore[ i ] = false;
			
			if( flGravity != 1.0 )
				set_pev( i, pev_gravity, flGravity );
		}
	}
}

public FwdClientKill( id ) {
	if( !g_bStart )
		return FMRES_IGNORED;
	
	console_print( id, "You cannot kill yourself during HideNSeek!" );
	GreenPrint( id, "You cannot kill yourself during^4 HideNSeek^1!" );
	
	return FMRES_SUPERCEDE;
}

public FwdGameDesc( ) {
	forward_return( FMV_STRING, g_szGamename );
	
	return FMRES_SUPERCEDE;
}

public FwdEmitSound( id, iChannel, const szSound[ ] ) {
	if( IsPlayer( id ) ) {
		if( g_iTeam[ id ] != CS_TEAM_T )
			return FMRES_IGNORED;
		
		static const KnifeDeploy[ ] = "weapons/knife_deploy1.wav";
		static const GunPickup[ ]   = "items/gunpickup2.wav";
		
		if( g_bNewGrens && equal( szSound, GunPickup ) )
			return FMRES_SUPERCEDE;
		else if( equal( szSound, KnifeDeploy ) )
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}
	
public FwdHamSpawn_Player( id ) {
	g_bAlive[ id ] = bool:is_user_alive( id );
	
	if( g_bAlive[ id ] ) {
		g_iTeam[ id ] = cs_get_user_team( id );
		
		if( g_iSpawnCount[ id ] < 2 ) {
			g_iSpawnCount[ id ]++;
			
			GreenPrint( id, "This server is using^4 HideNSeek^1 mod by^3 xPaw^1!" );
		}
		
		set_task( 0.1, "Task_GiveWeapons", id );
	}
}

public FwdHamKilled_Player( id, iAttacker, iShouldGib ) {
	g_bAlive[ id ]   = bool:is_user_alive( id );
	g_iTeam[ id ]    = cs_get_user_team( id );
	g_bRestore[ id ] = false;
	
	set_pev( id, pev_solid, SOLID_NOT );
	
	if( g_bScrim && g_iTeam[ id ] == CS_TEAM_T ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		if( iNum == 1 ) {
			new iBastard = iPlayers[ 0 ];
			
			g_bNewGrens = true;
			
			GreenPrint( iBastard, "You are the last alive terrorist!" );
			
			menu_display( iBastard, g_iMenuNewGrenades, 0 );
		}
	}
}

public HandleNewGrenades( id, menu, item ) {
	if( !g_bNewGrens || item == MENU_EXIT || !is_user_alive( id ) )
		return PLUGIN_HANDLED;
	
	new szData[ 6 ], access, callback;
	menu_item_getinfo( menu, item, access, szData, 5, _, _, callback );
	
	if( szData[ 0 ] == '1' ) {
		give_item( id, "weapon_smokegrenade" );
		give_item( id, "weapon_flashbang" );
		cs_set_user_bpammo( id, CSW_FLASHBANG, 2 );
		
		client_cmd( id, "spk items/smallmedkit1.wav" );
	} else
		g_bNewGrens = false;
	
	return PLUGIN_HANDLED;
}

public FwdHamSpawn_Grenade( iEntity )
	set_task( 0.01, "SetTrail", iEntity );

public SetTrail( iEntity ) {
	if( !pev_valid( iEntity ) )
		return PLUGIN_CONTINUE;
	
	new szModel[ 32 ], iColor[ 3 ];
	pev( iEntity, pev_model, szModel, charsmax( szModel ) );
	
	switch( szModel[ 9 ] ) {
		case 'h': iColor[ 0 ] = 255;
		case 'f': iColor[ 2 ] = 255;
		case 's': iColor[ 1 ] = 255;
	}
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( iEntity );
	write_short( g_iSprSmoke );
	write_byte( 10 );
	write_byte( 10 );
	write_byte( iColor[ 0 ] );
	write_byte( iColor[ 1 ] );
	write_byte( iColor[ 2 ] );
	write_byte( 100 );
	message_end( );
	
	return PLUGIN_CONTINUE;
}

public FwdHamSpawn_Weaponbox( iEntity ) {
	set_pev( iEntity, pev_flags, FL_KILLME );
	dllfunc( DLLFunc_Think, iEntity );
	
	return HAM_IGNORED;
}

public Task_TeamSwap( ) {
	new iPlayers[ 32 ], iNum, id;
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		g_iTeam[ id ] = cs_get_user_team( id );
		
		switch( g_iTeam[ id ] ) {
			case CS_TEAM_T: cs_set_user_team( id, CS_TEAM_CT ); 
			case CS_TEAM_CT: cs_set_user_team( id, CS_TEAM_T ); 
		}
	}
}	

public Task_GiveWeapons( id ) {
	if( !g_bAlive[ id ] )
		return;
	
	strip_user_weapons( id );
	give_item( id, "weapon_knife" );
	
	g_iTeam[ id ] = cs_get_user_team( id );
	
	switch( g_iTeam[ id ] ) {
		case CS_TEAM_T: {
			set_user_footsteps( id, 1 );
			cs_set_user_armor( id, 100, CS_ARMOR_KEVLAR );
			
			if( !g_bStart )
				Task_GiveGrenades( id );
		}
		case CS_TEAM_CT: {
			if( g_bStart && g_iTimer > 0 ) {
				engfunc( EngFunc_SetClientMaxspeed, id, 0.0000001 );
				set_pev( id, pev_maxspeed, 0.0000001 );
			}
		}
	}
}

public Task_GiveGrenades( id ) {
	if( !g_bAlive[ id ] )
		return;
	
	if( g_bScrim || !g_bStart ) {
		give_item( id, "weapon_smokegrenade" );
		give_item( id, "weapon_flashbang" );
		cs_set_user_bpammo( id, CSW_FLASHBANG, 2 );
	} else {
		if( random_num( 0, 100 ) <= 25 ) {
			give_item( id, "weapon_flashbang" );
			cs_set_user_bpammo( id, CSW_FLASHBANG, 2 );
			
			GreenPrint( id, "You just got^3 2^4 FlashBangs^1! (^3%i%%^1 chance)", 25 );
		}
		else if( random_num( 0, 100 ) <= 50 ) {
			give_item( id, "weapon_flashbang" );
			
			GreenPrint( id, "You just got^4 FlashBang^1! (^3%i%%^1 chance)", 50 );
		}
		
		if( random_num( 0, 100 ) <= 25 ) {
			give_item( id, "weapon_smokegrenade" );
			
			GreenPrint( id, "You just got^4 FrostNade^1! (^3%i%%^1 chance)", 25 );
		}
		
		if( random_num( 0, 100 ) <= 10 ) {
			give_item( id, "weapon_hegrenade" );
			
			GreenPrint( id, "You just got^3 HE Grenade^1! (^3%i%%^1 chance)", 10 );
		}
	}
}

public client_putinserver( id ) {
	g_iSpawnCount[ id ] = 0;
	g_bSawPlayer[ id ] = false;
	
	new szIP[ 32 ];
	get_user_ip( id, szIP, 31 );
	geoip_country( szIP, g_szCountry[ id ], 45 );
	
	if( equal( g_szCountry[ id ], "error" ) ) {
		if( !contain( szIP, "192.168." ) || !contain( szIP, "10." ) || !contain( szIP, "172." ) || equal( szIP, "127.0.0.1" ) )
			g_szCountry[ id ] = "LAN";
		
		else if( equal(szIP, "loopback") )
			g_szCountry[ id ] = "LAN Owner";
		
		else
			g_szCountry[ id ] = "Unknown Country";
	}
}

public client_disconnect( id )
	g_bAlive[ id ] = false;

public CmdJoinTeam( id ) {
	if( 0 < get_user_team( id ) < 3 )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public FwdThinkTimer( ent ) {
	if( !CheckPlayers( 1 ) ) // Maybe someone left or died
		g_iTimer = 0;
	
	if( g_iTimer ) {
		for( new id = 1; id <= g_iMaxPlayers; id++ ) {
			if( g_bAlive[ id ] && g_iTeam[ id ] == CS_TEAM_CT ) {
				engfunc( EngFunc_SetClientMaxspeed, id, 0.0000001 );
				set_pev( id, pev_maxspeed, 0.0000001 );
				
				MakeScreenFade( id, 1 ); 
			}
		}
		
		set_hudmessage( 0, 100, 255, -1.0, 0.82, 0, 0.0, 1.1, 0.0, 0.0, 1 );
		show_hudmessage( 0, "%i seconds to hide..", g_iTimer );
		
		new szSeconds[ 10 ];
		num_to_word( g_iTimer, szSeconds, 9 );
		
		client_cmd( 0, "spk ^"SoUlFaThEr/%s^"", szSeconds );
		
		set_pev( ent, pev_nextthink, get_gametime( ) + 1.0 );
		
		g_iTimer--; // Make the timer decrease
	} else {
		for( new id = 1; id <= g_iMaxPlayers; id++ ) {
			if( !g_bAlive[id] ) // Ignore deadies
				continue;
			
			switch( g_iTeam[ id ] ) {
				case CS_TEAM_T: Task_GiveGrenades( id );
				case CS_TEAM_CT: {
					engfunc( EngFunc_SetClientMaxspeed, id, 250.0 );
					set_pev( id, pev_maxspeed, 250.0 );
					
					MakeScreenFade( id );
				}
			}
		}
		
		set_hudmessage( 0, 100, 255, -1.0, 0.82, 0, 0.0, 2.0, 0.0, 0.4, 1 );
		show_hudmessage( 0, "Ready or not, here we come !" );
	}
}

MakeScreenFade( id, fade = 0 ) {
	message_begin( MSG_ONE, g_iMsgScreenFade, _, id );
	write_short( 8192 * fade );
	write_short( 8192 * fade );
	write_short( 0x0000 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( g_bScrim ? 255 : 200 );
	message_end();
}

bool:CheckPlayers( iStatus ) {
	new iPlayers[ 32 ], iNum, id, iTerrs, iCTs;
	if( iStatus )
		get_players( iPlayers, iNum, "a" );
	else
		get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		g_iTeam[ id ] = cs_get_user_team( id );
		
		switch( g_iTeam[ id ] ) {
			case CS_TEAM_T: iTerrs++;
			case CS_TEAM_CT: iCTs++;
		}
		
		if( iTerrs && iCTs )
			return true;
	}
	
	return false;
}

public BreakStuff( ) {
	new iEntity;
	while( ( iEntity = find_ent_by_class( iEntity, "func_breakable" ) ) > 0 )
		if( pev( iEntity, pev_spawnflags ) != SF_BREAK_TRIGGER_ONLY )
			ExecuteHamB( Ham_TakeDamage, iEntity, 0, 0, 9999.0, DMG_GENERIC );
}

stock ScrimAddScore( iTeam ) { // 0 - T | 1 - CT
	if( g_bChanged ) {
		g_iScores[ iTeam ? 0 : 1 ]++;
		
		if( ( g_iScores[ 0 ] + g_iScores[ 1 ] ) >= 10 ) {
			if( g_iScores[ 0 ] > g_iScores[ 1 ] ) {
				GreenPrint( 0, "Scrim has ended! Team^4 %s^1 won with^4 %i^1 wins!", g_szNames[ 0 ], g_iScores[ 0 ] );
			} else if( g_iScores[ 1 ] > g_iScores[ 0 ] ) {
				GreenPrint( 0, "Scrim has ended! Team^4 %s^1 won with^4 %i^1 wins!", g_szNames[ 1 ], g_iScores[ 1 ] );
			} else
				GreenPrint( 0, "Scrim has ended! Teams are tied!^4 %i - %i^1.", g_iScores[ 0 ], g_iScores[ 1 ] );
			
			g_bChanged = false;
			g_bScrim = false;
			
			server_cmd( "mp_forcecamera 0" );
			server_cmd( "mp_forcechasecam 0" );
			server_cmd( "sv_restart 1" );
		}
	} else {
		g_iScores[ iTeam ]++;
		
		if( ( g_iScores[ 0 ] + g_iScores[ 1 ] ) >= 5 ) {
			g_bChanged = true;
			
			set_task( 0.1, "Task_TeamSwap" );
			
			set_hudmessage( 0, 100, 255, -1.0, 0.82, 0, 0.0, 2.0, 0.2, 0.2, 1 );
			show_hudmessage( 0, "Switching teams!" );
			
			if( g_iScores[ 0 ] > g_iScores[ 1 ] ) {
				GreenPrint( 0, "5 rounds has been passed!^4 %s^1 is leading with^4 %i^1 wins!", g_szNames[ 0 ], g_iScores[ 0 ] );
			} else if( g_iScores[ 1 ] > g_iScores[ 0 ] ) {
				GreenPrint( 0, "5 rounds has been passed!^4 %s^1 is leading with^4 %i^1 wins!", g_szNames[ 1 ], g_iScores[ 1 ] );
			} else // Damn but this cant happen! :D
				GreenPrint( 0, "5 rounds has been passed! Teams are tied!^3 (%i - %i)", g_iScores[ 0 ], g_iScores[ 1 ] );
		}
	}
	
	return 1;
}

stock GreenPrint( id, const message[ ], any:... ) {
	static szMessage[ 192 ], iLen;
	if( !iLen )
		iLen = formatex( szMessage, 191, "^4[HideNSeek]^1 " );
	
	vformat( szMessage[ iLen ], 191 - iLen, message, 3 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
	
	return 1;
}