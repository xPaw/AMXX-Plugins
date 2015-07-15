#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < fun >
#include < chatcolor >

#define IsCt(%1)        ( cs_get_user_team( %1 ) == CS_TEAM_CT )
#define IsPlayer(%1) 	( 1 <= %1 <= g_iMaxPlayers )

#pragma semicolon 1

// Max Cts allowed
#define MAX_CTS 	5

// Reconnect Killer Time
#define RECONNECT	20.0

// HLSS Counter Kick
#define KICK_COUNTER	20

// End Round Text
new const PRISON_WIN[ ] = "Prisoners win!";
new const GUARD_WIN[ ] = "Guards win!";

// GameName from Server
new const GAME_NAME[ ] = "[ my-run.de ]";

new /*g_iDetected[ 33 ],*/ szMapname[ 32 ], g_bIsUserTe[ 33 ], g_iMaxPlayers;
new bool:g_bJustConnected[ 33 ];
new Float:g_flRoundStart, bool:g_bRoundEnd;

public plugin_init( ) {
	register_plugin( "Jail: Custom", "1.3", "xPaw / master4life" );
	
	register_concmd( "amx_ff", "CmdFF", ADMIN_KICK, "<0/1>" );
	
	register_forward( FM_GetGameDescription, "FwdGameDesc" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", true );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamTakeDamage", false );
	RegisterHam( Ham_TraceAttack, "player", "FwdHamTraceAttack", false );
	RegisterHam( Ham_Touch,       	"weaponbox", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Touch,       	"armoury_entity", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Use,       	"game_player_equip", "FwdHamPickupWeaponPre", false );
	
	//register_message( get_user_msgid( "ScoreAttrib" ), "Message_ScoreAttrib" );
	register_message( get_user_msgid( "StatusIcon" ),  "Message_StatusIcon" );
	register_message( get_user_msgid( "TextMsg" ),	   "Message_TextMsg" );
	register_message( get_user_msgid( "DeathMsg" ),	   "Message_DeathMsg" );
	
	register_event( "HLTV", "EventRoundStart", "a", "1=0", "2=0" );
	
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	
	register_clcmd( "say /cmd", "HandleSay" );
	register_clcmd( "say .cmd", "HandleSay" );
	
	set_msg_block( get_user_msgid( "ClCorpse" ), BLOCK_SET );
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	get_mapname( szMapname, 31 );
	
	g_flRoundStart 	= 250.0; // First round blubb
	g_iMaxPlayers 	= get_maxplayers( );
	
	// Remove Buyzone's
	remove_entity_name( "func_buyzone" );
	
	new Float:vAngles[ 3 ];
	
	new iEntity = g_iMaxPlayers;
	while( ( iEntity = find_ent_by_class( iEntity, "func_vehicle" ) ) > 0 ) {
		DispatchKeyValue( iEntity, "volume", "0" );
		
		entity_get_vector( iEntity, EV_VEC_angles, vAngles );
		entity_set_vector( iEntity, EV_VEC_vuser4, vAngles );
	}
	
	register_forward( FM_EmitSound, "FwdEmitSound" );
}

public CmdFF( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 3 ], bool:bFriendlyFire;
	read_argv( 1, szArg, 2 );
	
	if( szArg[ 0 ] == '1' || szArg[ 1 ] == 'n' || szArg[ 1 ] == 'N' )
		bFriendlyFire = true;
	else if( szArg[ 0 ] == '0' || szArg[ 1 ] == 'f' || szArg[ 1 ] == 'F' )
		bFriendlyFire = false;
	else {
		console_print( id, "* The value can be only 0/1 or off/on." );
		
		return PLUGIN_HANDLED;
	}
	
	if( bFriendlyFire )
	{
		arrayset( g_bIsUserTe, 0, 33 );
	}
	else
	{
		new iPlayers[ 32 ], iNum, iPlayer;
		get_players( iPlayers, iNum, "a" );
		
		for( new i; i < iNum; i++ )
		{
			iPlayer = iPlayers[ i ];
			
			g_bIsUserTe[ iPlayer ] = ( cs_get_user_team( iPlayer ) == CS_TEAM_T );
		}
	}
	
	new szName[ 32 ], iColor;
	get_user_name( id, szName, 31 );
	
	switch( get_user_team( id ) ) {
		case 2: iColor = Blue;
		case 3: iColor = Grey;
		default: iColor = Red;
	}
	
	ColorChat( 0, iColor, "^4Admin^3 %s^1: %sabled terrorist friendly fire!", szName, bFriendlyFire ? "en" : "dis" );
	
	return PLUGIN_HANDLED;
}

