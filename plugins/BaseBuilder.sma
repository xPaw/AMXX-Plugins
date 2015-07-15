#include < amxmodx >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < fun >
#include < hamsandwich >

const TASK				  = 546421;
const m_iHideHUD			= 361;
const m_iClientHideHUD	  = 362;

#define MOUSE2_MOVE_DURATION 0.150 // Milliseconds
#define IsPlayer(%1)	( 1 <= %1 <= g_iMaxPlayers )
#define IsUserAdmin(%1)	( get_user_flags( %1 ) & ADMIN_KICK )

const SHOTGUN_WEAPONS_BIT 	 = ( 1 << CSW_M3 | 1 << CSW_XM1014 );
const SUBMACHINE_WEAPONS_BIT = ( 1 << CSW_TMP | 1 << CSW_MAC10 | 1 << CSW_MP5NAVY | 1 << CSW_UMP45 | 1 << CSW_P90 );
const RIFLE_WEAPONS_BIT		 = ( 1 << CSW_FAMAS | 1 << CSW_GALIL | 1 << CSW_AK47 | 1 << CSW_SCOUT | 1 << CSW_M4A1 | 1 << CSW_SG552 | 1 << CSW_AUG | 1 << CSW_AWP );
const MACHINE_WEAPONS_BIT	 = ( 1 << CSW_M249 );
const PRIMARY_WEAPONS_BIT	 = ( SHOTGUN_WEAPONS_BIT | SUBMACHINE_WEAPONS_BIT | RIFLE_WEAPONS_BIT | MACHINE_WEAPONS_BIT );

new const g_szGamename[ ]	  = "[ my-run.de ]";
new const g_szZombieHand[ ]	= "models/myrun/bb_hand.mdl";
new const g_szMotdFile[ ]	  = "http://my-run.de/BaseBuilderMod.php";
new const g_szMotdTitle[ ]	 = "Base Builder Rules";		// Motd Title
new const g_szDeclineReason[ ] = "Rules Rejected";		// Kick Reason (Terms Rejected)

new g_hPrimaryMenu, g_hSecondaryMenu, g_hMenu;
new g_iMaxPlayers, g_iBarrier, g_iMsgSayText, g_pBuildTime;
new g_iEntity, g_iSeconds, g_iMinutes, g_HudSync, g_HudSync2;
new g_iGrabbed[ 33 ], g_szViewModel[ 33 ][ 32 ];
new bool:g_bGodmode, g_bCanGrab, g_bWeapon[ 33 ];
new Float:g_flGrabLength[ 33 ], Float:g_vGrabOffset[ 33 ][ 3 ], Float:g_fLastMoveTime[ 33 ], bool:g_bJustConnected[ 33 ];
new bool:g_bRenderSaved, g_iRender;

new CSW_MAXAMMO[ 33 ]= { -2, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100, -1, -1 };

IsPrimaryWeapon( iWeaponID ) { return ( ( 1 << iWeaponID ) & PRIMARY_WEAPONS_BIT ); }

new const g_szWeaponClassnames[ ][ ] = {
	"", // NULL
	"weapon_p228",
	"", // SHIELD
	"weapon_scout",
	"", // HEGRENADE
	"weapon_xm1014",
	"", // C4
	"weapon_mac10",
	"weapon_aug",
	"", // SMOKEGRENADE
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"",
	"", // FLASHBANG
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"", // KNIFE
	"weapon_p90"
};

enum AmmoTypes {
	AMMO_CLIP,
	AMMO_BACKPACK
};

new const g_iWeaponMaxAmmo[ sizeof( g_szWeaponClassnames ) ][ AmmoTypes ] = {
	{ 0, 0 }, // NULL
	{ 13, 52 },
	{ 0, 0 }, // SHIELD
	{ 10, 90 },
	{ 0, 1 }, // HEGRENADE
	{ 7, 32 },
	{ 0, 0 }, // C4
	{ 30, 100 },
	{ 30, 90 },
	{ 0, 1 }, // SMOKEGRENADE
	{ 30, 120 },
	{ 20, 100 },
	{ 25, 100 },
	{ 30, 90 },
	{ 35, 90 },
	{ 25, 90 },
	{ 12, 100 },
	{ 20, 120 },
	{ 10, 30 },
	{ 30, 120 },
	{ 100, 200 },
	{ 8, 32 },
	{ 30, 90 },
	{ 30, 120 },
	{ 20, 90 },
	{ 0, 2 }, // FLASHBANG
	{ 7, 35 },
	{ 30, 90 },
	{ 30, 90 },
	{ 0, 0 }, // KNIFE
	{ 50, 100 }
};

