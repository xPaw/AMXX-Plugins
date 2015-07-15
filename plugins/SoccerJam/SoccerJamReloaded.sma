#include <amxmodx>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

/*
	TODO:
	
		Store is_user_alive( ), is_user_bot( ), is_user_connected( )
		Ball spawn editor ? O_o
		Fix radar dot (ball place)
*/

// BALL BEAM
#define BALL_BEAM_RED		250
#define BALL_BEAM_GREEN		80
#define BALL_BEAM_BLUE		10

#define BALL_BEAM_WIDTH		5
#define BALL_BEAM_LIFE		10
#define BALL_BEAM_ALPHA		175

new const ROUND_START[ ] = "kickball/prepare.wav";
new const BALL_KICKED[ ] = "kickball/kicked.wav";
new const BALL_RESPAWN[ ] = "kickball/returned.wav";
new const BALL_PICKED_UP[ ] = "kickball/gotball.wav";
new const BALL_BOUNCE_GROUND[ ] = "kickball/bounce.wav";

new const g_szBallModel[ ] = "models/sj_ball.mdl";
new const g_szBallName[ ] = "sj_ball";

new const BotNames[ 3 ][ ] = {
	"", // Dont change
	"SJ Reloaded: T",
	"SJ Reloaded: CT"
};

new const TeamMascots[ 3 ][ ] = {
	"models/chick.mdl", // Dont change
	"models/player/terror/terror.mdl",
	"models/player/gign/gign.mdl"
};

new g_iMascots[ 3 ];
new g_iGoalNets[ 3 ];
new g_iBots[ 3 ];
new g_iBall;

new g_iBeamSprite;
new g_iMaxplayers;
new g_iMsgHostageK;
new g_iMsgHostagePos;

new Float:g_vBallOrigin[ 3 ];
new Float:g_flMascots[ 3 ][ 3 ];

public plugin_init( ) {
	register_plugin( "SoccerJam Reloaded", "1.0", "xPaw" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1 );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	
	g_iMaxplayers = get_maxplayers( );
	g_iMsgHostagePos = get_user_msgid( "HostagePos" );
	g_iMsgHostageK = get_user_msgid( "HostageK" );
	
	register_think( g_szBallName, "FwdThinkBall" );
	register_think( "sj_mascot",  "FwdThinkMascot" );
	
	// Touches
	register_touch( g_szBallName, "player",             "FwdTouchPlayer" );
//	register_touch( g_szBallName, "sj_goalnet",         "FwdTouchNet" );
	register_touch( g_szBallName, "worldspawn",         "FwdTouchWorld" );
	register_touch( g_szBallName, "func_wall",          "FwdTouchWorld" );
	register_touch( g_szBallName, "func_door",          "FwdTouchWorld" );
	register_touch( g_szBallName, "func_door_rotating", "FwdTouchWorld" );
	register_touch( g_szBallName, "func_wall_toggle",   "FwdTouchWorld" );
	register_touch( g_szBallName, "func_breakable",     "FwdTouchWorld" );
	
	set_task( 2.0, "CreateBots" );
	
	// SoccerJam map fix
	new szMapname[ 32 ];
	get_mapname( szMapname, 31 );
	
	if( equali( szMapname, "soccerjam" ) ) {
		SJMap_CreateWall( );
		
		new iEntity = create_entity( "info_target" );
		
		if( is_valid_ent( iEntity ) ) {
			entity_set_origin( iEntity, Float:{ 2110.0, 0.0, 1604.0 } );
			
			g_iGoalNets[ 1 ] = iEntity;
			FinalizeNet( 1, true );
		}
		
		iEntity = create_entity( "info_target" );
		
		if( is_valid_ent( iEntity ) ) {
			entity_set_origin( iEntity, Float:{ -2550.0, 0.0, 1604.0 } );
			
			g_iGoalNets[ 2 ] = iEntity;
			FinalizeNet( 2, true );
		}
	}
	
	register_clcmd( "say /reset", "ResetBall" );
}

public ResetBall( id )
	MoveBall( true, true );

