#include < amxmodx >
#include < chatcolor >
#include < LastRequest >

new g_hMenu, g_iLrGuy, g_iLrVictim;
new g_iOption[ 2 ];

new const g_szOptions[ ][ ] = {
	"Paper",
	"Rock",
	"Scissor"
};

public plugin_init( )
{
	register_plugin( "[LR] Rock, paper and scissors", "1.0", "master4life" );
	
	Lr_RegisterGame( "Rock, paper and scissors", "FwdGameBattle", true );
}

public FwdGameBattle( const id, const iVictim )
{
	if( !g_hMenu )
	{
		g_hMenu = menu_create( "Choose the option", "HandleMenu" );
		
		menu_additem( g_hMenu, "Paper", "1" );
		menu_additem( g_hMenu, "Rock", "2" );
		menu_additem( g_hMenu, "Scissor", "3" );
		
		menu_setprop( g_hMenu, MPROP_EXIT, MEXIT_NEVER );
	}
	
	Lr_RestoreHealth( id );
	
	if( iVictim )
	{
		Lr_RestoreHealth( iVictim );
		
		g_iLrGuy    = id;
		g_iLrVictim = iVictim;
		
		set_task( 1.0, "ReMenu" );
	}
}

public ShowMenu( id )
{
	menu_display( id, g_hMenu, 0 );
}

public HandleMenu( const id, const iMenu, const iItem )
{
	if( iItem == MENU_EXIT || !g_iLrGuy || !is_user_alive( id ) )
	{
		return;
	}
	
	new szKey[ 2 ], iTrash;
	menu_item_getinfo( iMenu, iItem, iTrash, szKey, 1, _, _, iTrash );
	
	iTrash = str_to_num( szKey );
	
	g_iOption[ g_iLrGuy == id ? 0 : 1 ] = --iTrash;
	
	if( g_iOption[ 0 ] == -1 || g_iOption[ 1 ] == -1 )
	{
		new szName[ 32 ];
		get_user_name( id, szName, charsmax( szName ) );
		
		ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has chosen. Waiting for other player.", szName );
		
		return;
	}
	
	if( g_iOption[ 0 ] == g_iOption[ 1 ] )
	{
		set_task( 1.0, "ReMenu" );
		ColorChat( 0, Red, "[ mY.RuN ]^1 D-R-A-W GAME AGAIN!.^3 1^1 sec." );
	}
	
	switch( g_iOption[ 0 ] )
	{
		case 0:
		{
			switch( g_iOption[ 1 ] )
			{
				case 1:
				{
					// WINNER
					FreezePlayer( g_iLrVictim );
				}
				case 2:
				{
					// LOOSER
					FreezePlayer( g_iLrGuy );
				}
			}
		}
		case 1:
		{
			switch( g_iOption[ 1 ] )
			{
				case 0:
				{
					// LOOSER
					FreezePlayer( g_iLrGuy );
				}
				case 2:
				{
					// WINNER
					FreezePlayer( g_iLrVictim );
				}
			}
		}
		case 2:
		{
			switch( g_iOption[ 1 ] )
			{
				case 0:
				{
					// WINNER
					FreezePlayer( g_iLrVictim );
				}
				case 1:
				{
					// LOOSER
					FreezePlayer( g_iLrGuy );
				}
			}
		}
	}
}

public FreezePlayer( const iVictim )
{
	new szName[ 32 ], szVictim[ 32 ], szLrGuy[ 32 ];
	get_user_name( iVictim, szName, 31 );
	get_user_name( g_iLrVictim, szVictim, 31 );
	get_user_name( g_iLrGuy, szLrGuy, 31 );
	
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has chosen^4 %s^1.", szLrGuy, g_szOptions[ g_iOption[ 0 ] ] );
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has chosen^4 %s^1.", szVictim, g_szOptions[ g_iOption[ 1 ] ] );
	ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has lost, and now dies.", szName );
	
	user_kill( iVictim );
}

public ReMenu( )
{
	g_iOption[ 0 ] = g_iOption[ 1 ] = -1;
	
	ShowMenu( g_iLrGuy );
	ShowMenu( g_iLrVictim );
}
