#include < amxmodx >
#include < engine >
#include < fakemeta >

new bool:g_bChangeLight;

public plugin_init( ) {
	register_plugin( "Jail: Maps Fixer", "1.0", "master4life / xPaw" );

	remove_entity_name( "func_pendulum" );
	remove_entity_name( "func_bomb_target" );
	remove_entity_name( "info_bomb_target" );
	
	new szMapname[ 32 ]; get_mapname( szMapname, sizeof szMapname );
	
	if( equali( szMapname, "jail_204jailbreak_v1" ) )
		FixMap_240( );
	else if( equali( szMapname, "jailbreak_final_1" ) )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*113" ) );
	else if( equali( szMapname, "jailbreak_recharged_remake2" ) )
		FixMap_recharged( );
	else if( equali( szMapname, "jailbreak_revolution_rage_v5c" ) )
		FixMap_revolution( );
	else if( equali( szMapname, "jailbreak_zow_dp" ) )
		FixMap_zow( );
	else if( equali( szMapname, "ba_tamama_v2" ) )
		FixMap_tamama( );
	else if( equali( szMapname, "vc__jail1_final" ) )
		FixMap_jail1( );
	else if( equali( szMapname, "jb_revo_complex_v3e" ) )
		FixMap_revo( );
	else if( equali( szMapname, "vc__jail_electric_large-b3" ) )
		FixMap_large( );
	else if( equali( szMapname, "jail_czone" ) )
		FixMap_czone( );
	else if( equali( szMapname, "jail_millenium_issue_b2" ) )
		FixMap_millenium( );
	else if( equali( szMapname, "jb_og_jailqon1_beta5" ) )
		FixMap_og( );
	else if( equali( szMapname, "jb_vbd_season1" ) )
		remove_entity_name( "trigger_hurt" );
	else if( equali( szMapname, "jail_city_b1" ) )
		Fix_City( );
	else if( equali( szMapname, "jail_zow_2towers" ) )
		Fix_2Towers( );
	else if( equali( szMapname, "jail_smen" ) )
		Fix_smen( );
	else if( equali( szMapname, "jb_impulse_syncho" ) )
		Fix_impulse( );
	else if( equali( szMapname, "jail_ms_shawshank" ) )
		Fix_shawshank( );
	else if( equali( szMapname, "jail_yakumo" ) )
		Fix_yakumo( );
	else if( equali( szMapname, "ms_jailbreak" ) )
		Fix_JailBreak( );
	else if( equali( szMapname, "jail_aztec_escape" ) )
		Fix_aztec_escape( );
	else if( equali( szMapname, "jail_neondragon" ) )
		Fix_neondragon( );
	else if( equali( szMapname, "jail_revolution" ) )
		Fix_revolution( );
	else if( equali( szMapname, "jail_greytown" ) )
		Fix_grey( );
	else if( equali( szMapname, "jailbreak_sneakpeek_v1" ) )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*120" ) );
	else if( equali( szMapname, "jail_zow_noname" ) )
		Fix_noname( );
	else if( equali( szMapname, "jail_avanzar_v1" ) )
		Fix_avanzar( );
	else if( equali( szMapname, "jail_zow_penitentary_full" ) )
		Fix_penitentary( );
	else if( equali( szMapname, "jail_varces_v2" ) )
		Fix_varces( );
	else if( equali( szMapname, "jail_chaos_v4" ) )
		Fix_chaos( );
	else if( equali( szMapname, "jail_xmf" ) )
		Fix_xmf( );
	else if( equali( szMapname, "sakura_jb_fort_v2a" ) )
		Fix_sakura( );
	else if( equali( szMapname, "jail_advancedprison_b5" ) )
		Fix_advanced( );
	else if( equali( szMapname, "jail_sanctuary" ) )
		Fix_sanctuary( );
	else  if( equali( szMapname, "jb_rikers_island_v7" ) )
		FixIsland_v7( );
	else  if( equali( szMapname, "jail_aj_ultimate_v2" ) )
		FixUltimate( );
	else  if( equali( szMapname, "jail_midday_v2" ) )
		FixMidday( );
	else  if( equali( szMapname, "jail_rehab_b4" ) )
		FixRehab( );
	else  if( equali( szMapname, "jb_freibier_beta3" ) )
		FixFreibier( );
}
public plugin_precache( ) precache_model( "models/gib_skull.mdl" );
	
