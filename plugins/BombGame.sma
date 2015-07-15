#include < amxmodx >
#include < fun >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

new const PREFIX[ ] = "[ Bomb Game ]";

#define USE_CONNORS_CHATCOLOR

#if defined USE_CONNORS_CHATCOLOR
	#include < chatcolor >
#else
	#include < colorchat >
	
	#define Red        RED
	#define Grey       GREY
	#define Blue       BLUE
	#define DontChange GREEN
#endif

#define FFADE_IN 0x0000

new g_iMsgScreenFade;
new g_iMsgScoreAttrib;
new g_iBomber;
new bool:g_bGameRunning;
new bool:g_bDead[ 33 ];

public plugin_init( ) {
	register_plugin( "Bomb Game", "1.0", "Stewie! / xPaw" );
	
	g_iMsgScreenFade  = get_user_msgid( "ScreenFade" );
	g_iMsgScoreAttrib = get_user_msgid( "ScoreAttrib" );
	
	set_msg_block( get_user_msgid( "ClCorpse" ),    BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "WeapPickup" ),  BLOCK_SET );
	set_msg_block( get_user_msgid( "AmmoPickup" ),  BLOCK_SET );
	
	register_message( g_iMsgScoreAttrib, "MessageScoreAttrib" );
	
	register_logevent( "EventRoundStart",         2, "1=Round_Start" );
	register_logevent( "EventRoundEnd",           2, "1=Round_End" );
	register_logevent( "EventSpawnedWithTheBomb", 3, "2=Spawned_With_The_Bomb" );
	
//	register_event( "HLTV",       "EventNewRound",     "a",  "1=0", "2=0" );
	register_event( "TextMsg",    "EventRoundRestart", "a",  "2=#Game_will_restart_in" );
	register_event( "WeapPickup", "EventBombPickup",   "be", "1=6" );
	
	register_forward( FM_ClientKill, "FwdClientKill" );
	register_forward( FM_SetModel,   "FwdSetModel" );
	
	RegisterHam( Ham_Spawn,  "player", "FwdHamPlayerSpawn",  1 );
//	RegisterHam( Ham_Killed, "player", "FwdHamPlayerKilled", 1 );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage" );
}

public plugin_precache( ) {
	new szMapName[ 32 ];
	get_mapname( szMapName, 31 );
	
	if( equali( szMapName, "de_cbble" ) ) {
		new const Float:CbbleSpawns[ ][ 3 ] = {
			{ -634.0, -1173.0, -82.0 },
			{ -765.0, -1136.0, -82.0 },
			{ -766.0, -1026.0, -82.0 },
			{ -532.0, -1062.0, -82.0 },
			{ -530.0, -1198.0, -82.0 },
			{ -387.0, -1196.0, -82.0 },
			{ -389.0, -1058.0, -82.0 },
			{ -270.0, -1000.0, -82.0 },
			{ -634.0, -1045.0, -82.0 },
			{ -266.0, -1116.0, -82.0 },
			{ -768.0, -890.0, -82.0 },
			{ -533.0, -919.0, -82.0 },
			{ -390.0, -927.0, -82.0 },
			{ -392.0, -804.0, -82.0 },
			{ -528.0, -764.0, -82.0 },
			{ -274.0, -863.0, -82.0 }
		};
		
		new iEntity;
		
		for( new i; i < sizeof CbbleSpawns; i++ ) {
			if( ( iEntity = create_entity( "info_player_deathmatch" ) ) > 0 ) {
				entity_set_int( iEntity, EV_INT_iuser1, 1337 );
				entity_set_vector( iEntity, EV_VEC_origin, CbbleSpawns[ i ] );
				
				DispatchSpawn( iEntity );
			}
		}
	}
}

