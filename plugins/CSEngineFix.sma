#include < amxmodx >
#include < engine >
#include < fakemeta >
#include < hamsandwich >

#define FindEntity(%1,%2) engfunc( EngFunc_FindEntityByString, %1, "classname", %2 )

enum ( <<=1 )
{
	WE_FIX_FUNC_PLAT = 1,
	WE_FIX_FUNC_VEHICLE,
	WE_FIX_FUNC_PENDULUM,
	WE_FIX_FUNC_PUSHABLE,
	WE_FIX_FUNC_BREAKABLE
};

new g_iThingsWeFix;

public plugin_init( )
{
	register_plugin( "CS Engine Fixes", "1.0", "xPaw" );
	
	// env_beam, env_lightning
	// SF_BEAM_STARTON
	// SF_BEAM_TOGGLE
	
	
	
	new iEntity = FM_NULLENT;
	
	if( ( iEntity = FindEntity( iEntity, "func_pushable" ) ) > 0 )
	{
		g_iThingsWeFix |= WE_FIX_FUNC_PUSHABLE;
	}
	
	iEntity = FM_NULLENT;
	
	while( ( iEntity = FindEntity( iEntity, "func_plat" ) ) > 0 )
	{
		if( pev( iEntity, pev_spawnflags ) & SF_PLAT_TOGGLE )
		{
			g_iThingsWeFix |= WE_FIX_FUNC_PLAT;
			break;
		}
	}
	
	new Float:vAngles[ 3 ];
	iEntity = FM_NULLENT;
	
	while( ( iEntity = FindEntity( iEntity, "func_vehicle" ) ) > 0 )
	{
		pev( iEntity, pev_angles, vAngles );
		set_pev( iEntity, pev_vuser4, vAngles );
		
		g_iThingsWeFix |= WE_FIX_FUNC_VEHICLE;
	}
	
	iEntity = FM_NULLENT;
	
	while( ( iEntity = FindEntity( iEntity, "func_pendulum" ) ) > 0 )
	{
		#define m_center 40
		
		vAngles[ 0 ] = get_pdata_float( iEntity, m_center, 5 );
		vAngles[ 1 ] = get_pdata_float( iEntity, m_center + 1, 5 );
		vAngles[ 2 ] = get_pdata_float( iEntity, m_center + 2, 5 );
		
		// TODO: Try pev_angles
		
		set_pev( iEntity, pev_vuser4, vAngles );
		
		g_iThingsWeFix |= WE_FIX_FUNC_PENDULUM;
	}
	
	if( ( iEntity = FindEntity( iEntity, "func_breakable" ) ) > 0 )
	{
		g_iThingsWeFix |= WE_FIX_FUNC_BREAKABLE;
		
		register_think( "func_breakable", "FwdThinkBreak" );
	}
	
	if( !g_iThingsWeFix )
	{
		log_amx( "Oh look, nothing to fix!" );
		pause( "a" );
	}
	
	register_event( "HLTV", "EventNewRound", "a", "1=0", "2=0" );
	
	server_print( "----------" );
	server_print( "Raw: %i", g_iThingsWeFix );
	server_print( "func_plat: %s", g_iThingsWeFix & WE_FIX_FUNC_PLAT ? "Yes" : "No" );
	server_print( "func_vehicle: %s", g_iThingsWeFix & WE_FIX_FUNC_VEHICLE ? "Yes" : "No" );
	server_print( "func_pendulum: %s", g_iThingsWeFix & WE_FIX_FUNC_PENDULUM ? "Yes" : "No" );
	server_print( "func_pushable: %s", g_iThingsWeFix & WE_FIX_FUNC_PUSHABLE ? "Yes" : "No" );
	server_print( "func_breakable: %s", g_iThingsWeFix & WE_FIX_FUNC_BREAKABLE ? "Yes" : "No" );
	
	RegisterHam( Ham_CS_Restart, "func_plat", "FwdHamCSReset" );
	RegisterHam( Ham_CS_Restart, "func_vehicle", "FwdHamCSReset" );
	RegisterHam( Ham_CS_Restart, "func_pendulum", "FwdHamCSReset" );
	RegisterHam( Ham_CS_Restart, "func_pushable", "FwdHamCSReset" );
}

public FwdHamCSReset( const iEntity )
{
	new szClassName[ 32 ];
	entity_get_string( iEntity, EV_SZ_classname, szClassName, charsmax( szClassName ) );
	
	log_amx( "Ham_CS_Restart - %s - %i", szClassName, iEntity );
}

public EventNewRound( )
{
	new iEntity = FM_NULLENT;
	
	// TODO: Test Ham_CS_Restart on entities !!
	
	if( g_iThingsWeFix & WE_FIX_FUNC_PUSHABLE )
	{
		// Credits to MPNumB
		
		while( ( iEntity = FindEntity( iEntity, "func_pushable" ) ) > 0 )
		{
			set_pev( iEntity, pev_velocity, Float:{ 0.0, 0.0, 0.0 } );
			engfunc( EngFunc_SetOrigin, iEntity, Float:{ 0.0, 0.0, 1.0 } );
		}
	}
	
	if( g_iThingsWeFix & WE_FIX_FUNC_VEHICLE )
	{
		new Float:vAngles[ 3 ];
		
		while( ( iEntity = FindEntity( iEntity, "func_vehicle" ) ) > 0 )
		{
			dllfunc( DLLFunc_Think, iEntity );
			pev( iEntity, pev_vuser4, vAngles );
			set_pev( iEntity, pev_angles, vAngles );
		}
	}
	
	if( g_iThingsWeFix & WE_FIX_FUNC_PENDULUM )
	{
		new Float:flMaxSpeed, Float:vAngles[ 3 ];
		
		while( ( iEntity = FindEntity( iEntity, "func_pendulum" ) ) > 0 )
		{
			#define m_maxSpeed 38
			
			flMaxSpeed = get_pdata_float( iEntity, m_maxSpeed, 5 );
			pev( iEntity, pev_vuser4, vAngles );
			
			set_pev( iEntity, pev_speed, flMaxSpeed );
			set_pev( iEntity, pev_angles, vAngles );
			set_pev( iEntity, pev_avelocity, Float:{ 0.0, 0.0, 0.0 } );
		}
	}
	
	if( g_iThingsWeFix & WE_FIX_FUNC_PLAT )
	{
		new iState;
		
		while( ( iEntity = FindEntity( iEntity, "func_plat" ) ) > 0 )
		{
			if( pev( iEntity, pev_spawnflags ) & SF_PLAT_TOGGLE )
			{
				iState = ExecuteHam( Ham_GetToggleState, iEntity );
				
				#define TS_AT_TOP   0
				#define TS_GOING_UP 2
				
				if( iState != TS_AT_TOP && iState != TS_GOING_UP )
				{
					ExecuteHam( Ham_Use, iEntity, 0, 0, 0, 1.0 );
				}
			}
		}
	}
}