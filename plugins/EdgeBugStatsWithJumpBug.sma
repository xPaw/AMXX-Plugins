#include < amxmodx >
#include < fakemeta >
#include < hamsandwich >

#define USE_CONNOR_COLOR_NATIVE // Uncomment this line to use ConnorMcLeod's ChatColor
#define USE_SOUNDS // Uncomment this if you want to hear sounds

new const PREFIX[ ] = "[XJ]"; // Change to your own if you want to

#if defined USE_CONNOR_COLOR_NATIVE
	#include < chatcolor >
#else
	#include < colorchat >
	
	#define Red RED
	#define DontChange GREEN
	#define client_print_color ColorChat
#endif

new g_iForwardJB;
new g_iForward;
new g_pGravity;
new g_iEdgebugs[ 33 ];
new g_iFrameTime[ 33 ][ 2 ];

new bool:g_bEdgeBug[ 33 ];
new bool:g_bFalling[ 33 ];
new Float:g_flJumpOff[ 33 ];
new Float:g_flTouchedVelocity[ 33 ];

new bool:g_bInDmgFall[ 33 ], g_iOldButtons, g_iButtons;

public plugin_init( )
{
	new const VERSION[ ] = "2.2 [+JB]";
	
	register_plugin( "EdgeBug Stats", VERSION, "xPaw" );
	
	set_pcvar_string( register_cvar( "edgebug_stats", VERSION, FCVAR_SERVER | FCVAR_SPONLY ), VERSION );
	
	register_forward( FM_CmdStart, "FwdCmdStart" );
	
	RegisterHam( Ham_Player_PostThink, "player", "FwdHamPlayerPostThink_Post", true );
	RegisterHam( Ham_Player_PreThink, "player", "FwdHamPlayerPreThink" );
	RegisterHam( Ham_Touch, "player", "FwdHamPlayerTouch" );
	RegisterHam( Ham_Touch, "trigger_teleport", "FwdHamTeleportTouch" );
	
	g_pGravity = get_cvar_pointer( "sv_gravity" );
	g_iForward = CreateMultiForward( "kz_edgebug", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
	g_iForwardJB = CreateMultiForward( "kz_jumpbug", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL );
}

#if defined USE_SOUNDS
public plugin_precache( )
{
	precache_sound( "jumpstats/excellent.wav" );
	precache_sound( "jumpstats/godlike.wav" );
	precache_sound( "jumpstats/holyshit.wav" );
}
#endif

public client_putinserver( id )
{
	Clear( id );
}

public FwdCmdStart( const id, const iHandle )
{
	g_iFrameTime[ id ][ 1 ] = g_iFrameTime[ id ][ 0 ];
	g_iFrameTime[ id ][ 0 ] = get_uc( iHandle, UC_Msec );
}

public FwdHamPlayerPreThink( const id )
{
	if( !is_user_alive( id ) )
	{
		return;
	}
	else if( pev( id, pev_waterlevel ) > 1 )
	{
		g_bInDmgFall[ id ] = false;
		Clear( id );
		return;
	}
	
	static iFlags;
	iFlags = pev( id, pev_flags );
	
	if( ~iFlags & FL_ONGROUND )
	{
		g_iButtons    = pev( id, pev_button );
		g_iOldButtons = pev( id, pev_oldbuttons );
		
		new Float:flFallVelocity;
		pev( id, pev_flFallVelocity, flFallVelocity );
		
		g_bInDmgFall[ id ] = bool:( flFallVelocity >= 500.0 );
	}
	else
	{
		g_bInDmgFall[ id ] = false;
	}
	
	if( !g_bFalling[ id ] && ~iFlags & FL_ONGROUND )
	{
		g_bFalling[ id ] = true;
		
		new Float:vAbsMin[ 3 ];
		pev( id, pev_absmin, vAbsMin );
		
		g_flJumpOff[ id ] = vAbsMin[ 2 ] + 1.0;
	}
	
	if( g_bFalling[ id ] )
	{
		if( iFlags & FL_ONGROUND )
		{
			Clear( id );
			return;
		}
		
		if( g_bEdgeBug[ id ] )
		{
			g_bEdgeBug[ id ] = false;
			
			new Float:vVelocity[ 3 ];
			pev( id, pev_velocity, vVelocity );
			
			new iEngineFps    = floatround( 1 / ( g_iFrameTime[ id ][ 0 ] * 0.001 ) );
			new iPossibleGain = 2000 / iEngineFps;
			
			new Float:flGravity, Float:flSvGravity = get_pcvar_float( g_pGravity );
			pev( id, pev_gravity, flGravity );
			
			if( floatabs( vVelocity[ 2 ] ) <= iPossibleGain
			&&  floatabs( g_flTouchedVelocity[ id ] ) > iPossibleGain
			&&  floatabs( vVelocity[ 2 ] + flSvGravity * flGravity * 0.001 * 0.5 * g_iFrameTime[ id ][ 1 ] ) < 0.00009 )
			{
				new Float:vOrigin[ 3 ], Float:flFallVelocity;
				pev( id, pev_flFallVelocity, flFallVelocity );
				pev( id, pev_absmin, vOrigin );
				
				vOrigin[ 2 ] += 1.0;
				
				new iDistance = floatround( ( g_flJumpOff[ id ] - vOrigin[ 2 ] ), floatround_floor );
				
				if( iDistance < 17 )
				{
					Clear( id );
					return;
				}
				
				PrintMessage( id, iDistance, floatround( flFallVelocity ), iEngineFps );
				
				g_flJumpOff[ id ] = vOrigin[ 2 ];
			}
		}
	}
}

public FwdHamPlayerPostThink_Post( const id )
{
	if( !g_bInDmgFall[ id ] || g_iOldButtons & IN_JUMP || ~g_iButtons & IN_JUMP )
	{
		return;
	}
	
	if( !is_user_alive( id ) )
	{
		g_bInDmgFall[ id ] = false;
		return;
	}
	
	if( g_iOldButtons & IN_DUCK && ~pev( id, pev_flags ) & FL_DUCKING )
	{
		new Float:vOrigin[ 3 ];
		pev( id, pev_velocity, vOrigin );
		
		if( vOrigin[ 2 ] > 0.0 )
		{
			g_bInDmgFall[ id ] = false;
			
			if( pev( id, pev_waterlevel ) > 0 )
			{
				client_print( id, print_chat, "[JB] Wtf? Water?" );
				return;
			}
			
			new Float:flFallVelocity;
			pev( id, pev_flFallVelocity, flFallVelocity );
			
			if( flFallVelocity < 0.0 )
			{
				client_print( id, print_chat, "[JB] Wtf?" );
				return;
			}
			
			pev( id, pev_absmin, vOrigin );
			
			vOrigin[ 2 ] += 1.0;
			
			new iDistance  = floatround( ( g_flJumpOff[ id ] - vOrigin[ 2 ] ), floatround_floor ),
				iEngineFps = floatround( 1 / ( g_iFrameTime[ id ][ 0 ] * 0.001 ) );
			
			PrintMessageJB( id, iDistance, floatround( flFallVelocity ), iEngineFps );
			
			g_flJumpOff[ id ] = vOrigin[ 2 ];
		}
	}
}

public FwdHamPlayerTouch( const id, const iEntity )
{
	if( !g_bFalling[ id ] )
	{
		return;
	}
	
	static Float:vVelocity[ 3 ];
	pev( id, pev_velocity, vVelocity );
	
	if( vVelocity[ 2 ] >= 0.0 )
	{
		return;
	}
	
	static Float:vOrigin[ 3 ];
	pev( id, pev_origin, vOrigin );
	
	new Float:flMagic = floatabs( vOrigin[ 2 ] - floatround( vOrigin[ 2 ], floatround_tozero ) );
	
	if( flMagic == 0.03125 || flMagic == 0.96875 ) // Lt.Rat is watching you !
	{
		g_bEdgeBug[ id ]          = true;
		g_flTouchedVelocity[ id ] = vVelocity[ 2 ];
	}
}

public FwdHamTeleportTouch( const iEntity, const id )
{
	if( 1 <= id <= 32 ) // g_iMaxPlayers ..
	{
		Clear( id );
	}
}

Clear( const id )
{
	g_bEdgeBug[ id ]  = false;
	g_bFalling[ id ]  = false;
	g_iEdgebugs[ id ] = 0;
}

PrintMessage( const id, const iDistance, const iSpeed, const iEngineFps )
{
	g_iEdgebugs[ id ]++;
	
	new szTag[ 10 ], szMessage[ 256 ];
	
	switch( g_iEdgebugs[ id ] )
	{
		case 1: { }
		case 2: szTag = "Double ";
		case 3: szTag = "Triple ";
		default: formatex( szTag, 9, "%ix ", g_iEdgebugs[ id ] );
	}
	
	engclient_print( id, engprint_console, "^nSuccessful %sEdgeBug was made! Fall Distance: %i units. Fall Speed: %i u/s. Engine FPS: %i^n", szTag, iDistance, iSpeed, iEngineFps );
	
	formatex( szMessage, 255, "Successful %sEdgeBug was made!^nFall Distance: %i units^nFall Speed: %i u/s^nEngine FPS: %i", szTag, iDistance, iSpeed, iEngineFps );
	
	set_hudmessage( 255, 127, 0, -1.0, 0.65, 0, 6.0, 6.0, 0.7, 0.7, 3 );
	show_hudmessage( id, szMessage );
	
	// Print stats to spectators
	new iPlayers[ 32 ], iNum, iSpec;
	get_players( iPlayers, iNum, "bch" );
	
	for( new i; i < iNum; i++ )
	{
		iSpec = iPlayers[ i ];
		
		if( iSpec == pev( id, pev_iuser2 ) )
		{
			show_hudmessage( iSpec, szMessage );
		}
	}
	
	ExecuteForward( g_iForward, iNum, id, iDistance, iSpeed, iEngineFps, g_iEdgebugs[ id ] );
	
	if( iSpeed < 500 )
	{
		return;
	}
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	client_print_color( 0, iDistance >= 2500 ? Red : DontChange, "%s %s did %sEdgeBug! Fall distance is %i units with %i u/s.", PREFIX, szName, szTag, iDistance, iSpeed );
	
#if defined USE_SOUNDS
	if( iDistance >= 2500 )
		client_cmd( 0, "spk ^"%s^"", g_iEdgebugs[ id ] > 1 ? "jumpstats/holyshit.wav" : "jumpstats/godlike.wav" );
#endif
}

PrintMessageJB( const id, const iDistance, const iSpeed, const iEngineFps )
{
	new szMessage[ 256 ];
	
	engclient_print( id, engprint_console, "^nSuccessful JumpBug was made! Fall Distance: %i units. Fall Speed: %i u/s. Engine FPS: %i^n", iDistance, iSpeed, iEngineFps );
	
	formatex( szMessage, 255, "Successful JumpBug was made!^nFall Distance: %i units^nFall Speed: %i u/s^nEngine FPS: %i", iDistance, iSpeed, iEngineFps );
	
	set_hudmessage( 255, 127, 0, -1.0, 0.65, 0, 6.0, 6.0, 0.7, 0.7, 3 );
	show_hudmessage( id, szMessage );
	
	// Print stats to spectators
	new iPlayers[ 32 ], iNum, iSpec;
	get_players( iPlayers, iNum, "bch" );
	
	for( new i; i < iNum; i++ )
	{
		iSpec = iPlayers[ i ];
		
		if( iSpec == pev( id, pev_iuser2 ) )
		{
			show_hudmessage( iSpec, szMessage );
		}
	}
	
	ExecuteForward( g_iForwardJB, iNum, id, iDistance, iSpeed, iEngineFps );
	
	if( iDistance < 500 )
	{
		return;
	}
	
	new szName[ 32 ];
	get_user_name( id, szName, 31 );
	
	client_print_color( 0, Red, "%s %s did JumpBug! Fall distance is %i units with %i u/s.", PREFIX, szName, iDistance, iSpeed );
	
#if defined USE_SOUNDS
	if( iDistance >= 1500 )
		client_cmd( 0, "spk ^"jumpstats/excellent.wav^"" );
#endif
}