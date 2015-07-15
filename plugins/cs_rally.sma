#include < amxmodx >
#include < amxmisc >
#include < fun >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < orpheu_memory >

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )

#define SPRITE          "sprites/csrally_checkpoint.spr"
#define SPR_CLASSNAME   "csrally_cp_sprite"
#define CPS_CLASSNAME   "csrally_checkpoint"

#define RANK_DELAY      0.5
#define MAX_ZONES       10
#define RACE_LAPS       2

enum (+=2000) {
	TASK_HUDUPD = 10000,
	TASK_RDYHUD,
	TASK_SHOWZONES,
	TASK_RACEEND
};

new const g_szCoordinates[ 3 ][ ] = { "x-coordinates", "y-coordinates", "z-coordinates" };
new const g_szHandsView[ ]       = "models/interior.mdl";
new const g_szSound_CountDown[ ] = "sound/carmod/countdown.mp3";
new const g_szSound_Engine[ ]    = "carmod/engine2.wav";
new const g_szSound_Horn[ ]      = "carmod/horn.wav";
new const g_szSound_EngStart[ ]  = "plats/vehicle_start1.wav";
new const g_szSound_CP[ ]        = "carmod/checkpoint.wav";

new const g_szSound_HitNorm[ ]   = "carmod/hitwall1.wav";
new const g_szSound_HitHard[ ]   = "carmod/hitwall2.wav";

new const g_szCarModels[ ][ ] = {
	"206",
	"accent",
	"celica",
	"corolla",
	"evo7",
	"fabia",
	"impreza2002",
	"xsara"
};
/*
new const g_szCarNames[ ][ ] = {
	"Peugeot",
	"Hyundai",
	"Celica GT",
	"Toyota Corolla",
	"Mitsubishi",
	"Skoda Fabia",
	"Subaru Impreza",
	"Citroen XSara"
};
*/
new g_iZones[ MAX_ZONES ];
new g_iSprite;
new g_iEditor;
new g_iCurrZone;
new g_iZonesCount;
new g_iDirection;
new g_iStepUnits = 10;

new g_iColor_Active[ 3 ] = { 0, 0, 255 };
new g_iColor_Red[ 3 ]    = { 255, 0, 0 };
new g_iColor_Green[ 3 ]  = { 255, 255, 0 };
new g_iColor_Blue[ 3 ]   = { 255, 255, 255 };

#define m_pPlayer               41
#define m_flNextPrimaryAttack   46
#define m_flNextSecondaryAttack 47
#define m_iRadiosLeft           192
#define	m_iHideHUD              361
#define	m_iClientHideHUD        362
#define	m_pClientActiveItem     374
#define m_flNextDecalTime       486

const HUD_HIDE = ( 1 << 1 ) | ( 1 << 4 ) | ( 1 << 5 ) | ( 1 << 6 )

new Float:g_fLastHit[ 33 ];
new Float:g_fLastHorn[ 33 ];
new Float:g_flLastThink[ 33 ];
new Float:g_flSpeedLastThink[ 33 ];
new Float:g_fWinners[ 3 ];
new Float:g_fLastLap[ 33 ];
new Float:g_fBestPersLap[ 33 ];
new Float:g_fLastLapTime[ 33 ];
new Float:g_fStartTime[ 33 ];
new Float:g_fCheckPointTime[ 33 ];
new Float:g_fRaceTime[ 33 ];
new Float:g_flRoundStartTime;
new Float:g_fBestLap;

new bool:g_bRoundStart;
new bool:g_bRaceRun;
new bool:g_bStarted[ 33 ];
new bool:g_bFinished[ 33 ];
new bool:g_bConnected[ 33 ];
new bool:g_bPlayerAlive[ 33 ];

new Trie:g_tRoundStartSounds;
new Trie:g_tBlockSounds;

new g_iSendAudioMessage;
new g_iMsgStatusIcon;
new g_iMsgScreenFade;
new g_iMsgSendAudio;
new g_iMaxPlayers;
new g_iFinished;
new g_iPlayerLaps[ 33 ];
new g_iLastCheckPoint[ 33 ];

new g_szWinners[ 3 ][ 32 ];
new g_szBestLap[ 32 ];
new g_szModel[ 33 ][ 12 ];

#define set_mp_pdata(%1,%2)  ( OrpheuMemorySetAtAddress( handleGameRules, %1, 1, %2 ) )