public plugin_precache( ) {
	for( new i; i < 3; i++ )
		precache_model( TeamMascots[ i ] );
	
	precache_model( g_szBallModel );
	
	precache_sound( ROUND_START );
	precache_sound( BALL_KICKED );
	precache_sound( BALL_RESPAWN );
	precache_sound( BALL_PICKED_UP );
	precache_sound( BALL_BOUNCE_GROUND );
	
	g_iBeamSprite = precache_model( "sprites/lgtning.spr" );
}

public EventNewRound( ) {
	if( !is_valid_ent( g_iBall ) )
		CreateBall( );
	
	MoveBall( true, false );
	
	client_cmd( 0, "spk %s", ROUND_START );
}

public FwdHamObjectCaps( id ) {
	if( g_iBall > 0 && is_user_alive( id ) ) {
		static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
		
		if( iOwner == id )
			KickBall( id, 0 );
	}
}

public FwdHamPlayerSpawn( id ) {
	if( is_user_alive( id ) ) {
		if( is_user_bot( id ) ) {
			static i;
			
			for( i = 1; i < 3; i++ ) {
				if( id == g_iBots[ i ] ) {
					set_pev( id, pev_takedamage, DAMAGE_NO );
					set_pev( id, pev_solid, SOLID_NOT );
					set_pev( id, pev_effects, pev( id, pev_effects ) | EF_NODRAW );
					
					new iTeam = get_user_team( id );
					
					if( 1 <= iTeam <= 2 ) {
						if( is_valid_ent( g_iMascots[ iTeam ] ) ) {
							new Float:vOrigin[ 3 ];
							entity_get_vector( g_iMascots[ iTeam ], EV_VEC_origin, vOrigin );
							entity_set_origin( id, vOrigin ); // Lets fake the radar :)
						}
					}
					
					break;
				}
			}
		}
	}
}

// CREATE BOTS
////////////////////////////////////////////////////////////
public CreateBots( ) {
	new id, szPtr[ 128 ];
	
	for( new i = 1; i < 3; i++ ) {
		id = find_player( "bli", BotNames[ i ] );
		
		if( id ) {
			g_iBots[ i ] = id;
			
			continue;
		}
		
		id = engfunc( EngFunc_CreateFakeClient, BotNames[ i ] );
		
		g_iBots[ i ] = id;
		
		dllfunc( DLLFunc_ClientConnect, id, BotNames[ i ], "127.0.0.1", szPtr );
		dllfunc( DLLFunc_ClientPutInServer, id );
		
		set_pev( id, pev_colormap, id );
		set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FAKECLIENT );
		
		switch( i ) {
			case 1: cs_set_user_team( id, CS_TEAM_T, CS_T_TERROR );
			case 2: cs_set_user_team( id, CS_TEAM_CT, CS_CT_GIGN );
		}
		
		ExecuteHamB( Ham_CS_RoundRespawn, id );
	}
}

