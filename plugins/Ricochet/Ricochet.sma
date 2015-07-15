#include < amxmodx >
#include < fakemeta >
#include < engine >
#include < cstrike >
#include < hamsandwich >
#include < xs >

#include < orpheu_stocks >
#include < orpheu_memory >

new const disc[ ] = "disc";

const m_iRadiosLeft           = 192;
const m_iTeam                 = 114;
const m_pPlayer               = 41;
const m_LastHitGroup          = 75;
const m_flNextPrimaryAttack   = 46;
const m_flNextSecondaryAttack = 47;
const m_iHideHUD              = 361;
const m_iClientHideHUD        = 362;

new const HIDE_HUD = 1 << 0 | 1 << 3 | 1 << 4 | 1 << 5;

const MAX_POWERUPS               = 4;
const DISC_VELOCITY              = 1000;  // Velocity multiplier for discs when thrown
const DISC_POWERUP_RESPAWN_TIME  = 10;    // Time it takes after a powerup is picked up before the next one appears
const Float:DISC_PUSH_MULTIPLIER = 1000.0; // Velocity multiplier used to push a player when hit by a disc
const Float:FREEZE_TIME          = 7.0;    // How long player is frozen after being hitted by frozen disc

/*
	TODO:
		- Count points? As frags or something
		- Partically fixed: Block disc with other disc
		- Add "observer crosshair"
		- Fix teleports :/
		- Partically fixed: Alot of debugs happens with discs deleting on round end
		- Block +use sound, maybe
		- Loop trough trigger_teleport in plugin_init and set the target ent to iuser* || just save origin
		- Add avelocity on discs
		- Add check for vel[ 2 ] on discs?
		- Bug: die on round end, and black fade disappears
	
	BETA 0.2:
		- Removed debug messages
		- Removed hud elements
		- Blocked Radio
		- Blocked Spray
		- Blocked buyzone (buying)
		- Fixed SV_BadSound..
		- Added trigger_camera (info_player_spectator)
		- Fixed a bug allowing you to throw 2 decap discs if you had fast shot powerup
		- Fixed a bug making you have only 1 disc after throwing fast shot's
		- Added gib head on decapitate
		- Probably fixed ice bug...
	
	BETA 0.3:
		- Blocked hint messages
		- Fixed glow bug after being decap'd while frozen
		- Added fade to blue when player gets frozen
		- Added fade to black on round end
		- New round start delay is longer.
		- Fixed case when sound of thrown decap disc could stay forever
		- Powerups and players are not respawned on round end
		- Head is being spawned by engine, removed code to spawn one
	
	BETA 0.4:
		- info_target origin is now properly calculated for spectate camera
		- Fixed triple powerup, bugged by mistake in beta 0.3
		- Fixed blue fade staying on decapitate while frozen
	
	BETA 0.5:
		- Maybe fixed team joining bug
	
	https://forums.alliedmods.net/showpost.php?p=1522817&postcount=10
*/

#define set_mp_pdata(%1,%2) ( OrpheuMemorySetAtAddress( g_pGameRules, %1, 1, %2 ) )
#define get_mp_pdata(%1)    ( OrpheuMemoryGetAtAddress( g_pGameRules, %1 ) )

new const GAME_DESC[ ] = "Ricochet BETA 0.5";

enum _:POWERUPS (<<=1) {
	POW_TRIPLE = 1,
	POW_FAST,
	POW_HARD,
	POW_FREEZE
};

new const g_iDiscColors[ 2 ][ 3 ] = {
	{ 255, 50, 0 },  // Normal disc
	{ 0, 127, 255 }  // Disk with freeze powerup
};

new const HIT_MESSAGES[ ][ ] = {
	"Decapitation! 1 Point!",
	"Direct Hit Kill! 1 Point!",
	"Single Rebound Kill! 2 Points!",
	"Double Rebound Kill! 3 Points!",
	"Triple Rebound Kill! 4 Points!",
	"Multiple Kill Disc! 5 Points!"
};

new const POWERUP_NAMES[ MAX_POWERUPS ][ ] = {
	"Triple Shot",
	"Fast Shot",
	"Power Shot",
	"Freeze Shot"
};

new const SCREAM_SOUNDS[ ][ ] = {
	"ricochet/scream1.wav",
	"ricochet/scream2.wav",
	"ricochet/scream3.wav"
};

new const THWACK_SOUNDS[ ][ ] = {
	"weapons/cbar_hitbod1.wav",
	"weapons/cbar_hitbod2.wav",
	"weapons/cbar_hitbod3.wav"
};

new const BOUNCE_SOUNDS[ ][ ] = {
	"ricochet/hit1.wav",
	"ricochet/hit2.wav"
};

new const POWERUP_MODELS[ MAX_POWERUPS ][ ] = {
	"models/ricochet/pow_triple.mdl",
	"models/ricochet/pow_fast.mdl",
	"models/ricochet/pow_hard.mdl",
	"models/ricochet/pow_freeze.mdl"
};

enum _:FORWARDS {
	Rc_RoundEnd,
	Rc_RoundStart,
	Rc_GainPowerup,
	Rc_PlayerDeath,
	Rc_DiscHit
};

new g_iForwards[ FORWARDS ], HamHook:g_iFwdKilledPost, g_iAttacker;
new g_iMaxPlayers, g_iTrail, g_iDiscReturn, g_pGravity;
new g_iFastShotDiscs[ 33 ], g_iPowerupDiscs[ 33 ], g_iPowers[ 33 ], g_iAmmo[ 33 ];
new g_iLastPlayerToHitMe[ 33 ], g_iLastDiscBounces[ 33 ], Float:g_flLastDiscHit[ 33 ];
new g_pGameRules, bool:g_bFirstSpawn[ 33 ], Float:g_flStartScaleTime[ 33 ];
new g_pFragLimit, g_pMaxRounds, bool:g_bFinished, Float:g_vFallOrigin[ 3 ];
new g_iMsgScreenFade, g_iMsgSayText, g_iMsgAmmoPickup;

new OrpheuStruct:g_iPpMove;

