#include < amxmodx >
#include < engine >
#include < achievements >

new const INFO_TARGET[ ] = "info_target";
new const CLASSNAME  [ ] = "gift_grab";
new const MODEL      [ ] = "models/myrun/present_v2.mdl";

new g_iAchievement;
new bool:g_bAchievementUnlocked[ 33 ];

public plugin_init( )
{
	register_plugin( "Gift Grab 2011", "1.0", "xPaw" );
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	register_event( "DeathMsg", "EventDeath", "a", "1>0", "2>0" );
	
	register_touch( CLASSNAME, "player", "FwdGiftTouch" );
	
	g_iAchievement = RegisterAchievement( "Gift Grab 2011 - JailBreak", "Collect seven gifts dropped by opponents", 7 );
}

public plugin_precache( )
{
	precache_model( MODEL );
}

public client_disconnect( id ) 
{
	g_bAchievementUnlocked[ id ] = false;
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	g_bAchievementUnlocked[ id ] = bool:HaveAchievement( id, g_iAchievement );
}

public Achv_Unlock( const id, const iAchievement )
{
	if( iAchievement == g_iAchievement )
	{
		g_bAchievementUnlocked[ id ] = true;
	}
}

public EventNewRound( )
{
	remove_entity_name( CLASSNAME );
}

public EventDeath( )
{
	new iVictim = read_data( 2 );
	
	if( iVictim != read_data( 1 ) && random( 100 ) <= 35 )
	{
		SpawnGift( iVictim );
	}
}

public FwdGiftTouch( const iGift, const id )
{
	if( is_user_alive( id ) && !g_bAchievementUnlocked[ id ] )
	{
		AchievementProgress( id, g_iAchievement );
		
		remove_entity( iGift );
	}
}

SpawnGift( const iOwner )
{
	new iEntity = create_entity( INFO_TARGET );
	
	if( !iEntity )
	{
		return;
	}
	
	new Float:vOrigin[ 3 ];
	
	vOrigin[ 0 ] = random_float( 0.0, 255.0 );
	vOrigin[ 1 ] = random_float( 0.0, 255.0 );
	vOrigin[ 2 ] = random_float( 0.0, 255.0 );
	
	entity_set_edict( iEntity, EV_ENT_owner, iOwner );
	entity_set_int( iEntity, EV_INT_renderfx, kRenderFxGlowShell );
	entity_set_vector( iEntity, EV_VEC_rendercolor, vOrigin );
	entity_set_int( iEntity, EV_INT_rendermode, kRenderNormal );
	entity_set_float( iEntity, EV_FL_renderamt, 16.0 );
	
	entity_set_float( iEntity, EV_FL_framerate, 2.0 );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_TOSS );
	entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
	
	entity_set_string( iEntity, EV_SZ_classname, CLASSNAME );
	
	entity_get_vector( iOwner, EV_VEC_origin, vOrigin );
	
	vOrigin[ 0 ] += random_float( -100.0, 100.0 );
	vOrigin[ 1 ] += random_float( -100.0, 100.0 );
	vOrigin[ 2 ] += 30.0;
	
	entity_set_origin( iEntity, vOrigin );
	entity_set_model( iEntity, MODEL );
}