// ENTITIES DATA
////////////////////////////////////////////////////////////
public pfn_keyvalue( iEntity ) {
	new Classname[ 32 ], Key[ 32 ], Value[ 32 ];
	copy_keyvalue( Classname, 31, Key, 31, Value, 31 );
	
	if( equal( Key, "classname" ) && equal( Value, "soccerjam_goalnet" ) )
		DispatchKeyValue( "classname", "func_wall" );
	
	if( equal( Classname, "game_player_equip" ) )
		remove_entity( iEntity );
	else if( equal( Classname, "func_wall" ) ) {
		if( equal( Key, "team" ) ) {
			new iTeam = str_to_num( Value );
			
			if( 1 <= iTeam <= 2 ) {
				g_iGoalNets[ iTeam ] = iEntity;
				
				FinalizeNet( iTeam, false );
			}
		}
	}
	else if( equal( Classname, "soccerjam_mascot" ) ) {
		new szTemp[ 3 ][ 10 ];
		
		if( equal( Key, "team" ) ) {
			new iTeam = str_to_num( Value );
			
			if( 1 <= iTeam <= 2 )
				CreateMascot( iTeam );
		}
		else if( equal( Key, "origin" ) ) {
			parse( Value, szTemp[ 0 ], 9, szTemp[ 1 ], 9, szTemp[ 2 ], 9 );
			
			g_flMascots[ 0 ][ 0 ] = floatstr( szTemp[ 0 ] );
			g_flMascots[ 0 ][ 1 ] = floatstr( szTemp[ 1 ] );
			g_flMascots[ 0 ][ 2 ] = floatstr( szTemp[ 2 ] );
		}
		else if( equal( Key, "angles" ) ) {
			parse( Value, szTemp[ 0 ], 9, szTemp[ 1 ], 9, szTemp[ 2 ], 9 );
			
			g_flMascots[ 1 ][ 0 ] = floatstr( szTemp[ 0 ] );
			g_flMascots[ 1 ][ 1 ] = floatstr( szTemp[ 1 ] );
			g_flMascots[ 1 ][ 2 ] = floatstr( szTemp[ 2 ] );
		}
	}
	else if( equal( Classname, "soccerjam_ballspawn" ) ) {
		if( equal( Key, "origin" ) ) {
			if( g_vBallOrigin[ 2 ] != 0.0 )
				return;
			
			new szTemp[ 3 ][ 10 ];
			parse( Value, szTemp[ 0 ], 9, szTemp[ 1 ], 9, szTemp[ 2 ], 9 );
			
			g_vBallOrigin[ 0 ] = floatstr( szTemp[ 0 ] );
			g_vBallOrigin[ 1 ] = floatstr( szTemp[ 1 ] );
			g_vBallOrigin[ 2 ] = floatstr( szTemp[ 2 ] ) + 10.0;
			
			CreateBall( );
		}
	}
}

// MASCOT
////////////////////////////////////////////////////////////
public FwdThinkMascot( iEntity ) {
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
	
	static iTeam, iCount, iChosen, iBallOwner, id, iPlayers[ 32 ];
	
	iTeam = entity_get_int( iEntity, EV_INT_team );
	iChosen = 0;
	iCount = 0;
	
	arrayset( iPlayers, 0, 31 );
	
	if( is_valid_ent( g_iBall ) )
		iBallOwner = pev( g_iBall, pev_owner );
	else
		iBallOwner = 0;
	
	for( id = 1; id <= g_iMaxplayers; id++ ) {
		if( is_user_alive( id ) && !is_user_bot( id ) ) {
			if( iTeam == get_user_team( id ) )
				continue;
			
			if( entity_range( id, iEntity ) < 650.0 ) {
				if( id == iBallOwner ) {
					iChosen = id;
					
					break;
				}
				
				iPlayers[ iCount++ ] = id;
			}
		}
	}
	
	if( !iCount && ! iChosen )
		return;
	
	if( !iChosen )
		iChosen = iPlayers[ random( iCount ) ];
	
	if( iChosen )
		TerminatePlayer( iChosen, iEntity, iTeam, ( iBallOwner == iChosen ? 230.0 : random_float( 5.0, 15.0 ) ) );
}

TerminatePlayer( id, iEntity, iTeam, Float:flDmg ) {
	static iOrigin[ 3 ], Float:vOrigin[ 3 ];
	
	get_user_origin( id, iOrigin );
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	
	static const TMascot[ ]  = "Terrorist Mascot";
	static const CTMascot[ ] = "CT Mascot";
	
	fakedamage( id, iTeam == 2 ? CTMascot : TMascot, flDmg, DMG_CRUSH );
	
	new iColor[ 3 ];
	iColor[ 1 ] = 127;
	
	switch( iTeam ) {
		case 1: iColor[ 0 ] = 255;
		case 2: iColor[ 2 ] = 255;
	}
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMPOINTS );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	write_short( g_iBeamSprite );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 7 );
	write_byte( 120 );
	write_byte( 25 );
	write_byte( iColor[ 0 ] );
	write_byte( iColor[ 1 ] );
	write_byte( iColor[ 2 ] );
	write_byte( 220 );
	write_byte( 1 );
	message_end( );
}