CreateWall( Float: flOrigin[ 3 ], Float:flMins[ 3 ], Float:flMaxs[ 3 ] ) {
	new iEntity = create_entity( "info_target" );
	
	engfunc( EngFunc_SetModel, iEntity, "models/gib_skull.mdl" );
	engfunc( EngFunc_SetSize, iEntity, flMins, flMaxs );
	set_pev( iEntity, pev_origin, flOrigin );
	set_pev( iEntity, pev_movetype, MOVETYPE_FLY );
	set_pev( iEntity, pev_solid, SOLID_BBOX );
	set_pev( iEntity, pev_effects, pev( iEntity, pev_effects) | EF_NODRAW );
		
	return iEntity;
}

FixFreibier( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*214" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*215" ) );
}

FixMidday( ) {
	new const szModel[ ][ ] = { "*280", "*281", "*282", "*279" };
	
	new iEntity, i;
	for( i = 0; i < sizeof szModel; i++ )
		if( ( iEntity = find_ent_by_model( FM_NULLENT, "func_door", szModel[ i ] ) ) > 0 )
			DispatchKeyValue( iEntity, "dmg", "35" );

	while( ( iEntity = find_ent_by_class( iEntity, "func_door" ) ) > 0 )
			DispatchKeyValue( iEntity, "speed", "100" );
			
	remove_entity( find_ent_by_model( FM_NULLENT, "trigger_teleport", "*287" ) );
}

FixRehab( ) {
	new iEntity = find_ent_by_model( FM_NULLENT, "func_wall", "*228" );
	DispatchKeyValue( iEntity, "renderamt", "255" );
	DispatchSpawn( iEntity );
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*172" ) );
}

FixUltimate( ) {
	new iEntity = find_ent_by_model( FM_NULLENT, "func_button", "*176" );
	DispatchKeyValue( iEntity, "spawnflags", "1" );
	DispatchKeyValue( iEntity, "wait", "1" );
	DispatchSpawn( iEntity );
	
	iEntity = find_ent_by_model( FM_NULLENT, "func_button", "*174" );
	DispatchKeyValue( iEntity, "spawnflags", "1" );
	DispatchKeyValue( iEntity, "wait", "1" );
	DispatchSpawn( iEntity );
}

FixIsland_v7( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*221" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*222" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*244" ) );
}

Fix_sanctuary( ) {
	new iEntity;
	while( ( iEntity = find_ent_by_tname( iEntity, "spawn1" ) ) > 0 )
		DispatchKeyValue( iEntity, "dmg", "100" );
		
	new ent = find_ent_by_model( FM_NULLENT, "func_water", "*140" );
	set_pev( ent, pev_effects, pev( ent, pev_effects ) | EF_NODRAW );
		
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*191" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*204" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*216" ) );
}

Fix_advanced( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*62" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*63" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*64" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*33" ) );	
}

Fix_sakura( ) {
	new const szDoor[ ][ ] = { "*76", "*77", "*78", "*79", "*80", "*81", "*82", "*83" };
	
	for( new i; i < sizeof szDoor; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", szDoor[ i ] ) );
		
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*33" ), "wait", "1" );
	
	new iEntity;
	while( ( iEntity = find_ent_by_tname( iEntity, "cell" ) ) > 0 )
		DispatchKeyValue( iEntity, "dmg", "100" );
	
}
Fix_xmf( ) {
	new iEntity;
	while( ( iEntity = find_ent_by_model( iEntity, "armoury_entity", "models/w_mac10.mdl" ) ) > 0 )
		remove_entity( iEntity );
	 
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*57" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*28" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*54" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*55" ) );
}

