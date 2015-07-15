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

new const PREFIX[ ] = "^4[CTF]";

new const ctf_flag[ ] = "ctf_flag";
new const ctf_dummy[ ] = "ctf_dummy";

new const FLAG_MODEL[ ] = "models/w_bag.mdl";
new const FLAG_MODEL2[ ] = "models/p_bag.mdl";

new g_iFlag;
new g_iFlagHolder;
new g_iFlagDummy;
new g_iMsgSayText;

public plugin_init( )
{
	register_plugin( "Capture The Flag", "0.1", "xPaw" );
	
	register_clcmd( "set_bag", "CmdSetBag" );
	
	register_event( "DeathMsg", "EventDeathMsg", "a", "2>0" );
	
	register_touch( ctf_dummy, "player", "FwdGroundFlagTouch" );
	register_think( ctf_dummy, "FwdDummyThink" );
	register_touch( ctf_flag, "player", "FwdFlagTouch" );
	register_think( ctf_flag, "FwdFlagThink" );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
	
//	SpawnFlag( vOrigin );
}

public plugin_precache( )
{
	precache_model( FLAG_MODEL );
	precache_model( FLAG_MODEL2 );
	
	if( ( g_iFlagDummy = create_entity( "info_target" ) ) )
	{
		entity_set_string( g_iFlagDummy, EV_SZ_classname, ctf_dummy );
		entity_set_model( g_iFlagDummy, FLAG_MODEL2 );
		entity_set_int( g_iFlagDummy, EV_INT_solid, SOLID_TRIGGER );
		entity_set_origin( g_iFlagDummy, Float:{ 0.0, 0.0, -8000.0 } );
	}
}

public client_disconnect( id )
{
	CheckFlag( id );
}

public EventDeathMsg( )
{
	CheckFlag( read_data( 2 ) );
}

CheckFlag( const id )
{
	if( g_iFlagHolder == id )
	{
		DropFlag( id );
	}
}

DropFlag( const id )
{
	g_iFlagHolder = 0;
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	GreenPrint( 0, id, "%s^3 %s^1 has dropped the bag!", PREFIX, szName );
	
	// 30 seconds delay to return to base
	entity_set_float( g_iFlag, EV_FL_nextthink, get_gametime( ) + 30.0 );
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	
	entity_set_float( g_iFlagDummy, EV_FL_nextthink, 0.0 );
	entity_set_edict( g_iFlagDummy, EV_ENT_aiment, 0 );
	entity_set_origin( g_iFlagDummy, vOrigin );
	
	drop_to_floor( g_iFlagDummy );
}

public CmdSetBag( const id )
{
	if( ~get_user_flags( id ) & ADMIN_KICK )
	{
		return PLUGIN_CONTINUE;
	}
	else if( g_iFlag )
	{
		console_print( id, "* Bag already exists!" );
		return PLUGIN_HANDLED;
	}
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	
	SpawnFlag( vOrigin );
	
	console_print( id, "* Bag position saved!" );
	return PLUGIN_HANDLED;
}

public FwdGroundFlagTouch( const iEntity, const id )
{
	if( g_iFlagHolder )
	{
		return;
	}
	
	entity_set_float( g_iFlag, EV_FL_nextthink, 0.0 );
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 10.0 );
	entity_set_edict( iEntity, EV_ENT_aiment, id );
	
	g_iFlagHolder = id;
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	GreenPrint( 0, id, "%s^3 %s^1 has pickuped the bag!", PREFIX, szName );
}

public FwdDummyThink( const iEntity )
{
	if( !g_iFlagHolder )
	{
		return;
	}
	
	set_pev( g_iFlagHolder, pev_frags, Float:pev( g_iFlagHolder, pev_frags ) + 1.0 );
	ExecuteHam( Ham_AddPoints, g_iFlagHolder, 0, true );
	
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 10.0 );
}

public FwdFlagThink( const iEntity )
{
	if( g_iFlagHolder )
	{
		return;
	}
	
	GreenPrint( 0, _, "%s^3 The bag has been respawned!", PREFIX );
	
	entity_set_int( g_iFlag, EV_INT_effects, entity_get_int( g_iFlag, EV_INT_effects ) & ~EF_NODRAW );
	entity_set_origin( g_iFlagDummy, Float:{ 0.0, 0.0, -8000.0 } );
}

public FwdFlagTouch( const iEntity, const id )
{
	if( !g_iFlagHolder && !( entity_get_int( iEntity, EV_INT_effects ) & EF_NODRAW ) )
	{
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		GreenPrint( 0, id, "%s^3 %s^1 has taken the bag!", PREFIX, szName );
		
		g_iFlagHolder = id;
		
		entity_set_edict( g_iFlagDummy, EV_ENT_aiment, id );
		entity_set_int( iEntity, EV_INT_effects, entity_get_int( iEntity, EV_INT_effects ) | EF_NODRAW );
	}
}

SpawnFlag( Float:vOrigin[ 3 ] )
{
	g_iFlag = create_entity( "info_target" );
	
	if( !g_iFlag )
	{
		return;
	}
	
	entity_set_origin( g_iFlag, vOrigin );
//	drop_to_floor( g_iFlag );
	
	entity_set_size( g_iFlag, Float:{ -5.0, -5.0, 0.0 }, Float:{ 5.0, 5.0, 28.0 } );
	entity_set_string( g_iFlag, EV_SZ_classname, ctf_flag );
	
	entity_set_model( g_iFlag, FLAG_MODEL );
	
	entity_set_int( g_iFlag, EV_INT_solid, SOLID_TRIGGER );
	entity_set_int( g_iFlag, EV_INT_movetype, MOVETYPE_FLY );
	entity_set_vector( g_iFlag, EV_VEC_avelocity, Float:{ 0.0, 80.0, 0.0 } );
}

GreenPrint( const id, iSender = 1, const Message[ ], any:... )
{
	new szMessage[ 191 ];
	vformat( szMessage, 190, Message, 4 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgSayText, _, id );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
}
