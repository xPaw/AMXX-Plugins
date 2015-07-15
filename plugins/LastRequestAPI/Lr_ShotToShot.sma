#include < amxmodx >
#include < achievements >
#include < fun >
#include < fakemeta >
#include < cstrike >
#include < hamsandwich >
#include < LastRequest >
#include < engine >
#include < chatcolor >

new ACH_SHOT, ACH_LR, ACH_1HP_REQUEST, ACH_SURVIVOR;
new g_iLrGuy, g_iLrVictim, g_iChosen, g_hMenu, g_iGameId;

enum Weapons {
	HamHook:WEP_NONE = -1,
	HamHook:WEP_DEAGLE,
	HamHook:WEP_M4A1,
	HamHook:WEP_AWP
};

new HamHook:g_iForwards[ Weapons ];
new g_iWeapon;

public plugin_init( ) {
	register_plugin( "[LR] Shot to Shot", "1.0", "master4life" );
	
	g_iGameId = Lr_RegisterGame( "Shot to shot", "FwdGameBattle", true );
	Lr_WaitForMe( g_iGameId );
	
	ACH_SHOT   = RegisterAchievement( "Shot Dueler", "Start 25 ^"Shot to Shot fights^"", 25 );
	ACH_LR     = RegisterAchievement( "Duel King", "Win 25 Last Request games.", 25 );
	ACH_1HP_REQUEST     = RegisterAchievement( "Hard work pays off", "Get last request while being on 1HP", 1 );
	ACH_SURVIVOR        = RegisterAchievement( "Survivor", "Be the last prisoner for 30 rounds", 30 );
	
	g_iForwards[ WEP_DEAGLE ] = RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_deagle", "FwdPrimaryAttackDeagle" );
	g_iForwards[ WEP_M4A1 ]   = RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_m4a1", "FwdPrimaryAttackM4a1" );
	g_iForwards[ WEP_AWP ]    = RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_awp", "FwdPrimaryAttackAwp" );
	
	DisableHamForward( g_iForwards[ WEP_DEAGLE ] );
	DisableHamForward( g_iForwards[ WEP_M4A1 ] );
	DisableHamForward( g_iForwards[ WEP_AWP ] );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	switch( g_iChosen ) {
		case 0: DisableHamForward( g_iForwards[ WEP_DEAGLE ] );
		case 1: DisableHamForward( g_iForwards[ WEP_M4A1 ] );
		case 2: DisableHamForward( g_iForwards[ WEP_AWP ] );
	}
	
	g_iLrGuy    = 0;
	g_iLrVictim = 0;
	g_iWeapon 	= _:WEP_NONE;
	
	if( g_hMenu > 0 ) {
		menu_destroy( g_hMenu );
		g_hMenu = 0;
	}

	if( bDidTerroristWin && id > 0 )
		AchievementProgress( id, ACH_LR );	
}

public Lr_GameSelected( const id, const iGameId ) {
	if( iGameId == g_iGameId ) {
		EnableHamForward( g_iForwards[ WEP_DEAGLE ] ); // Let it be the default
		g_iChosen = 0;
		
		AchievementProgress( id, ACH_SHOT );
		MenuShotToShot( id );
	}
}

public FwdGameBattle( const id, const iVictim ) {
	Lr_RestoreHealth( id );
	
	g_iLrGuy = id;
	
	if( iVictim ) {
		Lr_RestoreHealth( iVictim );
		
		g_iLrVictim = iVictim;
		
		switch( g_iChosen ) {
			case 0: {
				give_item( id, "weapon_deagle" );
				cs_set_user_bpammo( id, CSW_DEAGLE, 0 );
				cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_deagle", id ), 1 );
			} 
			case 1: {
				give_item( id, "weapon_m4a1" );
				cs_set_user_bpammo( id, CSW_M4A1, 0 );
				cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_m4a1", id ), 1 );
			}
			case 2: {
				give_item( id, "weapon_awp" );
				cs_set_user_bpammo( id, CSW_AWP, 0 );
				cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_awp", id ), 1 );
			}
		}
	}
}

public Lr_Menu_PreDisplay( const id ) {
	if( get_user_health( id ) == 1 )
		AchievementProgress( id, ACH_1HP_REQUEST );

	AchievementProgress( id, ACH_SURVIVOR );
}

public MenuShotToShot( const id ) {
	g_hMenu = menu_create( "Choose your weapon", "HandleGunToss" );
	
	switch( g_iChosen ) {
		case 0: menu_additem( g_hMenu, "Weapon:\d Deagle", "0" );
		case 1: menu_additem( g_hMenu, "Weapon:\d M4A1", "0" );
		case 2: menu_additem( g_hMenu, "Weapon:\d AWP", "0" );
	}
	
	menu_additem( g_hMenu, "Continue", "1" );
	
	menu_display( id, g_hMenu, 0 );
}

