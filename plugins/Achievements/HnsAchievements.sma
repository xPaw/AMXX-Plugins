#include < amxmodx >
#include < achievements >
#include < hamsandwich >
#include < fakemeta >
#include < cstrike >
#include < engine >
#include < csx >
#include < xs >

// JUMPSTATS
enum
{
	JUMP_LONG,
	JUMP_HIGH,
	JUMP_WEIRD,
	
	JUMP_BHOP,
	JUMP_STAND_BHOP,
	JUMP_DROPBHOP,
	JUMP_STAND_DROPBHOP,
	
	JUMP_COUNT,
	JUMP_DOUBLECOUNT,
	JUMP_MULTICOUNT,
	JUMP_DROP_COUNT,
	
	JUMP_LADDERJUMP,
	JUMP_LADDERBHOP
};

#define UnitsToMeters(%1)  ( %1 * 0.0254 )
#define IsUserOnGround(%1) ( entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND )
#define IsUserOnLadder(%1) ( entity_get_int( %1, EV_INT_movetype ) == MOVETYPE_FLY )

new g_iHS[ 33 ];
new g_iJumps[ 33 ];
new g_iPlayTime[ 33 ];
new g_iRoundKills[ 33 ];
new g_iCounterKills[ 33 ];
new g_iWins[ 33 ];

new bool:g_bJB[ 33 ];
new bool:g_bEB[ 33 ];

new Float:g_flGameStart;
new Float:g_flLastKill[ 33 ];
new Float:g_flDistance[ 33 ];
new Float:g_flFlashedAt[ 33 ];
new Float:g_vOldOrigin[ 33 ][ 3 ];
new Float:g_vDeathOrigin[ 33 ][ 3 ];

new const Float:g_vNullOrigin[ 3 ];

new ACH_KILL_1ST,
	ACH_LADDER,
	ACH_SURVIVE,
	ACH_AIR_BORNE,
	ACH_FLASHED,
	ACH_EDGEBUG_1HP,
	ACH_EDGEBUG_2TH,
	ACH_HIGH_EDGE;

new	ACH_DISTANCE,
	ACH_FAST_ASSASINS,
	ACH_ADDICT,
	ACH_PLAY_AROUND,
	ACH_DAY_MARATHON,
	ACH_3HS_IN_ROW,
	ACH_TRHOW_NADE;
	// +1

new ACH_EB_JB,
	ACH_JUMPBUG,
	ACH_JUMPBUGS,
	ACH_JUMPBUG_1HP,
	ACH_EDGEBUG_DBL,
	ACH_EDGEBUG_DBL2,
	ACH_1HP_SURVIVE,
	ACH_3CT_SURVIVE;

new ACH_MAP_SURVIVE,
	ACH_LADDER_JUMP,
	ACH_KILL_FIVE,
	ACH_THREE_MIN,
	ACH_MAP_JUMPS;

new ACH_LJ_PRE_BHOP,
	ACH_LJ_260CJ,
	ACH_LJ_250LJ,
	ACH_LJ_240BJ,
	ACH_LJ_WOOT;
	
new ACH_SPRAY,
	ACH_HUMILIATE,
	ACH_TERRORIST,
	ACH_NADE_CT,
	ACH_DAMAGE;

