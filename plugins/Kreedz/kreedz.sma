#include < amxmodx >
#include < fun >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >
#include < sqlx >

//#define SURF_BUILD // Uncomment if being compiled for Surf server
#define MPBHOP_FIX // Uncomment to enable mpbhop fix
//#define XJ_BUILD   // uncomment if being compiled for Xtreme-Jumps

// #pragma dynamic 10240

#define SetUserTeam(%1,%2)   set_pdata_int( %1, m_iTeam, _:%2, 5 )
#define IsPlayer(%1)         ( 1 <= %1 <= g_iMaxPlayers )
#define IsPlayerOnGround(%1) ( entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND2 )
#define SetLeetRender(%1)    UTIL_SetRendering( %1, kRenderFxGlowShell, Float:{ 255.0, 85.0, 0.0 }, kRenderNormal, 16.0 )

#define FindPlayers \
	new iPlayers[ 32 ], iNum; \ 
	get_players( iPlayers, iNum, "b" ); \
	if( iNum ) { \
		new iPlayer; \
		for( new i; i < iNum; i++ ) { \
			iPlayer = iPlayers[ i ]; \
			if( id == g_iSpectateId[ iPlayer ] ) {

#define EndPlayers } } }

#if defined XJ_BUILD
	native kz_is_in_cup( id );
	//kz_is_in_cup(id) { return false; }
#endif

#if defined MPBHOP_FIX
	native mpbhop_set_user_jumpoff( id, Float:JumpOrigin[ 3 ], Float:AngleGravity[ 3 ] );
#endif

#include "include/xpaw_kz/global.inc"
#include "include/xpaw_kz/commands.inc"
#include "include/xpaw_kz/hook.inc"
#include "include/xpaw_kz/util.inc"
#include "include/xpaw_kz/semiclip.inc"
#include "include/xpaw_kz/forwards_messages.inc"

stock Handle:SQL_MakeTupleByCvar( pSqlHost, pSqlUser, pSqlPass, pSqlDb ) {
	new szHost[ 64 ], szUser[ 32 ], szPass[ 32 ], szDb[ 64 ];
	
	get_pcvar_string( pSqlHost, szHost, 63 );
	get_pcvar_string( pSqlUser, szUser, 31 );
	get_pcvar_string( pSqlPass, szPass, 31 );
	get_pcvar_string( pSqlDb, szDb, 63 );
	
	return SQL_MakeDbTuple( szHost, szUser, szPass, szDb );
}

public plugin_init( ) {
	register_plugin( "Kreedz", "1.0", "xPaw" );
	
	set_cvar_num( "mp_flashlight", 1 );
	set_cvar_string( "humans_join_team", "ct" );
	
	g_tRestrictedWeapons = TrieCreate( );
	g_tSounds     = TrieCreate( );
	g_tStarts     = TrieCreate( );
	g_tStops      = TrieCreate( );
	g_iHudSync    = CreateHudSyncObj( );
	g_iMaxPlayers = get_maxplayers( );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	
	// Restricted weapons
	TrieSetCell( g_tRestrictedWeapons, "c4", 1 );
	TrieSetCell( g_tRestrictedWeapons, "hegrenade", 1 );
	TrieSetCell( g_tRestrictedWeapons, "flashbang", 1 );
	TrieSetCell( g_tRestrictedWeapons, "smokegrenade", 1 );
	
	get_mapname( g_szMap, 31 );
	strtolower( g_szMap );
	
	// Cvars
	/*new pSqlPass  = register_cvar( "kreedz_sql_pass",  "",            FCVAR_PROTECTED );
	new pSqlHost  = register_cvar( "kreedz_sql_host",  "localhost",   FCVAR_PROTECTED | FCVAR_PRINTABLEONLY );
	new pSqlUser  = register_cvar( "kreedz_sql_user",  "root",        FCVAR_PROTECTED | FCVAR_PRINTABLEONLY );
	new pSqlDb    = register_cvar( "kreedz_sql_db",    "",            FCVAR_PROTECTED | FCVAR_PRINTABLEONLY );
	new pSqlTable = register_cvar( "kreedz_sql_table", "KreedzTop",   FCVAR_PROTECTED | FCVAR_PRINTABLEONLY );
	new pTopLink  = register_cvar( "kreedz_top_link", "http://example.com/kztop/?r&map=%m%",   FCVAR_PRINTABLEONLY ); // %m% == replaced with map, ?r == doesn't add DOCTYPE on page
	
	new g_szSqlTable[ 33 ];
	get_pcvar_string( pSqlTable, g_szSqlTable, charsmax( g_szSqlTable ) );
	
	g_hSqlTuple = SQL_MakeTupleByCvar( pSqlHost, pSqlUser, pSqlPass, pSqlDb );*/
	
	// SQL
	g_hSqlTuple = SQL_MakeDbTuple( "127.0.0.1", "username", "password", "database" );
	
	register_impulse( 100, "FwdImpulseFlashLight" );
	
	// Register commands
	register_clcmd( "say",         "CmdSay" );
	register_clcmd( "nightvision", "CmdNightVision" );
	
	RegisterCommand( "checkpoint", "CmdCheckPoint" );
	RegisterCommand( "cp",         "CmdCheckPoint" );
	RegisterCommand( "gocheck",    "CmdGoCheck" );
	RegisterCommand( "gc",         "CmdGoCheck" );
	RegisterCommand( "tp",         "CmdGoCheck" );
	RegisterCommand( "stuck",	   "CmdStuck" );
	RegisterCommand( "spec",       "CmdSpectator" );
	RegisterCommand( "unspec",     "CmdCounterTerrorist" );
	RegisterCommand( "ct",         "CmdCounterTerrorist" );
	RegisterCommand( "start",      "CmdStart" );
	RegisterCommand( "invis",      "CmdInvisibility" );
	RegisterCommand( "menu",       "CmdMenu" );
	RegisterCommand( "scout",      "CmdScout" );
	RegisterCommand( "leet",       "CmdLeet" );
	RegisterCommand( "me",         "CmdMyBest" );
	RegisterCommand( "mybest",     "CmdMyBest" );
	
	RegisterCommand( "pause",      "CmdPause" );
	RegisterCommand( "unpause",    "CmdUnPause" );
	
	RegisterCommand( "top15",      "CmdTop" );
	RegisterCommand( "top10",      "CmdTop" );
	RegisterCommand( "pro15",      "CmdTop" );
	RegisterCommand( "pro10",      "CmdTop" );
	RegisterCommand( "nub15",      "CmdTop" );
	RegisterCommand( "nub10",      "CmdTop" );
	
	RegisterCommand( "nc",         "CmdNoclip" );
	RegisterCommand( "noclip",     "CmdNoclip" );
	RegisterCommand( "god",        "CmdGodmode" );
	RegisterCommand( "godmode",    "CmdGodmode" );
	
#if !defined SURF_BUILD
	RegisterCommand( "wr", "CmdWorldRecord" );
	
	register_concmd( "kz_updatewr", "CmdUpdateWR" );
#endif
	
	// Register admin commands
	register_concmd( "kz_hook", "CmdGiveHook" );
	
	// Generate link
	replace( g_szHTML, 223, "%m%", g_szMap );
	
	// Hook
	register_clcmd( "+hook",	"CmdHookOn" );
	register_clcmd( "-hook",	"CmdHookOff" );
	
	// Register Forwards
	register_forward( FM_EmitSound, "FwdEmitSound" );
	register_forward( FM_GetGameDescription, "FwdGameDesc" );
	
	RegisterHam( Ham_Use,        "func_button", "FwdHamButtonUse" );
	RegisterHam( Ham_Touch,        "weaponbox", "FwdHamTouchWeaponBox", 1 );
	RegisterHam( Ham_Spawn,           "player", "FwdHamPlayerSpawnPre" );
	RegisterHam( Ham_Spawn,           "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_TakeDamage,      "player", "FwdHamPlayerTakeDamage", 1 );
	RegisterHam( Ham_Item_PreFrame,   "player", "FwdHamPlayerResetSpeed" );
	RegisterHam( Ham_Killed,          "player", "FwdHamPlayerKilled", 1 );
	RegisterHam( Ham_Player_PreThink, "player", "FwdHamPlayerPreThink", 1 );
	
	register_forward( FM_AddToFullPack, "FwdAddToFullPack", 1 );
	
	// Block radio
	register_clcmd( "radio1", "CmdBlock" );
	register_clcmd( "radio2", "CmdBlock" );
	register_clcmd( "radio3", "CmdBlock" );
	
	// Block autobuy
	register_clcmd( "cl_setautobuy", "CmdBlock" );
	register_clcmd( "cl_setrebuy", "CmdBlock" );
	
	// Block messages
	g_iMsgFlashLight = get_user_msgid( "Flashlight" );
	g_iMsgRoundTime  = get_user_msgid( "RoundTime" );
	g_iMsgTeamInfo   = get_user_msgid( "TeamInfo" );
	
	set_msg_block( ( g_iMsgDeathMsg = get_user_msgid( "DeathMsg" ) ), BLOCK_SET );
	set_msg_block( get_user_msgid( "Geiger" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "ClCorpse" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	register_message( g_iMsgRoundTime,                 "MessageRoundTime" );
	register_message( get_user_msgid( "Health" ),      "MessageHealth" );
	register_message( get_user_msgid( "TextMsg" ),     "MessageTextMsg" );
	register_message( get_user_msgid( "ScoreInfo" ),   "MessageScoreInfo" );
	register_message( get_user_msgid( "StatusText" ),  "MessageStatusText" );
	
	register_event( "SpecHealth2", "EventSpecHealth",  "bd" );
	register_event( "CurWeapon",   "EventCurWeapon",   "be", "1=1" );
	
	// Register menus
	register_menucmd( register_menuid( "Invisibility" ), 1023, "HandleInvisMenu" );
	
	// Timers
	new const szStarts[ ][ ] = {
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
	};
	new const szStops[ ][ ]  = {
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	};
	
	new i;
	for( i = 0; i < sizeof szStarts; i++ )
		TrieSetCell( g_tStarts, szStarts[ i ], 1 );
	
	for( i = 0; i < sizeof szStops; i++ )
		TrieSetCell( g_tStops, szStops[ i ], 1 );
	
	// Silent Doors
	i = g_iMaxPlayers + 1;
	
	new const szNull[ ] = "common/null.wav";
	
	while( ( i = find_ent_by_class( i, "func_door" ) ) ) {
		if( entity_get_float( i, EV_FL_dmg ) < -999.0 ) {
			entity_set_string( i, EV_SZ_noise1, szNull );
			entity_set_string( i, EV_SZ_noise2, szNull );
			entity_set_string( i, EV_SZ_noise3, szNull );
			
			g_bAutoHeal = true;
		}
	}
	
	// Autoheal
	if( !g_bAutoHeal ) {
		i = create_entity( "trigger_hurt" );
		
		if( is_valid_ent( i ) ) {
			DispatchKeyValue( i, "classname", "trigger_hurt" );
			DispatchKeyValue( i, "damagetype", "1024" );
			DispatchKeyValue( i, "dmg", "-50" );
			
			DispatchSpawn( i );
			
			entity_set_size( i, Float:{ -4096.0, -4096.0, -4096.0 }, Float:{ 4096.0, 4096.0, 4096.0 } );
			entity_set_int( i, EV_INT_solid, SOLID_TRIGGER );
		}
	}
	
	// No weapons shoot
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_m4a1", "FwdHamItemDeploy", 1 );
	
	new szWeaponName[ 20 ];
	for( i = CSW_P228; i <= CSW_P90; i++ ) {
		if( i == CSW_USP || i == CSW_KNIFE )
			continue;
		
		if( get_weaponname( i, szWeaponName, 19 ) )
			RegisterHam( Ham_Item_Deploy, szWeaponName, "FwdHamItemDeploy", 1 );
	}
	
	// Sounds
	new const szBlockSounds[ ][ ] = {
		"player/pl_wade1.wav", "player/pl_wade2.wav", "player/pl_wade3.wav", "player/pl_wade4.wav", 
		"player/pl_pain2.wav", "player/pl_pain3.wav","player/pl_pain4.wav", "items/9mmclip1.wav",
		"player/pl_pain5.wav", "player/pl_pain6.wav", "player/pl_pain7.wav", "player/death6.wav",
		"player/bhit_kevlar-1.wav", "player/bhit_flesh-1.wav", "player/bhit_flesh-2.wav",
		"player/bhit_flesh-3.wav","player/pl_swim1.wav", "player/pl_swim2.wav",
		"player/pl_swim3.wav", "player/pl_swim4.wav", "player/waterrun.wav",
		"player/die1.wav", "player/die2.wav", "player/die3.wav",
		"player/headshot1.wav", "player/headshot2.wav", "player/headshot3.wav"
	};
	
	new const szOldSounds[ ][ ] = {
		"weapons/knife_hit1.wav",
		"weapons/knife_hit2.wav",
		"weapons/knife_hit3.wav",
		"weapons/knife_hit4.wav",
		"weapons/knife_stab.wav"
	};
	
	new const szNewSounds[ ][ ] = {
		"weapons/knife_slash1.wav",
		"weapons/knife_slash1.wav",
		"weapons/knife_slash1.wav",
		"weapons/knife_slash1.wav",
		"weapons/knife_slash2.wav"
	};
	
	for( i = 0; i < sizeof szOldSounds; i++ )
		TrieSetString( g_tSounds, szOldSounds[ i ], szNewSounds[ i ] );
	
	for( i = 0; i < sizeof szBlockSounds; i++ )
		TrieSetString( g_tSounds, szBlockSounds[ i ], "" );
	
#if !defined SURF_BUILD
	LoadWorldRecord( );
#endif
	
	LoadLeetClimber( );
	LoadStartLocation( );
	FindWaterEntities( );
	
	// Delete entities
	new const szDeleteEntities[ ][ ] = {
		"func_buyzone", "env_sound", "info_map_parameters", "info_player_deathmatch",
		"player_weaponstrip", "game_player_equip", "armoury_entity", "item_longjump"
	};
	
	new iEntity;
	for( i = 0; i < sizeof szDeleteEntities; i++ ) {
		iEntity = g_iMaxPlayers + 1;
		
		while( ( iEntity = find_ent_by_class( iEntity, szDeleteEntities[ i ] ) ) > 0 ) {
			if( !i && entity_get_int( i, EV_INT_iuser1 ) == 1337 ) continue;
			
			remove_entity( iEntity );
		}
	}
	
	// Register forwards
	g_iFwdTimerStart    = CreateMultiForward( "kz_timer_start",    ET_IGNORE, FP_CELL );
	g_iFwdTimerStop     = CreateMultiForward( "kz_timer_stop",     ET_IGNORE, FP_CELL, FP_FLOAT );
	g_iFwdCheatDetected = CreateMultiForward( "kz_cheat_detected", ET_IGNORE, FP_CELL );
}

public plugin_end( ) {
	SQL_FreeHandle( g_hSqlTuple );
	/*TrieDestroy( g_tRestrictedWeapons );
	TrieDestroy( g_tSounds );
	TrieDestroy( g_tStarts );
	TrieDestroy( g_tStops );
	
	if( g_tWaterEntities )
		TrieDestroy( g_tWaterEntities );*/
}

public plugin_precache( ) {
	g_iBeam = precache_model( "sprites/zbeam4.spr" );
	
	// Create buyzone
	new i = create_entity( "func_buyzone" );
	
	if( is_valid_ent( i ) ) {
		entity_set_size( i, Float:{ -4096.0, -4096.0, -4096.0 }, Float:{ -4095.0, -4095.0, -4095.0 } );
		entity_set_int( i, EV_INT_iuser1, 1337 );
	}
}

public plugin_natives( ) {
	register_library( "Kreedz" );
	
	register_native( "kz_detect_cheat", "NativeCheatDetect" );
}

public NativeCheatDetect( const iPlugin, const iParams ) {
	new id = get_param( 1 );
	
	if( !IsPlayer( id ) ) {
		log_error( AMX_ERR_BOUNDS, "[KREEDZ] index out of bounds (%i)", id );
		return;
	}
	
	new szCheat[ 32 ];
	get_string( 2, szCheat, 31 );
	
	CheatDetect( id, szCheat );
}

// CLIENT
// ==================================================================================
public client_authorized( id ) {
#if defined XJ_BUILD
	g_bAdmin[ id ] = bool:( get_user_flags( id ) & ADMIN_RESERVATION );
#else
	g_bAdmin[ id ] = bool:( get_user_flags( id ) & ADMIN_KICK );
#endif
	
	if( g_bAdmin[ id ] )
		g_bFinishedMap[ id ] = true;
	
	new szSteamId[ 30 ];
	get_user_authid( id, szSteamId, 29 );
	
	if( equal( szSteamId, g_szLeetSteamId ) ) {
		g_iLeet = id;
		
		if( is_user_alive( id ) )
			SetLeetRender( id );
	}
}

public client_putinserver( id ) {
	g_bConnected[ id ] = true;
}

public client_disconnect( id ) {
	g_flStartTime [ id ] = 0.0;
	g_flPaused    [ id ] = 0.0;
	g_iGoChecks   [ id ] = 0;
	g_iCheckPoints[ id ] = 0;
	g_iSpectateId [ id ] = 0;
	
	g_bBetaMsg  [ id ] = false;
	g_bConnected[ id ] = false;
	
	g_bInvisPlayers[ id ] = false;
	g_bInvisWater  [ id ] = false;
	
	g_bNightVision[ id ] = false;
	g_bProDisabled[ id ] = false;
	g_bFinishedMap[ id ] = false;
	g_bCpAlternate[ id ] = false;
	g_bAfterHook  [ id ] = false;
	g_bHook       [ id ] = false;
	g_bAdmin      [ id ] = false;
	
	new Float:vEmpty[ 3 ];
	g_vCheckPoints[ id ][ 0 ] = vEmpty;
	g_vCheckPoints[ id ][ 1 ] = vEmpty;
	g_vCheckAngles[ id ][ 0 ] = vEmpty;
	g_vCheckAngles[ id ][ 1 ] = vEmpty;
	g_vSavedOrigin[ id ]      = vEmpty;
	g_vSavedAngles[ id ]      = vEmpty;
	g_vUserStart  [ id ]      = vEmpty;
	g_vUserAngle  [ id ]      = vEmpty;
	
	if( g_iLeet == id )
		g_iLeet = 0;
}

public vip_removed( const id )
	g_bAdmin[ id ] = false;

public vip_connected( const id ) {
	g_bFinishedMap[ id ] = true;
	g_bAdmin[ id ] = true;
}

LoadStartLocation( ) {
	get_localinfo( "amxx_datadir", g_szStartFile, 127 );
	add( g_szStartFile, 127, "/kreedz/KzButtonPos.ini" );
	
	if( !file_exists( g_szStartFile ) ) {
		write_file( g_szStartFile, "// #kz.xPaw - Button locations", -1 );
		write_file( g_szStartFile, " ", -1 );
	}
	
	new szData[ 136 ], szMap[ 32 ], szOrigin[ 3 ][ 16 ], szAngles[ 3 ][ 16 ];
	new iFile = fopen( g_szStartFile, "rt" );
	
	if( !iFile ) return;
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, 135 );
		trim( szData );
		
		if( szData[ 0 ] == ';' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		parse( szData, szMap, 31,
			szOrigin[ 0 ], 16, szOrigin[ 1 ], 16, szOrigin[ 2 ], 16,
			szAngles[ 0 ], 16, szAngles[ 1 ], 16, szAngles[ 2 ], 16 );
		
		if( equal( szMap, g_szMap ) ) {
			g_vStartOrigin[ 0 ] = str_to_float( szOrigin[ 0 ] );
			g_vStartOrigin[ 1 ] = str_to_float( szOrigin[ 1 ] );
			g_vStartOrigin[ 2 ] = str_to_float( szOrigin[ 2 ] );
			g_vStartAngles[ 0 ] = str_to_float( szAngles[ 0 ] );
			g_vStartAngles[ 1 ] = str_to_float( szAngles[ 1 ] );
			g_vStartAngles[ 2 ] = str_to_float( szAngles[ 2 ] );
			
			break;
		}
	}
	
	fclose( iFile );
}

LoadLeetClimber( ) {
	new szQuery[ 200 ];
	formatex( szQuery, 199, "SELECT Time,Name,SteamId FROM `%s` WHERE Map='%s' AND Type=0 ORDER BY Time ASC LIMIT 1",
		SqlTable, g_szMap );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleSelectLeet", szQuery );
}

#if !defined SURF_BUILD
LoadWorldRecord( ) {
	new szQuery[ 200 ];
	formatex( szQuery, 199, "SELECT Time,Name,Ip FROM `%s` WHERE Map='%s' AND Type=2 ORDER BY Time ASC",
		SqlTable, g_szMap );
	
	SQL_ThreadQuery( g_hSqlTuple, "HandleSelectWR", szQuery );
}

public CmdUpdateWR( const id ) {
	if( !id || g_bAdmin[ id ] ) {
		LoadWorldRecord( );
		console_print( id, "[KREEDZ] Update forced." );
	} else
		console_print( id, "[KREEDZ] You have no access to this command." );
	
	return PLUGIN_HANDLED;
}
#endif

public CmdGiveHook( const id ) {
	if( !id || g_bAdmin[ id ] ) {
		new szArg[ 32 ];
		read_argv( 1, szArg, 31 );
		
		new iPlayer = CommandTarget( id, szArg );
		
		if( iPlayer && iPlayer != id ) {
			new szName[ 32 ], szAdmin[ 32 ];
			get_user_name( iPlayer, szName, 31 );
			get_user_name( id, szAdmin, 31 );
			
			console_print( id, "[KREEDZ] You gave hook to %s", szName );
			
			ColorChat( iPlayer, Red, "%s^3 %s^1 gave you access to hook.", Prefix, szAdmin );
			
			g_bFinishedMap[ iPlayer ] = true;
		} else {
			console_print( id, "[KREEDZ] Player not found." );
		}
	} else
		console_print( id, "[KREEDZ] You have no access to this command." );
	
	return PLUGIN_HANDLED;
}
