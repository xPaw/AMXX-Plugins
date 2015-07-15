#include < amxmodx >
#include < engine >
#include < hamsandwich >

new g_iDoors[ 6 ], g_iDoors2[ 3 ], g_iMaxPlayers;

public plugin_init( ) {
	register_plugin( "Jail: Beach Dice Fix", "1.0", "xPaw" );
	
	new szMap[ 32 ];
	get_mapname( szMap, 31 );
	
	if( !equali( szMap, "jail_beach_myrun" ) )
		return;
	
	RegisterHam( Ham_Use, "env_beam", "FwdHamActivateBeam" );
	
	g_iMaxPlayers = get_maxplayers( ) + 1;
	
	remove_entity( find_ent_by_model( g_iMaxPlayers, "func_pushable", "*14" ) );
	remove_entity( find_ent_by_model( g_iMaxPlayers, "func_pushable", "*15" ) );
	remove_entity( find_ent_by_model( g_iMaxPlayers, "func_pushable", "*16" ) );
	remove_entity( find_ent_by_model( g_iMaxPlayers, "func_pushable", "*17" ) );
	
	g_iDoors[ 0 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel1" );
	g_iDoors[ 1 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel2" );
	g_iDoors[ 2 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel3" );
	g_iDoors[ 3 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel4" );
	g_iDoors[ 4 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel5" );
	g_iDoors[ 5 ] = find_ent_by_tname( g_iMaxPlayers, "wuerfel6" );
	
	g_iDoors2[ 0 ] = find_ent_by_tname( g_iMaxPlayers, "karte1" );
	g_iDoors2[ 1 ] = find_ent_by_tname( g_iMaxPlayers, "karte2" );
	g_iDoors2[ 2 ] = find_ent_by_tname( g_iMaxPlayers, "karte3" );
	
	// Fix ents
	new const szDoors[ ][ ] = { "*5", "*6", "*7", "*8", "*9", "*10", "*11" };
	
	new iEntity;
	for( new i; i < sizeof szDoors; i++ )
		if( ( iEntity = find_ent_by_model( g_iMaxPlayers, "func_door", szDoors[ i ] ) ) > 0 )
			DispatchKeyValue( iEntity, "dmg", "200" );
}

public FwdHamActivateBeam( const iEntity ) {
	static const szGenerator[ ] = "zufallswuerfelgenerator";
	static const szGenerator2[ ] = "zufallskarte";
	
	new iType, szTargetName[ 24 ];
	entity_get_string( iEntity, EV_SZ_targetname, szTargetName, 23 );
	
	if( equal( szTargetName, szGenerator ) ) iType = 1;
	else if( equal( szTargetName, szGenerator2 ) ) iType = 2;
	
	if( !iType ) return HAM_IGNORED;
	
	new Float:flGameTime = get_gametime( );
	
	if( entity_get_float( iEntity, EV_FL_fuser4 ) > flGameTime )
		return HAM_SUPERCEDE;
	
	entity_set_float( iEntity, EV_FL_fuser4, flGameTime + 1.3 );
	
	if( iType == 1 ) {
		new iRandom = random_num( 0, 5 );
		ExecuteHam( Ham_Use, g_iDoors[ iRandom ], iEntity, iEntity, 2, 1.0 );
		
		new iPlayer = -1;
		
		num_to_word( iRandom + 1, szTargetName, 24 );
		
		while( ( iPlayer = find_ent_in_sphere( iPlayer, Float:{ -1662.0, -230.0, 180.0 }, 600.0 ) ) > 0 ) {
			if( iPlayer >= g_iMaxPlayers ) break;
			
			set_hudmessage( 0, 127, 255, -1.0, 0.6, 0, 4.5, 4.5, 0.6, 0.6, 1 );
			show_hudmessage( iPlayer, "Dice roll - %s", szTargetName );
		}
	} else {
		ExecuteHam( Ham_Use, g_iDoors2[ random_num( 0, 3 ) ], iEntity, iEntity, 2, 1.0 );
	}
	
	return HAM_SUPERCEDE;
}
