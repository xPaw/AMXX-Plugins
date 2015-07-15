/*
 * LAST REQUEST API
 * by xPaw, 2011
 *
 * This plugin provides basic but flexible programming interface
 * for easy implenting of new games into LR menu
 */

#include < amxmodx >
#include < cstrike >
#include < fakemeta >
#include < chatcolor >
#include < hamsandwich >

new const PREFIX[ ] = "^3[ mY.RuN ]";

#define DisplayMenu(%1) menu_display( %1, g_iMenu, 0 )

enum _:GAME_DATA
{
	GAME_NAME[ 32 ],
	GAME_FWD_ID,
	bool:GAME_VICTIM,
	bool:GAME_WAIT
};

enum _:FORWARDS
{
	FWD_GAME_SELECTED,
	FWD_GAME_FINISHED,
	FWD_MENU_PREDISPLAY
};

new Array:g_aGames;

new bool:g_bSawMenu;

new g_iForwards[ FORWARDS ];
new g_iLastPlr;
new g_iVictim;
new g_iMenuSize;
new g_iMenu;
new g_iSprite;
new g_iCurrentFwd;
new Float:g_flStart;

public plugin_init( )
{
	register_plugin( "Last Request API", "1.0", "xPaw" );
	
	g_aGames = ArrayCreate( GAME_DATA );
	
	if( g_aGames == Invalid_Array )
	{
		set_fail_state( "Paranoia failure: failed to create array (g_aGames)" );
	}
	
	register_clcmd( "say /lr",      "CmdLastRequest" );
	register_clcmd( "say_team /lr", "CmdLastRequest" );
	
	register_event( "DeathMsg",  "EventPlayerDeath", "a" );
	register_event( "HLTV",      "EventRoundStart",  "a", "1=0", "2=0" );
	
	// TODO: Enable/disable forwards...
	//RegisterHam( Ham_TraceAttack, "player", "FwdHamTraceAttack" );
	//RegisterHam( Ham_TakeDamage,  "player", "FwdHamTakeDamage" );
	
	g_iForwards[ FWD_GAME_SELECTED   ] = CreateMultiForward( "Lr_GameSelected", ET_IGNORE, FP_CELL, FP_CELL );
	g_iForwards[ FWD_GAME_FINISHED   ] = CreateMultiForward( "Lr_GameFinished", ET_IGNORE, FP_CELL, FP_CELL );
	g_iForwards[ FWD_MENU_PREDISPLAY ] = CreateMultiForward( "Lr_Menu_PreDisplay", ET_STOP2, FP_CELL );
	
	g_iMenu = menu_create( "Choose your last request", "HandleRequestMenu" );
	
	g_flStart = 30.0;
}

public plugin_end( )
{
	ArrayDestroy( g_aGames );
}

public plugin_natives( )
{
	register_library( "LastRequest" );
	
	register_native( "Lr_MoveAlong",     "NativeMoveAlong" );
	register_native( "Lr_WaitForMe",     "NativeWaitForMe" );
	register_native( "Lr_RegisterGame",  "NativeRegisterGame" );
	register_native( "Lr_RestoreHealth", "NativeRestoreHealth" );
}

public plugin_precache( )
{
	g_iSprite = precache_model( "sprites/laserbeam.spr" );
}

