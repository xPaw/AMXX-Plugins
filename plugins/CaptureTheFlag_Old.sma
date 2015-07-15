#include < amxmodx >
#include < fun >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

/*
	TODO:
		- Radar dot
		- Player trail for carrying flag players
	
	BUGS:
		- Fix bbox for dropped flags
		- Fix angles for attached flags on players
*/

const TASK = 236273;

new const ctf_flag[ ]    = "ctf_flag";
new const ctf_hp_kit[ ]  = "ctf_hp_kit";
new const ctf_ammobox[ ] = "ctf_ammobox";

new const FLAG_CAPTURED[ ] = "sound/ctf/PVPFlagCaptured.mp3";
new const FLAG_RETURNED[ ] = "sound/ctf/PVPFlagReturned.mp3";
new const FLAG_TAKEN[ ]    = "sound/ctf/PVPFlagTaken.mp3";

new const FLAG_MODELS[ CsTeams ][ ] = {
	"",
	"models/red_flag.mdl",
	"models/blue_flag.mdl",
	""
};

new const FLAG_ICONS[ CsTeams ][ ] = {
	"",
	"sprites/spotlight01.spr",
	"sprites/spotlight01.spr",
	""
};

new g_iScores[ CsTeams ];
new g_iFlags[ CsTeams ];
new g_iFlagsIcons[ CsTeams ];
new g_iFlagsDummy[ CsTeams ];
new g_iFlagHolders[ CsTeams ];
new g_iMsgSayText;

const HUD_HIDE = 1 << 4 | 1 << 5;

const m_iHideHUD          = 361;
const m_iClientHideHUD    = 362;
const m_pClientActiveItem = 374;
const m_iInternalModel    = 126;

public plugin_init( ) {
	register_plugin( "Capture The Flag", "0.1", "xPaw" );
	
	register_event( "ResetHUD", "EventResetHUD", "be" );
	register_event( "HideWeapon", "EventHideWeapon", "be" );
	register_event( "DeathMsg", "EventDeathMsg", "a", "2>0" );
	
	register_touch( "ctf_flag_ground", "player", "FwdGroundFlagTouch" );
	register_touch( ctf_flag, "player", "FwdFlagTouch" );
	register_think( ctf_flag, "FwdFlagThink" );
	
	RegisterHam( Ham_Spawn, "weaponbox", "FwdHamWeaponBoxSpawn", 1 );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
//	RegisterHam( Ham_ObjectCaps, "player", "FwdHamPlayerObjectCaps" );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
	
	set_task( 1.0, "ShowHudScores", TASK );
}

public plugin_precache( ) {
	new iEntity;
	
	for( new CsTeams:i = CS_TEAM_T; i <= CS_TEAM_CT; i++ ) {
		precache_model( FLAG_MODELS[ i ] );
		precache_model( FLAG_ICONS[ i ] );
		
		if( ( iEntity = g_iFlagsDummy[ i ] = create_entity( "info_target" ) ) ) {
			entity_set_string( iEntity, EV_SZ_classname, "ctf_flag_ground" );
			entity_set_model( iEntity, FLAG_MODELS[ i ] );
			entity_set_int( iEntity, EV_INT_team, _:i );
			entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
			entity_set_origin( iEntity, Float:{ 0.0, 0.0, -8000.0 } );
		}
		
		if( ( iEntity = g_iFlagsIcons[ i ] = create_entity( "env_sprite" ) ) ) {
			entity_set_origin( iEntity, Float:{ 0.0, 0.0, -8000.0 } );
			entity_set_string( iEntity, EV_SZ_model, FLAG_ICONS[ i ] );
			entity_set_float( iEntity, EV_FL_scale, 0.6 );
			DispatchSpawn( iEntity );
		}
	}
}

public pfn_keyvalue( iEntity ) {
	new szClassName[ 13 ], szKeyName[ 32 ], szValue[ 128 ];
	copy_keyvalue( szClassName, 12, szKeyName, 31, szValue, 127 );
	
	if( equal( szClassName, ctf_flag ) ) {
		static Float:vOrigin[ 3 ];
		
		switch( szKeyName[ 0 ] ) {
			case 'o': ParseVector( szValue, vOrigin );
			case 't': SpawnFlag( vOrigin, CsTeams:str_to_num( szValue ) );
		}
	}
	else if( equal( szClassName, ctf_ammobox ) ) {
		
	}
	else if( equal( szClassName, ctf_hp_kit ) ) {
		
	}
}

public client_disconnect( id )
	CheckFlag( id );

public EventDeathMsg( )
	CheckFlag( read_data( 2 ) );

public EventResetHUD( const id ) {
	set_pdata_int( id, m_iClientHideHUD, 0 );
	set_pdata_int( id, m_iHideHUD, HUD_HIDE );
}