new const Float:g_flMoves[ ][ 3 ] = { // Credits to Ramono
	{ 0.0, 0.0, 1.0 }, { 0.0, 0.0, -1.0 }, { 0.0, 1.0, 0.0 }, { 0.0, -1.0, 0.0 }, { 1.0, 0.0, 0.0 }, {-1.0, 0.0, 0.0 }, {-1.0, 1.0, 1.0 }, { 1.0, 1.0, 1.0 }, { 1.0, -1.0, 1.0 }, { 1.0, 1.0, -1.0 }, {-1.0, -1.0, 1.0 }, { 1.0, -1.0, -1.0 }, {-1.0, 1.0, -1.0 }, {-1.0, -1.0, -1.0 },
	{ 0.0, 0.0, 2.0 }, { 0.0, 0.0, -2.0 }, { 0.0, 2.0, 0.0 }, { 0.0, -2.0, 0.0 }, { 2.0, 0.0, 0.0 }, {-2.0, 0.0, 0.0 }, {-2.0, 2.0, 2.0 }, { 2.0, 2.0, 2.0 }, { 2.0, -2.0, 2.0 }, { 2.0, 2.0, -2.0 }, {-2.0, -2.0, 2.0 }, { 2.0, -2.0, -2.0 }, {-2.0, 2.0, -2.0 }, {-2.0, -2.0, -2.0 },
	{ 0.0, 0.0, 3.0 }, { 0.0, 0.0, -3.0 }, { 0.0, 3.0, 0.0 }, { 0.0, -3.0, 0.0 }, { 3.0, 0.0, 0.0 }, {-3.0, 0.0, 0.0 }, {-3.0, 3.0, 3.0 }, { 3.0, 3.0, 3.0 }, { 3.0, -3.0, 3.0 }, { 3.0, 3.0, -3.0 }, {-3.0, -3.0, 3.0 }, { 3.0, -3.0, -3.0 }, {-3.0, 3.0, -3.0 }, {-3.0, -3.0, -3.0 },
	{ 0.0, 0.0, 4.0 }, { 0.0, 0.0, -4.0 }, { 0.0, 4.0, 0.0 }, { 0.0, -4.0, 0.0 }, { 4.0, 0.0, 0.0 }, {-4.0, 0.0, 0.0 }, {-4.0, 4.0, 4.0 }, { 4.0, 4.0, 4.0 }, { 4.0, -4.0, 4.0 }, { 4.0, 4.0, -4.0 }, {-4.0, -4.0, 4.0 }, { 4.0, -4.0, -4.0 }, {-4.0, 4.0, -4.0 }, {-4.0, -4.0, -4.0 },
	{ 0.0, 0.0, 5.0 }, { 0.0, 0.0, -5.0 }, { 0.0, 5.0, 0.0 }, { 0.0, -5.0, 0.0 }, { 5.0, 0.0, 0.0 }, {-5.0, 0.0, 0.0 }, {-5.0, 5.0, 5.0 }, { 5.0, 5.0, 5.0 }, { 5.0, -5.0, 5.0 }, { 5.0, 5.0, -5.0 }, {-5.0, -5.0, 5.0 }, { 5.0, -5.0, -5.0 }, {-5.0, 5.0, -5.0 }, {-5.0, -5.0, -5.0 }
};