public plugin_init( ) {
	register_plugin( "Ricochet", "1.0", "xPaw" );
	
	register_cvar( "ricochet", "1.0", FCVAR_SERVER | FCVAR_SPONLY );
	
	// when anybody`s scored reaches rc_fraglimit the round ends.
	g_pFragLimit = register_cvar( "rc_fraglimit", "0" );
	
	// when the amount of rounds is reached, the map is changed.
	g_pMaxRounds = register_cvar( "rc_maxrounds", "0" );
	
	register_clcmd( "radio1", "CmdRadio" );
	register_clcmd( "radio2", "CmdRadio" );
	register_clcmd( "radio3", "CmdRadio" );
	
//	register_touch( disc, disc,                 "FwdDiscTouch_Disc" );
	register_touch( disc, "player",             "FwdDiscTouch_Player" );
	register_touch( disc, "worldspawn",         "FwdDiscTouch_WorldSpawn" );
	register_touch( "trigger_teleport",   disc, "FwdDiscTouch_Teleport" );
	register_touch( "trigger_discreturn", disc, "FwdDiscTouch_DiscReturn" );	
	
	register_touch( "trigger_jump", "player", "FwdTriggerTouch_Jump" );
	register_touch( "item_powerup", "player", "FwdItemPowerupTouch" );
	
	register_think( "item_powerup", "FwdItemPowerupThink" );
	register_think( "head",         "FwdGibHeadThink" );
	register_think( disc,           "FwdDiscThink" );
	
	register_impulse( 201, "FwdImpulse201" );
	
	register_forward( FM_GetGameDescription, "FwdGetGameDescription" );
	
	RegisterHam( Ham_Spawn,      "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_Killed,     "player", "FwdHamPlayerKilled" );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage" );
	
	RegisterHam( Ham_Item_Deploy,            "weapon_knife", "FwdHamKnifeDeploy", 1 );
	RegisterHam( Ham_Weapon_PrimaryAttack,   "weapon_knife", "FwdHamKnifePrimaryAttack" );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "FwdHamKnifeSecondaryAttack" );
	
	DisableHamForward( g_iFwdKilledPost = RegisterHam( Ham_Killed, "player", "FwdHamPlayerKilledPost", 1 ) );
	
	OrpheuRegisterHook( OrpheuGetDLLFunction( "pfnPM_Move", "PM_Move" ), "PM_Move" );
	OrpheuRegisterHook( OrpheuGetFunction( "PM_Jump" ), "PM_Jump" );
	OrpheuRegisterHook( OrpheuGetFunction( "PM_Duck" ), "PM_Duck" );
	
	OrpheuRegisterHook( OrpheuGetFunction( "CheckMapConditions", "CHalfLifeMultiplay" ), "FwdOrpheuSupercede" );
	OrpheuRegisterHook( OrpheuGetFunction( "CheckWinConditions", "CHalfLifeMultiplay" ), "FwdOrpheuSupercede" );
	OrpheuRegisterHook( OrpheuGetFunction( "HasRoundTimeExpired", "CHalfLifeMultiplay" ), "FwdOrpheuSupercede" );
	
	set_msg_block( get_user_msgid( "Money" ),       BLOCK_SET );
	set_msg_block( get_user_msgid( "ClCorpse" ),    BLOCK_SET );
	set_msg_block( get_user_msgid( "WeapPickup" ),  BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	register_logevent( "EventNewRound", 2, "1=Round_Start" );
	register_event( "ResetHUD", "EventResetHUD", "b" );
	register_event( "HideWeapon", "EventHideWeapon", "b" );
	
	g_iMsgSayText    = get_user_msgid( "SayText" );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	g_iMsgAmmoPickup = get_user_msgid( "AmmoPickup" );
	
	g_pGravity    = get_cvar_pointer( "sv_gravity" );
	g_iMaxPlayers = get_maxplayers( );
	
	new Float:vOrigin[ 3 ], szTarget[ 16 ], iEntity = g_iMaxPlayers + 1, iTarget;
	
	while( ( iEntity = find_ent_by_class( iEntity, "trigger_jump" ) ) > 0 ) {
		// Find the target point
		entity_get_string( iEntity, EV_SZ_target, szTarget, 15 );
		
		if( szTarget[ 0 ] && ( iTarget = find_ent_by_tname( g_iMaxPlayers, szTarget ) ) ) {
			entity_get_vector( iTarget, EV_VEC_origin, vOrigin );
			entity_set_vector( iEntity, EV_VEC_vuser1, vOrigin );
		} else {
			log_amx( "trigger_jump - Could not find target %s", szTarget );
			entity_set_int( iEntity, EV_INT_flags, FL_KILLME );
		}
	}
	
//	iEntity = g_iMaxPlayers + 1;
//	while( ( iEntity = find_ent_by_class( iEntity, "info_player_start" ) ) > 0 )
//		remove_entity( iEntity );
	
//	set_cvar_string( "humans_join_team", "t" );
//	set_cvar_num( "mp_fadetoblack", 1 );
	server_cmd( "mp_fadetoblack 1" );
	server_exec( );
	
	register_message( g_iMsgScreenFade, "MessageScreenFade" );
	
	//
	// Rc_GainPowerup( const id, const iPowerUp )
	// Rc_PlayerDeath( const id, const iKiller, bool:bDecapitate, bool:bTeleported )
	// Rc_RoundEnd( const iRoundFinished, const iWinner )
	// Rc_RoundStart( )
	// Rc_DiscHit( const iDisc, const iVictim, const iOwner )
	g_iForwards[ Rc_RoundEnd ]    = CreateMultiForward( "Rc_RoundEnd", ET_IGNORE, FP_CELL, FP_CELL );
	g_iForwards[ Rc_RoundStart ]  = CreateMultiForward( "Rc_RoundStart", ET_IGNORE );
	g_iForwards[ Rc_GainPowerup ] = CreateMultiForward( "Rc_GainPowerup", ET_IGNORE, FP_CELL, FP_CELL );
	g_iForwards[ Rc_PlayerDeath ] = CreateMultiForward( "Rc_PlayerDeath", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
	g_iForwards[ Rc_DiscHit ]     = CreateMultiForward( "Rc_DiscHit", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL );
	
	//
	iEntity = create_entity( "player_weaponstrip" );
	DispatchKeyValue( iEntity, "targetname", "rc_stripper" );
	DispatchSpawn( iEntity );
	
	iEntity = create_entity( "game_player_equip" );
	DispatchKeyValue( iEntity, "weapon_knife", "1" );
	DispatchKeyValue( iEntity, "targetname", "rc_equipment" );
	DispatchSpawn( iEntity );
	
	iEntity = create_entity( "multi_manager" );
	DispatchKeyValue( iEntity, "rc_stripper", "0" );
	DispatchKeyValue( iEntity, "rc_equipment", "0.4" );
	DispatchKeyValue( iEntity, "targetname", "game_playerspawn" );
	DispatchKeyValue( iEntity, "spawnflags", "1" );
	DispatchSpawn( iEntity );
}

/*public plugin_natives( ) {
	register_library( "Ricochet" );
	
	// natives ?
	// Rc_GetPowerUps( id )
}*/

public plugin_precache( ) {
	OrpheuRegisterHook( OrpheuGetFunction( "InstallGameRules" ), "InstallGameRules", OrpheuHookPost );
	
	new i;
	
	for( i = 0; i < sizeof BOUNCE_SOUNDS; i++ )
		precache_sound( BOUNCE_SOUNDS[ i ] );
	
	for( i = 0; i < sizeof THWACK_SOUNDS; i++ )
		precache_sound( THWACK_SOUNDS[ i ] );
	
	for( i = 0; i < sizeof SCREAM_SOUNDS; i++ )
		precache_sound( SCREAM_SOUNDS[ i ] );
	
	for( i = 0; i < sizeof POWERUP_MODELS; i++ )
		precache_model( POWERUP_MODELS[ i ] );
	
	// Create buyzone out of map
	i = create_entity( "func_buyzone" );
	entity_set_size( i, Float:{ -4096.0, -4096.0, -4096.0 }, Float:{ -4095.0, -4095.0, -4095.0 } );
	
	g_iTrail      = precache_model( "sprites/smoke.spr" );
	g_iDiscReturn = precache_model( "sprites/discreturn.spr" );
	
	precache_model( "models/head.mdl" );
	precache_model( "models/ricochet/disc.mdl" );
	precache_model( "models/ricochet/disc_hard.mdl" );
	
	precache_sound( "ricochet/triggerjump.wav" );
	precache_sound( "ricochet/discreturn.wav" );
	precache_sound( "ricochet/dischit.wav" );
	precache_sound( "ricochet/powerup.wav" );
	precache_sound( "ricochet/pspawn.wav" );
	precache_sound( "ricochet/decap.wav" );
	precache_sound( "ricochet/shatter.wav" );
	precache_sound( "ricochet/throw.wav" );
	precache_sound( "ricochet/throw_decap.wav" );
	precache_sound( "ricochet/discdecap.wav" );
	precache_sound( "weapons/electro5.wav" );
	precache_sound( "items/gunpickup2.wav" );
	precache_sound( "player/pl_fallpain3.wav" );
	
	precache_generic( "sound/ricochet/abc/Welcome.mp3" );
	precache_generic( "sound/ricochet/abc/ScoreLimit.mp3" );
	precache_generic( "sound/ricochet/abc/RoundsLimit.mp3" );
}

public InstallGameRules( ) {
	g_pGameRules = OrpheuGetReturn( );
	
//	OrpheuRegisterHookFromObject( g_pGameRules, "CheckMapConditions",  "CGameRules", "FwdOrpheuSupercede" );
//	OrpheuRegisterHookFromObject( g_pGameRules, "CheckWinConditions",  "CGameRules", "FwdOrpheuSupercede" );
//	OrpheuRegisterHookFromObject( g_pGameRules, "HasRoundTimeExpired", "CHalfLifeMultiplay", "FwdOrpheuSupercede" );
}

public PM_Move( OrpheuStruct:ppmove, server )
    g_iPpMove = ppmove;

public PM_Jump( ) {
	new iPlayer = OrpheuGetStructMember( g_iPpMove, "player_index" ) + 1;
	
	if( is_user_alive( iPlayer ) )
		OrpheuSetStructMember( g_iPpMove, "oldbuttons", OrpheuGetStructMember( g_iPpMove, "oldbuttons" ) | IN_JUMP );
}

public PM_Duck( ) {
	new iPlayer = OrpheuGetStructMember( g_iPpMove, "player_index" ) + 1;
	
	if( is_user_alive( iPlayer ) ) {
		new OrpheuStruct:cmd = OrpheuStruct:OrpheuGetStructMember( g_iPpMove, "cmd" );
		OrpheuSetStructMember( cmd, "buttons", OrpheuGetStructMember( cmd, "buttons" ) & ~IN_DUCK );
	}
}

//public OrpheuHookReturn:FwdOrpheuPmSupercede( )
//	return OrpheuSupercede;

public OrpheuHookReturn:FwdOrpheuSupercede( ) {
	OrpheuSetReturn( false );
	return OrpheuSupercede;
}

public CmdRadio( const id )
	return PLUGIN_HANDLED;

public pfn_keyvalue( iEntity ) {
	new szClassName[ 22 ], szKeyName[ 17 ], szValue[ 17 ];
	copy_keyvalue( szClassName, 21, szKeyName, 16, szValue, 16 );
	
	// ===============================================================================
	// Trigger that starts the fall animation for players
	if( equal( szClassName, "trigger_fall" ) ) {
		new iNew = create_entity( "trigger_hurt" );
		
		DispatchKeyValue( iNew, "dmg", "500" );
		DispatchKeyValue( iNew, "damagetype", "1" );
		DispatchKeyValue( iNew, szKeyName, szValue );
		DispatchSpawn( iNew );
		
		entity_set_string( iNew, EV_SZ_classname, szClassName );
		
		//
		new Float:vMin[ 3 ], Float:vMax[ 3 ];
		entity_get_vector( iNew, EV_VEC_absmin, vMin );
		entity_get_vector( iNew, EV_VEC_absmax, vMax );
		
		g_vFallOrigin[ 0 ] = ( vMin[ 0 ] + vMax[ 0 ] ) * 0.5;
		g_vFallOrigin[ 1 ] = ( vMin[ 1 ] + vMax[ 1 ] ) * 0.5;
		g_vFallOrigin[ 2 ] = ( vMin[ 2 ] + vMax[ 2 ] ) * 0.5;
	}
	// ===============================================================================
	// Brush that jumps a player to a target point
	else if( equal( szClassName, "trigger_jump" ) ) {
		static szModel[ 4 ], iHeight;
		
		switch( szKeyName[ 0 ] ) {
			case 'm': copy( szModel, 3, szValue );
			case 'h': iHeight = str_to_num( szValue ) - 15;
			case 't': {
				new iNew = create_entity( "info_target" );
				
				entity_set_int( iNew, EV_INT_solid, SOLID_TRIGGER );
				entity_set_int( iNew, EV_INT_effects, EF_NODRAW );
				entity_set_int( iNew, EV_INT_iuser1, ( iHeight ? iHeight : 113 ) );
				entity_set_string( iNew, EV_SZ_classname, szClassName );
				entity_set_string( iNew, EV_SZ_target, szValue );
				engfunc( EngFunc_SetModel, iNew, szModel );
			}
		}
	}
	// ===============================================================================
	// Trigger that returns discs to their thrower immediately
	else if( equal( szClassName, "trigger_discreturn" ) ) {
		new iNew = create_entity( "info_target" );
		
		entity_set_string( iNew, EV_SZ_classname, szClassName );
		entity_set_int( iNew, EV_INT_solid, SOLID_TRIGGER );
		entity_set_int( iNew, EV_INT_effects, EF_NODRAW );
		engfunc( EngFunc_SetModel, iNew, szValue );
	}
	// ===============================================================================
	// Powerups
	else if( equal( szClassName, "item_powerup" ) ) {
		new iNew = create_entity( "info_target" );
		
		DispatchKeyValue( iNew, "classname", szClassName );
		DispatchKeyValue( iNew, szKeyName, szValue );
		DispatchSpawn( iNew );
		
		entity_set_int( iNew, EV_INT_solid, SOLID_TRIGGER );
		entity_set_size( iNew, Float:{ -64.0, -64.0, 0.0 }, Float:{ 64.0, 64.0, 128.0 } );
		entity_set_float( iNew, EV_FL_nextthink, 10.0 );
		
		entity_set_int( iNew, EV_INT_rendermode, kRenderTransAdd );
		entity_set_float( iNew, EV_FL_renderamt, 150.0 );
		entity_set_int( iNew, EV_INT_effects, EF_NODRAW );
	}
	else if( equal( szClassName, "info_player_spectator" ) ) {
		static Float:vOrigin[ 3 ], iPitch;
		new szInput[ 3 ][ 6 ], iNew;
		
		switch( szKeyName[ 0 ] ) {
			case 'o': {
				iNew = create_entity( "trigger_camera" );
				
				DispatchKeyValue( iNew, "target", "ricochet_camera" );
				DispatchKeyValue( iNew, szKeyName, szValue );
				DispatchSpawn( iNew );
				
				parse( szValue, szInput[ 0 ], 6, szInput[ 1 ], 6, szInput[ 2 ], 6 );
				vOrigin[ 0 ] = str_to_float( szInput[ 0 ] );
				vOrigin[ 1 ] = str_to_float( szInput[ 1 ] );
				vOrigin[ 2 ] = str_to_float( szInput[ 2 ] );
			}
			case 'p': iPitch = str_to_num( szValue );
			case 'a': {
				parse( szValue, szInput[ 0 ], 6, szInput[ 1 ], 6 );
				new iYaw = str_to_num( szInput[ 1 ] );
				
				if( !iYaw ) {
					vOrigin[ 0 ] += 90;
				} else {
					if( iYaw > 180 ) iYaw -= 360;
					
					vOrigin[ 1 ] += iYaw;
				}
				
				vOrigin[ 2 ] -= -iPitch;
				
				iNew = create_entity( "info_target" );
				entity_set_string( iNew, EV_SZ_targetname, "ricochet_camera" );
				entity_set_origin( iNew, vOrigin );
			}
		}
	}
	else if( equal( szClassName, "info_player_start" ) ) {
		remove_entity( iEntity );
	}
}

public FwdItemPowerupThink( const iEntity ) {
	if( entity_get_int( iEntity, EV_INT_effects ) & EF_NODRAW ) {
		if( g_bFinished ) {
			entity_set_float( iEntity, EV_FL_nextthink, 0.0 );
			
			return;
		}
		
		new iPowerUp, iLastPower = entity_get_int( iEntity, EV_INT_iuser1 );
		
		while( iPowerUp == iLastPower ) { iPowerUp = random( MAX_POWERUPS ); }
		
		entity_set_model( iEntity, POWERUP_MODELS[ iPowerUp ] );
		
		entity_set_int( iEntity, EV_INT_iuser1, iPowerUp );
		entity_set_int( iEntity, EV_INT_effects, 0 );
		entity_set_float( iEntity, EV_FL_frame, 0.0 );
		entity_set_float( iEntity, EV_FL_framerate, 1.0 );
		
		emit_sound( iEntity, CHAN_STATIC, "ricochet/pspawn.wav", 0.7, ATTN_NORM, 0, PITCH_NORM );
	}
}

public FwdItemPowerupTouch( const iEntity, const id ) {
	if( ~entity_get_int( iEntity, EV_INT_effects ) & EF_NODRAW && is_user_alive( id ) ) {
		new iPow   = entity_get_int( iEntity, EV_INT_iuser1 ),
			iPower = ( 1 << iPow );
		
		if( HasPower( id, iPower ) )
			return;
		
		g_iPowers[ id ]      |= iPower;
		g_iPowerupDiscs[ id ] = 3;
		
		client_print( id, print_center, "You received ^"%s^"", POWERUP_NAMES[ iPow ] );
		
		entity_set_int( iEntity, EV_INT_effects, EF_NODRAW );
		entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + DISC_POWERUP_RESPAWN_TIME );
		
		emit_sound( id, CHAN_STATIC, "ricochet/powerup.wav", 0.6, ATTN_NORM, 0, PITCH_NORM );
		
		// Call forward
		new iReturn;
		ExecuteForward( g_iForwards[ Rc_GainPowerup ], iReturn, id, iPower );
	}
}