public NativeRegisterGame( const iPlugin, const iParams )
{
	if( iParams != 3 )
	{
		log_error( AMX_ERR_PARAMS, "Wrong parameters" );
		return -1;
	}
	
	new iPosition = ArraySize( g_aGames );
	
	new aGameData[ GAME_DATA ];
	new szCallback[ 32 ], bool:bDoWeNeedVictim = bool:get_param( 3 );
	get_string( 1, aGameData[ GAME_NAME ], 31 );
	get_string( 2, szCallback, 31 );
	
//	log_amx( "[LR] Registering new game: %s", aGameData[ GAME_NAME ] );
	
	if( !szCallback[ 0 ] )
	{
		log_error( AMX_ERR_GENERAL, "Paranoia failure: ignoring new game with empty callback (%s)", aGameData[ GAME_NAME ] );
		return -1;
	}
	
	new iForward = CreateOneForward( iPlugin, szCallback, FP_CELL, FP_CELL );
	
	if( !iForward )
	{
		log_error( AMX_ERR_GENERAL, "Paranoia failure: failed to create callback forward (%s)", szCallback );
		return -1;
	}
	
	aGameData[ GAME_FWD_ID ] = iForward;
	aGameData[ GAME_VICTIM ] = bDoWeNeedVictim;
	aGameData[ GAME_WAIT   ] = false;
	
	ArrayPushArray( g_aGames, aGameData );
	
	return iPosition;
}

public NativeRestoreHealth( const iPlugin, const iParams )
{
	if( iParams != 1 )
	{
		log_error( AMX_ERR_PARAMS, "Wrong parameters" );
		return false;
	}
	
	new iPlayer = get_param( 1 );
	
	if( !is_user_alive( iPlayer ) )
	{
		log_error( AMX_ERR_PARAMS, "Player is not alive (%i)", iPlayer );
		return false;
	}
	
	set_pev( iPlayer, pev_health, 100.0 );
	
	// This is not surely needed, but player could pickup something after a game
	cs_set_user_armor( iPlayer, 0, CS_ARMOR_NONE );
	
	return true;
}

public NativeWaitForMe( const iPlugin, const iParams )
{
	if( iParams != 1 )
	{
		log_error( AMX_ERR_PARAMS, "Wrong parameters" );
		return false;
	}
	
	new iGameId = get_param( 1 );
	
	if( !( 0 <= iGameId <= ArraySize( g_aGames ) ) )
	{
		log_error( AMX_ERR_BOUNDS, "iGameId is not registered" );
		return false;
	}
	
	new aGameData[ GAME_DATA ];
	ArrayGetArray( g_aGames, iGameId, aGameData );
	
	aGameData[ GAME_WAIT ] = true;
	
	ArraySetArray( g_aGames, iGameId, aGameData );
	
	return true;
}

public NativeMoveAlong( const iPlugin, const iParams )
{
	if( iParams != 0 )
	{
		log_error( AMX_ERR_PARAMS, "Wrong parameters" );
		return false;
	}
	else if( !g_iLastPlr )
	{
		log_error( AMX_ERR_GENERAL, "Lr_MoveAlong called when there is no last request player" );
		return false;
	}
	else if( g_iVictim )
	{
		log_error( AMX_ERR_GENERAL, "Lr_MoveAlong called when there is victim selected already" );
		return false;
	}
	else if( !g_iCurrentFwd )
	{
		log_error( AMX_ERR_GENERAL, "Lr_MoveAlong called when no game is running" );
		return false;
	}
	
	ShowVictimsMenu( g_iLastPlr );
	
	return true;
}

/*public FwdHamTakeDamage( const id, const iInflictor, const iAttacker )
{
	return FwdHamTraceAttack( id, iAttacker );
}

public FwdHamTraceAttack( const id, const iAttacker )
{
	if( g_iVictim && g_iLastPlr )
	{
		// Probably g_iLastPlr check is not required
		// Would been stupid to have g_iVictim and not have LR player
		// More testing is required
		
		if( ( g_iVictim == id && g_iLastPlr == iAttacker )
		||	( g_iVictim == iAttacker && g_iLastPlr == id ) )
		{
			return HAM_IGNORED;
		}
		
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}*/

public EventRoundStart( )
{
	g_flStart = get_gametime( ) + 15.0;
	
	if( g_iCurrentFwd )
	{
		// Round got restarted, force end or any other shit could cause this
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], g_iCurrentFwd, g_iLastPlr, false );
		
		g_iCurrentFwd = 0;
	}
	
	if( g_iLastPlr )
	{
		remove_task( g_iLastPlr );
		
		g_iLastPlr = 0;
	}
	
	if( g_iVictim )
	{
		remove_task( g_iVictim );
		
		g_iVictim = 0;
	}

	g_bSawMenu = false;
}