public plugin_init( )
{
	register_plugin( "HNS: Achievements", "1.0", "xPaw & master4life" );
	
	ACH_SURVIVE       = RegisterAchievement( "Catch me if you can", "Survive 50 rounds as a Terrorist", 50 );
	ACH_DISTANCE      = RegisterAchievement( "Far, far away", "Walk 10000 meters", 10000 );
	
	ACH_AIR_BORNE     = RegisterAchievement( "Air Show", "Kill 50 enemies while they are in air", 50 );
	ACH_FLASHED       = RegisterAchievement( "Blind Ambition", "Kill 5 Terrorists while they are fully flashed", 5 );
	ACH_FAST_ASSASINS = RegisterAchievement( "Double Cross", "Kill 2 Terrorists in 2 seconds or less", 1 );
	ACH_LADDER        = RegisterAchievement( "Ladderlicious", "Kill 15 Terrorists while they are on a ladder", 15 );
	
	ACH_DAMAGE        = RegisterAchievement( "Does It Hurt When I Do This?", "Get killed 100 times by environmental damage", 100 );
	ACH_TERRORIST     = RegisterAchievement( "Your Experience", "Kill 500 Terrorists", 500 );
	ACH_NADE_CT       = RegisterAchievement( "No Hard Feelings", "Kill 15 Counter-Terrorists with a grenade", 15 );
	ACH_SPRAY         = RegisterAchievement( "Urban Designer", "Spray 100 decals", 100 );
	ACH_HUMILIATE     = RegisterAchievement( "Who Cares? They're dead!", "Spray 15 decals on dead bodies of Counter-Terrorists", 15 );
	
	ACH_3HS_IN_ROW    = RegisterAchievement( "Eviction Notice", "Get 3 headshots in a row", 1 );
	ACH_1HP_SURVIVE   = RegisterAchievement( "Wounded But Steady", "Survive a round while having 1 HP left", 1 );
	ACH_3CT_SURVIVE   = RegisterAchievement( "Against The Odds", "Survive a round against 3 or more Counter-Terrorists", 1 );
	ACH_MAP_SURVIVE   = RegisterAchievement( "Still Alive", "Survive 10 rounds before a map change", 1 );
	ACH_MAP_JUMPS     = RegisterAchievement( "Super Mario Brothers", "Make 2000 jumps before map change", 1 );
	
	ACH_EB_JB         = RegisterAchievement( "Old School", "Make a edgebug and jumpbug in same round", 1 );
	ACH_EDGEBUG_1HP   = RegisterAchievement( "Asking for Trouble", "Make a edgebug from a height of 1000 units while at 1 HP", 1 );
	ACH_EDGEBUG_2TH   = RegisterAchievement( "Basic Science", "Make a edgebug from a height of 1500 or higher", 1 );
	ACH_HIGH_EDGE     = RegisterAchievement( "Edgebug Veteran", "Perform 25 successful edgebugs", 25 );
	ACH_EDGEBUG_DBL   = RegisterAchievement( "New Innovation", "Make a double edgebug", 1 );
	ACH_EDGEBUG_DBL2  = RegisterAchievement( "Double Edgebug Veteran", "Perform 10 successful double edgebugs", 10 );
	
	ACH_JUMPBUG_1HP   = RegisterAchievement( "Preservation of Mass", "Make a jumpbug while at 1 HP", 1 );
	ACH_JUMPBUG       = RegisterAchievement( "Pit Boss", "Make a jumpbug", 1 );
	ACH_JUMPBUGS      = RegisterAchievement( "Jumpbug Veteran", "Perform 25 successful jumpbugs", 25 );
	
	ACH_KILL_1ST      = RegisterAchievement( "Serial Killer", "Acquire 30 kills before map change", 1 );
	ACH_THREE_MIN     = RegisterAchievement( "Party of Three", "Acquire 3 kills within 60 seconds after round start", 1 );
	
	ACH_KILL_FIVE     = RegisterAchievement( "Take No Prisoners", "Get 5 kills in single round", 1 );
	ACH_LADDER_JUMP   = RegisterAchievement( "Vertically Unchallenged", "Kill 5 Terrorists that are on ladder, while you are in air", 5 );
	ACH_TRHOW_NADE    = RegisterAchievement( "Potato Layer", "Throw 1000 grenades", 1000 );
	
	ACH_LJ_PRE_BHOP   = RegisterAchievement( "Stranger Than Friction", "Get prestrafe speed of 299 on bhop and successfully make the jump", 1 );
	ACH_LJ_260CJ      = RegisterAchievement( "Count Jump", "Jump 260 countjump 5 times", 5 );
	ACH_LJ_250LJ      = RegisterAchievement( "Long Jump", "Jump 250 longjump 5 times", 5 );
	ACH_LJ_240BJ      = RegisterAchievement( "Bhop Jump", "Jump 240 bhopjump 5 times", 5 );
	ACH_LJ_WOOT       = RegisterAchievement( "Triple Crown", "Unlock 3 achievements: Count Jump, Long Jump and Bhop Jump", 3 );
	
	ACH_ADDICT        = RegisterAchievement( "Addict", "Join to the server 500 times", 500 );
	ACH_PLAY_AROUND   = RegisterAchievement( "Play Around", "Spent 1 hour playing on server", 1 );
	ACH_DAY_MARATHON  = RegisterAchievement( "Day Marathon", "Spent 1 day playing on server", 1 );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
	RegisterHam( Ham_Player_PreThink, "player", "FwdHamPlayerPreThink", true );
	
	register_event( "ScreenFade", "EventScreenFade", "be", "1>4096", "4=255", "5=255", "6=255", "7>199" );
	register_event( "DeathMsg", "EventDeathMsg", "a", "2>0" );
	register_event( "SendAudio", "EventSendAudio", "a", "2=%!MRAD_terwin" ); // "2=%!MRAD_ctwin"
	register_event( "HLTV", "EventRoundStart",  "a", "1=0", "2=0" );
	register_event( "23", "EventSpray", "a", "1=112" );
	register_event( "ClCorpse", "EventClCorpse", "a" );
}