public plugin_cfg( ) {
	new iEntity = FM_NULLENT;
	while( ( iEntity = find_ent_by_class( iEntity, "info_player_start" ) ) > 0 )
		remove_entity( iEntity );
	
	new szMapName[ 32 ];
	get_mapname( szMapName, 31 );
	
	if( equali( szMapName, "de_cbble" ) ) {
		iEntity = FM_NULLENT;
		while( ( iEntity = find_ent_by_class( iEntity, "info_player_deatmatch" ) ) > 0 )
			if( entity_get_int( iEntity, EV_INT_iuser1 ) != 1337 )
				remove_entity( iEntity );
	}
	
	iEntity = FM_NULLENT;
	while( ( iEntity = find_ent_by_class( iEntity, "func_bomb_target" ) ) > 0 )
		entity_set_int( iEntity, EV_INT_solid, SOLID_NOT );
	
	iEntity = FM_NULLENT;
	while( ( iEntity = find_ent_by_class( iEntity, "info_bomb_target" ) ) > 0 )
		entity_set_int( iEntity, EV_INT_solid, SOLID_NOT );
	
	set_cvar_num( "mp_limitteams", 32 );
	set_cvar_num( "mp_autoteambalance", 0 );
	set_cvar_string( "humans_join_team", "t" );
	set_cvar_num( "sv_restart", 1 );
}

public client_putinserver( id ) {
	g_bDead[ id ] = true;
}

public client_disconnect( id ) {
	if( g_bGameRunning && g_iBomber == id ) {
		entity_set_vector( find_ent_by_class( -1, "weapon_c4" ), EV_VEC_origin, Float:{ 0.0, 0.0, -8096.0 } );
		
		g_bGameRunning = bool:( get_playersnum( ) > 1 );
		
		if( g_bGameRunning ) {
			ColorChat( 0, Red, "^4%s^1 The bomber left the server!", PREFIX );
			ColorChat( 0, Red, "^4%s^1 Lets pick a new bomber!", PREFIX );
			
			NewBomber( );
		}
	}
}

public MessageScoreAttrib( ) {
	if( get_msg_arg_int( 2 ) == 1 )
		return;
	
	if( g_iBomber == get_msg_arg_int( 1 ) ) {
		set_msg_arg_int( 2, ARG_BYTE, 2 );
	} else {
		set_msg_arg_int( 2, ARG_BYTE, 0 );
	}
}

public EventRoundRestart( ) {
	if( g_bGameRunning ) {
		g_bGameRunning = false;
		
		if( is_user_alive( g_iBomber ) ) {
			set_user_rendering( g_iBomber );
			
			engclient_cmd( g_iBomber, "drop", "weapon_c4" );
		}
		
		g_iBomber = 0;
		
		arrayset( g_bDead, false, 33 );
	}
}

public EventRoundStart( ) {
	g_bGameRunning = bool:( get_playersnum( ) > 1 );
	
	if( g_bGameRunning )
		NewBomber( );
}

public EventRoundEnd( ) {
	if( !g_bGameRunning )
		return;
	
	g_bGameRunning = false;
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "a" );
	
	if( is_user_alive( g_iBomber ) ) {
		user_kill( g_iBomber );
		
		set_user_rendering( g_iBomber );
		
		entity_set_vector( find_ent_by_class( -1, "weapon_c4" ), EV_VEC_origin, Float:{ 0.0, 0.0, -8096.0 } );
		entity_set_int( g_iBomber, EV_INT_effects, entity_get_int( g_iBomber, EV_INT_effects ) | EF_NODRAW );
		
		new iOrigin[ 3 ];
		get_user_origin( g_iBomber, iOrigin );
		
		message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
		write_byte( TE_TELEPORT );
		write_coord( iOrigin[ 0 ] );
		write_coord( iOrigin[ 1 ] );
		write_coord( iOrigin[ 2 ] );
		message_end( );
		
		FixScoreAttrib( g_iBomber );
		
		if( iNum > 1 ) {
			new szName[ 32 ];
			get_user_name( g_iBomber, szName, 31 );
			
			ColorChat( 0, Red, "^4%s^3 %s^1 has been left with the bomb!", PREFIX, szName );
		}
	}
	
	g_iBomber = 0;
	
	if( iNum == 0 ) {
		server_cmd( "sv_restartround 1" );
	}
	else if( iNum == 1 ) {
		server_cmd( "sv_restartround 3" );
		
		new szName[ 32 ], id = iPlayers[ 0 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "^4%s^3 %s^1 won the bomb game!", PREFIX, szName );
	}
}

public EventSpawnedWithTheBomb( ) {
	new id = GetLogUser( );
	
	strip_user_weapons( id );
	give_item( id, "weapon_knife" );
	
	FixScoreAttrib( id );
}

