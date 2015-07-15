#include < amxmodx >
#include < fakemeta >

new g_iHudSync1;
new g_iHudSync2;

public plugin_init( )
{
	register_plugin( "AMXX Commands", "1.0", "xPaw" );
	
	register_event( "Damage", "EventDamage", "b", "2!0", "3=0", "4!0" );
	
	g_iHudSync1 = CreateHudSyncObj( );
	g_iHudSync2 = CreateHudSyncObj( );
}

public EventDamage( id )
{
	new iAttacker = get_user_attacker( id );
	
	if( is_user_connected( iAttacker ) )
	{
		new iDamage = read_data( 2 );
		
		set_hudmessage( 255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1 );
		ShowSyncHudMsg( id, g_iHudSync1, "%i", iDamage );
		
		set_hudmessage( 0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02 );
		ShowSyncHudMsg( iAttacker, g_iHudSync2, "%i", iDamage );
		
		new iPlayers[ 32 ], iCount;
		get_players( iPlayers, iCount, "bch" );
		
		for( new i = 0; i < iCount; i++ )
		{
			id = iPlayers[ i ];
			
			if( pev( id, pev_iuser2 ) == iAttacker )
			{
				set_hudmessage( 0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02 );
				ShowSyncHudMsg( iAttacker, g_iHudSync2, "%i", iDamage );
			}
		}
	}
}