#include < amxmodx >
#include < GeoIP >
#include < ChatColor >
#include < Achievements >

new g_iAchievements;

public plugin_init( )
{
	register_plugin( "Connect Announcer", "1.0", "xPaw" );
}

public plugin_cfg( )
{
	g_iAchievements = GetUnlocksCount( 0 );
	
	if( !g_iAchievements ) g_iAchievements = 1; // divide by zero
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	new szName[ 32 ], szIP[ 16 ], szCode[ 3 ], szCountry[ 46 ];
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) )
	{
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	geoip_country( szIP, szCountry, 45 );
	
	if( szCountry[ 0 ] == 'e' && szCountry[ 1 ] == 'r' && szCountry[ 3 ] == 'o' )
		szCountry = "Unknown Country";
	
	if( iConnects ) {
		new iCount = GetUnlocksCount( id ), iPercent = iCount * 100 / g_iAchievements;
		
		ColorChat( 0, Red, "[ mY.RuN ]^1 Player^3 [%s]^4 %s^1 has connected from^4 %s^1. Achievements:^4 %i/%i ^3(%i%%)",
			szCode, szName, szCountry, iCount, g_iAchievements, iPercent );
	} else {
		ColorChat( 0, Red, "[ mY.RuN ]^1 Player^3 [%s]^4 %s^1 has connected from^4 %s^1.",
			szCode, szName, szCountry );
	}
}

public client_disconnect( id )
{
	new szName[ 32 ], szIP[ 16 ], szCode[ 3 ], szCountry[ 46 ];
	get_user_name( id, szName, 31 );
	get_user_ip( id, szIP, 15, 1 );
	
	if( !geoip_code2_ex( szIP, szCode ) )
	{
		szCode[ 0 ] = '-';
		szCode[ 1 ] = '-';
	}
	
	geoip_country( szIP, szCountry, 45 );
	
	if( szCountry[ 0 ] == 'e' && szCountry[ 1 ] == 'r' && szCountry[ 3 ] == 'o' )
		szCountry = "Unknown Country";
	
	ColorChat( 0, Red, "[ mY.RuN ]^1 Player^3 [%s]^4 %s^1 has disconnected from^4 %s^1.",
		szCode, szName, szCountry );
}