public EventHideWeapon( const id ) {
	new iFlags = read_data( 1 );

	if( iFlags & HUD_HIDE != HUD_HIDE ) {
		set_pdata_int( id, m_iClientHideHUD, 0 );
		set_pdata_int( id, m_iHideHUD, HUD_HIDE );
	}
	else if( is_user_alive( id ) ) {
		set_pdata_cbase( id, m_pClientActiveItem, FM_NULLENT );
	}
}

CheckFlag( const id ) {
	if( g_iFlagHolders[ CS_TEAM_T ] == id )
		DropFlag( id, CS_TEAM_T );
	else if( g_iFlagHolders[ CS_TEAM_CT ] == id )
		DropFlag( id, CS_TEAM_CT );
}

DropFlag( const id, const CsTeams:iTeam ) {
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	GreenPrint( 0, id, "^4[ CTF ]^3 %s^1 has dropped^3 %s^1 flag!", szName, iTeam == CS_TEAM_T ? "T" : "CT" );
	
	g_iFlagHolders[ iTeam ] = 0;
	
	entity_set_float( g_iFlags[ iTeam ], EV_FL_nextthink, get_gametime( ) + 30.0 ); // 30 seconds delay to return to base.
	
	new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	entity_get_vector( id, EV_VEC_angles, vAngles );
	
	vAngles[ 0 ] = -90.0;
	vAngles[ 2 ] = -90.0;
	
	new iEntity = g_iFlagsDummy[ iTeam ];
	entity_set_edict( iEntity, EV_ENT_aiment, 0 );
	entity_set_vector( iEntity, EV_VEC_angles, vAngles );
	entity_set_origin( iEntity, vOrigin );
	
	drop_to_floor( iEntity );
	
	vOrigin[ 2 ] += 50.0;
	
	entity_set_origin( g_iFlagsIcons[ iTeam ], vOrigin );
	
	ShowHudScores( );
}

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {
		strip_user_weapons( id );
		give_item( id, "weapon_knife" );
		
		switch( get_pdata_int( id, m_iInternalModel, 5 ) ) {
			case CS_T_GUERILLA: { // Sergeant
				give_item( id, "weapon_ak47" );
				give_item( id, "weapon_deagle" );
				cs_set_user_bpammo( id, CSW_AK47, 90 );
				cs_set_user_bpammo( id, CSW_DEAGLE, 35 );
			}
			case CS_CT_GIGN: { // Sergeant
				give_item( id, "weapon_m4a1" );
				give_item( id, "weapon_deagle" );
				cs_set_user_bpammo( id, CSW_M4A1, 90 );
				cs_set_user_bpammo( id, CSW_DEAGLE, 35 );
			}
			case CS_T_ARCTIC: { // Commander
				give_item( id, "weapon_sg552" );
				give_item( id, "weapon_usp" );
				cs_set_user_bpammo( id, CSW_SG552, 90 );
				cs_set_user_bpammo( id, CSW_USP, 100 );
			}
			case CS_CT_SAS: { // Commander
				give_item( id, "weapon_aug" );
				give_item( id, "weapon_usp" );
				cs_set_user_bpammo( id, CSW_AUG, 90 );
				cs_set_user_bpammo( id, CSW_USP, 100 );
			}
			case CS_T_TERROR: { // Private
				give_item( id, "weapon_galil" );
				give_item( id, "weapon_p228" );
				cs_set_user_bpammo( id, CSW_GALIL, 90 );
				cs_set_user_bpammo( id, CSW_P228, 52 );
			}
			case CS_CT_URBAN: { // Private
				give_item( id, "weapon_famas" );
				give_item( id, "weapon_p228" );
				cs_set_user_bpammo( id, CSW_FAMAS, 90 );
				cs_set_user_bpammo( id, CSW_P228, 52 );
			}
			case CS_T_LEET, CS_CT_GSG9: { // Scout
				give_item( id, "weapon_awp" );
				give_item( id, "weapon_usp" );
				cs_set_user_bpammo( id, CSW_AWP, 30 );
				cs_set_user_bpammo( id, CSW_USP, 100 );
			}
		}
	}
}

public FwdHamPlayerObjectCaps( const id ) {
	static Float:flLast, Float:flGameTime; flGameTime = get_gametime( );
	
	if( flLast > flGameTime )
		return;
	
	flLast = flGameTime + 0.5;
	
	if( is_user_alive( id ) && get_user_button( id ) & IN_USE ) {
		new CsTeams:iTeam = cs_get_user_team( id ) == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T; // hax
		
		if( g_iFlagHolders[ iTeam ] == id ) {
			new iTarget, iBody;
			get_user_aiming( id, iTarget, iBody, 64 );
			
			if( is_user_alive( iTarget ) && iTeam == cs_get_user_team( iTarget ) ) {
				g_iFlagHolders[ iTeam ] = iTarget;
				
				entity_set_edict( g_iFlagsDummy[ iTeam ], EV_ENT_aiment, iTarget );
				
				new szName[ 32 ];
				get_user_name( iTarget, szName, 31 );
				GreenPrint( id, id, "^4[ CTF ]^1 You gave flag to^3 %s^1.", szName );
				
				get_user_name( id, szName, 31 );
				GreenPrint( iTarget, iTarget, "^4[ CTF ]^3 %s^1 gave you the flag!", szName );
				
				ShowHudScores( );
			}
		}
	}
}

