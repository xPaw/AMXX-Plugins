#include < amxmodx >
#include < hamsandwich >
#include < achievements >

const MENU_KEYS = ( 1 << 0 ) | ( 1 << 1 ) | ( 1 << 4 ) | ( 1 << 5 );

//new const HTML_RULE[ ] = "<html><head><meta http-equiv='Refresh' content='0; URL=http://my-run.de/game/motd.php?s=jail'></head><body bgcolor=black><center><img src=http://my-run.de/l.png>";
new const HTML_GAME[ ] = "<html><head><meta http-equiv='Refresh' content='0; URL=http://my-run.de/game/jb_games.html'></head><body bgcolor=black><center><img src=http://my-run.de/l.png>";

new bool:g_bAccepted[ 33 ], g_iCountDown[ 33 ];

public plugin_init( )
{
	register_plugin( "Jail: Rules", "1.1", "xPaw & master4life" );
	
	register_menucmd( register_menuid( "JailRules" ), MENU_KEYS, "HandleRules" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	
	register_clcmd( "say /gamelist", "CmdGames" );
	register_clcmd( "say /games", "CmdGames" );
	
	register_clcmd( "say_team /rules", "CmdRules" );
	register_clcmd( "say /rules", "CmdRules" );
	register_clcmd( "say .rules", "CmdRules" );
}

public CmdGames( const id )
{
	show_motd( id, HTML_GAME, "[ mY.RuN ] JailBreak Games" );
}

public CmdRules( const id )
{
	//show_motd( id, HTML_RULE, "[ mY.RuN ] JailBreak Rules" );
	show_motd( id, "motd.txt", "[ mY.RuN ] JailBreak Rules" );
}

public client_putinserver( id )
{
	g_iCountDown[ id ] = 0;
	g_bAccepted[ id ]  = false;
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	if( iPlayTime > 2880 || get_user_flags( id ) & ADMIN_RCON )
	{
		g_bAccepted[ id ] = true;
	}
}

public FwdHamPlayerSpawn( const id )
{
	if( !g_bAccepted[ id ] && is_user_alive( id ) )
	{
		g_iCountDown[ id ] = 10;
		
		ShowMenu( id );
	}
}

public ShowMenu( const id )
{
	if( g_bAccepted[ id ] || !g_iCountDown[ id ] )
	{
		show_menu( id, MENU_KEYS, "\r[\d mY.RuN JailBreak Rules \r]^n^n\r1. \r[\r Accept ]^n\r2. \r[\d Decline\r ]^n^n\r5. \yShow Rules^n\r6. \yShow Games^n^n       \rwww.\ymy-run\r.de", -1, "JailRules" );
	}
	else
	{
		new szMenu[ 164 ];
		formatex( szMenu, 163, "\r[\d mY.RuN JailBreak Rules \r]^n^n\r1. \r[\d Accept \r%i sec ]^n\r2. \r[\d Decline\r ]^n^n\r5. \yShow Rules^n\r6. \yShow Games^n^n       \rwww.\ymy-run\r.de", g_iCountDown[ id ] );
		
		show_menu( id, MENU_KEYS, szMenu, -1, "JailRules" );
		
		if( !task_exists( id ) )
		{
			set_task( 1.0, "TaskCountDown", id );
		}
	}
}

public TaskCountDown( const id )
{
	if( --g_iCountDown[ id ] > 0 )
	{
		set_task( 1.0, "TaskCountDown", id );
	}
	
	ShowMenu( id );
}

public HandleRules( const id, const iKey )
{
	switch( iKey )
	{
		case 0:
		{
			g_bAccepted[ id ] = true;
		}
		case 1:
		{
			g_bAccepted[ id ] = false;
			server_cmd( "kick #%i ^"You must accept the rules!^"", get_user_userid( id ) );
		}
		case 4:
		{
			CmdRules( id );
			ShowMenu( id );
		}
		case 5:
		{
			CmdGames( id );
			ShowMenu( id );
		}
	}
}
