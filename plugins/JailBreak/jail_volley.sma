#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >

static const BALL_BOUNCE_GROUND[ ] = "kickball/bounce.wav";
static const g_szBallModel[ ]	 = "models/volley/ball.mdl";
static const g_szBallName[ ] 	 = "volley";

new g_iBall, g_szFile[ 128 ], g_szMapname[ 32 ], g_iButtonsMenu, g_iTrailSprite;
new bool:g_bNeedBall;
new Float:g_vOrigin[ 3 ];

public plugin_init( ) {
	register_plugin( "SoccerJam Reloaded", "1.0", "xPaw & master4life" );
	
	RegisterHam( Ham_ObjectCaps, "player", "FwdHamObjectCaps", 1 );
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	
	register_think( g_szBallName, "FwdThinkBall" );
	register_touch( g_szBallName, "player", "FwdTouchPlayer" );
	
	new const szEntity[ ][ ] = {
		"info_target", "worldspawn", "func_wall", "func_door",  "func_door_rotating",
		"func_wall_toggle", "func_breakable", "func_pushable", "func_train",
		"func_illusionary", "func_button", "func_rot_button", "func_rotating"
	}
	
	for( new i; i < sizeof szEntity; i++ )
		register_touch( g_szBallName, szEntity[ i ], "FwdTouchWorld" );
	
	g_iButtonsMenu = menu_create( "\rBall\y Spawn Menu", "HandleButtonsMenu" );
	
	menu_additem( g_iButtonsMenu, "Create Volleyball", "1" );
	menu_additem( g_iButtonsMenu, "Delete the Volleyball", "2" );
	menu_additem( g_iButtonsMenu, "Save", "3" );
	
	register_clcmd( "say /volley", "CmdButtonsMenu", ADMIN_RCON );
	register_clcmd( "say /reset", "UpdateBall" );
}

public FwdTouchField( )
	return PLUGIN_CONTINUE;

public UpdateBall( id ) {
	if( !id || get_user_flags( id ) & ADMIN_KICK )
		ResetBall( );
	
	return PLUGIN_HANDLED;
}

public ResetBall( ) {
	if( is_valid_ent( g_iBall ) ) {
		entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
		entity_set_origin( g_iBall, g_vOrigin );
			
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		entity_set_int( g_iBall, EV_INT_iuser1, 0 );
	}
}

public plugin_precache( ) {
	precache_model( g_szBallModel );
	precache_sound( BALL_BOUNCE_GROUND );
	
	g_iTrailSprite = precache_model( "sprites/laserbeam.spr" );
	
	get_mapname( g_szMapname, 31 );
	strtolower( g_szMapname );
	
	// File
	new szDatadir[ 64 ];
	get_localinfo( "amxx_datadir", szDatadir, charsmax( szDatadir ) );
	
	formatex( szDatadir, charsmax( szDatadir ), "%s", szDatadir );
	
	if( !dir_exists( szDatadir ) )
		mkdir( szDatadir );
	
	formatex( g_szFile, charsmax( g_szFile ), "%s/volley.ini", szDatadir );
	
	if( !file_exists( g_szFile ) ) {
		write_file( g_szFile, "// Volley Spawn Editor", -1 );
		write_file( g_szFile, " ", -1 );
		
		return; // We dont need to load file
	}
	
	new szData[ 256 ], szMap[ 32 ], szOrigin[ 3 ][ 16 ];
	new iFile = fopen( g_szFile, "rt" );
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, charsmax( szData ) );
		
		if( !szData[ 0 ] || szData[ 0 ] == ';' || szData[ 0 ] == ' ' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		parse( szData, szMap, 31, szOrigin[ 0 ], 15, szOrigin[ 1 ], 15, szOrigin[ 2 ], 15 );
		
		if( equal( szMap, g_szMapname ) ) {
			new Float:vOrigin[ 3 ];
			
			vOrigin[ 0 ] = str_to_float( szOrigin[ 0 ] );
			vOrigin[ 1 ] = str_to_float( szOrigin[ 1 ] );
			vOrigin[ 2 ] = str_to_float( szOrigin[ 2 ] );
			
			CreateBall( 0, vOrigin );
			
			g_vOrigin = vOrigin;
			
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
		case 1:	{
			if( pev_valid( g_iBall ) )
				return PLUGIN_CONTINUE;
				
			CreateBall( id );
		}
		case 2: {
			new iEntity;
			
			while( ( iEntity = find_ent_by_class( iEntity, g_szBallName ) ) > 0 )
				remove_entity( iEntity );
		}
		case 3: {
			new iBall, iEntity, Float:vOrigin[ 3 ];
			
			while( ( iEntity = find_ent_by_class( iEntity, g_szBallName ) ) > 0 )
				iBall = iEntity;
			
			if( iBall > 0 )
				entity_get_vector( iBall, EV_VEC_origin, vOrigin );
			else
				return PLUGIN_HANDLED;
			
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
					formatex( szString, 255, "%s %f %f %f", g_szMapname, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
					
					write_file( g_szFile, szString, iPos - 1 );
					
					break;
				}
			}
			
			if( !bFound )
				fprintf( iFile, "%s %f %f %f^n", g_szMapname, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ] );
			
			fclose( iFile );
			
			client_print( id, print_chat, "* Successfully saved ball!" );
		}
		default: return PLUGIN_HANDLED;
	}
	
	menu_display( id, g_iButtonsMenu, 0 );
	
	return PLUGIN_HANDLED;
}

