#include < Amxmodx >
#include < achievements >
#include < fakemeta >
#include < hamsandwich >
#include < engine >
#include < cstrike >

#define IsPlayer(%1) ( 1 <= %1 <= g_iMaxPlayers )
#define IsUserInAir(%1) ( ~pev( %1, pev_flags ) & FL_ONGROUND )

const ONE_HOUR = 60;
const ONE_DAY  = 1440;

new ACH_ADDICT,
	ACH_PLAY_AROUND,
	ACH_DAY_MARATHON,
	ACH_PLANT,
	ACH_COMBAT,
	ACH_RITE,
	ACH_COUNTER,
	ACH_BOOMALA,
	ACH_DEFUSE,
	ACH_ROUNDS1,
	ACH_ROUNDS2,
	ACH_ART_OF_WAR,
	ACH_BODY_BAGGER,
	ACH_GOD_OF_WAR,
	ACH_DEAD_MAN;
new ACH_UNSTOPPABLE,
	ACH_BATTLE_ZERO,
	ACH_FAVOR_POINTS,
	ACH_MADE_POINTS,
	ACH_HAT_TRICK,
	ACH_BUNNY_HUNT,
	ACH_DOUBLE_KILL,
	ACH_CASH,
	ACH_GRENADE,
	ACH_FLASHED,
	ACH_DEFUSETHIS,
	ACH_80HEDMG,
	ACH_BLIND_FURY,
	ACH_GOLDEN_MEDAL;
new ACH_SHORT_FUSE,
	ACH_SECOND_NONE,
	ACH_HARD_WAY,
	ACH_BLAST_WILL,
	ACH_SHOTGUN1,
	ACH_SHOTGUN2,
	ACH_SHOTGUN3,
	ACH_30KILLS;

new Float:g_flGrenade[ 33 ], Float:g_flDoubleKill, g_iDoubleKiller;
new bool:g_bFirstConnect[ 33 ], g_iPlayTime[ 33 ], g_iPlanter, g_iDefuser, bool:g_bNeedKit;
new g_iKillsInRound[ 33 ], g_iHsInRow[ 33 ], g_iMaxPlayers, g_iLastMoney[ 33 ], bool:g_bSecondNone;
new Float:g_flRoundStart;
new g_iMapKills[ 33 ];

new Trie:g_tWeaponAchievements;