// BALL BRAIN :)
////////////////////////////////////////////////////////////
public FwdThinkBall( iEntity ) {
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 0.05 );
	
	static Float:vOrigin[ 3 ];
	pev( iEntity, pev_origin, vOrigin );
	
	message_begin( MSG_ONE, g_iMsgHostagePos, _, 1 );
	write_byte( 1 );
	write_byte( 1 );
	engfunc( EngFunc_WriteCoord, vOrigin[ 0 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 1 ] );
	engfunc( EngFunc_WriteCoord, vOrigin[ 2 ] );
	message_end( );
	
	message_begin( MSG_ONE, g_iMsgHostageK, _, 1 );
	write_byte( 1 );
	message_end( );
	
	static iOwner; iOwner = pev( iEntity, pev_iuser1 );
	static iSolid; iSolid = pev( iEntity, pev_solid );
	
	if( iOwner > 0 ) {
		if( !is_user_connected( iOwner ) ) {
			MoveBall( true, true );
			
			return PLUGIN_CONTINUE;
		}
		
		static Float:vOwnerOrigin[ 3 ];
		entity_get_vector( iOwner, EV_VEC_origin, vOwnerOrigin );
		
		if( !is_user_alive( iOwner ) ) {
			entity_set_int( iEntity, EV_INT_iuser1, 0 );
			
			vOwnerOrigin[ 2 ] += 5.0;
			
			entity_set_origin( iEntity, vOwnerOrigin );
			entity_set_vector( iEntity, EV_VEC_velocity, Float:{ 1.0, 1.0, 1.0 } );
			
			return PLUGIN_CONTINUE;
		}
		
		if( iSolid != SOLID_NOT )
			set_pev( iEntity, pev_solid, SOLID_NOT );
		
		static Float:vAngles[ 3 ], Float:vReturn[ 3 ];
		entity_get_vector( iOwner, EV_VEC_v_angle, vAngles );
		
		vReturn[ 0 ] = ( floatcos( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 0 ];
		vReturn[ 1 ] = ( floatsin( vAngles[ 1 ], degrees ) * 55.0 ) + vOwnerOrigin[ 1 ];
		vReturn[ 2 ] = vOwnerOrigin[ 2 ];
		
		vReturn[ 2 ] -= ( entity_get_int( iOwner, EV_INT_flags ) & FL_DUCKING ) ? 10 : 30;
		
		static const Float:vVelocity[ 3 ] = { 1.0, 1.0, 0.0 };
		
		entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
		entity_set_origin( iEntity, vReturn );
	} else {
		if( iSolid != SOLID_BBOX )
			set_pev( iEntity, pev_solid, SOLID_BBOX );
	}
	
	return PLUGIN_CONTINUE;
}

MoveBall( bool:Point, bool:Sound ) {
	entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
	
	if( !Point )
		entity_set_origin( g_iBall, Float:{ 0.0, 0.0, -8096.0 } );
	else {
		entity_set_origin( g_iBall, g_vBallOrigin );
		entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 400.0 } );
		
		if( Sound )
			client_cmd( 0, "spk %s", BALL_RESPAWN );
	}
	
	entity_set_int( g_iBall, EV_INT_iuser1, 0 );
}

