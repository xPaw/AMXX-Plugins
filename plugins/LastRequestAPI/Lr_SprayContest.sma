#include < amxmodx >
#include < achievements >
#include < fun >
#include < fakemeta >
#include < LastRequest >
#include < chatcolor >

new ACH_LR_SPRAY
new g_iLrGuy, g_hMenu, g_iGameId;
new bool:g_bJump;
new bool:g_bMode;
new bool:g_bOptional;
new bool:g_bStart;

public plugin_init( ) {
	register_plugin( "[LR] Spray Contest", "1.0", "master4life" );
	
	g_iGameId = Lr_RegisterGame( "Spray contest", "FwdGameBattle", true );
	
	register_event( "DeathMsg", "EventPlayerDeath", "a" );

	ACH_LR_SPRAY	= RegisterAchievement( "Gravity Junkie", "Win 100 spray contests", 100 );
	
	Lr_WaitForMe( g_iGameId );
}

public EventPlayerDeath( ) {
	new iKiller = read_data( 1 ), iVictim = read_data( 2 );
	
	if( iKiller != iVictim && iKiller == g_iLrGuy && is_user_alive( iKiller ) )
		AchievementProgress( iKiller, ACH_LR_SPRAY );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	g_bJump = false;
	g_bMode = false;
	g_bOptional = false;
	g_bStart = false;
	
	g_iLrGuy = 0;
	
	if( g_hMenu > 0 ) {
		menu_destroy( g_hMenu );
		g_hMenu = 0;
	}
}

public Lr_GameSelected( const id, const iGameId )
	if( iGameId == g_iGameId )
		HandleSprayMenu( id );

public FwdGameBattle( const id, const iVictim ) {
	Lr_RestoreHealth( id );
	ColorChat( id, Red, "[ mY.RuN ]^1 Your spray has been reset!" );
	set_pdata_float( id, 486, 0.1 );
	
	g_iLrGuy = id;
	
	if( iVictim ) {
		Lr_RestoreHealth( iVictim );
		ColorChat( iVictim, Red, "[ mY.RuN ]^1 Your spray has been reset!" );
		set_pdata_float( iVictim, 486, 0.1 );
	}
}

public HandleSprayMenu( id ) {
	g_hMenu = menu_create( "Choose the options", "HandleStart" );
	
	new szMessage[ 32 ];
	formatex( szMessage, charsmax( szMessage ), "Jump: %s", g_bJump ? "Lowest Wins" : "Highest Wins" );	
	menu_additem( g_hMenu, szMessage, "0" );
	
	formatex( szMessage, charsmax( szMessage ), "Mode: %sCut", g_bMode ? "" : "No " );
	menu_additem( g_hMenu, szMessage, "1" );
	
	formatex( szMessage, charsmax( szMessage ), "Tricks: %sCheats", g_bOptional ? "" : "No " );
	menu_additem( g_hMenu, szMessage, "2" );
	
	formatex( szMessage, charsmax( szMessage ), "Start: %s", g_bStart ? "Me" : "You" );
	menu_additem( g_hMenu, szMessage, "3" );
	
	menu_additem( g_hMenu, "Continue", "4" );
	
	menu_display( id, g_hMenu, 0 );
}

public HandleStart( const id, menu, item  ) {
	if( item == MENU_EXIT || !is_user_alive( id ) ) {
		menu_destroy( menu );
		
		g_hMenu = 0;
		
		return;
	}
	
	new szKey[ 2 ], Trash, iKey;
	menu_item_getinfo( menu, item, Trash, szKey, 1, _, _, Trash );
	menu_destroy( menu );
	
	g_hMenu = 0;
	
	iKey = str_to_num( szKey );
	
	switch( iKey ) {
		case 0: g_bJump = !g_bJump;
		case 1: g_bMode = !g_bMode;
		case 2: g_bOptional = !g_bOptional;
		case 3: g_bStart = !g_bStart;
		case 4: {
			new szMessage[ 96 ];
			formatex( szMessage, charsmax( szMessage ), "Spray Rules:^n%s^n%s^n%s^n%s"
			,g_bJump ? "Lowest Wins" : "Highest Wins", g_bMode ? "Cut allowed" : "No Cut", g_bOptional ? "Cheats allowed" : "No Cheats", g_bStart ? "T starts" : "CT starts" );
			
			ColorChat( 0, Red, "[ mY.RuN ]^1 Spray Rules:^4 %s^1 -^4 %s^1 -^4 %s^1 - ^4%s"
			,g_bJump ? "Lowest Wins" : "Highest Wins", g_bMode ? "Cut allowed" : "No Cut", g_bOptional ? "Cheats allowed" : "No Cheats", g_bStart ? "T starts" : "CT starts" );

			
			UTIL_DirectorMessage(
				.index       = 0, 
				.message     = szMessage,
				.red         = 90,
				.green       = 30,
				.blue        = 0,
				.x           = 0.77,
				.y           = 0.17,
				.effect      = 0,
				.fxTime      = 5.0,
				.holdTime    = 5.0,
				.fadeInTime  = 0.5,
				.fadeOutTime = 0.3
			);
			
			Lr_MoveAlong( );
		}
	}
	
	if( iKey != 4 )
		HandleSprayMenu( id );
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
