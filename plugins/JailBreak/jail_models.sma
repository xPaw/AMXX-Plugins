#include < amxmodx >
#include < cstrike >
#include < fakemeta >

new const g_szHand[ ] = "models/myrun/hand.mdl";
new Trie: g_tSounds;

public plugin_init( ) {
	register_plugin( "Jail: Models", "1.0", "xPaw /master4life" );

	register_forward( FM_EmitSound, "FwdEmitSound" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "1=1", "2=29" );
}

public plugin_end( )
	TrieDestroy( g_tSounds );

public plugin_precache(){
	precache_model( "models/player/myrunct/myrunct.mdl" );
	precache_model( "models/player/myrunt/myrunt.mdl" );
	precache_model( g_szHand );
	
	g_tSounds = TrieCreate( );
	
	new const szNewSounds[ ][ ] = {
		"myrun/box_hit1.wav",
		"myrun/box_hit2.wav",
		"myrun/box_hit3.wav",
		"myrun/box_hit4.wav",
		"myrun/box_stab.wav",
		"myrun/box_hit3.wav"
	};
	
	new const szOldSounds[ ][ ] = {
		"weapons/knife_hit1.wav",
		"weapons/knife_hit2.wav",
		"weapons/knife_hit3.wav",
		"weapons/knife_hit4.wav",
		"weapons/knife_stab.wav",
		"weapons/knife_hitwall1.wav"
	};
	
	for( new i; i < sizeof szOldSounds; i++ ) {
		precache_sound( szNewSounds[ i ] );
		TrieSetString( g_tSounds, szOldSounds[ i ], szNewSounds[ i ] );
	}
}

public EventCurWeapon( const id ) {
	if( cs_get_user_team( id ) == CS_TEAM_T ) {
		set_pev( id, pev_viewmodel2, g_szHand );
		set_pev( id, pev_weaponmodel2, "" );
	}
}

public FwdEmitSound( const id, const iChannel, const szSound[ ], Float:fVol, Float:fAttn, const iFlags, const iPitch ) {
	static szNewSound[ 26 ];
	
	if( TrieGetString( g_tSounds, szSound, szNewSound, charsmax( szNewSound ) ) ) {
		if( cs_get_user_team( id ) == CS_TEAM_T ) {
			emit_sound( id, iChannel, szNewSound, fVol, fAttn, iFlags, iPitch );
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
