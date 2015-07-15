#include < amxmodx >
#include < cstrike >
#include < chatcolor >

new g_iCountMenu, g_iTimer, bool:g_bCountMenu;

public plugin_init( ) {
	register_plugin( "Jail: Countdown", "0.1", "master4life" );
	
	register_clcmd( "say /cd", "HandleCoundDown" );
	register_clcmd( "say .cd", "HandleCoundDown" );
	register_clcmd( "say_team /cd", "HandleCoundDown" );
	register_clcmd( "say_team .cd", "HandleCoundDown" );
	
	g_iCountMenu = menu_create( "\rCountDown^n\d   for Race...^n   for Kreedz...^n   for Run to the Cage...", "HandleStart" );
	menu_additem( g_iCountMenu, "Start\r [ 5 Sec ]",  "0", 0 );
	menu_additem( g_iCountMenu, "Start\r [ 10 Sec ]", "1", 0 );
	menu_additem( g_iCountMenu, "Start\r [ 15 Sec ]", "2", 0 );
	menu_additem( g_iCountMenu, "Cancel",             "3", 0 );
	menu_setprop( g_iCountMenu, MPROP_EXIT, MEXIT_NEVER );
}

	
public HandleCoundDown( id ) {
	if( g_bCountMenu ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 The countdown is already running!" );
		return PLUGIN_CONTINUE;
	}
	if( !is_user_alive( id ) ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You're not^3 alive!" );
		
		return PLUGIN_CONTINUE;
	}
	if( cs_get_user_team( id ) != CS_TEAM_CT ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You're not a Guard!" );
		
		return PLUGIN_CONTINUE;
	}
	
	g_bCountMenu = true;
	
	menu_display( id, g_iCountMenu, 0 );
	
	return PLUGIN_CONTINUE;
}

public HandleStart( id, menu, item ) {
	if( item == MENU_EXIT || !is_user_alive( id ) ) return PLUGIN_CONTINUE;
	
	new szKey[ 2 ], Trash, szName[ 32 ];
	menu_item_getinfo( menu, item, Trash, szKey, 1, _, _, Trash );
		
	get_user_name( id, szName, 31 );
	switch( str_to_num( szKey ) ) {
		case 0: g_iTimer = 5;
		case 1: g_iTimer = 10;
		case 2: g_iTimer = 15;
		case 3: {
			g_bCountMenu = false;
			
			return PLUGIN_HANDLED;
		}
	}
	
	ColorChat( 0, Red, "[ mY.RuN ]^1 Guard^4 %s^1 started the^3 countdown^1!", szName );
	ColorChat( 0, Red, "[ mY.RuN ]^1 When it will reach zero, start thinking how to save your ass!" );
	
	Timer( );
	
	return PLUGIN_CONTINUE;
}

public Timer( ) {
	if( g_iTimer > 0 ) { 
		set_hudmessage( 255, 0, 0, -1.0, -1.0, 0, _, 1.0, 0.5, 0.5, 4 );
		show_hudmessage( 0, "%i", g_iTimer );
		
		new szSound[ 15 ];
		num_to_word( g_iTimer, szSound, 14 );
		client_cmd( 0, "spk fvox/%s", szSound );
		
		g_iTimer--;
		set_task( 1.0, "Timer" );
	} else {
		set_hudmessage( 255, 125, 0, -1.0, -1.0, 0, _, 1.0, 0.5, 0.5, 4 );
		show_hudmessage( 0, "Go! Go! GO!" );
		client_cmd( 0, "spk barney/letsgo" );
		
		g_bCountMenu = false;
	}
}