Fix_chaos( ) {
	new iEntity = find_ent_by_model( FM_NULLENT, "func_button", "*70" );
	set_pev( iEntity, pev_spawnflags, 1 );
	DispatchKeyValue( iEntity, "wait", "2" );
	
	new ent = find_ent_by_model( FM_NULLENT, "func_water", "*120" );
	set_pev( ent, pev_effects, pev( ent, pev_effects ) | EF_NODRAW );
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*171" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*142" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*143" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*144" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*145" ) );
}

Fix_varces( ) {
	new const szBreak[ ][ ] = {
		"*45", "*46", "*47", "*48", "*49",
		"*50", "*51", "*52", "*53", "*54",
		"*56", "*20"
	};
	
	for( new i; i < sizeof szBreak; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_breakable", szBreak[ i ] ) );
	
	new iEntity;
	while( ( iEntity = find_ent_by_model( iEntity, "armoury_entity", "models/w_smokegrenade.mdl" ) ) > 0 )
		remove_entity( iEntity );
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*17" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*41" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*42" ) );
}

Fix_avanzar( ) {
	new iEntity;
	while( ( iEntity = find_ent_by_tname( iEntity, "Door" ) ) > 0 )
		DispatchKeyValue( iEntity, "dmg", "100" );
	
	remove_entity_name( "game_player_equip" );
	remove_entity_name( "player_weaponstrip" );
}

Fix_noname( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "button_target", "*11" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "button_target", "*67" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "trigger_multiple", "*19" ) );
	
	new iEntity, Float:vOrigin[ 3 ];
	new const szModel[ ][ ] = { "*24", "*25" };
	
	for( new i; i < sizeof szModel; i++ ) {
		iEntity = find_ent_by_model( FM_NULLENT, "button_target", szModel[ i ] );
		
		if( iEntity > 0 ) {
			entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
			remove_entity( iEntity );
				
			iEntity = create_entity( "func_button" );
			entity_set_vector( iEntity, EV_VEC_origin, vOrigin );
			entity_set_string( iEntity, EV_SZ_target, "door2" );
			set_pev( iEntity, pev_spawnflags, 1 );
			entity_set_string( iEntity, EV_SZ_model, szModel[ i ] );
			DispatchSpawn( iEntity );
		}
	}
	
	iEntity = find_ent_by_model( FM_NULLENT, "button_target", "*41" );
	
	if( iEntity > 0 ) {
		entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
		remove_entity( iEntity );
				
		iEntity = create_entity( "func_button" );
		entity_set_vector( iEntity, EV_VEC_origin, vOrigin );
		entity_set_string( iEntity, EV_SZ_target, "door1" );
		set_pev( iEntity, pev_spawnflags, 1 );
		entity_set_string( iEntity, EV_SZ_model, "*41" );
		DispatchSpawn( iEntity );
	}
}
Fix_penitentary( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "armoury_entity", "models/w_mac10.mdl" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*180" ) );
	
	CreateWall( Float: { 210.4, -130.4, 331.2 }, Float: { -37.0, -392.0, -32.0 }, Float: { 37.0, 392.0, 32.0 } );
	CreateWall( Float: { 47.0, 343.9, 332.1 }, Float: { -97.0, -142.0, -32.0 }, Float: { 97.0, 142.0, 32.0 } );
	
	new iEntity;
	while( ( iEntity = find_ent_by_model( iEntity, "armoury_entity", "models/w_awp.mdl" ) ) > 0 )
		remove_entity( iEntity );
		
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*248" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*249" ) );
}

Fix_revolution( ) { 
	CreateWall( Float: { -150.5, 459.9, 171.0 }, Float: { -32.0, -32.0, -77.0 }, Float: { 32.0, 32.0, 77.0 } );
	
	new iEntity = find_ent_by_model( FM_NULLENT, "func_water", "*139" );
	set_pev( iEntity, pev_effects, pev( iEntity, pev_effects ) | EF_NODRAW );
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*144" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_rotating", "*146" ) );
}

