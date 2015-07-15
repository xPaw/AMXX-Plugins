#include < amxmodx >
#include < blockmaker >

new g_iBhop, g_iDelayBhop, g_iNoSlowDownBhop;

public plugin_init( )
{
	register_plugin( "BM: Bhops", "1.0", "xPaw" );
	
	BM_RegisterTouch( g_iBhop,           "ForwardBhopTouch" );
	BM_RegisterTouch( g_iDelayBhop,      "ForwardBhopTouch" );
	BM_RegisterTouch( g_iNoSlowDownBhop, "ForwardBhopTouch" );
	
	BM_RegisterParam( g_iDelayBhop, "Delay Before Disappear", "1.0" );
	
	register_think( "bm_block", "ForwardBlockThink" );
}

public plugin_precache( )
{
	g_iBhop = BM_RegisterBlock( "Bhop", "bhop" );
	BM_PrecacheModel( g_iBhop, BM_NORMAL, "models/blockmaker/bm_block_bhop.mdl" );
	BM_PrecacheModel( g_iBhop, BM_SMALL,  "models/blockmaker/small/bm_block_bhop.mdl" );
	BM_PrecacheModel( g_iBhop, BM_LARGE,  "models/blockmaker/large/bm_block_bhop.mdl" );
	
	g_iDelayBhop = BM_RegisterBlock( "Delayed Bhop", "bhop_delay" );
	BM_PrecacheModel( g_iDelayBhop, BM_NORMAL, "models/blockmaker/bm_block_bhop_delay.mdl" );
	BM_PrecacheModel( g_iDelayBhop, BM_SMALL,  "models/blockmaker/small/bm_block_bhop_delay.mdl" );
	BM_PrecacheModel( g_iDelayBhop, BM_LARGE,  "models/blockmaker/large/bm_block_bhop_delay.mdl" );
	
	g_iNoSlowDownBhop = BM_RegisterBlock( "No Slow Down Bhop", "bhop_noslow" );
	BM_PrecacheModel( g_iNoSlowDownBhop, BM_NORMAL, "models/blockmaker/bm_block_bhop_noslow.mdl" );
	BM_PrecacheModel( g_iNoSlowDownBhop, BM_SMALL,  "models/blockmaker/small/bm_block_bhop_noslow.mdl" );
	BM_PrecacheModel( g_iNoSlowDownBhop, BM_LARGE,  "models/blockmaker/large/bm_block_bhop_noslow.mdl" );
}

public ForwardBhopTouch( const iBlock, const id, const iBlockType, bool:bPlayerOnTop )
{
	static Float:flNextThink, Float:flGametime;
	flNextThink = entity_get_float( iBlock, EV_FL_nextthink );
	flGametime  = get_gametime( );
	
	if( flNextThink > flGametime )
	{
		return;
	}
	
	if( iBlockType == g_iBhop || iBlockType == g_iNoSlowDownBhop )
	{
		entity_set_float( iBlock, EV_FL_nextthink, flGametime + 0.1 );
	}
	else if( iBlockType == g_iDelayBhop )
	{
		entity_set_float( iBlock, EV_FL_nextthink, flGametime + 1.0 );
	}
}

public ForwardBlockThink( const iBlock )
{
	static iBlockType; iBlockType = entity_get_int( iBlock, EV_INT_body );
	
	if( iBlockType != g_iBhop && iBlockType != g_iDelayBhop && iBlockType != g_iNoSlowDownBhop )
	{
		return;
	}
	
	if( entity_get_int( iBlock, EV_INT_solid ) == SOLID_BBOX )
	{
		entity_set_int( iBlock, EV_INT_solid, SOLID_NOT );
		entity_set_float( iBlock, EV_FL_nextthink, get_gametime( ) + 1.0 );
		
		BM_SetRendering( iBlock, _, _, kRenderTransAdd, 120.0 );
	}
	else
	{
		entity_set_int( iBlock, EV_INT_solid, SOLID_BBOX );
		
		BM_SetRendering( iBlock );
	}
}
