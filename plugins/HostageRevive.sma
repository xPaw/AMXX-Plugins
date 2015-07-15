#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >

/*
	1st revive:
		- Hostage have 75% HP.
		- Player got 150$
	
	2th revive:
		- Hostage have 50% HP.
		- Player got 100$
	
	3rd revive:
		- Hostage have 25% HP.
		- Player got 50$
*/

const TASK_REVIVE = 23843;

enum _:SOUNDS {
	HEAL,
	HEAL_REV,
	HEAL_NO
};

new const g_szSounds[ SOUNDS ][ ] = {
	"items/medshot5.wav",
	"items/smallmedkit1.wav",
	"items/medshotno1.wav"
};

new g_pEnabled;
new g_iMsgBarTime;
new bool:g_bReviving[ 33 ];

public plugin_init( ) {
	register_plugin( "Hostage revive", "1.0", "xPaw" );
	
//	register_dictionary( "hostage_revive.txt" );
	
	register_cvar( "hostage_revive", "1.0", FCVAR_SERVER | FCVAR_SPONLY );
	
	g_pEnabled = register_cvar( "sv_hos_revive", "1" );
	
	if( engfunc( EngFunc_FindEntityByString, -1, "classname", "hostage_entity" ) ) {
		g_iMsgBarTime = get_user_msgid( "BarTime" );
		
		register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
		
		RegisterHam( Ham_Use, "hostage_entity", "FwdHamHostageUse" );
	}
}

public plugin_precache( )
	for( new i; i < SOUNDS; i++ )
		precache_sound( g_szSounds[ i ] );

public FwdHamHostageUse( iEntity, id, iActivator, iUseType, Float:flValue ) {
	if( !get_pcvar_num( g_pEnabled ) || iUseType != 2 || pev( iEntity, pev_health ) > 0.0 )
		return HAM_IGNORED;
	
	if( cs_get_user_team( id ) != CS_TEAM_CT )
		return HAM_IGNORED;
	
	if( flValue == 1.0 ) {
		if( g_bReviving[ id ] )
			return HAM_IGNORED;
		
		if( is_user_alive( pev( iEntity, pev_euser4 ) ) ) {
			emit_sound( iEntity, CHAN_WEAPON, g_szSounds[ HEAL_NO ], 0.5, ATTN_NORM, 0, PITCH_NORM );
			
			return HAM_IGNORED;
		}
		
		new Float:flLastUse, Float:flGametime = get_gametime( );
		pev( iEntity, pev_fuser4, flLastUse );
		
		if( pev( iEntity, pev_iuser4 ) > 2 ) {
			if( flLastUse < flGametime ) {
				set_pev( iEntity, pev_fuser4, flGametime + 0.5 );
				
				emit_sound( iEntity, CHAN_ITEM, g_szSounds[ HEAL_NO ], 0.7, ATTN_NORM, 0, PITCH_NORM );
			}
			
			return HAM_IGNORED;
		}
		
		if( flLastUse < flGametime ) {
			set_pev( iEntity, pev_fuser4, flGametime + 1.0 );
			
			g_bReviving[ id ] = true;
			
			set_pev( iEntity, pev_euser4, id );
			
			message_begin( MSG_ONE_UNRELIABLE, g_iMsgBarTime, _, id );
			write_short( 3 );
			message_end( );
			
			new iParams[ 2 ]; iParams[ 0 ] = id; iParams[ 1 ] = iEntity;
			
			set_task( 0.1, "EmitSound", TASK_REVIVE + id, iParams, 2 );
			set_task( 3.0, "ReviveHostage", TASK_REVIVE + id, iParams, 2 );
			
			return HAM_SUPERCEDE;
		}
	} else {
		if( g_bReviving[ id ] ) {
			g_bReviving[ id ] = false;
			
			remove_task( TASK_REVIVE + id );
			
			message_begin( MSG_ONE_UNRELIABLE, g_iMsgBarTime, _, id );
			write_short( 0 );
			message_end( );
			
			set_pev( iEntity, pev_euser4, 0 );
		}
	}
	
	return HAM_IGNORED;
}

public EmitSound( iParams[ 2 ] )
	emit_sound( iParams[ 1 ], CHAN_ITEM, g_szSounds[ HEAL ], 0.4, ATTN_NORM, 0, PITCH_NORM );

public ReviveHostage( iParams[ 2 ] ) {
	new id = iParams[ 0 ];
	new iEntity = iParams[ 1 ];
	
	remove_task( TASK_REVIVE + id );
	
	if( !pev_valid( iEntity ) )
		return;
	
	set_pev( iEntity, pev_euser4, 0 );
	
	if( is_user_alive( id ) ) {
		client_print( id, print_center, "You revived a hostage!" );
		
		emit_sound( iEntity, CHAN_ITEM, g_szSounds[ HEAL_REV ], 0.8, ATTN_NORM, 0, PITCH_NORM );
		
		ExecuteHam( Ham_Spawn, iEntity );
		
		new Float:flHealth, iRevives = pev( iEntity, pev_iuser4 );
		
		switch( iRevives ) {
			case 0: flHealth = 75.0;
			case 1: flHealth = 50.0;
			case 2: flHealth = 25.0;
		}
		
		cs_set_user_money( id, clamp( ( cs_get_user_money( id ) + floatround( flHealth ) * 2 ), 0, 16000 ), 1 );
		
		set_pev( iEntity, pev_health, flHealth );
		set_pev( iEntity, pev_iuser3, 1 );
		set_pev( iEntity, pev_iuser4, iRevives + 1 );
	}
}

public EventNewRound( ) {
	new iEntity = FM_NULLENT;
	
	while( ( iEntity = engfunc( EngFunc_FindEntityByString, iEntity, "classname", "hostage_entity" ) ) > 0 ) {
		set_pev( iEntity, pev_euser4, 0 );
		set_pev( iEntity, pev_iuser4, 0 );
	}
	
	arrayset( g_bReviving, false, 33 );
}

public client_disconnect( id )
	g_bReviving[ id ] = false;