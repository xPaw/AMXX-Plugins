#include < amxmodx >
#include < achievements >		
#include < fun >
#include < fakemeta >
#include < cstrike >
#include < hamsandwich >
#include < LastRequest >
#include < chatcolor >

new bool:g_bRambo, g_iLrGuy, ACH_ZEUS, ACH_RAMBO;

public plugin_init( ) {
	register_plugin( "[LR] Rambo", "1.0", "master4life" );
	
	register_event( "DeathMsg", "EventPlayerDeath", "a" );
	ACH_RAMBO	= RegisterAchievement( "Rocky Balboa", "Kill 100 guards while in rambo mode", 100 );
	ACH_ZEUS	= RegisterAchievement( "Zeus", "Kill Rambo 5 times", 5 );
	
	RegisterHam( Ham_CS_Item_CanDrop, "weapon_m249", "FwdHamM249DropPre", false );
	RegisterHam( Ham_Touch,       	  "weaponbox", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Touch,       	  "armoury_entity", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Use,       	  "game_player_equip", "FwdHamPickupWeaponPre", false );
	
	Lr_RegisterGame( "Rambo", "FwdGameBattle", false );
}

public FwdHamM249DropPre( const iEntity ) {
	if( g_bRambo ) {
		SetHamReturnInteger( 0 );
        
		return HAM_SUPERCEDE;
	}
    
	return HAM_IGNORED;
}

public FwdHamPickupWeaponPre( const iWeapon, const id )
	return( g_bRambo && get_user_team( id ) == 1 ) ? HAM_SUPERCEDE : HAM_IGNORED;

public EventPlayerDeath( ) {
	new iKiller = read_data( 1 ), iVictim = read_data( 2 );
	
	if( get_user_team( iKiller ) == 2 && g_iLrGuy == iVictim ) 
		AchievementProgress( iKiller, ACH_ZEUS );
	
	if( iKiller != iVictim && iKiller == g_iLrGuy && is_user_alive( iKiller ) )
		AchievementProgress( iKiller, ACH_RAMBO );
}
	
public FwdGameBattle( const id, const iVictim ) {
	g_bRambo = true;
	g_iLrGuy = id;
	
	strip_user_weapons( id );
	give_item( id, "weapon_knife" );
	give_item( id, "weapon_m249" );
	cs_set_user_bpammo( id, CSW_M249, 200 );

	new iPlayers[ 32 ], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "c" );
	
	for( i = 0; i < iNum; i++ )
		if( get_user_team( iPlayers[ i ] ) == 2 && is_user_alive( iPlayers[ i ] ) )
			iPlayer++;
	
	if( iPlayer > 1 )
		set_pev( id, pev_health, 300.0 * iPlayer );
	else 
		set_pev( id, pev_health, 300.0 );
	
	new szName[ 32 ];
	get_user_name( id, szName, charsmax( szName ) );
	
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 is RAMBO !!!", szName );
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 is RAMBO !!!", szName );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin )
	g_bRambo = false;
