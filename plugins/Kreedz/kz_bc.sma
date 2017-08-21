#include <amxmodx>
#include <engine>

new const g_szModel[ ] = "models/w_c4.mdl";

new const g_szTargets[ 2 ][ ] = {
	"counter_start",
	"counter_off"
};

new g_szFile[ 128 ];
new g_szMapname[ 32 ];
new g_iButtonsMenu;

public plugin_init( ) {
	register_plugin( "KZ Buttons Creator", "1.0", "xPaw" );
	
	register_clcmd( "say /cbm", "CmdButtonsMenu", ADMIN_RCON );
	
	g_iButtonsMenu = menu_create( "\rClimb Buttons Creator \wBy xPaw", "HandleButtonsMenu" );
	
	menu_additem( g_iButtonsMenu, "Create \yStart", "1" );
	menu_additem( g_iButtonsMenu, "Create \rStop^n", "2" );
	menu_additem( g_iButtonsMenu, "Move Up", "3" );
	menu_additem( g_iButtonsMenu, "Move Down^n", "4" );
	menu_additem( g_iButtonsMenu, "Delete Button", "5" );
	menu_additem( g_iButtonsMenu, "Delete All Buttons", "6" );
	menu_additem( g_iButtonsMenu, "Save", "7" );
}

public plugin_precache( ) {
	precache_model( g_szModel );
	
	get_mapname( g_szMapname, 31 );
	strtolower( g_szMapname );
	
	// File
	new szDatadir[ 64 ];
	get_localinfo( "amxx_datadir", szDatadir, charsmax( szDatadir ) );
	
	formatex( szDatadir, charsmax( szDatadir ), "%s/kreedz", szDatadir );
	
	if( !dir_exists( szDatadir ) )
		mkdir( szDatadir );
	
	formatex( g_szFile, charsmax( g_szFile ), "%s/KzNewButtons.ini", szDatadir );
	
	if( !file_exists( g_szFile ) ) {
		write_file( g_szFile, "// #kz.xPaw - New climb buttons", -1 );
		write_file( g_szFile, " ", -1 );
		
		return; // We dont need to load file
	}
	
	new szData[ 256 ], szMap[ 32 ], szOrigin[ 2 ][ 3 ][ 16 ];
	new iFile = fopen( g_szFile, "rt" );
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, charsmax( szData ) );
		
		if( !szData[ 0 ] || szData[ 0 ] == ';' || szData[ 0 ] == ' ' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		parse( szData, szMap, 31,
			szOrigin[ 0 ][ 0 ], 15, szOrigin[ 0 ][ 1 ], 15, szOrigin[ 0 ][ 2 ], 15, 
			szOrigin[ 1 ][ 0 ], 15, szOrigin[ 1 ][ 1 ], 15, szOrigin[ 1 ][ 2 ], 15 );
		
		if( equal( szMap, g_szMapname ) ) {
			new Float:vOrigin[ 2 ][ 3 ];
			
			vOrigin[ 0 ][ 0 ] = str_to_float( szOrigin[ 0 ][ 0 ] );
			vOrigin[ 0 ][ 1 ] = str_to_float( szOrigin[ 0 ][ 1 ] );
			vOrigin[ 0 ][ 2 ] = str_to_float( szOrigin[ 0 ][ 2 ] );
			
			vOrigin[ 1 ][ 0 ] = str_to_float( szOrigin[ 1 ][ 0 ] );
			vOrigin[ 1 ][ 1 ] = str_to_float( szOrigin[ 1 ][ 1 ] );
			vOrigin[ 1 ][ 2 ] = str_to_float( szOrigin[ 1 ][ 2 ] );
			
			CreateButton( 0, 0, vOrigin[ 0 ] );
			CreateButton( 0, 1, vOrigin[ 1 ] );
			
			break;
		}
	}
	
	fclose( iFile );
}

