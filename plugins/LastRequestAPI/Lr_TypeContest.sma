#include < amxmodx >
#include < LastRequest >
#include < chatcolor >

new g_szWord[ 32 ];
new bool:g_bGameStart;
new g_iLrGuy, g_iLrVictim;

public plugin_init( ) {
	register_plugin( "[LR] Typing Const", "0.1", "master4life" );
	
	Lr_RegisterGame( "Typing Contest", "FwdGameBattle", true );
	
	register_clcmd( "say", "CmdHook" );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	g_bGameStart = false;
	g_iLrGuy = g_iLrVictim = 0;
	
	remove_task( 192182 );
}

public FwdGameBattle( const id, const iVictim ) {
	Lr_RestoreHealth( id );	
	remove_task( 192182 );
	
	if( iVictim ) {
		Lr_RestoreHealth( iVictim );
		
		g_iLrGuy = id
		g_iLrVictim = iVictim;
		
		set_task( 3.0, "ReadWord", 192182 );
	}
}

public ReadWord( ) {
	new const szFile[ ] = "addons/amxmodx/configs/words.txt";
	
	new iLines = file_size( szFile, true );
	read_file( szFile, random_num( 0, iLines - 1 ), g_szWord, charsmax( g_szWord ),iLines );
	
	g_bGameStart = true;
	
	new szMessage[ 96 ];
	formatex( szMessage, charsmax( szMessage ), "The Word:^n%s", g_szWord );		
	ColorChat( 0, Red, "[ mY.RuN ]^1 The Word:^4 %s", g_szWord );
	
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
}

public CmdHook( const id ) {
	if( g_bGameStart && ( id == g_iLrVictim || id == g_iLrGuy ) ) {
		new szSaid[ 50 ];
		read_args( szSaid, 49 );
		remove_quotes( szSaid );
		
		if( equali( g_szWord, szSaid ) ) {
			g_bGameStart = false;
			
			FinishOver( id == g_iLrGuy ?  g_iLrVictim : g_iLrGuy , id )
		} 
		else if( !equali( g_szWord, szSaid ) )
			ColorChat( id, Red, "[ mY.RuN ]^1 Your word is wrong, try again." );
	}
}

public FinishOver( const iLooser, const iWinner ) {
	new szMessage[ 96 ], szName[ 2 ][ 33 ];
	
	get_user_name( iWinner, szName[ 0 ], 32 );
	get_user_name( iLooser, szName[ 1 ], 32 );
	
	formatex( szMessage, charsmax( szMessage ), "%s has won, %s dies.", szName[ 0 ], szName[ 1 ] );
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has won,^4 %s^1 dies.", szName[ 0 ], szName[ 1 ] );
	
	UTIL_DirectorMessage(
		.index       = 0, 
		.message     = szMessage,
		.red         = 90,
		.green       = 30,
		.blue        = 0,
		.x           = -1.0,
		.y           = -1.0,
		.effect      = 0,
		.fxTime      = 5.0,
		.holdTime    = 5.0,
		.fadeInTime  = 0.5,
		.fadeOutTime = 0.3
	);
	
	user_kill( iLooser );
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
