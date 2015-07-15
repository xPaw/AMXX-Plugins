#include < amxmodx >
#include < fakemeta >

#define USE_CONNOR_COLOR_NATIVE // Uncomment this line to use ConnorMcLeod's ChatColor

new const PREFIX[ ] = "[XJ]"; // Change to your own if you want to

#if defined USE_CONNOR_COLOR_NATIVE
	#include < chatcolor >
#else
	#include < colorchat >
	
	#define Red RED
	#define client_print_color ColorChat
#endif

new bool:g_bInDmgFall[ 33 ], g_iFrameTime[ 33 ];
new g_iOldButtons, g_iButtons;

public plugin_init( ) {
	register_plugin( "JumpBug Stats", "1.5", "Numb" );
	
	register_forward( FM_CmdStart, "FwdCmdStart" );
	register_forward( FM_PlayerPreThink,  "FM_PlayerPreThink_Pre" );
	register_forward( FM_PlayerPostThink, "FM_PlayerPostThink_Post", true );
}

public plugin_precache( )
	precache_sound( "misc/mod_excellent.wav" );

public FwdCmdStart( const id, const iHandle )
	g_iFrameTime[ id ] = get_uc( iHandle, UC_Msec );

public FM_PlayerPreThink_Pre( const id ) {
	if( !is_user_alive( id ) || pev( id, pev_flags ) & FL_ONGROUND || pev( id, pev_waterlevel ) >= 2 ) {
		g_bInDmgFall[ id ] = false;
		
		return;
	}
	
	g_iButtons    = pev( id, pev_button );
	g_iOldButtons = pev( id, pev_oldbuttons );
	
	new Float:flFallVelocity;
	pev( id, pev_flFallVelocity, flFallVelocity );
	
	g_bInDmgFall[ id ] = bool:( flFallVelocity >= 500.0 );
}

public FM_PlayerPostThink_Post( const id ) {
	if( !g_bInDmgFall[ id ] || g_iOldButtons & IN_JUMP || ~g_iButtons & IN_JUMP )
		return;
	
	if( g_iOldButtons & IN_DUCK && ~pev( id, pev_flags ) & FL_DUCKING ) {
		new Float:vVelocity[ 3 ];
		pev( id, pev_velocity, vVelocity );
		
		if( vVelocity[ 2 ] > 0.0 ) {
			g_bInDmgFall[ id ] = false;
			
			JumpBugMade( id );
		}
	}
}

JumpBugMade( const id ) {
	//new iDistance = floatround( ( g_flJumpOff[ id ] - vOrigin[ 2 ] ), floatround_floor );
	new iEngineFps = floatround( 1 / ( g_iFrameTime[ id ] * 0.001 ) );
	
	new szMessage[ 256 ];
	
	engclient_print( id, engprint_console, "^nSuccessful JumpBug was made! Fall Distance: %i units. Fall Speed: %i u/s. Engine FPS: %i^n", -1, -1, iEngineFps );
	
	formatex( szMessage, 255, "Successful JumpBug was made!^nFall Distance: %i units^nFall Speed: %i u/s^nEngine FPS: %i", -1, -1, iEngineFps );
	
	set_hudmessage( 255, 127, 0, -1.0, 0.65, 0, 6.0, 6.0, 0.7, 0.7, 3 );
	show_hudmessage( id, szMessage );
	
	// Print stats to spectators
	new iPlayers[ 32 ], iNum, iSpec;
	get_players( iPlayers, iNum, "bch" );
	
	for( new i; i < iNum; i++ ) {
		iSpec = iPlayers[ i ];
		
		if( iSpec == pev( id, pev_iuser2 ) )
			show_hudmessage( iSpec, szMessage );
	}
	
	client_cmd( 0, "spk misc/mod_excellent" );
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	client_print_color( 0, Red, "%s %s did JumpBug! Fall distance is %i units with %i u/s.", PREFIX, szName, -1, -1 );
	
}