Fix_grey( ) {
	new const szDoorsDmg[ ][ ] = { "*1", "*3", "*4", "*5", "*6", "*7" };
	new const szDoor[ ][ ] = { "*33", "*34", "*39" };
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*31" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*32" ) );
	
	for( new i; i < sizeof szDoorsDmg; i++ )
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", szDoorsDmg[ i ] ), "dmg", "100" ); 
		
	for( new i; i < sizeof szDoor; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", szDoor[ i ] ) );
}

Fix_neondragon( ) {
	new iEntity = FM_NULLENT, iCount;
	
	while( ( iEntity = find_ent_by_model( iEntity, "armoury_entity", "models/w_kevlar.mdl" ) ) > 0 ) {
		switch( iCount++ ) {
			case 1, 2: {
				set_pdata_int( iEntity, 34, 0, 4 );
				entity_set_model( iEntity, "models/w_mp5.mdl" );
			}
			case 3, 4: {
				set_pdata_int( iEntity, 34, 6, 4 );
				entity_set_model( iEntity, "models/w_m4a1.mdl" );
			}
			default: {
				set_pdata_int( iEntity, 34, 4, 4 );
				entity_set_model( iEntity, "models/w_ak47.mdl" );
			}
		}
	}
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*163" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*59" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*60" ) );
	
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_breakable", "*79" ), "health", "1000" );
}

Fix_aztec_escape( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*87" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*111" ) );
	
	new iEntity, Float:vOrigin[ 3 ];	
	CreateWall( Float: { -504.5, -1017.9, 143.0 }, Float: { -20.0, -22.0, -107.0 }, Float: { 20.0, 22.0, 107.0 } );
	iEntity = find_ent_by_model( FM_NULLENT, "func_breakable", "*110" );
	
	if( iEntity > 0 ) {
		entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
		remove_entity( iEntity );
			
		iEntity = create_entity( "func_wall" );
		entity_set_vector( iEntity, EV_VEC_origin, vOrigin );
		entity_set_string( iEntity, EV_SZ_model, "*110" );
		DispatchSpawn( iEntity );
	}
}

Fix_JailBreak( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*102" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*132" ) );

}

Fix_yakumo( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*120" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*121" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*121" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*122" ) );
	
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*21" ), "wait", "1" );
	new iEntity = find_ent_by_model( FM_NULLENT, "func_water", "*74" );
	set_pev( iEntity, pev_effects, pev( iEntity, pev_effects ) | EF_NODRAW );
		
	iEntity = FM_NULLENT;
	while( ( iEntity = find_ent_by_tname( iEntity, "celldoor" ) ) > 0 )
		DispatchKeyValue( iEntity, "dmg", "100" );
}

Fix_shawshank( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*79" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*215" ) );
	
	new iEntity = find_ent_by_target( FM_NULLENT, "dtrap" );
	if( pev_valid( iEntity )  )
		remove_entity( iEntity );
	
}

Fix_impulse( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*11" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*12" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*13" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*94" ) );
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*69" ), "spawnflags", "1" );
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*70" ), "spawnflags", "1" );
}

Fix_smen( ) {
	new const szDoor[ ][ ] = { "*31", "*126"  };
	new const szButton[ ][ ] = { "*32", "*33", "*134", "*135" };
	
	remove_entity_name( "trigger_camera" ); 
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*148" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door_rotating", "*36" ) );
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", "*29" ), "dmg", "100" );
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*30" ), "wait", "2" );
	
	for( new i = 0; i < sizeof szDoor; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", szDoor[ i ] ) );
		
	for( new i = 0; i < sizeof szButton; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_button", szButton[ i ] ) );
}

Fix_2Towers( ) {
	remove_entity_name( "trigger_hurt" );
	remove_entity_name( "trigger_camera" ); 
	remove_entity( find_ent_by_model( FM_NULLENT, "cycler_sprite", "sprites/zowbanner2.spr" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*134" ) );
	
	new const Walls[ ][ ] = { "*232", "*233", "*234","*235", "*236", "*237","*238", "*239" };
	for( new i = 0; i < sizeof Walls; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Walls[ i ] ) );
	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*228" ) );
}

Fix_City( ) {
	set_pev( find_ent_by_model( FM_NULLENT, "func_wall", "*44" ), pev_rendermode, kRenderTransAlpha );
	set_pev( find_ent_by_model( FM_NULLENT, "func_tank", "*70" ), pev_rendermode, kRenderNormal );

	new const szDoors[ ][ ] = {
		"*1", "*4", "*6","*7",
		"*10", "*11", "*14", "*16",
		"*17", "*20", "*21", "*24",
		"*26", "*27", "*30", "*34",
		"*31", "*36", "*37", "*40"
	};
	
	for( new i; i < sizeof szDoors; i++ )
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door_rotating", szDoors[ i ] ), "dmg", "100" );
}

FixMap_og( ) {
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*133" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*134" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*113" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*117" ) );
}

