#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >

#define PevTrapOwner  pev_iuser3
#define PevBeamIndent pev_iuser2

const GIB_ALWAYS     = 2;
const m_iStartEntity = 35;
const m_toggle_state = 41;
const m_cTargets     = 73;
const m_LastHitGroup = 75;
const m_iTargetName  = 76;
const m_iTrain       = 350;

new Float:g_flLastTouch[ 33 ];
new Array:g_aEntities, g_iMaxplayers;
new g_iIgnore[ 2 ], g_iTouchOwner[ 33 ];

public plugin_init( ) {
	register_plugin( "Deathrun Real Killer", "Private", "xPaw" );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	
	new const szDropEnts[ ][ ] = { // Ents wich should be registered ( touch )
		"func_door",
		"func_train",
		"func_button",
		"func_rotating",
		"func_breakable",
		"func_tracktrain",
		"func_door_rotating",
		
		"trigger_push"
	};
	
	for( g_iMaxplayers = 0; g_iMaxplayers < sizeof szDropEnts; g_iMaxplayers++ )
		RegisterHam( Ham_Touch, szDropEnts[ g_iMaxplayers ], "FwdHamTouchPlayer", 1 );
	
	RegisterHam( Ham_Think,   "func_breakable",   "FwdHamThinkBreakable" );
	RegisterHam( Ham_Think,   "func_door",        "FwdHamThinkDoor" );
	RegisterHam( Ham_Killed,  "player",           "FwdHamPlayerKilled" );
	
	RegisterHam( Ham_Use,     "func_rot_button",  "FwdHamUse_Button" );
	RegisterHam( Ham_Use,     "func_button",      "FwdHamUse_Button" );
	RegisterHam( Ham_Use,     "button_target",    "FwdHamUse_Button" );
	RegisterHam( Ham_Use,     "func_vehicle",     "FwdHamUse_Vehicle" );
	
	g_aEntities   = ArrayCreate( );
	g_iMaxplayers = get_maxplayers( );
	
	if( g_aEntities == Invalid_Array )
		set_fail_state( "Failed to create array. Stupid AMXX." );
	
	EnvBeamInit( );
	
	// Some fixes
	new szMap[ 32 ];
	get_mapname( szMap, 31 );
	
	if( equali( szMap, "deathrun_aztecrun" ) )
		g_iIgnore[ 0 ] = find_ent_by_model( -1, "func_button", "*67" );
	else if( equali( szMap, "deathrun_pyramid" ) ) {
		g_iIgnore[ 0 ] = find_ent_by_model( -1, "func_button", "*36" );
		g_iIgnore[ 1 ] = find_ent_by_model( -1, "func_button", "*37" );
	}
	else if( equali( szMap, "deathrun_aquariums" ) )
		g_iIgnore[ 0 ] = find_ent_by_model( -1, "func_button", "*90" ); // CT Road
	else if( equali( szMap, "deathrun_agony" ) )
		g_iIgnore[ 0 ] = find_ent_by_model( -1, "func_button", "*74" ); // CT Road
	else if( equali( szMap, "deathrun_nightmare" ) )
		g_iIgnore[ 0 ] = find_ent_by_model( -1, "func_button", "*46" ); // Wheel
	else if( equali( szMap, "deathrun_pycho" ) )
		entity_set_string( find_ent_by_model( -1, "func_button", "*10" ), EV_SZ_targetname, "" ); // Lame-mapping
}

public plugin_end( )
	ArrayDestroy( g_aEntities );

public client_disconnect( id ) {
	g_iTouchOwner[ id ] = 0;
	g_flLastTouch[ id ] = 0.0;
}

public EventNewRound( ) {
	arrayset( g_iTouchOwner, 0, 33 );
	arrayset( _:g_flLastTouch, _:0.0, 33 );
	
	new iArraySize = ArraySize( g_aEntities );
	
	if( iArraySize > 0 ) {
		new iEntity;
		
		for( new i = 0; i < iArraySize; i++ ) {
			iEntity = ArrayGetCell( g_aEntities, i );
			
			if( pev_valid( iEntity ) )
				set_pev( iEntity, PevTrapOwner, 0 );
		}
		
		ArrayClear( g_aEntities );
	}
}

public FwdHamUse_Vehicle( const iEntity, const id, const iActivator, const iUseType, const Float:flValue ) {
	if( iUseType != 2 || flValue != 1.0 || !is_user_alive( id ) )
		return HAM_IGNORED;
	
	set_pev( iEntity, PevTrapOwner, id );
	ArrayPushCell( g_aEntities, iEntity );
	
	return HAM_IGNORED;
}

