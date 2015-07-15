#include < amxmodx >

// Let the compiler know that we want semicolons and check the amxx version to prevent n00bz
#pragma semicolon 1

#if AMXX_VERSION_NUM < 181
	#assert Old AMXX version (AMXX_VERSION_NUM), please upgrade in order to use this plugin properly.
#endif

#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < sqlx >

#define BM_ADMIN_LEVEL ADMIN_LEVEL_G

#define m_afButtonPressed 246

#define IsUserAdmin(%1) ( get_user_flags( %1 ) & BM_ADMIN_LEVEL )
#define IsPlayer(%1)    ( 1 <= %1 <= g_iMaxPlayers )

new const CLASSNAME[ ]           = "bm_block";
new const CLASSNAME_TELEPORT[ ]  = "bm_teleport";
new const CLASSNAME_LIGHT[ ]     = "bm_light";

enum _:BlockSizes
{
	BM_SMALL = 0,
	BM_NORMAL,
	BM_LARGE
};

enum _:Forwards
{
	FV_BlockCreated,
	FV_ParamChange,
	FV_ResetPlayer,
	FV_RequestProps
};

enum _:BlockInfo
{
	Block_Name[ 32 ],
	Block_SaveName[ 32 ],
	Trie:Block_Models,
	Trie:Block_Params
};

new const g_szBlockSizeNames[ BlockSizes ][ ] =
{
	"Small",
	"Normal",
	"Large"
};

enum _:BlockAngles {
	ANGLE_NORMAL,
	ANGLE_ROTATE1,
	ANGLE_ROTATE2
};

new const Float:g_vMins[ BlockSizes ][ BlockAngles ][ 3 ] =
{
	{
		{ -8.0, -8.0, -4.0 },
		{ -4.0, -8.0, -8.0 },
		{ -8.0, -4.0, -8.0 }
	},
	{
		{ -32.0, -32.0, -4.0 },
		{ -4.0, -32.0, -32.0 },
		{ -32.0, -4.0, -32.0 }
	},
	{
		{ -64.0, -64.0, -4.0 },
		{ -4.0, -64.0, -64.0 },
		{ -64.0, -4.0, -64.0 }
	}
};

new const Float:g_vMaxs[ BlockSizes ][ BlockAngles ][ 3 ] =
{
	{
		{ 8.0, 8.0, 4.0 },
		{ 4.0, 8.0, 8.0 },
		{ 8.0, 4.0, 8.0 }
	},
	{
		{ 32.0, 32.0, 4.0 },
		{ 4.0, 32.0, 32.0 },
		{ 32.0, 4.0, 32.0 }
	},
	{
		{ 64.0, 64.0, 4.0 },
		{ 4.0, 64.0, 64.0 },
		{ 64.0, 4.0, 64.0 }
	}
};

new const Float:g_vAngles[ BlockAngles ][ 3 ] =
{
	{ 0.0, 0.0, 0.0 },
	{ 90.0, 0.0, 0.0 },
	{ 90.0, 0.0, 90.0 }
};

new Array:g_aBlocks, Trie:g_tForwards;
new g_iBlockSelectionMenu, g_iMaxPlayers;
new g_iSelectedBlock[ 33 ];
new g_iSelectedSize[ 33 ];
new g_iGrabbed[ 33 ];
new bool:g_bSnapping[ 33 ];
new Float:g_flGap[ 33 ];
new g_iForward[ Forwards ];
new g_szLogFile[ 128 ];
new Float:g_flGrabLength[ 33 ];
new Float:g_vGrabOffset[ 33 ][ 3 ];
new g_szViewModel[ 33 ][ 32 ];

new Trie:g_tSaveIds;
new g_szMapName[ 32 ];
new Handle:g_hSqlConnection;

#if !defined _fun_included
	#define get_user_noclip(%1) ( entity_get_int( %1, EV_INT_movetype ) == MOVETYPE_NOCLIP )
	
	stock get_user_godmode( const id ) {
		new Float:flVal = entity_get_float( id, EV_FL_takedamage );
		
		return ( flVal == DAMAGE_NO );
	}
	
	stock set_user_godmode( const id, iGodmode = 0 ) {
		entity_set_float( id, EV_FL_takedamage, iGodmode == 1 ? DAMAGE_NO : DAMAGE_AIM );
		
		return 1;
	}
	
	stock set_user_noclip( const id, iNoclip = 0 ) {
		entity_set_int( id, EV_INT_movetype, iNoclip == 1 ? MOVETYPE_NOCLIP : MOVETYPE_WALK );
		
		return 1;
	}
#endif