public FwdTriggerTouch_Jump( const iEntity, const id ) {
	if( !is_user_alive( id ) )
		return;
	
	new Float:flLastTouched = entity_get_float( iEntity, EV_FL_fuser1 ),
		Float:flGameTime    = get_gametime( );
	
	if( flLastTouched > flGameTime ) {
		entity_set_float( iEntity, EV_FL_fuser1, flGameTime + 0.1 );
		return;
	}
	
	new Float:flGravity = get_pcvar_float( g_pGravity );
	new Float:vMidPoint[ 3 ], Float:vOrigin[ 3 ], Float:vTarget[ 3 ];
	
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	entity_get_vector( iEntity, EV_VEC_vuser1, vTarget );
	
	vMidPoint[ 0 ] = vOrigin[ 0 ] + ( vTarget[ 0 ] - vOrigin[ 0 ] ) * 0.5;
	vMidPoint[ 1 ] = vOrigin[ 1 ] + ( vTarget[ 1 ] - vOrigin[ 1 ] ) * 0.5;
	vMidPoint[ 2 ] = vOrigin[ 2 ] + ( vTarget[ 2 ] - vOrigin[ 2 ] ) * 0.5;
	vMidPoint[ 2 ] += entity_get_int( iEntity, EV_INT_iuser1 );
	
	// How high should we travel to reach the apex
	new Float:flDistance1 = vMidPoint[ 2 ] - vOrigin[ 2 ],
		Float:flDistance2 = vMidPoint[ 2 ] - vTarget[ 2 ];
	
	// How long will it take to travel this distance
	new Float:flTime1 = floatsqroot( flDistance1 / ( 0.5 * flGravity ) ),
		Float:flTime2 = floatsqroot( flDistance2 / ( 0.5 * flGravity ) );
	
	if( flTime1 < 0.1 ) return;
	
	// how hard to launch to get there in time.
	new Float:vTargetVel[ 3 ];
	vTargetVel[ 0 ] = vTarget[ 0 ] - vOrigin[ 0 ] / ( flTime1 + flTime2 );
	vTargetVel[ 1 ] = vTarget[ 1 ] - vOrigin[ 1 ] / ( flTime1 + flTime2 );
	vTargetVel[ 2 ] = flGravity * flTime1;
	
	// ((CBasePlayer*)pOther)->SetAnimation( PLAYER_SUPERJUMP );
	
	entity_set_vector( id, EV_VEC_velocity, vTargetVel );
	entity_set_float( iEntity, EV_FL_fuser1, flGameTime + 0.2 );
	
	emit_sound( id, CHAN_STATIC, "ricochet/triggerjump.wav", 0.5, ATTN_NORM, 0, PITCH_NORM );
}

