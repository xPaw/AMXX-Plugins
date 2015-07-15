#include < amxmodx >
#include < chatcolor >

const RESERVED_SLOTS = 1;

enum _:ServerData
{
	Server_Name[ 15 ],
	Server_Addr[ 22 ]
};

new Array:g_aServers, g_iOwnServer = -1, g_szIp[ 22 ], g_iMenu;

public plugin_init( )
{
	register_plugin( "Redirect", "1.3", "xPaw" );
	
	g_aServers = ArrayCreate( ServerData );
	
	register_clcmd( "say /server",     "CmdServers" );
	register_clcmd( "say /servers",    "CmdServers" );
	register_clcmd( "say /serverlist", "CmdServers" );
	
	get_user_ip( 0, g_szIp, 21 );
	
	AddServer( "DeathRun",       "213.239.209.206:27038" );
	AddServer( "JailBreak",      "213.239.209.206:27016" );
	AddServer( "Knife",          "213.239.209.206:27020" );
	AddServer( "HideNSeek",      "213.239.209.206:27022" );
	AddServer( "Kreedz",         "213.239.209.206:27021" );
	AddServer( "Surf SpeedRuns", "213.239.209.206:27023" );
	AddServer( "Surf Ski 2",     "213.239.209.206:27025" );
	//AddServer( "SuperHero",      "93.186.194.15:28062" );
	//AddServer( "Dust2 Only",     "93.186.194.15:27099" );
	
	new iServers = ArraySize( g_aServers );
	
	new aServer[ ServerData ], szString[ 32 ];
	
	g_iMenu = menu_create( "\ymY.RuN Servers \r//\w www.my-run.de\R", "HandleServers" );
	
	for( new i; i < iServers; i++ )
	{
		ArrayGetArray( g_aServers, i, aServer );
		
		if( i == g_iOwnServer )
		{
			formatex( szString, 31, "\d%s", aServer[ Server_Name ] );
		}
		else if( iServers == 9 && i == 8 )
		{
			formatex( szString, 31, "%s^n", aServer[ Server_Name ] );
		}
		else
		{
			copy( szString, 31, aServer[ Server_Name ] );
		}
		
		menu_additem( g_iMenu, szString );
	}
	
	if( iServers < 10 )
	{
		menu_setprop( g_iMenu, MPROP_PERPAGE, 0 );
		
		if( iServers < 9 )
		{
			menu_addblank( g_iMenu );
		}
		
		menu_additem( g_iMenu, "Exit", "*" );
	}
}

AddServer( const szName[ 15 ], const szAddr[ 22 ] )
{
	if( equal( szAddr, g_szIp ) )
	{
		g_iOwnServer = ArraySize( g_aServers );
	}
	
	new aServer[ ServerData ];
	aServer[ Server_Name ] = szName;
	aServer[ Server_Addr ] = szAddr;
	
	ArrayPushArray( g_aServers, aServer );
}

public plugin_end( )
{
	ArrayDestroy( g_aServers );
	menu_destroy( g_iMenu );
}

public client_putinserver( id )
{
	new szServer[ 4 ];
	get_user_info( id, "myrun", szServer, 3 );
	
	if( szServer[ 0 ] )
	{
		set_task( 1.0, "TaskResetInfo", id );
		
		new iServ = str_to_num( szServer );
		
		if( !( 0 <= iServ < ArraySize( g_aServers ) ) )
		{
			return;
		}
		
		new aServer[ ServerData ];
		ArrayGetArray( g_aServers, iServ, aServer );
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has been redirected here from^4 %s^1.", szName, aServer[ Server_Name ] );
	}
}

public TaskResetInfo( const id )
{
	if( is_user_connected( id ) )
	{
		client_cmd( id, "setinfo ^"myrun^" ^"^"" );
	}
}

public CmdServers( const id )
{
	menu_display( id, g_iMenu );
}

public HandleServers( const id, const iMenu, const iItem )
{
	if( iItem == MENU_EXIT || iItem == 9 /* 9 only when less than 10 servers */ )
	{
		return;
	}
	
	if( iItem == g_iOwnServer )
	{
		menu_display( id, g_iMenu );
		return;
	}
	
	new aServer[ ServerData ], szName[ 32 ];
	
	ArrayGetArray( g_aServers, iItem, aServer );
	
	client_cmd( id, "setinfo ^"myrun^" ^"%i^"", g_iOwnServer );
	
	get_user_name( id, szName, 31 );
	
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has been redirected to^4 %s^1.", szName, aServer[ Server_Name ] );
	
	client_cmd( id, ";Connect %s", aServer[ Server_Addr ] );
}