public plugin_init( )
{
	register_plugin( "Dust2: Achievements", "1.0", "xPaw" );
	
	g_iMaxPlayers = get_maxplayers( );
	
	ACH_PLANT         = RegisterAchievement( "Someone Set Up Us The Bomb", "Win a round by planting a bomb", 1 );
	ACH_RITE          = RegisterAchievement( "Rite of First Defusal", "Win a round by defusing a bomb", 1 );
	ACH_BOOMALA       = RegisterAchievement( "Boomala Boomala", "Plant 50 bombs", 50 );
	ACH_DEFUSE        = RegisterAchievement( "The Hurt Blocker", "Defuse 50 bombs", 50 );
	ACH_COMBAT        = RegisterAchievement( "Combat Ready", "Defuse a bomb with a kit when it would have failed without one", 1 );
	ACH_COUNTER       = RegisterAchievement( "Counter-Counter-Terrorist", "Kill a CT while he is defusing the bomb", 1 );
	ACH_ROUNDS1       = RegisterAchievement( "Newb World Order", "Win 10 rounds", 10 );
	ACH_ROUNDS2       = RegisterAchievement( "Veteran", "Win 100 rounds", 100 );
	ACH_ART_OF_WAR    = RegisterAchievement( "The Art of War", "Spray 100 decals", 100 );
	ACH_BODY_BAGGER   = RegisterAchievement( "Body Bagger", "Kill 100 enemies", 100 );
	ACH_GOD_OF_WAR    = RegisterAchievement( "God of War", "Kill 500 enemies", 500 );
	ACH_DEAD_MAN      = RegisterAchievement( "Dead Man Stalking", "Kill an enemy while at 1 health", 1 );
	ACH_UNSTOPPABLE   = RegisterAchievement( "The Unstoppable Force", "Kill 5 enemy players in a single round", 1 );
	ACH_BATTLE_ZERO   = RegisterAchievement( "Battle Sight Zero", "Kill 250 enemy players with headshots", 250 );
	ACH_FAVOR_POINTS  = RegisterAchievement( "Points in Your Favor", "Inflict 2,500 total points of damage to enemy players", 2500 );
	ACH_MADE_POINTS   = RegisterAchievement( "You've Made Your Points", "Inflict 50,000 total points of damage to enemy players", 50000 );
	new ACH_STREET_FIGHT = RegisterAchievement( "Street Fighter", "Kill 25 enemies with an knife", 25 );
	ACH_HAT_TRICK     = RegisterAchievement( "Hat Trick", "Get 3 headshots in a row", 1 );
	ACH_BUNNY_HUNT    = RegisterAchievement( "Bunny Hunt", "Kill an airborne enemy", 1 );
	ACH_DOUBLE_KILL   = RegisterAchievement( "Ammo Conservation", "Kill two enemy players with a single bullet", 1 );
	ACH_CASH          = RegisterAchievement( "War Bonds", "Earn $125,000 total cash", 125000 );
	ACH_GRENADE       = RegisterAchievement( "Premature Burial", "Kill an enemy with a grenade after you've died", 1 );
	ACH_FLASHED       = RegisterAchievement( "Blind Ambition", "Kill a total of 25 enemy players blinded by flashbangs", 25 );
	ACH_DEFUSETHIS    = RegisterAchievement( "Defuse This!", "Kill the defuser with an HE grenade", 1 );
	ACH_80HEDMG       = RegisterAchievement( "Shrapnelproof", "Take 80 points of damage from enemy grenades and still survive the round", 1 );
	ACH_BLIND_FURY    = RegisterAchievement( "Blind Fury", "Kill an enemy player while you are blinded from a flashbang", 1 );
	ACH_ADDICT        = RegisterAchievement( "Addict", "Join to the server 500 times", 500 );
	ACH_PLAY_AROUND   = RegisterAchievement( "Play Around", "Spent 1 hour playing on the server", 1 );
	ACH_DAY_MARATHON  = RegisterAchievement( "Day Marathon", "Spent 1 day playing on the server", 1 );
	ACH_GOLDEN_MEDAL  = RegisterAchievement( "Golden Medal", "Achieve 25 of the achievements", 1 );
	ACH_SECOND_NONE   = RegisterAchievement( "Second to None", "Successfully defuse a bomb with less than one second remaining", 1 );
	ACH_HARD_WAY      = RegisterAchievement( "The Hard Way", "Kill two enemy players with a single grenade", 1 );
	ACH_BLAST_WILL    = RegisterAchievement( "Blast Will and Testament", "Win 10 rounds by planting a bomb", 10 );
	
	ACH_SHORT_FUSE    = RegisterAchievement( "Short Fuse", "Plant a bomb within 25 seconds", 1 );
	ACH_30KILLS       = RegisterAchievement( "Serial Killer", "Acquire 30 kills before map change", 1 );
	
	ACH_SHOTGUN1      = RegisterAchievement( "Leone Gauge Super Expert", "Kill 25 enemy players with the Leone 12 Gauge Super", 25 );
	ACH_SHOTGUN2      = RegisterAchievement( "Leone Auto Shotgun Expert", "Kill 25 enemy players with the Leone YG1265 Auto Shotgun", 25 );
	ACH_SHOTGUN3      = RegisterAchievement( "Shotgun Master", "Unlock both shotgun kill achievements", 1 );
	
	new ACH_PISTOL1   = RegisterAchievement( "KM Tactical .45 Expert", "Kill 75 enemy players with the KM Tactical .45 <i>(USP)</i>", 75 );
	new ACH_PISTOL2   = RegisterAchievement( "9x19 Sidearm Expert", "Kill 75 enemy players with the 9x19 Sidearm <i>(Glock)</i>", 75 );
	new ACH_PISTOL3   = RegisterAchievement( "Night Hawk .50c Expert", "Kill 50 enemy players with the Night Hawk .50c <i>(Deagle)</i>", 50 );
	new ACH_PISTOL4   = RegisterAchievement( ".40 Dual Elites Expert", "Kill 25 enemy players with the .40 Dual Elites", 25 );
	new ACH_PISTOL5   = RegisterAchievement( "ES Five-Seven Expert", "Kill 25 enemy players with the ES Five-Seven", 25 );
	new ACH_PISTOL6   = RegisterAchievement( "228 Compact Expert", "Kill 25 enemy players with the 228 Compact", 25 );
	
	new ACH_M4A1      = RegisterAchievement( "Maverick M4A1 Carbine Expert", "Kill 100 enemy players with the Maverick M4A1 Carbine", 100 );
	new ACH_AK47      = RegisterAchievement( "AK-47 Expert", "Kill 100 enemy players with the AK-47", 100 );
	new ACH_AWP       = RegisterAchievement( "Magnum Sniper Rifle Expert", "Kill 50 enemy players with the Magnum Sniper Rifle", 50 );
	new ACH_SCOUT     = RegisterAchievement( "Schmidt Scout Expert", "Kill 25 enemy players with the Schmidt Scout", 25 );
	
	new ACH_FAMAS     = RegisterAchievement( "Clarion 5.56 Expert", "Kill 50 enemy players with the Clarion 5.56", 50 );
	new ACH_GALIL     = RegisterAchievement( "IDF Defender Expert", "Kill 25 enemy players with the IDF Defender", 25 );
	new ACH_MP5       = RegisterAchievement( "KM Sub-Machine Gun Expert", "Kill 50 enemy players with the KM Sub-Machine Gun", 50 );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage", true );
    
	register_logevent( "EventBombDefused", 3, "2=Defused_The_Bomb" );
	register_logevent( "EventPlantTheBomb", 3, "2=Planted_The_Bomb" );
	register_logevent( "EventBombExploded", 6, "3=Target_Bombed" );
	
	register_event( "Money", "EventMoney", "b" );
	register_event( "BarTime", "EventBombDefusing", "be", "1=5", "1=10" );
	register_event( "DeathMsg", "EventDeathMsg", "a", "1>0", "2>0" );
	register_event( "HLTV", "EventRoundStart", "a", "1=0", "2=0" );
	register_event( "SendAudio", "EventSendAudio", "a", "2=%!MRAD_terwin", "2=%!MRAD_ctwin" );
	register_event( "23", "EventSpray", "a", "1=112" );
	
	g_tWeaponAchievements = TrieCreate( );
	
	/*
		http://wiki.amxmodx.org/CS_Weapons_Information
	*/
	
	TrieSetCell( g_tWeaponAchievements, "usp",       ACH_PISTOL1 );
	TrieSetCell( g_tWeaponAchievements, "glock18",   ACH_PISTOL2 );
	TrieSetCell( g_tWeaponAchievements, "deagle",    ACH_PISTOL3 );
	TrieSetCell( g_tWeaponAchievements, "elite",     ACH_PISTOL4 );
	TrieSetCell( g_tWeaponAchievements, "fiveseven", ACH_PISTOL5 );
	TrieSetCell( g_tWeaponAchievements, "p228",      ACH_PISTOL6 );
	
	TrieSetCell( g_tWeaponAchievements, "xm1014",    ACH_SHOTGUN2 );
	TrieSetCell( g_tWeaponAchievements, "m3",        ACH_SHOTGUN1 );
	
	TrieSetCell( g_tWeaponAchievements, "knife",     ACH_STREET_FIGHT );
	TrieSetCell( g_tWeaponAchievements, "m4a1",      ACH_M4A1 );
	TrieSetCell( g_tWeaponAchievements, "ak47",      ACH_AK47 );
	TrieSetCell( g_tWeaponAchievements, "awp",       ACH_AWP );
	TrieSetCell( g_tWeaponAchievements, "scout",     ACH_SCOUT );
	TrieSetCell( g_tWeaponAchievements, "famas",     ACH_FAMAS );
	TrieSetCell( g_tWeaponAchievements, "galil",     ACH_GALIL );
	TrieSetCell( g_tWeaponAchievements, "mp5navy",   ACH_MP5 );
}

