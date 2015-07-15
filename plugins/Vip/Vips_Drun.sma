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
	RegisterHam( Ham_TraceAttack, "player", "FwdHamTraceAttack" );
}

public plugin_precache( )
	precache_model( "models/player/vip/vip.mdl" );

public client_disconnect( id )
	g_bVip[ id ] = false;

public vip_removed( const id )
	g_bVip[ id ] = false;

public vip_connected( const id )
	g_bVip[ id ] = true;

public FwdHamPlayerSpawn( const id ) {
	if( g_bVip[ id ] && is_user_alive( id ) ) {
		cs_set_user_money( id, clamp( ( cs_get_user_money( id ) + 300 ), 0, 16000 ) );
		cs_set_user_model( id, "vip" );
		
		set_task( 2.0, "TaskGiveWeapons", id );
	}
}

public FwdHamTraceAttack( id, iAttacker ) {
	if( id != iAttacker && iAttacker <= 32 && get_user_weapon( iAttacker ) == CSW_USP )
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public TaskGiveWeapons( const id ) {
	if( g_bVip[ id ] && is_user_alive( id ) ) {
		switch( cs_get_user_team( id ) ) {
			case CS_TEAM_CT: {
				give_item( id, "weapon_usp" );
				cs_set_user_bpammo( id, CSW_USP, 100 );
			}
			case CS_TEAM_T: {
				give_item( id, "weapon_flashbang" );
			}
		}
	}
}