public EventRoundStart( ) {
	if( !g_bNeedBall )
		return;
	
	if( !is_valid_ent( g_iBall ) )
		CreateBall( 0, g_vOrigin );
	else {
		entity_set_vector( g_iBall, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } ); // To be sure ?
		entity_set_origin( g_iBall, g_vOrigin );
		
		entity_set_int( g_iBall, EV_INT_solid, SOLID_BBOX );
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_float( g_iBall, EV_FL_gravity, 0.7 );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		entity_set_int( g_iBall, EV_INT_iuser1, 0 );
	}
}

public FwdHamObjectCaps( id ) {
	if( pev_valid( g_iBall ) && is_user_alive( id ) ) {
		static iOwner; iOwner = pev( g_iBall, pev_iuser1 );
		
		if( iOwner == id )
			KickBall( id );
	}
}

// BALL BRAIN :)
////////////////////////////////////////////////////////////
public FwdThinkBall( iEntity ) {
	if( !is_valid_ent( g_iBall ) )
		return PLUGIN_HANDLED;
	
	entity_set_float( iEntity, EV_FL_nextthink, halflife_time( ) + 0.05 );
	
	static Float:vOrigin[ 3 ], Float:vBallVelocity[ 3 ];
	entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
	entity_get_vector( iEntity, EV_VEC_velocity, vBallVelocity );
	
	static iOwner; iOwner = pev( iEntity, pev_iuser1 );
	static iSolid; iSolid = pev( iEntity, pev_solid );
	
	// Trail --- >
	static Float:flGametime, Float:flLastThink;
	flGametime = get_gametime( );
	
	if( flLastThink < flGametime ) {
		if( floatround( vector_length( vBallVelocity ) ) > 10 ) {
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_KILLBEAM );
			write_short( g_iBall );
			message_end( );
			
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_BEAMFOLLOW );
			write_short( g_iBall );
			write_short( g_iTrailSprite );
			write_byte( 10 );
			write_byte( 10 );
			write_byte( 255 );
			write_byte( 50 );
			write_byte( 0 );
			write_byte( 150 );
			message_end( );
		}
		
		flLastThink = flGametime + 3.0;
	}
	// Trail --- <
	
	if( iOwner > 0 ) {
		static Float:vOwnerOrigin[ 3 ];
		entity_get_vector( iOwner, EV_VEC_origin, vOwnerOrigin );
		
		static const Float:vVelocity[ 3 ] = { 1.0, 1.0, 0.0 };
		
		if( !is_user_alive( iOwner ) ) {
			entity_set_int( iEntity, EV_INT_iuser1, 0 );
			
			vOwnerOrigin[ 2 ] += 5.0;
			
			entity_set_origin( iEntity, vOwnerOrigin );
			entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
			
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
		
		entity_set_vector( iEntity, EV_VEC_velocity, vVelocity );
		entity_set_origin( iEntity, vReturn );
	} else {
		if( iSolid != SOLID_BBOX )
			set_pev( iEntity, pev_solid, SOLID_BBOX );
		
		static Float:flLastVerticalOrigin;
		
		if( vBallVelocity[ 2 ] == 0.0 ) {
			static iCounts;
			
			if( flLastVerticalOrigin > vOrigin[ 2 ] ) {
				iCounts++;
				
				if( iCounts > 10 ) {
					iCounts = 0;
					
					UpdateBall( 0 );
				}
			} else {
				iCounts = 0;
				
				if( PointContents( vOrigin ) != CONTENTS_EMPTY )
					UpdateBall( 0 );
			}
			
			flLastVerticalOrigin = vOrigin[ 2 ];
		}
	}
	
	return PLUGIN_CONTINUE;
}