public plugin_end( )
{
	TrieDestroy( g_tWeaponAchievements );
}

public Achv_Unlock( const id, const iAchievement )
{
	new iUnlocks = GetUnlocksCount( id ) + 1;
	
	if( 24 < iUnlocks < 30 )
	{
		new iData[ 1 ]; iData[ 0 ] = ACH_GOLDEN_MEDAL;
		
		set_task( 0.1, "TaskUnlockAchievement", id, iData, 1 );
		
		//AchievementProgress( id, ACH_GOLDEN_MEDAL );
	}
	
	if( ( iAchievement == ACH_SHOTGUN1 && HaveAchievement( id, ACH_SHOTGUN2 ) )
	||  ( iAchievement == ACH_SHOTGUN2 && HaveAchievement( id, ACH_SHOTGUN1 ) ) )
	{
		new iData[ 1 ]; iData[ 0 ] = ACH_SHOTGUN3;
		
		set_task( 0.1, "TaskUnlockAchievement", id, iData, 1 );
		
		//AchievementProgress( id, ACH_SHOTGUN3 );
	}
}

public TaskUnlockAchievement( iData[ ], id )
{
	AchievementProgress( id, iData[ 0 ] );
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	g_iPlayTime[ id ] = iPlayTime;
	
	AchievementProgress( id, ACH_ADDICT );
}

