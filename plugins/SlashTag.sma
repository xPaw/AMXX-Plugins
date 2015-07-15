#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <colorchat>

new g_MsgScoreAttrib;
new g_MsgStatusIcon;
new g_MsgHideWeapon;
new g_MsgCrosshair;
new g_MsgDeathMsg;
new g_iMaxClients;
new g_iVada;

new g_mdlGlassGibs;
new g_sprExplode;
new g_sprTrail;

new g_iNova[ 33 ];

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxClients )

public plugin_init() {
	register_plugin( "Slash Tag", "1.0", "xPaw" );
	
	g_iMaxClients = get_maxplayers( );
	
	g_MsgDeathMsg = get_user_msgid( "DeathMsg" );
	g_MsgStatusIcon = get_user_msgid( "StatusIcon" );
	g_MsgScoreAttrib = get_user_msgid( "ScoreAttrib" );
	g_MsgHideWeapon	= get_user_msgid( "HideWeapon" );
	g_MsgCrosshair	= get_user_msgid( "Crosshair" );
	
	// Block death body & death msg
	set_msg_block( g_MsgDeathMsg, BLOCK_SET );
	set_msg_block( get_user_msgid( "ClCorpse" ), BLOCK_SET );
	
	// No weapons shoot!
	new szWeaponName[20];
	for( new i = CSW_P228; i <= CSW_P90; i++ ) {
		if( i == CSW_KNIFE )
			continue;
		
		if( get_weaponname( i, szWeaponName, charsmax( szWeaponName ) ) )
			RegisterHam( Ham_Item_Deploy, szWeaponName, "fwdHamWeaponDeploy", 1 );
	}
	
	// Remove Gay entitys
	new const szRemoveEntities[][] = {
		"func_bomb_target", "info_bomb_target", "hostage_entity",
		"func_hostage_rescue", "info_hostage_rescue",
		"info_vip_start", "func_vip_safetyzone", "func_escapezone",
		"game_player_equip", "player_weaponstrip",
		"info_player_deathmatch", "info_map_parameters"
	};
	
	new iEntity = FM_NULLENT;
	for( new i = 0; i < sizeof szRemoveEntities; i++ ) {
		while( ( iEntity = find_ent_by_class( iEntity, szRemoveEntities[ i ] ) ) ) {
			engfunc( EngFunc_RemoveEntity, iEntity );
		}
		
		iEntity = FM_NULLENT;
	}
	
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_usp", "fwdHamWeaponDeploy", 1 );
	RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_m4a1", "fwdHamWeaponDeploy", 1 );
	RegisterHam( Ham_TakeDamage, "player",	"fwdHamTakeDamage_Player" );
	RegisterHam( Ham_Killed, "player", 	"fwdHamKilled_Player", 1 );
	
	register_event( "ResetHUD", "EventResetHUD", "be" );
	register_event( "CurWeapon", "EventCurWeapon", "be", "1!0", "2!29" );
	
	register_logevent( "EventRoundStart", 2, "0=World triggered", "1=Round_Start" );
	
	register_message( get_user_msgid( "HudTextArgs" ),	"msgHudTextArgs" );
	register_message( get_user_msgid( "StatusIcon" ),		"msgStatusIcon" );
}

public plugin_precache( ) {
	g_sprExplode = precache_model( "sprites/shockwave.spr" );
	g_sprTrail = precache_model( "sprites/laserbeam.spr" );
	
	g_mdlGlassGibs = precache_model( "models/glassgibs.mdl" );
	precache_model( "models/frostnova.mdl" );
	
	precache_sound( "warcraft3/impalehit.wav" ); // player is frozen
	precache_sound( "warcraft3/impalelaunch1.wav" ); // frozen wears off
	
	// Create own entity to block buying.
	new iEntity = create_entity( "info_map_parameters" );
	
	set_kvd( 0, KV_ClassName, "info_map_parameters" );
	set_kvd( 0, KV_KeyName, "buying" );
	set_kvd( 0, KV_Value, "3" );
	set_kvd( 0, KV_fHandled, 0 );
	
	dllfunc( DLLFunc_KeyValue, iEntity, 0 );
	dllfunc( DLLFunc_Spawn, iEntity );
	
	// Create trigger - autohealer (trigger_hurt)
	iEntity = create_entity( "trigger_hurt" );
	
	if( pev_valid( iEntity ) ) {
		DispatchKeyValue( iEntity, "classname", "trigger_hurt" );
		DispatchKeyValue( iEntity, "damagetype", "1024" );
		DispatchKeyValue( iEntity, "dmg", "-50" );
		DispatchKeyValue( iEntity, "origin", "0 0 0" );
		
		DispatchSpawn( iEntity );
		
		new Float:flMins[ 3 ] = { -4096.0, -4096.0, -4096.0 };
		new Float:flMaxs[ 3 ] = { 4096.0, 4096.0, 4096.0 };
		
		entity_set_size( iEntity, flMins, flMaxs );
		entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
	}
}