public plugin_init( ) {
	register_plugin( "BlockMaker", "1.0", "xPaw" );
	
	// Open Storage
	// ==========================================================
	if( !SQL_SetAffinity( "sqlite" ) )
		set_fail_state( "Failed to set database type to ^"sqlite^". Check your modules.ini" );
	
	//SQL_SetAffinity( "sqlite" );
	
	new szError[ 128 ], iErrorCode;
	
	new Handle:hSqlTuple = SQL_MakeDbTuple( "", "bm_api", "", "bm_api" );
	g_hSqlConnection = SQL_Connect( hSqlTuple, iErrorCode, szError, 127 );
	
	SQL_FreeHandle( hSqlTuple );
	
	if( g_hSqlConnection == Empty_Handle )
		set_fail_state( szError );
	
	// Setup tables
	// ==========================================================
	//SQL_QueryAndIgnore( g_hSqlConnection, "DROP TABLE IF EXISTS `bm_blocks`" );
	SQL_QueryAndIgnore2( g_hSqlConnection, "CREATE TABLE IF NOT EXISTS `bm_blocks` ( \
		`id` INTEGER PRIMARY KEY AUTOINCREMENT, `map` VARCHAR(32) NOT NULL, \
		`savename` VARCHAR(32) NOT NULL, `creator` VARCHAR(32) NOT NULL, \
		`template` VARCHAR(32) NOT NULL, `angles` TINYINT(1) NOT NULL, `size` TINYINT(1) NOT NULL, \
		`origin1` FLOAT(16) NOT NULL, `origin2` FLOAT(16) NOT NULL, `origin3` FLOAT(16) NOT NULL )" );
	
	/*formatex( g_szQuery, charsmax(g_szQuery),
			"CREATE TABLE IF NOT EXISTS `%s` ( \
				`id` INTEGER PRIMARY KEY AUTOINCREMENT, \
				`player_id` TEXT UNIQUE DEFAULT NULL, \
				`score` INTEGER NOT NULL DEFAULT '0', \
				`deaths` INTEGER NOT NULL DEFAULT '0', \
				`time` INTEGER NOT NULL DEFAULT '0' \
			)",
		g_Table );*/
	
	
	// Cool to see 2-3 comments in whole code, ha?
	// ==========================================================
	g_iMaxPlayers = get_maxplayers( );
	
	get_mapname( g_szMapName, 31 );
	strtolower( g_szMapName );
	
	register_clcmd( "say /bm",     "CmdBlockMaker" );
	register_clcmd( "say /bcm",    "CmdBlockMaker" );
	register_clcmd( "say /blocks", "CmdBlockMaker" );
	
	register_clcmd( "say /bmstats", "CmdStats" );
	
	register_clcmd( "+bmgrab", "CmdGrab", BM_ADMIN_LEVEL, " - bind ^"key^" +bmgrab" );
	register_clcmd( "-bmgrab", "CmdRelease", BM_ADMIN_LEVEL );
	
	register_touch( CLASSNAME, "player", "FwdBlockTouch" );
	
	register_forward( FM_CmdStart, "FwdCmdStart" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "1!0" );
	
	g_iForward[ FV_ParamChange ]  = CreateMultiForward( "BM_ParamChange", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING );
	g_iForward[ FV_BlockCreated ] = CreateMultiForward( "BM_BlockCreated", ET_IGNORE, FP_CELL, FP_CELL );
	g_iForward[ FV_ResetPlayer ]  = CreateMultiForward( "BM_ResetPlayer", ET_IGNORE, FP_CELL );
	g_iForward[ FV_RequestProps ] = CreateMultiForward( "BM_RequestProps", ET_IGNORE, FP_CELL, FP_CELL );
	
	set_task( 5.0, "Task_LoadBlocks" );
}

public CmdStats( const id ) {
	new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT COUNT(*) FROM `bm_blocks` WHERE `map` = '%s'", g_szMapName );
	
	if( !SQL_Execute( hQuery ) ) {
		new szError[ 256 ];
		SQL_QueryError( hQuery, szError, 255 );
		
		BM_Log( "[SQL] %s", szError );
		
		SQL_FreeHandle( hQuery );
		
		return;
	}
	
	client_print( id, print_chat, "%i blocks in the database", SQL_ReadResult( hQuery, 0 ) );
	
	SQL_FreeHandle( hQuery );
}

public plugin_cfg( ) {
	new Block_Data[ BlockInfo ], szNum[ 3 ], iArraySize = ArraySize( g_aBlocks );
	
	g_iBlockSelectionMenu = menu_create( "Block Selection\R", "HandleBlockSelection" );
	
	for( new i; i < iArraySize; i++ ) {
		ArrayGetArray( g_aBlocks, i, Block_Data );
		
		num_to_str( i, szNum, 2 );
		
		menu_additem( g_iBlockSelectionMenu, Block_Data[ Block_Name ], szNum );
	}
	
	menu_setprop( g_iBlockSelectionMenu, MPROP_EXITNAME, "Back" );
}

public plugin_natives( ) {
	register_library( "BlockMaker" );
	
	register_native( "BM_RegisterBlock",      "NativeRegisterBlock" );
	register_native( "BM_RegisterTouch",      "NativeRegisterTouch" );
	register_native( "BM_RegisterParam",      "NativeRegisterParam" );
	
	register_native( "BM_PrecacheModel",      "NativePrecacheModel" );
	//register_native( "BM_GetBlockGrabber",    "GetBlockGrabber" );
}

public plugin_precache( ) {
	g_aBlocks   = ArrayCreate( BlockInfo );
	g_tForwards = TrieCreate( );
	g_tSaveIds  = TrieCreate( );
	
	new szDate[ 16 ];
	get_localinfo( "amxx_basedir", g_szLogFile, 127 );
	get_time( "%m_%d", szDate, 15 );
	format( g_szLogFile, 127, "%s/logs/blockmaker_%s.log", g_szLogFile, szDate );
}

public plugin_end( ) {
	new Block_Data[ BlockInfo ], iArraySize = ArraySize( g_aBlocks );
	
	for( new i; i < iArraySize; i++ ) {
		ArrayGetArray( g_aBlocks, i, Block_Data );
		
		if( Block_Data[ Block_Models ] )
			TrieDestroy( Block_Data[ Block_Models ] );
		
		if( Block_Data[ Block_Params ] )
			TrieDestroy( Block_Data[ Block_Params ] );
	}
	
	SQL_FreeHandle( g_hSqlConnection );
	ArrayDestroy( g_aBlocks );
	TrieDestroy( g_tForwards );
	TrieDestroy( g_tSaveIds );
}

