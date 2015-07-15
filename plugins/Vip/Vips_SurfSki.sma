#include < amxmodx >
#include < hamsandwich >
#include < cstrike >
#include < fun >

forward vip_connected( const id );
forward vip_removed( const id );

new bool:g_bVip[ 33 ];

public plugin_init( ) {
	register_plugin( "VIP Features", "1.0", "xPaw" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", true );
}

public client_disconnect( id )
	g_bVip[ id ] = false;

public vip_removed( const id )
	g_bVip[ id ] = false;

public vip_connected( const id )
	g_bVip[ id ] = true;

public FwdHamPlayerSpawn( const id )
{
	if( g_bVip[ id ] && is_user_alive( id ) )
	{
		cs_set_user_money( id, clamp( ( cs_get_user_money( id ) + 300 ), 0, 16000 ) );
		
		//set_task( 7.5, "TaskGiveWeapons", id );
	}
}

/*public TaskGiveWeapons( const id )
{
	if( g_bVip[ id ] && is_user_alive( id ) )
	{
		give_item( id, "weapon_usp" );
		cs_set_user_bpammo( id, CSW_USP, 100 );
	}
}*/