public Achv_Unlock( const id, const iAchievement )
{
	new i = -1;
	
	if( iAchievement      == ACH_LJ_260CJ ) i = 0;
	else if( iAchievement == ACH_LJ_250LJ ) i = 1;
	else if( iAchievement == ACH_LJ_240BJ ) i = 2;
	
	if( i > -1 )
	{
		SetAchievementComponentBit( id, ACH_LJ_WOOT, i );
	}
	
	if( is_user_alive( id ) )
	{
		new iOrigin[ 3 ];
		get_user_origin( id, iOrigin );
		
		message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
		write_byte( TE_IMPLOSION );
		write_coord( iOrigin[ 0 ] );
		write_coord( iOrigin[ 1 ] );
		write_coord( iOrigin[ 2 ] );
		write_byte( 400 );
		write_byte( 100 );
		write_byte( 7 );
		message_end( );
	}
}

ResetStats( id )
{
	g_flDistance[ id ] = 0.0;
	g_vOldOrigin[ id ] = g_vNullOrigin;
}

public client_putinserver( id )
{
	ResetStats( id );
	
	g_iCounterKills[ id ]
	= g_iJumps[ id ]
	= g_iWins[ id ]
	= g_iHS[ id ]
	= g_iRoundKills[ id ] = 0;
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	g_iPlayTime[ id ] = iPlayTime;
	
	AchievementProgress( id, ACH_ADDICT );
}

public EventRoundStart( )
{
	g_flGameStart = get_gametime( ) + 60.0;
}

public grenade_throw( id, iEntity, iNadeType )
{
	AchievementProgress( id, ACH_TRHOW_NADE );
}

public EventSendAudio( )
{
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "c" );
	
	if( iNum < 2 )
	{
		return;
	}
	
	new i, id, iTS[ 32 ], iTNum, iCTNum, CsTeams:iTeam;
	
	for( i = 0; i < iNum; i++ )
	{
		id = iPlayers[ i ];
		
		iTeam = cs_get_user_team( id );
		
		if( iTeam == CS_TEAM_CT )
		{
			if( is_user_alive( id ) )
			{
				iCTNum++;
			}
		}
		else if( iTeam == CS_TEAM_T && is_user_alive( id ) )
		{
			iTS[ iTNum++ ] = id;
			
			AchievementProgress( id, ACH_SURVIVE );
			
			if( get_user_health( id ) == 1 )
			{
				AchievementProgress( id, ACH_1HP_SURVIVE );
			}
			
			if( ++g_iWins[ id ] == 10 )
			{
				AchievementProgress( id, ACH_MAP_SURVIVE );
			}
		}
	}
	
	if( iTNum && iCTNum >= 3 )
	{
		for( i = 0; i < iTNum; i++ )
		{
			AchievementProgress( iTS[ i ], ACH_3CT_SURVIVE );
		}
	}
}

public EventClCorpse( )
{
	if( read_data( 11 ) != 2 ) // CS_TEAM_CT
	{
		return;
	}
	
	new id = read_data( 12 );
	
	read_data( 2, g_vDeathOrigin[ id ][ 0 ] );
	read_data( 3, g_vDeathOrigin[ id ][ 1 ] );
	read_data( 4, g_vDeathOrigin[ id ][ 2 ] );
	
	g_vDeathOrigin[ id ][ 0 ] /= 128.0;
	g_vDeathOrigin[ id ][ 1 ] /= 128.0;
	g_vDeathOrigin[ id ][ 2 ] /= 128.0;
}