// NATIVES
//////////////////////////////////////////////////////////////
public NativeRegisterBlock( const iPlugin, const iParams ) {
	new Block_Data[ BlockInfo ], iPos = ArraySize( g_aBlocks );
	get_string( 1, Block_Data[ Block_Name ], charsmax( Block_Data[ Block_Name ] ) );
	get_string( 2, Block_Data[ Block_SaveName ], charsmax( Block_Data[ Block_SaveName ] ) );
	
	ArrayPushArray( g_aBlocks, Block_Data );
	
	TrieSetCell( g_tSaveIds, Block_Data[ Block_SaveName ], iPos );
	
	return iPos;
}

public NativeRegisterTouch( const iPlugin, const iParams ) {
	new szForward[ 32 ], iPointer = get_param( 1 );
	get_string( 2, szForward, 31 );
	
	new iForward = CreateOneForward( iPlugin, szForward, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
	
	new szBlock[ 2 ]; szBlock[ 0 ] = iPointer;
	TrieSetCell( g_tForwards, szBlock, iForward );
}

public NativeRegisterParam( const iPlugin, const iParams ) {
	new Block_Data[ BlockInfo ], szParam[ 32 ], szValue[ 16 ], iPointer = get_param( 1 );
	get_string( 2, szParam, 31 );
	get_string( 3, szValue, 15 );
	
	ArrayGetArray( g_aBlocks, iPointer, Block_Data );
	
	if( !Block_Data[ Block_Params ] )
		Block_Data[ Block_Params ] = _:TrieCreate( );
	
	TrieSetString( Block_Data[ Block_Params ], szParam, szValue );
	
	ArraySetArray( g_aBlocks, iPointer, Block_Data );
}

public NativePrecacheModel( const iPlugin, const iParams ) {
	new Block_Data[ BlockInfo ], szModel[ 64 ], iPointer = get_param( 1 );
	get_string( 3, szModel, 63 );
	
	ArrayGetArray( g_aBlocks, iPointer, Block_Data );
	
	if( !Block_Data[ Block_Models ] )
		Block_Data[ Block_Models ] = _:TrieCreate( );
	
	new iSize = get_param( 2 );
	
	TrieSetString( Block_Data[ Block_Models ], g_szBlockSizeNames[ iSize ], szModel );
	
	ArraySetArray( g_aBlocks, iPointer, Block_Data );
	
	if( file_exists( szModel ) ) {
		precache_model( szModel );
	} else {
		new szPlugin[ 32 ];
		get_plugin( iPlugin, szPlugin, 31 );
		
		BM_Log( "[%s] Model is not found <%s><%s><^"%s^">", szPlugin, Block_Data[ Block_SaveName ], g_szBlockSizeNames[ iSize ], szModel );
	}
}

//
//////////////////////////////////////////////////////////////
public EventCurWeapon( const id ) {
	if( g_iGrabbed[ id ] ) {
		entity_get_string( id, EV_SZ_viewmodel, g_szViewModel[ id ], 31 );
		entity_set_string( id, EV_SZ_viewmodel, "" );
	}
}

public CmdGrab( const id ) {
	if( !IsUserAdmin( id ) )
		return PLUGIN_HANDLED;
	
	new iEntity, iBody;
	g_flGrabLength[ id ] = get_user_aiming( id, iEntity, iBody );
	
	if( !is_valid_ent( iEntity ) )
		return PLUGIN_HANDLED;
	
	new iGrabber = GetBlockGrabber( iEntity );
	
	if( iGrabber == 0 || iGrabber == id ) {
		if( IsBlock( iEntity ) ) {
			new iPlayer = GetBlockGrouper( iEntity );
			
			if( iPlayer == 0 || iPlayer == id ) {
				SetGrabbed( id, iEntity );
				
				//if this block is in this players group and group count is greater than 1
				/*	if (player == id && gGroupCount[id] > 1)
					{
							new Float:vGrabbedOrigin[3];
							new Float:vOrigin[3];
							new Float:vOffset[3];
							new block;
							
							//get origin of the block
							entity_get_vector(ent, EV_VEC_origin, vGrabbedOrigin);
							
							//iterate through all blocks in players group
							for (new i = 0; i < gGroupCount[id]; ++i)
							{
								block = gGroupedBlocks[id][i];
								
								//if block is still valid
								if (is_valid_ent(block))
								{
									player = GetObjectGrouper(block);
									
									//if block is still in this players group
									if (player == id)
									{
										//get origin of block in players group
										entity_get_vector(block, EV_VEC_origin, vOrigin);
										
										//calculate offset from grabbed block
										vOffset[0] = vGrabbedOrigin[0] - vOrigin[0];
										vOffset[1] = vGrabbedOrigin[1] - vOrigin[1];
										vOffset[2] = vGrabbedOrigin[2] - vOrigin[2];
										
										//save offset value in grouped block
										entity_set_vector(block, EV_VEC_vuser1, vOffset);
									}
								}
							}
				}*/
			}
		}
		else if( IsTeleport( iEntity ) || IsLight( iEntity ) ) {
			SetGrabbed( id, iEntity );
		}
	}
	
	return PLUGIN_HANDLED;
}

SetGrabbed( const id, const iEntity ) {
	new Float:vOrigin[ 3 ], iAiming[ 3 ];
	
	entity_get_string( id, EV_SZ_viewmodel, g_szViewModel[ id ], 31 );
	entity_set_string( id, EV_SZ_viewmodel, "" );
	
	get_user_origin( id, iAiming, 3 );
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	
	g_iGrabbed[ id ] = iEntity;
	g_vGrabOffset[ id ][ 0 ] = vOrigin[ 0 ] - iAiming[ 0 ];
	g_vGrabOffset[ id ][ 1 ] = vOrigin[ 1 ] - iAiming[ 1 ];
	g_vGrabOffset[ id ][ 2 ] = vOrigin[ 2 ] - iAiming[ 2 ];
}

public CmdRelease( const id ) {
	if( !IsUserAdmin( id ) || !g_iGrabbed[ id ] )
		return PLUGIN_HANDLED;
	
	
	entity_set_string( id, EV_SZ_viewmodel, g_szViewModel[ id ] );
	
	g_iGrabbed[ id ] = 0;
	
	return PLUGIN_HANDLED;
}

MoveGrabbedEntity( const id, Float:vMoveTo[ 3 ] = { 0.0, 0.0, 0.0 } ) {
	new iOrigin[ 3 ], iAiming[ 3 ], Float:vOrigin[ 3 ], Float:vAiming[ 3 ];
	new Float:vDirection[ 3 ], Float:flLength;
	
	get_user_origin( id, iOrigin, 1 );
	get_user_origin( id, iAiming, 3 );
	IVecFVec( iOrigin, vOrigin );
	IVecFVec( iAiming, vAiming );
	
	vDirection[ 0 ] = vAiming[ 0 ] - vOrigin[ 0 ];
	vDirection[ 1 ] = vAiming[ 1 ] - vOrigin[ 1 ];
	vDirection[ 2 ] = vAiming[ 2 ] - vOrigin[ 2 ];
	
	flLength = get_distance_f( vAiming, vOrigin );
	
	if( flLength == 0.0 )
		flLength = 1.0;
	
	vMoveTo[ 0 ] = ( vOrigin[ 0 ] + vDirection[ 0 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 0 ];
	vMoveTo[ 1 ] = ( vOrigin[ 1 ] + vDirection[ 1 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 1 ];
	vMoveTo[ 2 ] = ( vOrigin[ 2 ] + vDirection[ 2 ] * g_flGrabLength[ id ] / flLength ) + g_vGrabOffset[ id ][ 2 ];
	vMoveTo[ 2 ] = float( floatround( vMoveTo[ 2 ], floatround_floor ) );
	
	MoveEntity( id, g_iGrabbed[ id ], vMoveTo, true );
}

MoveEntity( const id, const iEntity, Float:vMoveTo[ 3 ], bool:bDoSnapping ) {
	// Todo remove funcs, and retrieve classname once instead.
	
	if( IsBlock( id ) || IsLight( id ) ) {
		if( bDoSnapping )
			DoSnapping( id, iEntity, vMoveTo );
		
		entity_set_origin( iEntity, vMoveTo );
		
		new iSprite = entity_get_int( iEntity, EV_INT_iuser1 );
		
		if( iSprite ) { 
			new Float:vMaxs[ 3 ];
			entity_get_vector( iEntity, EV_VEC_maxs, vMaxs );
			
			vMoveTo[ 2 ] += vMaxs[ 2 ] + 0.15;
			entity_set_origin( iSprite, vMoveTo );
		}
	} else {
		entity_set_origin( iEntity, vMoveTo );
	}
}

//
//////////////////////////////////////////////////////////////
public FwdCmdStart( const id, const iUcHandle, const iSeed ) {
	if( !is_user_alive( id ) )
		return;
	
	if( !g_iGrabbed[ id ] ) {
		if( get_pdata_int( id, m_afButtonPressed ) & IN_USE ) {
			static Float:flGametime, Float:flLastUse[ 33 ];
			flGametime = get_gametime( );
			
			if( flLastUse[ id ] < flGametime ) {
				flLastUse[ id ] = flGametime + 0.5;
				
				static iEntity, iBody;
				get_user_aiming( id, iEntity, iBody, 2000 );
				
				if( is_valid_ent( iEntity ) && IsBlock( iEntity ) ) {
					new szCreator[ 32 ], szBlock[ 32 ], iBlockType = entity_get_int( iEntity, EV_INT_body );
					GetCreatorName( iEntity, szCreator, 31 );
					GetBlockNameById( iBlockType, szBlock, 31 );
					
					new iReturn;
					ExecuteForward( g_iForward[ FV_RequestProps ], iReturn, iEntity, iBlockType );
					
					set_hudmessage( 0, 100, 255, 0.02, 0.25, 0, 2.0, 2.0, 0.4, 0.4, 4 );
					show_hudmessage( id, "%s^nCreated by: %s", szBlock, szCreator );
				}
			}
		}
	} else {
		if( !is_valid_ent( g_iGrabbed[ id ] ) ) {
			CmdRelease( id );
		} else {
			new iButtons    = get_uc( iUcHandle, UC_Buttons ),
				iOldButtons = get_user_oldbutton( id );
			
			if( iButtons & IN_ATTACK && ~iOldButtons & IN_ATTACK ) {
				set_uc( iUcHandle, UC_Buttons, iButtons & ~IN_ATTACK );
				
				client_print( id, print_chat, "We should copy the block now" );
			}
			else if( iButtons & IN_ATTACK2 && ~iOldButtons & IN_ATTACK2 ) {
				set_uc( iUcHandle, UC_Buttons, iButtons & ~IN_ATTACK2 );
				
				client_print( id, print_chat, "We should delete the block now" );
			}
			
			if( iButtons & IN_JUMP && ~iOldButtons & IN_DUCK ) {
				if( g_flGrabLength[ id ] > 72.0 )
					g_flGrabLength[ id ] -= 16.0;
			}
			else if( iButtons & IN_DUCK && ~iOldButtons & IN_DUCK )
				g_flGrabLength[ id ] += 16.0;
			
			MoveGrabbedEntity( id );
		}
	}
}

public client_putinserver( id ) {
	g_flGrabLength[ id ]   = 0.0;
	g_flGap[ id ]          = 0.0;
	g_iGrabbed[ id ]       = 0;
	g_iSelectedBlock[ id ] = 0;
	g_iSelectedSize[ id ]  = BM_NORMAL;
	g_bSnapping[ id ]      = true;
}

public client_disconnect( id )
	g_iGrabbed[ id ] = 0;

public CmdBlockMaker( const id ) {
	new iMenu = menu_create( "\rBlock Maker \yby xPaw", "HandleMainMenu" );
	
	menu_additem( iMenu, "Block Menu", "1", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dTeleport Menu", "2", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dLight Menu^n", "3", BM_ADMIN_LEVEL );
	
	new szItem[ 32 ];
	formatex( szItem, 31, "Noclip: %s", get_user_noclip( id ) ? "\yOn" : "\rOff" );
	menu_additem( iMenu, szItem, "4", BM_ADMIN_LEVEL );
	
	formatex( szItem, 31, "Godmode: %s^n", get_user_godmode( id ) ? "\yOn" : "\rOff" );
	menu_additem( iMenu, szItem, "5", BM_ADMIN_LEVEL );
	
	menu_additem( iMenu, "Save/Load Menu", "6", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dOptions Menu", "7", BM_ADMIN_LEVEL );
	
	menu_display( id, iMenu );
	
	return PLUGIN_HANDLED;
}

public HandleMainMenu( const id, const iMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	new szKey[ 4 ], iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, szKey, 3, _, _, iTrash );
	menu_destroy( iMenu );
	
	switch( szKey[ 0 ] ) {
		case '1': ShowBlockMenu( id );
		case '2': CmdBlockMaker( id ); // Teleport
		case '3': CmdBlockMaker( id ); // Light
		case '4': {
			set_user_noclip( id, !get_user_noclip( id ) );
			
			CmdBlockMaker( id );
		}
		case '5': {
			set_user_godmode( id, !get_user_godmode( id ) );
			
			CmdBlockMaker( id );
		}
		case '6': ShowSaveLoadMenu( id );
		case '7': CmdBlockMaker( id ); // Options
	}
}

public ShowBlockMenu( const id ) {
	new szItem[ 32 ], iMenu = menu_create( "\rBlock Menu", "HandleBlockMenu" );
	
	GetBlockNameById( g_iSelectedBlock[ id ], szItem, 31 );
	format( szItem, 31, "Block Type: \y%s", szItem );
	menu_additem( iMenu, szItem, "1" );
	
	formatex( szItem, 31, "Block Size: \y%s^n", g_szBlockSizeNames[ g_iSelectedSize[ id ] ] );
	menu_additem( iMenu, szItem, "2" );
	
	menu_additem( iMenu, "Create Block",   "3", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "Convert Block",  "4", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "Remove Block",   "5", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "Rotate Block^n", "6", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dSet Properties", "7", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dOptions Menu^n",   "8", BM_ADMIN_LEVEL );
	menu_addblank( iMenu, 1 );
	menu_additem( iMenu, "Main Menu", "*", BM_ADMIN_LEVEL );
	menu_setprop( iMenu, MPROP_PERPAGE, 0 );
	menu_setprop( iMenu, MPROP_EXITNAME, "Main Menu" );
	
	menu_display( id, iMenu );
	
	return PLUGIN_HANDLED;
}

public HandleBlockMenu( const id, const iMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		CmdBlockMaker( id );
		
		return;
	}
	
	new szKey[ 4 ], iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, szKey, 3, _, _, iTrash );
	menu_destroy( iMenu );
	
	switch( szKey[ 0 ] ) {
		case '1': menu_display( id, g_iBlockSelectionMenu );
		case '2': {
			switch( g_iSelectedSize[ id ] ) {
				case BM_SMALL : g_iSelectedSize[ id ] = BM_NORMAL;
				case BM_NORMAL: g_iSelectedSize[ id ] = BM_LARGE;
				case BM_LARGE : g_iSelectedSize[ id ] = BM_SMALL;
			}
			
			ShowBlockMenu( id );
		}
		case '3': {
			CreateBlockAiming( id );
			
			ShowBlockMenu( id );
		}
		case '4': {
			ConvertBlockAiming( id );
			
			ShowBlockMenu( id );
		}
		case '5': {
			DeleteBlockAiming( id );
			
			ShowBlockMenu( id );
		}
		case '6': ShowBlockMenu( id ); // Rotate
		case '7': ShowBlockMenu( id ); // Set props
		case '8': ShowBlockMenu( id ); // Options
		case '*': CmdBlockMaker( id );
	}
}

public HandleBlockSelection( const id, const iMenu, const iItem ) {
	if( iItem != MENU_EXIT ) {
		new szKey[ 4 ], iTrash;
		menu_item_getinfo( iMenu, iItem, iTrash, szKey, 3, _, _, iTrash );
		
		g_iSelectedBlock[ id ] = str_to_num( szKey );
	}
	
	ShowBlockMenu( id );
}

public ShowSaveLoadMenu( const id ) {
	new iMenu = menu_create( "\rSave/Load Menu", "HandleSaveLoadMenu" );
	
	menu_additem( iMenu, "Save Blocks", "1", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "Load Blocks^n", "2", BM_ADMIN_LEVEL );
	
	menu_additem( iMenu, "Delete all blocks", "5", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dDelete all teleports", "6", BM_ADMIN_LEVEL );
	menu_additem( iMenu, "\dDelete all lights^n", "7", BM_ADMIN_LEVEL );
	
//	menu_addblank( iMenu, 1 );
//	menu_additem( iMenu, "Main Menu", "*", BM_ADMIN_LEVEL );
//	menu_setprop( iMenu, MPROP_PERPAGE, 0 );
	menu_setprop( iMenu, MPROP_EXITNAME, "Main Menu" );
	
	menu_display( id, iMenu );
	
	return PLUGIN_HANDLED;
}

public HandleSaveLoadMenu( const id, const iMenu, const iItem ) {
	if( iItem == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		CmdBlockMaker( id );
		
		return;
	}
	
	new szKey[ 4 ], iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, szKey, 3, _, _, iTrash );
	menu_destroy( iMenu );
	
	switch( szKey[ 0 ] ) {
		case '1': {
			ShowSaveLoadMenu( id );
			
			// Delete all blocks from database first
			new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, "DELETE * FROM `bm_blocks` WHERE `map` = '%s'", g_szMapName );
			
			if( !SQL_Execute( hQuery ) ) {
				new szError[ 256 ];
				SQL_QueryError( hQuery, szError, 255 );
				
				BM_Log( "[SQL] %s", szError );
				
				SQL_FreeHandle( hQuery );
				
				client_print( id, print_chat, "[BM] Failed to clean the database, so can't save blocks." );
				
				return;
			}
			
			SQL_FreeHandle( hQuery );
			
			// Save Blocks
			new iEntity = g_iMaxPlayers + 1;
			new szCreator[ 32 ], szBlock[ 32 ];
			new Float:vOrigin[ 3 ], iBlocks;
			
			while( ( iEntity = find_ent_by_class( iEntity, CLASSNAME ) ) ) {
				GetCreatorName( iEntity, szCreator, 31 );
				GetBlockSaveNameById( entity_get_int( iEntity, EV_INT_body ), szBlock, 31 );
				
				entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
				
				SQL_QueryAndIgnore2( g_hSqlConnection, "INSERT INTO `bm_blocks` VALUES (null, '%s', '%s', '%s', 'default', '%i', '%i', '%f', '%f', '%f');",
					g_szMapName, szBlock, szCreator, GetBlockAngle( iEntity ), GetBlockSize( iEntity ), vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
				
				iBlocks++;
			}
			
			client_print( id, print_chat, "Saved %i blocks", iBlocks );
		}
		case '2': {
			client_print( id, print_chat, "Load blocks? Nope." );
			
			ShowSaveLoadMenu( id );
		}
		case '5': ShowSaveLoadMenu( id ); // Blocks
		case '6': ShowSaveLoadMenu( id ); // Teleports
		case '7': ShowSaveLoadMenu( id ); // Lights
		//case '*': CmdBlockMaker( id );
	}
}

//
//////////////////////////////////////////////////////////////
public FwdBlockTouch( const iBlock, const id ) {
	if( !is_valid_ent( iBlock ) || !is_user_alive( id ) )
		return PLUGIN_CONTINUE;
	
	static szBlock[ 2 ], iForward;
	szBlock[ 0 ] = entity_get_int( iBlock, EV_INT_body );
	
	if( !TrieGetCell( g_tForwards, szBlock, iForward ) )
		return PLUGIN_CONTINUE;
	
	static iReturn;
	ExecuteForward( iForward, iReturn, iBlock, id, szBlock[ 0 ], ( ( pev( id, pev_flags ) & FL_ONGROUND ) && pev( id, pev_groundentity ) == iBlock ) );
	
	return PLUGIN_CONTINUE;
}

//
//////////////////////////////////////////////////////////////
DeleteBlockAiming( const id ) {
	if( !IsUserAdmin( id ) )
		return;
	
	new iEntity, iBody;
	get_user_aiming( id, iEntity, iBody );
	
	if( is_valid_ent( iEntity ) && IsBlock( iEntity ) ) {
		new iGrabber = GetBlockGrabber( iEntity );
		
		if( iGrabber == 0 || iGrabber == id ) {
			remove_entity( iEntity );
			
			g_iGrabbed[ id ] = 0;
		}
	}
}

ConvertBlockAiming( const id ) {
	if( !IsUserAdmin( id ) )
		return;
	
	
}

CreateBlockAiming( const id ) {
	if( !IsUserAdmin( id ) )
		return;
	
	new iOrigin[ 3 ], Float:vOrigin[ 3 ], szName[ 32 ];
	get_user_origin( id, iOrigin, 3 );
	get_user_name( id, szName, 31 );
	IVecFVec( iOrigin, vOrigin );
	
	vOrigin[ 0 ] += g_vMaxs[ g_iSelectedSize[ id ] ][ ANGLE_NORMAL ][ 2 ];
	
	CreateBlock( id, g_iSelectedBlock[ id ], vOrigin, ANGLE_NORMAL, g_iSelectedSize[ id ], szName );
}

public Task_LoadBlocks( ) {
	new Handle:hQuery = SQL_PrepareQuery( g_hSqlConnection, "SELECT * FROM `bm_blocks` WHERE `map` = '%s'", g_szMapName );
	
	if( !SQL_Execute( hQuery ) ) {
		new szError[ 256 ];
		SQL_QueryError( hQuery, szError, 255 );
		
		BM_Log( "[SQL] %s", szError );
		
		SQL_FreeHandle( hQuery );
		
		return;
	}
	
	new Float:vOrigin[ 3 ], szBlock[ 32 ], iBlockType;
	
	while( SQL_MoreResults( hQuery ) ) {
		SQL_ReadResult( hQuery, 2, szBlock, 31 );
		
		if( TrieGetCell( g_tSaveIds, szBlock, iBlockType ) ) {
			SQL_ReadResult( hQuery, 3, szBlock, 31 );
			
			SQL_ReadResult( hQuery, 7, vOrigin[ 0 ] );
			SQL_ReadResult( hQuery, 8, vOrigin[ 1 ] );
			SQL_ReadResult( hQuery, 9, vOrigin[ 2 ] );
			
			CreateBlock( 0, iBlockType, vOrigin, SQL_ReadResult( hQuery, 5 ), SQL_ReadResult( hQuery, 6 ), szBlock );
		} else
			BM_Log( "[%s] Wrong block: %s", g_szMapName, szBlock );
		
		SQL_NextRow( hQuery );
	}
	
	SQL_FreeHandle( hQuery );
}

CreateBlock( const id, const iBlockType, Float:vOrigin[ 3 ], const iAxis, const iSize, const szCreator[ ] ) {
	static const INFO_TARGET[ ] = "info_target";
	
	new iEntity = create_entity( INFO_TARGET );
	
	if( !is_valid_ent( iEntity ) )
		return 0;
	
	entity_set_string( iEntity, EV_SZ_classname, CLASSNAME );
	entity_set_string( iEntity, EV_SZ_netname, szCreator );
	entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_NONE );
	entity_set_int( iEntity, EV_INT_body, iBlockType );
	
	new Block_Data[ BlockInfo ], szModel[ 64 ];
	ArrayGetArray( g_aBlocks, iBlockType, Block_Data );
	TrieGetString( Block_Data[ Block_Models ], g_szBlockSizeNames[ iSize ], szModel, 63 );
	
	entity_set_model( iEntity, szModel );
	entity_set_vector( iEntity, EV_VEC_angles, g_vAngles[ iAxis ] );
	entity_set_size( iEntity, g_vMins[ iSize ][ iAxis ], g_vMaxs[ iSize ][ iAxis ] );
	
	if( IsPlayer( id ) )
		DoSnapping( id, iEntity, vOrigin );
	
	entity_set_origin( iEntity, vOrigin );
	
	new iReturn;
	ExecuteForward( g_iForward[ FV_BlockCreated ], iReturn, iEntity, iBlockType );
	
//	SetBlockRender( iEntity, Block_Data[ Block_RenderFx ], Block_Data[ Block_RenderColor ], Block_Data[ Block_RenderMode ], Block_Data[ Block_RenderAmt ] ] );
	
	return iEntity;
}