public client_putinserver( id )
{
	g_iMapKills[ id ] = 0;
	g_iHsInRow[ id ] = 0;
	g_iLastMoney[ id ] = 0;
	g_iKillsInRound[ id ] = 0;
	g_bFirstConnect[ id ] = true;
}

public FwdHamPlayerSpawnPost( const id )
{
	if( !is_user_alive( id ) )
		return;
	
	if( g_bFirstConnect[ id ] )
	{
		g_bFirstConnect[ id ] = false;
		
		if( g_iPlayTime[ id ] >= ONE_HOUR )
		{
			AchievementProgress( id, ACH_PLAY_AROUND );
		
			if( g_iPlayTime[ id ] >= ONE_DAY )
				AchievementProgress( id, ACH_DAY_MARATHON );
		}
	}
	
	g_flGrenade[ id ] = 0.0;
}

public FwdHamPlayerTakeDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
{
	if( iDamageBits & DMG_FALL || id == iAttacker || !IsPlayer( iAttacker ) )
	{
		return;
	}
	
	if( get_user_team( iAttacker ) != get_user_team( id ) )
	{
		new iDamage = floatround( flDamage );
		
		if( iDamageBits & ( 1 << 24 ) )
		{
			g_flGrenade[ id ] += flDamage;
		}
		
		AchievementProgress( iAttacker, ACH_FAVOR_POINTS, iDamage );
		AchievementProgress( iAttacker, ACH_MADE_POINTS, iDamage );
	}
}

public EventMoney( const id )
{
	new iMoney = read_data( 1 ),
		iLast  = g_iLastMoney[ id ];
	
	if( iMoney > iLast )
	{
		AchievementProgress( id, ACH_CASH, ( iMoney - iLast ) );
	}
	
	g_iLastMoney[ id ] = iMoney;
}

public EventRoundStart( )
{
	g_iPlanter = 0;
	g_iDefuser = 0;
	g_bNeedKit = false;
	g_bSecondNone = false;
	g_flRoundStart = get_gametime( );
	
	arrayset( g_iHsInRow, 0, 33 );
	arrayset( g_iKillsInRound, 0, 33 );
}

public EventSendAudio( )
{
	if( get_playersnum( ) < 4 ) return;
	
	new iPlayers[ 32 ], iNum, id;
	read_data( 2, iPlayers, 8 );
	
	new CsTeams:iWinner = iPlayers[ 7 ] == 't' ? CS_TEAM_T : CS_TEAM_CT;
	
	get_players( iPlayers, iNum, "c" );
	
	for( new i; i < iNum; i++ )
	{
		id = iPlayers[ i ];
		
		if( is_user_alive( id ) && cs_get_user_team( id ) == iWinner )
		{
			AchievementProgress( id, ACH_ROUNDS1 );
			AchievementProgress( id, ACH_ROUNDS2 );
			
			if( g_flGrenade[ id ] >= 80.0 )
			{
				AchievementProgress( id, ACH_80HEDMG );
			}
		}
	}
}

public EventSpray( )
{
	AchievementProgress( read_data( 2 ), ACH_ART_OF_WAR );
}