FixMap_millenium( ) {
	new const doordmgspeed[ ][ ] = { "*16", "*17" };
	
	for( new i = 0; i < sizeof doordmgspeed; ++i ) {
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", doordmgspeed[ i ] ), "dmg", "100" );
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", doordmgspeed[ i ] ), "speed", "60" );
	}
}

FixMap_czone( ) {
	new const doordmg[ ][ ] = {
		"*36",	"*33",	"*31",
		"*30",	"*21",	"*23",
		"*25",	"*27",	"*50",
		"*42",	"*39",	"*38"
	};
	
	for( new i = 0; i < sizeof doordmg; ++i )
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", doordmg[ i ] ), "dmg", "100" );
}

FixMap_240( ) {
	new const Doors[ ][ ] = {
		"*1",	"*2",	"*12",
		"*13",	"*27",	"*28",
		"*33",	"*34",	"*87"
	};
	
	new const Wall[ ][ ] = { "*200",	"*201",	"*238" };

	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*88" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_breakable", "*79" ) );
	
	new i;
	for( i = 0; i < sizeof Doors; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", Doors[ i ] ) );
	
	for( i = 0; i < sizeof Wall; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Wall[ i ] ) );
}

FixMap_recharged( ) {
	new const Doors[ ][ ] = { "*129", "*194" };
	new const Button[ ][ ] = { "*130", "*131" };
	new const doordmg[ ][ ] = {
		"*57",	"*60",	"*63",	"*66",	"*69",	"*72",
		"*54",	"*51",	"*48",	"*45",	"*42",	"*39",
		"*36",	"*33",	"*30",	"*27",	"*24",	"*21",
		"*3",	"*6",	"*9",	"*12",	"*15",	"*18"
	};
	
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*105" ), "wait", "1" );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*193" ));
	remove_entity_name( "trigger_hurt" );
	
	new i;
	for( i = 0; i < sizeof doordmg; ++i )
		DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_door", doordmg[ i ] ), "dmg", "100" );
	
	for( i = 0; i < sizeof Doors; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", Doors[ i ] ) );

	for( i = 0; i < sizeof Button; i++ ) 
		remove_entity( find_ent_by_model( FM_NULLENT, "func_button", Button[ i ] ) );
}

FixMap_revolution( ) {
	remove_entity_name( "trigger_hurt" );
	remove_entity_name( "func_rotating" );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*1" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*2" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*3" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*6" ) );
}

FixMap_zow( ) {
	new const Wall[ ][ ] = {	"*119",	"*120",	"*121",	"*122",	"*123",	"*124",	"*125" };
	new const Door[ ][ ] = { "*13", "*16", "*31", "*58", "*59", "*73", "*98" };
	
	DispatchKeyValue( find_ent_by_model( FM_NULLENT, "func_button", "*15" ), "wait", "8" );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*56" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*107" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "armoury_entity", "models/w_m249.mdl" ) );
	
	new i;
	for( i = 0; i < sizeof Wall; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Wall[ i ] ) );
	
	for( i = 0; i < sizeof Door; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", Door[ i ] ) );
}

FixMap_tamama( ) {
	remove_entity_name( "armoury_entity" );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*112" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_illusionary", "*115" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*64" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", "*65" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*62" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_door", "*66" ) );	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*63" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_button", "*67" ) );	
	remove_entity( find_ent_by_model( FM_NULLENT, "func_pushable", "*56" ) );
}

