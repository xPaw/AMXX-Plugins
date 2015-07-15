#include < amxmodx >
#include < engine >

public plugin_init( ) {
	register_plugin( "Environment", "1.0", "xPaw" );
	
	set_cvar_string( "sv_skyname", "night" );
}

public plugin_precache( ) {
	precache_sound( "zombie_plague/thunder1.wav" );
	
	// FOG & RAIN
	create_entity( "env_rain" );
	
	new iEntity = create_entity( "env_fog" );
	DispatchKeyValue( iEntity, "density", "0.001" );
	DispatchKeyValue( iEntity, "rendercolor", "128 128 128" );
	
	// AMBIENCE SOUND
	iEntity = create_entity( "ambient_generic" );
	entity_set_float( iEntity, EV_FL_health, 10.0 );
	entity_set_string( iEntity, EV_SZ_message, "ambience/rain.wav" );
	entity_set_int( iEntity, EV_INT_spawnflags, ( 1 << 0 ) );
	DispatchSpawn( iEntity );
	
	// THUNDER CLAP
	iEntity = create_entity( "info_target" );
	entity_set_string( iEntity, EV_SZ_classname, "env_thunder_clap" );
	entity_set_float( iEntity, EV_FL_nextthink, 30.0 );
	register_think( "env_thunder_clap", "FwdThunderClap" );
}

public FwdThunderClap( const iEntity ) {
	static iClap, Float:flNextThink; iClap = entity_get_int( iEntity, EV_INT_iuser4 );
	
	switch( iClap ) {
		case 0: {
			iClap       = 1;
			flNextThink = 1.25;
			
			client_cmd( 0, "spk zombie_plague/thunder1.wav" );
		}
		case 1: {
			iClap       = 2;
			flNextThink = 2.5;
			
			set_lights( "bcdefedcijklmlkjihgfedcb" );
		}
		case 2: {
			iClap       = 0;
			flNextThink = random_float( 15.0, 30.0 );
			
			set_lights( "b" );
		}
	}
	
	entity_set_int( iEntity, EV_INT_iuser4, iClap );
	entity_set_float( iEntity, EV_FL_nextthink, get_gametime( ) + flNextThink );
}

public client_putinserver( id ) {
	client_cmd( id, "cl_weather 3" );
	
	set_lights( "b" );
}