public EventPlayerDeath( )
{
	if( !g_bSawMenu )
	{
		new iPlayers[ 32 ], iPlayer;
		GetPlayers( iPlayers, iPlayer, CS_TEAM_T );
		
		if( iPlayer == 1 )
		{
			iPlayer = iPlayers[ 0 ];
			
			DisplayLastRequest( iPlayer );
			
			ColorChat( iPlayer, Red, "%s^1 You're the last prisoner, say^4 /lr^1 for your last request!", PREFIX );
		}
	}
	
	new id = read_data( 2 );
	
	if( id == g_iLastPlr )
	{
		remove_task( id );
		
		if( g_iVictim )
		{
			remove_task( g_iVictim );
			
			g_iVictim = 0;
		}
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "%s^4 %s^1 has died during last request!", PREFIX, szName );
	}
	else if( id == g_iVictim )
	{
		remove_task( id );
		remove_task( g_iLastPlr );
		
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], g_iVictim, id, false );
		
		g_iVictim = 0;
		
		ShowSelectMenu( g_iLastPlr );
		//ShowVictimsMenu( g_iLastPlr );
	}
}

public client_disconnect( id )
{
	if( !g_bSawMenu )
		return;
	
	if( id == g_iLastPlr )
	{
		remove_task( id );
		
		if( g_iVictim )
		{
			remove_task( g_iVictim );
			
			g_iVictim = 0;
		}
		
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], g_iLastPlr, id, false );
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "%s^4 %s^1 was too scared and left the battle.", PREFIX, szName );
		
		g_iLastPlr = 0;
	}
	else if( id == g_iVictim )
	{
		remove_task( id );
		remove_task( g_iLastPlr );
		
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], g_iVictim, g_iLastPlr, false );
		
		g_iVictim = 0;
		
		ShowSelectMenu( g_iLastPlr );
		//ShowVictimsMenu( g_iLastPlr );
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "%s^4 %s^1 was too scared and left the battle.^4 Prisoner selects new victim.", PREFIX, szName );
	}
}

public CmdLastRequest( const id )
{
	if( !is_user_alive( id ) )
	{
		ColorChat( id, Red, "%s^1 You're not alive.", PREFIX );
		
		return;
	}
	else if( cs_get_user_team( id ) != CS_TEAM_T )
	{
		ColorChat( id, Red, "%s^1 You're not a prisoner.", PREFIX );
		
		return;
	}
	else if( g_bSawMenu )
	{
		ColorChat( id, Red, "%s^1 You already used last request command once.", PREFIX );
		
		return;
	}
	else if( g_flStart > get_gametime( ) )
	{
		ColorChat( id, Red, "%s^1 You can't use^4 Last Request^4 at this time, try later.", PREFIX );
		
		return;
	}
	
	new iNum = CountPlayers( CS_TEAM_T );
	
	if( iNum > 1 )
	{
		ColorChat( id, Red, "%s^1 There are^4 %i^1 prisoners alive right now.", PREFIX, iNum );
		
		return;
	}
	
	DisplayLastRequest( id );
}

DisplayLastRequest( const id )
{
	new iReturn = CountPlayers( CS_TEAM_CT );
	
	if( !iReturn )
	{
		ColorChat( id, Red, "%s^1 There are no guards alive, your last request was cancelled.", PREFIX );
		
		return;
	}
	
	// Call forward and don't display menu if required
	ExecuteForward( g_iForwards[ FWD_MENU_PREDISPLAY ], iReturn, id );
	
	if( iReturn == PLUGIN_HANDLED )
	{
		ColorChat( id, Red, "%s^1 You are not allowed to access last request.", PREFIX );
		
		return;
	}
	
	new iSize = ArraySize( g_aGames );
	
	if( g_iMenuSize != iSize )
	{
		g_iMenuSize = iSize;
		
		new szKey[ 6 ], aGameData[ GAME_DATA ];
		
		for( new i = 0; i < iSize; i++ )
		{
			ArrayGetArray( g_aGames, i, aGameData );
			
			num_to_str( i, szKey, 5 );
			
			menu_additem( g_iMenu, aGameData[ GAME_NAME ], szKey );
		}
	}
	
	DisplayMenu( id );
	
	g_bSawMenu = true;
}