KickBall( id, VelType ) {
	static Float:vOrigin[ 3 ];
	
	entity_get_vector( g_iBall, EV_VEC_origin, vOrigin );
	
	if( PointContents( vOrigin ) != CONTENTS_EMPTY )
		return PLUGIN_HANDLED;
	else {
	#if 0
		static i, Float:vBallSides[ 8 ][ 3 ];
		
		for( i = 0; i < 8; i++ )
			vBallSides[ i ] = vOrigin;
		
		for( i = 1; i <= 6; i++ ) {
			vBal
		}
		
		for(a=1; a<=6; a++) {

			ballF[1] += 3.0;	ballB[1] -= 3.0;
			ballR[0] += 3.0;	ballL[0] -= 3.0;

			ballTL[0] -= 3.0;	ballTL[1] += 3.0;
			ballTR[0] += 3.0;	ballTR[1] += 3.0;
			ballBL[0] -= 3.0;	ballBL[1] -= 3.0;
			ballBR[0] += 3.0;	ballBR[1] -= 3.0;

			if(point_contents(ballF) != CONTENTS_EMPTY || point_contents(ballR) != CONTENTS_EMPTY ||
			point_contents(ballL) != CONTENTS_EMPTY || point_contents(ballB) != CONTENTS_EMPTY ||
			point_contents(ballTR) != CONTENTS_EMPTY || point_contents(ballTL) != CONTENTS_EMPTY ||
			point_contents(ballBL) != CONTENTS_EMPTY || point_contents(ballBR) != CONTENTS_EMPTY)
				return PLUGIN_HANDLED
		}
		
		new ent = -1
		testorigin[2] += 35.0

		while((ent = find_ent_in_sphere(ent, testorigin, 35.0)) != 0) {
			if(ent > maxplayers)
			{
				new classname[32]
				entity_get_string(ent, EV_SZ_classname, classname, 31)

				if((contain(classname, "goalnet") != -1 || contain(classname, "func_") != -1) &&
					!equal(classname, "func_water") && !equal(classname, "func_illusionary"))
					return PLUGIN_HANDLED
			}
		}
		testorigin[2] -= 35.0
		
		#endif
	}
	
	new iKickVel;
	
	if( !VelType ) {
	//	new str = (PlayerUpgrades[id][STR] * AMOUNT_STR) + (AMOUNT_POWERPLAY*(PowerPlay*5))
		iKickVel = 650;
	} else
		iKickVel = random_num( 100, 600 );
	
	new Float:vVelocity[ 3 ];
	velocity_by_aim( id, iKickVel, vVelocity );
	
	entity_set_int( g_iBall, EV_INT_iuser1, 0 );
	entity_set_vector( g_iBall, EV_VEC_velocity, vVelocity );
	
	emit_sound( g_iBall, CHAN_ITEM, BALL_KICKED, 1.0, ATTN_NORM, 0, PITCH_NORM );
	
	return PLUGIN_CONTINUE;
}

// BALL TOUCHES
////////////////////////////////////////////////////////////
public FwdTouchPlayer( Ball, id ) {
	if( is_user_bot( id ) )
		return PLUGIN_CONTINUE;
	
	static iOwner; iOwner = pev( Ball, pev_iuser1 );
	
	if( iOwner == 0 ) {
		emit_sound( Ball, CHAN_ITEM, BALL_PICKED_UP, 1.0, ATTN_NORM, 0, PITCH_NORM );
		
		entity_set_int( Ball, EV_INT_iuser1, id );
		
		set_hudmessage( 255, 20, 20, -1.0, 0.4, 1, 1.0, 1.5, 0.1, 0.1, 2 );
		show_hudmessage( id, "YOU HAVE THE BALL !!" );
	}
	
	return PLUGIN_CONTINUE;
}

