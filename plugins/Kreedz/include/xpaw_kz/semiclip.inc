new g_iPlayers[ 32 ], g_iNum, g_iPlayer, g_szEntityString[ 2 ];

// FIND WATER ENTITIES
// ==================================================================================
FindWaterEntities( ) {
	new iSkin, iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_water" ) ) ) {
		entity_set_float( iEntity, EV_FL_scale, 0.0 );
		
		AddWaterEntity( iEntity );
	}
	
	iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_conveyor" ) ) )
		if( entity_get_int( iEntity, EV_INT_spawnflags ) == 3 )
			AddWaterEntity( iEntity );
	
	iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_illusionary" ) ) ) {
		iSkin = entity_get_int( iEntity, EV_INT_skin );
		
		if( iSkin == CONTENTS_WATER || iSkin == CONTENTS_SLIME )
			AddWaterEntity( iEntity );
	}
}

AddWaterEntity( const iEntity ) {
	if( !g_tWaterEntities ) g_tWaterEntities = TrieCreate( );
	
	g_szEntityString[ 0 ] = iEntity;
	TrieSetCell( g_tWaterEntities, g_szEntityString, true );
}


// SEMICLIP AND INVISIBILITY
// ==================================================================================
public FwdAddToFullPack( es_handle, e, iEnt, id, hostflags, player, pSet ) {
	if( !get_orig_retval( ) )
		return FMRES_IGNORED;
	
	if( player ) {
		if( id == iEnt || iEnt == g_iSpectateId[ id ] )
			return FMRES_IGNORED;
		
		if( g_bNightVision[ iEnt ] )
			set_es( es_handle, ES_Effects, get_es( es_handle, ES_Effects ) & ~EF_BRIGHTLIGHT );
		
		set_es( es_handle, ES_Solid, SOLID_NOT );
		
		if( g_bInvisPlayers[ id ] ) {
			static const Float:vOrigin[ 3 ] = { 0.0, 0.0, -9999.0 };
			
			set_es( es_handle, ES_Origin, vOrigin );
			set_es( es_handle, ES_Effects, EF_NODRAW );
	//	} else {
		}
		else if( g_bConnected[ iEnt ] ) {
			static Float:flDistance;
			flDistance = entity_range( id, iEnt );
			
			if( flDistance < 512.0 ) {
				set_es( es_handle, ES_RenderMode, kRenderTransAlpha )
				set_es( es_handle, ES_RenderAmt, floatround( flDistance ) / 2 );
			}
		}
		
		return FMRES_HANDLED;
	}
	else if( g_tWaterEntities && g_bInvisWater[ id ] ) {
		g_szEntityString[ 0 ] = iEnt;
		
		if( TrieKeyExists( g_tWaterEntities, g_szEntityString ) ) {
			set_es( es_handle, ES_Effects, EF_NODRAW );
			
			return FMRES_HANDLED;
		}
	}
	
	return FMRES_IGNORED;
}

public FwdHamPlayerPreThink( const id )
	Semiclip( id, SOLID_NOT );

public client_PostThink( id )
	Semiclip( id, SOLID_SLIDEBOX );

Semiclip( const id, const iSolid ) {
	if( !is_user_alive( id ) )
		return;
	
	static const AliveFlag[ ] = "a";
	
	get_players( g_iPlayers, g_iNum, AliveFlag );
	
	for( new i = 0; i < g_iNum; i++ ) {
		g_iPlayer = g_iPlayers[ i ];
		
		if( id != g_iPlayer )
			set_pev( g_iPlayer, pev_solid, iSolid );
	}
}