#include < amxmodx >
#include < fakemeta >
#include < chatcolor >

new g_iMutedMask[ 33 ];
new g_iClientMuted[ 33 ];
new g_iMaxClients;
new g_iCallback;

public plugin_init( )
{
	register_plugin( "Mute", "2.0", "xPaw" );
	
	register_event( "VoiceMask", "EventVoiceMask", "b" );
	
	register_clcmd( "say", "CmdSay" );
	
	register_forward( FM_Voice_SetClientListening, "FwdVoice_SetClientListening" );
	
	g_iCallback   = menu_makecallback( "CallbackMuteMenu" );
	g_iMaxClients = get_maxplayers( );
}

public client_disconnect( id )
{
	g_iMutedMask[ id ] = 0;
	
	new iPlayerMask = ( 1 << id - 1 );
	
	for( new i; i <= g_iMaxClients; i++ )
	{
		g_iMutedMask[ i ] &= ~iPlayerMask;
	}
}

public CmdSay( const id )
{
	new szMessage[ 38 ];
	read_args( szMessage, 37 );
	remove_quotes( szMessage );
	
	if( szMessage[ 0 ] != '/' )
	{
		return PLUGIN_CONTINUE;
	}
	
	new szCmd[ 7 ], szArg[ 32 ];
	parse( szMessage, szCmd, 6, szArg, 31 );
	
	if( equali( szCmd, "/mute", 5 ) )
	{
		if( !szArg[ 0 ] )
		{
			DisplayMuteMenu( id, 0 );
			
			return PLUGIN_HANDLED;
		}
		
		new iPlayer = find_player( "bl", szArg );
		
		if( !iPlayer )
		{
			ColorChat( id, Red, "[ mY.RuN ]^1 Player^4 %s^1 not found.", szArg );
		}
		else if( iPlayer == id )
		{
			ColorChat( id, Red, "[ mY.RuN ]^4 You can't mute yourself." );
		}
		else if( g_iClientMuted[ id ] & ( 1 << iPlayer - 1 ) )
		{
			get_user_name( iPlayer, szArg, 31 );
			
			ColorChat( id, Red, "[ mY.RuN ]^4 %s^1 is muted by your game.", szArg );
		}
		else
		{
			ToggleMute( id, iPlayer );
		}
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public EventVoiceMask( const id )
{
	g_iClientMuted[ id ] = read_data( 2 );
}

public FwdVoice_SetClientListening( const iReceiver, const iSender, const bool:bListen )
{
	if( bListen && iReceiver != iSender && g_iMutedMask[ iReceiver ] & ( 1 << iSender - 1 ) )
	{
		engfunc( EngFunc_SetClientListening, iReceiver, iSender, false );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public CallbackMuteMenu( const id, const hMenu, const iItem )
{
	new iPlayer, szKey[ 1 ];
	menu_item_getinfo( hMenu, iItem, iPlayer, szKey, 1, _, _, iPlayer );
	
	iPlayer = szKey[ 0 ];
	
	return iPlayer == id || g_iClientMuted[ id ] & ( 1 << iPlayer - 1 ) ? ITEM_DISABLED : ITEM_ENABLED;
}

public HandleMuteMenu( const id, const hMenu, const iItem )
{
	if( iItem == MENU_EXIT )
	{
		menu_destroy( hMenu );
		return;
	}
	
	new iTrash, iMenuPage, szKey[ 1 ];
	player_menu_info( id, iTrash, iTrash, iMenuPage );
	menu_item_getinfo( hMenu, iItem, iTrash, szKey, 1, _, _, iTrash );
	menu_destroy( hMenu );
	
	new iPlayer = szKey[ 0 ];
	
	if( is_user_connected( iPlayer ) )
	{
		ToggleMute( id, iPlayer );
	}
	
	DisplayMuteMenu( id, iMenuPage );
}

DisplayMuteMenu( const id, const iPage )
{
	new iPlayers[ 32 ], iCount;
	get_players( iPlayers, iCount, "ch" );
	
	assert( iCount != 0 );
	
	new iPlayer, iPlayerMask, szMenu[ 64 ], szName[ 32 ], szKey[ 1 ];
	
	new hMenu = menu_create( "\r[ mY.RuN ] \wMute", "HandleMuteMenu" );
	
	for( new i; i < iCount; i++ )
	{
		iPlayer     = iPlayers[ i ];
		iPlayerMask = ( 1 << iPlayer - 1 );
		
		get_user_name( iPlayer, szName, 31 );
		
		formatex( szMenu, 63, "%s%s", szName,
			g_iMutedMask  [ id ] & iPlayerMask ? " \yMuted" :
			g_iClientMuted[ id ] & iPlayerMask ? " \rMuted by game" : "" );
		
		szKey[ 0 ] = iPlayer;
		
		menu_additem( hMenu, szMenu, szKey, _, g_iCallback );
	}
	
	menu_display( id, hMenu, iPage );
}

ToggleMute( const id, const iPlayer )
{
	new iPlayerMask = ( 1 << iPlayer - 1 );
	
	g_iMutedMask[ id ] ^= iPlayerMask;
	
	new bMuted = g_iMutedMask[ id ] & iPlayerMask;
	
	new szName[ 32 ];
	get_user_name( iPlayer, szName, 31 );
	
	ColorChat( id, Red, "[ mY.RuN ]^1 You have %smuted^4 %s", bMuted ? "^3" : "^4un", szName );
	
	engfunc( EngFunc_SetClientListening, id, iPlayer, bMuted );
}
