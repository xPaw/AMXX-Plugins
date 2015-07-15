/*
 * LAST REQUEST API
 * by xPaw, 2011
 */

#if defined _last_request_included
	#endinput
#endif
#define _last_request_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib LastRequest
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib LastRequest
	#endif
#else
	#pragma library LastRequest
#endif

/* 
 * Registers new game
 * 
 * @param		szName - The display name
 * @param		szCallback - The callback function
 * @param		bDoWeNeedVictim - true if game requires selection of victim
 * 
 * @return		Returns the unique game id
 *				-1 on failure
 */
native Lr_RegisterGame( szName[ 32 ], szCallback[ 32 ], bool:bDoWeNeedVictim );

/* 
 * Restores player health
 * 
 * @param		id - Player id
 * 
 * @return		true on success, false on failure
 */
native Lr_RestoreHealth( id );

native Lr_WaitForMe( iGameId );
native Lr_MoveAlong( );

/*
 * Called when player selects game
 * 
 * @param		id - Player id
 * @param		iGameId - unique game id returned from Lr_RegisterGame
 * 
 */
forward Lr_GameSelected( const id, const iGameId );

/*
 * Called when game has ended
 * 
 * @param		id - Player id
 * @param		bDidTerroristWin - true if 'lr' guy has won
 * 
 */
forward Lr_GameFinished( const id, const bool:bDidTerroristWin );

/*
 * Called before menu to player has been displayed
 *	Return PLUGIN_HANDLED if you don't want player to see the menu
 * 
 * @param		id - Player id
 * 
 */
forward Lr_Menu_PreDisplay( const id );

