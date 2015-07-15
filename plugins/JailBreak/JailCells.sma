#include < amxmodx >
#include < amxmisc >
#include < engine >

new g_iCellButton;

public plugin_init( )
{
	register_plugin( "Jail: Cells", "1.0", "xPaw" );
	
	register_concmd( "amx_open_cell", "CmdOpenCell", ADMIN_BAN );
	
	register_clcmd( "say /setcell", "CmdSetCell", ADMIN_RCON );
	
	LoadButtons( );
}

LoadButtons( )
{
	new szFile[ 128 ];
	get_localinfo( "amxx_datadir", szFile, charsmax( szFile ) );
	add( szFile, charsmax( szFile ), "/JailCellButtons.ini" );
	
	new iFile = fopen( szFile, "rt" );
	
	if( !iFile ) return;
	
	new szMap[ 32 ], szModel[ 5 ], szCurrentMap[ 32 ];
	
	get_mapname( szCurrentMap, charsmax( szCurrentMap ) );
	
	while( !feof( iFile ) )
	{
		fgets( iFile, szFile, charsmax( szFile ) );
		trim( szFile );
		
		//if( szFile[ 0 ] == ';' || ( szFile[ 0 ] == '/' && szFile[ 1 ] == '/' ) )
		//	continue;
		
		parse( szFile, szMap, charsmax( szMap ), szModel, charsmax( szModel ) );
		
		if( equali( szMap, szCurrentMap ) )
		{
			g_iCellButton = find_ent_by_model( -1, "func_button", szModel );
			
			break;
		}
	}
	
	fclose( iFile );
}

public CmdOpenCell( const id, const iLevel, const iCid )
{
	if( !cmd_access( id, iLevel, iCid, 1 ) )
	{
		return PLUGIN_HANDLED;
	}
	
	if( !g_iCellButton )
	{
		console_print( id, "No button is set for this map! Use /setcell" );
		return PLUGIN_HANDLED;
	}
	
	force_use( id, g_iCellButton );
	
	console_print( id, "Cells opened!" );
	
	set_hudmessage( 255, 127, 0, -1.0, 0.1, 0, 0.0, 1.6, 0.1, 0.1, -1 );
	show_hudmessage( 0, "Cells have been opened!" );
	
	return PLUGIN_HANDLED;
}

public CmdSetCell( const id )
{
	if( get_user_flags( id ) & ADMIN_RCON )
	{
		if( g_iCellButton )
		{
			client_print( id, print_chat, "The button is set already" );
			return;
		}
		
		new iEntity, iBody;
		get_user_aiming( id, iEntity, iBody, 400 );
		
		if( is_valid_ent( iEntity ) && IsButton( iEntity ) )
		{
			g_iCellButton = iEntity;
			
			new szModel[ 5 ];
			entity_get_string( iEntity, EV_SZ_model, szModel, charsmax( szModel ) );
			
			client_print( id, print_chat, "Got the button: %i - %s", iEntity, szModel );
			
			new szFile[ 128 ];
			get_localinfo( "amxx_datadir", szFile, charsmax( szFile ) );
			add( szFile, charsmax( szFile ), "/JailCellButtons.ini" );
			
			new iFile = fopen( szFile, "at" );
			
			if( iFile )
			{
				new szMapName[ 32 ];
				get_mapname( szMapName, charsmax( szMapName ) );
				
				formatex( szFile, charsmax( szFile ), "%s %s^n", szMapName, szModel );
				fputs( iFile, szFile );
				fclose( iFile );
			}
		}
		else
		{
			client_print( id, print_chat, "Look at the button!" );
		}
	}
}

IsButton( const iEntity )
{
	new szClassName[ 17 ];
	entity_get_string( iEntity, EV_SZ_classname, szClassName, charsmax( szClassName ) );
	
	// func_rot_button button_target
	
	return equal( szClassName, "func_button" );
}
