#include < amxmodx >

public plugin_init( ) {
	register_plugin( "", "", "xPaw" );
	
	new iCvar = register_cvar( "_server_startup", "0" );
	
	if( get_pcvar_num( iCvar ) == 1337 )
		return;
	
	set_pcvar_num( iCvar, 1337 );
	
	new const LastMapFile[ ] = "addons/amxmodx/data/last_map.ini";
	
	new iFile = fopen( LastMapFile, "r" );
	
	if( !iFile )
		return;
	
	new szLastMap[ 40 ];
	fgets( iFile, szLastMap, 39 );
	fclose( iFile );
	
	trim( szLastMap );
	
	if( !is_map_valid( szLastMap ) )
		return;
	
	log_amx( "Hi: %s", szLastMap );
	
	server_cmd( "map %s", szLastMap );
	server_exec( );
}

/*
public plugin_init( ) {
	register_plugin( "Random Map @ Server Start", "1.0", "xPaw" );
	
	new iCvar = register_cvar( "_server_startup", "0" );
	
	if( get_pcvar_num( iCvar ) == 1337 )
		return;
	
	set_pcvar_num( iCvar, 1337 );
	
	new const MapsFile[ ] = "addons/amxmodx/configs/maps.ini";
	
	new iFile = fopen( MapsFile, "r" );
	
	if( !iFile )
		return;
	
	new Array:aMaps = ArrayCreate( );
	
	new szLine[ 64 ];
	
	while( !feof( iFile ) ) {
		fgets( iFile, szLine, 63 );
		trim( szLine );
		
		if( !szLine[ 0 ] || szLine[ 0 ] == ';' || ( szLine[ 0 ] == '/' && szLine[ 1 ] == '/' ) )
			continue;
		
		if( !is_map_valid( szLine ) )
			continue;
		
		ArrayPushString( aMaps, szLine );
	}
	
	fclose( iFile );
	
	// test
	new iTotalMaps = ArraySize( aMaps );
	
	for( new i; i < iTotalMaps; i++ ) {
		ArrayGetString( aMaps, i, szLine, 63 );
		
		log_amx( "Map: %s", szLine );
	}
	
	ArrayGetString( aMaps, random( iTotalMaps ), szLine, 63 );
	
	log_amx( "And teh random map is (total: %i): %s", iTotalMaps, szLine );
	
	ArrayDestroy( aMaps );

//	set_task( 5.0, "ChangeMap", szLine, 31 );
}

public ChangeMap( const szMap[ ] ) {
	server_cmd( "map %s", szMap );
	server_exec( );
}*/