DoSnapping( const id, const iEntity, Float:vMoveTo[ 3 ] ) {
	if( !g_bSnapping[ id ] )
		return;
	
	new Float:flSnapSizeGap = 10.0 + g_flGap[ id ];
	new Float:flDist, Float:flDistOld = 9999.9, iTr, iTrClosest;
	new Float:vReturn[ 3 ], Float:vStart[ 3 ], Float:vEnd[ 3 ];
	new Float:vMins[ 3 ], Float:vMaxs[ 3 ], iBlockFace;
	
	entity_get_vector( iEntity, EV_VEC_mins, vMins );
	entity_get_vector( iEntity, EV_VEC_maxs, vMaxs );
	
	for( new i; i < 6; i++ ) {
		vStart = vMoveTo;
		
		switch( i ) {
			case 0: vStart[ 0 ] += vMins[ 0 ];
			case 1: vStart[ 0 ] += vMaxs[ 0 ];
			case 2: vStart[ 1 ] += vMins[ 1 ];
			case 3: vStart[ 1 ] += vMaxs[ 1 ];
			case 4: vStart[ 2 ] += vMins[ 2 ];
			case 5: vStart[ 2 ] += vMaxs[ 2 ];
		}
		
		vEnd = vStart;
		
		switch( i ) {
			case 0: vEnd[ 0 ] -= flSnapSizeGap;
			case 1: vEnd[ 0 ] += flSnapSizeGap;
			case 2: vEnd[ 1 ] -= flSnapSizeGap;
			case 3: vEnd[ 1 ] += flSnapSizeGap;
			case 4: vEnd[ 2 ] -= flSnapSizeGap;
			case 5: vEnd[ 2 ] += flSnapSizeGap;
		}
		
		iTr = trace_line( iEntity, vStart, vEnd, vReturn );
		
		if( is_valid_ent( iTr ) && IsBlock( iTr ) /* && (!isBlockInGroup(id, tr) || !isBlockInGroup(id, ent)) */ ) {
			flDist = get_distance_f( vStart, vReturn );
			
			if( flDist < flDistOld ) {
				iTrClosest = iTr;
				flDistOld  = flDist;
				iBlockFace = i;
			}
		}
	}
	
	if( is_valid_ent( iTrClosest ) ) {
		new Float:vOrigin[ 3 ], Float:vMins2[ 3 ], Float:vMaxs2[ 3 ];
		entity_get_vector( iTrClosest, EV_VEC_origin, vOrigin );
		entity_get_vector( iTrClosest, EV_VEC_mins, vMins2 );
		entity_get_vector( iTrClosest, EV_VEC_maxs, vMaxs2 );
		
		vMoveTo = vOrigin;
		
		switch( iBlockFace ) {
			case 0: vMoveTo[ 0 ] += ( vMaxs2[ 0 ] + vMaxs[ 0 ] ) + flSnapSizeGap;
			case 1: vMoveTo[ 0 ] += ( vMins2[ 0 ] + vMins[ 0 ] ) - flSnapSizeGap;
			case 2: vMoveTo[ 1 ] += ( vMaxs2[ 1 ] + vMaxs[ 1 ] ) + flSnapSizeGap;
			case 3: vMoveTo[ 1 ] += ( vMins2[ 1 ] + vMins[ 1 ] ) - flSnapSizeGap;
			case 4: vMoveTo[ 2 ] += ( vMaxs2[ 2 ] + vMaxs[ 2 ] ) + flSnapSizeGap;
			case 5: vMoveTo[ 2 ] += ( vMins2[ 2 ] + vMins[ 2 ] ) - flSnapSizeGap;
		}
	}
}

