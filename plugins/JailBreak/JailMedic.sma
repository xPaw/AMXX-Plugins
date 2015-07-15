#include < amxmodx >
#include < engine >
#include < hamsandwich >

new g_iMedic;

public plugin_init( )
{
	register_plugin( "Jail: Medic", "1.0", "xPaw" );
	
	new const hostage_entity[ ] = "hostage_entity";
	
	RegisterHam( Ham_TakeDamage, hostage_entity, "FwdHamMedicTakeDamage" );
	RegisterHam( Ham_Killed, hostage_entity, "FwdHamMedicKilled" );
	
	CreateMedic( );
}

public FwdHamMedicTakeDamage( const iMedic, const iInflictor, const iAttacker )
{
	client_print( 0, print_chat, "[DEBUG] Medic (%i) was attacked by %i (%i)", iMedic, iInflictor, iAttacker );
}

public FwdHamMedicKilled( const iMedic, const iAttacker, const bool:bShouldGib )
{
	client_print( 0, print_chat, "[DEBUG] Medic (%i) was killed by (%i)", iMedic, iAttacker );
}

public CreateMedic( )
{
	new iSpawn = find_ent_by_class( -1, "info_player_start" );
	
	if( !iSpawn )
	{
		return;
	}
	
	g_iMedic = create_entity( "hostage_entity" );
	
	if( !g_iMedic )
	{
		return;
	}
	
	new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
	entity_get_vector( iSpawn, EV_VEC_origin, vOrigin );
	entity_get_vector( iSpawn, EV_VEC_angles, vAngles );
	
	entity_set_vector( g_iMedic, EV_VEC_origin, vOrigin );
	entity_set_vector( g_iMedic, EV_VEC_angles, vAngles );
	
	ExecuteHam( Ham_Spawn, g_iMedic );
	
	entity_set_float( g_iMedic, EV_FL_health, 500.0 );
	
	entity_set_byte(g_iMedic,EV_BYTE_controller1,125);
	entity_set_byte(g_iMedic,EV_BYTE_controller2,125);
	entity_set_byte(g_iMedic,EV_BYTE_controller3,125);
	entity_set_byte(g_iMedic,EV_BYTE_controller4,125);
}