KickBall( id ) {
	static Float:vOrigin[ 3 ];
	
	entity_get_vector( g_iBall, EV_VEC_origin, vOrigin );
	
	if( PointContents( vOrigin ) != CONTENTS_EMPTY )
		return PLUGIN_HANDLED;

	new Float:vVelocity[ 3 ];
	velocity_by_aim( id, 450, vVelocity );
		
	set_pev( g_iBall, pev_solid, SOLID_BBOX );
	entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
	entity_set_int( g_iBall, EV_INT_iuser1, 0 );
	entity_set_vector( g_iBall, EV_VEC_velocity, vVelocity );
		
	return PLUGIN_CONTINUE;
}

// BALL TOUCHES
////////////////////////////////////////////////////////////
public FwdTouchPlayer( const iBall, const id ) {
	if( is_user_bot( id ) )
		return PLUGIN_CONTINUE;
	
	static iOwner; iOwner = pev( iBall, pev_iuser1 );
	
	if( iOwner == 0 )	
		entity_set_int( iBall, EV_INT_iuser1, id );
	
	return PLUGIN_CONTINUE;
}

public FwdTouchWorld( const iBall, const World ) {
	static Float:vVelocity[ 3 ];
	entity_get_vector( iBall, EV_VEC_velocity, vVelocity );
	
	if( floatround( vector_length( vVelocity ) ) > 10 ) {
		vVelocity[ 0 ] *= 0.75;
		vVelocity[ 1 ] *= 0.75;
		vVelocity[ 2 ] *= 0.75;
		
		entity_set_vector( iBall, EV_VEC_velocity, vVelocity );
		
		emit_sound( iBall, CHAN_ITEM, BALL_BOUNCE_GROUND, 1.0, ATTN_NORM, 0, PITCH_NORM );
	}
}


// ENTITIES CREATING
////////////////////////////////////////////////////////////
CreateBall( id, Float:vOrigin[ 3 ] = { 0.0, 0.0, 0.0 } ) {
	if( !id && vOrigin[ 0 ] == 0.0 && vOrigin[ 1 ] == 0.0 && vOrigin[ 2 ] == 0.0 )
		return 0;
	
	g_bNeedBall = true;
	
	g_iBall = create_entity( "info_target" );
	
	if( is_valid_ent( g_iBall ) ) {
		entity_set_string( g_iBall, EV_SZ_classname, g_szBallName );
		entity_set_int( g_iBall, EV_INT_solid, SOLID_BBOX );
		entity_set_int( g_iBall, EV_INT_movetype, MOVETYPE_BOUNCE );
		entity_set_float( g_iBall, EV_FL_gravity, 0.7 );
		entity_set_model( g_iBall, g_szBallModel );
		entity_set_size( g_iBall, Float:{ -15.0, -15.0, 0.0 }, Float:{ 15.0, 15.0, 12.0 } );
		
		entity_set_float( g_iBall, EV_FL_framerate, 0.0 );
		entity_set_int( g_iBall, EV_INT_sequence, 0 );
		
		entity_set_float( g_iBall, EV_FL_nextthink, get_gametime( ) + 0.05 );
		
		if( id > 0 ) {
			new iOrigin[ 3 ];
			get_user_origin( id, iOrigin, 3 );
			IVecFVec( iOrigin, vOrigin );
			
			vOrigin[ 2 ] += 5.0;
			
			entity_set_origin( g_iBall, vOrigin );
		} else
			entity_set_origin( g_iBall, vOrigin );
		
		g_vOrigin = vOrigin;
		
		return g_iBall;
	}
	
	return -1;
}
