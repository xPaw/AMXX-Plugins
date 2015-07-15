#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < chatcolor >

new const CLASSNAME    [ ] = "jb_dookie";
new const DOOKIE_SOUND1[ ] = "dookie/dookie1.wav";
new const DOOKIE_SOUND2[ ] = "dookie/dookie3.wav";
new const DOOKIE_MODEL [ ] = "models/dookie3.mdl";
new const STEAM_SPRITE [ ] = "sprites/xsmoke3.spr";
new const SMOKE_SPRITE [ ] = "sprites/steam1.spr";

new g_iSteam, g_iSmoke, g_iForward, g_iMsgShake;
new bool:g_bDookie[ 33 ], g_iHeadShots[ 33 ];

public plugin_init( ) {
	register_plugin( "Jail: Dookie", "1.0", "xPaw" );
	
	register_clcmd( "dookie", "CmdDookie" );
	
	register_think( CLASSNAME, "FwdDookieThink" );
	
	register_logevent( "EventNewRound", 2, "1=Round_Start" );
	
	g_iMsgShake = get_user_msgid( "ScreenShake" );
	g_iForward  = CreateMultiForward( "Jail_CreateDookie", ET_IGNORE, FP_CELL );
	
	register_event( "DeathMsg", "EventDeathMsg", "a", "3>0" );
}

public plugin_precache( ) {
	precache_model( DOOKIE_MODEL );
	precache_sound( DOOKIE_SOUND1 );
	precache_sound( DOOKIE_SOUND2 );
	
	g_iSteam = precache_model( STEAM_SPRITE );
	g_iSmoke = precache_model( SMOKE_SPRITE );
}

public client_disconnect( id )
	g_iHeadShots[ id ] = 0;

public EventNewRound( ) {
	arrayset( g_bDookie, false, 33 );
	
	new iEntity;
	
	while( ( iEntity = find_ent_by_class( iEntity, CLASSNAME ) ) > 0 )
		remove_entity( iEntity );
}

public EventDeathMsg( ) {
	new id = read_data( 1 );
	
	if( id != read_data( 2 ) )
		g_iHeadShots[ id ]++;
}

public CmdDookie( const id ) {
	if( !is_user_alive( id ) )
		return PLUGIN_HANDLED;
	
	if( g_bDookie[ id ] ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You can take a dump only once in a round!" );
		
		return PLUGIN_HANDLED;
	}
	
	g_bDookie[ id ] = true;
	
	new iReturn, bool:bHuge = bool:( g_iHeadShots[ id ] > 0 );
	ColorChat( id, Red, "[ mY.RuN ]^1 You just took a%s dump.", ( bHuge ? " huge" : "" ) );
	CreateDookie( id, bHuge );
	
	ExecuteForward( g_iForward, iReturn, id );
	
	g_iHeadShots[ id ]--;
	
	return PLUGIN_HANDLED;
}

public FwdDookieThink( const iEntity ) {
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SPRITE );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] + 10.0 );
	write_short( g_iSteam );
	write_byte( 8 );
	write_byte( 10 );
	message_end( );
}

CreateDookie( const id, const bool:bHuge ) {
	new iEntity = create_entity( "info_target" );
	
	if( !iEntity ) return;
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	
	entity_set_string( iEntity, EV_SZ_classname, CLASSNAME );
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_TOSS );
	
	entity_set_origin( iEntity, vOrigin );
	entity_set_model( iEntity, DOOKIE_MODEL );
	
	engfunc( EngFunc_EmitSound, id, CHAN_VOICE, bHuge ? DOOKIE_SOUND2 : DOOKIE_SOUND1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SMOKE );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	write_short( g_iSmoke );
	write_byte( 60 );
	write_byte( 5 );
	message_end( );
	
	if( bHuge ) {
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgShake, _, id );
		write_short( 1 << 15 );
		write_short( 1 << 11 );
		write_short( 1 << 15 );
		message_end( );
		
		vOrigin[ 2 ] -= 20.0;
		
		for( new i; i < 10; i++ ) {
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_BLOODSTREAM );
			engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
			engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
			engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
			write_coord( random_num( -100, 100 ) );
			write_coord( random_num( -100, 100 ) );
			write_coord( random_num( 20, 300 ) );
			write_byte( 100 );
			write_byte( random_num( 100, 200 ) );
			message_end( );
		}
	}
}