public HandleRequestMenu( const id, const iMenu, const iItem )
{
	if( !g_bSawMenu || !is_user_alive( id ) ) // id != g_iLastPlr
	{
		return;
	}
	else if( iItem == MENU_EXIT )
	{
		g_bSawMenu = false;
		
		return;
	}
	
	g_iLastPlr = id;
	
	new iPlayers[ 32 ], iNum, i, iPlayer;
	
	menu_item_getinfo( iMenu, iItem, i, iPlayers, 31, _, _, i );
	// Yeah, iPlayers... But it's an array, and it's fine :P
	new iKey = str_to_num( iPlayers );
	
	GetPlayers( iPlayers, iNum );
	
	for( i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		set_pev( iPlayer, pev_health, 100.0 );
		cs_set_user_armor( iPlayer, 0, CS_ARMOR_NONE );
	}
	
	if( !( 0 <= iKey <= ArraySize( g_aGames ) ) )
	{
		// How iz diz pussibul?
		
		return;
	}
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	new aGameData[ GAME_DATA ];
	ArrayGetArray( g_aGames, iKey, aGameData );
	
	g_iCurrentFwd = aGameData[ GAME_FWD_ID ];
	
	ExecuteForward( g_iForwards[ FWD_GAME_SELECTED ], i, id, iKey );
	ExecuteForward( g_iCurrentFwd, i, id, 0 );
	
	if( aGameData[ GAME_VICTIM ] && !aGameData[ GAME_WAIT ] )
	{
		ShowVictimsMenu( id );
	}
	
	new szMessage[ 90 ];
	formatex( szMessage, 89, "%s has selected:^n%s", szName, aGameData[ GAME_NAME ] );
	
	UTIL_DirectorMessage(
		.index       = 0, 
		.message     = szMessage,
		.red         = 90,
		.green       = 30,
		.blue        = 0,
		.x           = -1.0,
		.y           = 0.2,
		.effect      = 0,
		.fxTime      = 5.0,
		.holdTime    = 5.0,
		.fadeInTime  = 0.5,
		.fadeOutTime = 0.3
	);
}

bool:ShowSelectMenu( const id )
{
	new iPlayers[ 32 ], iNum;
	GetPlayers( iPlayers, iNum, CS_TEAM_CT );
	
	if( !iNum )
	{
		g_iCurrentFwd = 0;
		
		// Game has finished
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], iNum, id, true );
		
		return false;
	}
	
	DisplayMenu( id );
	
	return true;
}

bool:ShowVictimsMenu( const id )
{
	new iPlayers[ 32 ], iNum;
	GetPlayers( iPlayers, iNum, CS_TEAM_CT );
	
	if( !iNum )
	{
		g_iCurrentFwd = 0;
		
		// Game has finished
		ExecuteForward( g_iForwards[ FWD_GAME_FINISHED ], iNum, id, true );
		
		return false;
	}
	
	new szName[ 26 ], iPlayer, szId[ 2 ];
	//get_user_name( id, szName, 31 );
	//ColorChat( 0, Red, "%s^4 %s^1 now selects a new victim!", PREFIX, szName );
	
	new iMenu = menu_create( "Select your victim", "HandleVictimMenu" );
	
	//menu_additem( iMenu, "\rChange Last Request", "*" );
	//menu_addblank( iMenu );
	
	for( new i; i < iNum; i++ )
	{
		iPlayer   = iPlayers[ i ];
		szId[ 0 ] = iPlayer;
		
		get_user_name( iPlayer, szName, 25 );
		menu_additem( iMenu, szName, szId );
	}
	
	menu_display( id, iMenu, 0 );
	
	return true;
}