public EventDeathMsg( )
{
	new iVictim = read_data( 2 ), iKiller = read_data( 1 );
	
	if( iKiller == iVictim )
	{
		return;
	}
	
	AchievementProgress( iKiller, ACH_BODY_BAGGER );
	AchievementProgress( iKiller, ACH_GOD_OF_WAR );
	
	if( ++g_iMapKills[ iKiller ] == 30 )
	{
		AchievementProgress( iKiller, ACH_30KILLS );
	}
	
	if( ++g_iKillsInRound[ iKiller ] == 5 )
	{
		AchievementProgress( iKiller, ACH_UNSTOPPABLE );
	}
	
	new szWeapon[ 12 ];
	read_data( 4, szWeapon, 11 );
	
	if( iVictim == g_iDefuser )
	{
		AchievementProgress( iKiller, ACH_COUNTER );
		
		if( szWeapon[ 0 ] == 'g' && szWeapon[ 1 ] == 'r' )
		{
			AchievementProgress( iKiller, ACH_DEFUSETHIS );
		}
	}
	
	if( read_data( 3 ) ) // headshot
	{
		AchievementProgress( iKiller, ACH_BATTLE_ZERO );
		
		if( ++g_iHsInRow[ iKiller ] == 3 )
			AchievementProgress( iKiller, ACH_HAT_TRICK );
	}
	
	// Double kill check
	new Float:flGameTime = get_gametime( );
	
	if( g_iDoubleKiller == iKiller && g_flDoubleKill == flGameTime )
	{
		AchievementProgress( iKiller, ( szWeapon[ 0 ] == 'g' && szWeapon[ 1 ] == 'r' ) ? ACH_HARD_WAY : ACH_DOUBLE_KILL );
	}
	
	g_iDoubleKiller = iKiller;
	g_flDoubleKill  = flGameTime;
	
	if( GetUserFlash( iVictim ) > flGameTime )
	{
		AchievementProgress( iKiller, ACH_FLASHED );
	}
	
	if( GetUserFlash( iKiller ) > flGameTime )
	{
		AchievementProgress( iKiller, ACH_BLIND_FURY );
	}
	
	if( IsUserInAir( iVictim ) )
	{
		AchievementProgress( iKiller, ACH_BUNNY_HUNT );
	}
	
	if( is_user_alive( iKiller ) )
	{
		if( get_user_health( iKiller ) == 1 )
		{
			AchievementProgress( iKiller, ACH_DEAD_MAN );
		}
	} 
	else
	{
		if( szWeapon[ 0 ] == 'g' && szWeapon[ 1 ] == 'r' )
		{
			AchievementProgress( iKiller, ACH_GRENADE );
		}
	}
	
	//client_print( 0, print_chat, "Weapon: %s", szWeapon );
	
	if( TrieGetCell( g_tWeaponAchievements, szWeapon, iVictim ) )
	{
		AchievementProgress( iKiller, iVictim ); // iVictim == achievement id
	}
}

public EventBombDefusing( const id )
{
	new iC4;
	
	const m_bIsC4 = 96;
	const m_flC4Blow = 100;
	const m_flDefuseCountDown = 99;
	
	while( ( g_iDefuser = engfunc( EngFunc_FindEntityByString, g_iDefuser, "classname", "grenade" ) ) )
	{
		if( get_pdata_int( g_iDefuser, m_bIsC4, 5 ) & ( 1 << 8 ) )
		{
			iC4 = g_iDefuser;
			break;
		}
	}
	
	g_iDefuser = id;
	
	new Float:flTime    = get_pdata_float( iC4, m_flC4Blow, 5 ),
		Float:flDefTime = flTime - get_gametime( );
	
	flTime -= get_pdata_float( iC4, m_flDefuseCountDown, 5 );
	
	if( flDefTime < 10.0 && flTime >= 0.0 )
		g_bNeedKit = true;
	
	if( flTime <= 1.0 )
	{
		g_bSecondNone = true;
	}
}

public EventBombDefused( ) {
	if( is_user_alive( g_iDefuser ) ) {
		AchievementProgress( g_iDefuser, ACH_RITE );
		AchievementProgress( g_iDefuser, ACH_DEFUSE );
		
		if( g_bSecondNone )
			AchievementProgress( g_iDefuser, ACH_SECOND_NONE );
		
		if( g_bNeedKit )
			AchievementProgress( g_iDefuser, ACH_COMBAT );
	}
}

public EventPlantTheBomb( )
{
	if( get_playersnum( ) < 2 ) return;
	
	g_iPlanter = GetUserIndex( );
	
	AchievementProgress( g_iPlanter, ACH_BOOMALA );
	
	new Float:flTimeDifference = get_gametime( ) - g_flRoundStart;
	
	if( flTimeDifference <= 25.0 )
	{
		AchievementProgress( g_iPlanter, ACH_SHORT_FUSE );
	}
}

public EventBombExploded( )
{
	if( is_user_connected( g_iPlanter ) )
	{
		AchievementProgress( g_iPlanter, ACH_PLANT );
		AchievementProgress( g_iPlanter, ACH_BLAST_WILL );
	}
}

GetUserIndex( ) {
	new szLogUser[ 80 ], szName[ 32 ];
	read_logargv( 0, szLogUser, 79 );
	parse_loguser( szLogUser, szName, 31 );
 
	return get_user_index( szName );
}

Float:GetUserFlash( const id )
{
	#define m_flFlashedUntil  514
	#define m_flFlashHoldTime 516
	
	new Float:flFlashedUntil = get_pdata_float( id, m_flFlashedUntil );
	
	if( !flFlashedUntil )
	{
		return 0.0;
	}
	
	new Float:flFlashHoldTime = get_pdata_float( id, m_flFlashHoldTime );
	
	return flFlashedUntil + ( flFlashHoldTime - ( flFlashHoldTime * 0.33 ) );
}