//
//////////////////////////////////////////////////////////////
GetCreatorName( const iEntity, szCreator[ ], iLen = sizeof( szCreator ) ) {
	entity_get_string( iEntity, EV_SZ_netname, szCreator, iLen );
	
	if( szCreator[ 0 ] == '^0' )
		copy( szCreator, iLen, "Unknown" );
}

GetBlockNameById( const iPointer, szName[ ], iLen ) {
	new Block_Data[ BlockInfo ];
	ArrayGetArray( g_aBlocks, iPointer, Block_Data );
	
	copy( szName, iLen, Block_Data[ Block_Name ] );
}

GetBlockSaveNameById( const iPointer, szName[ ], iLen ) {
	new Block_Data[ BlockInfo ];
	ArrayGetArray( g_aBlocks, iPointer, Block_Data );
	
	copy( szName, iLen, Block_Data[ Block_SaveName ] );
}

public GetBlockGrabber( const iEntity ) {
	for( new i = 1; i <= g_iMaxPlayers; i++ )
		if( g_iGrabbed[ i ] == iEntity && GetBlockGrouper( iEntity ) == i )
			return i;
	
	return 0;
}

GetBlockGrouper( const iEntity ) {
	
/*	if( isTeleport(ent) ) return 0;
	
	for( new client = 1; client <= g_max_clients; client++ )
	{
		if( !g_connected[client] ) continue;
		
		for( new i = 0; i < gGroupCount[client]; i++ )
		{
			if( gGroupedBlocks[client][i] == ent )
			{
				return client;
			}
		}
	}*/
	
	return ( iEntity == 1337 ) ? 0 : 0;
}

