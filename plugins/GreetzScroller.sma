#include < amxmodx >

// SETTINGS
/////////////////////////////////////////////////
#define MAX    40    // Max nicks
#define RED    0     // Red color
#define GREEN  90    // Green color
#define BLUE   0     // Blue color

new g_iHud, g_iNicks, g_iCount, bool:g_bAlready;
new g_szNicks[ MAX ][ 60 ];

public plugin_init( ) {
	register_plugin( "Greetz scroller", "1.0", "xPaw" );
	
	register_clcmd( "say .gratz", "CmdGratz" );
	register_clcmd( "say .greez", "CmdGratz" );
	register_clcmd( "say /gratz", "CmdGratz" );
	register_clcmd( "say /greez", "CmdGratz" );
	
	g_iHud = CreateHudSyncObj( );
	g_bAlready = false;
	
	// LOAD NICKS
	////////////////////////////////////////////
	new szFile[ 64 ], szData[ 60 ];
	get_localinfo( "amxx_configsdir", szFile, charsmax( szFile ) );
	formatex( szFile, charsmax( szFile ), "%s/Greetings.txt", szFile );
	
	if( !file_exists( szFile ) ) {
		write_file( szFile, "// Greetings goes here - Plugin by xPaw", -1 );
		write_file( szFile, "// At new line new nick, use ^n for new line at once", -1 );
		write_file( szFile, " ", -1 );
	}
	
	new iFile = fopen( szFile, "rt" );
	
	while( !feof( iFile ) ) {
		fgets( iFile, szData, charsmax( szData ) );
		
		if( szData[ 0 ] == ';' || szData[ 0 ] == ' ' || ( szData[ 0 ] == '/' && szData[ 1 ] == '/' ) )
			continue;
		
		format( g_szNicks[ g_iNicks ], charsmax( g_szNicks[ ] ), szData );
		
		g_iNicks++;
	}
	
	fclose( iFile );
}

public CmdGratz( id ) {
	if( id != 1 )
		return PLUGIN_CONTINUE;
	
	if( g_bAlready )
		return PLUGIN_CONTINUE;
	
	if( g_iNicks > 0 ) {
		g_bAlready = true;
		g_iCount = 0;
		
		set_task( 0.1, "ShowNick" );
	}
	
	return PLUGIN_HANDLED;
}

public ShowNick( ) {
	if( g_iCount >= g_iNicks ) {
		g_bAlready = false;
		g_iCount = 0;
	} else {
		set_hudmessage( RED, GREEN, BLUE, -1.0, 0.25, 0, _, 2.8, 0.2, 0.3, 1 );
		
		if( g_iCount == 0 ) {
			new szMessage[ 96 ];
			formatex( szMessage, charsmax( szMessage ), "Greetz to:^n%s", g_szNicks[ g_iCount ] );
			
			ShowSyncHudMsg( 0, g_iHud, szMessage );
		} else
			ShowSyncHudMsg( 0, g_iHud, g_szNicks[ g_iCount ] );
		
		g_iCount++;
		
		set_task( 3.0, "ShowNick" );
	}
}