public FwdHamWeaponBoxSpawn( const iEntity )
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 30.0 ); 

public FwdGroundFlagTouch( const iEntity, const id ) {
	new CsTeams:iTeam = CsTeams:entity_get_int( iEntity, EV_INT_team );
	
	if( g_iFlagHolders[ iTeam ] )
		return;
	
	if( g_iFlagHolders[ iTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T ] == id )
		return;
	
	PlaySound( 0, FLAG_TAKEN );
	
	entity_set_origin( g_iFlagsIcons[ iTeam ], Float:{ 0.0, 0.0, -8000.0 } );
	entity_set_float( g_iFlags[ iTeam ], EV_FL_nextthink, 0.0 );
	
	g_iFlagHolders[ iTeam ] = id;
	
	entity_set_edict( iEntity, EV_ENT_aiment, id );
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	GreenPrint( 0, id, "^4[ CTF ]^3 %s^1 has pickuped^3 %s^1 flag!", szName, iTeam == CS_TEAM_T ? "T" : "CT" );
	
	ShowHudScores( );
}

public FwdFlagThink( const iEntity ) {
	new CsTeams:iTeam = CsTeams:entity_get_int( iEntity, EV_INT_team );
	
	if( g_iFlagHolders[ iTeam ] )
		return;
	
	PlaySound( _:iTeam, FLAG_RETURNED );
	
	GreenPrint( 0, _, "^4[ CTF ]^3 %s^1's flag has been returned to the base!", iTeam == CS_TEAM_T ? "T" : "CT" );
	
	entity_set_int( g_iFlags[ iTeam ], EV_INT_effects, entity_get_int( g_iFlags[ iTeam ], EV_INT_effects ) & ~EF_NODRAW );
	entity_set_origin( g_iFlagsDummy[ iTeam ], Float:{ 0.0, 0.0, -8000.0 } );
	entity_set_origin( g_iFlagsIcons[ iTeam ], Float:{ 0.0, 0.0, -8000.0 } );
	
	ShowHudScores( );
}

public FwdFlagTouch( const iEntity, const id ) {
	new iTempEnt, CsTeams:iTeam = CsTeams:entity_get_int( iEntity, EV_INT_team );
	
	if( iTeam == cs_get_user_team( id ) ) {
		if( !g_iFlagHolders[ iTeam ] ) {
			new CsTeams:iTeamEnemy = iTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T;
			
			if( g_iFlagHolders[ iTeamEnemy ] == id ) {
				++g_iScores[ iTeam ];
				
				new szName[ 32 ];
				get_user_name( id, szName, 31 );
				
				PlaySound( 0, FLAG_CAPTURED );
				
				GreenPrint( 0, id, "^4[ CTF ]^3 %s^1 has captured^3 %s^1 flag!", szName, iTeam == CS_TEAM_T ? "CT" : "T" );
				
				g_iFlagHolders[ iTeamEnemy ] = 0;
				
				iTempEnt = g_iFlagsDummy[ iTeamEnemy ];
				
				entity_set_edict( iTempEnt, EV_ENT_aiment, 0 );
				entity_set_origin( iTempEnt, Float:{ 0.0, 0.0, -8000.0 } );
				
				iTempEnt = g_iFlags[ iTeamEnemy ];
				
				entity_set_int( iTempEnt, EV_INT_effects, entity_get_int( iTempEnt, EV_INT_effects ) & ~EF_NODRAW );
				
				ShowHudScores( );
			}
		}
		else if( g_iFlagHolders[ iTeam ] == id ) {
			new szName[ 32 ];
			get_user_name( id, szName, 31 );
			
			PlaySound( _:iTeam, FLAG_RETURNED );
			
			GreenPrint( 0, id, "^4[ CTF ]^3 %s^1 has returned^3 %s^1 flag to the base!", szName, iTeam == CS_TEAM_T ? "T" : "CT" );
			
			g_iFlagHolders[ iTeam ] = 0;
			
			iTempEnt = g_iFlagsDummy[ iTeam ];
			
			entity_set_edict( iTempEnt, EV_ENT_aiment, 0 );
			entity_set_origin( iTempEnt, Float:{ 0.0, 0.0, -8000.0 } );
			
			iTempEnt = g_iFlags[ iTeam ];
			
			entity_set_int( iTempEnt, EV_INT_effects, entity_get_int( iTempEnt, EV_INT_effects ) & ~EF_NODRAW );
			
			ShowHudScores( );
		}
	}
	else if( !g_iFlagHolders[ iTeam ] && !( entity_get_int( iEntity, EV_INT_effects ) & EF_NODRAW ) ) {
		if( g_iFlagHolders[ iTeam == CS_TEAM_T ? CS_TEAM_CT : CS_TEAM_T ] == id )
			return;
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		PlaySound( 0, FLAG_TAKEN );
		
		GreenPrint( 0, id, "^4[ CTF ]^3 %s^1 has taken^3 %s^1 flag!", szName, iTeam == CS_TEAM_T ? "T" : "CT" );
		
		g_iFlagHolders[ iTeam ] = id;
		
		entity_set_edict( g_iFlagsDummy[ iTeam ], EV_ENT_aiment, id );
		
		iTempEnt = g_iFlags[ iTeam ];
		
		entity_set_int( iTempEnt, EV_INT_effects, entity_get_int( iTempEnt, EV_INT_effects ) | EF_NODRAW );
		
		ShowHudScores( );
	}
}