public plugin_init( ) {
	register_plugin( "Base Builder", "1.0", "xPaw" );
	
	register_clcmd( "jointeam", "CmdBlock" );
	register_clcmd( "say /gun", "CmdWeapons" );
	register_clcmd( "say /guns", "CmdWeapons" );
	register_clcmd( "say /stuck", "CmdStuck" );
	register_clcmd( "+grab", "CmdGrabStart" );
	register_clcmd( "-grab", "CmdGrabStop" ); 
	register_clcmd( "say /respawn", "CmdRespawn" );
	register_clcmd( "say_team /respawn", "CmdRespawn" );
	register_clcmd( "say /rules", "ClCmd_Rules", _, "Block Builder Rules" );
	register_clcmd( "say_team /rules", "ClCmd_Rules", _, "Block Builder Rules" );
	register_clcmd( "say /bbrules", "ClCmd_Rules", _, "Block Builder Rules" );
	register_clcmd( "say_team /bbrules", "ClCmd_Rules", _, "Block Builder Rules" );
	register_clcmd( "say /help", "ClCmd_Rules", _, "Block Builder Rules" );
	register_clcmd( "say_team /help", "ClCmd_Rules", _, "Block Builder Rules" );
	
	register_event( "CurWeapon", "EventCurWeaponModelView", "be", "1!0" );
	register_event( "CurWeapon", "EventCurWeaponInfinitAmmo", "be", "1=1" );
	register_event( "DeathMsg", "EventDeathMsg", "a" );
	register_event( "TextMsg", "EventTextMsg", "a", "2&#CTs_Win", "2&#Terrorists_Win" );
	register_event( "TeamInfo", "EventTeamInfo", "a" );
	register_event( "ResetHUD", "EventResetHUD", "b" );
	
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	register_logevent( "EventNewRound", 2, "1=Round_Start" );
	
	register_forward( FM_ClientKill, "FwdClientKill" );
	register_forward( FM_CmdStart, "FwdCmdStart" );
	register_forward( FM_GetGameDescription, "FwdGameDisc" );
	register_think( "env_status", "FwdStatus" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamSpawnPlayerPost", 1 );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerDamagePre" );
	RegisterHam( Ham_Touch, "armoury_entity", "FwdHamPlayerPickupPre" );
	RegisterHam( Ham_Touch, "weaponbox", "FwdHamPlayerPickupPre" );
	
	g_iMaxPlayers = get_maxplayers( );
	g_iMsgSayText = get_user_msgid( "SayText" );
	g_HudSync	 = CreateHudSyncObj( );
	g_HudSync2	= CreateHudSyncObj( );
	g_iEntity	 = create_entity( "info_target" );
	
	entity_set_string( g_iEntity, EV_SZ_classname, "env_status" );	
	
	// All Map Cvars Figured out	
	g_pBuildTime = register_cvar( "blockmaker_buildtime", "150.0" );
	
	g_hPrimaryMenu   = menu_create( "Primary Weapons", "MenuPrimary" );
	g_hSecondaryMenu = menu_create( "Secondary Weapons", "MenuSecondary" );
	g_hMenu		  = menu_create( "\r mY.RuN\d Terms of Agreement", "HandleTermsMenu" );
	
	new szNum[ 3 ], szWeapon[ 13 ], i;
	for( i = 0; i < sizeof( g_szWeaponClassnames ); i++ ) {
		if( !g_szWeaponClassnames[ i ][ 0 ] ) continue;
		copy( szWeapon, 12, g_szWeaponClassnames[ i ][ 7 ] );
		
		num_to_str( i, szNum, 2 );
		
		menu_additem( IsPrimaryWeapon( i ) ? g_hPrimaryMenu : g_hSecondaryMenu, szWeapon, szNum );
	}
	
	menu_additem( g_hMenu, "\wAgree", "1" );
	menu_additem( g_hMenu, "\wDecline^n", "2" );
	menu_additem( g_hMenu, "\wShow Rules", "3" );

	menu_setprop( g_hMenu, MPROP_EXIT, MEXIT_NEVER );
}

public CmdBlock( )
	return PLUGIN_HANDLED;

public client_putinserver( id )
	g_bJustConnected[ id ] = true;

public plugin_cfg( ) {
	g_iBarrier = find_ent_by_tname( -1, "bb_barrier" );
	
	if( !g_iBarrier )
		log_amx( "NO BARRIER FOR THIS MAP!" );
}

public plugin_precache( ) {
	new iEnt = create_entity( "info_map_parameters" );
	DispatchKeyValue( iEnt, "buying", "3" );
	DispatchSpawn( iEnt );
	
	precache_model( g_szZombieHand );
}

public FwdGameDisc( ) { 
	forward_return( FMV_STRING, g_szGamename );
	
	return FMRES_SUPERCEDE
}

public client_disconnect( id ) {
	g_bJustConnected[ id ] = false;
	StopGrab( id, false );
	remove_task( id );
}