public EventRoundStart( ) {
	new iPlayer = GetRandomPlayer( );
	
	if( iPlayer > 0 )
		NewVada( iPlayer );
}

public client_disconnect( id ) {
	if( id == g_iVada ) {
		ColorChat( 0, RED, "[SlashTag]^x01 Current seeker has disconnected, making a new one!" );
		
		new iPlayer = GetRandomPlayer( );
	
		if( iPlayer > 0 )
			NewVada( iPlayer );
	}
}

public EventResetHUD( id ) {
	if( !is_user_bot( id ) ) {
		message_begin( MSG_ONE_UNRELIABLE, g_MsgHideWeapon, _, id );
		write_byte( ( 1 << 3 | 1 << 4 | 1 << 5 ) );
		message_end();
		
		message_begin( MSG_ONE_UNRELIABLE, g_MsgCrosshair, _, id );
		write_byte( 0 );
		message_end();
	}
}

public msgHudTextArgs( msg_id, msg_dest, id ) {
	static szTemp[ 17 ];
	get_msg_arg_string( 1, szTemp, sizeof( szTemp ) - 1 );
	if( equal( szTemp, "#Hint_press_buy_" ) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public msgStatusIcon( msg_id, msg_dest, id ) {
	new szIcon[ 8 ];
	get_msg_arg_string( 2, szIcon, 7 );
	
	if( equal( szIcon, "buyzone" ) )
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public fwdHamKilled_Player( id, idattacker, shouldgib ) {
	if( cs_get_user_team( id ) == CS_TEAM_T || cs_get_user_team( id ) == CS_TEAM_CT ) {
		ColorChat( 0, RED, "[SlashTag]^x01 An idiot jumped off and died :)" );
		
		set_task( 1.0, "RespawnPlayer", id );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public RespawnPlayer( id ) {
	if( !is_user_alive( id ) && ( cs_get_user_team( id ) == CS_TEAM_T || cs_get_user_team( id ) == CS_TEAM_CT ) ) {
		set_pev( id, pev_deadflag, DEAD_RESPAWNABLE );
		dllfunc( DLLFunc_Think, id );
	}
}

public fwdHamSpawn_Block( iEntity )
	return HAM_SUPERCEDE;

public fwdHamWeaponDeploy( iEntity )
	set_pdata_float( iEntity, 46, 9999.0, 4 );

public fwdHamTakeDamage_Player( id, idInflictor, idAttacker, Float:flDamage, iDamageBits ) {
	if( IsPlayer( idAttacker ) ) {
		if( g_iVada == idAttacker )
			NewVada( id, idAttacker );
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public EventCurWeapon( id )
	engclient_cmd( id, "weapon_knife" );

NewVada( id, iKiller = 0 ) {
	g_iVada = id;
	
	if( iKiller > 0 ) {
		MakeDeathMSG( iKiller, id );
		
		// Remove Glow
		RemoveGlow( iKiller );
		
		// Remove Beam
		ManageBeam( iKiller, 0 );
		
		// Remove Icon
		ManageIcon( iKiller, 0 );
		
		set_user_frags( iKiller, get_user_frags( id ) + 2 );
		
		// Give frag (why 2? because same team and you got -1)
	//	set_pev( iKiller, pev_frags, 2.0 + pev( iKiller, pev_frags ) );
	}
	
	// Froze Player
	FreezePlayer( id );
	emit_sound( id, CHAN_BODY, "warcraft3/impalehit.wav", VOL_NORM, ATTN_NORM, 0, PITCH_HIGH );
	
	// Set Glow
	SetGlow( id, Float:{ 255.0, 150.0, 0.0 } );
	
	// Ring
	new Float:vOrigin[ 3 ];
	pev( id, pev_origin, vOrigin );
	CreateBlast( vOrigin );
	
	// Set Beam
	ManageBeam( id, 1 );
	
	// Set Icon
	ManageIcon( id, 2 );
	
	// Hud msg
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	set_hudmessage( 0, 100, 255, -1.0, 0.20, 0, 2.0, 3.0, 0.3, 0.3, 2 );
	show_hudmessage( 0, "%s is new seeker!", szName );
}

public RemoveFreeze( id ) {
	ManageIcon( id, 1 );
	
	set_pev( id, pev_flags, pev( id, pev_flags ) & ~FL_FROZEN );
	
	if( pev_valid( g_iNova[ id ] ) ) {
		new iOrigin[ 3 ], Float:vOrigin[ 3 ];
		pev( g_iNova[ id ], pev_origin, vOrigin );
		FVecIVec( vOrigin, iOrigin );
		
		// add some tracers
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_IMPLOSION );
		write_coord( iOrigin[0] ); // x
		write_coord( iOrigin[1] ); // y
		write_coord( iOrigin[2] + 8 ); // z
		write_byte( 64 ); // radius
		write_byte( 10 ); // count
		write_byte( 3 ); // duration
		message_end( );
		
		// add some sparks
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_SPARKS );
		write_coord( iOrigin[0] ); // x
		write_coord( iOrigin[1] ); // y
		write_coord( iOrigin[2] ); // z
		message_end( );
		
		// add the shatter
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_BREAKMODEL );
		write_coord( iOrigin[0] ); // x
		write_coord( iOrigin[1] ); // y
		write_coord( iOrigin[2] + 24 ); // z
		write_coord( 16 ); // size x
		write_coord( 16 ); // size y
		write_coord( 16 ); // size z
		write_coord( random_num( -50, 50 ) ); // velocity x
		write_coord( random_num( -50, 50 ) ); // velocity y
		write_coord( 25 ); // velocity z
		write_byte( 10 ); // random velocity
		write_short( g_mdlGlassGibs ); // model
		write_byte( 10 ); // count
		write_byte( 25 ); // life
		write_byte( 0x01 ); // flags
		message_end( );
		
		emit_sound( g_iNova[ id ], CHAN_BODY, "warcraft3/impalelaunch1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_LOW );
		set_pev( g_iNova[ id ], pev_flags, pev( g_iNova[ id ], pev_flags ) | FL_KILLME );
	}
	
	g_iNova[ id ] = 0;
}

FreezePlayer( id ) {
	set_task( 5.0, "RemoveFreeze", id );
	
	set_pev( id, pev_flags, pev( id, pev_flags ) | FL_FROZEN );
	
	new iNova = create_entity( "info_target" );
	engfunc( EngFunc_SetSize, iNova, Float:{ -8.0, -8.0, -4.0 }, Float:{ 8.0, 8.0, 4.0 } );
	engfunc( EngFunc_SetModel, iNova, "models/frostnova.mdl" );
	
	// Random Orientation
	new Float:flAngles[ 3 ];
	flAngles[ 1 ] = random_float( 0.0, 360.0 );
	set_pev( iNova, pev_angles, flAngles );
	
	// Put nova at player's feet
	new Float:flMins[ 3 ], Float:flNovaOrigin[ 3 ];
	pev( id, pev_mins, flMins );
	pev( id, pev_origin, flNovaOrigin );
	
	flNovaOrigin[ 2 ] += flMins[ 2 ];
	engfunc( EngFunc_SetOrigin, iNova, flNovaOrigin );
	
	// Rendering
	set_pev( iNova, pev_rendercolor, Float:{ 0.0, 0.0, 150.0 } );
	set_pev( iNova, pev_rendermode, kRenderTransColor );
	set_pev( iNova, pev_renderamt, 100.0 );
	
	g_iNova[ id ] = iNova;
}

ManageIcon( id, iStatus = 0 ) {
	static const szIcon[] = "dmg_cold";
	
	message_begin( MSG_ONE_UNRELIABLE, g_MsgStatusIcon, _, id );
	write_byte( iStatus );
	write_string( szIcon );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 250 );
	message_end();
}

MakeDeathMSG( iKiller, iVictim ) {
	static const szWeapon[] = "knife";
	message_begin( MSG_BROADCAST, g_MsgDeathMsg );
	write_byte( iKiller );
	write_byte( iVictim );
	write_byte( 0 );
	write_string( szWeapon );
	message_end( );
	
	message_begin( MSG_BROADCAST, g_MsgScoreAttrib );
	write_byte( iVictim );
	write_byte( 0 );
	message_end( );
}

SetGlow( iEntity, Float:iColor[3] = { 255.0, 255.0, 255.0 } ) {
	set_pev( iEntity, pev_renderfx, kRenderFxGlowShell );
	set_pev( iEntity, pev_rendercolor, iColor );
	set_pev( iEntity, pev_rendermode, kRenderNormal );
	set_pev( iEntity, pev_renderamt, 16.0 );
}

RemoveGlow( iEntity ) {
	set_pev( iEntity, pev_renderfx, kRenderFxNone );
	set_pev( iEntity, pev_rendercolor, { 0.0, 0.0, 0.0 } );
	set_pev( iEntity, pev_rendermode, kRenderNormal );
	set_pev( iEntity, pev_renderamt, 16.0 );
}

ManageBeam( index, iStatus = 0 ) {
	message_begin( MSG_BROADCAST,SVC_TEMPENTITY );
	write_byte( TE_KILLBEAM );
	write_short( index );
	message_end( );
	
	if( iStatus == 1 ) {
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
		write_byte( TE_BEAMFOLLOW );
		write_short( index ); // entity
		write_short( g_sprTrail ); // sprite
		write_byte( 10 ); // life
		write_byte( 10 ); // width
		write_byte( 0 ); // red
		write_byte( 0 ); // green
		write_byte( 150 ); // blue
		write_byte( 150 ); // brightness
		message_end( );
	}
}

GetRandomPlayer( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	return ( iNum > 0 ) ? iPlayers[ random( iNum ) ] : 0;
}

CreateBlast( Float:flOrigin[ 3 ] ) {
	new vOrigin[ 3 ];
	FVecIVec( flOrigin, vOrigin );
	
	// smallest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(vOrigin[0]); // x
	write_coord(vOrigin[1]); // y
	write_coord(vOrigin[2]); // z
	write_coord(vOrigin[0]); // x axis
	write_coord(vOrigin[1]); // y axis
	write_coord(vOrigin[2] + 385); // z axis
	write_short(g_sprExplode); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(0); // red
	write_byte(150); // green
	write_byte(0); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(vOrigin[0]); // x
	write_coord(vOrigin[1]); // y
	write_coord(vOrigin[2]); // z
	write_coord(vOrigin[0]); // x axis
	write_coord(vOrigin[1]); // y axis
	write_coord(vOrigin[2] + 470); // z axis
	write_short(g_sprExplode); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(0); // red
	write_byte(150); // green
	write_byte(0); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// largest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(vOrigin[0]); // x
	write_coord(vOrigin[1]); // y
	write_coord(vOrigin[2]); // z
	write_coord(vOrigin[0]); // x axis
	write_coord(vOrigin[1]); // y axis
	write_coord(vOrigin[2] + 555); // z axis
	write_short(g_sprExplode); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(0); // red
	write_byte(150); // green
	write_byte(0); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// light effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(vOrigin[0]); // x
	write_coord(vOrigin[1]); // y
	write_coord(vOrigin[2]); // z
	write_byte(48); // radius
	write_byte(0); // red
	write_byte(150); // green
	write_byte(0); // blue
	write_byte(8); // life
	write_byte(40); // decay rate
	message_end();
}
