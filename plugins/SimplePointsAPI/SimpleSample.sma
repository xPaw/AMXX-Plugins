/*
 * SIMPLE POINTS API
 * by xPaw
 *
 * Website: https://xpaw.me/
 */

#include < amxmodx >
#include < SimplePoints >

new bool:g_bConnected[ 33 ];

public plugin_init( )
{
	register_event( "DeathMsg", "EventDeathMsg", "a" );
}

public client_disconnect( id )
{
	g_bConnected[ id ] = false;
}

public points_client_connected( const id )
{
	g_bConnected[ id ] = true;
}

public EventDeathMsg( )
{
	new iKiller = read_data( 1 ),
		iVictim = read_data( 2 );
	
	if( !g_bConnected[ iKiller ] || iKiller == iVictim )
	{
		return;
	}
	
	// Give 5 points for killing, and -5 points for teamkill obviously
	points_add( iKiller, get_user_team( iKiller ) == get_user_team( iVictim ) ? -5 : 5 );
}