FixMap_jail1( ) {
	new const Wall[ ][ ] = {
		"*166",	"*167",	"*158",	"*165",	"*164",	"*163",
		"*162",	"*161",	"*159",	"*160",	"*156",	"*157"
	};
	
	remove_entity_name( "trigger_camera" );
	remove_entity( find_ent_by_model( FM_NULLENT, "func_breakable", "*106" ) );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_button", "*6" ), EV_SZ_target, "arm" ); 
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_button", "*7" ), EV_SZ_target, "arm" );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_button", "*102" ), EV_SZ_target, "cells" );
	
	for( new i = 0; i < sizeof Wall; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Wall[ i ] ) );	
}

public FixMap_revo( ) {
	new const Walls[ ][ ] = { "*83", "*84", "*93", "*89", "*35", "*36", "*100" };
	new const Buttons[ ][ ] = { "*8", "*9", "*58", "*60" };
	new const Doors[ ][ ] = { "*48", "*59", "*7" };
	new const Break[ ][ ] = { "*35", "*36" };
	
	remove_entity_name( "trigger_hurt" );
	remove_entity_name( "func_rotating" );
	remove_entity_name( "game_text" );
	
	new i;
	for( i = 0; i <sizeof Break; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_breakable", Break[ i ] ) );	

	for( i = 0; i <sizeof Doors; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_door", Doors[ i ] ) );
	
	for( i = 0; i <sizeof Buttons; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_buttons", Buttons[ i ] ) );
		
	for( i = 0; i <sizeof Walls; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Walls[ i ] ) );		
	
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_door", "*48" ), EV_SZ_targetname, "garagecontrol" );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_door", "*7" ), EV_SZ_targetname, "garagecontrol" );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_door", "*25" ), EV_SZ_targetname, "armoury_manager" );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_door", "*26" ), EV_SZ_targetname, "armoury_manager" );
	entity_set_string( find_ent_by_model( FM_NULLENT, "func_button", "*22" ), EV_SZ_target, "celldoor" );
	
	g_bChangeLight = true;
	set_lights( "d" );
}

FixMap_large( ) {
	new const Breaks[ ][ ] = { "*18", "*66" };
	new const Wall[ ][ ] = {
		"*84",	"*85",	"*86",	"*87",	"*88",	"*89",
		"*90",	"*91",	"*92",	"*93",	"*94",	"*95"
	};

	remove_entity_name( "trigger_camera" );	
	remove_entity_name( "trigger_hurt" );
	remove_entity_name( "game_text" );
	
	new i;
	for( i = 0; i < sizeof Wall; i++ )
		remove_entity( find_ent_by_model( FM_NULLENT, "func_wall", Wall[ i ] ) );
	
	new iEntity, Float:vOrigin[ 3 ];
	for( i = 0; i < sizeof Breaks; i++ ) {
		iEntity = find_ent_by_model( FM_NULLENT, "func_breakable", Breaks[ i ] );
	
		if( iEntity > 0 ) {
			entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
			remove_entity( iEntity );
			
			iEntity = create_entity( "func_wall" );
			entity_set_vector( iEntity, EV_VEC_origin, vOrigin );
			entity_set_string( iEntity, EV_SZ_model, Breaks[ i ] );
			DispatchSpawn( iEntity );
			
			if( i != 0 ) {
				entity_set_int( iEntity, EV_INT_rendermode, kRenderTransTexture );
				entity_set_vector( iEntity, EV_VEC_rendercolor, Float:{ 0.0, 0.0, 0.0 } );
				entity_set_float( iEntity, EV_FL_renderamt, 100.0 );
			}
		}
	}
	
	remove_entity( find_ent_by_model( FM_NULLENT, "armoury_entity", "models/w_mac10.mdl" ) );
	remove_entity( find_ent_by_model( FM_NULLENT, "armoury_entity", "models/w_tmp.mdl" ) );
}

public client_putinserver( id )
	if( g_bChangeLight )
		set_lights( "d" );