public plugin_init( ) {
	register_plugin( "CS Rally", "1.0", "xPaw" );
	
	register_menu( "CSR_MainMenu", -1, "HandleMainMenu", 0 );
	register_menu( "CSR_EditMenu", -1, "HandleEditMenu", 0 );
	register_menu( "CSR_KillMenu", -1, "HandleKillMenu", 0 );
	
	register_clcmd( "radio1",     "CmdBlock" );
	register_clcmd( "radio2",     "CmdBlock" );
	register_clcmd( "radio3",     "CmdBlock" );
	register_clcmd( "chooseteam", "CmdBlock" );
	
	register_clcmd( "rally_cps", "CmdRallyCpsMenu", ADMIN_RCON );
	
	register_event( "HideWeapon", "EventHideWeapon", "b" );
	register_event( "ResetHUD",   "EventResetHUD",   "b" );
	register_event( "CurWeapon",  "EventCurWeapon",  "be", "1=1" );
	
	g_iMsgStatusIcon = get_user_msgid( "StatusIcon" )
	g_iMsgSendAudio  = get_user_msgid( "SendAudio" );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	g_iMaxPlayers    = get_maxplayers( );
	
	set_msg_block( get_user_msgid( "DeathMsg" ),   BLOCK_SET );
//	set_msg_block( get_user_msgid( "ClCorpse" ),   BLOCK_SET );
	set_msg_block( get_user_msgid( "WeapPickup" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "AmmoPickup" ), BLOCK_SET );
	
	register_message( g_iMsgStatusIcon,             "MsgStatusIcon" );
	register_message( get_user_msgid( "ClCorpse" ), "MsgClCorpse" );
	register_message( get_user_msgid( "ShowMenu" ), "MsgShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ), "MsgVGUIMenu" );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	register_logevent( "EventRoundStart", 2, "0=World triggered", "1=Round_Start" );
	
	register_impulse( 201, "FwdImpulse_201" );
	register_touch( CPS_CLASSNAME, "player", "CpsTouch" );
	register_touch( "worldspawn", "player", "TrgWorldTouch" );
	
	register_forward( FM_EmitSound,         "FwdEmitSound" );
	register_forward( FM_PlayerPreThink,    "FwdPlayerPreThink" );
	register_forward( FM_PlayerPostThink,   "FwdPlayerPostThink" );
	register_forward( FM_UpdateClientData,  "FwdUpdateClientData", 1 );
	register_forward( FM_SetClientKeyValue, "FwdSetClientKeyValue" );
	
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "FwdHamKnifeDeploy", 1 );
	RegisterHam( Ham_Player_Jump, "player", "FwdHamPlayerJump" );
	RegisterHam( Ham_Player_Duck, "player", "FwdHamPlayerDuck" );
	RegisterHam( Ham_Spawn,       "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_Killed,      "player", "FwdHamPlayerKilled", 1 );
	
	set_task( 1.0, "LoadZones" );
	set_task( 2.0, "task_DoCvars" );
	
	g_tRoundStartSounds = TrieCreate( );
	g_tBlockSounds      = TrieCreate( );
	
	// Some sounds 'n' tries stuff
	new const szStartRadios[][] = { "%!MRAD_GO", "%!MRAD_LOCKNLOAD", "%!MRAD_LETSGO", "%!MRAD_MOVEOUT" };
	new const szSounds[ ][ ] = { "weapons/knife_deploy1.wav", "items/gunpickup2.wav", "player/die1.wav",
		"player/die3.wav", "player/die3.wav", "player/death6.wav" };
	
	new i;
	for( i = 0; i < sizeof szStartRadios; i++ ) TrieSetCell( g_tRoundStartSounds, szStartRadios[ i ], 1 );
	for( i = 0; i < sizeof szSounds; i++ ) TrieSetCell( g_tBlockSounds, szSounds[ i ], 1 );
}

public CmdBlock( id )
	return PLUGIN_HANDLED;

public task_DoCvars( ) {
	server_cmd( "mp_freezetime 5" );
	server_cmd( "sv_maxvelocity 2000" );
	server_cmd( "sv_maxspeed 2000" );
	server_cmd( "sv_gravity 520" );
	server_cmd( "sv_stepsize 8" );
	server_cmd( "sv_airaccelerate 0.1" );
	server_cmd( "mp_autoteambalance 0" );
	server_cmd( "mp_footsteps 0" );
	server_cmd( "mp_flashlight 0" );
	server_cmd( "mp_limitteams 32" );
	server_cmd( "sv_restart 1" );
}

public plugin_end( ) {
	TrieDestroy( g_tBlockSounds );
	TrieDestroy( g_tRoundStartSounds );
}

public plugin_precache( ) {
	g_iSprite = precache_model( "sprites/dot.spr" );
	precache_model( SPRITE );
	precache_model( g_szHandsView );
	precache_model( "models/rpgrocket.mdl" );
	
	precache_generic( g_szSound_CountDown );
	precache_sound( g_szSound_Engine );
	precache_sound( g_szSound_EngStart );
	precache_sound( g_szSound_Horn );
	precache_sound( g_szSound_CP );
	precache_sound( g_szSound_HitNorm );
	precache_sound( g_szSound_HitHard );
	precache_sound( "carmod/_period.wav" ); // Empty sound ftw
	
	// Car models
	new szModel[ 128 ];
	for( new i; i < sizeof( g_szCarModels ); i++ ) {
		formatex( szModel, 127, "models/player/%s/%s.mdl", g_szCarModels[ i ], g_szCarModels[ i ] );
		
		precache_model( szModel );
	}
	
	// Ct spawns -> T spawns
	RegisterHam( Ham_Spawn, "info_player_start", "FwdHamSpawn_CT", 1 );
	
	// Stuff
	new iEntity = create_entity( "player_weaponstrip" );
	DispatchKeyValue( iEntity, "origin", "9999 9999 9999" );
	DispatchKeyValue( iEntity, "targetname", "stripper" );
	DispatchSpawn( iEntity );
	
	iEntity = create_entity( "game_player_equip" );
	DispatchKeyValue( iEntity, "weapon_knife", "1" );
	DispatchKeyValue( iEntity, "targetname", "equipment" );
	DispatchSpawn( iEntity );
	
	iEntity = create_entity( "multi_manager" );
	DispatchKeyValue( iEntity, "stripper", "0" );
	DispatchKeyValue( iEntity, "equipment", "0.1" );
	DispatchKeyValue( iEntity, "targetname", "game_playerspawn" );
	DispatchKeyValue( iEntity, "spawnflags", "1" );
	DispatchSpawn( iEntity );
	
	iEntity = create_entity( "info_map_parameters" );
	DispatchKeyValue( iEntity, "buying", "3" );
	DispatchSpawn( iEntity );
}

public FwdHamSpawn_CT( iEntity ) {
	new szClass[ 32 ];
	entity_get_string( iEntity, EV_SZ_classname, szClass, 16 );
	
	if( szClass[ 5 ] != 'p' || szClass[ 12 ] != 's' )
		return HAM_IGNORED;
	
	new Float:vAngles[ 3 ], Float:vOrigin[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	entity_get_vector( iEntity, EV_VEC_angles, vAngles );
	
	entity_set_int( iEntity, EV_INT_flags, FL_KILLME );
	call_think( iEntity );
	
	iEntity = create_entity( "info_player_deathmatch" );
	
	if( !is_valid_ent( iEntity ) )
		return HAM_IGNORED;
	
	entity_set_vector( iEntity, EV_VEC_origin, vOrigin );
	entity_set_vector( iEntity, EV_VEC_angles, vAngles );
	
	return HAM_IGNORED;
}

public client_connect( id )
	client_cmd( id, ";cl_minmodels 0;cl_forwardspeed 2000;cl_sidespeed 2000;cl_backspeed 2000" );

public client_putinserver( id ) {
	g_bConnected[ id ] = true;
	g_bPlayerAlive[ id ] = false;
	
	if( !is_user_bot( id ) )
		set_task( 0.1, "Init_Checks", id );
}

public client_disconnect( id ) {
	remove_task( id );
	
	g_bConnected[ id ] = false;
	g_bPlayerAlive[ id ] = false;
	
	if( id == g_iEditor )
		HideAllZones( );
}

public CmdRallyCpsMenu( id ) {
	if( !(get_user_flags( id ) & ADMIN_RCON ) )
		return PLUGIN_HANDLED;
	
	if( g_bConnected[ g_iEditor ] && g_iEditor != id ) {
		console_print( id, "Someone is already using menu!" );
		
		return PLUGIN_HANDLED;
	}
	
	g_iEditor = id;
	
	FindAllZones( );
	ShowAllZones( );
	
	set_task( 0.1, "OpenMenu", id );
	
	return PLUGIN_HANDLED;
}

public OpenMenu( id ) {
	new szMenu[ 512 ], iKeys = MENU_KEY_0 + MENU_KEY_4 + MENU_KEY_9;
	
	formatex( szMenu, 511, "\r[CS Rally] \wCheckpoints Menu^n \r%i \wzones found", g_iZonesCount );
	
	if( pev_valid( g_iZones[ g_iCurrZone ] ) ) {
		format( szMenu, 511, "%s (Current: \r%i\w)", szMenu, g_iCurrZone + 1 );
		
		format( szMenu, 511, "%s^n^n\r1. \wEdit Current Zone^n      \r2 \y<- \wPrevious     \r3 \y-> \wNext", szMenu );
		
		iKeys += MENU_KEY_1 + MENU_KEY_2 + MENU_KEY_3;
	}
	
	format( szMenu, 511, "%s^n^n\r4. \wCreate New Zone", szMenu );
	
	if( pev_valid( g_iZones[ g_iCurrZone ] ) ) {
		format( szMenu, 511, "%s^n^n\r5. \wDelete Current Zone", szMenu );
		
		iKeys += MENU_KEY_5;
	}
	
	format( szMenu, 511, "%s^n^n\r9. \wSave All Zones^n\r0. \wExit^n^n \r!!! First zone should be start !!!", szMenu );
	
	show_menu( id, iKeys, szMenu, -1, "CSR_MainMenu" );
	
	return PLUGIN_HANDLED;
}

public OpenEditMenu( id ) {
	new szMenu[ 512 ];
	
	formatex( szMenu, 511, "\r[CS Rally] \wZone Edit Menu^n^n" );
	
	format( szMenu, 511, "%s^n^n\r1. \wChange Size Over '\y%s\w'^n", szMenu, g_szCoordinates[ g_iDirection ] );
	format( szMenu, 511, "%s^n      \r5 <- strip       6 -> wider\w", szMenu );
	format( szMenu, 511, "%s^n      \y7 <- strip       8 -> wider\w", szMenu );
	format( szMenu, 511, "%s^n^n\r9. \wIncrement \d%i\w units^n\r0. \wBack", szMenu, g_iStepUnits );
	
	show_menu( id, ( MENU_KEY_0 + MENU_KEY_1 + MENU_KEY_5 + MENU_KEY_6 + MENU_KEY_7 + MENU_KEY_8 + MENU_KEY_9 ), szMenu, -1, "CSR_EditMenu" );
}

public HandleEditMenu( id, iKey ) {
	iKey = ( iKey == 10 ) ? 0 : iKey + 1;
	
	switch( iKey ) {
		case 1 : g_iDirection = ( g_iDirection < 2 ) ? g_iDirection + 1 : 0;
			case 5 : RedAdd( );
			case 6 : RedDelete( );
			case 7 : GreenDelete( );
			case 8 : GreenAdd( );
			case 9 : g_iStepUnits = ( g_iStepUnits < 100 ) ? g_iStepUnits * 10 : 1;
			case 10: CmdRallyCpsMenu( id );
		}
	
	if( iKey != 10 )
		OpenEditMenu( id );
}

public HandleMainMenu( id, iKey ) {
	iKey = ( iKey == 10 ) ? 0 : iKey + 1;
	
	switch( iKey ) {
		case 1: {
			if( pev_valid( g_iZones[ g_iCurrZone ] ) )
				OpenEditMenu( id );
			else
				CmdRallyCpsMenu( id );
		}
		case 2: {
			g_iCurrZone = ( g_iCurrZone > 0 ) ? g_iCurrZone - 1 : g_iCurrZone;
			
			OpenMenu( id );
		}
		case 3: {
			g_iCurrZone = ( g_iCurrZone < g_iZonesCount - 1 ) ? g_iCurrZone + 1 : g_iCurrZone;
			
			OpenMenu( id );
		}
		case 4: {
			if( g_iZonesCount < MAX_ZONES - 1 ) {
				CreateZoneOnPlayer( id );
				ShowAllZones( );
				
				HandleMainMenu( id, 0 );
			} else {
				GreenPrint( id, "You can't create more zones." );
				CmdRallyCpsMenu( id );
			}
		}
		case 5: OpenKillMenu( id );
		case 9: {
			SaveZones( id );
			CmdRallyCpsMenu( id );
		}
		case 10: {
			g_iEditor = 0;
			HideAllZones( );
		}
	}
}

public OpenKillMenu( id ) {
	new szMenu[ 96 ];
	formatex( szMenu, 95, "\r[CS Rally] \yATTENTION!\w Delete current zone?^n^n\r1. \wNo^n\r0. \wYes" );
	
	show_menu( id, ( MENU_KEY_0 + MENU_KEY_1 ), szMenu, -1, "CSR_KillMenu" );
}

public HandleKillMenu( id, iKey ) {
	iKey = ( iKey == 10 ) ? 0 : iKey + 1;
	
	switch( iKey ) {
		case 1: GreenPrint( id, "Zone has'nt been deleted." );
		case 10: {
			GreenPrint( id, "Zone has been deleted." );
			
			new iSprite = pev( g_iZones[ g_iCurrZone ], pev_euser4 );
			
			if( pev_valid( iSprite ) )
				remove_entity( iSprite );
			
			remove_entity( g_iZones[ g_iCurrZone ] );
			
			g_iCurrZone--;
			
			if( g_iCurrZone < 0 )
				g_iCurrZone = 0;
		}
	}
	
	CmdRallyCpsMenu( id );
}

public CreateZone( Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ] ) {
	new iEntity = create_entity( "info_target" );
	
	if( !pev_valid( iEntity ) )
		return 0;
	
	set_pev( iEntity, pev_classname, CPS_CLASSNAME );
	set_pev( iEntity, pev_movetype, MOVETYPE_FLY );
	
	if( g_iEditor )
		set_pev( iEntity, pev_solid, SOLID_NOT );
	else
		set_pev( iEntity, pev_solid, SOLID_TRIGGER );
	
	set_pev( iEntity, pev_origin, vOrigin );
	entity_set_size( iEntity, vMins, vMaxs );
	set_entity_visibility( iEntity, 0 );
	
	return iEntity;
}

public CreateNewZone( Float:vOrigin[ 3 ] )
	return CreateZone( vOrigin, Float:{ -32.0, -32.0, -32.0 }, Float:{ 32.0, 32.0, 32.0 } );

public CreateZoneOnPlayer( id ) {
	new Float:vOrigin[ 3 ];
	pev( id, pev_origin, vOrigin );
	
	new iEntity = CreateNewZone( vOrigin );
	
	FindAllZones( );
	
	for( new i = 0; i < MAX_ZONES; i++ )
		if( g_iZones[ i ] == iEntity )
		g_iCurrZone = i;
}

public FindAllZones( ) {
	new iEntity = -1;
	g_iZonesCount = 0;
	g_iCurrZone = 0;
	
	arrayset( g_iZones, 0, MAX_ZONES - 1 );
	
	while( ( iEntity = find_ent_by_class( iEntity, CPS_CLASSNAME ) ) > 0 ) {
		g_iZones[ g_iZonesCount ] = iEntity;
		g_iCurrZone = g_iZonesCount;
		
		g_iZonesCount++;
	}
}

public HideAllZones( ) {
	new iZone;
	g_iEditor = 0;
	
	for( new i = 0; i < MAX_ZONES; i++ ) {
		iZone = g_iZones[ i ];
		
		remove_task( TASK_SHOWZONES + iZone );
		
		set_pev( iZone, pev_solid, SOLID_TRIGGER );
	}
}

public ShowAllZones( ) {
	FindAllZones( );
	
	new iZone;
	for( new i = 0; i < MAX_ZONES; i++ ) {
		iZone = g_iZones[ i ];
		
		remove_task( TASK_SHOWZONES + iZone );
		
		set_pev( iZone, pev_solid, SOLID_NOT );
		
		set_task( 0.2, "ShowZoneBox", TASK_SHOWZONES + iZone, _, _, "b" );
	}
}

// Shitty Add/Delete functions
public RedAdd( ) {
	new iEntity = g_iZones[ g_iCurrZone ];
	
	new Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	pev( iEntity, pev_mins, vMins );
	pev( iEntity, pev_maxs, vMaxs );
	
	if( ( floatabs( vMins[ g_iDirection ] ) + vMaxs[ g_iDirection ] ) < g_iStepUnits + 1 )
		return;
	
	vMins[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	vMaxs[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	vOrigin[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	
	set_pev( iEntity, pev_origin, vOrigin );
	entity_set_size( iEntity, vMins, vMaxs );
}

public GreenAdd( ) {
	new iEntity = g_iZones[ g_iCurrZone ];
	
	new Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	pev( iEntity, pev_mins, vMins );
	pev( iEntity, pev_maxs, vMaxs );
	
	vMins[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	vMaxs[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	vOrigin[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	
	set_pev( iEntity, pev_origin, vOrigin );
	entity_set_size( iEntity, vMins, vMaxs );
}

public RedDelete( ) {
	new iEntity = g_iZones[ g_iCurrZone ];
	
	new Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	pev( iEntity, pev_mins, vMins );
	pev( iEntity, pev_maxs, vMaxs );
	
	vMins[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	vMaxs[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	vOrigin[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	
	set_pev( iEntity, pev_origin, vOrigin );
	entity_set_size( iEntity, vMins, vMaxs );
}

public GreenDelete( ) {
	new iEntity = g_iZones[ g_iCurrZone ];
	
	new Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	pev( iEntity, pev_mins, vMins );
	pev( iEntity, pev_maxs, vMaxs );
	
	if( ( floatabs( vMins[ g_iDirection ] ) + vMaxs[ g_iDirection ] ) < g_iStepUnits + 1 )
		return;
	
	vMins[ g_iDirection ] += float( g_iStepUnits ) / 2.0;
	vMaxs[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	vOrigin[ g_iDirection ] -= float( g_iStepUnits ) / 2.0;
	
	set_pev( iEntity, pev_origin, vOrigin );
	entity_set_size( iEntity, vMins, vMaxs );
}

// Sprite & Box Stuff
public DrawLine( Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, iColor[ 3 ] ) {
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, g_iEditor );
	write_byte( TE_BEAMPOINTS );
	write_coord( floatround( x1 ) );
	write_coord( floatround( y1 ) );
	write_coord( floatround( z1 ) );
	write_coord( floatround( x2 ) );
	write_coord( floatround( y2 ) );
	write_coord( floatround( z2 ) );
	write_short( g_iSprite );
	write_byte( 1 );	// framestart 
	write_byte( 1 );	// framerate 
	write_byte( 4 );	// life in 0.1's 
	write_byte( 5 );	// width
	write_byte( 1 ); 	// noise 
	write_byte( iColor[ 0 ] );  // r, g, b 
	write_byte( iColor[ 1 ] );  // r, g, b 
	write_byte( iColor[ 2 ] );  // r, g, b 
	write_byte( 200 );  	// brightness 
	write_byte( 0 );  	// speed 
	message_end( );
}

public ShowZoneBox( iEntity ) {
	iEntity -= TASK_SHOWZONES;
	
	if( !g_iEditor || !pev_valid( iEntity ) )
		return;
	
	new Float:vOrigin[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	
	if( !is_in_viewcone( g_iEditor, vOrigin ) && iEntity != g_iZones[ g_iCurrZone ] )
		return;
	
	new Float:vEditor[ 3 ], Float:vHitPoint[ 3 ];
	pev( g_iEditor, pev_origin, vEditor );
	trace_line( -1, vEditor, vOrigin, vHitPoint );
	
	if( iEntity == g_iZones[ g_iCurrZone ] )
		DrawLine( vEditor[ 0 ], vEditor[ 1 ], vEditor[ 2 ] - 16.0, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ], { 255, 0, 0 } );
	
	new Float:flDh = vector_distance( vOrigin, vEditor ) - vector_distance( vEditor, vHitPoint );
	
	if( floatabs( flDh ) > 128.0 && iEntity != g_iZones[ g_iCurrZone ] )
		return;
	
	new Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	pev( iEntity, pev_mins, vMins );
	pev( iEntity, pev_maxs, vMaxs );
	
	vMins[ 0 ] += vOrigin[ 0 ];
	vMins[ 1 ] += vOrigin[ 1 ];
	vMins[ 2 ] += vOrigin[ 2 ];
	vMaxs[ 0 ] += vOrigin[ 0 ];
	vMaxs[ 1 ] += vOrigin[ 1 ];
	vMaxs[ 2 ] += vOrigin[ 2 ];
	
	new iColor[ 3 ];
	iColor[ 0 ] = ( iEntity == g_iZones[ g_iCurrZone ] ) ? g_iColor_Active[ 0 ] : g_iColor_Blue[ 0 ];
	iColor[ 1 ] = ( iEntity == g_iZones[ g_iCurrZone ] ) ? g_iColor_Active[ 1 ] : g_iColor_Blue[ 1 ];
	iColor[ 2 ] = ( iEntity == g_iZones[ g_iCurrZone ] ) ? g_iColor_Active[ 2 ] : g_iColor_Blue[ 2 ];
	
	DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], iColor );
	DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], iColor );
	DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], iColor );
	
	DrawLine( vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], iColor );
	DrawLine( vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], iColor );
	DrawLine( vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], iColor );
	
	DrawLine( vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], iColor );
	DrawLine( vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], iColor );
	DrawLine( vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], iColor );
	
	DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], iColor );
	DrawLine( vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], iColor );
	DrawLine( vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], iColor );
	
	if( iEntity != g_iZones[ g_iCurrZone ] )
		return;
	
	switch( g_iDirection ) {
		case 0: { // X
			DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], g_iColor_Green );
			DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], g_iColor_Green );
			
			DrawLine( vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], g_iColor_Red );
			DrawLine( vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], g_iColor_Red );
		}
		case 1: { // Y
			DrawLine( vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], g_iColor_Green );
			DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], g_iColor_Green );
			
			DrawLine( vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], g_iColor_Red );
			DrawLine( vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], g_iColor_Red );
		}
		case 2: { // Z
			DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMins[ 1 ], vMaxs[ 2 ], g_iColor_Green );
			DrawLine( vMaxs[ 0 ], vMins[ 1 ], vMaxs[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMaxs[ 2 ], g_iColor_Green );
			
			DrawLine( vMaxs[ 0 ], vMaxs[ 1 ], vMins[ 2 ], vMins[ 0 ], vMins[ 1 ], vMins[ 2 ], g_iColor_Red );
			DrawLine( vMaxs[ 0 ], vMins[ 1 ], vMins[ 2 ], vMins[ 0 ], vMaxs[ 1 ], vMins[ 2 ], g_iColor_Red );
		}
	}
}

