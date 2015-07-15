#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < cstrike >
#include < chatcolor >

#pragma dynamic 10240

new const g_szGamename[ ] = "[ my-run.de ]";

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )

new const g_szAliveFlags[ ] = "a";
new g_iPlayers[ 32 ], g_iNum, g_iPlayer, g_iMaxPlayers, i;
new g_iTeam[ 33 ], g_iSpectatedId[ 33 ], g_iStripper;
new bool:g_bInvisWater[ 33 ], bool:g_bInvisPlayers[ 33 ];
new Float:g_flSpawnedAt[ 33 ];

new g_szEntityString[ 2 ];
new bool:g_bRoundRunning;
new bool:g_bAllowGrenade;
new bool:g_bDontResetButtons;
new Trie:g_tWaterEntities;

public plugin_init( )
{
	register_plugin( "Deathrun Features", "2.0", "xPaw" );
	
	FindWaterEnts( );
	
	new szMap[ 32 ];
	get_mapname( szMap, 31 );
	
	if( equali( szMap, "deathrun_w0rms" )
	||  equali( szMap, "deathrun_death" )
	||  equali( szMap, "deathrun_taringacs_inthetetris" ) )
	{
		g_bDontResetButtons = true;
	}
	else if( equali( szMap, "deathrun_burnzone" ) )
	{
		g_bAllowGrenade = true;
	}
	
	register_menucmd( register_menuid( "Invisibility" ), 1023, "HandleInvisMenu" );
	
	register_impulse( 201, "Fwd_Impulse201" );
	
	register_think( "func_breakable", "FwdThinkBreak" );
	
	register_forward( FM_ClientKill,         "FwdClientKill" );
	register_forward( FM_GetGameDescription, "FwdGameDescription" );
	register_forward( FM_ShouldCollide,      "FwdShouldCollide" );
	register_forward( FM_AddToFullPack,      "FwdAddToFullPack", true );
	
	RegisterHam( Ham_TakeDamage,      "player", "FwdHamPlayerDamage" );
	RegisterHam( Ham_Player_PreThink, "player", "FwdHamPlayerPreThink", true );
	RegisterHam( Ham_Killed,          "player", "FwdHamPlayerKilled",   true );
	RegisterHam( Ham_Spawn,           "player", "FwdHamPlayerSpawn",    true );
	
	register_event( "HLTV",        "EventNewRound",    "a",  "1=0", "2=0" );
	register_event( "CurWeapon",   "EventCurWeapon",   "be", "1=1" );
	register_event( "TeamInfo",    "EventTeamInfo",    "a" );
	register_event( "SpecHealth2", "EventSpecHealth2", "bd" );
	
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	
	//register_message( get_user_msgid( "ScoreAttrib" ), "MsgScoreAttrib" );
	
	//set_msg_block( get_user_msgid( "MOTD" ),        BLOCK_SET );
	set_msg_block( get_user_msgid( "Geiger" ),      BLOCK_SET );
	set_msg_block( get_user_msgid( "ClCorpse" ),    BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	register_clcmd( "radio1", "CmdRadio" );
	register_clcmd( "radio2", "CmdRadio" );
	register_clcmd( "radio3", "CmdRadio" );
	
	register_clcmd( "chooseteam", "CmdJoinTeam" );
	register_clcmd( "jointeam",   "CmdJoinTeam" );
	
	register_clcmd( "say /invis",        "CmdInvis" );
	register_clcmd( "say /invisibility", "CmdInvis" );
	
	g_iMaxPlayers = get_maxplayers( );
}

public plugin_end( )
	if( g_tWaterEntities )
		TrieDestroy( g_tWaterEntities );

public plugin_precache( )
{
	precache_model( "models/player/vip/vip.mdl" );
	
	new iEnt = create_entity( "info_map_parameters" );
	DispatchKeyValue( iEnt, "buying", "3" );
	DispatchSpawn( iEnt );
	
	iEnt = create_entity( "func_buyzone" );
	entity_set_size( iEnt, Float:{ -4096.0, -4096.0, -4096.0 }, Float:{ -4095.0, -4095.0, -4095.0 } );
	entity_set_int( iEnt, EV_INT_iuser1, 1337 );
	
	g_iStripper = create_entity( "player_weaponstrip" );
	DispatchSpawn( g_iStripper );
}

public client_disconnect( id )
{
	g_bInvisWater  [ id ] = false;
	g_bInvisPlayers[ id ] = false;
	g_iSpectatedId [ id ] = 0;
}

public CmdJoinTeam( const id )
{
	if( g_bRoundRunning && is_user_alive( id ) && cs_get_user_team( id ) == CS_TEAM_T )
	{
		ColorChat( id, Red, "[ mY.RuN ]^x01 You can't change team before round end." );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public CmdInvis( const id )
{
	new szMenu[ 156 ];
	
	new iLen = formatex( szMenu, charsmax( szMenu ), "\rmY.RuN \y- \wInvisibility by xPaw^n^n" );
	
	iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r1. \wPlayers: \y%s^n", g_bInvisPlayers[ id ] ? "ON" : "OFF" );
	iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r2. \wWater: %s^n^n", g_tWaterEntities ? ( g_bInvisWater[ id ] ? "\yON" : "\yOFF" ) : "\dNo water" );
	iLen += formatex( szMenu[ iLen ], charsmax( szMenu ) - iLen, "\r0. \wExit" );
	
	show_menu( id, ( 1<<0 | 1<<1 | 1<<9 ), szMenu, -1, "Invisibility" );
	
	return PLUGIN_HANDLED;
}

public HandleInvisMenu( const id, iKey )
{
	switch( iKey )
	{
		case 0: {
			g_bInvisPlayers[ id ] = !g_bInvisPlayers[ id ];
			
			if( g_bInvisPlayers[ id ] )
				ColorChat( id, Red, "[ mY.RuN ]^x01 CT Players are now invisible." );
			else
				ColorChat( id, Red, "[ mY.RuN ]^x01 CT Players are now visible." );
			
			CmdInvis( id );
		}
		case 1: {
			if( g_tWaterEntities ) {
				g_bInvisWater[ id ] = !g_bInvisWater[ id ];
				
				if( g_bInvisWater[ id ] )
					ColorChat( id, Red, "[ mY.RuN ]^x01 Water is now invisible." );
				else
					ColorChat( id, Red, "[ mY.RuN ]^x01 Water is now visible." );
			}
			
			CmdInvis( id );
		}
	}
	
	return PLUGIN_HANDLED;
}

public CmdRadio( const id )
	return PLUGIN_HANDLED_MAIN;

public EventSpecHealth2( const id )
	g_iSpectatedId[ id ] = read_data( 2 );

public EventTeamInfo( ) {
	new szTeamInfo[ 2 ], id = read_data( 1 );
	read_data( 2, szTeamInfo, 1 );
	
	switch( szTeamInfo[ 0 ] )
	{
		case 'T': g_iTeam[ id ] = 1;
		case 'C': g_iTeam[ id ] = 2;
		case 'S': g_iTeam[ id ] = 3;
		default : g_iTeam[ id ] = 0;
	}
}

public EventCurWeapon( const id )
{
	if( g_iTeam[ id ] == 1 )
	{
		new iWeapon = read_data( 2 );
		
		if( g_bAllowGrenade && iWeapon == CSW_HEGRENADE )
			return;
		
		if( iWeapon != CSW_KNIFE && iWeapon != CSW_FLASHBANG )
			engclient_cmd( id, "weapon_knife" );
	}
}

public EventRoundEnd( )
{
	g_bRoundRunning = false;
}

public EventNewRound( )
{
	g_bRoundRunning = true;
	
	remove_task( 9797976 );
	set_task( 60.0, "TaskAfkBomb", 9797976 );
	set_task( 0.1, "Fucking_AMXX_Sucks" );
	
	if( !g_bDontResetButtons )
	{
		set_task( 1.0, "TaskResetButtons" );
	}
	
/*	i = g_iMaxPlayers + 1;
	while( ( i = find_ent_by_class( i, "func_pushable" ) ) > 0 )
	{
		entity_set_vector( i, EV_VEC_velocity, Float:{ 0.0, 0.0, 0.0 } );
		entity_set_origin( i, Float:{ 0.0, 0.0, 1.0 } );
	}	*/
}

public TaskResetButtons( )
{
	i = g_iMaxPlayers + 1;
	while( ( i = find_ent_by_class( i, "func_button" ) ) > 0 )
	{
		call_think( i );
	}
}

public Fucking_AMXX_Sucks( )
{
	new iNum;
	static iPlayers[ 32 ];
	get_players( iPlayers, iNum, "c" );
	
	if( iNum > 1 )
	{
		new id, iTeam, iLegalNum, iLegal[ 32 ];
		static iLastPlayer;
		
		for( i = 0; i < iNum; i++ )
		{
			id    = iPlayers[ i ];
			iTeam = g_iTeam[ id ];
			
			if( iTeam == 1 )
				goto End;
			else if( iTeam == 2 && iLastPlayer != id )
				iLegal[ iLegalNum++ ] = id;
		}
		
		if( iLegalNum > 0 )
		{
			new iRandom = iLegal[ random( iLegalNum ) ];
			
			g_iTeam[ iRandom ] = 1;
			
			cs_set_user_team( iRandom, CS_TEAM_T );
			
			entity_set_int( iRandom, EV_INT_solid, SOLID_BBOX ); // Semiclip bugfix
			
			ExecuteHam( Ham_Spawn, iRandom );
			
			iLastPlayer = iRandom;
		}
	}
	
End:
	return;
}

public TaskAfkBomb( )
{
	new iEntity, id, Float:vOrigin[ 3 ], Float:flGameTime = get_gametime( );
	
	while( ( iEntity = find_ent_by_class( iEntity, "info_player_start" ) ) > 0 )
	{
		entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
		
		id = -1;
		
		while( ( id = find_ent_in_sphere( id, vOrigin, 96.0 ) ) > 0 )
		{
			if( id > g_iMaxPlayers )
				break;
			
			if( flGameTime > ( g_flSpawnedAt[ id ] + 30.0 ) && is_user_alive( id ) )
			{
				user_kill( id );
				
				set_hudmessage( 0, 100, 255, -1.0, 0.4, 0, 0.0, 12.0, 0.2, 0.2 );
				show_hudmessage( id, "***^n* AFK BOMB *^n***" );
			}
		}
	}
}

/*
public MsgScoreAttrib( const iMsgID, const iMsgDest, const id )
	if( !get_msg_arg_int( 2 ) && get_user_flags( get_msg_arg_int( 1 ) ) & ADMIN_LEVEL_H )
		set_msg_arg_int( 2, ARG_BYTE, ( 1 << 2 ) );
*/

public FwdAddToFullPack( es, e, iEnt, id, hostflags, player, pSet )
{
	if( !get_orig_retval( ) )
		return;
	
	if( player )
	{
		if( id != iEnt && g_iTeam[ id ] == 2 && g_iTeam[ iEnt ] == 2 )
		{
			set_es( es, ES_Solid, SOLID_NOT );
			
			if( iEnt == g_iSpectatedId[ id ] )
				return;
			
			if( g_bInvisPlayers[ id ] )
			{
				static const Float:vOrigin[ 3 ] = { 0.0, 0.0, -9999.0 };
				
				set_es( es, ES_Origin, vOrigin );
				set_es( es, ES_Effects, get_es( es, ES_Effects ) | EF_NODRAW );
				
				return;
			}
			
			static Float:flDistance;
			flDistance = entity_range( id, iEnt );
			
			if( flDistance < 512.0 )
			{
				set_es( es, ES_RenderMode, kRenderTransAlpha )
				set_es( es, ES_RenderAmt, floatround( flDistance ) / 2 );
			}
		}
	}
	else if( g_tWaterEntities && g_bInvisWater[ id ] ) {
		g_szEntityString[ 0 ] = iEnt;
		
		if( TrieKeyExists( g_tWaterEntities, g_szEntityString ) )
			set_es( es, ES_Effects, EF_NODRAW );
	}
}

public FwdThinkBreak( const iEntity )
{
	if( entity_get_int( iEntity, EV_INT_solid ) == SOLID_NOT )
	{
		new iEffects = entity_get_int( iEntity, EV_INT_effects );
		
		if( ~iEffects & EF_NODRAW )
			entity_set_int( iEntity, EV_INT_effects, iEffects | EF_NODRAW );
		
		entity_set_int( iEntity, EV_INT_deadflag, DEAD_DEAD );
	}
}

public FwdShouldCollide( const iTouched, const iOther )
{
	if( IsPlayer( iTouched ) && IsPlayer( iOther ) && g_iTeam[ iTouched ] == 2 && g_iTeam[ iOther ] == 2 )
	{
		if( is_user_alive( iTouched ) && is_user_alive( iOther ) )
		{
			static Float:flDistance;
			flDistance = entity_range( iTouched, iOther );
			
			if( flDistance < 50.0 )
			{
				forward_return( FMV_CELL, 0 );
				return FMRES_SUPERCEDE;
			}
		}
	}
	
	return FMRES_IGNORED;
}

public FwdGameDescription( )
{
	forward_return( FMV_STRING, g_szGamename );
	
	return FMRES_SUPERCEDE; 
}

public FwdClientKill( const id )
{
	if( is_user_alive( id ) && g_iTeam[ id ] == 1 )
	{
		ColorChat( id, Red, "[ mY.RuN ]^4 You can't suicide as a terrorist!" );
		console_print( id, "Can't suicide -- terrorist!" );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Fwd_Impulse201( const id, const iUcHandle, const iSeed )
{
	if( is_user_alive( id ) )
		client_print( id, print_center, "** Spray is disabled on this server! **" );
	
	return PLUGIN_HANDLED_MAIN;
}

public FwdHamPlayerDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
	return ( iDamageBits & DMG_FALL && g_iTeam[ id ] == 1 ) ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamPlayerSpawn( const id )
{
	if( !is_user_alive( id ) )
		return;
	
	g_iSpectatedId[ id ] = 0;
	g_iTeam       [ id ] = _:cs_get_user_team( id );
	g_flSpawnedAt [ id ] = get_gametime( );
	
	force_use( id, g_iStripper ); // strip_user_weapons( id );
	give_item( id, "weapon_knife" );
	
	set_pdata_int( id, 116, 0 ); // No primary weapon
	set_pdata_int( id, 192, 0 ); // Zero radio uses
	
	if( get_user_flags( id ) & ADMIN_KICK )
		cs_set_user_model( id, "vip" );
}

public FwdHamPlayerKilled( const id )
{
	if( g_iTeam[ id ] != 2 )
		return;
	
	get_players( g_iPlayers, g_iNum, g_szAliveFlags );
	
	for( i = 0; i < g_iNum; i++ )
	{
		entity_set_int( g_iPlayers[ i ], EV_INT_solid, SOLID_SLIDEBOX );
	}
}

public FwdHamPlayerPreThink( const id )
	Semiclip( id, SOLID_NOT );

public client_PostThink( id )
	Semiclip( id, SOLID_SLIDEBOX );

Semiclip( const id, const iSolid )
{
	if( g_iTeam[ id ] != 2 || !is_user_alive( id ) )
		return;
	
	get_players( g_iPlayers, g_iNum, g_szAliveFlags );
	
	for( i = 0; i < g_iNum; i++ )
	{
		g_iPlayer = g_iPlayers[ i ];
		
		if( id != g_iPlayer && g_iTeam[ g_iPlayer ] == 2 )
			entity_set_int( g_iPlayer, EV_INT_solid, iSolid );
	}
}

FindWaterEnts( )
{
	new iSkin, iEntity = g_iMaxPlayers + 1;
	
	// Remove buyzone on map
	while( ( iEntity = find_ent_by_class( iEntity, "func_buzyone" ) ) )
		if( entity_get_int( iEntity, EV_INT_iuser1 ) != 1337 )
			remove_entity( iEntity );
	
	iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_water" ) ) )
	{
		entity_set_float( iEntity, EV_FL_scale, 0.0 );
		
		AddWaterEntity( iEntity );
	}
	
	iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_conveyor" ) ) )
		if( entity_get_int( iEntity, EV_INT_spawnflags ) == 3 )
			AddWaterEntity( iEntity );
	
	iEntity = g_iMaxPlayers + 1;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_illusionary" ) ) )
	{
		iSkin = entity_get_int( iEntity, EV_INT_skin );
		
		if( iSkin == CONTENTS_WATER || iSkin == CONTENTS_SLIME )
			AddWaterEntity( iEntity );
	}
}

AddWaterEntity( const iEntity ) {
	if( !g_tWaterEntities ) g_tWaterEntities = TrieCreate( );
	
	g_szEntityString[ 0 ] = iEntity;
	TrieSetCell( g_tWaterEntities, g_szEntityString, true );
}