public EventNewRound( ) {
	NewRound_Info( );
	UnGrabAll( );
	
	if( !g_bRenderSaved ) {
		g_bRenderSaved = true;
		g_iRender = pev( g_iBarrier, pev_rendermode );
	}
	
	set_pev( g_iBarrier, pev_solid, SOLID_BSP );
	set_pev( g_iBarrier, pev_rendermode, g_iRender );

	arrayset( g_bWeapon, false, 33 );
	
	g_bGodmode = true;
	
	g_iMinutes = get_pcvar_num( g_pBuildTime ) / 60;
	g_iSeconds = get_pcvar_num( g_pBuildTime ) - 60 * g_iMinutes - 3;
	entity_set_float( g_iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	
	new iEntity = FM_NULLENT;
	while( ( iEntity = find_ent_by_tname( iEntity, "bb_block" ) ) > 0 )
		engfunc( EngFunc_SetOrigin, iEntity, Float:{ 0.0, 0.0, 0.0 } );
}

public EventTeamInfo( ) {
	new id = read_data( 1 );

	if( is_user_connected( id ) && !task_exists( id ) && !is_user_alive( id ) ) {
		switch( cs_get_user_team( id ) ) {
			case CS_TEAM_T: set_task( 1.0, "CmdRespawnPlayer", id );
			case CS_TEAM_CT: {
				if( g_bCanGrab )
					set_task( 1.0, "CmdRespawnPlayer", id );
			}
		}	
	}
}

public NewRound_Info( ) {
	set_hudmessage( 128, 128, 128, -1.0, 0.5, 0, 0.0, 5.0, 0.4, 0.4, 3 );
	show_hudmessage( 0, "Players have %i:%i minutes to build!", g_iMinutes, g_iSeconds );

	g_bCanGrab = true;
	set_task( get_pcvar_float( g_pBuildTime ), "NewRound_GoGo", TASK );
}

public NewRound_GoGo( ) {
	set_hudmessage( 128, 128, 128, -1.0, 0.5, 0, 0.0, 5.0, 0.4, 0.4, 3 );
	show_hudmessage( 0, "Time is up!" );
	
	UnGrabAll( true );
	g_bGodmode = false;
	g_bCanGrab = false;

	set_pev( g_iBarrier, pev_solid, SOLID_NOT );
	set_pev( g_iBarrier, pev_rendermode, kRenderTransColor );
}

public EventResetHUD( const id ) {
	set_pdata_int( id, m_iClientHideHUD, 0 );
	
	switch( cs_get_user_team( id ) ) {
		case CS_TEAM_CT: set_pdata_int( id, m_iHideHUD, ( 1<<5 ) );
		case CS_TEAM_T: set_pdata_int( id, m_iHideHUD, ( 1<<0 ) | ( 1<<3 ) | ( 1<<5 ) );
	}
}

public EventDeathMsg( ) {
	static iVictim; iVictim = read_data( 2 );
	StopGrab( iVictim, false );
	
	if( cs_get_user_team( iVictim ) == CS_TEAM_T ) {
		client_print( iVictim, print_center, "You will respawn in 5 seconds." );
		set_task( 5.0, "CmdRespawn", iVictim );
	}
}

public FwdHamSpawnPlayerPost( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	if( g_bJustConnected[ id ] ) {
		g_bJustConnected[ id ] = false;
		
		set_task( 1.0, "Task_ShowTermsMenu", id );
	}
	
	StripPlayerWeapons( id );
	
	set_pdata_int( id, 116, 0 ); // primary weapon bug fix ( ConnorMcLeod )
		
	if( cs_get_user_team( id ) == CS_TEAM_T )
		set_user_health( id, 2500 );		
}

public FwdHamPlayerDamagePre( const id, iInflictor, const iAttacker, Float:flDamage, iDamageBits )
	return g_bGodmode ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamPlayerPickupPre( const iEntity, const id )
	return ( IsPlayer( id ) && cs_get_user_team( id ) == CS_TEAM_T )
		? HAM_SUPERCEDE : HAM_IGNORED;
	
public CmdRespawnPlayer( const id )
	if( !is_user_alive( id ) )
		ExecuteHamB( Ham_CS_RoundRespawn, id );

public FwdClientKill( const id ) {
	if( !is_user_alive(id) )
		return FMRES_IGNORED;
	
	client_print( id, print_center, "You may not kill yourself." );
	client_print( id, print_console, "You may not kill yourself." );
		
	return FMRES_SUPERCEDE;
}

public FwdStatus( iEntity ) {
	static id;
	for ( id = 1; id <= g_iMaxPlayers; id++ ) {
		if( !is_user_alive( id ) ) continue;
		
		if( g_bGodmode ) {
			set_hudmessage( 60, 60, 60, -1.0, 0.00, 0, 0.0, 1.1, 0.0, 0.0, 4 );
			ShowSyncHudMsg( id, g_HudSync, "[ Building Time: %i Min | %i Sec ]", g_iMinutes, g_iSeconds );
		}
		
		set_hudmessage( 60, 60, 60, 0.01, 0.93, 0, 6.0, 1.0 );
		ShowSyncHudMsg( id, g_HudSync2, "[ Health: %i ]", get_user_health( id ) );
	}
	
	if( g_iSeconds == 0 ) {
		g_iSeconds = 60;
		g_iMinutes--;
	} else g_iSeconds--;
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime() + 1.0 );
}

public CmdStuck( const id ) {
	if( !is_user_alive( id ) ) {
		GreenPrint( id, "^x04[BB]^x01 The stuck command is not for dead people!" );
		return;
	}
	else if( !g_bCanGrab ) {
		GreenPrint( id, "^x04[BB]^x01 The stuck command is not avaible when the time is up!" );
		return;
	}
	if( !CheckStuck( id ) )
		GreenPrint( id, "^x04[BB]^x01 You aren't stuck!" );
}

