#include < amxmodx >
#include < engine >

//#define USE_ADDTOFULLPACK_METHOD // Comment this if you dont want to get more cpu usage
// but it would cause some render bugs, such as with breaking breakables while its marked

#if defined USE_ADDTOFULLPACK_METHOD
	#include < fakemeta >
	
	new Trie:g_tEnts, g_iMarked, g_iFwdAddToFullPack;
#else
	#define EV_FL_renderamt2    EV_FL_scale
	#define EV_INT_renderfx2    EV_INT_iuser1
	#define EV_INT_rendermode2  EV_INT_iuser2
	#define EV_VEC_rendercolor2 EV_VEC_vuser2
#endif

new const g_iColors[ ][ ] = {
	{ 255, 127, 0 },		// orange
	{ 0, 160, 0 },		// green
	{ 0, 127, 255 },		// light blue
	{ 127, 0, 255 },		// purple
	{ 255, 127, 255 }	// pink
};

const SIZE_FUNCS    = 36;
const SIZE_TRIGGERS = 8;
const SIZE_OTHERS   = 6;

new g_szFuncsOnMap[ SIZE_FUNCS ][ 32 ],       g_iFuncsOnMap;
new g_szTriggersOnMap[ SIZE_TRIGGERS ][ 32 ], g_iTriggersOnMap;
new g_szOthersOnMap[ SIZE_OTHERS ][ 32 ],     g_iOthersOnMap;
new g_iPlayerMenu[ 33 ], Trie:g_tMarked;

public plugin_init( ) {
	register_plugin( "Mark entities", "1.0", "xPaw" );
	
	register_clcmd( "say /markent", "CmdMarkMenu", ADMIN_RCON );
}

public plugin_cfg( ) {
	new const szFuncs[ ][ ] = {
		"func_breakable",
		"func_button",
		"func_conveyor",
		"func_door",
		"func_door_rotating",
		"func_friction",
		"func_guntarget",
		"func_healthcharger",
		"func_illusionary",
		"func_ladder",
		"func_mortar_field",
		"func_pendulum",
		"func_plat",
		"func_platrot",
		"func_pushable",
		"func_recharge",
		"func_rot_button",
		"func_rotating",
		"func_tank",
		"func_tanklaser",
		"func_tankmortar",
		"func_tracktrain",
		"func_trackchange",
		"func_trackautochange",
		"func_train",
		"func_traincontrols",
		"func_wall",
		"func_wall_toggle",
		"func_vip_safetyzone",
		"func_escapezone",
		"func_bomb_target",
		"func_vehicle",
		"func_buyzone",
		"func_grencatch",
		"func_hostage_rescue"
	};
	
	new const szTriggers[ ][ ] = {
		"trigger_push",
		"trigger_teleport",
		"trigger_gravity",
		"trigger_hurt",
		"trigger_multiple",
		"trigger_once",
		"trigger_counter"
	};
	
	new const szOthers[ ][ ] = {
		"momentary_rot_button",
		"momentary_door",
		"button_target",
		"env_bubbles",
		"game_zone_player"
	};
	
	g_tMarked = TrieCreate( );
	
#if defined USE_ADDTOFULLPACK_METHOD
	g_tEnts = TrieCreate( );
#endif
	
	new i;
	for( i = 0; i < sizeof szFuncs; i++ ) {
		if( find_ent_by_class( -1, szFuncs[ i ] ) ) {
			copy( g_szFuncsOnMap[ g_iFuncsOnMap ], charsmax( g_szFuncsOnMap[ ] ), szFuncs[ i ] );
			
			g_iFuncsOnMap++;
		}
	}
	
	for( i = 0; i < sizeof szTriggers; i++ ) {
		if( find_ent_by_class( -1, szTriggers[ i ] ) ) {
			copy( g_szTriggersOnMap[ g_iTriggersOnMap ], charsmax( g_szTriggersOnMap[ ] ), szTriggers[ i ] );
			
			g_iTriggersOnMap++;
		}
	}
	
	for( i = 0; i < sizeof szOthers; i++ ) {
		if( find_ent_by_class( -1, szOthers[ i ] ) ) {
			copy( g_szOthersOnMap[ g_iOthersOnMap ], charsmax( g_szOthersOnMap[ ] ), szOthers[ i ] );
			
			g_iOthersOnMap++;
		}
	}
}

public plugin_end( ) {
	TrieDestroy( g_tMarked );
	
#if defined USE_ADDTOFULLPACK_METHOD
	TrieDestroy( g_tEnts );
#endif
}

// GENERATE & SHOW MENUS
///////////////////////////////////////////////////////
public CmdMarkMenu( const id ) {
	if( get_user_flags( id ) & ADMIN_RCON ) {
		new iMenu = menu_create( "\rMark entities by xPaw", "HandleMainMenu" );
		menu_additem( iMenu, "Funcs", "1", 0 );
		menu_additem( iMenu, "Triggers", "2", 0 );
		menu_additem( iMenu, "Others", "3", 0 );
		menu_setprop( iMenu, MPROP_EXIT, MEXIT_ALL );
		
		menu_display( id, iMenu, 0 );
		g_iPlayerMenu[ id ] = 0;
	}
	
	return PLUGIN_HANDLED;
}