public EventRoundStart( ) {
	g_flRoundStart = get_gametime( ) + RECONNECT;
	g_bRoundEnd = false;

	new iEntity, Float:vAngles[ 3 ];
	while( ( iEntity = find_ent_by_class( iEntity, "func_vehicle" ) ) > 0 ) {
		entity_get_vector( iEntity, EV_VEC_vuser4, vAngles );
		entity_set_vector( iEntity, EV_VEC_angles, vAngles );
	}
}

public EventRoundEnd( )
	g_bRoundEnd = true;

public FwdHamPickupWeaponPre( const iEntity, const id )
	return g_bRoundEnd ? HAM_SUPERCEDE : HAM_IGNORED;

public plugin_precache( ) {
	RegisterHam( Ham_Spawn, "armoury_entity", "FwdArmouryEntitySpawn", true );
	
	new iEnt = create_entity( "info_map_parameters" );
	DispatchKeyValue( iEnt, "buying", "3" );
	DispatchSpawn( iEnt );
}

public FwdArmouryEntitySpawn( const iEntity )
{
	engfunc( EngFunc_DropToFloor, iEntity );
	
	set_pev( iEntity, pev_movetype, MOVETYPE_NONE );
}

public Message_StatusIcon(  const MsgId, const MsgDest, const id  ) {
	new szIcon[ 8 ]; get_msg_arg_string( 2, szIcon, 7 );
	
	if( equal( szIcon, "buyzone" ) ) {
		set_pdata_int( id, 235, get_pdata_int( id, 235, 5 ) & ~( 1<<0 ), 5 );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
	
public Message_TextMsg( const MsgId, const MsgDest, const id ) {
	new szMsg[ 16 ]; get_msg_arg_string( 2, szMsg, 15 );
	
	if( equal( szMsg, "#Terrorists_Win" ) )
		set_msg_arg_string( 2, PRISON_WIN );
	else if ( equal( szMsg, "#CTs_Win" ) )
		set_msg_arg_string( 2, GUARD_WIN );	
}

public Message_DeathMsg( ) {
	new iKiller = get_msg_arg_int( 1 );
	
	if( is_user_alive( iKiller ) && cs_get_user_team( iKiller ) == CS_TEAM_T ) {
		set_msg_arg_int( 1, ARG_BYTE, 0 );
		set_msg_arg_int( 3, ARG_BYTE, 0 );
		set_msg_arg_string( 4, "worldspawn" );
	}
	
//	return ( iKiller != get_msg_arg_int( 2 ) && is_user_alive( iKiller )
//	&& cs_get_user_team( iKiller ) == CS_TEAM_T ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

/*public Message_ScoreAttrib( const MsgId, const MsgType, const MsgDest ) {
	new id = get_msg_arg_int( 1 );
	
	if( ( get_user_flags( id ) & ADMIN_LEVEL_H ) && !get_msg_arg_int( 2 ) )
		set_msg_arg_int( 2, ARG_BYTE, ( 1 << 2 ) );
}*/

public UserStripWeapons( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	give_item( id, "weapon_knife" );
	
	if( cs_get_user_team( id ) == CS_TEAM_CT ) {
		give_item( id, "weapon_deagle" );
		cs_set_user_bpammo( id, CSW_DEAGLE, 35 );
		cs_set_user_armor( id, 100, CS_ARMOR_VESTHELM );
		
		/*if( g_bWeapons ) {
			switch( random_num( 0, 1 ) ) {
				case 0: {
					give_item( id, "weapon_m4a1" );
					cs_set_user_bpammo( id, CSW_M4A1, 90 );
				}
				case 1: {
					give_item( id, "weapon_ak47" );
					cs_set_user_bpammo( id, CSW_AK47, 90 );
				}
			}
		}*/
	}
	
	if( g_bJustConnected[ id ] ) {
		g_bJustConnected[ id ] = false;
		
		set_task( 3.0, "TaskMessages", id );
		
		if( g_flRoundStart < get_gametime( ) ) {
			ColorChat( id, Red, "[ mY.RuN ]^1 You have been killed because you joined too late." );
			
			user_kill( id, 1 );
		}
	}
}

public TaskMessages( const id ) {
	if( !is_user_alive( id ) ) {
		g_bJustConnected[ id ] = true;
		return;
	}
	
	new szName[ 32 ], iTimeleft = get_timeleft( );
	get_user_name( id, szName, 31 );
	
	ColorChat( id, Red, "[ mY.RuN ] %s^4, Welcome to the^3 mY.RuN JailBreak Server", szName );
	ColorChat( id, Red, "[ mY.RuN ]^4 Type^3 /cmd^4 to see available commands." );
	ColorChat( id, Red, "[ mY.RuN ]^4 Current Map:^3 %s^4 - Timeleft:^3 %d:%02d", szMapname, ( iTimeleft / 60 ), ( iTimeleft % 60 ) );
}

public FwdHamPlayerSpawn( id ) {
	if( !is_user_alive( id ) ) return;
	
	new CsTeams:iTeam = cs_get_user_team( id );
	
	g_bIsUserTe[ id ] = ( iTeam == CS_TEAM_T );
	
	strip_user_weapons( id );
	set_pdata_int( id, 116, 0 );
	
	set_task( 0.2, "UserStripWeapons", id );

	set_speak( id, iTeam == CS_TEAM_CT ? SPEAK_ALL | SPEAK_LISTENALL : SPEAK_MUTED | SPEAK_LISTENALL );
}

public FwdHamTraceAttack( id, iAttacker ) {
	if( IsPlayer( iAttacker ) && id != iAttacker && g_bIsUserTe[ id ] && g_bIsUserTe[ iAttacker ] )
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public FwdHamTakeDamage( id, iInflictor, iAttacker, Float:flDamage, iDamageBits ) {
	if( IsPlayer( iAttacker ) && id != iAttacker && g_bIsUserTe[ id ] && g_bIsUserTe[ iAttacker ] )
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

public HandleSay( id ) {
	ColorChat( id, Red, "[ mY.RuN ]^4 Funstuff: ^3'piss' or 'dookie'^4 in console." );
	ColorChat( id, Red, "[ mY.RuN ]^4 Mainstuff: Type in-game: ^3'rtv', '/rules', '/lr', '/cd' '/gamelist' '/day'" );
}

public FwdEmitSound( const iEntity, iChannel, const szSample[ ], Float:flVolume, Float:flAtt, iFlags, iPitch ) {
	static const Ignition  [ ] = "plats/vehicle_ignition.wav";
	static const FlashLight[ ] = "items/flashlight1.wav";
	static const Sprayer   [ ] = "player/sprayer.wav";
	
	if( equal( szSample, Sprayer ) ) {
		new iPlayer = pev( iEntity, pev_owner );
		
		new Float:vOrigin[ 3 ], Float:vViewOfs[ 3 ];
		
		pev( iPlayer, pev_origin, vOrigin );
		pev( iPlayer, pev_view_ofs, vViewOfs );
		
		vOrigin[ 0 ] += vViewOfs[ 0 ];
		vOrigin[ 1 ] += vViewOfs[ 1 ];
		vOrigin[ 2 ] += vViewOfs[ 2 ];
		
		set_pev( iEntity, pev_origin, vOrigin );
	}
	else if( equal( szSample, FlashLight ) ) {
		new Float:flGameTime = get_gametime( );
		static Float:flLast[ 33 ];
		
		if( flLast[ iEntity ] > flGameTime )
			return FMRES_SUPERCEDE;
		
		flLast[ iEntity ] = flGameTime + 0.1;
		
		emit_sound( iEntity, iChannel, szSample, 0.2, flAtt, iFlags, iPitch );
		
		return FMRES_SUPERCEDE;
	}
	else if( equal( szSample, Ignition ) ) {
		emit_sound( iEntity, iChannel, szSample, 0.4, flAtt, iFlags, iPitch );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public client_putinserver( id ) {
	//g_iDetected[ id ] = 0;
	
	if( !is_user_bot( id ) /*&& !is_user_hltv( id )*/ ) {
		set_speak( id, SPEAK_MUTED | SPEAK_LISTENALL );
	
		//set_task( 1.0, "WorkMyTrevorMagic", id );
	}
	
	g_bJustConnected[ id ] = true;
}

/*public WorkMyTrevorMagic( id )
	if( is_user_connected( id ) )
		query_client_cvar( id, "voice_inputfromfile", "QueryClientCvar" );
		
public QueryClientCvar( id, const szCvar[ ], const szValue[ ] ) {
	if( str_to_num( szValue ) != 0 ) {
		client_cmd( id, "-voicerecord; voice_inputfromfile 0" );
		
		if( g_iDetected[ id ]++ >= KICK_COUNTER )
			KickUser( id, "HLSS is not allowed on this server!" );
	}
	
	query_client_cvar( id, "voice_inputfromfile", "QueryClientCvar" );
}*/

public FwdGameDesc( ) {
	forward_return( FMV_STRING, GAME_NAME );
	return FMRES_SUPERCEDE; 
}

stock KickUser( id, const szKickMsg[ ] ) {
	emessage_begin( MSG_ONE_UNRELIABLE, SVC_DISCONNECT, _, id );
	ewrite_string( szKickMsg );
	emessage_end( );
}