public CmdGrabStart( const id ) {
	if( !is_user_alive( id ) ) {
		GreenPrint( id, "^x04[BB]^x01 You can't grab while you're dead!" );
		return PLUGIN_HANDLED;
	}
	
	if( !IsUserAdmin( id ) ) {
		if( !g_bCanGrab ) {
			GreenPrint( id, "^x04[BB]^x01 You can't grab after the building period!" );
			return PLUGIN_HANDLED;
		}
		else if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			GreenPrint( id, "^x04[BB]^x01 Zombies can't grab!" );
			return PLUGIN_HANDLED;
		}
	}
	
	new iEntity, iBody, szTn[ 10 ];
	g_flGrabLength[ id ] = get_user_aiming( id, iEntity, iBody );
	
	if( IsPlayer( iEntity ) || !is_valid_ent( iEntity ) )
		return PLUGIN_HANDLED;
	
	entity_get_string( iEntity, EV_SZ_targetname, szTn, 9 );
	
	if( !equal( szTn, "bb_block" ) )
		return PLUGIN_HANDLED;
	
	if( is_user_alive( entity_get_int( iEntity, EV_INT_iuser4 ) ) ) {
		GreenPrint( id, "^x04[BB]^x01 Someone is already grabbing that block!" );
		
		return PLUGIN_HANDLED;
	}
	
	entity_set_int( iEntity, EV_INT_iuser4, id );
	
	entity_get_string( id, EV_SZ_viewmodel, g_szViewModel[ id ], 31 );
	entity_set_string( id, EV_SZ_viewmodel, "" );
	
	new Float:vOrigin[ 3 ], iAiming[ 3 ];
	get_user_origin( id, iAiming, 3 );
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	
	g_iGrabbed[ id ]		 = iEntity;
	g_vGrabOffset[ id ][ 0 ] = vOrigin[ 0 ] - iAiming[ 0 ];
	g_vGrabOffset[ id ][ 1 ] = vOrigin[ 1 ] - iAiming[ 1 ];
	g_vGrabOffset[ id ][ 2 ] = vOrigin[ 2 ] - iAiming[ 2 ];
	
	entity_set_int( iEntity, EV_INT_rendermode, kRenderTransColor );
	entity_set_float( iEntity, EV_FL_renderamt, 100.0 );
	entity_set_vector( iEntity, EV_VEC_rendercolor, Float:{ 153.0, 0.0, 204.0 } );
	
	return PLUGIN_HANDLED;
}

public CmdGrabStop( const id ) {
	StopGrab( id, true );

	return PLUGIN_HANDLED;
}
	
StopGrab( const id, bool:bConnected ) {
	if( !g_iGrabbed[ id ] )
		return PLUGIN_HANDLED;
		
	if( bConnected )
		entity_set_string( id, EV_SZ_viewmodel, g_szViewModel[ id ] );
		
	entity_set_int( g_iGrabbed[ id ], EV_INT_iuser4, 0 );
	entity_set_int( g_iGrabbed[ id ], EV_INT_rendermode, kRenderNormal );
	entity_set_float( g_iGrabbed[ id ], EV_FL_renderamt, 255.0 );
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	set_pev( g_iGrabbed[ id ], pev_message, szName );
	
//  drop_to_floor( g_iGrabbed[ id ] );
	
	g_iGrabbed[ id ] = 0;
	
	return PLUGIN_HANDLED;
}

public EventCurWeaponModelView( const id ) {
	if( g_iGrabbed[ id ] ) {
		entity_get_string( id, EV_SZ_viewmodel, g_szViewModel[ id ], 31 );
		entity_set_string( id, EV_SZ_viewmodel, "" );
	}
	
	if( cs_get_user_team( id ) == CS_TEAM_T
	&& get_user_weapon( id ) == CSW_KNIFE ) {
		entity_set_string( id, EV_SZ_viewmodel, g_szZombieHand ); 
		entity_set_string( id, EV_SZ_weaponmodel, "" );
	}
}