public EventSpray( )
{
	new id = read_data( 2 );
	
	AchievementProgress( id, ACH_SPRAY );
	
	if( cs_get_user_team( id ) != CS_TEAM_T )
	{
		return;
	}
	
	new Float:vOrigin[ 3 ], iPlayers[ 32 ], iNum, iPlayer;
	
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	get_players( iPlayers, iNum, "be", "CT" );
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		
		if( get_distance_f( vOrigin, g_vDeathOrigin[ iPlayer ] ) < 80.0 )
		{
			AchievementProgress( id, ACH_HUMILIATE );
			
			break;
		}
	}
}

public EventScreenFade( const id )
{
	g_flFlashedAt[ id ] = get_gametime( ) + ( read_data( 1 ) >> 12 );
}

public EventDeathMsg( )
{
	new iVictim = read_data( 2 ),
		iKiller = read_data( 1 );
	
	if( !iKiller || iKiller == iVictim )
	{
		AchievementProgress( iVictim, ACH_DAMAGE );
		
		return;
	}
	
	g_iHS[ iVictim ] = 0;
	
	new CsTeams:iTeam = cs_get_user_team( iKiller );
	
	if( iTeam == CS_TEAM_CT )
	{
		entity_get_vector( iVictim, EV_VEC_origin, g_vDeathOrigin[ iVictim ] );
		
		AchievementProgress( iKiller, ACH_TERRORIST );
		
		if( ++g_iCounterKills[ iKiller ] == 30 )
		{
			AchievementProgress( iKiller, ACH_KILL_1ST );
		}
		
		if( ++g_iRoundKills[ iKiller ] == 5 )
		{
			AchievementProgress( iKiller, ACH_KILL_FIVE );
		}
		else if( g_iRoundKills[ iKiller ] == 3 && g_flGameStart >= get_gametime( ) )
		{
			AchievementProgress( iKiller, ACH_THREE_MIN );
		}
		
		if( !IsUserOnGround( iKiller ) && IsUserOnLadder( iVictim ) )
		{
			AchievementProgress( iKiller, ACH_LADDER_JUMP );
		}
		
		if( read_data( 3 ) )
		{
			if( ++g_iHS[ iKiller ] == 3 )
			{
				AchievementProgress( iKiller, ACH_3HS_IN_ROW );
			}
		}
		else
		{
			g_iHS[ iKiller ] = 0;
		}
		
		if( g_flFlashedAt[ iVictim ] > get_gametime( ) )
		{
			AchievementProgress( iKiller, ACH_FLASHED );
		}
		
		if( IsUserOnLadder( iVictim ) )
		{
			AchievementProgress( iKiller, ACH_LADDER );
		}
		else if( !IsUserOnGround( iVictim ) )
		{
			AchievementProgress( iKiller, ACH_AIR_BORNE );
		}
		
		new Float:flGameTime = get_gametime( );
		
		if( g_flLastKill[ iKiller ] >= flGameTime )
		{
			AchievementProgress( iKiller, ACH_FAST_ASSASINS );
		}
		
		g_flLastKill[ iKiller ] = flGameTime + 2.0;
	}
	else if( iTeam == CS_TEAM_T )
	{
		new szWeapon[ 5 ]; 
		read_data( 4, szWeapon, 4 );
		
		if( szWeapon[ 0 ] == 'g' && szWeapon[ 3 ] == 'n' ) // grenade
		{
			AchievementProgress( iKiller, ACH_NADE_CT );
		}
	}
}

public AddStats( id )
{
	if( !is_user_connected( id ) )
	{
		return;
	}
	
	new iDistance = floatround( UnitsToMeters( g_flDistance[ id ] ) );
	
	if( iDistance > 0 && cs_get_user_team( id ) == CS_TEAM_T )
	{
		AchievementProgress( id, ACH_DISTANCE, iDistance );
	}
	
	ResetStats( id );
}