public CmdButtonsMenu( id ) {
	if( get_user_flags( id ) & ADMIN_RCON )
		menu_display( id, g_iButtonsMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public HandleButtonsMenu( id, iMenu, iItem ) {
	if( iItem == MENU_EXIT )
		return PLUGIN_HANDLED;
	
	new szKey[ 2 ], _Access, _Callback;
	menu_item_getinfo( iMenu, iItem, _Access, szKey, 1, "", 0, _Callback );
	
	new iKey = str_to_num( szKey );
	
	switch( iKey ) {
		case 1, 2: CreateButton( id, iKey - 1 );
		case 3: {
			new iButton = GetButton( id );
			
			if( iButton > 0 ) {
				new Float:vOrigin[ 3 ];
				entity_get_vector( iButton, EV_VEC_origin, vOrigin );
				
				vOrigin[ 2 ] += 5.0;
				
				entity_set_origin( iButton, vOrigin );
			}
		}
		case 4: {
			new iButton = GetButton( id );
			
			if( iButton > 0 ) {
				new Float:vOrigin[ 3 ];
				entity_get_vector( iButton, EV_VEC_origin, vOrigin );
				
				vOrigin[ 2 ] -= 5.0;
				
				entity_set_origin( iButton, vOrigin );
			}
		}
		case 5: {
			new iButton = GetButton( id );
			
			if( iButton > 0 ) {
				remove_entity( iButton );
				
				client_print( id, print_chat, "* Climb button has been deleted!" );
			}
		}
		case 6: {
			new iEntity, iCount, szModel[ 2 ];
			
			for( new i; i < 2; i++ ) {
				while( ( iEntity = find_ent_by_target( iEntity, g_szTargets[ i ] ) ) > 0 ) {
					entity_get_string( iEntity, EV_SZ_model, szModel, 1 );
					
					if( szModel[ 0 ] != '*' ) {
						remove_entity( iEntity );
						
						iCount++;
					}
				}
			}
			
			if( iCount )
				client_print( id, print_chat, "* All climb buttons has been deleted!" );
		}
		case 7: {
			new iEntity, iButton, szModel[ 2 ], Float:vOrigin[ 2 ][ 3 ];
			
			for( new i; i < 2; i++ ) {
				iButton = -1;
				iEntity = -1;
				
				while( ( iEntity = find_ent_by_target( iEntity, g_szTargets[ i ] ) ) > 0 ) {
					entity_get_string( iEntity, EV_SZ_model, szModel, 1 );
					
					if( szModel[ 0 ] != '*' )
						iButton = iEntity;
				}
				
				if( iButton > 0 )
					entity_get_vector( iButton, EV_VEC_origin, vOrigin[ i ] );
			}
			
			new bool:bFound, iPos, szData[ 32 ], iFile = fopen( g_szFile, "r+" );
			
			if( !iFile )
				return PLUGIN_HANDLED;
			
			while( !feof( iFile ) ) {
				fgets( iFile, szData, 31 );
				parse( szData, szData, 31 );
				
				iPos++;
				
				if( equal( szData, g_szMapname ) ) {
					bFound = true;
					
					new szString[ 256 ];
					formatex( szString, 255, "%s %f %f %f %f %f %f", g_szMapname,
					vOrigin[ 0 ][ 0 ], vOrigin[ 0 ][ 1 ], vOrigin[ 0 ][ 2 ],
					vOrigin[ 1 ][ 0 ], vOrigin[ 1 ][ 1 ], vOrigin[ 1 ][ 2 ] );
					
					write_file( g_szFile, szString, iPos - 1 );
					
					break;
				}
			}
			
			if( !bFound )
				fprintf( iFile, "%s %f %f %f %f %f %f^n", g_szMapname,
				vOrigin[ 0 ][ 0 ], vOrigin[ 0 ][ 1 ], vOrigin[ 0 ][ 2 ],
				vOrigin[ 1 ][ 0 ], vOrigin[ 1 ][ 1 ], vOrigin[ 1 ][ 2 ] );
			
			fclose( iFile );
			
			client_print( id, print_chat, "* Successfully saved climb buttons! Restart the map!" );
		}
		default: return PLUGIN_HANDLED;
	}
	
	menu_display( id, g_iButtonsMenu, 0 );
	
	return PLUGIN_HANDLED;
}

GetButton( id ) {
	new iEntity, _Body;
	get_user_aiming( id, iEntity, _Body, 4000 );
	
	if( is_valid_ent( iEntity ) ) {
		new szModel[ 2 ];
		entity_get_string( iEntity, EV_SZ_model, szModel, 1 );
		
		if( szModel[ 0 ] != '*' )
			return iEntity;
		else
			client_print( id, print_chat, "* You must aim on a climb button!" );
	} else
		client_print( id, print_chat, "* You must aim on a climb button!" );
	
	return -1;
}

CreateButton( id, iType, Float:vOrigin[ 3 ] = { 0.0, 0.0, 0.0 } ) {
	if( !id && vOrigin[ 0 ] == 0.0 && vOrigin[ 1 ] == 0.0 && vOrigin[ 2 ] == 0.0 )
		return 0;
	
	new iEntity = create_entity( "func_button" );
	
	if( !is_valid_ent( iEntity ) )
		return 0;
	
	if( id > 0 ) {
		new iOrigin[ 3 ];
		get_user_origin( id, iOrigin, 3 );
		IVecFVec( iOrigin, vOrigin );
		
		vOrigin[ 2 ] += 5.0;
		
		entity_set_origin( iEntity, vOrigin );
	} else
		entity_set_origin( iEntity, vOrigin );
	
	entity_set_string( iEntity, EV_SZ_target, g_szTargets[ iType ] );
	entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
	entity_set_model( iEntity, g_szModel );
	entity_set_size( iEntity, Float:{ -6.0, -3.0, 0.0 }, Float:{ 6.0, 3.0, 6.0 } );
	
	new Float:vColor[ 3 ]; vColor[ 1 ] = 127.0;
	
	if( iType )
		vColor[ 2 ] = 255.0;
	
	SetRendering( iEntity, kRenderFxGlowShell, vColor, kRenderNormal, 5.0 );
	
	return iEntity;
}

stock SetRendering( iEntity, iFX = kRenderFxNone, Float:vColor[ 3 ] = { 255.0, 255.0, 255.0 }, iRender = kRenderNormal, Float:flAmount = 16.0 ) {
	entity_set_int( iEntity, EV_INT_renderfx, iFX );
	entity_set_vector( iEntity, EV_VEC_rendercolor, vColor );
	entity_set_int( iEntity, EV_INT_rendermode, iRender );
	entity_set_float( iEntity, EV_FL_renderamt, flAmount );
}