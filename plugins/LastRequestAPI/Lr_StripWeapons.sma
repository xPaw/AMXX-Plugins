#include < amxmodx >
#include < achievements >
#include < fun >
#include < hamsandwich >
#include < LastRequest >
#include < chatcolor >

new ACH_SADIST;
new HamHook:g_iForward1;
new HamHook:g_iForward2;
new HamHook:g_iForward3;

public plugin_init( ) {
	register_plugin( "[LR] Strip weapons from CT's", "1.0", "master4life" );
	
	Lr_RegisterGame( "Strip weapons from CT's", "FwdGameBattle", false );
	ACH_SADIST = RegisterAchievement( "Sadist", "Strip weapons from Guards 25 times", 25 );
	
	g_iForward1 = RegisterHam( Ham_Touch,	"weaponbox", "FwdHamPickupWeaponPre", false );
	g_iForward2 = RegisterHam( Ham_Touch,	"armoury_entity", "FwdHamPickupWeaponPre", false );
	g_iForward3 = RegisterHam( Ham_Use, "game_player_equip", "FwdHamPickupWeaponPre", false );
	
	ToggleForwards( false );
}

public FwdHamPickupWeaponPre( const iEntity, const id )
	return get_user_team( id ) == 2 ? HAM_SUPERCEDE : HAM_IGNORED;

public FwdGameBattle( const id, const iVictim ) {
	AchievementProgress( id, ACH_SADIST );
	
	ToggleForwards( true );
	
	new iPlayers[ 32 ], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" );
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( get_user_team( iPlayer ) == 2 )
			strip_user_weapons( iPlayer );
		
		Lr_RestoreHealth( iPlayer );
	}
	
	ColorChat( 0, Red, "[ mY.RuN ]^1 You have^4 1^1 minutes to kill guards." );
	
	set_task( 60.0, "CmdWeaponBack", 146712344 );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	remove_task( 146712344 );
	
	ToggleForwards( false );
}

public CmdWeaponBack( ) {
	new iPlayers[ 32 ], iNum, i, iPlayer;
	get_players( iPlayers, iNum, "a" );
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( get_user_team( iPlayer ) == 2 ) {
			give_item( iPlayer, "weapon_m4a1" );
			
			// TODO: give ammo
		}
	}
}

ToggleForwards( const bool:bEnable ) {
	if( bEnable ) {
		EnableHamForward( g_iForward1 );
		EnableHamForward( g_iForward2 );
		EnableHamForward( g_iForward3 );
	} else {
		DisableHamForward( g_iForward1 );
		DisableHamForward( g_iForward2 );
		DisableHamForward( g_iForward3 );
	}
}