public HandleVictimMenu( const id, const iMenu, const iItem )
{
	if( iItem == MENU_EXIT || !g_bSawMenu || !is_user_alive( id ) ) // id != g_iLastPlr
	{
		menu_destroy( iMenu );
		
		return;
	}
	
	new szId[ 2 ], i;
	menu_item_getinfo( iMenu, iItem, i, szId, 1, _, _, i );
	menu_destroy( iMenu );
	
	new iPlayer = szId[ 0 ];
	
	if( !is_user_alive( iPlayer ) )
	{
		ColorChat( id, Red, "%s^1 Selected player is not alive anymore, try again!", PREFIX );
		
		ShowVictimsMenu( id );
		
		return;
	}
	
	ExecuteForward( g_iCurrentFwd, i, id, iPlayer );
	
	new szName[ 2 ][ 32 ];
	get_user_name( id, szName[ 0 ], 31 );
	get_user_name( iPlayer, szName[ 1 ], 31 );
	
	ColorChat( 0, Red, "%s^4 %s^1 has been selected as victim of^4 %s^1.", PREFIX, szName[ 1 ], szName[ 0 ] );
	
	set_task( 3.0, "TaskShowBeacon", id, .flags = "b" );
	set_task( 3.0, "TaskShowBeacon", iPlayer, .flags = "b" );
	
	TaskShowBeacon( id );
	TaskShowBeacon( iPlayer );
	
	g_iVictim = iPlayer;
}

public TaskShowBeacon( const id )
{
	if( !is_user_alive( id ) )
	{
		remove_task( id );
		return;
	}
	
	static const BLIP[ ] = "buttons/blip1.wav";
	
	new iOrigin[ 3 ], iTeam = get_user_team( id );
	get_user_origin( id, iOrigin );
	
	emit_sound( id, CHAN_ITEM, BLIP, 1.0, ATTN_NORM, 0, PITCH_NORM );
	
	message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
	write_byte( TE_BEAMCYLINDER );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] - 20 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] + 200 );
	write_short( g_iSprite );
	write_byte( 0 );
	write_byte( 1 );
	write_byte( 6 );
	write_byte( 2 );
	write_byte( 1 );
	write_byte( iTeam == 1 ? 255 : 50 );
	write_byte( 50 );
	write_byte( iTeam == 1 ? 50 : 255 );
	write_byte( 200 );
	write_byte( 6 );
	message_end( );
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

stock CountPlayers( CsTeams:iTeam = CS_TEAM_UNASSIGNED )
{
	new iTempPlayers[ 32 ], iTempNum;
	get_players( iTempPlayers, iTempNum, "ac" );
	
	if( iTeam != CS_TEAM_UNASSIGNED )
	{
		new iNum;
		
		for( new i = 0; i < iTempNum; i++ )
		{
			if( cs_get_user_team( iTempPlayers[ i ] ) == iTeam )
			{
				iNum++;
			}
		}
		
		return iNum;
	}
	
	return iTempNum;
}

stock GetPlayers( iPlayers[ 32 ], &iNum, CsTeams:iTeam = CS_TEAM_UNASSIGNED )
{
	new iTempPlayers[ 32 ], iTempNum;
	
	// Clear them
	iPlayers = iTempPlayers;
	iNum     = 0;
	
	get_players( iTempPlayers, iTempNum, "ac" );
	
	if( iTeam == CS_TEAM_UNASSIGNED )
	{
		iPlayers = iTempPlayers;
		iNum     = iTempNum;
	}
	else
	{
		new id;
		
		for( new i = 0; i < iTempNum; i++ )
		{
			id = iTempPlayers[ i ];
			
			if( cs_get_user_team( id ) == iTeam )
			{
				iPlayers[ iNum++ ] = id;
			}
		}
	}
}