ShowAdvMenu( const id, const iMenuNum, const iPage ) {
	new iMenu, szString[ 32 ];
	
	switch( iMenuNum ) {
		case 1: { // Funcs
			if( g_iFuncsOnMap == 0 ) {
				client_print( id, print_chat, "[AMXX] No funcs on this map!" );
				
				CmdMarkMenu( id );
			} else {
				iMenu = menu_create( "\rMark entities: \yFuncs", "HandleMenu" );
				
				for( new i = 0; i < g_iFuncsOnMap; i++ ) {
				//	if( !g_szFuncsOnMap[ i ][ 0 ] )
				//		continue;
					
					formatex( szString, charsmax( szString ), "%s %s", g_szFuncsOnMap[ i ], TrieKeyExists( g_tMarked, g_szFuncsOnMap[ i ] ) ? "\y( Marked )" : "" );
					menu_additem( iMenu, szString );
				}
			}
		}
		case 2: { // Triggers
			if( g_iTriggersOnMap == 0 ) {
				client_print( id, print_chat, "[AMXX] No triggers on this map!" );
				
				CmdMarkMenu( id );
			} else {
				iMenu = menu_create( "\rMark entities: \yTriggers", "HandleMenu" );
				
				for( new i = 0; i < g_iTriggersOnMap; i++ ) {
					formatex( szString, charsmax( szString ), "%s %s", g_szTriggersOnMap[ i ], TrieKeyExists( g_tMarked, g_szTriggersOnMap[ i ] ) ? "\y( Marked )" : "" );
					menu_additem( iMenu, szString );
				}
			}
		}
		case 3: { // Others
			if( g_iOthersOnMap == 0 ) {
				client_print( id, print_chat, "[AMXX] No 'Others' on this map!" );
				
				CmdMarkMenu( id );
			} else {
				iMenu = menu_create( "\rMark entities: \yOthers", "HandleMenu" );
				
				for( new i = 0; i < g_iOthersOnMap; i++ ) {
					formatex( szString, charsmax( szString ), "%s %s", g_szOthersOnMap[ i ], TrieKeyExists( g_tMarked, g_szOthersOnMap[ i ] ) ? "\y( Marked )" : "" );
					menu_additem( iMenu, szString );
				}
			}
		}
		default: return;
	}
	
	g_iPlayerMenu[ id ] = iMenuNum;
	
	if( iMenu > 0 ) {
		menu_setprop( iMenu, MPROP_EXIT, MEXIT_ALL );
		menu_display( id, iMenu, iPage );
	}
}

// MENU HANDLES
///////////////////////////////////////////////////////
public HandleMainMenu( const id, const iMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		return PLUGIN_HANDLED;
	}
	
	new szKey[ 2 ], iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, szKey, 1, _, _, iTrash );
	
	ShowAdvMenu( id, str_to_num( szKey ), 0 );
	
	menu_destroy( iMenu );
	
	return PLUGIN_HANDLED;
}

public HandleMenu( const id, const iMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		CmdMarkMenu( id );
		
		return PLUGIN_HANDLED;
	}
	
	new szItem[ 32 ], szEnt[ 32 ], iPage, iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, "", 0, szItem, 31, iTrash );
	player_menu_info( id, iPage, iPage, iPage );
	
	parse( szItem, szEnt, 31 );
	
	MarkEnt( id, szEnt, bool:TrieKeyExists( g_tMarked, szEnt ) );
	
	ShowAdvMenu( id, g_iPlayerMenu[ id ], iPage );
	
	menu_destroy( iMenu );
	
	return PLUGIN_HANDLED;
}

