#include < amxmodx >
#include < sockets >
#include < chatcolor >

#pragma semicolon 1

new const DIRECTORY_DATA[ ]      = "addons/amxmodx/data/kreedz";
new const FILE_LAST_UPDATE[ ]    = "addons/amxmodx/data/kreedz/sc_last_update.ini";
new const FILE_AVAILABLE_MAPS[ ] = "addons/amxmodx/data/kreedz/sc_available_maps.txt";
new const PICTURE_DIRECTORY[ ]   = "http://xtreme-jumps.eu/shortcuts/shortcuts";

new g_iAvailableMaps;
new Trie:g_trieAvailableMaps;
new Array:g_arrayAvailableMaps;

new g_hSocketId;

public plugin_init( ) {
	register_plugin( "KZ Shortcuts", "1.0", "SchlumPF" );
	register_clcmd( "say", "hookSay" );
}

public plugin_cfg( ) {
	g_arrayAvailableMaps = ArrayCreate( 32 );
	g_trieAvailableMaps = TrieCreate( );
	
	if( !dir_exists( DIRECTORY_DATA ) )
		mkdir( DIRECTORY_DATA );
	
	new year, month, day;
	date( year, month, day );
	
	if( !file_exists( FILE_LAST_UPDATE ) ) {
		updateAvailableMaps( year, month, day );
		return PLUGIN_CONTINUE;
	}
	
	new buffer[32];
	new f = fopen( FILE_LAST_UPDATE, "rt" );
	fgets( f, buffer, 31 );
	fclose( f );
	
	if( str_to_num( buffer[0] ) < year || str_to_num( buffer[5] ) < month || str_to_num( buffer[8] ) < day )
		updateAvailableMaps( year, month, day );
	else
		storeAvailableMaps( );
	
	return PLUGIN_CONTINUE;
}

public updateAvailableMaps( year, month, day ) {
	new curDate[128];
	new f = fopen( FILE_LAST_UPDATE, "wt" );
	format( curDate, 128, "%04ix%02ix%02i", year, month, day );
	fputs( f, curDate );
	fclose( f );
	
	new error;
	g_hSocketId = socket_open( "xtreme-jumps.eu", 80, SOCKET_TCP, error );
	
	new message[256];
	formatex( message, 255, "GET /shortcuts/sc.php HTTP/1.0^nHost: xtreme-jumps.eu^r^n^r^n" );
	
	socket_send( g_hSocketId, message, 255 );
	
	if( file_exists( FILE_AVAILABLE_MAPS ) )
		delete_file( FILE_AVAILABLE_MAPS );
	
	readWeb( );
}

public readWeb( ) {
	new buffer[2048];
	socket_recv( g_hSocketId, buffer, 2047 );
	
	if( buffer[0] ){
		replace_all( buffer, 2047, "|", "^n" );
		
		new f = fopen( FILE_AVAILABLE_MAPS, "at" );
		fputs( f, buffer );
		fclose( f );
		
		set_task( 0.5,"readWeb" );
	} else {
		storeAvailableMaps( );
		socket_close( g_hSocketId );
	}
}

public storeAvailableMaps( ) {
	new bool:data;
	
	new buffer[256];
	new f = fopen( FILE_AVAILABLE_MAPS, "rt" );
	while( !feof( f ) ) {
		fgets( f, buffer, 255 );
		replace_all( buffer, 255, "^n", "" );
		
		if( data ) {
			ArrayPushString( g_arrayAvailableMaps, buffer );
			TrieSetCell( g_trieAvailableMaps, buffer, 1337 );
			
			g_iAvailableMaps++;
		}
		else if( equal( buffer, "i like turtles, bitch!" ) )
			data = true;
	}
	fclose( f );
}

public hookSay( plr ) {
	static command[64];
	read_args( command, 32 );
	remove_quotes( command );
	
	if( !( equal( command, "/sc", 3 ) || equal( command, "/scs", 4 ) || equal( command, "/shortcuts", 10 ) ) )
		return PLUGIN_CONTINUE;
	
	static pattern[64], pos;
	if( ( pos = contain( command, " " ) ) > -1 )
		formatex( pattern, 63, "%s", command[pos+1] );
	else
		get_mapname( pattern, 63 );
	
	if( TrieKeyExists( g_trieAvailableMaps, pattern ) ) {
		static motd[256];
		formatex( motd, 255, "%s/%s.jpg", PICTURE_DIRECTORY, pattern );
			
		show_motd( plr, motd, "[ Shortcuts ]" );
	} else {
		static menuitem[64], map[64];
		static menu, items;
		
		menu = menu_create( "\r#kz.xPaw \wShortcuts", "menuMapHandler" );
		items = 0;
		
		for( new i; i < g_iAvailableMaps; i++ ) {
			ArrayGetString( g_arrayAvailableMaps, i, map, 63 );
			
			if( containi( map, pattern ) > -1 ) {
				formatex( menuitem, 63, "\w%s", map );
				menu_additem( menu, menuitem, map );
				
				items++;
			}
		}
		
		if( items )
			menu_display( plr, menu, 0 );
		else
			ColorChat( plr, Red, "[ mY.RuN ]^1 Could not find ^4'%s'^1 in the database!", pattern );
	}
	
	return PLUGIN_HANDLED;
}

public menuMapHandler( plr, menu, item ) {
	if( item == MENU_EXIT ) {
		menu_destroy( menu );
		return PLUGIN_HANDLED;
	}
	
	static data[64], name[64];
	static access, callback;
	menu_item_getinfo( menu, item, access, data, 63, name, 63, callback );
	
	static motd[256];
	formatex( motd, 255, "%s/%s.jpg", PICTURE_DIRECTORY, data );
	
	show_motd( plr, motd, "[ Shortcuts ]" );
	
	menu_destroy( menu );
	
	return PLUGIN_HANDLED;
}