public FwdTouchWorld( Ball, World ) {
	static Float:vVelocity[ 3 ];
	entity_get_vector( Ball, EV_VEC_velocity, vVelocity );
	
	if( floatround( vector_length( vVelocity ) ) > 10 ) {
		vVelocity[ 0 ] *= 0.85;
		vVelocity[ 1 ] *= 0.85;
		vVelocity[ 2 ] *= 0.85;
		
		entity_set_vector( Ball, EV_VEC_velocity, vVelocity );
		
		emit_sound( Ball, CHAN_ITEM, BALL_BOUNCE_GROUND, 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
}

// GOAL NETS
////////////////////////////////////////////////////////////
public FinalizeNet( Team, bool:SJMapFix ) {
	new iEntity = g_iGoalNets[ Team ];
	
	entity_set_string( iEntity, EV_SZ_classname, "sj_goalnet" );
	entity_set_int( iEntity, EV_INT_team, Team );
	
	if( SJMapFix ) {
		entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
		entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_NONE );
		entity_set_model( iEntity, TeamMascots[ 0 ] );
		entity_set_size( iEntity, Float:{ -25.0, -145.0, -36.0 }, Float:{ 25.0, 145.0, 70.0 } );
	}
	
	set_entity_visibility( iEntity, 0 );
}

// ENTITIES CREATING
////////////////////////////////////////////////////////////
CreateBall( ) {
	g_iBall = create_entity( "info_target" );
	
	if( is_valid_ent( g_iBall ) ) {
		entity_set_string( g_iBall, EV_SZ_classname, g_szBallName );
		entity_set_int( g_iBall, EV_INT_solid, SOLID_BBOX );
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_model( g_iBall, g_szBallModel );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		
		entity_set_float( g_iBall, EV_FL_framerate, 0.0 );
		entity_set_int( g_iBall, EV_INT_sequence, 0 );
		
		entity_set_float( g_iBall, EV_FL_nextthink, get_gametime( ) + 0.05 );
		
		SetRendering( g_iBall, kRenderFxGlowShell, Float:{ 0.0, 127.0, 255.0 }, kRenderNormal, 16.0 );
		
		MoveBall( true, false );
		
		return g_iBall;
	}
	
	return -1;
}

CreateMascot( iTeam ) {
	new iEntity = create_entity( "info_target" );
	
	if( is_valid_ent( iEntity ) ) {
		g_iMascots[ iTeam ] = iEntity;
		
		entity_set_string( iEntity, EV_SZ_classname, "sj_mascot" );
		entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
		entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_NONE );
		entity_set_int( iEntity, EV_INT_team, iTeam );
		entity_set_model( iEntity, TeamMascots[ iTeam ] );
		entity_set_size( iEntity, Float:{ -16.0, -16.0, -36.0 }, Float:{ 16.0, 16.0, 36.0 } );
		
		entity_set_vector( iEntity, EV_VEC_angles, g_flMascots[ 1 ] );
		entity_set_origin( iEntity, g_flMascots[ 0 ] );
		entity_set_float( iEntity, EV_FL_animtime, 2.0 );
		entity_set_float( iEntity, EV_FL_framerate, 1.0 );
		entity_set_int( iEntity, EV_INT_sequence, 64 );
		
		entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + 1.0 );
		
		new Float:vColors[ 3 ];
		vColors[ 1 ] = 127.0;
		
		switch( iTeam ) {
			case 1: vColors[ 0 ] = 255.0;
			case 2: vColors[ 2 ] = 255.0;
		}
		
		SetRendering( iEntity, kRenderFxGlowShell, vColors, kRenderNormal, 5.0 );
	}
}

// SOCCERJAM MAP ( OFFICIAL )
////////////////////////////////////////////////////////////
SJMap_CreateWall( ) {
	new iEntity = create_entity( "func_wall" );
	
	if( is_valid_ent( iEntity ) ) {
		entity_set_string( iEntity, EV_SZ_classname, "sj_block_wall" );
		entity_set_int( iEntity, EV_INT_solid, SOLID_BBOX );
		entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_NONE );
		entity_set_model( iEntity, TeamMascots[ 0 ] );
		entity_set_size( iEntity, Float:{ -72.0, -100.0, -72.0 }, Float:{ 72.0, 100.0, 72.0 } );
		entity_set_origin( iEntity, Float:{ 2355.0, 1696.0, 1604.0 } );
		
		DispatchSpawn( iEntity );
		
		set_entity_visibility( iEntity, 0 );
	}
}

// STOCKS
////////////////////////////////////////////////////////////
stock SetRendering( iEntity, iFX = kRenderFxNone, Float:iColor[ 3 ] = { 255.0, 255.0, 255.0 }, iRender = kRenderNormal, Float:iAmount = 16.0 ) {
	set_pev( iEntity, pev_renderfx, iFX );
	set_pev( iEntity, pev_rendercolor, iColor );
	set_pev( iEntity, pev_rendermode, iRender );
	set_pev( iEntity, pev_renderamt, iAmount );
	
	return 1;
}
