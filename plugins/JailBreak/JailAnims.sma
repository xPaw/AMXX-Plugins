#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >

// https://forums.alliedmods.net/showpost.php?p=1297994&postcount=70

#define IsPlayerOnGround(%1) ( entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND )

enum _:RENDER_RESTORE
{
	Render,
	Float:Amount
};

enum _:ANIMATION
{
	Animation_szCommand[ 16 ],
	Float:Animation_flFrameRate,
	Float:Animation_flLength,
	Animation_iSequence
};

new Trie:g_tAnimations;
new g_iDummy[ 33 ];
new g_iPlayer[ 33 ];
new g_iRestore[ 33 ][ RENDER_RESTORE ];

public plugin_init( )
{
	register_plugin( "Jail: Like a baus", "1.0", "xPaw" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "1=1", "2!29" );
	
	register_think( "trigger_camera", "FwdCameraThink" );
	
	register_forward( FM_SetView, "FwdSetView" );
	register_forward( FM_CmdStart, "FwdCmdStart" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", true );
	RegisterHam( Ham_Item_PreFrame, "player", "FwdHamPlayerResetSpeed" );
	
	g_tAnimations = TrieCreate( );
	
	new const iAnimations[ ][ ANIMATION ] =
	{
		{
			".sit",
			1.0,
			0.0,
			1
		},
		{
			".sit2",
			1.0,
			0.0,
			2
		},
		{
			".wave",
			1.5,
			0.0,
			3
		},
		{
			".float",
			1.0,
			0.0,
			4
		},
		{
			".finger",
			1.0,
			1.0,
			5
		},
		{
			".scratch",
			0.8,
			1.0,
			6
		},
		{
			".pump",
			1.0,
			0.0,
			7
		},
		{
			".flip",
			1.0,
			1.0,
			8
		},
		{
			".pushup",
			1.0,
			0.0,
			10
		},
		{
			".pound",
			0.75,
			0.0,
			11
		},
		{
			".dance",
			0.5,
			0.0,
			16
		},
		{
			".dance2",
			1.0,
			0.0,
			17
		},
		{
			".beatit",
			1.8,
			0.0,
			18
		}
	};
	
	/*
		Command			Sentence		FrameRate	Length	Next
		0. "Stand"		"Stand"				1.0		0.0		-0
		1. "Sit"		"Sitting"			1.0		0.0		-0
		2. "Sit2"		"Sitting"			1.0		0.0		-0
		3. "Wave"		"Waving"			1.5		0.0		-0
		4. "Float"		"Floating"			1.0		0.0		-0
		5. "Finger"		"Giving the Finger"	1.0		1.0		0
		6. "Scratch"	"Scratching"		0.8		1.0		0
		7. "Pump"		"Fist Pumping"		1.0		0.0		-0
		8. "Flip"		"Flipping"			1.0		1.0		0
		9. "Lay"		"Laying"			1.0		0.0		-0
		10. "Pushup"	"Doing Pushups"		1.0		0.0		-0
		11. "Pound"		"Chest Pounding"	0.75	0.0		-0
		12. "Y"			"The Y"				1.0		0.0		-0
		13. "M"			"The M"				1.0		0.0		-0
		14. "C"			"The C"				1.0		0.0		-0
		15. "A"			"The A"				1.0		0.0		-0
		16. "DanceA"	"Dancing"			0.5		0.0		-0
		17. "DanceB"	"Dancing"			1.0		0.0		-0
		18. "Beatit"	"MJ Beat It"		1.8		0.0		-1
	*/
	
	new szCommand[ 20 ];
	
	for( new i; i < sizeof iAnimations; i++ )
	{
		formatex( szCommand, charsmax( szCommand ), "say %s", iAnimations[ i ][ Animation_szCommand ] );
		
		register_clcmd( szCommand, "CmdHandle" );
		
		TrieSetArray( g_tAnimations, iAnimations[ i ][ Animation_szCommand ], iAnimations[ i ], ANIMATION );
	}
}

public plugin_end( )
{
	TrieDestroy( g_tAnimations );
}

public plugin_precache( )
{
	precache_model( "models/myrun/animations_b1.mdl" );
}

public client_disconnect( id )
{
	if( g_iPlayer[ id ] )
	{
		Reset( id );
	}
}

public EventCurWeapon( id )
{
	if( g_iPlayer[ id ] )
	{
		engclient_cmd( id, "weapon_knife" );
	}
}

public FwdSetView( const id, const iEntity )
{
	if( is_user_alive( id ) && g_iPlayer[ id ] )
	{
		new iCamera = find_ent_by_owner( FM_NULLENT, "PlayerCamera", id );
		
		if( iCamera && iCamera != iEntity )
		{
			attach_view( id, iCamera );
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public FwdCmdStart( const id, const iUcHandle )
{
	if( !g_iPlayer[ id ] )
	{
		return FMRES_IGNORED;
	}
	else if( !is_user_alive( id ) )
	{
		Reset( id );
		return FMRES_IGNORED;
	}
	
	static iButtons;
	iButtons = get_uc( iUcHandle, UC_Buttons );
	
	if( iButtons > 0 )
	{
		if( iButtons & IN_USE )
		{
			Reset( id );
		}
		
		set_uc( iUcHandle, UC_Buttons, 0 );
		return FMRES_HANDLED;
	}
	
	return FMRES_IGNORED;
}

public FwdHamPlayerSpawn( const id )
{
	if( g_iPlayer[ id ] )
	{
		Reset( id );
	}
}

public FwdHamPlayerResetSpeed( const id )
{
	return g_iPlayer[ id ] ? HAM_SUPERCEDE : HAM_IGNORED;
}

public CmdHandle( const id )
{
	if( !is_user_alive( id ) || g_iPlayer[ id ] || !IsPlayerOnGround( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	new iAnimation[ ANIMATION ], szModel[ 41 ];
	read_argv( 1, szModel, charsmax( szModel ) );
	
	strtolower( szModel );
	
	client_print( id, print_chat, "Command: %s", szModel );
	
	if( !TrieGetArray( g_tAnimations, szModel, iAnimation, ANIMATION ) )
	{
		// If this ever happens... wat.
		return PLUGIN_CONTINUE;
	}
	
	new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	entity_get_vector( id, EV_VEC_v_angle, vAngles );
	
	vAngles[ 0 ] = vAngles[ 2 ] = 0.0;
	
	engfunc( EngFunc_InfoKeyValue, engfunc( EngFunc_GetInfoKeyBuffer, id ), "model", szModel, charsmax( szModel ) );
	format( szModel, charsmax( szModel ), "models/player/%s/%s.mdl", szModel, szModel );
	
	// Create animations entity
	new iPlayer = create_entity( "info_target" );
	
	assert iPlayer;
	
	entity_set_model( iPlayer, "models/myrun/animations_b1.mdl" );
	entity_set_vector( iPlayer, EV_VEC_angles, vAngles );
	entity_set_origin( iPlayer, vOrigin );
	
	//drop_to_floor( iPlayer );
	
	// Create model dummy, only for player model
	new iDummy = create_entity( "info_target" );
	
	assert iDummy;
	
	entity_set_model( iDummy, szModel );
	set_pev( iDummy, pev_movetype, MOVETYPE_FOLLOW );
	set_pev( iDummy, pev_aiment, iPlayer );
	
	// Make animations dummy solid
	engfunc( EngFunc_SetSize, iPlayer, {-16.0, -16.0, 0.0}, {16.0, 16.0, 16.0} );
	set_pev( iPlayer, pev_movetype, MOVETYPE_TOSS );
	
	// Fix head position
	set_controller( iPlayer, 0, 0.5 );
	set_controller( iPlayer, 1, 0.5 );
	
	// Set animation data
	set_pev( iPlayer, pev_sequence, iAnimation[ Animation_iSequence ] );
	set_pev( iPlayer, pev_framerate, iAnimation[ Animation_flFrameRate ] );
	
	set_pev( iPlayer, pev_frame, 0 );
	set_pev( iPlayer, pev_animtime, get_gametime( ) );
	
	// Set stuff on player himself
	g_iDummy[ id ] = iDummy;
	g_iPlayer[ id ] = iPlayer;
	
	engclient_cmd( id, "weapon_knife" );
	
	// Reset player speed
//	engfunc( EngFunc_SetClientMaxspeed, id, 1.0 );
//	entity_set_float( id, EV_FL_maxspeed, 1.0 );
	entity_set_vector( id, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
	
	g_iRestore[ id ][ Render ] = entity_get_int( id, EV_INT_rendermode );
	g_iRestore[ id ][ Amount ] = _:entity_get_float( id, EV_FL_renderamt );
	
	entity_set_int( id, EV_INT_rendermode, kRenderTransTexture );
	entity_set_float( id, EV_FL_renderamt, 0.0 );
	
	// Copy render from player to dummy
	entity_get_vector( id, EV_VEC_rendercolor, vOrigin );
	
	entity_set_int( iDummy, EV_INT_renderfx, entity_get_int( id, EV_INT_renderfx ) );
	entity_set_int( iDummy, EV_INT_rendermode, g_iRestore[ id ][ Render ] );
	entity_set_float( iDummy, EV_FL_renderamt, g_iRestore[ id ][ Amount ] );
	entity_set_vector( iDummy, EV_VEC_rendercolor, vOrigin );
	
	PlayerCamera( id );
	
	return PLUGIN_HANDLED;
}

Reset( const id )
{
	if( is_valid_ent( g_iDummy[ id ] ) )
	{
		remove_entity( g_iDummy[ id ] );
	}
	
	if( is_valid_ent( g_iPlayer[ id ] ) )
	{
		remove_entity( g_iPlayer[ id ] );
	}
	
	g_iPlayer[ id ] = g_iDummy[ id ] = 0;
	
	ExecuteHam( Ham_Item_PreFrame, id );
	
	entity_set_int( id, EV_INT_rendermode, g_iRestore[ id ][ Render ] );
	entity_set_float( id, EV_FL_renderamt, g_iRestore[ id ][ Amount ] );
	
	RemoveCamera( id );
}

PlayerCamera( id )
{
	/*new iCamera = find_ent_by_owner( FM_NULLENT, "PlayerCamera", id );
	
	if( iCamera )
	{
		attach_view( id, iCamera );
		return;
	}*/
	
	new iEnt = create_entity( "trigger_camera" );
	set_kvd(0, KV_ClassName, "trigger_camera")
	set_kvd(0, KV_fHandled, 0)
	set_kvd(0, KV_KeyName, "wait")
	set_kvd(0, KV_Value, "999999")
	dllfunc(DLLFunc_KeyValue, iEnt, 0)
	//DispatchKeyValue( iEnt, "wait", "999999" );
	//DispatchSpawn( iEnt );

	set_pev(iEnt, pev_spawnflags, SF_CAMERA_PLAYER_TARGET|SF_CAMERA_PLAYER_POSITION)
	set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_ALWAYSTHINK)
	set_pev( iEnt, pev_owner, id );
	
	DispatchSpawn( iEnt );
	
	ExecuteHam(Ham_Use, iEnt, id, id, 3, 1.0)
}

RemoveCamera( const id )
{
	attach_view( id, id );
	
	new iCamera = find_ent_by_owner( FM_NULLENT, "PlayerCamera", id );
	
	if( iCamera )
	{
		remove_entity( iCamera );
	}
}

public FwdCameraThink( iEnt )
{
	new id = entity_get_edict( iEnt, EV_ENT_owner );
	
	if( !id ) return;
	
	static Float:fVecPlayerOrigin[3], Float:fVecCameraOrigin[3], Float:fVecAngles[3], Float:fVecBack[3]
	
	pev(id, pev_origin, fVecPlayerOrigin)
	pev(id, pev_view_ofs, fVecAngles)
	fVecPlayerOrigin[2] += fVecAngles[2]
	
	pev(id, pev_v_angle, fVecAngles)
	
	angle_vector(fVecAngles, ANGLEVECTOR_FORWARD, fVecBack)
	
	engfunc(EngFunc_TraceLine, fVecPlayerOrigin, fVecCameraOrigin, IGNORE_MONSTERS, id, 0)
	static Float:flFraction
	flFraction = get_tr2(0, TR_flFraction, flFraction) * 150.0;
	
	fVecCameraOrigin[0] = fVecPlayerOrigin[0] + (-fVecBack[0] * flFraction)
	fVecCameraOrigin[1] = fVecPlayerOrigin[1] + (-fVecBack[1] * flFraction)
	fVecCameraOrigin[2] = fVecPlayerOrigin[2] + (-fVecBack[2] * flFraction)
	
	set_pev(iEnt, pev_origin, fVecCameraOrigin)
	set_pev(iEnt, pev_angles, fVecAngles)
}
