#include < amxmodx >
#include < chatcolor >
#include < Achievements >

new const SOUND_DOM[ ] = "myrun/dominate.wav";
new const SOUND_REV[ ] = "myrun/revenge.wav";

#define Sound(%1,%2) client_cmd( %1, "spk ^"%s^"", %2 )

new g_iMaxPlayers, g_iKills[ 33 ][ 33 ];
new ACH_1, ACH_2, ACH_3;

public plugin_init( ) {
	register_plugin( "Domination", "1.0", "xPaw" );
	
	register_event( "DeathMsg", "EventDeathMsg", "a", "1>0", "2>0" );
	
	g_iMaxPlayers = get_maxplayers( );
	
	ACH_1 = RegisterAchievement( "Repeat Offender", "Dominate 10 enemy players.", 10 );
	ACH_2 = RegisterAchievement( "Decimator", "Get 10 kills on players that you're dominating.", 10 );
	ACH_3 = RegisterAchievement( "Command and Control", "Get 5 revenge kills on players that are dominating you.", 5 );
}

public plugin_precache( ) {
	precache_sound( SOUND_DOM );
	precache_sound( SOUND_REV );
}

public client_disconnect( id ) {
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		g_iKills[ i ][ id ] = 0;
		g_iKills[ id ][ i ] = 0;
	}
}

public EventDeathMsg( ) {
	if( get_playersnum( ) < 4 )
		return;
	
	new iVictim = read_data( 2 ),
		iKiller = read_data( 1 );
	
	if( iKiller == iVictim )
		return;
	
	new iKills = ++g_iKills[ iKiller ][ iVictim ];
	
	if( iKills > 3 ) {
		new szKiller[ 32 ], szVictim[ 32 ];
		get_user_name( iKiller, szKiller, 31 );
		get_user_name( iVictim, szVictim, 31 );
		
		ColorChat( 0, Blue, "^t^t^3%s^1 is dominating^3 %s^1 !", szKiller, szVictim );
		
		Sound( iKiller, SOUND_DOM );
		Sound( iVictim, SOUND_DOM );
		
		AchievementProgress( iKiller, iKills > 4 ? ACH_2 : ACH_1 );
	}
	else if( g_iKills[ iVictim ][ iKiller ] > 3 ) {
		g_iKills[ iVictim ][ iKiller ] = 0;
		
		new szKiller[ 32 ], szVictim[ 32 ];
		get_user_name( iKiller, szKiller, 31 );
		get_user_name( iVictim, szVictim, 31 );
		
		ColorChat( 0, Blue, "^t^t^3%s^1 got revenge kill on^3 %s^1 !", szKiller, szVictim );
		
		Sound( iKiller, SOUND_REV );
		Sound( iVictim, SOUND_REV );
		
		AchievementProgress( iKiller, ACH_3 );
	}
}