GetBlockSize( const iEntity ) {
	new iSize, iAngle, Float:vMaxs[ 3 ];
	entity_get_vector( iEntity, EV_VEC_maxs, vMaxs );
	
	for( iSize = 0; iSize < BlockSizes; iSize++ ) {
		for( iAngle = 0; iAngle < BlockAngles; iAngle++ ) {
			if( g_vMaxs[ iSize ][ iAngle ][ 0 ] == vMaxs[ 0 ]
			&&  g_vMaxs[ iSize ][ iAngle ][ 1 ] == vMaxs[ 1 ]
			&&  g_vMaxs[ iSize ][ iAngle ][ 2 ] == vMaxs[ 2 ] )
				return iSize;
		}
	}
	
	return 0;
}

GetBlockAngle( const iEntity ) {
	new iAngle, Float:vAngles[ 3 ];
	entity_get_vector( iEntity, EV_VEC_angles, vAngles );
	
	for( iAngle = 0; iAngle < BlockAngles; iAngle++ ) {
		if( g_vAngles[ iAngle ][ 0 ] == vAngles[ 0 ]
		&&  g_vAngles[ iAngle ][ 1 ] == vAngles[ 1 ]
		&&  g_vAngles[ iAngle ][ 2 ] == vAngles[ 2 ] )
			return iAngle;
	}
	
	return 0;
}

