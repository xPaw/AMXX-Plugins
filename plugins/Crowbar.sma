#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >

//#define MAKE_SPARKS // Uncomment this, if you want to spawn sparks when you hit walls
//#define BLOCK_SECONDARY // Uncomment this, if you want to block secondary attack (like in HL)

new const P_CROWBAR[ ] = "models/p_crowbar.mdl";
new const V_CROWBAR[ ] = "models/v_crowbar.mdl";

const m_pPlayer               = 41;
const m_flNextPrimaryAttack   = 46;
const m_flNextSecondaryAttack = 47;

new Trie:g_tSounds, g_iShot1Decal, g_iCrowbarMdlP, g_iCrowbarMdlV;
new Beam, bool:g_bTraces;

// TODO: Fix delay times after attack (miss - more delay)

public plugin_init( ) {
	register_plugin( "Crowbar", "1.1", "xPaw" );
	
//	register_message( get_user_msgid( "DeathMsg" ), "MsgDeathMsg" );
	
	register_forward( FM_EmitSound, "FwdEmitSound" );
	register_forward( FM_TraceLine, "FwdTraceLine", 1 );
	
	RegisterHam( Ham_Item_Deploy,            "weapon_knife", "FwdHamKnifeDeploy",          1 );
	RegisterHam( Ham_Weapon_PrimaryAttack,   "weapon_knife", "FwdHamKnifePrimaryAttack",   1 );
//	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_knife", "FwdHamKnifeSecondaryAttack", 1 );
	
	g_iCrowbarMdlP = engfunc( EngFunc_AllocString, P_CROWBAR );
	g_iCrowbarMdlV = engfunc( EngFunc_AllocString, V_CROWBAR );
	g_iShot1Decal  = engfunc( EngFunc_DecalIndex, "{shot1" );
}

public plugin_end( )
	TrieDestroy( g_tSounds );

public plugin_precache( ) {
	precache_model( P_CROWBAR );
	precache_model( V_CROWBAR );
	Beam = precache_model( "sprites/laserbeam.spr" );
	g_tSounds = TrieCreate( );
	
	new const szNewSounds[ ][ ] = {
		"weapons/cbar_hitbod1.wav",
		"weapons/cbar_hitbod2.wav",
		"weapons/cbar_hitbod3.wav",
		"weapons/cbar_hitbod2.wav",
		"weapons/cbar_hitbod3.wav",
		"weapons/cbar_hit1.wav",
		"weapons/cbar_miss1.wav",
		"weapons/cbar_miss1.wav",
		"weapons/cbar_miss1.wav"
	};
	
	new const szOldSounds[ ][ ] = {
		"weapons/knife_hit1.wav",
		"weapons/knife_hit2.wav",
		"weapons/knife_hit3.wav",
		"weapons/knife_hit4.wav",
		"weapons/knife_stab.wav",
		"weapons/knife_hitwall1.wav",
		"weapons/knife_slash1.wav",
		"weapons/knife_slash2.wav",
		"weapons/knife_deploy1.wav"
	};
	
	new Trie:tPrecached = TrieCreate( ); // Precache sounds only once lol
	
	for( new i; i < sizeof szOldSounds; i++ ) {
		if( !TrieKeyExists( tPrecached, szNewSounds[ i ] ) ) {
			TrieSetCell( tPrecached, szNewSounds[ i ], 1 );
			
			precache_sound( szNewSounds[ i ] );
		}
		
		TrieSetString( g_tSounds, szOldSounds[ i ], szNewSounds[ i ] );
	}
	
	TrieDestroy( tPrecached );
}

/*public MsgDeathMsg( ) {
	new szWeapon[ 6 ];
	get_msg_arg_string( 4, szWeapon, charsmax( szWeapon ) );
	
	if( equal( szWeapon, "knife" ) )
		set_msg_arg_string( 4, "crowbar" );
}*/

public FwdHamKnifeDeploy( iKnife ) {
	new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
	
	set_pev( id, pev_viewmodel, g_iCrowbarMdlV );
	set_pev( id, pev_weaponmodel, g_iCrowbarMdlP );
	
#if defined BLOCK_SECONDARY
	set_pdata_float( iKnife, m_flNextSecondaryAttack, 9999.0, 4 );
#endif
}