public FwdHamUse_Button( const iEntity, const id, const iActivator, const iUseType, const Float:flValue ) {
	if( iUseType != 2 || flValue != 1.0 || iEntity == g_iIgnore[ 0 ] || iEntity == g_iIgnore[ 1 ] )
		return HAM_IGNORED;
	
	if( !is_user_alive( id ) || get_pdata_int( iEntity, m_toggle_state, 4 ) != 1 )
		return HAM_IGNORED;
	
	new szTarget[ 40 ];
	entity_get_string( iEntity, EV_SZ_target, szTarget, 39 );
	
	if( szTarget[ 0 ] ) {
		new iEntity, szClassname[ 14 ];
		
		while( ( iEntity = find_ent_by_tname( iEntity, szTarget ) ) ) {
			entity_get_string( iEntity, EV_SZ_classname, szClassname, 13 );
			
			if( equal( szClassname, "multi_manager" ) )
				MultiManagerStuff( iEntity, id );
			else
				ConfigureEntity( iEntity, id );
		}
	}
	
	return HAM_IGNORED;
}

public FwdHamThinkDoor( const iEntity ) {
	new iOwner = pev( iEntity, PevTrapOwner );
	
	if( iOwner == 0 )
		return HAM_IGNORED;
	
	new iPlayers[ 32 ], iNum, id;
	get_players( iPlayers, iNum, "a" );
	
	for( new i; i < iNum; i++ ) {
		id = iPlayers[ i ];
		
		if( IsColliding( iEntity, id ) )
			SetOwner( id, iOwner );
	}
	
	return HAM_IGNORED;
}

public FwdHamThinkBreakable( const iEntity ) {
	if( entity_get_int( iEntity, EV_INT_solid ) == SOLID_NOT ) {
		new iOwner = pev( iEntity, PevTrapOwner );
		
		if( iOwner == 0 )
			return HAM_IGNORED;
		
		new iPlayers[ 32 ], iNum, id;
		get_players( iPlayers, iNum, "a" );
		
		for( new i; i < iNum; i++ ) {
			id = iPlayers[ i ];
			
			if( IsPlayerAboveEntity( id, iEntity ) )
				SetOwner( id, iOwner );
		}
	}
	
	return HAM_IGNORED;
}

public FwdHamTouchPlayer( const iEntity, const id ) {
	if( is_user_alive( id ) ) {
		new iOwner;
		
		if( ( iOwner = pev( iEntity, PevTrapOwner ) ) > 0 )
			SetOwner( id, iOwner );
	}
}

public FwdHamPlayerKilled( const id, const iAttacker, const iShouldGib ) {
	if( 1 <= iAttacker <= g_iMaxplayers )
		return HAM_IGNORED;
	
	if( iAttacker == 0 || pev_valid( iAttacker ) ) {
		static iOwner; iOwner = pev( iAttacker, PevTrapOwner );
		
		if( !iOwner && g_iTouchOwner[ id ] > 0 ) {
			new szClassname[ 32 ];
			entity_get_string( iAttacker, EV_SZ_classname, szClassname, 31 );
			
			if( iAttacker == 0 || equal( szClassname, "func_water" ) || equal( szClassname, "trigger_hurt" ) ) {
				iOwner = g_iTouchOwner[ id ];
				
				if( ( get_gametime( ) - g_flLastTouch[ id ] ) > 8.0 ) {
					g_iTouchOwner[ id ] = 0;
					
					return HAM_IGNORED;
				}
			}
		}
		
		if( id == iOwner || !is_user_connected( iOwner ) )
			return HAM_IGNORED;
		
		// get_pdata_int( iOwner, m_iTrain ) < Check for func_vehicle
		
		SetHamParamEntity( 2, iOwner );
		SetHamParamInteger( 3, GIB_ALWAYS );
		
	//	set_pdata_int( id, m_LastHitGroup, HIT_HEAD, 5 );
	}
	
	return HAM_IGNORED;
}

// Other stuff
public SetOwner( const id, const iOwner ) {
	g_iTouchOwner[ id ] = iOwner;
	g_flLastTouch[ id ] = get_gametime( );
}

ConfigureEntity( const iTarget, const id ) {
	set_pev( iTarget, PevTrapOwner, id );
	
	if( !EnvBeamCheck( iTarget, id ) )
		TargetCheck( iTarget, id );
	
	ArrayPushCell( g_aEntities, iTarget );
}

