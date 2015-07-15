#include < amxmodx >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

const m_iJuice = 75;

new g_iType[ 33 ];
new g_szMenu[ 256 ];
new g_szConfigFile[ 96 ];

new const g_szHpModel[ ] = "models/healthcharger.mdl";
new const g_szApModel[ ] = "models/armorcharger.mdl";

new const g_szClasses[ ][ ] = {
	"func_healthcharger",
	"func_recharge"
};

public plugin_init( ) {
	register_plugin( "HP/AP Chargers", "1.0", "xPaw" );
	
	register_clcmd( "say /chargers", "CmdMenu" );
	register_clcmd( "amx_chargers",  "CmdMenu" );
	
	register_menucmd( register_menuid( "HpApMenu" ), 1023, "HandleMenu" );
	
//	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	register_event( "Battery", "EventBattery", "be", "1>0" ); // Simon Logic
	
	RegisterHam( Ham_Use,   "func_healthcharger", "FwdHamRechargeUse", 1 );
	RegisterHam( Ham_Use,   "func_recharge",      "FwdHamRechargeUse", 1 );
	RegisterHam( Ham_Think, "func_healthcharger", "FwdHamRechargeUse", 1 );
	RegisterHam( Ham_Think, "func_recharge",      "FwdHamRechargeUse", 1 );
}

public plugin_cfg( ) {
	// Generate Menu
	add( g_szMenu, 511, "\rChargers Creator^n^n\r1. \wCurrent:\y %s^n^n" );
	add( g_szMenu, 511, "\r2. \wCreate Charger^n\r3. \wDelete \y(By Aim)^n^n" );
	add( g_szMenu, 511, "\r4. \wDelete all %s chargers^n^n" );
	add( g_szMenu, 511, "\r5. \wSave^n\r6. \wLoad^n^n\r0. \wExit" );
	
	// Format file path
	get_localinfo( "amxx_datadir", g_szConfigFile, 95 );
	format( g_szConfigFile, 95, "%s/chargers", g_szConfigFile );
	
	if( !dir_exists( g_szConfigFile ) )
		mkdir( g_szConfigFile );
	
	new szMapName[ 32 ];
	get_mapname( szMapName, 31 );
	strtolower( szMapName );
	format( g_szConfigFile, 95, "%s/%s.txt", g_szConfigFile, szMapName );
	
	LoadChargers( 0 );
}

public plugin_precache( ) {
	precache_model( g_szHpModel );
	precache_model( g_szApModel );
	
	new szSounds[ ][ ] = {
		"items/medshot4.wav",
		"items/medshotno1.wav",
		"items/medcharge4.wav",
		
		"items/suitcharge1.wav",
		"items/suitchargeno1.wav",
		"items/suitchargeok1.wav"
	};
	
	for( new i; i < sizeof szSounds; i++ )
		precache_sound( szSounds[ i ] );
}

public client_putinserver( id )
	g_iType[ id ] = 0;

public CmdMenu( id ) {
	if( get_user_flags( id ) & ADMIN_CFG )
		ShowMenu( id );
	
	return PLUGIN_HANDLED;
}

public ShowMenu( id ) {
	new szMenu[ 256 ], szCurr[ 7 ];
	
	switch( g_iType[ id ] ) {
		case 0: szCurr = "Health";
		case 1: szCurr = "Armor";
	}
	
	formatex( szMenu, 255, g_szMenu, szCurr, szCurr );
	
	show_menu( id, 1023, szMenu, -1, "HpApMenu" );
	
	return PLUGIN_HANDLED;
}

