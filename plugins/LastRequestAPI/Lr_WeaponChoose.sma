#include < amxmodx >
#include < fun >
#include < cstrike >
#include < LastRequest >

new g_hWeaponsMenu;

public plugin_init( ) {
	register_plugin( "[LR] weapon chooses", "1.0", "master4life" );
	
	Lr_RegisterGame( "Choose a Weapon", "FwdGameBattle", false );
	
	g_hWeaponsMenu = menu_create( "Choose a weapon", "HandleWeaponMenu" );
	
	menu_additem( g_hWeaponsMenu, "M4A1", "0" );
	menu_additem( g_hWeaponsMenu, "AK47", "1" );
	menu_additem( g_hWeaponsMenu, "AWP",  "2" );
	menu_additem( g_hWeaponsMenu, "Deagle", "3" ); // Stupid option? Just give all the time?
	menu_additem( g_hWeaponsMenu, "M246", "4" );
	
	menu_setprop( g_hWeaponsMenu, MPROP_EXIT, MEXIT_ALL );
}

public FwdGameBattle( const id, const iVictim ) {
	Lr_RestoreHealth( id );
	menu_display( id, g_hWeaponsMenu, 0 ); 
}

public HandleWeaponMenu( const id, const menu, const item ) {
	// Re-display menu on exit??
	// Print message to all on menu exit??
	
	if( item == MENU_EXIT || !is_user_alive( id ) )
		return;
	
	new szKey[ 2 ], iDummy;
	menu_item_getinfo( menu, item, iDummy, szKey, 1, _, _, iDummy );
	
	switch( str_to_num( szKey ) ) {
		case 0: {
			give_item( id, "weapon_m4a1" );
			cs_set_user_bpammo( id, CSW_M4A1, 90 );
		}
		case 1: {
			give_item( id, "weapon_ak47" );
			cs_set_user_bpammo( id, CSW_AK47, 90 );
		}
		case 2: {
			give_item( id, "weapon_awp" );
			cs_set_user_bpammo( id, CSW_AWP, 30 );
		}
		case 3: {
			give_item( id, "weapon_deagle" );
			cs_set_user_bpammo( id, CSW_DEAGLE, 35 );
		}
		case 4: {
			give_item( id, "weapon_m249" );
			cs_set_user_bpammo( id, CSW_M249, 200 );
		}
	}
}