public FwdHamKnifePrimaryAttack( iKnife )
	set_pdata_float( iKnife, m_flNextPrimaryAttack, 0.25, 4 );

public FwdEmitSound( id, iChannel, const szSound[ ], Float:fVol, Float:fAttn, iFlags, iPitch ) {
	static szNewSound[ 26 ];
	
	if( TrieGetString( g_tSounds, szSound, szNewSound, charsmax( szNewSound ) ) ) {
		static const HitBod[ ] = "cbar_hitbod";
		static const HitWall[ ] = "weapons/knife_hitwall1.wav";
		
		if( contain( szNewSound, HitBod ) != -1 ) { // Randromize sound as HL engine does
			static const HitBody[ ][ ] = {
				"weapons/cbar_hitbod1.wav",
				"weapons/cbar_hitbod2.wav",
				"weapons/cbar_hitbod3.wav"
			};
			
			copy( szNewSound, 25, HitBody[ random( 3 ) ] );
		}
		
		emit_sound( id, iChannel, szNewSound, fVol, fAttn, iFlags, iPitch );
		
		if( equal( szSound, HitWall ) )
			g_bTraces = true;
	//		FakeTraceLine( id, 48.0 );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public FwdTraceLine( Float:vecSrc[3], Float:vecEnd[3], noMonsters, skipEnt, tr )
{
	if( !g_bTraces || !is_user_alive( skipEnt ) )
	{
		return FMRES_IGNORED;
	}
	
	if( get_user_weapon( skipEnt ) != CSW_KNIFE )
	{
		return FMRES_IGNORED;
	}
	
	static button;
	button = pev( skipEnt, pev_button );
	
	if( !( button & IN_ATTACK ) && !( button & IN_ATTACK2 ) )
	{
		return FMRES_IGNORED;
	}
	
	static Float:flFraction;
	get_tr2( tr, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 )
	{
		return FMRES_IGNORED;
	}
	
	g_bTraces = false;
	
	static Float:vecEndPos[3];
	get_tr2( tr, TR_vecEndPos, vecEndPos );
	
	draw_laser( vecSrc, vecEndPos, 0 );
	
	return FMRES_IGNORED;
}

public draw_laser( Float:start[ 3 ], Float:end[ 3 ], iStatus ) {
    message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
    write_byte( TE_BEAMPOINTS );
    engfunc( EngFunc_WriteCoord, start[0] );
    engfunc( EngFunc_WriteCoord, start[1] );
    engfunc( EngFunc_WriteCoord, start[2] );
    engfunc( EngFunc_WriteCoord, end[0] );
    engfunc( EngFunc_WriteCoord, end[1] );
    engfunc( EngFunc_WriteCoord, end[2] );
    write_short( Beam );
    write_byte( 0 );
    write_byte( 0 );
    write_byte( 100 );
    write_byte( 10 );
    write_byte( 1 );
    write_byte( 0 );
    write_byte( iStatus ? 255 : 127 );
    write_byte( iStatus ? 0 : 255 );
    write_byte( 127 );
    write_byte( 1 );
    message_end( );
}

/*FakeTraceLine( id, Float:flDist ) {
	new Float:flFraction, Float:vStart[ 3 ], Float:vEnd[ 3 ], Float:v_forward[ 3 ], iTr = create_tr2( );
	
	new Float:vViewOfs[ 3 ], Float:vEndPos[ 3 ], pHit;
	
	pev( id, pev_origin, vStart );
	pev( id, pev_view_ofs, vViewOfs );
	
	global_get( glb_v_forward, v_forward );
	
	vStart[ 0 ] = vStart[ 0 ] + vViewOfs[ 0 ];
	vStart[ 1 ] = vStart[ 1 ] + vViewOfs[ 1 ];
	vStart[ 2 ] = vStart[ 2 ] + vViewOfs[ 2 ];
	
	vEnd[ 0 ] = vStart[ 0 ] + v_forward[ 0 ] * flDist;
	vEnd[ 1 ] = vStart[ 1 ] + v_forward[ 1 ] * flDist;
	vEnd[ 2 ] = vStart[ 2 ] + v_forward[ 2 ] * flDist;
	
	engfunc( EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, id, iTr );
	get_tr2( iTr, TR_flFraction, flFraction );
	
	if( flFraction >= 1.0 ) {
		engfunc( EngFunc_TraceHull, vStart, vEnd, DONT_IGNORE_MONSTERS, HULL_HEAD, id, iTr );
		
		get_tr2( iTr, TR_flFraction, flFraction );
		
		if( flFraction < 1.0 ) {
			pHit = get_tr2( iTr, TR_pHit );
			
			get_tr2( iTr, TR_vecEndPos, vEndPos );
			
			if( !pHit ) {
				vEnd[ 0 ] = vStart[ 0 ] + ( ( vEndPos[ 0 ] - vStart[ 0 ] ) * 2 );
				vEnd[ 1 ] = vStart[ 1 ] + ( ( vEndPos[ 1 ] - vStart[ 1 ] ) * 2 );
				vEnd[ 2 ] = vStart[ 2 ] + ( ( vEndPos[ 2 ] - vStart[ 2 ] ) * 2 );
				
				engfunc( EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, id, iTr );
				
				get_tr2( iTr, TR_flFraction, flFraction );
				
				if( flFraction < 1.0 ) {
					get_tr2( iTr, TR_vecEndPos, vEndPos );
					
					draw_laser( vStart, vEndPos, 0 );
				}
			}
		} else
			return 0;
	} else {
		pHit = get_tr2( iTr, TR_pHit );
		
		get_tr2( iTr, TR_vecEndPos, vEndPos );
	}
	
	free_tr2( iTr );
	
	if( !pHit ) {
		new Float:vEndTest[ 3 ];
		
		vEndTest[ 0 ] = vStart[ 0 ] + ( vEnd[ 0 ] - vStart[ 0 ] ) * 2;
		vEndTest[ 1 ] = vStart[ 1 ] + ( vEnd[ 1 ] - vStart[ 1 ] ) * 2;
		vEndTest[ 2 ] = vStart[ 2 ] + ( vEnd[ 2 ] - vStart[ 2 ] ) * 2;
		
		draw_laser( vStart, vEndTest, 0 );
	}
	
	if( flFraction == 0.0 )
		return 0;
	
	draw_laser( vStart, vEndPos, 1 );
	
	client_print( id, print_chat, "Fraction: %f vEnd: %f %f %f pHit: %i", flFraction, vEndPos[ 0 ], vEndPos[ 1 ], vEndPos[ 2 ], pHit );
	
//	DrawDecal( pHit, g_iShot1Decal - random( 5 ), vEnd );
	
#if defined MAKE_SPARKS
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_SPARKS );
	engfunc( EngFunc_WriteCoord, vEnd[ 0 ] );
	engfunc( EngFunc_WriteCoord, vEnd[ 1 ] );
	engfunc( EngFunc_WriteCoord, vEnd[ 2 ] );
	message_end( );
#endif
	
	return 1;
}

DrawDecal( const pHit, const iDecal, const Float:vEnd[ 3 ] ) {
	if( pev_valid( pHit ) ) {
		new szModel[ 3 ];
		pev( pHit, pev_model, szModel, 2 );
		
		if( szModel[ 0 ] != '*' ) // Entity, not map brush
			return 0;
	}
	
//	if ( VARS(pTrace->pHit)->solid == SOLID_BSP || VARS(pTrace->pHit)->movetype == MOVETYPE_PUSHSTEP )
	
	client_print( 0, print_chat, "pHit: %i iDecal: %i Msg: %i", pHit, iDecal, pHit ? TE_DECAL : TE_WORLDDECAL );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( pHit ? TE_DECAL : TE_WORLDDECAL );
	engfunc( EngFunc_WriteCoord, vEnd[ 0 ] );
	engfunc( EngFunc_WriteCoord, vEnd[ 1 ] );
	engfunc( EngFunc_WriteCoord, vEnd[ 2 ] );
	write_byte( iDecal );
	if( pHit )
		write_byte( pHit );
	message_end( );
	
	return 1;
}*/