public HandleMenu( id, iKey ) {
	switch( ( iKey + 1 ) ) {
		case 1: g_iType[ id ] = !g_iType[ id ];
		case 2: {
			new Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
			
			GetAimOrigin( id, vOrigin, vAngles );
			
			new iPointContents = PointContents( vOrigin );
			
			if( iPointContents == CONTENTS_SOLID || iPointContents == CONTENTS_SKY || iPointContents == CONTENTS_LADDER ) {
				ShowMenu( id );
				
				return PLUGIN_CONTINUE;
			}
			
			vector_to_angle( vAngles, vAngles );
			
			CreateCharger( g_iType[ id ], vOrigin, vAngles );
		}
		case 3: {
			new Float:vStart[ 3 ], Float:vEnd[ 3 ];
			pev( id, pev_origin, vStart );
			pev( id, pev_view_ofs, vEnd );
			xs_vec_add( vStart, vEnd, vStart );
			
			pev( id, pev_v_angle, vEnd );
			engfunc( EngFunc_MakeVectors, vEnd );
			global_get( glb_v_forward, vEnd );
			
			xs_vec_mul_scalar( vEnd, 9999.0, vEnd );
			xs_vec_add( vStart, vEnd, vEnd );
			
			new iTemp = FM_NULLENT, iEntity = FM_NULLENT, iTr = create_tr2( );
			engfunc( EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, id, iTr );
			get_tr2( iTr, TR_vecEndPos, vEnd );
			
			for( new i; i < sizeof g_szClasses; i++ ) {
				while( ( iTemp = find_ent_by_class( iTemp, g_szClasses[ i ] ) ) ) {
					if( pev( iTemp, pev_iuser3 ) != 444 )
						continue;
					
					engfunc( EngFunc_TraceModel, vStart, vEnd, HULL_POINT, iTemp, iTr );
					
					if( get_tr2( iTr, TR_pHit ) == iTemp ) {
						iEntity = iTemp;
						
						break;
					}
				}
				
				if( i == 0 && iEntity > 0 )
					break;
			}
			
			free_tr2( iTr );
			
			client_print( id, print_chat, "Hit: %i", iEntity );
		}
		case 4: DeleteChargers( id, g_iType[ id ] );
		case 5: {
			delete_file( g_szConfigFile );
			
			new iFile = fopen( g_szConfigFile, "a" );
			if( iFile ) {
				fputs( iFile, "; HP / AP Chargers by xPaw^n; <type> <origin> <angles>^n^n" );
				
				new iCount, iEntity, Float:vOrigin[ 3 ], Float:vAngles[ 3 ];
				
				for( new i; i < sizeof g_szClasses; i++ ) {
					while( ( iEntity = find_ent_by_class( iEntity, g_szClasses[ i ] ) ) > 0 ) {
						if( pev( iEntity, pev_iuser3 ) != 444 )
							continue;
						
						entity_get_vector( iEntity, EV_VEC_origin, vOrigin );
						entity_get_vector( iEntity, EV_VEC_angles, vAngles );
						
						fprintf( iFile, "^"%i^" ^"%f^" ^"%f^" ^"%f^" ^"%f^" ^"%f^" ^"%f^"^n",
						i, vOrigin[ 0 ], vOrigin[ 1 ], vOrigin[ 2 ], vAngles[ 0 ], vAngles[ 1 ], vAngles[ 2 ] );
						
						iCount++;
					}
				}
				
				fclose( iFile );
				
				if( !iCount )
					delete_file( g_szConfigFile );
				else
					GreenPrint( id, "You saved^4 %i^1 chargers.", iCount );
			}
		}
		case 6: LoadChargers( id );
		default: return PLUGIN_CONTINUE;
	}
	
	ShowMenu( id );
	
	return PLUGIN_CONTINUE;
}

public EventBattery( id ) {
	new CsArmorType:iArmorType, iArmor;
	iArmor = cs_get_user_armor( id, iArmorType );
	
	if( iArmorType == CS_ARMOR_NONE )
		cs_set_user_armor( id, iArmor, CS_ARMOR_KEVLAR );
}

public FwdHamRechargeUse( iEntity )
	if( pev( iEntity, pev_iuser3 ) == 444 )
		set_pev( iEntity, pev_body, get_pdata_int( iEntity, m_iJuice, 5 ) > 0 ? 0 : 1 );

CreateCharger( IsArmor, Float:vOrigin[ 3 ], Float:vAngles[ 3 ] ) {
	new iEntity = create_entity( g_szClasses[ IsArmor ] );
	
	if( !is_valid_ent( iEntity ) )
		return 0;
	
	set_pev( iEntity, pev_origin, vOrigin );
	set_pev( iEntity, pev_angles, vAngles );
	
	entity_set_model( iEntity, IsArmor ? g_szApModel : g_szHpModel );
	
	DispatchSpawn( iEntity );
	
	set_pev( iEntity, pev_iuser3, 444 );
	
	return iEntity;
}