//
///////////////////////////////////////////////////////
MarkEnt( const id, szClassname[ 32 ], bool:bUnMark = false ) {
	new iEntity, iCount;
	
#if defined USE_ADDTOFULLPACK_METHOD
	new szEnt[ 2 ];
#else
	new Float:vColor[ 3 ], Float:flAmt;
#endif
	
	new bool:bIllusionary = bool:( szClassname[ 5 ] == 'i' && szClassname[ 6 ] == 'l' && szClassname[ 9 ] == 's' );
	
	if( !bUnMark ) {
		TrieSetCell( g_tMarked, szClassname, 1 );
		
#if defined USE_ADDTOFULLPACK_METHOD
		if( !g_iFwdAddToFullPack )
			g_iFwdAddToFullPack = register_forward( FM_AddToFullPack, "FwdAddToFullPack", 1 );
		
		++g_iMarked;
#endif
		
		new iColor;
		while( ( iEntity = find_ent_by_class( iEntity, szClassname ) ) > 0 ) {
			if( bIllusionary && entity_get_int( iEntity, EV_INT_skin ) == CONTENTS_WATER )
				continue;
			
			iCount++;
			
			iColor = random( sizeof( g_iColors ) );
			
#if defined USE_ADDTOFULLPACK_METHOD
			szEnt[ 0 ] = iEntity;
			
			TrieSetCell( g_tEnts, szEnt, iColor );
#else
			if( entity_get_int( iEntity, EV_INT_effects ) & EF_NODRAW ) {
				set_entity_visibility( iEntity, 1 );
				
				entity_set_int( iEntity, EV_INT_iuser4, 0 );
			} else
				entity_set_int( iEntity, EV_INT_iuser4, 1 );
			
			entity_set_int( iEntity, EV_INT_renderfx2, entity_get_int( iEntity, EV_INT_renderfx ) );
			entity_set_int( iEntity, EV_INT_rendermode2, entity_get_int( iEntity, EV_INT_rendermode ) );
			
			flAmt = entity_get_float( iEntity, EV_FL_renderamt );
			entity_set_float( iEntity, EV_FL_renderamt2, flAmt );
			
			entity_get_vector( iEntity, EV_VEC_rendercolor, vColor );
			entity_set_vector( iEntity, EV_VEC_rendercolor2, vColor );
			
			set_rendering( iEntity, kRenderFxNone, g_iColors[ iColor ][ 0 ], g_iColors[ iColor ][ 1 ], g_iColors[ iColor ][ 2 ], kRenderTransColor, 150 );
#endif
		}
	} else {
		TrieDeleteKey( g_tMarked, szClassname );
		
#if defined USE_ADDTOFULLPACK_METHOD
		if( --g_iMarked == 0 && g_iFwdAddToFullPack ) {
			unregister_forward( FM_AddToFullPack, g_iFwdAddToFullPack, 1 );
			
			g_iFwdAddToFullPack = 0;
		}
#endif
		
		while( ( iEntity = find_ent_by_class( iEntity, szClassname ) ) > 0 ) {
			if( bIllusionary && entity_get_int( iEntity, EV_INT_skin ) == CONTENTS_WATER )
				continue;
			
			iCount++;
			
#if defined USE_ADDTOFULLPACK_METHOD
			szEnt[ 0 ] = iEntity;
			
			TrieDeleteKey( g_tEnts, szEnt );
#else
			set_entity_visibility( iEntity, entity_get_int( iEntity, EV_INT_iuser4 ) );
			
			entity_set_int( iEntity, EV_INT_renderfx, entity_get_int( iEntity, EV_INT_renderfx2 ) );
			entity_set_int( iEntity, EV_INT_rendermode, entity_get_int( iEntity, EV_INT_rendermode2 ) );
			
			flAmt = entity_get_float( iEntity, EV_FL_renderamt2 );
			entity_set_float( iEntity, EV_FL_renderamt, flAmt );
			
			entity_get_vector( iEntity, EV_VEC_rendercolor2, vColor );
			entity_set_vector( iEntity, EV_VEC_rendercolor, vColor );
			
			// Clear it now
			entity_set_int( iEntity, EV_INT_iuser4, 0 );
			entity_set_int( iEntity, EV_INT_renderfx2, 0 );
			entity_set_int( iEntity, EV_INT_rendermode2, 0 );
			entity_set_float( iEntity, EV_FL_renderamt2, 0.0 );
			entity_set_vector( iEntity, EV_VEC_rendercolor2, Float:{ 0.0, 0.0, 0.0 } );
#endif
		}
	}
	
	set_hudmessage( 0, 127, 255, -1.0, 0.70, 0, 0.0, 2.0, 0.3, 0.3, 1 );
	show_hudmessage( id, "*** %i %s%s has been %smarked ***", iCount, szClassname, iCount == 1 ? "" : "'s", bUnMark ? "un" : "" );
	
	console_print( id, "*** %i %s%s has been %smarked ***", iCount, szClassname, iCount == 1 ? "" : "'s", bUnMark ? "un" : "" );
	
	return PLUGIN_HANDLED;
}

#if defined USE_ADDTOFULLPACK_METHOD
public FwdAddToFullPack( const iEsHandle, const e, const iEntity, const iHost, iHostFlags, bPlayer, pSet ) {
	if( !bPlayer ) {
		static szEnt[ 2 ], iColor;
		szEnt[ 0 ] = iEntity;
		
		if( TrieGetCell( g_tEnts, szEnt, iColor ) ) {
			static vColor[ 3 ];
			vColor[ 0 ] = g_iColors[ iColor ][ 0 ];
			vColor[ 1 ] = g_iColors[ iColor ][ 1 ];
			vColor[ 2 ] = g_iColors[ iColor ][ 2 ];
			
		//	set_es( iEsHandle, ES_Effects, get_es( iEsHandle, ES_Effects ) & ~EF_NODRAW );
			
			set_es( iEsHandle, ES_RenderMode, kRenderTransColor );
		//	set_es( iEsHandle, ES_RenderFx, kRenderFxGlowShell );
			set_es( iEsHandle, ES_RenderColor, vColor );
			set_es( iEsHandle, ES_RenderAmt, 150 );
		}
	}
}
#endif