ParseVector( const szInput[ ], Float:vVector[ 3 ] ) {
	new szInput2[ 3 ][ 6 ];
	
	parse( szInput, szInput2[ 0 ], 6, szInput2[ 1 ], 6, szInput2[ 2 ], 6 );
	
	vVector[ 0 ] = str_to_float( szInput2[ 0 ] );
	vVector[ 1 ] = str_to_float( szInput2[ 1 ] );
	vVector[ 2 ] = str_to_float( szInput2[ 2 ] );
	
	return 1;
}

SpawnFlag( Float:vOrigin[ 3 ], const CsTeams:iTeam ) {
	if( !( CS_TEAM_T <= iTeam <= CS_TEAM_CT ) ) {
		log_amx( "[ CTF ] Wrong team parsed in ctf_flag entity, ignoring." );
		
		return -1;
	}
	
	new iEntity = create_entity( "info_target" );
	
	if( !iEntity )
		return -1;
	
	g_iFlags[ iTeam ] = iEntity;
	vOrigin[ 2 ] += 45.0;
	
	entity_set_size( iEntity, Float:{ -2.0, -2.0, 0.0 }, Float:{ 2.0, 2.0, 32.0 } );
	entity_set_vector( iEntity, EV_VEC_avelocity, Float:{ 0.0, 80.0, 0.0 } );
	entity_set_string( iEntity, EV_SZ_classname, ctf_flag );
	entity_set_origin( iEntity, vOrigin );
	
	entity_set_model( iEntity, FLAG_MODELS[ iTeam ] );
	
	entity_set_int( iEntity, EV_INT_team, _:iTeam );
	entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_FLY );
	
	return iEntity;
}

GreenPrint( const id, iSender = 1, const Message[ ], any:... ) {
	new szMessage[ 191 ];
	vformat( szMessage, 190, Message, 4 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
}

PlaySound( iTeam = 0, const szSound[ ] ) {
	if( iTeam == 0 ) {
		client_cmd( 0, "mp3 play ^"%s^"", szSound );
	} else {
		new iPlayers[ 32 ], iNum, id;
		get_players( iPlayers, iNum, "ac" );
		
		for( new i; i < iNum; i++ ) {
			id = iPlayers[ i ];
			
			if( cs_get_user_team( id ) == CsTeams:iTeam )
				client_cmd( id, "mp3 play ^"%s^"", szSound );
		}
	}
}

public ShowHudScores( ) {
	remove_task( TASK );
	set_task( 1.0, "ShowHudScores", TASK );
	
	new szFlagLocation[ 32 ];
	
	for( new CsTeams:i = CS_TEAM_T; i <= CS_TEAM_CT; i++ ) {
		if( !g_iFlagHolders[ i ] )
			szFlagLocation = ( entity_get_float( g_iFlags[ i ], EV_FL_nextthink ) > 0.0 ) ? "On Ground" : "Base";
		else
			get_user_name( g_iFlagHolders[ i ], szFlagLocation, 31 );
		
		set_hudmessage( i == CS_TEAM_T ? 255 : 0, 0, i == CS_TEAM_CT ? 255 : 0, -1.0, 0.03, 0, 1.1, 1.1, 0.0, 0.0, i == CS_TEAM_CT ? 3 : 2 );
		show_hudmessage( 0, "%s[ %i ] %s Flag: %s", i == CS_TEAM_T ? "" : "_^n", g_iScores[ i ], i == CS_TEAM_T ? "T" : "CT", szFlagLocation );
	}
}