DeleteChargers( id, iType ) {
	new iEntity = FM_NULLENT, iCount;
	
	switch( iType ) {
		case 0, 1: {
			while( ( iEntity = find_ent_by_class( iEntity, g_szClasses[ iType ] ) ) > 0 ) {
				if( pev( iEntity, pev_iuser3 ) != 444 )
					continue;
				
				remove_entity( iEntity );
				
				iCount++;
			}
		}
		default: {
			for( new i; i < sizeof g_szClasses; i++ ) {
				while( ( iEntity = find_ent_by_class( iEntity, g_szClasses[ i ] ) ) > 0 ) {
					if( pev( iEntity, pev_iuser3 ) != 444 )
						continue;
					
					remove_entity( iEntity );
					
					iCount++;
				}
			}
		}
	}
	
	if( id ) {
		if( iCount )
			GreenPrint( id, "You deleted^4 %i^1 chargers.", iCount );
		else
			GreenPrint( id, "No chargers on map." );
	}
}

LoadChargers( id ) {
	new iFile = fopen( g_szConfigFile, "r" );
	
	if( iFile ) {
		DeleteChargers( 0, 2 );
		
		new iCount, szData[ 128 ], Float:vOrigin[ 3 ], Float:vAngles[ 3 ], szDatas[ 7 ][ 17 ];
		
		while( !feof( iFile ) ) {
			fgets( iFile, szData, charsmax( szData ) );
			
			if( !szData[ 0 ] || szData[ 0 ] == ';' )
				continue;
			
			parse( szData, szDatas[ 0 ], 1, szDatas[ 1 ], 16, szDatas[ 2 ], 16, szDatas[ 3 ], 16,
			szDatas[ 4 ], 16, szDatas[ 5 ], 16, szDatas[ 6 ], 16 );
			
			vOrigin[ 0 ] = str_to_float( szDatas[ 1 ] );
			vOrigin[ 1 ] = str_to_float( szDatas[ 2 ] );
			vOrigin[ 2 ] = str_to_float( szDatas[ 3 ] );
			
			vAngles[ 0 ] = str_to_float( szDatas[ 4 ] );
			vAngles[ 1 ] = str_to_float( szDatas[ 5 ] );
			vAngles[ 2 ] = str_to_float( szDatas[ 6 ] );
			
			if( !vOrigin[ 0 ] && !vOrigin[ 1 ] && !vOrigin[ 2 ] )
				continue;
			
			CreateCharger( str_to_num( szDatas[ 0 ] ), vOrigin, vAngles );
			
			iCount++;
		}
		
		fclose( iFile );
		
		if( id ) {
			if( iCount )
				GreenPrint( id, "You loaded^4 %i^1 chargers.", iCount );
			else
				GreenPrint( id, "No chargers in file." );
		}
	}
}

stock GetAimOrigin( const id, Float:vOrigin[ 3 ], Float:vAngles[ 3 ] ) {
	new Float:vStart[ 3 ], Float:vEnd[ 3 ];
	pev( id, pev_origin, vStart );
	pev( id, pev_view_ofs, vEnd );
	xs_vec_add( vStart, vEnd, vStart );
	
	pev( id, pev_v_angle, vEnd );
	engfunc( EngFunc_MakeVectors, vEnd );
	global_get( glb_v_forward, vEnd );
	
	xs_vec_mul_scalar( vEnd, 9999.0, vEnd );
	xs_vec_add( vStart, vEnd, vEnd );
	
	new i, iTr = create_tr2( );
	engfunc( EngFunc_TraceLine, vStart, vEnd, DONT_IGNORE_MONSTERS, id, iTr );
	get_tr2( iTr, TR_vecEndPos, vOrigin );
	get_tr2( iTr, TR_vecPlaneNormal, vAngles );
	free_tr2( iTr );
	
	new Float:flDist = get_distance_f( vStart, vEnd );
	
	for( i = 0; i < 3; i++ )
		vOrigin[ i ] -= ( vOrigin[ i ] - vStart[ i ] ) / flDist;
	
	for( i = 0; i < 3; i++ )
		vAngles[ i ] *= -1.0;
}

stock GreenPrint( id, const message[ ], any:... ) {
	static szMessage[ 192 ], iLen, iSayText;
	
	if( !iLen )
		iLen = formatex( szMessage, 191, "^4[Chargers]^1 " );
	
	if( !iSayText )
		iSayText = get_user_msgid( "SayText" );
	
	vformat( szMessage[ iLen ], 191 - iLen, message, 3 );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
	
	return 1;
}