public EventBombPickup( const id ) {
	if( !g_bGameRunning )
		return;
	
	client_cmd( id, "weapon_c4" );
	
	if( g_iBomber != id ) {
		SetBomber( id );
		
		if( is_user_alive( g_iBomber ) ) {
		//	set_user_gravity( g_iBomber, 1.0 );
			set_user_maxspeed( g_iBomber, 250.0 );
			set_user_rendering( g_iBomber );
			
			FixScoreAttrib( g_iBomber );
		}
		
		g_iBomber = id;
	}
}

public FwdHamPlayerSpawn( const id ) {
	if( is_user_alive( id ) ) {	
		strip_user_weapons( id );
		give_item( id, "weapon_knife" );
		
		if( g_bGameRunning && g_bDead[ id ] ) {
			user_kill( id );
			
			entity_set_int( id, EV_INT_deadflag, DEAD_DISCARDBODY );
			entity_set_int( id, EV_INT_effects, entity_get_int( id, EV_INT_effects ) | EF_NODRAW );
		}
	}
}

public FwdClientKill( const id ) {
	if( g_bGameRunning && is_user_alive( id ) ) {
		console_print( id, "Can't suicide -- game is running!" );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdSetModel( const iEntity, const szModel[ ] ) {
	static const BackPackModel[ ] = "models/w_backpack.mdl";
	
	if( equal( szModel, BackPackModel ) ) {
		if( g_bGameRunning ) {
			SetRendering( iEntity, kRenderFxGlowShell, Float:{ 255.0, 100.0, 50.0 }, _, 16.0 );
		} else {
			entity_set_vector( iEntity, EV_VEC_origin, Float:{ 0.0, 0.0, -8096.0 } );
		}
	}
}

public FwdHamPlayerTakeDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
	return ( iDamageBits & ( 1 << 5 ) ) ? HAM_SUPERCEDE : HAM_IGNORED;

//
/////////////////////////////////////////////////////////////////////
MakeScreenFade( const id, const vColor[ 3 ] ) {
	message_begin( id > 0 ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_iMsgScreenFade, _, id );
	write_short( ( 1 << 12 ) );
	write_short( ( 1 << 12 ) );
	write_short( FFADE_IN );
	write_byte( vColor[ 0 ] );
	write_byte( vColor[ 1 ] );
	write_byte( vColor[ 2 ] );
	write_byte( 50 );
	message_end( );
}

GetLogUser( ) {
	new szLogUser[ 80 ], szName[ 32 ];
	
	read_logargv( 0, szLogUser, 79 );
	parse_loguser( szLogUser, szName, 31 );
	
	return get_user_index( szName );
}

GetRandomPlayer( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "a" );
	
	if( !iNum )
		return 0;
	
	return iPlayers[ random( iNum ) ];
}

NewBomber( ) {
	g_iBomber = GetRandomPlayer( );
	
	if( g_iBomber > 0 ) {
		give_item( g_iBomber, "weapon_c4" );
		cs_set_user_plant( g_iBomber, 1, 1 );
		
		entity_set_int( g_iBomber, EV_INT_body, 1 );
		
		SetBomber( g_iBomber );
	}
}

SetBomber( const id ) {
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	ColorChat( 0, Red, "^4%s^3 %s^1 has picked up the bomb!", PREFIX, szName );
	
//	set_user_gravity( id, 0.8 );
	set_user_maxspeed( id, 320.0 );
	set_user_rendering( id, kRenderFxGlowShell, 255, 80, 20, kRenderNormal, 16 );
	
	MakeScreenFade( id, { 255, 30, 0 } );
	
	FixScoreAttrib( id, true );
}

FixScoreAttrib( const id, bool:bShow = false ) {
	message_begin( MSG_BROADCAST, g_iMsgScoreAttrib );
	write_byte( id );
	write_byte( bShow ? 2 : 0 );
	message_end( );
}

SetRendering( iEntity, iFX = kRenderFxNone, Float:vColor[ 3 ], iRender = kRenderNormal, Float:flAmount ) {
	entity_set_int( iEntity, EV_INT_renderfx, iFX );
	entity_set_int( iEntity, EV_INT_rendermode, iRender );
	entity_set_float( iEntity, EV_FL_renderamt, flAmount );
	entity_set_vector( iEntity, EV_VEC_rendercolor, vColor );
}
