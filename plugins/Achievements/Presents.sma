#include < amxmodx >
#include < fun >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >
#include < Achievements >

new const CLASSNAME[ ] = "xmas_present";
new const MODEL    [ ] = "models/myrun/present_v2.mdl";

new g_iAchievement;
new Float:g_vOrigins[ 3 ], Float:g_vLastSpawn[ 3 ];

public plugin_init( ) {
	register_plugin( "Presents", "1.0", "xPaw" );
	
	register_touch( CLASSNAME, "player", "FwdPumpkinTouch" );
	
	g_iAchievement = RegisterAchievement( "Santa's Little Helper", "Find five presents that Santa lost while travelling", 5 );
	
	set_task( 300.0, "TaskSpawnPresent", 133367 );
	
	entity_get_vector( find_ent_by_class( FM_NULLENT, "info_player_start" ), EV_VEC_origin, g_vOrigins );
}

public plugin_precache( )
	precache_model( MODEL );

public TaskSpawnPresent( ) {
	if( get_playersnum( ) < 6 ) {
		set_task( 25.0, "TaskSpawnPresent", 133367 );
		return;
	}
	
	new Float:vOrigin[ 3 ], iNum;
	if( FindRandomOrigin( vOrigin, iNum ) ) {
		SpawnPumpkin( vOrigin );
		
		set_hudmessage( 255, 0, 0, -1.0, 0.20, 2, 5.0, 5.0, 0.05, 0.4, -1 );
		show_hudmessage( 0, "Present has just appeared!^nThe first one to find it, keeps it!" );
		
		set_task( 150.0, "TaskRemovePresent", 133368 );
	} else
		set_task( 10.0, "TaskSpawnPresent", 133367 );
}

public TaskRemovePresent( ) {
	remove_task( 133367 );
	set_task( 300.0, "TaskSpawnPresent", 133367 );
	
	set_hudmessage( 255, 0, 0, -1.0, 0.20, 2, 3.5, 3.5, 0.05, 0.4, -1 );
	show_hudmessage( 0, "No one has found the present." );
	
	new iEntity;
	
	while( ( iEntity = find_ent_by_class( iEntity, CLASSNAME ) ) > 0 )
		remove_entity( iEntity );
}

public FwdPumpkinTouch( const iPumpkin, const id ) {
	remove_task( 133368 );
	set_task( 300.0, "TaskSpawnPresent", 133367 );
	
	client_cmd( 0, "spk ^"ambience/goal_1^"" );
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	ColorChat( 0, Red, "^t^t^t^t^t^t^3%s^4 has found the present !", szName );
	
	AchievementProgress( id, g_iAchievement );
	
	give_item( id, "weapon_hegrenade" );
	
	remove_entity( iPumpkin );
}

SpawnPumpkin( const Float:vOrigin[ 3 ] ) {
	new iEntity = create_entity( "info_target" );
	
	if( !iEntity ) return 0;
	
	entity_set_origin( iEntity, vOrigin );
	
	entity_set_int( iEntity, EV_INT_renderfx, kRenderFxGlowShell );
	entity_set_vector( iEntity, EV_VEC_rendercolor, Float:{ 0.0, 100.0, 255.0 } );
	entity_set_int( iEntity, EV_INT_rendermode, kRenderNormal );
	entity_set_float( iEntity, EV_FL_renderamt, 16.0 );
	
	entity_set_float( iEntity, EV_FL_framerate, 2.0 );
	entity_set_int( iEntity, EV_INT_movetype, MOVETYPE_TOSS );
	entity_set_int( iEntity, EV_INT_solid, SOLID_TRIGGER );
	
	entity_set_string( iEntity, EV_SZ_classname, CLASSNAME );
	
	entity_set_model( iEntity, MODEL );
	
	return iEntity;
}

FindRandomOrigin( Float:vOrigin[ 3 ], &iNum ) {
	if( iNum++ > 250 )
		return 0;
	
	static Float:max_origin[ 3 ], Float:min_origin[ 3 ];
	
	#define xyrange 3000.0
	#define zrange 300.0
	
	vOrigin[ 0 ] = random_float( -4096.0, 4096.0 );
	vOrigin[ 1 ] = random_float( -4096.0, 4096.0 );
	
	/*if( vOrigin[ 0 ] > 0.0 )
		vOrigin[ 0 ] -= random_float( 1000.0, xyrange );
	else
		vOrigin[ 0 ] += random_float( 1000.0, xyrange );
	
	if( vOrigin[ 1 ] > 0.0 )
		vOrigin[ 1 ] -= random_float( 1000.0, xyrange );
	else
		vOrigin[ 1 ] += random_float( 1000.0, xyrange );*/
	
	vOrigin[ 2 ] = g_vOrigins[ 2 ] + random_float( -zrange, zrange );
	
	/*max_origin[0] = (max_origin[0] + g_vOrigins[0] + xyrange) / 2;
	min_origin[0] = (min_origin[0] + g_vOrigins[0] - xyrange) / 2;
	max_origin[1] = (max_origin[1] + g_vOrigins[1] + xyrange) / 2;
	min_origin[1] = (min_origin[1] + g_vOrigins[1] - xyrange) / 2;
	max_origin[2] = (max_origin[2] + g_vOrigins[2] + zrange) / 2;
	min_origin[2] = (min_origin[2] + g_vOrigins[2] - zrange) / 2;
	
	if(max_origin[0]>4800.0) max_origin[0] = 4800.0;
	if(min_origin[0]<-4800.0) min_origin[0] = 4800.0;
	if(max_origin[1]>4800.0) max_origin[1] = 4800.0;
	if(min_origin[1]<-4800.0) min_origin[1] = 4800.0;
	if(max_origin[2]>4800.0) max_origin[2] = 4800.0;
	if(min_origin[2]<-4800.0) min_origin[2] = 4800.0;
	
	vOrigin[ 0 ] = random_float(min_origin[0],max_origin[0]);
	vOrigin[ 1 ] = random_float(min_origin[1],max_origin[1]);
	vOrigin[ 2 ] = random_float(min_origin[2],max_origin[2]);*/
	
	if( ( get_distance_f( g_vLastSpawn, vOrigin ) < 1500.0 ) || !IsValidOrigin( vOrigin ) )
		return FindRandomOrigin( vOrigin, iNum );
	
	//vOrigin = vRandomOrigin;
	g_vLastSpawn = vOrigin;
	
	return 1;
}

IsValidOrigin( Float:end[ 3 ] ) {
	SetFloor(end)
	end[2] += 36.0
	new point = engfunc(EngFunc_PointContents, end)
	if(point == CONTENTS_EMPTY && CheckPoints(end) && !trace_hull(end, HULL_HEAD, -1))
		return true
	
	return false
}

SetFloor(Float:start[3]) {
	new tr, Float:end[3]
	end[0] = start[0]
	end[1] = start[1]
	end[2] = -99999.9
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, start)
}

CheckPoints(Float:origin[3])
{
	new Float:data[3], tr, point
	data[0] = origin[0]
	data[1] = origin[1]
	data[2] = 99999.9
	engfunc(EngFunc_TraceLine, origin, data, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, data)
	point = engfunc(EngFunc_PointContents, data)
	if(point == CONTENTS_SKY && get_distance_f(origin, data) < 250.0)
	{
		return false
	}
	data[2] = -99999.9
	engfunc(EngFunc_TraceLine, origin, data, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, data)
	point = engfunc(EngFunc_PointContents, data)
	if(point < CONTENTS_SOLID)
		return false
	
	return true
}
