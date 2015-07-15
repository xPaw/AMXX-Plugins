/*
 * LAST REQUEST API
 * by xPaw, 2011
 *
 * TEST-DEBUG PLUGIN
 */

#include < amxmodx >
#include < fun >
#include < LastRequest >

public plugin_init( )
{
	register_plugin( "[LR] Debug", "1.0", "xPaw" );
	
	Lr_RegisterGame( "Debugging item", "FwdTestCallback", true );
}

public FwdTestCallback( const id, const iVictim )
{
	client_print( 0, print_chat, "* [DEBUG]: FWD Callback - Id: %i - Victim: %i", id, iVictim );
	
	Lr_RestoreHealth( id );
	give_item( id, "weapon_deagle" );
	
	if( iVictim )
	{
		Lr_RestoreHealth( iVictim );
		give_item( iVictim, "weapon_deagle" );
	}
}

public Lr_Menu_PreDisplay( const id )
{
	client_print( 0, print_chat, "* [DEBUG]: Lr_Menu_PreDisplay - Id: %i", id );
}

public Lr_GameSelected( const id, const iGameId )
{
	client_print( 0, print_chat, "* [DEBUG]: Lr_GameSelected - Id: %i - GameId: %i", id, iGameId );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin )
{
	client_print( 0, print_chat, "* [DEBUG]: Lr_GameFinished - Id: %i - Terrorist win: %i", id, bDidTerroristWin );
}
