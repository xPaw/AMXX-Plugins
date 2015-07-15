#include < amxmodx >
#include < blockmaker >

new g_iGlass;

public plugin_init( )
	register_plugin( "BM: Platform", "1.0", "xPaw" );

public plugin_precache( )
{
	new iPlatform = BM_RegisterBlock( "Platform", "platform" );
	BM_PrecacheModel( iPlatform, BM_NORMAL, "models/blockmaker/bm_block_platform.mdl" );
	BM_PrecacheModel( iPlatform, BM_SMALL,  "models/blockmaker/bm_block_small_platform.mdl" );
	BM_PrecacheModel( iPlatform, BM_LARGE,  "models/blockmaker/bm_block_large_platform.mdl" );
	
	g_iGlass = BM_RegisterBlock( "Glass", "glass" );
	
	BM_PrecacheModel( g_iGlass, BM_NORMAL, "models/blockmaker/bm_block_glass.mdl" );
	BM_PrecacheModel( g_iGlass, BM_SMALL,  "models/blockmaker/bm_block_small_glass.mdl" );
	BM_PrecacheModel( g_iGlass, BM_LARGE,  "models/blockmaker/bm_block_large_glass.mdl" );
}

public BM_BlockCreated( const iEntity, const iBlockType )
{
	if( iBlockType == g_iGlass )
	{
		BM_SetRendering( iEntity, _, _, kRenderTransAlpha, 50.0 );
	}
}