bool:IsBlock( const iEntity ) {
	new szClassName[ 16 ];
	entity_get_string( iEntity, EV_SZ_classname, szClassName, 15 );
	
	return bool:equal( szClassName, CLASSNAME );
}

bool:IsTeleport( const iEntity ) {
	new szClassName[ 16 ];
	entity_get_string( iEntity, EV_SZ_classname, szClassName, 15 );
	
	return bool:equal( szClassName, CLASSNAME_TELEPORT );
}

bool:IsLight( const iEntity ) {
	new szClassName[ 16 ];
	entity_get_string( iEntity, EV_SZ_classname, szClassName, 15 );
	
	return bool:equal( szClassName, CLASSNAME_LIGHT );
}

BM_Log( const szFmt[ ], any:... ) {
	new szString[ 512 ], szTime[ 32 ];
	vformat( szString, 511, szFmt, 2 );
	get_time( "%m/%d/%Y - %H:%M:%S", szTime, 31 );
	
	server_cmd( "echo [BM] %s: %s", szTime, szString );
	
	new iFile = fopen( g_szLogFile, "a" );
	fprintf( iFile, "L %s: %s^n", szTime, szString );
	fclose( iFile );
}

stock SQL_QueryAndIgnore2( Handle:db, const queryfmt[ ], any:... ) {
	static query[4096];
	new Handle:hQuery;
	new ret;
	
	vformat(query, sizeof(query)-1, queryfmt, 3);
	hQuery = SQL_PrepareQuery(db, "%s", query);
	
	if (SQL_Execute(hQuery))
	{
		ret = SQL_AffectedRows(hQuery);
	} else {
		ret = -1;
		
		new szError[ 256 ];
		SQL_QueryError( hQuery, szError, 255 );
		
		BM_Log( "[SQL] %s", szError );
	}
	
	SQL_FreeHandle(hQuery);
	
	return ret;
}
