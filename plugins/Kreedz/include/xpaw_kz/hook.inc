// HOOK
// ==================================================================================

public CmdHookOn( const id ) {
#if defined XJ_BUILD
	if( kz_is_in_cup( id ) )
		return PLUGIN_HANDLED;
#endif
	
	if( !g_bHook[ id ] && g_bFinishedMap[ id ] && is_user_alive( id ) )
		HookCreate( id );
	
	return PLUGIN_HANDLED;
}

public CmdHookOff( const id ) {
	if( g_bHook[ id ] )
		HookRemove( id );
	
	return PLUGIN_HANDLED;
}

public HookCreate( const id ) {
	if( !get_user_origin( id, g_iHookOrigin[ id ], 3 ) )
		return PLUGIN_HANDLED;
	
	//CheatDetect( id, "Hook" );
	
	g_bHook[ id ]      = true;
	g_bAfterHook[ id ] = false;
	
	HookKillBeam( id );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMENTPOINT );
	write_short( id );
	write_coord( g_iHookOrigin[ id ][ 0 ] );
	write_coord( g_iHookOrigin[ id ][ 1 ] );
	write_coord( g_iHookOrigin[ id ][ 2 ] );
	write_short( g_iBeam );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 100 );
	write_byte( 15 );
	write_byte( 3 );
	write_byte( 255 );
	write_byte( 85 );
	write_byte( 0 );
	write_byte( 150 );
	write_byte( 0 );
	message_end( );
	
	return PLUGIN_HANDLED;
}

public HookRemove( const id ) {
	g_bHook[ id ]      = false;
	g_bAfterHook[ id ] = true;
	
	//if( gUserConnected[ id ] )
	HookKillBeam( id );
}

public HookKillBeam( const id ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, _, id );
	write_byte( TE_KILLBEAM );
	write_short( id );
	message_end( );
}

public HookThink( const id ) {
	if( !g_bHook[ id ] ) {
		if( g_bAfterHook[ id ] ) {
			static Float:vVelocity[ 3 ];
			entity_get_vector( id, EV_VEC_velocity, vVelocity );
			
			if( vector_length( vVelocity ) < 10.0 && IsPlayerOnGround( id ) )
				g_bAfterHook[ id ] = false;
		}
		
		return;
	}
	
	static const Hook[ ] = "Hook";
	
	CheatDetect( id, Hook );
	
	static iOrigin[ 3 ], Float:vVelocity[ 3 ], iDistance;
	get_user_origin( id, iOrigin );
	vVelocity = Float:{ 0.0, 0.0, 0.0 };
	iDistance = get_distance( g_iHookOrigin[ id ], iOrigin );
	
	if( iDistance > 32 ) {
		new Float:flSpeed = HOOK_SPEED / iDistance;
		
		vVelocity[ 0 ] = ( g_iHookOrigin[ id ][ 0 ] - iOrigin[ 0 ] ) * flSpeed;
		vVelocity[ 1 ] = ( g_iHookOrigin[ id ][ 1 ] - iOrigin[ 1 ] ) * flSpeed;
		vVelocity[ 2 ] = ( g_iHookOrigin[ id ][ 2 ] - iOrigin[ 2 ] ) * flSpeed;
	}
	
	entity_set_vector( id, EV_VEC_velocity, vVelocity );
}