public FwdDiscTouch_Disc( const iDisc, const iOther ) {
	if( !is_valid_ent( iDisc ) || !is_valid_ent( iOther ) )
		return;
	
//	client_print( 0, print_chat, "[ %f ] Friendly: %s | two discs touched each other!", get_gametime( ),
//		( entity_get_edict( iDisc, EV_ENT_euser1 ) == entity_get_edict( iOther, EV_ENT_euser1 ) ) ? "Yes" : "No" );
	
	if( entity_get_edict( iDisc, EV_ENT_euser1 ) != entity_get_edict( iOther, EV_ENT_euser1 ) ) {
	//	DiscReturnEffect( iDisc );
		
	//	emit_sound( iDisc, CHAN_ITEM, "ricochet/dischit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		
	//	ReturnToThrower( iDisc );
	//	ReturnToThrower( iOther );
	}
}

public FwdDiscTouch_Player( const iDisc, const iOther ) {
	if( is_user_alive( iOther ) ) {
		new Float:flGameTime = get_gametime( ), iOwner = entity_get_edict( iDisc, EV_ENT_euser1 );
		
		if( iOther == iOwner ) {
			if( entity_get_float( iDisc, EV_FL_fuser1 ) > flGameTime )
				return;
			
			emit_sound( iOther, CHAN_WEAPON, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			
			ReturnToThrower( iDisc );
			
			return;
		}
		else if( entity_get_float( iDisc, EV_FL_fuser2 ) < flGameTime ) {
			new iReturn, iFlags  = entity_get_int( iOther, EV_INT_flags ),
				bool:bDecapitate = bool:entity_get_int( iDisc, EV_INT_iuser2 );
			
			// Call forward
			ExecuteForward( g_iForwards[ Rc_DiscHit ], iReturn, iDisc, iOther, iOwner );
			
			// Do freeze seperately so you can freeze and shatter a person with a single shot
			if( ~iFlags & FL_FROZEN && entity_get_int( iDisc, EV_INT_iuser1 ) & POW_FREEZE ) {
				emit_sound( iOther, CHAN_WEAPON, "weapons/electro5.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				
				if( !bDecapitate ) {
					entity_set_int( iOther, EV_INT_flags, iFlags | FL_FROZEN );
					
					// Glow blue
					entity_set_int( iOther, EV_INT_renderfx, kRenderFxGlowShell );
					entity_set_float( iOther, EV_FL_renderamt, 25.0 );
					entity_set_vector( iOther, EV_VEC_rendercolor, Float:{ 0.0, 0.0, 200.0 } );
					
					entity_set_float( iDisc, EV_FL_fuser2, flGameTime + 2.0 ); // fDontTouchEnemies
					
					set_task( FREEZE_TIME, "ClearFreezeAndRender", iOther );
					
					// Screen fade
					message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, iOther );
					write_short( ( 2 * ( 1 << 12 ) ) );
					write_short( floatround( ( FREEZE_TIME * ( 1 << 12 ) ) ) );
					write_short( 0x0000 );
					write_byte( 0 );
					write_byte( 127 );
					write_byte( 255 );
					write_byte( 130 );
					message_end( );
					
					// If it's not a decap, return now. If it's a decap, continue to shatter
					return;
				}
			}
			
		//	if ( m_bTeleported )
		//		((CBasePlayer*)pOther)->m_flLastDiscHitTeleport = gpGlobals->time;
			
			g_iLastPlayerToHitMe[ iOther ] = iOwner;
			g_iLastDiscBounces[ iOther ]   = entity_get_int( iDisc, EV_INT_iuser4 );
			g_flLastDiscHit[ iOther ]      = flGameTime;
			
			if( bDecapitate ) { // Decapitate!
				entity_set_float( iDisc, EV_FL_fuser2, flGameTime + 0.5 ); // fDontTouchEnemies
				
				set_pdata_int( iOther, m_LastHitGroup, HIT_HEAD, 5 );
				
				ExecuteHamB( Ham_TakeDamage, iOther, 0, 0, 5000.0, DMG_ALWAYSGIB );
				
				if( g_vFallOrigin[ 0 ] )
					entity_set_origin( iOther, g_vFallOrigin );
				
				// If the player is frozen, shatter instead of decapitating
				if( iFlags & FL_FROZEN ) {
					emit_sound( iOther, CHAN_WEAPON, "ricochet/shatter.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
					
					// Remove render
					remove_task( iOther );
					
					entity_set_int( iOther, EV_INT_renderfx, kRenderFxNone );
					entity_set_float( iOther, EV_FL_renderamt, 0.0 );
					entity_set_vector( iOther, EV_VEC_rendercolor, Float:{ 0.0, 0.0, 0.0 } );
				} else {
					emit_sound( iOther, CHAN_WEAPON, "ricochet/decap.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				}
				
				// Call forward
				ExecuteForward( g_iForwards[ Rc_PlayerDeath ], iReturn, iOther, iOwner, true, false );
			} else {
				emit_sound( iOther, CHAN_BODY, THWACK_SOUNDS[ random( sizeof( THWACK_SOUNDS ) ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
				
				// Push the player
				new Float:vDir[ 3 ];
				entity_get_vector( iDisc, EV_VEC_velocity, vDir );
				xs_vec_normalize( vDir, vDir );
				xs_vec_mul_scalar( vDir, DISC_PUSH_MULTIPLIER, vDir );
				
				// Remove on ground flags
				if( iFlags & FL_ONGROUND )
					entity_set_int( iOther, EV_INT_flags, iFlags & ~FL_ONGROUND );
				
				entity_set_vector( iOther, EV_VEC_velocity, vDir );
				
				// Shield flash only if the player isnt frozen
			/*	if ( ((CBasePlayer*)pOther)->m_iFrozen == false ) {
					pOther->pev->renderfx = kRenderFxGlowShell;
					pOther->pev->rendercolor.x = 255;
					pOther->pev->renderamt = 150;
				}	*/
				
				entity_set_float( iDisc, EV_FL_fuser2, flGameTime + 2.0 ); // fDontTouchEnemies
			}
		}
	}
}

public FwdDiscTouch_Teleport( const iTrigger, const iDisc ) {
	new Float:vOrigin[ 3 ], iOrigin[ 3 ];
	entity_get_vector( iDisc, EV_VEC_origin, vOrigin );
	FVecIVec( vOrigin, iOrigin );
	
	TehReturnEffect( iOrigin );
	
	new szTarget[ 11 ];
	entity_get_string( iTrigger, EV_SZ_target, szTarget, 10 );
	
	new iTeleport = find_ent_by_tname( g_iMaxPlayers, szTarget );
	
	if( !iTeleport ) {
		log_amx( "trigger_teleport - Could not find target %s", szTarget );
		
		ReturnToThrower( iDisc );
		
		return;
	}
	
	entity_get_vector( iTeleport, EV_VEC_origin, vOrigin );
	entity_set_origin( iDisc, vOrigin );
	FVecIVec( vOrigin, iOrigin );
	TehReturnEffect( iOrigin );
	
	emit_sound( iDisc, CHAN_AUTO, "ricochet/discreturn.wav", 0.2, ATTN_NORM, 0, PITCH_NORM );
	
	// Discs keep their velocity
	entity_get_vector( iTeleport, EV_VEC_angles, vOrigin );
//	entity_set_vector( iDisc, EV_VEC_angles, vAngles );
	
	//engfunc( EngFunc_MakeVectors, vOrigin );
	
	new bool:bFastDisc = bool:( entity_get_int( iDisc, EV_INT_iuser1 ) & POW_FAST );
	
	vOrigin[ 0 ] *= DISC_VELOCITY * ( bFastDisc ? 1.5 : 1.0 ); // Fast powerup makes discs go faster
	vOrigin[ 1 ] *= DISC_VELOCITY * ( bFastDisc ? 1.5 : 1.0 ); // Fast powerup makes discs go faster
	vOrigin[ 2 ] *= DISC_VELOCITY * ( bFastDisc ? 1.5 : 1.0 ); // Fast powerup makes discs go faster
	
	entity_set_vector( iDisc, EV_VEC_velocity, vOrigin );
	
//	m_bTeleported = true;
}

public FwdDiscTouch_DiscReturn( const iTrigger, const iDisc ) {
	DiscReturnEffect( iDisc );
	
	emit_sound( iDisc, CHAN_AUTO, "ricochet/discreturn.wav", 0.2, ATTN_NORM, 0, PITCH_NORM );
	
	ReturnToThrower( iDisc );
}

public FwdDiscTouch_WorldSpawn( const iDisc, const iOther ) {
	entity_set_int( iDisc, EV_INT_iuser4, ( 1 + entity_get_int( iDisc, EV_INT_iuser4 ) ) ); // iBounces
	
	emit_sound( iDisc, CHAN_ITEM, BOUNCE_SOUNDS[ random( sizeof( BOUNCE_SOUNDS ) ) ], VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	
	new Float:vOrigin[ 3 ], iOrigin[ 3 ];
	entity_get_vector( iDisc, EV_VEC_origin, vOrigin );
	FVecIVec( vOrigin, iOrigin );
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
	write_byte( TE_SPARKS );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	message_end( );
}

public FwdHamKnifeDeploy( const iKnife ) {
	new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
	
	set_pev( id, pev_viewmodel, 0 );
	set_pev( id, pev_weaponmodel, 0 );
}

public FwdHamKnifeSecondaryAttack( const iKnife ) {
	if( g_bFinished )
		return HAM_SUPERCEDE;
	
	new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
	
	// Fast powerup has a number of discs per 1 normal disc (so it can throw a decap when it has at least 1 real disc)
	if( ( g_iAmmo[ id ] && HasPower( id, POW_FAST ) ) || g_iAmmo[ id ] == 3 ) {
		// Fast shot allows faster throwing
		set_pdata_float( iKnife, m_flNextSecondaryAttack, HasPower( id, POW_FAST ) ? 0.3 : 0.6, 4 );
		
		FireDisc( id, true );
		
		// Remove fast shot powerup, or deduct all discs if we don't have fast shot
		if( HasPower( id, POW_FAST ) ) {
			g_iFastShotDiscs[ id ] = 3;
			g_iPowers[ id ] &= ~POW_FAST;
			g_iAmmo[ id ]--;
		} else {
			g_iAmmo[ id ] = 0;
		}
		
		// Remove one powered disc
		if( g_iPowerupDiscs[ id ] )
			if( --g_iPowerupDiscs[ id ] == 0 )
				g_iPowers[ id ] = 0;
	} else
		set_pdata_float( iKnife, m_flNextSecondaryAttack, 0.5, 4 );
	
	return HAM_SUPERCEDE;
}

public FwdHamKnifePrimaryAttack( const iKnife ) {
	if( g_bFinished )
		return HAM_SUPERCEDE;
	
	new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
	
	if( g_iAmmo[ id ] ) {
		// Fast shot allows faster throwing
		set_pdata_float( iKnife, m_flNextPrimaryAttack, HasPower( id, POW_FAST ) ? 0.2 : 0.5, 4 );
		
		new bool:bRemoveSelf;
		
		// Fast powerup has a number of discs per 1 normal disc
		if( HasPower( id, POW_FAST ) ) {
			if( --g_iFastShotDiscs[ id ] == 0 )
				g_iFastShotDiscs[ id ] = 3;
			else
				bRemoveSelf = true;
		}
		
		FireDisc( id, false, bRemoveSelf );
		
		g_iAmmo[ id ]--;
		
		// Remove one powered disc
		if( g_iPowerupDiscs[ id ] )
			if( --g_iPowerupDiscs[ id ] == 0 )
				g_iPowers[ id ] = 0;
	} else
		set_pdata_float( iKnife, m_flNextPrimaryAttack, 1.0, 4 );
	
	return HAM_SUPERCEDE;
}

CreateDisc( Float:vOrigin[ 3 ], Float:vAngles[ 3 ], iOwner, bool:bDecapitator, iPowerupFlags, bool:bRemoveSelf = false ) {
	new iDisc = create_entity( "info_target" );
	
	if( !iDisc )
		return -1;
	
	entity_set_string( iDisc, EV_SZ_classname, "disc" );
	entity_set_origin( iDisc, vOrigin );
	entity_set_vector( iDisc, EV_VEC_angles, vAngles );
	entity_set_edict( iDisc, EV_ENT_euser1, iOwner );
	entity_set_int( iDisc, EV_INT_team, _:cs_get_user_team( iOwner ) );
	entity_set_int( iDisc, EV_INT_iuser1, iPowerupFlags );
	entity_set_int( iDisc, EV_INT_iuser2, ( bDecapitator || ( iPowerupFlags & POW_HARD ) ) );
	entity_set_int( iDisc, EV_INT_iuser3, bRemoveSelf );
	entity_set_int( iDisc, EV_INT_movetype, MOVETYPE_BOUNCEMISSILE );
	entity_set_int( iDisc, EV_INT_solid, SOLID_TRIGGER );
	
	entity_set_model( iDisc, iPowerupFlags & POW_HARD ? "models/ricochet/disc_hard.mdl" : "models/ricochet/disc.mdl" );
	entity_set_size( iDisc, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 } );
	
	new Float:vVelocity[ 3 ];
	engfunc( EngFunc_MakeVectors, vAngles );
	global_get( glb_v_forward, vVelocity );
	
	vVelocity[ 0 ] *= DISC_VELOCITY * ( iPowerupFlags & POW_FAST ? 1.5 : 1.0 ); // Fast powerup makes discs go faster
	vVelocity[ 1 ] *= DISC_VELOCITY * ( iPowerupFlags & POW_FAST ? 1.5 : 1.0 );
	vVelocity[ 2 ] *= DISC_VELOCITY * ( iPowerupFlags & POW_FAST ? 1.5 : 1.0 );
	
	entity_set_vector( iDisc, EV_VEC_velocity, vVelocity );
	
	new iColor = !!( iPowerupFlags & POW_FREEZE );
	
	// Trail
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( iDisc );
	write_short( g_iTrail );
	write_byte( bDecapitator ? 5 : 3 )
	write_byte( 5 );
	write_byte( g_iDiscColors[ iColor ][ 0 ] );
	write_byte( g_iDiscColors[ iColor ][ 1 ] );
	write_byte( g_iDiscColors[ iColor ][ 2 ] );
	write_byte( 250 );
	message_end( );
	
	// Decapitator's make sound
	if( bDecapitator )
		emit_sound( iDisc, CHAN_VOICE, "ricochet/discdecap.wav", 0.5, ATTN_NORM, 0, PITCH_NORM );
	
	// Highlighter
	entity_set_int( iDisc, EV_INT_renderfx, kRenderFxGlowShell );
	entity_set_vector( iDisc, EV_VEC_rendercolor, Float:g_iDiscColors[ iColor ] );
	entity_set_float( iDisc, EV_FL_renderamt, 100.0 );
	
	new Float:flGameTime = get_gametime( );
	
	entity_set_float( iDisc, EV_FL_fuser1, flGameTime + 0.2 ); // fDontTouchOwner
	entity_set_float( iDisc, EV_FL_nextthink, flGameTime + 1.0 );
	
	return iDisc;
}

FireDisc( const id, const bool:bDecapitator, const bool:bRemoveSelf = false ) {
//	SendWeaponAnim( DISC_THROW1, 1 );
//	m_pPlayer->SetAnimation( PLAYER_ATTACK1 );
	
	emit_sound( id, CHAN_WEAPON, bDecapitator ? "ricochet/throw_decap.wav" : "ricochet/throw.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
	
	new Float:vStart[ 3 ], Float:vOrigin[ 3 ], Float:vFireDir[ 3 ], Float:vViewOfs[ 3 ], Float:vForward[ 3 ];
	entity_get_vector( id, EV_VEC_v_angle, vFireDir );
	
	vFireDir[ 0 ] = 0.0;
	vFireDir[ 2 ] = 0.0;
	
	engfunc( EngFunc_MakeVectors, vFireDir );
	
	entity_get_vector( id, EV_VEC_view_ofs, vViewOfs );
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	global_get( glb_v_forward, vForward );
	
	vStart[ 0 ] = vOrigin[ 0 ] + ( vViewOfs[ 0 ] * 0.25 ) + vForward[ 0 ] * 16.0;
	vStart[ 1 ] = vOrigin[ 1 ] + ( vViewOfs[ 1 ] * 0.25 ) + vForward[ 1 ] * 16.0;
	vStart[ 2 ] = vOrigin[ 2 ] + ( vViewOfs[ 2 ] * 0.25 ) + vForward[ 2 ] * 16.0;
	
	CreateDisc( vStart, vFireDir, id, bDecapitator, g_iPowers[ id ], bRemoveSelf );
	
	// Triple shot fires 2 more disks
	if( HasPower( id, POW_TRIPLE ) ) {
		vFireDir[ 1 ] -= 7;
		CreateDisc( vStart, vFireDir, id, bDecapitator, POW_TRIPLE, true );
		
		vFireDir[ 1 ] += 14;
		CreateDisc( vStart, vFireDir, id, bDecapitator, POW_TRIPLE, true );
	}
}

ReturnToThrower( const iDisc ) {
	new id               = entity_get_edict( iDisc, EV_ENT_euser1 ),
		bool:bDecapitate = bool:entity_get_int( iDisc, EV_INT_iuser2 );
	
	if( bDecapitate )
		emit_sound( iDisc, CHAN_VOICE, "ricochet/discdecap.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
	
	if( g_iAmmo[ id ] < 3 /*&& !entity_get_int( iDisc, EV_INT_iuser3 ) - bRemoveSelf*/ ) {
		if( bDecapitate )
			g_iAmmo[ id ] = 3;
		else
			g_iAmmo[ id ]++;
		
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgAmmoPickup, _, id );
		write_byte( 12 );
		write_byte( bDecapitate ? 3 : 1 );
		message_end( );
	}
	
	remove_entity( iDisc );
}

DiscReturnEffect( const iDisc ) {
	new Float:vOrigin[ 3 ], iOrigin[ 3 ];
	entity_get_vector( iDisc, EV_VEC_origin, vOrigin );
	FVecIVec( vOrigin, iOrigin );
	
	TehReturnEffect( iOrigin );
}

TehReturnEffect( const iOrigin[ 3 ] ) {
	message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
	write_byte( TE_SPRITE );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	write_short( g_iDiscReturn );
	write_byte( 8 );
	write_byte( 255 );
	message_end( );
}

public ClearFreezeAndRender( const id ) {
	if( !is_user_alive( id ) ) // Remove task on disconnect / death instead ?
		return;
	
	new iFlags = entity_get_int( id, EV_INT_flags );
	
	if( iFlags & FL_FROZEN ) {
		entity_set_int( id, EV_INT_flags, iFlags & ~FL_FROZEN );
		
		entity_set_int( id, EV_INT_renderfx, kRenderFxNone );
		entity_set_float( id, EV_FL_renderamt, 0.0 );
		entity_set_vector( id, EV_VEC_rendercolor, Float:{ 0.0, 0.0, 0.0 } );
	}
}

public FwdGibHeadThink( const iEntity )
	remove_entity( iEntity );

public FwdDiscThink( const iDisc ) {
	// Make Freeze discs home towards any player ahead of them
//	if ( (m_iPowerupFlags & POW_FREEZE) && (m_iBounces == 0) ) // soon..
	
	new iBounces = entity_get_int( iDisc, EV_INT_iuser4 );
	
	// Track the player if we've bounced 3 or more times ( Fast discs remove immediately )
	if( iBounces >= 3 || ( entity_get_int( iDisc, EV_INT_iuser1 ) & POW_FAST && iBounces >= 1 ) ) {
		if( entity_get_int( iDisc, EV_INT_iuser3 ) ) { // bRemoveSelf
			emit_sound( iDisc, CHAN_VOICE, "ricochet/discdecap.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
			remove_entity( iDisc );
			return;
		}
		
		// 7 Bounces, just remove myself
		if( iBounces > 7 ) {
			ReturnToThrower( iDisc );
			return;
		}
		
		// Start heading for the player
		// Can anyone say me what the hell is this ?
		/*if ( m_hOwner )
		{
			Vector vecDir = ( m_hOwner->pev->origin - pev->origin );
			vecDir = vecDir.Normalize();
			pev->velocity = vecDir * DISC_VELOCITY;
			pev->nextthink = gpGlobals->time + 0.1;
		}
		else
		{
			UTIL_Remove( this ); 
		}*/
	}
	
	// Call think, if it needs any funcs, on each bounce.
	entity_set_float( iDisc, EV_FL_nextthink, get_gametime( ) + 0.1 );
}

public FwdHamPlayerKilled( const id, iAttacker, const iShouldGib ) {
	// Tell all this player's discs to remove themselves after the 3rd bounce
	new iDisc = FM_NULLENT;
	
	while( ( iDisc = find_ent_by_class( iDisc, disc ) ) > 0 ) {
		if( entity_get_edict( iDisc, EV_ENT_euser1 ) == id ) {
			entity_set_int( iDisc, EV_INT_iuser3, true ); // bRemoveSelf
			
			// make think
		}
	}
	
	/*if( is_user_alive( iAttacker ) ) {
		CheckForFrags( iAttacker );
		
		return;
	}*/
	
	if( iAttacker == 0 ) { // Decap?
		if( get_gametime( ) < g_flLastDiscHit[ id ] + 4.0 ) {
			EnableHamForward( g_iFwdKilledPost );
			
			g_iAttacker = iAttacker = g_iLastPlayerToHitMe[ id ];
			
			CheckForFrags( iAttacker );
			
			set_pdata_int( iAttacker, m_iTeam, _:CS_TEAM_T, 5 );
			
			SetHamParamEntity( 2, iAttacker );
			
			client_print( iAttacker, print_center, "%s", HIT_MESSAGES[ 0 ] );
		}
		
		return;
	}
	
	new szClassName[ 13 ];
	entity_get_string( iAttacker, EV_SZ_classname, szClassName, 12 );
	
	if( equal( szClassName, "trigger_fall" ) ) {
		emit_sound( id, CHAN_BODY, SCREAM_SOUNDS[ random( sizeof( SCREAM_SOUNDS ) ) ], 0.6, ATTN_NORM, 0, PITCH_NORM );
		
		EnableHamForward( g_iFwdKilledPost );
		
		// Let's check if player fell because of enemy's disc
		if( get_gametime( ) < g_flLastDiscHit[ id ] + 4.0 ) {
			g_iAttacker = iAttacker = g_iLastPlayerToHitMe[ id ];
			
			CheckForFrags( iAttacker );
			
			set_pdata_int( iAttacker, m_iTeam, _:CS_TEAM_T, 5 );
			
			SetHamParamEntity( 2, iAttacker );
			
			iDisc = clamp( g_iLastDiscBounces[ id ], 1, 5 );
			
			client_print( iAttacker, print_center, "%s", HIT_MESSAGES[ iDisc ] );
			
			ExecuteForward( g_iForwards[ Rc_PlayerDeath ], iDisc, id, iAttacker, false, false );
		} else {
			// Player fell him self
			ExecuteForward( g_iForwards[ Rc_PlayerDeath ], iDisc, id, 0, false, false );
		}
	}
}

public client_PreThink( id ) {
	if( g_flStartScaleTime[ id ] ) { // Fall animation
		new Float:flGameTime  = get_gametime( ),
			Float:flTimeDelta = flGameTime - g_flStartScaleTime[ id ];
		
		if( flTimeDelta >= 6.0 || ( flTimeDelta > 4.0 && entity_get_int( id, EV_INT_iuser1 ) ) ) {
			g_flStartScaleTime[ id ] = 0.0;
			
			if( !g_bFinished && cs_get_user_team( id ) == CS_TEAM_CT )
				ExecuteHamB( Ham_CS_RoundRespawn, id );
			
			return;
		}
		
		// Spin the view
		new Float:vViewAngle[ 3 ];
		vViewAngle[ 0 ] = 89.0;
		vViewAngle[ 1 ] = ( flTimeDelta * 45.0 ) * ( 1.0 + ( flTimeDelta * 2.0 ) );
		
		entity_set_vector( id, EV_VEC_angles, vViewAngle );
		entity_set_int( id, EV_INT_fixangle, 1 );
	}
}

public FwdHamPlayerKilledPost( const id, iAttacker, const iShouldGib ) {
	DisableHamForward( g_iFwdKilledPost );
	
	g_flStartScaleTime[ id ] = get_gametime( );
	
	if( g_iAttacker ) {
		set_pdata_int( g_iAttacker, m_iTeam, _:CS_TEAM_CT, 5 );
		
		g_iAttacker = 0;
	}
}

public client_putinserver( id ) {
	g_flStartScaleTime[ id ] = 0.0;
	g_bFirstSpawn[ id ]      = true;
}

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {
		if( !g_bFinished && g_bFirstSpawn[ id ] ) {
			g_bFirstSpawn[ id ] = false;
			
			client_cmd( id, "mp3 play sound/ricochet/abc/Welcome" );
			
			GreenPrint( id, "^3[Ricochet]^1 Welcome to Ricochet Arena!^4 Remember, this is Free-For-All!" );
			GreenPrint( id, "^3[Ricochet]^1 Visit us at^4 www.my-run.de ^1!" );
		}
		
		set_pdata_int( id, m_iRadiosLeft, 0 );
		
		g_iAmmo[ id ]          = 3;
		g_iPowers[ id ]        = 0;
		g_iPowerupDiscs[ id ]  = 0;
		g_iFastShotDiscs[ id ] = 3;
		g_iLastPlayerToHitMe[ id ] = 0;
		g_flStartScaleTime[ id ]   = 0.0;
	}
}

public FwdHamPlayerTakeDamage( const id, iInflictor, iAttacker, Float:flDamage, iDamageBits ) {
	if( iDamageBits & DMG_FALL ) {
		emit_sound( id, CHAN_BODY, "player/pl_fallpain3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public FwdImpulse201( )
	return PLUGIN_HANDLED_MAIN;

public FwdGetGameDescription( ) {
	forward_return( FMV_STRING, GAME_DESC );
	
	return FMRES_SUPERCEDE;
}

public EventNewRound( ) {
	if( !g_bFinished )
		return;
	
	g_bFinished = false;
	
	new iPlayers[ 32 ], iNum, id, i;
	get_players( iPlayers, iNum, "a" );
	
	for( i = 0; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		entity_set_float( id, EV_FL_frags, 0.0 );
		cs_set_user_deaths( id, 0 );
	}
	
	// Force powerups to be spawned
	while( ( i = find_ent_by_class( i, "item_powerup" ) ) > 0 )
		entity_set_float( i, EV_FL_nextthink, get_gametime( ) + 4.0 );
	
	ExecuteForward( g_iForwards[ Rc_RoundStart ], id );
}

public EventResetHUD( const id ) {
	set_pdata_int( id, m_iClientHideHUD, 0 );
	set_pdata_int( id, m_iHideHUD, HIDE_HUD );
}

public EventHideWeapon( const id ) {
	new iFlags = read_data( 1 );
	
	if( iFlags & HIDE_HUD != HIDE_HUD ) {
		set_pdata_int( id, m_iClientHideHUD, 0 );
		set_pdata_int( id, m_iHideHUD, iFlags | HIDE_HUD );
	}
}

public MessageScreenFade( const iMsgId, const iMsgType, const id ) { // block fadetoblack
	if( iMsgType == MSG_ONE && get_msg_arg_int( 3 ) == 5 && get_msg_arg_int( 7 ) == 255 ) {
		set_msg_arg_int( 7, ARG_BYTE, 0 );
	}
	
//	return ( iMsgType == MSG_ONE && get_msg_arg_int( 3 ) == 5 && get_msg_arg_int( 7 ) == 255 ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
GreenPrint( id, const message[ ], any:... ) {
	new szMessage[ 192 ];
	vformat( szMessage, 191, message, 3 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
}

bool:HasPower( const id, const iPower )
	return bool:( g_iPowers[ id ] & iPower );

CheckForFrags( const id ) {
	new iFragLimit = get_pcvar_num( g_pFragLimit ) - 3;
	
	if( iFragLimit > 0 ) {
		new iFrags = get_user_frags( id ) + 1;
		
		if( iFrags >= iFragLimit ) {
			iFrags = iFragLimit - iFrags + 3;
			
			if( !iFrags ) {
				g_bFinished = true;
				
				iFragLimit = get_pcvar_num( g_pMaxRounds );
				iFrags = get_mp_pdata( "m_iNumTerroristWins" );
				
				if( iFragLimit > 0 && iFragLimit >= iFrags ) {
					client_print( 0, print_chat, "^t[Ricochet] The round limit was reached!!" );
				}
				
				client_cmd( 0, "mp3 play sound/ricochet/abc/ScoreLimit" );
				
				new szName[ 32 ];
				get_user_name( id, szName, 31 );
				
				set_hudmessage( 128, 128, 128, -1.0, 0.15, 0, 6.0, 6.0, 0.2, 0.2, 2 );
				show_hudmessage( 0, "%s was first to reach frag limit !", szName );
				
				client_print( 0, print_center, "%s was first to reach frag limit !", szName );
				
				// Call forward
				ExecuteForward( g_iForwards[ Rc_RoundEnd ], iFragLimit, iFrags, id );
				
				// ->
				set_mp_pdata( "m_iNumTerroristWins", iFrags + 1 );
				
				UpdateTeamScores( );
				
				set_mp_pdata( "m_iRoundWinStatus", 2 );
				set_mp_pdata( "m_fTeamCount", get_gametime( ) + 6.0 );
				set_mp_pdata( "m_bRoundTerminating", true );
				
				CheckWinConditions( );
				
				// -> Delete all discs
				new i = FM_NULLENT;
				
				while( ( i = find_ent_by_class( i, disc ) ) > 0 ) {
					if( entity_get_int( i, EV_INT_iuser2 ) ) // bDecapitate
						emit_sound( i, CHAN_VOICE, "ricochet/discdecap.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
					
					remove_entity( i );
				}
				
				// -> Unfroze all
				new iPlayers[ 32 ], iNum, id;
				get_players( iPlayers, iNum, "ac" );
				
				for( i = 0; i < iNum; i++ ) {
					id = iPlayers[ i ];
					
					remove_task( id );
					ClearFreezeAndRender( id );
				}
				
				// Screen fade
				message_begin( MSG_BROADCAST, g_iMsgScreenFade );
				write_short( ( 3 * ( 1 << 12 ) ) );
				write_short( ( 9 * ( 1 << 12 ) ) );
				write_short( 0x0001 );
				write_byte( 0 );
				write_byte( 0 );
				write_byte( 0 );
				write_byte( 255 );
				message_end( );
				
				GreenPrint( 0, "^3[Ricochet]^1 Round^4 %i^1 has finished. Prepare to new battle!", ( iFrags + 1 ) );
				
				return;
			}
			
			set_hudmessage( 128, 128, 128, -1.0, 0.15, 0, 3.0, 3.0, 0.2, 0.2, 2 );
			show_hudmessage( id, "%i Frag%s left !", iFrags, iFrags == 1 ? "" : "s" );
		}
	}
}

CheckWinConditions( ) {
	static OrpheuFunction:handleFuncCheckWinConditions;
	
	if( !handleFuncCheckWinConditions )
		handleFuncCheckWinConditions = OrpheuGetFunction( "CheckWinConditions", "CHalfLifeMultiplay" );
	
	OrpheuCall( handleFuncCheckWinConditions, g_pGameRules );
}

UpdateTeamScores( ) {
	static OrpheuFunction:handleFuncUpdateTeamScores;
	
	if( !handleFuncUpdateTeamScores )
		handleFuncUpdateTeamScores = OrpheuGetFunction( "UpdateTeamScores", "CHalfLifeMultiplay" );
	
	OrpheuCallSuper( handleFuncUpdateTeamScores, g_pGameRules );
}
