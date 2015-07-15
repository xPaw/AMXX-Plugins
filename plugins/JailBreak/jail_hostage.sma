#include < amxmodx >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >

#define IsPlayer(%1) (1 <= %1 <= g_iMaxPlayers)

new const MODEL[ ] = "models/barney.mdl";
new Trie:g_tHuds, g_iHostage, g_iMsgStatusText, g_iMaxPlayers, g_iMoney;
new bool:g_bIsHostage;

public plugin_init( ) {
	register_plugin( "Jail: Hostage Medic", "1.0", "xPaw /master4life" );
	
	register_event( "HLTV", "CreateHostage", "a", "1=0", "2=0" );
	register_event( "StatusValue", "EventStatusValue", "b", "1>0", "2>0" );
	
	register_message( get_user_msgid( "HudTextArgs" ), "HudTextArg" );
	
	set_msg_block( get_user_msgid( "Scenario" ), BLOCK_SET );
	
	register_forward( FM_EmitSound, "FwdEmitSound" );
	
	RegisterHam( Ham_Use,         "hostage_entity", "FwdHamHostageUsed" );
	RegisterHam( Ham_Killed,      "hostage_entity", "FwdHamHostageKilled" );
	RegisterHam( Ham_TraceAttack, "hostage_entity", "FwdHamTraceAttack" );
	RegisterHam( Ham_TakeDamage,  "hostage_entity", "FwdHamTakeDamage" );
	RegisterHam( Ham_TakeDamage,  "hostage_entity", "FwdHamTakeDamagePost", 1 );
	
	new const g_szHudText[ ][ ] = {
		"#Hint_removed_for_next_hostage_killed",
		"#Hint_careful_around_hostages",
		"#Hint_hostage_rescue_zone",
		"#Hint_use_hostage_to_stop_him",
		"#Hint_lead_hostage_to_rescue_point",
		"#Hint_prevent_hostage_rescue",
		"#Hint_rescue_the_hostages",
		"#Hint_press_use_so_hostage_will_follow"
	};
	
	g_tHuds = TrieCreate( );
	g_iMsgStatusText = get_user_msgid( "StatusText" );
	
	for( new i; i < sizeof g_szHudText; i++ )
		TrieSetCell( g_tHuds, g_szHudText[ i ], 1 );
	
	CreateHostage( );
}

public plugin_end( )
	TrieDestroy( g_tHuds );

public plugin_precache( ) {
	new iEntity = create_entity( "func_hostage_rescue" );
	
	if( !is_valid_ent( iEntity ) )
		set_fail_state( "Failed to create rescue zone!" );
	
	entity_set_origin( iEntity, Float:{ 0.0, 0.0, -55000.0 } );
	DispatchSpawn( iEntity );	
	
	precache_sound( "items/medshotno1.wav" );
	precache_sound( "items/medshot4.wav" );
	
	precache_model( MODEL );
}

public HudTextArg( iMsgID, iMsgDest, iMsgEnt ) {
	new szMsg[ 38 ]; get_msg_arg_string( 1, szMsg, 37 );
	
	return TrieKeyExists( g_tHuds, szMsg ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public EventStatusValue( const id ) {
	if( read_data( 1 ) == 1 ) {
		g_bIsHostage = bool:( read_data( 2 ) == 3 );
	} else {
		if( !g_bIsHostage )
			return;
		
		g_bIsHostage = false;
		
		new szMessage[ 34 ];
		formatex( szMessage, 33, cs_get_user_team( id ) == CS_TEAM_CT ? "1 Medic's %%h: %%i3%%%%" : "1 Enemy Medic" );
		
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgStatusText, _, id );
		write_byte( 0 );
		write_string( szMessage );
		message_end( );
	}
}

public FwdHamHostageKilled( const iEntity, const id ) {
	static const KILLED[ ] = "[ mY.RuN ]^4 Medic^1 has been killed.^3 Be carefull!";
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum, "ch" );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( cs_get_user_team( iPlayer ) == CS_TEAM_CT )
			ColorChat( iPlayer, Red, KILLED );
	}
}

public FwdEmitSound( const iEntity, const iChannel, const szSound[ ] )
	return ( pev_valid( iEntity ) && equal( szSound, "hostage/hos", 11 ) )
		? FMRES_SUPERCEDE : FMRES_IGNORED;

public FwdHamTraceAttack( const iEntity, const iAttacker )
	return( cs_get_user_team( iAttacker ) == CS_TEAM_CT ) 
		? HAM_SUPERCEDE : HAM_IGNORED;

public FwdHamTakeDamage( iEntity, iInflictor, iAttacker, Float:flDamage, bitsDamageType ) {
	g_iMoney = ( flDamage && IsPlayer( iAttacker ) ) ? cs_get_user_money( iAttacker ) : 0;
	
	return( cs_get_user_team( iAttacker ) == CS_TEAM_CT ) 
		? HAM_SUPERCEDE : HAM_IGNORED;
		
}

public FwdHamTakeDamagePost( iEntity, iInflictor, iAttacker, Float:flDamage, bitsDamageType ) {
	if( g_iMoney > 0 ) {
		cs_set_user_money( iAttacker, g_iMoney );
		
		g_iMoney = 0;
	}	
}

public FwdHamHostageUsed( const iEntity, const id ) {
	static Float:flLastUsed, Float:flGameTime; flGameTime = get_gametime( );
	
	if( flLastUsed > flGameTime )
		return FMRES_HANDLED;
	
	flLastUsed = flGameTime + 1.2;
	
	new Float:flHealth = entity_get_float( id, EV_FL_health );
	new Float:flHostageHealth = entity_get_float( iEntity, EV_FL_health );
	
	if( flHostageHealth > 0 ) return FMRES_HANDLED;
	
	if( flHealth < 100.0 ) {
		entity_set_float( id, EV_FL_health, floatmin( flHealth + 3.0, 100.0 ) );
		
		emit_sound( iEntity, CHAN_BODY, "items/medshot4.wav", VOL_NORM, 1.0, 0, PITCH_NORM );
	} else
		emit_sound( iEntity, CHAN_BODY, "items/medshotno1.wav", VOL_NORM, 1.0, 0, PITCH_NORM );
	
	return FMRES_SUPERCEDE;
}

public CreateHostage( ) {
	if( is_valid_ent( g_iHostage ) ) {
		entity_set_float( g_iHostage, EV_FL_health, 250.0 );
		
		return;
	}
	
	g_iHostage = create_entity( "hostage_entity" );
	
	if( !is_valid_ent( g_iHostage ) )
		return;
	
	new iEnt = find_ent_by_class( -1, "info_player_start" );
	
	if( !iEnt )
		set_fail_state( "No CT Spawn has been found!" );
	
	new Float:vOrigin[ 3 ], szOrigin[ 16 ];
	entity_get_vector( iEnt, EV_VEC_origin, vOrigin );
	formatex( szOrigin, 15, "%i %i %i", floatround( vOrigin[ 0 ] ), floatround( vOrigin[ 1 ] ), floatround( vOrigin[ 2 ] ) );
	
	remove_entity( iEnt ); // Prevent players to spawn in hostage
	
	DispatchKeyValue( g_iHostage, "model", MODEL );
	DispatchKeyValue( g_iHostage, "origin", szOrigin );
	DispatchSpawn( g_iHostage );
	
	entity_set_float( g_iHostage, EV_FL_health, 250.0 );
}