public FwdHamPlayerSpawnPost( const id )
{
	if( !is_user_alive( id ) )
	{
		return;
	}
	
	if( g_iPlayTime[ id ] )
	{
		#define ONE_HOUR 60
		#define ONE_DAY  1440
		
		if( g_iPlayTime[ id ] >= ONE_HOUR )
		{
			AchievementProgress( id, ACH_PLAY_AROUND );
			
			if( g_iPlayTime[ id ] >= ONE_DAY )
			{
				AchievementProgress( id, ACH_DAY_MARATHON );
			}
		}
		
		g_iPlayTime[ id ] = 0;
	}
	
	set_task( 2.0, "AddStats", id );
	
	g_iRoundKills[ id ] = 0;
	g_flFlashedAt[ id ] = 0.0;
	g_bEB[ id ] = g_bJB[ id ] = false;
	g_vDeathOrigin[ id ] = g_vNullOrigin;
}

public FwdHamPlayerPreThink( const id )
{
	if( is_user_alive( id ) )
	{
		#define m_afButtonPressed 246
		
		if( IsUserOnGround( id )
		&&  get_pdata_int( id, m_afButtonPressed ) & IN_JUMP
		&&  ++g_iJumps[ id ] == 2000 )
		{
			AchievementProgress( id, ACH_MAP_JUMPS );
		}
		
		if( cs_get_user_team( id ) != CS_TEAM_T )
		{
			return;
		}
		
		static Float:vOrigin[ 3 ];
		entity_get_vector( id, EV_VEC_origin, vOrigin );
		
		vOrigin[ 2 ] = 0.0;
		
		if( !xs_vec_equal( g_vOldOrigin[ id ], g_vNullOrigin ) )
		{
			g_flDistance[ id ] += get_distance_f( vOrigin, g_vOldOrigin[ id ] );
		}
		
		g_vOldOrigin[ id ] = vOrigin;
	}
}

public kz_edgebug( const id, const iDistance, const iSpeed, const iEngineFps, const iTimes )
{
	if( iDistance < 150 )
	{
		return;
	}
	
	AchievementProgress( id, ACH_HIGH_EDGE );
	
	if( iTimes == 2 )
	{
		AchievementProgress( id, ACH_EDGEBUG_DBL );
		AchievementProgress( id, ACH_EDGEBUG_DBL2 );
	}
	
	if( iDistance >= 1000 && get_user_health( id ) == 1 )
	{
		AchievementProgress( id, ACH_EDGEBUG_1HP );
	}
	
	if( iDistance >= 1500 )
	{
		AchievementProgress( id, ACH_EDGEBUG_2TH );
	}
	
	g_bEB[ id ] = true;
	
	CheckEB_JB( id );
}

public kz_jumpbug( const id, const iDistance, const iSpeed, const iEngineFps )
{
	AchievementProgress( id, ACH_JUMPBUG );
	AchievementProgress( id, ACH_JUMPBUGS );
	
	if( get_user_health( id ) == 1 )
	{
		AchievementProgress( id, ACH_JUMPBUG_1HP );
	}
	
	g_bJB[ id ] = true;
	
	CheckEB_JB( id );
}

CheckEB_JB( id )
{
	if( g_bEB[ id ] && g_bJB[ id ] )
	{
		AchievementProgress( id, ACH_EB_JB );
	}
}

public js_jump( id, iType, iDirection, Float:flDistance, Float:flPreStrafe, Float:flMaxSpeed, iStrafes, iSync )
{
	if( flDistance >= 260.0 && ( iType == JUMP_COUNT || iType == JUMP_DOUBLECOUNT || iType == JUMP_MULTICOUNT ) )
	{
		AchievementProgress( id, ACH_LJ_260CJ );
	}
	
	if( flPreStrafe >= 299.0 && ( iType == JUMP_BHOP || iType == JUMP_STAND_BHOP ) )
	{
		AchievementProgress( id, ACH_LJ_PRE_BHOP );
	}
	
	if( flDistance >= 250.0 && ( iType == JUMP_LONG || iType == JUMP_HIGH ) )
	{
		AchievementProgress( id, ACH_LJ_250LJ );
	}
	
	if( flDistance >= 240.0 && ( iType == JUMP_BHOP || iType == JUMP_STAND_BHOP ) )
	{
		AchievementProgress( id, ACH_LJ_240BJ );
	}
}