TargetCheck( const iEntity, const id ) {
	new szTarget[ 32 ];
	entity_get_string( iEntity, EV_SZ_target, szTarget, 31 );
	
	if( !szTarget[ 0 ] )
		return PLUGIN_CONTINUE;
	
	new szTargetname[ 32 ];
	entity_get_string( iEntity, EV_SZ_targetname, szTargetname, 31 );
	
	if( !szTargetname[ 0 ] || equal( szTarget, szTargetname ) )
		return PLUGIN_CONTINUE;
	
	static const PathTrack[ ]  = "path_track";
	static const PathCorner[ ] = "path_corner";
	
	new iEnt2, szClass[ 32 ];
	
	while( ( iEnt2 = find_ent_by_tname( iEnt2, szTarget ) ) ) {
		if( iEntity == iEnt2 )
			continue;
		
		entity_get_string( iEnt2, EV_SZ_classname, szClass, 31 );
		
		if( !equal( szClass, PathTrack ) && !equal( szClass, PathCorner ) )
			ConfigureEntity( iEnt2, id );
	}
	
	return PLUGIN_CONTINUE;
}

EnvBeamInit( ) {
	new iEntity, iTarget, szStart[ 32 ];
	
	while( ( iEntity = find_ent_by_class( iEntity, "env_beam" ) ) ) {
		global_get( glb_pStringBase, get_pdata_int( iEntity, m_iStartEntity ), szStart, 31 );
		
		while( ( iTarget = find_ent_by_tname( iTarget, szStart ) ) )
			set_pev( iTarget, PevBeamIndent, iEntity );
		
		iTarget = FM_NULLENT;
	}
}

EnvBeamCheck( const iEntity, const id ) {
	new iBeam = pev( iEntity, PevBeamIndent );
	
	if( pev_valid( iBeam ) ) {
		set_pev( iBeam, PevTrapOwner, id );
		
		return 1;
	}
	
	return 0;
}

MultiManagerStuff( const iEntity, const id ) {
	new iTarget, szTarget[ 32 ], iMaxTargets = get_pdata_int( iEntity, m_cTargets );
	
	for( new i = 0; i < iMaxTargets; i++ ) {
		eng_get_string( get_pdata_int( iEntity, m_iTargetName + i ), szTarget, 31 );
		
		while( ( iTarget = find_ent_by_tname( iTarget, szTarget ) ) )
			ConfigureEntity( iTarget, id );
		
		iTarget = FM_NULLENT;
	}
}

bool:IsColliding( const iEntity1, const iEntity2 ) {
	new Float:AbsMin1[ 3 ], Float:AbsMin2[ 3 ], Float:AbsMax1[ 3 ], Float:AbsMax2[ 3 ];
	
	entity_get_vector( iEntity1, EV_VEC_absmin, AbsMin1 );
	entity_get_vector( iEntity1, EV_VEC_absmax, AbsMax1 );
	entity_get_vector( iEntity2, EV_VEC_absmin, AbsMin2 );
	entity_get_vector( iEntity2, EV_VEC_absmax, AbsMax2 );
	
	if( AbsMin1[ 0 ] > AbsMax2[ 0 ] || AbsMin1[ 1 ] > AbsMax2[ 1 ] || AbsMin1[ 2 ] > AbsMax2[ 2 ] ||
		AbsMax1[ 0 ] < AbsMin2[ 0 ] || AbsMax1[ 1 ] < AbsMin2[ 1 ] || AbsMax1[ 2 ] < AbsMin2[ 2 ] )
		return false;
	
	return true;
}

bool:IsPlayerAboveEntity( const id, const iEntity ) {
	new Float:vOrigin[ 3 ], Float:vAbsMinPlayer[ 3 ], Float:vAbsMin[ 3 ], Float:vAbsMax[ 3 ];
	
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	entity_get_vector( id, EV_VEC_absmin, vAbsMinPlayer );
	entity_get_vector( iEntity, EV_VEC_absmin, vAbsMin );
	entity_get_vector( iEntity, EV_VEC_absmax, vAbsMax );
	
	if( vAbsMin[ 0 ] <= vOrigin[ 0 ] <= vAbsMax[ 0 ] && vAbsMin[ 1 ] <= vOrigin[ 1 ] <= vAbsMax[ 1 ]
	&& -10.0 <= vAbsMinPlayer[ 2 ] - vAbsMax[ 2 ] <= 38.0 )
		return true;
	
	return false;
}