// Auto join
public MsgShowMenu( iMsgid, iDest, id ) {
	new szMenuCode[ 22 ];
	get_msg_arg_string( 4, szMenuCode, 21 );
	
	if( equal( szMenuCode, "#Team_Select" ) || equal( szMenuCode, "#Team_Select_Spect" ) ) {
		if( !task_exists( id ) ) {
			set_autojoin_task( id, iMsgid );
			return PLUGIN_HANDLED;
		}
	}
	else if( equal( szMenuCode, "#IG_Team_Select" ) || equal( szMenuCode, "#IG_Team_Select_Spect" ) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public MsgVGUIMenu( iMsgid, iDest, id ) {
	if( get_msg_arg_int( 1 ) != 2 )
		return PLUGIN_CONTINUE;
	
	if( !task_exists( id ) ) {
		set_autojoin_task( id, iMsgid );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public handle_join( szParam[ ], id ) {
	new iMsgBlock = get_msg_block( szParam[ 0 ] );
	set_msg_block( szParam[ 0 ], BLOCK_SET );
	
	engclient_cmd( id, "jointeam", "1" );
	engclient_cmd( id, "joinclass", "2" );
	
	set_msg_block( szParam[ 0 ], iMsgBlock );
}

public set_autojoin_task( id, iMsgid ) {
	new szParam[ 2 ];
	szParam[ 0 ] = iMsgid;
	set_task( 0.1, "handle_join", id, szParam, 2 );
}

// Save & Load stuff
public SaveZones( id ) {
	new szMapname[ 32 ], szFile[ 128 ];
	
	get_mapname( szMapname, 32 );
	get_localinfo( "amxx_datadir", szFile, 127 );
	
	format( szFile, 127, "%s/cs_rally", szFile );
	
	if( !dir_exists( szFile ) )
		mkdir( szFile );
	
	format( szFile, 127, "%s/%s.txt", szFile, szMapname );
	
	delete_file( szFile );
	
	FindAllZones( );
	
	// Header
	write_file( szFile, "; CS Rally - Checkpoint zones" );
	write_file( szFile, "; <position (x/y/z)> <mins (x/y/z)> <maxs (x/y/z)>" );
	write_file( szFile, ";" );
	write_file( szFile, "" );
	
	new iZone, Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ], szOutput[ 512 ];
	for( new i = 0; i < MAX_ZONES; i++ ) {
		iZone = g_iZones[ i ];
		
		if( !pev_valid( iZone ) )
			continue;
		
		pev( iZone, pev_origin, vOrigin );
		pev( iZone, pev_mins, vMins );
		pev( iZone, pev_maxs, vMaxs );
		
		format( szOutput, 511, "%.1f %.1f %.1f %i %i %i %i %i %i", vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ], 
		floatround( vMins[ 0 ] ), floatround( vMins[ 1 ] ), floatround( vMins[ 2 ] ),
		floatround( vMaxs[ 0 ] ), floatround( vMaxs[ 1 ] ), floatround( vMaxs[ 2 ] ) );
		
		write_file( szFile, szOutput );
	}
	
	GreenPrint( id, "Zones has been succesfully saved." );
}

public LoadZones( ) {
	new szMapname[ 32 ], szFile[ 128 ];
	
	get_mapname( szMapname, 32 );
	get_localinfo( "amxx_datadir", szFile, 127 );
	
	format( szFile, 127, "%s/cs_rally", szFile );
	
	if( !dir_exists( szFile ) ) {
		mkdir( szFile );
		
		return;
	}
	
	format( szFile, 127, "%s/%s.txt", szFile, szMapname );
	
	if( !file_exists( szFile ) )
		return;
	
	new iEntity, iOwner, szData[ 512 ], iFile = fopen( szFile, "rt" );
	new Float:vOrigin[ 3 ], Float:vMins[ 3 ], Float:vMaxs[ 3 ];
	new szParse[ 9 ][ 16 ]; // 0-2 = origin | 3-5 = mins | 6-8 = maxs
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, 511 );
		
		if( !szData[ 0 ] || szData[ 0 ] == ';' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		parse( szData, szParse[ 0 ], 15, szParse[ 1 ], 15, szParse[ 2 ], 15,
		szParse[ 3 ], 15, szParse[ 4 ], 15, szParse[ 5 ], 15,
		szParse[ 6 ], 15, szParse[ 7 ], 15, szParse[ 8 ], 15 );
		
		vOrigin[ 0 ] = str_to_float( szParse[ 0 ] );
		vOrigin[ 1 ] = str_to_float( szParse[ 1 ] );
		vOrigin[ 2 ] = str_to_float( szParse[ 2 ] );
		
		if( vOrigin[ 0 ] == 0.0 )
			continue;
		
		vMins[ 0 ] = str_to_float( szParse[ 3 ] );
		vMins[ 1 ] = str_to_float( szParse[ 4 ] );
		vMins[ 2 ] = str_to_float( szParse[ 5 ] );
		
		vMaxs[ 0 ] = str_to_float( szParse[ 6 ] );
		vMaxs[ 1 ] = str_to_float( szParse[ 7 ] );
		vMaxs[ 2 ] = str_to_float( szParse[ 8 ] );
		
		iOwner = CreateZone( vOrigin, vMins, vMaxs );
		
		iEntity = create_entity( "env_sprite" );
		
		if( pev_valid( iEntity ) ) {
			set_pev( iEntity, pev_classname, SPR_CLASSNAME );
			set_pev( iEntity, pev_model, SPRITE );
			set_pev( iEntity, pev_movetype, MOVETYPE_FLY );
			set_pev( iEntity, pev_scale, 0.2 );
			set_pev( iEntity, pev_rendermode, kRenderTransAdd );
			set_pev( iEntity, pev_renderfx, kRenderFxHologram );
			set_pev( iEntity, pev_renderamt, 255.0 );
			
			set_pev( iOwner, pev_euser4, iEntity );
			
			vOrigin[ 2 ] += vMaxs[ 2 ];
			vOrigin[ 2 ] += 10.0;
			
			set_pev( iEntity, pev_origin, vOrigin );
			
			DispatchSpawn( iEntity );
		}
	}
	
	fclose( iFile );
	
	FindAllZones( );
	HideAllZones( );
}

// Main mod
public Init_Checks( id )
	if( g_bConnected[ id ] )
		query_client_cvar( id, "cl_minmodels", "Cvar_Result" );

public Msg_SendAudio( iMsgId, iMsgDest, iMsgEnt ) {
	if( get_gametime() > g_flRoundStartTime ) {
		unregister_message(g_iMsgSendAudio, g_iSendAudioMessage);
		g_iSendAudioMessage = 0;
		return PLUGIN_CONTINUE;
	}
	
	if( iMsgEnt ) {
		new szAudioString[17];
		get_msg_arg_string(2, szAudioString, charsmax(szAudioString));
		
		if( TrieKeyExists(g_tRoundStartSounds, szAudioString) )
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public EventResetHUD( id ) {
	set_pdata_int( id, m_iClientHideHUD, 0 );
	set_pdata_int( id, m_iHideHUD, HUD_HIDE );
}

public EventHideWeapon( id ) {
	new iFlags = read_data( 1 );
	
	set_pdata_int( id, m_iClientHideHUD, 0 );
	set_pdata_int( id, m_iHideHUD, iFlags | HUD_HIDE );
	
	if( iFlags & HUD_HIDE && g_bPlayerAlive[ id ] )
		set_pdata_cbase( id, m_pClientActiveItem, FM_NULLENT );
}

public Countdown( ) {
	client_cmd( 0, "mp3 play ^"%s^"", g_szSound_CountDown );
	
	set_task( 0.2, "Ready",    TASK_RDYHUD );
	set_task( 1.4, "Steady",   TASK_RDYHUD );
	set_task( 2.6, "GoGo",     TASK_RDYHUD );
	set_task( 3.1, "FixSpeed", TASK_RDYHUD );
}

public Ready( ) {
	set_hudmessage( 255, 0, 0, -1.0, 0.4, 0, 0.0, 1.2, 0.1, 0.0, 3 );
	show_hudmessage( 0, "READY" );
	
	MakeFade( 0, { 255, 0, 0 } );
	
	for( new id = 1; id <= g_iMaxPlayers; id++ ) {
		if( g_bPlayerAlive[ id ] ) {
			g_bStarted[ id ] = true;
			
			emit_sound( id, CHAN_BODY, g_szSound_EngStart, 0.8, ATTN_NORM, 0, PITCH_NORM );
			g_flLastThink[ id ] = get_gametime( ) + 1.2;
		}
	}
}

public Steady( ) {
	set_hudmessage( 255, 100, 0, -1.0, 0.4, 0, 0.0, 1.2, 0.0, 0.0, 3 );
	show_hudmessage( 0, "SET" );
	
	MakeFade( 0, { 255, 100, 0 } );
}

public GoGo( ) {
	set_hudmessage( 0, 255, 0, -1.0, 0.4, 0, 0.0, 1.5, 0.1, 0.4, 3 );
	show_hudmessage( 0, "GO GO GO" );
	
	MakeFade( 0, { 0, 255, 0 } );
}

public FixSpeed( ) {
	g_bRoundStart = false;
	g_bRaceRun = true;
	
	for( new id = 1; id <= g_iMaxPlayers; id++ ) {
		if( g_bPlayerAlive[ id ] ) {
			EventCurWeapon( id );
			
			if( !g_bStarted[ id ] ) { // Late join
				g_bStarted[ id ] = true;
				
				g_flLastThink[ id ] = get_gametime( ) + 0.1;
			}
		}
	}
}

public MakeFade( id, iColor[ 3 ] ) {
	if( id > 0 )
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, id );
	else
		message_begin( MSG_BROADCAST, g_iMsgScreenFade );
	write_short( ( 1 << 12 ) );
	write_short( ( 1 << 12 ) );
	write_short( 0x0000 ); // FFADE_IN
	write_byte( iColor[ 0 ] );
	write_byte( iColor[ 1 ] );
	write_byte( iColor[ 2 ] );
	write_byte( 50 );
	message_end( );
}

public EventCurWeapon( id )
	if( !g_bRoundStart && g_bStarted[ id ] )
		set_user_maxspeed( id, 500.0 );

public MsgClCorpse( )
	set_msg_arg_string( 1, g_szModel[ get_msg_arg_int( 12 ) ] );

public MsgStatusIcon( msgid, msgdest, id ) {
	static szMsg[ 8 ];
	get_msg_arg_string( 2, szMsg, 7 );
	
	if( equal( szMsg, "buyzone" ) && get_msg_arg_int( 1 ) ) {
		set_pdata_int( id, 235, get_pdata_int( id, 235 ) & ~( 1 << 0 ) );
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public FwdSetClientKeyValue( id, const szInfoBuffer[], const szKey[] ) {
	if( equal( szKey, "model" ) )
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public FwdImpulse_201( id, uc_handle, seed )
	return PLUGIN_HANDLED_MAIN;

public FwdEmitSound( id, iChannel, const szSample[], Float:fVol, Float:fAttn, iFlags, iPitch ) {
//	client_print( 0, print_chat, "%s", szSample );
	
	if( TrieKeyExists( g_tBlockSounds, szSample ) )
		return FMRES_SUPERCEDE;
	
	if( !IsPlayer( id ) )
		return FMRES_IGNORED;
	
	if( !g_bStarted[ id ] )
		return FMRES_IGNORED;
	
	static const szUseSound[] = "common/wpn_denyselect.wav";
	
	if( equal( szSample, szUseSound ) ) {
		static Float:flGametime; flGametime = get_gametime( );
		
		if( g_fLastHorn[ id ] < flGametime ) {
			g_fLastHorn[ id ] = flGametime + 2.0;
			
			emit_sound( id, iChannel, g_szSound_Horn, VOL_NORM, fAttn, iFlags, PITCH_NORM );
		}
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdPlayerPreThink( id ) {
	if( g_bPlayerAlive[ id ] ) {
		set_pev( id, pev_solid, SOLID_SLIDEBOX );
		
		static Float:vAngles[ 3 ];
		pev( id, pev_v_angle, vAngles );
		
		if( vAngles[ 0 ] > 40.0 ) {
			vAngles[ 0 ] = 40.0;
			
			set_pev( id, pev_angles, vAngles );
			set_pev( id, pev_fixangle, 1 );
		}
		else if( vAngles[ 0 ] < -30.0 ) {
			vAngles[ 0 ] = -30.0;
			
			set_pev( id, pev_angles, vAngles );
			set_pev( id, pev_fixangle, 1 );
		}
		
		if( g_bStarted[ id ] ) {
			static Float:flGametime; flGametime = get_gametime( );
			
			if( g_flLastThink[ id ] < flGametime ) {
				g_flLastThink[ id ] = flGametime + 1.0;
				
				emit_sound( id, CHAN_BODY, g_szSound_Engine, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			}
		}
	}
	
	return FMRES_IGNORED;
}

public FwdPlayerPostThink( id )
	if( g_bPlayerAlive[ id ] )
		set_pev( id, pev_solid, SOLID_NOT );

public FwdUpdateClientData( id, sendweapons, cd_handle ) {
	new Float:flGametime; flGametime = get_gametime( );
	
	if( g_flSpeedLastThink[ id ] < flGametime ) {
		if( !g_bPlayerAlive[ id ] )
			return FMRES_IGNORED;
		
		static Float:vVelocity[ 3 ], Float:flSpeed, Float:flGear;
		pev( id, pev_velocity, vVelocity );
		flSpeed = vector_length( vVelocity );
		
		if( flSpeed > 999.0 )
			set_pev( id, pev_armorvalue, 999.0 );
		else
			set_pev( id, pev_armorvalue, float_speed( flSpeed ) );
		
		flGear = flSpeed / 100.0;
		
		if( flGear < 1.0 )
			flGear = 1.0;
		
		set_pev( id, pev_health, float_speed( flGear ) );
		
		g_flSpeedLastThink[ id ] = flGametime + 0.02;
	}
	
	return FMRES_IGNORED;
}

public FwdHamPlayerKilled( id ) {
	g_bPlayerAlive[ id ] = bool:is_user_alive( id );
	
	set_view( id, CAMERA_NONE );
}

public FwdHamPlayerSpawn( id ) {
	g_bPlayerAlive[ id ] = bool:is_user_alive( id );
	
	if( g_bPlayerAlive[ id ] ) {
		if( g_bRaceRun ) {
			user_silentkill( id );
			
			GreenPrint( id, "You can't join while race is already running." );
			
			return HAM_IGNORED;
		}
		
		set_pdata_int( id, m_iRadiosLeft, 0 );
		
		set_pev( id, pev_takedamage, DAMAGE_NO );
		set_pev( id, pev_friction, 0.1 );
		
		formatex( g_szModel[ id ], 11, g_szCarModels[ random( sizeof( g_szCarModels ) ) ] );
		
		set_user_info( id, "model", g_szModel[ id ] );
		
		set_view( id, CAMERA_NONE );
	}
	
	return HAM_IGNORED;
}

public FwdHamKnifeDeploy( iKnife ) {
	new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
	
	entity_set_string( id, EV_SZ_viewmodel, g_szHandsView );
	entity_set_string( id, EV_SZ_weaponmodel, "" );
	
	// Block attack
	set_pdata_float( iKnife, m_flNextPrimaryAttack, 9999.0, 4 );
	set_pdata_float( iKnife, m_flNextSecondaryAttack, 9999.0, 4 );
}

public FwdHamPlayerJump( id ) {
	static iOldbuttons; iOldbuttons = entity_get_int( id, EV_INT_oldbuttons );
	
	if( !( iOldbuttons & IN_JUMP ) ) {
		entity_set_int( id, EV_INT_oldbuttons, iOldbuttons | IN_JUMP );
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public FwdHamPlayerDuck( id ) { // This is total wrong :D
	static iOldbuttons; iOldbuttons = entity_get_int( id, EV_INT_oldbuttons );
	
	if( !( iOldbuttons & IN_DUCK ) ) {
		entity_set_int( id, EV_INT_oldbuttons, iOldbuttons | IN_DUCK );
		return HAM_HANDLED;
	}
	
	return HAM_IGNORED;
}

public Cvar_Result( id, const szCvar[], const szValue[] ) { 
	if( g_bConnected[ id ] ) {
		if( szValue[0] != '0' || szValue[1] != 0 )
			client_cmd( id, ";cl_minmodels 0" );
		
		query_client_cvar( id, "cl_minmodels", "Cvar_Result" );
	} 
}

Float:float_speed( Float:f ) {
	new a = _:f;
	new e = 150 - ((a>>23) & 0xFF);
	a >>= e;
	a <<= e;
	return Float:a;
}

// Time and ranks stuff
public EventNewRound() {
	remove_task( TASK_HUDUPD );
	remove_task( TASK_RDYHUD );
	
	g_bRaceRun = false;
	g_bRoundStart = true;
	
	arrayset( g_bStarted, false, 32 );
	
	client_cmd( 0, "mp3 stop" );
	
	set_task( 2.0, "Countdown", TASK_RDYHUD );
}

public EventRoundStart( ) {
	g_flRoundStartTime = get_gametime( );
	
	if( !g_iSendAudioMessage )
		g_iSendAudioMessage = register_message( g_iMsgSendAudio, "Msg_SendAudio" );
	
	g_iFinished = 0;
	
	new i;
	for( i = 0; i < g_iMaxPlayers; i++ ) {
		g_fRaceTime[ i ] = 0.0;
		g_fCheckPointTime[ i ] = 0.0;
		g_fStartTime[ i ] = 0.0;
		g_bFinished[ i ] = false;
		g_iPlayerLaps[ i ] = 0;
		g_iLastCheckPoint[ i ] = 0;
		g_fBestPersLap[ i ] = 0.0;
		g_fLastLap[ i ] = 0.0;
		g_fLastLapTime[ i ] = 0.0;
	}
	for( i = 0; i < 3; i++ ) {
		g_szWinners[ i ][ 0 ] = '^0';
		g_fWinners[ i ] = 0.0;
	}
	
	g_szBestLap[ 0 ] = '^0';
	g_fBestLap = 0.0;
	
	set_task( RANK_DELAY, "task_ShowHudRank", TASK_HUDUPD );
}

public StatusIcon( id, iStatus, szName[ ] ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgStatusIcon, _, id );
	write_byte( iStatus );
	write_string( szName );
	write_byte( 0 );
	write_byte( 255 );
	write_byte( 0 );
	message_end( );
}

public TrgWorldTouch( iEntity, id ) {
	if( !g_bPlayerAlive[ id ] )
		return PLUGIN_CONTINUE;
	
	static Float:flGametime; flGametime = get_gametime( );
	
	if( g_fLastHit[ id ] < flGametime ) {
		static Float:vVelocity[ 3 ], Float:flSpeed;
		pev( id, pev_velocity, vVelocity );
		flSpeed = vector_length( vVelocity );
		
		if( flSpeed > 250.0 )
			emit_sound( id, CHAN_WEAPON, g_szSound_HitNorm, 0.8, ATTN_NORM, 0, PITCH_NORM );
		else if( flSpeed > 350.0 )
			emit_sound( id, CHAN_WEAPON, g_szSound_HitHard, 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		g_fLastHit[ id ] = flGametime + 1.0;
	}
	
	return PLUGIN_CONTINUE;
}

public CpsTouch( cp, id ) {
	if( g_iPlayerLaps[id] >= RACE_LAPS )
		return PLUGIN_CONTINUE;
	
	if( g_iLastCheckPoint[id] == cp )
		return PLUGIN_CONTINUE;
	
	if( cp != g_iZones[ 0 ] ) {
		new i, iLastCp, iZone;
		for( i = 0; i < g_iZonesCount; i++ ) {
			if( g_iZones[ i ] == cp )
				iZone = i;
			
			if( g_iLastCheckPoint[ id ] == g_iZones[ i ] )
				iLastCp = i;
		}
		
		if( g_iZones[ iLastCp + 1 ] != cp )
			return PLUGIN_CONTINUE;
		
		if( !g_fStartTime[ id ] )
			return PLUGIN_CONTINUE;
		
		set_hudmessage( 128, 128, 128, -1.0, 0.3, 2, 0.0, 1.5, 0.1, 0.4, 3 );
		show_hudmessage( id, "CHECKPOINT %i / %i", iZone, g_iZonesCount - 1 );
		client_cmd( id, "spk ^"%s^"", g_szSound_CP );
		
		MakeFade( id, { 0, 127, 255 } );
	} else {
		if( g_iLastCheckPoint[ id ] > 0 && g_iLastCheckPoint[ id ] != g_iZones[ g_iZonesCount - 1 ] )
			return PLUGIN_CONTINUE;
		
		if( !g_fStartTime[ id ] ) {
			g_fStartTime[ id ] = get_gametime( );
			
			set_hudmessage( 0, 255, 0, -1.0, 0.4, 0, 0.0, 1.5, 0.1, 0.4, 3 );
			show_hudmessage( id, "GO GO GO" );
			client_cmd( id, "spk ^"events/tutor_msg^"" );
			
			StatusIcon( id, 1, "number_0" );
		}
		
		if( g_fCheckPointTime[id] > 0.0 ) {
			++g_iPlayerLaps[id];
			
			if( g_iPlayerLaps[id] == RACE_LAPS ) {
				set_hudmessage( 100, 100, 100, -1.0, 0.4, 2, 0.0, 1.5, 0.1, 0.1, 2 );
				show_hudmessage( id, "WELL DONE !" );
				
				if( g_iPlayerLaps[ id ] > 0 ) {
					new szLap[ 9 ];
					formatex( szLap, 8, "number_%i", g_iPlayerLaps[ id ] - 1 );
					StatusIcon( id, 0, szLap );
				}
				
				StatusIcon( id, 1, "dollar" );
			} else {
				set_hudmessage( 100, 100, 100, -1.0, 0.4, 2, 0.0, 2.5, 0.1, 0.4, 2 );
				show_hudmessage( id, "LAP %i / %i", g_iPlayerLaps[ id ], RACE_LAPS );
				
				new szLap[ 9 ];
				if( g_iPlayerLaps[ id ] > 0 ) {
					formatex( szLap, 8, "number_%i", g_iPlayerLaps[ id ] - 1 );
					StatusIcon( id, 0, szLap );
				}
				
				formatex( szLap, 8, "number_%i", g_iPlayerLaps[ id ] );
				StatusIcon( id, 1, szLap );
			}
		}
		
		if( g_fLastLapTime[ id ] )
			g_fLastLap[ id ] = get_gametime( ) - g_fLastLapTime[ id ];
		
		g_fLastLapTime[ id ] = get_gametime( );
		
		if( g_fLastLapTime[ id ] > g_fStartTime[ id ] ) {
			if( g_fLastLap[ id ] < g_fBestLap || !g_fBestLap ) {
				g_fBestLap = g_fLastLap[ id ];
				get_user_name( id, g_szBestLap, 31 );
			}
			
			if( g_fLastLap[ id ] < g_fBestPersLap[ id ] || !g_fBestPersLap[ id ] )
				g_fBestPersLap[ id ] = g_fLastLap[ id ];
		}
	}
	
	if( g_iPlayerLaps[id] >= RACE_LAPS ) {
		g_iFinished++;
		
		g_bStarted[ id ] = false;
		g_bFinished[ id ] = true;
		g_fCheckPointTime[ id ] = 0.0;
		
		g_fRaceTime[ id ] = get_gametime( ) - g_fStartTime[ id ];
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		if( !g_fWinners[ 0 ] ) {
			g_fWinners[ 0 ] = g_fRaceTime[ id ];
			copy( g_szWinners[ 0 ], 31, szName );
		}
		else if( !g_fWinners[ 1 ] ) {
			g_fWinners[ 1 ] = g_fRaceTime[ id ];
			copy( g_szWinners[ 1 ], 31, szName );
		}
		else if( !g_fWinners[ 2 ] ) {
			g_fWinners[ 2 ] = g_fRaceTime[ id ];
			copy( g_szWinners[ 2 ], 31, szName );
		}
		
		new iTime = floatround( g_fRaceTime[ id ] );
		
		client_cmd( id, "spk ^"events/task_complete^"" );
		GreenPrint( 0, "%s finished the course in^4 %02d:%02d^1 !", szName, iTime / 60, iTime % 60 );
		
		set_user_maxspeed( id, 0.001 );
		set_view( id, CAMERA_3RDPERSON );
		
		if( !task_exists( TASK_RACEEND ) ) {
			set_task( 20.0, "Task_RaceEnd", TASK_RACEEND );
			
			GreenPrint( 0, "Race will end in^4 20^1 seconds!" );
		}
	}
	
	g_fCheckPointTime[ id ] = get_gametime() - g_fStartTime[id];
	g_iLastCheckPoint[ id ] = cp;
	
	return PLUGIN_HANDLED;
}

public Task_RaceEnd( ) {
	g_iFinished = g_iMaxPlayers;
}

public task_ShowHudRank( ) {
	new iTop15[ 33 ][ 2 ], iTop15Count, iPlayers, plr;
	
	for( plr = 1; plr <= g_iMaxPlayers; plr++ ) {
		if( !g_bConnected[ plr ] || !g_fStartTime[ plr ] )
			continue;
		
		iTop15[ iTop15Count ][ 0 ] = plr;
		iTop15[ iTop15Count ][ 1 ] = floatround( g_fStartTime[ plr ] );
		
		iTop15Count++;
		
		if( g_bPlayerAlive[ plr ] && ( g_bStarted[ plr ] || g_bFinished[ plr ] ) )
			iPlayers++;
	}
	
	if( g_iFinished == 0 ) // Uber fix on round start
		iPlayers++;
	
	if( g_iFinished >= iPlayers ) {
		remove_task( TASK_RACEEND );
		
		// FUCKING ROUND END HERE AFTER 10 SECONDS LOL
		ForceRoundEnd( );
		
		client_cmd( 0, "spk ^"ambience/goal_1^"" );
		
		new iTime, szTemp[ 128 ], szMsg[ 512 ];
		formatex( szMsg, 511, "Congratulations to:" );
		
		for( new i = 0; i < 3; i++ ) {
			if( g_fWinners[ i ] ) {
				iTime = floatround( g_fWinners[ i ] );
				
				formatex( szTemp, 127, "^n%i. %s - %02d:%02d", i + 1, g_szWinners[ i ], iTime / 60, iTime % 60 );
			} else
				formatex( szTemp, 127, "^n%i. NONE", i + 1 );
			
			format( szMsg, 511, "%s%s", szMsg, szTemp );
		}
		
		if( g_fBestLap ) {
			iTime = floatround( g_fBestLap );
			
			format( szMsg, 511, "%s^n^nBest lap time:^n%s - %02d:%02d", szMsg, g_szBestLap, iTime / 60, iTime % 60 );
		}
		
		set_hudmessage( 0, 90, 0, -1.0, 0.3, 2, 6.0, 6.0, 0.1, 1.0, 4 );
		show_hudmessage( 0, szMsg );
		
		remove_task( TASK_HUDUPD );
		return PLUGIN_HANDLED;
	}
	
	if( iTop15Count > 0 ) {
		SortCustom2D( iTop15, iTop15Count, "Sort2DDecending" );
		
		new szHudMessage[256], szName[32];
		new iLen, iTime;
		new Float:flGametime = get_gametime( );
		
		iLen = formatex(szHudMessage, charsmax(szHudMessage), "CS Rally Rank:^n^n");
		
		for( new i = 0; i < iTop15Count; i++ ) {
			if( g_bFinished[ iTop15[ i ][ 0 ] ] )
				iTime = floatround( g_fRaceTime[ iTop15[ i ][ 0 ] ] );
			else
				iTime = floatround(flGametime - g_fStartTime[iTop15[i][0]]);
			
			get_user_name( iTop15[ i ][ 0 ], szName, charsmax( szName ) );
			iLen += format(szHudMessage[iLen], charsmax(szHudMessage) - iLen, "%i. %s - %02d:%02d^n", i + 1, szName, iTime / 60, iTime % 60);
		}
		
		set_hudmessage( 128, 128, 128, 0.05, 0.15, 0, 0.0, RANK_DELAY + 0.1, 0.0, 0.0, 4 );
		show_hudmessage( 0, szHudMessage );
		
		new iBestTime, iCurrTime;
		for( plr = 1; plr <= g_iMaxPlayers; plr++ ) {
			if( !g_bPlayerAlive[ plr ] )
				continue;
			
			if( !g_bStarted[ plr ] && !g_bFinished[ plr ] )
				continue;
			
			iTime = floatround( g_fLastLap[ plr ] );
			iBestTime = floatround( g_fBestPersLap[ plr ] );
			iCurrTime = floatround( flGametime - g_fLastLapTime[ plr ] );
			
			set_hudmessage( 0, 127, 255, 0.75, 0.05, 0, 0.0, RANK_DELAY + 0.1, 0.0, 0.0, 1 );
			
			if( g_fLastLapTime[ plr ] > g_fStartTime[ plr ] ) {
				if( !g_bFinished[ plr ] )
					show_hudmessage( plr, "Current time: %02d:%02d^nLast lap time: %02d:%02d^nBest lap time: %02d:%02d", iCurrTime / 60, iCurrTime % 60, iTime / 60, iTime % 60, iBestTime / 60, iBestTime % 60 );
				else
					show_hudmessage( plr, "Last lap time: %02d:%02d^nBest lap time: %02d:%02d", iTime / 60, iTime % 60, iBestTime / 60, iBestTime % 60 );
			} else
				show_hudmessage( plr, "Current time: %02d:%02d", iCurrTime / 60, iCurrTime % 60 );
		}
	}
	
	set_task( RANK_DELAY, "task_ShowHudRank", TASK_HUDUPD );
	return PLUGIN_CONTINUE;
}

public Sort2DDecending( const elem1[], const elem2[] ) {
	if ( elem1[ 1 ] < elem2[ 1 ] )
		return -1;
/*	else if ( elem1[ 1 ] > elem2[ 1 ] )
		return 1; */
	
	return 0;
}

stock GreenPrint( id, const message[], any:... ) {
	new szMessage[ 192 ];
	formatex( szMessage, 191, "^4[CS Rally]^1 " );
	vformat( szMessage[ 13 ], 185, message, 3 );
	
	static iSayText;
	if( !iSayText )
		iSayText = get_user_msgid( "SayText" );
	
	if( id > 0 ) {
		message_begin( MSG_ONE_UNRELIABLE, iSayText, _, id );
		write_byte( id );
		write_string( szMessage );
		message_end( );
	} else {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ch" );
		
		for( new i; i < iNum; i++ ) {
			message_begin( MSG_ONE_UNRELIABLE, iSayText, _, iPlayers[ i ] );
			write_byte( iPlayers[ i ] );
			write_string( szMessage );
			message_end( );
		}
	}
	
	return 1;
}

ForceRoundEnd( ) { // Arkshine
	new handleGameRules = OrpheuMemoryGet( "g_pGameRules" );
	
	set_mp_pdata( "m_iRoundWinStatus"  , 1 );
	set_mp_pdata( "m_fTeamCount"       , get_gametime( ) + 15.0 );
	set_mp_pdata( "m_bRoundTerminating", true );
}
