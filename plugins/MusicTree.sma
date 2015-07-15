#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >

new const MODEL[ ] = "models/myrun/christmas_tree1.mdl";
new const SONG[ ] = "myrun/how_is_your_life_going.wav";

#define AMBIENT_SOUND_LARGERADIUS 8

public plugin_precache( ) {
	engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "env_snow" ) );
	
	precache_model( MODEL );
	precache_sound( SONG );
}

public plugin_init( ) {
	register_plugin( "Christmas!", "Deathrun", "xPaw" );
	
	new iSpawn = engfunc( EngFunc_FindEntityByString, FM_NULLENT, "classname", "info_player_start" );
	
	if( !iSpawn ) return;
	
	new iEntity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "ambient_generic" ) );
	
	set_pev( iEntity, pev_message, SONG );
	set_pev( iEntity, pev_spawnflags, AMBIENT_SOUND_LARGERADIUS );
	set_pev( iEntity, pev_effects, EF_BRIGHTFIELD );
	
	new Float:vOrigin[ 3 ];
	pev( iSpawn, pev_origin, vOrigin );
	set_pev( iEntity, pev_origin, vOrigin );
	set_pev( iEntity, pev_health, 10.0 );
	
	ExecuteHam( Ham_Spawn, iEntity );
	engfunc( EngFunc_SetModel, iEntity, MODEL );
	engfunc( EngFunc_DropToFloor, iEntity );
}
