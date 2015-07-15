#include < amxmodx >
#include < engine >
#include < chatcolor >

#define GetNextMessage() random_float( 50.0, 80.0 )

enum _:AdvertData {
	AD_Color,
	AD_Message[ 164 ]
};

new Array:g_aMessages, g_iEntity, g_iCurrent;

public plugin_init( ) {
	register_plugin( "Advertiser", "1.0", "xPaw" );
	
	g_aMessages = ArrayCreate( AdvertData );
	
	if( ( g_iEntity = create_entity( "info_target" ) ) ) {
		entity_set_string( g_iEntity, EV_SZ_classname, "myrun_advertiser" );
		entity_set_float( g_iEntity, EV_FL_nextthink, get_gametime( ) + 50.0 );
		
		register_think( "myrun_advertiser", "ForwardThink" );
	} else {
		set_task( 50.0, "ShowMessage" );
	}
}

public plugin_end( )
	ArrayDestroy( g_aMessages );

public plugin_cfg( ) {
	new szFile[ 64 ];
	get_localinfo( "amxx_configsdir", szFile, 63 );
	format( szFile, 63, "%s/advertisements.ini", szFile );
	
	if( !file_exists( szFile ) ) {
		pause( "ad" );
		
		return;
	}
	
	new iFile = fopen( szFile, "rt" );
	
	if( !iFile )
		return;
	
	new szLine[ 164 ], Advert_Data[ AdvertData ];
	
	while( !feof( iFile ) ) {
		fgets( iFile, szLine, 163 );
		trim( szLine );
		
		if( !szLine[ 0 ] || szLine[ 0 ] == ';' )
			continue;
		
		if( szLine[ 0 ] == '[' ) {
			switch( szLine[ 1 ] ) {
				case 'R', 'r': Advert_Data[ AD_Color ] = Red;
				case 'B', 'b': Advert_Data[ AD_Color ] = Blue;
				case 'G', 'g': Advert_Data[ AD_Color ] = Grey;
				default: Advert_Data[ AD_Color ] = DontChange;
			}
			
			copy( szLine, 163, szLine[ contain( szLine, "]" ) + 2 ] );
		} else
			Advert_Data[ AD_Color ] = DontChange;
		
		while( replace( szLine, 163, "!t", "^3" ) ) { }
		while( replace( szLine, 163, "!g", "^4" ) ) { }
		while( replace( szLine, 163, "!n", "^1" ) ) { }
		
		Advert_Data[ AD_Message ] = szLine;
		
		ArrayPushArray( g_aMessages, Advert_Data );
	}
	
	fclose( iFile );
}

public ForwardThink( const iEntity ) {
	if( iEntity == g_iEntity ) {
		entity_set_float( g_iEntity, EV_FL_nextthink, get_gametime( ) + GetNextMessage( ) );
		
		ShowMessage( );
	}
}

ShowMessage( ) {
	if( g_iCurrent >= ArraySize( g_aMessages ) )
		g_iCurrent = 0;
	
	new Advert_Data[ AdvertData ];
	ArrayGetArray( g_aMessages, g_iCurrent++, Advert_Data );
	
	ColorChat( 0, Advert_Data[ AD_Color ], "%s", Advert_Data[ AD_Message ] );
	
	if( !g_iEntity )
		set_task( GetNextMessage( ), "ShowMessage" );
}
