#include < amxmodx >
#include < amxmisc >
#include < fun >
#include < engine >
#include < cstrike >
#include < hamsandwich >
#include < fakemeta >
#include < orpheu_stocks >
#include < orpheu_memory >

const m_pPlayer = 41;

new const func_bomb_target[ ] = "func_bomb_target";

/*
	[+] Small bomb explode radius
	[+] Block plant of bomb more than one on same plant
	[-] Do not kill team mates with bomb
	[-] Show death messages of killed bomb (+ frags aswell)
	[-] Extend round time on bomb explode
	[-] Round start spawns are on normal spawns, later use CSDM spawns
	[-] All round weapons same as buyed
	[-] End round on both bombs explode
	[-] Anything about team switching ?
	[-] If player plants and other plants at same time, they plant 2 bombs
	[-] Give bomb to user who planted it
*/

new g_iMsgShowTimer, g_iBombPlants[ 2 ];
new g_szConfigFile[ 96 ], g_iBombs[ 2 ];
new bool:g_bBombExploded[ 2 ];
new bool:g_bBombPlanted[ 2 ];
new Float:g_flExplodeAt[ 2 ];
new g_pGameRules;

public plugin_init( ) {
	register_plugin( "Demolition", "1.0", "xPaw" );
	
	if( !find_ent_by_class( -1, func_bomb_target ) )
		pause( "a" );
	
	register_clcmd( "set_bomb_name", "CmdSetName", ADMIN_MAP, "<1/2>" );
	
	RegisterHam( Ham_Spawn,	"player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_CS_Item_CanDrop, "weapon_c4", "FwdHamBombCanDrop" );
	RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_c4", "FwdHamBombPrimaryAttack" );
	
	g_iMsgShowTimer = get_user_msgid( "ShowTimer" );
	
	set_msg_block( get_user_msgid( "ClCorpse" ),    BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	register_logevent( "EventBombPlanted", 3, "2=Planted_The_Bomb" );
	register_logevent( "EventBombDefused", 3, "2=Defused_The_Bomb" );
	register_event( "23", "EventBombExploded", "a", "1=17", "6=-105", "7=17" );
	
	// INFINITE ROUND / AUTO RESPAWN
	OrpheuRegisterHook( OrpheuGetFunction( "FPlayerCanRespawn",  "CHalfLifeMultiplay" ), "FPlayerCanRespawn" );
	OrpheuRegisterHook( OrpheuGetFunction( "CheckWinConditions", "CHalfLifeMultiplay" ), "CheckWinConditions" );
	
	LoadBombPlants( );
	
	set_task( 0.1, "TaskShowBombs" );
}

public TaskShowBombs( ) {
	new szA[ 16 ], szB[ 16 ];
	
	if( g_bBombPlanted[ 0 ] ) {
		formatex( szA, 15, "%.1f", g_flExplodeAt[ 0 ] - get_gametime( ) );
	} else
		szA = g_bBombExploded[ 0 ] ? "Exploded" : "Not planted";
	
	if( g_bBombPlanted[ 1 ] ) {
		formatex( szB, 15, "%.1f", g_flExplodeAt[ 1 ] - get_gametime( ) );
	} else
		szB = g_bBombExploded[ 1 ] ? "Exploded" : "Not planted";
	
	set_hudmessage( 60, 60, 60, -1.0, 0.00, 0, 0.0, 0.3, 0.0, 0.0, 4 );
	show_hudmessage( 0, "A: %s^nB: %s", szA, szB );
	
	set_task( 0.1, "TaskShowBombs" );
}

public plugin_precache( ) {
	OrpheuRegisterHook( OrpheuGetFunction( "InstallGameRules" ), "InstallGameRules", OrpheuHookPost );
	
//	precache_sound( "demolition/bomb_planted.wav" );
//	precache_sound( "demolition/bomb_defused1.wav" );
//	precache_sound( "demolition/bomb_defused2.wav" );
	precache_sound( "demolition/obj_defend.wav" );
	precache_sound( "demolition/obj_destroy.wav" );
	precache_sound( "demolition/round_lost.wav" );
	precache_sound( "demolition/round_win.wav" );
	
	// LOWER THE BOMB DAMAGE RADIUS
	new iEntity = create_entity( "info_map_parameters" );
	
	DispatchKeyValue( iEntity, "bombradius", "100" );
	DispatchSpawn( iEntity );
}

public InstallGameRules( )
	g_pGameRules = OrpheuGetReturn( );

public plugin_end( ) {
	delete_file( g_szConfigFile );
	
	new iFile = fopen( g_szConfigFile, "a" );
	if( iFile ) {
		new iEntity, szModel[ 5 ];
		for( new i; i < 2; i++ ) {
			iEntity = g_iBombPlants[ i ];
			
			if( !is_valid_ent( iEntity ) ) {
				fprintf( iFile, "^"*LOL^" ; %s^n", ( !i ? "A" : "B" ) );
				
				continue;
			}
			
			entity_get_string( iEntity, EV_SZ_model, szModel, 4 );
			
			fprintf( iFile, "^"%s^" ; %s^n", szModel, ( !i ? "A" : "B" ) );
		}
		
		fclose( iFile );
	}
}

LoadBombPlants( ) {
	get_localinfo( "amxx_datadir", g_szConfigFile, charsmax( g_szConfigFile ) );
	formatex( g_szConfigFile, charsmax( g_szConfigFile ), "%s/demolition", g_szConfigFile );
	
	if( !dir_exists( g_szConfigFile ) )
		mkdir( g_szConfigFile );
	
	new szMapName[ 32 ];
	get_mapname( szMapName, 31 );
	strtolower( szMapName );
	formatex( g_szConfigFile, charsmax( g_szConfigFile ), "%s/%s.txt", g_szConfigFile, szMapName );
	
	new iFile = fopen( g_szConfigFile, "r" );
	
	if( iFile ) {
		new szData[ 15 ], szModel[ 5 ], i, iPlant;
		
		while( !feof( iFile ) ) {
			fgets( iFile, szData, 14 );
			trim( szData );
			
			if( !szData[ 0 ] || szData[ 0 ] == ';' )
				continue;
			
			parse( szData, szModel, 4 );
			
			if( szModel[ 1 ] == 'L' ) { // *LOL
				++i;
				continue;
			}
			
			iPlant = find_ent_by_model( -1, func_bomb_target, szModel );
			
			if( iPlant > 0 ) {
				entity_set_int( iPlant, EV_INT_iuser1, i );
				entity_set_string( iPlant, EV_SZ_target, "" );
				
				g_iBombPlants[ i ] = iPlant;
			}
			
			++i;
		}
		
		fclose( iFile );
	}
}

public EventBombPlanted( ) {
	new Float:vOrigin[ 3 ], iPlant, szClass[ sizeof func_bomb_target ], iEntity = -1;
	
	while( ( iEntity = find_ent_by_model( iEntity, "grenade", "models/w_c4.mdl" ) ) > 0 ) {
		entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
		
		iPlant = -1;
		
		while( ( iPlant = find_ent_in_sphere( iPlant, vOrigin, 16.0 ) ) > 0 ) {
			entity_get_string( iPlant, EV_SZ_classname, szClass, charsmax( func_bomb_target ) );
			
			if( equal( szClass, func_bomb_target ) ) {
				new i = entity_get_int( iPlant, EV_INT_iuser1 );
				
				if( g_bBombPlanted[ i ] )
					continue;
				
				g_flExplodeAt[ i ] = cs_get_c4_explode_time( iEntity );
				
				client_print( 0, print_chat, "[ %f ] Bomb planted on %s", get_gametime( ), ( !i ? "A" : "B" ) );
				
				g_bBombPlanted[ i ] = true;
				
				break;
			}
		}
	}
}

public EventBombDefused( ) {
	client_print( 0, print_chat, "[ %f ] Bomb Defused", get_gametime( ) );
	
	UTIL_ShowTimer( );
}

public EventBombExploded( ) {
	new Float:flGameTime = get_gametime( );
	
	for( new i; i < 2; i++ ) {
		if( g_bBombPlanted[ i ] && flGameTime >= g_flExplodeAt[ i ] ) {
			client_print( 0, print_chat, "[ %f ] Bomb Exploded on %s", flGameTime, ( !i ? "A" : "B" ) );
			
			g_bBombPlanted[ i ] = false;
			g_bBombExploded[ i ] = true;
		}
	}
	
	new iBombsExploded;
	
	for( new i; i < 2; i++ )
		if( g_bBombExploded[ i ] )
			iBombsExploded++;
	
	if( iBombsExploded == 2 )
		client_print( 0, print_chat, "Round should end now :D" );
	else
		UTIL_ShowTimer( );
}

public OrpheuHookReturn:FPlayerCanRespawn( ) {
	OrpheuSetReturn( true );
	
	return OrpheuSupercede;
}

public OrpheuHookReturn:CheckWinConditions( ) {
	client_print( 0, print_chat, "[ %f ] CheckWinCondition", get_gametime( ) );
	
	OrpheuSetReturn( false );
	
	return OrpheuSupercede;
}

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {
		switch( cs_get_user_team( id ) ) {
			case CS_TEAM_T: {
				give_item( id, "weapon_c4" );
				cs_set_user_plant( id, 1, 1 );
				
				client_cmd( id, "spk demolition/obj_destroy" );
			}
			case CS_TEAM_CT: {
				cs_set_user_defuse( id, 1 );
				
				client_cmd( id, "spk demolition/obj_defend" );
			}
		}
	}
}

public FwdHamBombCanDrop( const iEntity ) {
	SetHamReturnInteger( false );
	
	return HAM_SUPERCEDE;
}

public FwdHamBombPrimaryAttack( const iEntity ) {
	new id = get_pdata_cbase( iEntity, m_pPlayer, 4 );
	
	if( !is_user_alive( id ) )
		return HAM_IGNORED;
	
	if( ~cs_get_user_mapzones( id ) & CS_MAPZONE_BOMBTARGET )
		return HAM_IGNORED;
	
//	set_pdata_int( iPlayer, m_iMapZone, iMapZones & ~CS_MAPZONE_BOMBTARGET );
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	
	new szClass[ sizeof func_bomb_target ], iEntity = -1, iPlant;
	while( ( iEntity = find_ent_in_sphere( iEntity, vOrigin, 64.0 ) ) > 0 ) {
		entity_get_string( iEntity, EV_SZ_classname, szClass, charsmax( func_bomb_target ) );
		
		iPlant = entity_get_int( iEntity, EV_INT_iuser1 );
		
		if( equal( szClass, func_bomb_target ) && ( g_bBombPlanted[ iPlant ] || g_bBombExploded[ iPlant ] ) )
			return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public CmdSetName( const id, const iLevel, const iCid ) {
	if( !cmd_access( id, iLevel, iCid, 2 ) )
		return PLUGIN_HANDLED;
	
	new Float:vOrigin[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	
	new iPlant, szClass[ sizeof func_bomb_target ], iEntity = -1;
	while( ( iEntity = find_ent_in_sphere( iEntity, vOrigin, 16.0 ) ) > 0 ) {
		entity_get_string( iEntity, EV_SZ_classname, szClass, charsmax( func_bomb_target ) );
		
		if( equal( szClass, func_bomb_target ) ) {
			iPlant = iEntity;
			break;
		}
	}
	
	if( !iPlant ) {
		console_print( id, "You must be standing in plant to use this !" );
		return PLUGIN_HANDLED;
	}
	
	new szArg[ 2 ];
	read_argv( 1, szArg, 2 );
	
	new iName = ( szArg[ 0 ] == '1' || szArg[ 0 ] == 'a' || szArg[ 0 ] == 'A' ) ? 0 : 1;
	
	g_iBombPlants[ iName ] = iPlant;
	
	entity_set_int( iPlant, EV_INT_iuser1, iName );
	entity_set_string( iPlant, EV_SZ_target, "" );
	
	console_print( id, "Bomb name has been set. (%s)", ( !iName ? "A" : "B" ) );
	
	return PLUGIN_HANDLED;
}

UTIL_GetLoguser( ) {
	new szLogUser[ 80 ], szName[ 32 ];
	read_logargv( 0, szLogUser, 79 );
	parse_loguser( szLogUser, szName, 31 );
	
	return get_user_index( szName );
}

UTIL_ShowTimer( ) {
	for( new i; i < 2; i++ )
		if( g_bBombPlanted[ i ] )
			return;
	
	message_begin( MSG_BROADCAST, g_iMsgShowTimer );
	message_end( );
}

#if 0
public plugin_init()
{
	register_event("BarTime", "event_defusing", "be", "1=5", "1=10")
	
	register_logevent("logevent_bomb_planted", 3, "2=Planted_The_Bomb")
	register_logevent("logevent_bomb_defused", 3, "2=Defused_The_Bomb")
	
	register_event("HLTV","event_new_round","a","1=0","2=0")
	
	g_iHamForward = RegisterHam(Ham_Think, "grenade", "C4_Think", 1)
}

public event_defusing(id)
{
	const m_flDefuseCountDown = 99
	
	new Float:flTime = get_pdata_float(g_C4Ent, m_flDefuseCountDown,5) - get_gametime()
}

public logevent_bomb_planted()
{		
	new iC4Ent = FM_NULLENT
	
	const m_bIsC4 = 96
	const m_flC4Blow = 100
	
	while((iC4Ent = engfunc(EngFunc_FindEntityByString, iC4Ent, "classname","grenade")))
	{
		if(get_pdata_int(iC4Ent, m_bIsC4, 5) & (1<<8))
		{
			g_C4Ent = iC4Ent
			
			fC4Timer = get_pdata_float(g_C4Ent, m_flC4Blow, 5) 
			
			EnableHamForward(g_iHamForward)
			
			bForwardEnabled = 1
			
			return
		}
	}
}

public C4_Think(iC4)
{
	if(g_C4Ent != iC4)
	{
		return
	}
	
	static Float:flTime, iTime
	
	flTime = fC4Timer - get_gametime()
	iTime = floatround(flTime, floatround_ceil)
	
	if(g_iTime != iTime)
	{
		g_iTime = iTime
	}
}
#endif