public FwdCmdStart( const id, const iUcHandle, const iSeed ) {
	if( !is_user_alive( id ) ) {
	//	StopGrab( id, true ); // not really needed here?
		
		return;
	}
	
	new iButtons = get_uc( iUcHandle, UC_Buttons );
	
	if( g_iGrabbed[ id ] ) {
		if( !is_valid_ent( g_iGrabbed[ id ] ) ) // Wont happen xD
			StopGrab( id, true );
		else {
			new iButtons = get_uc( iUcHandle, UC_Buttons ), Float:flGameTime = get_gametime( );
		
			if( iButtons & IN_ATTACK ) {
				if( flGameTime - g_fLastMoveTime[ id ] > MOUSE2_MOVE_DURATION ) {
					g_fLastMoveTime[ id ] = flGameTime;
					g_flGrabLength[ id ] += 16.0;
				}
				
				set_uc( iUcHandle, UC_Buttons, iButtons & ~IN_ATTACK );
			}
			else if( iButtons & IN_ATTACK2 ) {
				if( flGameTime - g_fLastMoveTime[ id ] > MOUSE2_MOVE_DURATION && g_flGrabLength[ id ] > 72.0 ) {
					g_fLastMoveTime[ id ] = flGameTime;
					g_flGrabLength[ id ] -= 16.0;
				}
				
				set_uc( iUcHandle, UC_Buttons, iButtons & ~IN_ATTACK2 );
			}
			
			MoveGrabbedEntity( id );
		}
	} else {
		if( iButtons & IN_USE && ~get_user_oldbutton( id ) & IN_USE ) {
			new iEntity, iBody;
			get_user_aiming( id, iEntity, iBody );
			
			if( IsPlayer( iEntity ) || !is_valid_ent( iEntity ) )
				return PLUGIN_HANDLED;
			
			new szTn[ 32 ];
			entity_get_string( iEntity, EV_SZ_targetname, szTn, 9 );
			
			if( !equal( szTn, "bb_block" ) )
				return;
			
			entity_get_string( iEntity, EV_SZ_message, szTn, 31 );
			
			set_hudmessage( 0, 100, 255, 0.02, 0.25, 0, 2.0, 2.0, 0.4, 0.4, 1 );
			show_hudmessage( id, "Block #%i^nLast mover: %s", iEntity, szTn );
		}
	}
}

UnGrabAll( bool:bCheckStuck = false ) {
	new iPlayers[ 32 ], iNum, id;
	get_players( iPlayers, iNum, "ac" );
	
	for( new i; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		StopGrab( id, true );
		
		if( bCheckStuck )
			CheckStuck( id );
	}
}

bool:CheckStuck( const id ) {
	new Float:vOrigin[ 3 ], iFlags = entity_get_int( id, EV_INT_flags );
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	
	if( IsUserStuck( id, vOrigin, iFlags ) ) {
		new Float:vNewOrigin[ 3 ], Float:vMins[ 3 ];
		entity_get_vector( id, EV_VEC_mins, vMins );
		
		for( new i = 0; i < sizeof g_flMoves; i++ ) {
			vNewOrigin[ 0 ] = vOrigin[ 0 ] - vMins[ 0 ] * g_flMoves[ i ][ 0 ];
			vNewOrigin[ 1 ] = vOrigin[ 1 ] - vMins[ 1 ] * g_flMoves[ i ][ 1 ];
			vNewOrigin[ 2 ] = vOrigin[ 2 ] - vMins[ 2 ] * g_flMoves[ i ][ 2 ];
			
			if( !IsUserStuck( id, vNewOrigin, iFlags ) ) {
				entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
				entity_set_int( id, EV_INT_flags, iFlags | FL_DUCKING );
				
				entity_set_size( id, Float:{ -16.0, -16.0, -18.0 }, Float:{ 16.0, 16.0, 18.0 } );
				entity_set_origin( id, vNewOrigin );
				
				GreenPrint( id, "^x04[BB]^x01 You are no longer stuck!" );
				
				return true;
			}
		}
	}
	
	return false;
}

bool:IsUserStuck( const id, const Float:vOrigin[ 3 ], const iFlags )
	return bool:( trace_hull( vOrigin, iFlags & FL_DUCKING ? HULL_HEAD : HULL_HUMAN, id, IGNORE_MONSTERS ) & 2 );

