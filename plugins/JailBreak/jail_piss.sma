#include < amxmodx >
#include < engine >
#include < hamsandwich >
#include < chatcolor >

new g_iForward;
new bool:g_bPiss[ 33 ];
new g_iPuddleCount[ 33 ];

public plugin_init( ) {
	register_plugin( "Jail: Piss", "1.0", "xPaw" );
	
	register_clcmd( "piss", "CmdPiss" );
	g_iForward = CreateMultiForward( "Jail_CreatePiss", ET_IGNORE, FP_CELL );
	
	register_event( "DeathMsg", "EventDeathMsg", "a" );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
}

public plugin_precache( ) {
	precache_sound( "piss/pissing.wav" );
	
	precache_model( "models/piss/piss_puddle1.mdl" );
	precache_model( "models/piss/piss_puddle2.mdl" );
	precache_model( "models/piss/piss_puddle3.mdl" );
	precache_model( "models/piss/piss_puddle4.mdl" );
	precache_model( "models/piss/piss_puddle5.mdl" );
}

public CmdPiss( id ) {
	if( !is_user_alive( id ) )
		return PLUGIN_HANDLED;
	
	if( g_bPiss[ id ] ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You can piss only once in a round!" );
		
		return PLUGIN_HANDLED;
	}
	
	g_bPiss[ id ] = true;
	g_iPuddleCount[ id ] = 1;
	
	new iReturn;
	ColorChat( id, Red, "[ mY.RuN ]^1 You're pissing now!" );
	
	emit_sound( id, CHAN_VOICE, "piss/pissing.wav", 1.0, ATTN_NORM, 0, PITCH_NORM );
	ExecuteForward( g_iForward, iReturn, id );
	
	set_task( 0.3, "MakePee", id, _, _, "a", 48 );
	set_task( 2.2, "PlacePuddle", id + 3681, _, _, "a", 4 );
	
	return PLUGIN_HANDLED;
}

public MakePee( id ) {
	new vOrigin[ 3 ], vAim[ 3 ], vVelocity[ 3 ], iLength;
	
	get_user_origin( id, vOrigin );
	get_user_origin( id, vAim, 3 );
	
	new iDistance = get_distance( vOrigin, vAim );
	new iSpeed = floatround( iDistance * 1.9 );
	
	vVelocity[ 0 ] = vAim[ 0 ] - vOrigin[ 0 ];
	vVelocity[ 1 ] = vAim[ 1 ] - vOrigin[ 1 ];
	vVelocity[ 2 ] = vAim[ 2 ] - vOrigin[ 2 ];
	
	iLength = sqroot( vVelocity[ 0 ] * vVelocity[ 0 ] + vVelocity[ 1 ] * vVelocity[ 1 ] + vVelocity[ 2 ] * vVelocity[ 2 ] );
	
	vVelocity[ 0 ] = vVelocity[ 0 ] * iSpeed / iLength;
	vVelocity[ 1 ] = vVelocity[ 1 ] * iSpeed / iLength;
	vVelocity[ 2 ] = vVelocity[ 2 ] * iSpeed / iLength;
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BLOODSTREAM );
	write_coord( vOrigin[ 0 ] );
	write_coord( vOrigin[ 1 ] );
	write_coord( vOrigin[ 2 ] );
	write_coord( vVelocity[ 0 ] );
	write_coord( vVelocity[ 1 ] );
	write_coord( vVelocity[ 2 ] );
	write_byte ( 102 );
	write_byte ( 160 );
	message_end( );
}

public PlacePuddle( iTask ) {
	new id = iTask - 3681;
	
	new iOrigin[ 3 ], Float:vOrigin[ 3 ];
	get_user_origin( id, iOrigin, 3 );
	
	IVecFVec( iOrigin, vOrigin );
	
	new iEntity = create_entity( "info_target" );
	
	if( !is_valid_ent( iEntity ) )
		return PLUGIN_HANDLED_MAIN;
	
	entity_set_size( iEntity, Float:{ -1.0, -1.0, -1.0 }, Float:{ 1.0, 1.0, 1.0 } );
	
	new szModel[ 96 ];
	formatex( szModel, 95, "models/piss/piss_puddle%i.mdl", g_iPuddleCount[ id ] );
	
	entity_set_string( iEntity, EV_SZ_classname, "piss_puddle" );
	entity_set_model( iEntity, szModel );
	
	entity_set_origin( iEntity, vOrigin );
	entity_set_edict( iEntity, EV_ENT_owner, id );
	entity_set_int( iEntity, EV_INT_solid, 3 );
	entity_set_int( iEntity, EV_INT_movetype, 6 );
	
	if( g_iPuddleCount[ id ] >= 5 )
		remove_task( id + 3681 );
	
	g_iPuddleCount[ id ]++;
	
	return PLUGIN_CONTINUE;
}

public client_putinserver( id ) {
	g_bPiss[ id ] = false;
	g_iPuddleCount[ id ] = 1;
}

public client_disconnect( id ) {
	if( g_bPiss[ id ] ) {
		remove_task( id );
		remove_task( id + 3681 );
		
		emit_sound( id, CHAN_VOICE, "piss/pissing.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
	}
}

public EventDeathMsg( ) {
	new id = read_data( 2 );
	
	if( g_bPiss[ id ] ) {
		remove_task( id );
		remove_task( id + 3681 );
		
		emit_sound( id, CHAN_VOICE, "piss/pissing.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
	}
}

public FwdHamPlayerSpawn( id ) {
	if( is_user_alive( id ) ) {
		if( g_bPiss[ id ] ) {
			remove_task( id );
			remove_task( id + 3681 );
			
			emit_sound( id, CHAN_VOICE, "piss/pissing.wav", 0.0, ATTN_NORM, 0, PITCH_NORM );
		}
		
		g_bPiss[ id ] = false;
		g_iPuddleCount[ id ] = 1;
		
		new iEntity;
		while( ( iEntity = find_ent_by_owner( iEntity, "piss_puddle", id ) ) > 0 )
			remove_entity( iEntity );
	}
}