public HandleGunToss( const id, const menu, const item ) {
	if( item == MENU_EXIT || !is_user_alive( id ) ) {
		menu_destroy( menu );
		g_hMenu = 0;
		return;
	}
	
	new szKey[ 2 ], Trash;
	menu_item_getinfo( menu, item, Trash, szKey, 1, _, _, Trash );
	menu_destroy( menu );
	
	g_hMenu = 0;
	g_iWeapon = str_to_num( szKey ) 
	
	switch( g_iWeapon ) {
		case 0: {
			g_iChosen++;
			
			if( g_iChosen > 2 )
				g_iChosen = 0;
			
			switch( g_iChosen ) {
				case 0: {
					DisableHamForward( g_iForwards[ WEP_AWP ] );
					EnableHamForward( g_iForwards[ WEP_DEAGLE ] );
				}
				case 1: {
					DisableHamForward( g_iForwards[ WEP_DEAGLE ] );	
					EnableHamForward( g_iForwards[ WEP_M4A1 ] );
				}
				case 2: {
					DisableHamForward( g_iForwards[ WEP_M4A1 ] );
					EnableHamForward( g_iForwards[ WEP_AWP ] );
				}
			}
			
			MenuShotToShot( id );
		}
		case 1: {
			new szMessage[ 96 ];
			
			strip_user_weapons( id );
			
			switch( g_iChosen ) {
				case 0: {
					give_item( id, "weapon_deagle" );
					cs_set_user_bpammo( id, CSW_DEAGLE, 0 );
					cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_deagle", id ), 1 );
					
					formatex( szMessage, charsmax( szMessage ), "Shot to Shot: Deagle" );
					ColorChat( 0, Red, "[ mY.RuN ]^1 Shot to Shot:^4 Deagle" );
				} 
				case 1: {
					give_item( id, "weapon_m4a1" );
					cs_set_user_bpammo( id, CSW_M4A1, 0 );
					cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_m4a1", id ), 1 );
					
					formatex( szMessage, charsmax( szMessage ), "Shot to Shot: M4A1" );
					ColorChat( 0, Red, "[ mY.RuN ]^1 Shot to Shot:^4 M4A1" );
				}
				case 2: {
					give_item( id, "weapon_awp" );
					cs_set_user_bpammo( id, CSW_AWP, 0 );
					cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_awp", id ), 1 );
					
					formatex( szMessage, charsmax( szMessage ), "Shot to Shot: AWP" );
					ColorChat( 0, Red, "[ mY.RuN ]^1 Shot to Shot^4 AWP" );
				}
			}
			
			UTIL_DirectorMessage(
				.index       = 0,
				.message     = szMessage,
				.red         = 90,
				.green       = 30,
				.blue        = 0,
				.x           = -1.0,
				.y           = 0.2,
				.effect      = 0,
				.fxTime      = 5.0,
				.holdTime    = 5.0,
				.fadeInTime  = 0.5,
				.fadeOutTime = 0.3
			);
			
			Lr_MoveAlong( );
		}
	}
}

public FwdPrimaryAttackDeagle( const iEntity ) {
	new id = pev( iEntity, pev_owner );
	
	if( ( id != g_iLrVictim ) && ( id != g_iLrGuy ) || !is_user_alive( id ) )
		return HAM_IGNORED;
	
	SwapWeapons( id, id == g_iLrGuy ? g_iLrVictim : g_iLrGuy, "weapon_deagle" );
	
	return HAM_HANDLED;
}

public FwdPrimaryAttackM4a1( const iEntity ) {
	new id = pev( iEntity, pev_owner );
	
	if( ( id != g_iLrVictim ) && ( id != g_iLrGuy ) || !is_user_alive( id ) )
		return HAM_IGNORED;
	
	SwapWeapons( id, id == g_iLrGuy ? g_iLrVictim : g_iLrGuy, "weapon_m4a1" );
	
	return HAM_HANDLED;
}

public FwdPrimaryAttackAwp( const iEntity ) {
	new id = pev( iEntity, pev_owner );
	
	if( ( id != g_iLrVictim ) && ( id != g_iLrGuy ) || !is_user_alive( id ) )
		return HAM_IGNORED;
	
	SwapWeapons( id, id == g_iLrGuy ? g_iLrVictim : g_iLrGuy, "weapon_awp" );
	
	return HAM_HANDLED;
}

public SwapWeapons( const id, const id2, const szWeapon[] ) {	
	if( is_user_alive( id2 ) ) {
		strip_user_weapons( id2 );
		
		new szWeapon2 = give_item( id2, szWeapon );
		give_item( id2, szWeapon );
		
		cs_set_weapon_ammo( szWeapon2, 1 );
		
		strip_user_weapons( id );
		set_user_maxspeed( id, 250.0 );
	}
	
	return PLUGIN_HANDLED;
}

stock UTIL_DirectorMessage( const index, const message[], const red = 0, const green = 160, const blue = 0, 
					  const Float:x = -1.0, const Float:y = 0.65, const effect = 2, const Float:fxTime = 6.0, 
					  const Float:holdTime = 3.0, const Float:fadeInTime = 0.1, const Float:fadeOutTime = 1.5 )
{
	#define pack_color(%0,%1,%2) ( %2 + ( %1 << 8 ) + ( %0 << 16 ) )
	#define write_float(%0) write_long( _:%0 )
	
	message_begin( index ? MSG_ONE : MSG_BROADCAST, SVC_DIRECTOR, .player = index );
	{
		write_byte( strlen( message ) + 31 ); // size of write_*
		write_byte( DRC_CMD_MESSAGE );
		write_byte( effect );
		write_long( pack_color( red, green, blue ) );
		write_float( x );
		write_float( y );
		write_float( fadeInTime );
		write_float( fadeOutTime );
		write_float( holdTime );
		write_float( fxTime );
		write_string( message );
	}
	message_end( );
}
