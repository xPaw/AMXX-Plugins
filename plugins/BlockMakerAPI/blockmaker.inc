#if defined _blockmaker_included
	#endinput
#endif
#define _blockmaker_included

#include < engine >

enum {
	BM_SMALL = 0,
	BM_NORMAL,
	BM_LARGE
};

native BM_RegisterBlock( szBlockName[ ], szSaveName[ ] );
native BM_SetUpDefaultRender( iBlockType, iFX = kRenderFxNone, Float:vColor[ 3 ] = { 0.0, 0.0, 0.0 }, iRender = kRenderNormal, Float:flAmount = 0.0 );
native BM_PrecacheModel( iBlockType, iSize, szModelPath[ ] );
native BM_RegisterTouch( iBlockType, szForwardName[ ] );
native BM_RegisterParam( iBlockType, szParamName[ ], szParamValue[ ] );
native BM_GetBlockGrabber( iEntity );

/*
 * Called when parameter has been changed
 */
forward BM_ParamChange( const iEntity, const iBlockType, szNewValue[ ] );

/*
 * Called when block is created
 */
forward BM_BlockCreated( const iEntity, const iBlockType );

/*
 * Called on player spawn/die/disconnect
 * This is used to reset any player specials or cooldowns
 */
forward BM_ResetPlayer( const id );

/*
 * Called when main plugin requires a info about block, to print for player in hud (when +use)
 *
 * return formatted string with parameters, if no parameters for block, return an empty string, use ^n for new lines. and dont put block name into string.
 */
forward BM_RequestProps( const iEntity, const iBlockType );

/*
 * Used to set render ( for example in BM_BlockCreated forward )
 */
stock BM_SetRendering( iEntity, iFX = kRenderFxNone, Float:vColor[ 3 ] = { 255.0, 255.0, 255.0 }, iRender = kRenderNormal, Float:flAmount = 16.0 ) {
	entity_set_int( iEntity, EV_INT_renderfx, iFX );
	entity_set_int( iEntity, EV_INT_rendermode, iRender );
	entity_set_float( iEntity, EV_FL_renderamt, flAmount );
	entity_set_vector( iEntity, EV_VEC_rendercolor, vColor );
}