MoveGrabbedEntity( const id, Float:vMoveTo[ 3 ] = { 0.0, 0.0, 0.0 } ) {
	new iOrigin[ 3 ], iAiming[ 3 ], Float:vOrigin[ 3 ], Float:vAiming[ 3 ];
	new Float:vDirection[ 3 ], Float:flLength;
	
	get_user_origin( id, iOrigin, 1 );
	get_user_origin( id, iAiming, 3 );
	IVecFVec( iOrigin, vOrigin );
	IVecFVec( iAiming, vAiming );
	
	vDirection[ 0 ] = vAiming[ 0 ] - vOrigin[ 0 ];
	vDirection[ 1 ] = vAiming[ 1 ] - vOrigin[ 1 ];
	vDirection[ 2 ] = vAiming[ 2 ] - vOrigin[ 2 ];
	
	flLength = get_distance_f( vAiming, vOrigin );
	
	if( flLength <= 0.0 )
		flLength = 1.0;
	
	vMoveTo[ 0 ] = ( vOrigin[ 0 ] + vDirection[ 0 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 0 ];
	vMoveTo[ 1 ] = ( vOrigin[ 1 ] + vDirection[ 1 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 1 ];
	vMoveTo[ 2 ] = ( vOrigin[ 2 ] + vDirection[ 2 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 2 ];
	
	entity_set_origin( g_iGrabbed[ id ], vMoveTo );
}
/*
bool:IsBlockStuck( const iEntity ) {
	new iContent, i;
	new Float:vOrigin[ 3 ], Float:vPoint[ 3 ], Float:vSizeMin[ 3 ], Float:vSizeMax[ 3 ];
	
	entity_get_vector( iEntity, EV_VEC_absmin, vSizeMin );
	entity_get_vector( iEntity, EV_VEC_absmax, vSizeMax );
	
	vOrigin[ 0 ] = ( vSizeMin[ 0 ] + vSizeMax[ 0 ] ) * 0.5;
	vOrigin[ 1 ] = ( vSizeMin[ 1 ] + vSizeMax[ 1 ] ) * 0.5;
	vOrigin[ 2 ] = ( vSizeMin[ 2 ] + vSizeMax[ 2 ] ) * 0.5;
	
	vSizeMin[ 0 ] += 1.0;
	vSizeMin[ 1 ] += 1.0;
	vSizeMin[ 2 ] += 1.0;
	
	vSizeMax[ 0 ] -= 1.0;
	vSizeMax[ 1 ] -= 1.0; 
	vSizeMax[ 2 ] -= 1.0;
	
	for( i = 0; i < 14; ++i ) {
		vPoint = vOrigin;
		
		switch( i ) {
			case 0: {
				vPoint[ 0 ] += vSizeMax[ 0 ];
				vPoint[ 1 ] += vSizeMax[ 1 ];
				vPoint[ 2 ] += vSizeMax[ 2 ];
			}
			case 1: {
				vPoint[ 0 ] += vSizeMin[ 0 ];
				vPoint[ 1 ] += vSizeMax[ 1 ];
				vPoint[ 2 ] += vSizeMax[ 2 ];
			}
			case 2: {
				vPoint[ 0 ] += vSizeMax[ 0 ];
				vPoint[ 1 ] += vSizeMin[ 1 ];
				vPoint[ 2 ] += vSizeMax[ 2 ];
			}
			case 3: {
				vPoint[ 0 ] += vSizeMin[ 0 ];
				vPoint[ 1 ] += vSizeMin[ 1 ];
				vPoint[ 2 ] += vSizeMax[ 2 ];
			}
			case 4: {
				vPoint[ 0 ] += vSizeMax[ 0 ];
				vPoint[ 1 ] += vSizeMax[ 1 ];
				vPoint[ 2 ] += vSizeMin[ 2 ];
			}
			case 5: {
				vPoint[ 0 ] += vSizeMin[ 0 ];
				vPoint[ 1 ] += vSizeMax[ 1 ];
				vPoint[ 2 ] += vSizeMin[ 2 ];
			}
			case 6: {
				vPoint[ 0 ] += vSizeMax[ 0 ];
				vPoint[ 1 ] += vSizeMin[ 1 ];
				vPoint[ 2 ] += vSizeMin[ 2 ];
			}
			case 7: {
				vPoint[ 0 ] += vSizeMin[ 0 ];
				vPoint[ 1 ] += vSizeMin[ 1 ];
				vPoint[ 2 ] += vSizeMin[ 2 ];
			}
			case 8: vPoint[ 0 ] += vSizeMax[ 0 ];
			case 9: vPoint[ 0 ] += vSizeMin[ 0 ];
			case 10: vPoint[ 1 ] += vSizeMax[ 1 ];
			case 11: vPoint[ 1 ] += vSizeMin[ 1 ];
			case 12: vPoint[ 2 ] += vSizeMax[ 2 ];
			case 13: vPoint[ 2 ] += vSizeMin[ 2 ];
		}
		
		iContent = engfunc( EngFunc_PointContents, vPoint );
		if( iContent == CONTENTS_EMPTY || !iContent ) return false;
	}
	
	return true;
}*/

public CmdWeapons( const iPlayer ) {
	if( g_bWeapon[ iPlayer ] ) {
		GreenPrint( iPlayer, "^x04[BB]^x01 You has already gun choosed." );
	
		return;
	}
	
	if( is_user_alive( iPlayer ) && cs_get_user_team( iPlayer ) != CS_TEAM_T )
		menu_display( iPlayer, g_hSecondaryMenu );
}

public MenuPrimary( iPlayer, hMenu, iItem ) {
	if( iItem == MENU_EXIT ) 
		return;
	
	new iAccess, szInfo[ 3 ], hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szInfo, 2, _, _, hCallback );
	
	new iWeaponID = str_to_num( szInfo );
	
	GiveWeapon( iPlayer, iWeaponID );
}

public MenuSecondary( const iPlayer, hMenu, iItem ) {
	if( iItem == MENU_EXIT )
		return;
	
	new iAccess, szInfo[ 3 ], hCallback;
	menu_item_getinfo( hMenu, iItem, iAccess, szInfo, 2, _, _, hCallback );
	
	new iWeaponID = str_to_num( szInfo );
	StripPlayerWeapons( iPlayer )
	GiveWeapon( iPlayer, iWeaponID );
	g_bWeapon[ iPlayer] = true;
	
	menu_display( iPlayer, g_hPrimaryMenu );
}

StripPlayerWeapons( const id ) {
	strip_user_weapons( id );
	
	give_item( id, "weapon_knife" );
}

GiveWeapon( const iPlayer, iWeaponID ) {
	if( is_user_alive( iPlayer ) && cs_get_user_team( iPlayer ) != CS_TEAM_T ) {
		cs_set_weapon_ammo( give_item( iPlayer, g_szWeaponClassnames[ iWeaponID ] ), g_iWeaponMaxAmmo[ iWeaponID ][ AMMO_CLIP ] );
		cs_set_user_bpammo( iPlayer, iWeaponID, g_iWeaponMaxAmmo[ iWeaponID ][ AMMO_BACKPACK ] );
		
		if( cs_get_user_bpammo( iPlayer, iWeaponID ) != CSW_MAXAMMO[ iWeaponID ] )
			cs_set_user_bpammo( iPlayer, iWeaponID, CSW_MAXAMMO[ iWeaponID ] );
	} else
		GreenPrint( iPlayer, "^x04[BB]^x01 You can't have a gun." );
}

public EventCurWeaponInfinitAmmo( const id ) {
	new szWeapon = read_data( 2 );
	if( szWeapon == CSW_C4 || szWeapon == CSW_KNIFE 
	|| szWeapon == CSW_HEGRENADE || szWeapon == CSW_SMOKEGRENADE 
	|| szWeapon == CSW_FLASHBANG )
		return PLUGIN_CONTINUE;
	
	if( cs_get_user_bpammo( id, szWeapon ) != CSW_MAXAMMO[ szWeapon ] )
		cs_set_user_bpammo( id, szWeapon, CSW_MAXAMMO[ szWeapon ] );
	
	return PLUGIN_CONTINUE;
}

public EventTextMsg( ) {
	new iPlayers[ 32 ], iNum, id, i;
	get_players( iPlayers, iNum );
	
	for( i = 0; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		switch( cs_get_user_team( id ) ) {
			case CS_TEAM_T: cs_set_user_team( id, CS_TEAM_CT );
			case CS_TEAM_CT: cs_set_user_team( id, CS_TEAM_T );
		}
	}
}

public ClCmd_Rules( const id )
	show_motd( id, g_szMotdFile, g_szMotdTitle );

public Task_ShowTermsMenu( const id ) {
	if( !is_user_alive( id ) ) {
		g_bJustConnected[ id ] = true;
		
		return;
	}
	
	menu_display( id, g_hMenu, 0 );
}

public HandleTermsMenu( const id, menu, item) {
	if( item == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szKey[ 2 ], iAccess, iCallback;
	menu_item_getinfo( menu, item, iAccess, szKey, 1, _, _, iCallback );
	
	switch( str_to_num( szKey ) ) {
		case 1: GreenPrint( id, "^x04[BB]^x01 Thanks and have fun!" );
		case 2: server_cmd( "kick ^"#%d^" ^"%s^"", get_user_userid( id ), g_szDeclineReason );
		case 3: {
			ClCmd_Rules( id );
			
			Task_ShowTermsMenu( id );
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdRespawn( const id ) {
	if( !is_user_connected( id ) || is_user_alive( id ) )
		return;
	
	switch( cs_get_user_team( id ) ) {
		case CS_TEAM_T: {
			client_print( id, print_center, "You will respawn in 5 seconds." );
			set_task( 5.0, "CmdRespawnPlayer", id );
		}
		case CS_TEAM_CT: {
			if( g_bCanGrab )
				ExecuteHamB( Ham_CS_RoundRespawn, id );
		}
	}
}

stock GreenPrint( const id, const szMsg[ ], any:... ) {
	static szMessage[ 192 ]; vformat( szMessage, 191, szMsg, 3 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
	
	return 1;
}
