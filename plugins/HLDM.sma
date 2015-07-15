#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

new g_iDeadies;
new g_iFhCmdStart;
new g_iSeconds[ 33 ];
new bool:g_bDeadie[ 33 ];

#define InTeam(%1) ( CS_TEAM_UNASSIGNED < cs_get_user_team( %1 ) < CS_TEAM_SPECTATOR )

public plugin_init( ) {
	register_plugin( "HL DM", "1.0", "xPaw" );
	
	RegisterHam( Ham_Killed, "player", "FwdHamPlayerKilled" );
	RegisterHam( Ham_Spawn,  "player", "FwdHamPlayerSpawn", 1 );
}

public client_disconnect( id ) {
	if( g_bDeadie[ id ] ) {
		g_bDeadie[ id ] = false;
		
		g_iDeadies--;
		
		CheckForward( );
	}
}

public FwdHamPlayerSpawn( id ) {
	if( is_user_alive( id ) ) {
		if( g_bDeadie[ id ] ) {
			g_bDeadie[ id ] = false;
			
			g_iDeadies--;
			
			CheckForward( );
		}
	}
}

public FwdHamPlayerKilled( id ) {
	set_pev( id, pev_solid, SOLID_NOT ); // Dont block some rotating entities
	
	g_iDeadies++;
	
	g_bDeadie[ id ] = true;
	
	g_iSeconds[ id ] = 5;
	
	Countdown( id );
	
	CheckForward( );
	
	return HAM_SUPERCEDE;
}

public Countdown( id ) {
	if( g_bDeadie[ id ] ) {
		g_iSeconds[ id ]--;
		
		engclient_print( id, engprint_center, "^nYou can respawn in %i !", g_iSeconds[ id ] );
		
		if( g_iSeconds[ id ] > 0 )
			set_task( 1.0, "Countdown", id );
		else
			engclient_print( id, engprint_center, "^nYou can respawn now !^nPress your attack key !" );
	}
}

CheckForward( ) {
	if( g_iDeadies > 0 ) {
		if( !g_iFhCmdStart )
			g_iFhCmdStart = register_forward( FM_CmdStart, "FwdCmdStart" );
	} else {
		if( g_iFhCmdStart ) {
			unregister_forward( FM_CmdStart, g_iFhCmdStart );
			
			g_iFhCmdStart = 0;
		}
	}
}

public FwdCmdStart( id, iHandle ) {
	if( !g_bDeadie[ id ] || g_iSeconds[ id ] )
		return;
	
//	if( is_user_alive( id ) || !InTeam( id ) )
//		return;
	
	if( get_uc( iHandle, UC_Buttons ) & IN_ATTACK )
		ExecuteHamB( Ham_CS_RoundRespawn, id );
}
