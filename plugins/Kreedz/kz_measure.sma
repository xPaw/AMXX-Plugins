#include <amxmodx>
#include <fakemeta>
#include <xs>

#pragma semicolon 1

new g_flBeam;
new Float:g_vFirstLoc[33][3];
new Float:g_vSecondLoc[33][3];

public plugin_init() {
	register_plugin( "KZ Measure", "1.0", "SchlumPF / xPaw" );
	
	register_clcmd( "say /measure",		"cmdMeasure" );
	register_clcmd( "say /distance",	"cmdMeasure" );
	
	register_menucmd( register_menuid( "\r#kz.xPaw \wMeasuring tool^n^n" ), 1023, "menuAction" );
}

public plugin_precache()
	g_flBeam = precache_model( "sprites/zbeam4.spr" );

public cmdMeasure( plr ) {
	g_vFirstLoc[plr][0] = 0.0;
	g_vFirstLoc[plr][1] = 0.0;
	g_vFirstLoc[plr][2] = 0.0;
	g_vSecondLoc[plr] = g_vFirstLoc[plr];
	
	remove_task( plr + 45896 );
	set_task( 0.1, "tskBeam", plr + 45896, _, _, "ab" );
	
	menuDisplay( plr );
}
	
public menuDisplay( plr ) {
	static menu[2048];
	
	new len = format( menu, 2047, "\r#kz.xPaw \wMeasuring tool^n^n" );
	
	len += format( menu[len], 2047 - len, "\r1. \wSet Loc #1 \d< %.03f | %.03f | %.03f >^n", g_vFirstLoc[plr][0], g_vFirstLoc[plr][1], g_vFirstLoc[plr][2] );
	len += format( menu[len], 2047 - len, "\r2. \wSet Loc #2 \d< %.03f | %.03f | %.03f >^n", g_vSecondLoc[plr][0], g_vSecondLoc[plr][1], g_vSecondLoc[plr][2] );
	len += format( menu[len], 2047 - len, "\r3. \wReset Locs^n^n");
	
	if( g_vFirstLoc[plr][0] != 0.0 && g_vFirstLoc[plr][1] != 0.0 && g_vFirstLoc[plr][2] != 0.0
	&& g_vSecondLoc[plr][0] != 0.0 && g_vSecondLoc[plr][1] != 0.0 && g_vSecondLoc[plr][2] != 0.0 ) {
		len += format( menu[len], 2047 - len, "\r      Results:^n" );
		len += format( menu[len], 2047 - len, "\r      \wHeight difference: \d%f^n", floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) );
		len += format( menu[len], 2047 - len, "\r      \wReal distance: \d%f^n^n", get_distance_f( g_vFirstLoc[plr], g_vSecondLoc[plr] ) );
	}
	len += format( menu[len], 2047 - len, "\r0. \wExit" );
	
	show_menu( plr, ( 1<<0 | 1<<1 | 1<<2 | 1<<9 ), menu, -1 );
}

public menuAction( plr, key ) {
	switch( key ) {
		case 0: {
			fm_get_aim_origin( plr, g_vFirstLoc[plr] );
			
			// [ Make some sparks ]
			message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, plr );
			write_byte( TE_SPARKS );
			engfunc( EngFunc_WriteCoord, g_vFirstLoc[plr][0] );
			engfunc( EngFunc_WriteCoord, g_vFirstLoc[plr][1] );
			engfunc( EngFunc_WriteCoord, g_vFirstLoc[plr][2] );
			message_end( );
			
			menuDisplay( plr );
		}
		case 1: {
			fm_get_aim_origin( plr, g_vSecondLoc[plr] );
			
			// [ Make some sparks ]
			message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, plr );
			write_byte( TE_SPARKS );
			engfunc( EngFunc_WriteCoord, g_vSecondLoc[plr][0] );
			engfunc( EngFunc_WriteCoord, g_vSecondLoc[plr][1] );
			engfunc( EngFunc_WriteCoord, g_vSecondLoc[plr][2] );
			message_end( );
			
			menuDisplay( plr );
		}
		case 2: {
			g_vFirstLoc[plr][0] = 0.0;
			g_vFirstLoc[plr][1] = 0.0;
			g_vFirstLoc[plr][2] = 0.0;
			g_vSecondLoc[plr] = g_vFirstLoc[plr];
			menuDisplay( plr );
		}
		case 9: {
			remove_task( plr + 45896 );
			show_menu( plr, 0, "" );
		}
	}
}

public tskBeam( plr ) {
	plr -= 45896;
	
	if( g_vFirstLoc[plr][0] != 0.0 && g_vFirstLoc[plr][1] != 0.0 && g_vFirstLoc[plr][2] != 0.0
	&& g_vSecondLoc[plr][0] != 0.0 && g_vSecondLoc[plr][1] != 0.0 && g_vSecondLoc[plr][2] != 0.0 ) {
		draw_beam( plr, g_vFirstLoc[plr], g_vSecondLoc[plr] );
		
		if( floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) >= 2 ) {
			static Float:temp[3];
			temp[0] = g_vSecondLoc[plr][0];
			temp[1] = g_vSecondLoc[plr][1];
			temp[2] = g_vFirstLoc[plr][2];
			
			draw_beam( plr, g_vFirstLoc[plr], temp );
			draw_beam( plr, temp, g_vSecondLoc[plr] );
		}
	}
}

public draw_beam( plr, Float:aorigin[3], Float:borigin[3] ) {
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, plr );
	write_byte( TE_BEAMPOINTS );
	engfunc( EngFunc_WriteCoord, aorigin[0] );
	engfunc( EngFunc_WriteCoord, aorigin[1] );
	engfunc( EngFunc_WriteCoord, aorigin[2] );
	engfunc( EngFunc_WriteCoord, borigin[0] );
	engfunc( EngFunc_WriteCoord, borigin[1] );
	engfunc( EngFunc_WriteCoord, borigin[2] );
	write_short( g_flBeam );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 2 );
	write_byte( 20 );
	write_byte( 0 );
	write_byte( 0 );	// 255 85 0
	write_byte( 100 );
	write_byte( 255 );
	write_byte( 150 );
	write_byte( 0 );
	message_end( );
}

fm_get_aim_origin( plr, Float:origin[3] ) {
	new Float:start[3], Float:view_ofs[3];
	pev( plr, pev_origin, start );
	pev( plr, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );

	new Float:dest[3];
	pev( plr, pev_v_angle, dest );
	engfunc( EngFunc_MakeVectors, dest);
	global_get( glb_v_forward, dest );
	xs_vec_mul_scalar( dest, 9999.0, dest );
	xs_vec_add( start, dest, dest );

	engfunc( EngFunc_TraceLine, start, dest, 0, plr, 0 );
	get_tr2( 0, TR_vecEndPos, origin );

	return 1;
}