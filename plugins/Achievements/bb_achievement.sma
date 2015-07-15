#include < amxmodx >
#include < achievements >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

#define UnitsToMeters(%1)	( %1 * 0.0254 )
#define IsPlayer(%1)	( 1 <= %1 <= g_iMaxPlayers )
#define IsUserInAir(%1) ( ~entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND )

const ONE_HOUR = 60;
const ONE_DAY  = 1440;
const m_pPlayer          = 41;
const m_fInReload        = 54;
const m_fInSpecialReload = 55;
const m_flTimeWeaponIdle = 48;

new ACH_ZOMBIE,
    ACH_SURVIVOR,
    ACH_HUNTER,
    ACH_ZOMBIE_STRIKE,
    ACH_ZOMBIE_KING,
    ACH_LEFT4DEAD,
    ACH_KNIFE,
    ACH_FLYAWAY,
    ACH_SPECIALLIST,
    ACH_PYROMANCER,
    ACH_ZOMBIE_ONE,
    ACH_TWOHANDS,
    ACH_BASE_DELUXE,
    ACH_LASTONE,
    ACH_ADDICT,
    ACH_PLAY_AROUND,
    ACH_DAY_MARATHON,
    ACH_NODMG,
    ACH_NIGHTMARE,
    ACH_LEET,
    ACH_DAMAGE,
    ACH_RELOAD,
    ACH_SURESHOT,
    ACH_DISTANCE,
    ACH_SPRAY,
    ACH_FRIEND;

new const Float:g_vNullOrigin[ 3 ];
new Float:g_flDistance[ 33 ], Float:g_vOldOrigin[ 33 ][ 3 ], Float:g_flZombieLastAttack[ 33 ];
new g_iZombieKills[ 33 ], g_iMoves[ 33 ], g_iPlayTime[ 33 ], g_vOrigin[ 33 ][ 3 ], g_iPlayer[ 33 ];
new bool:g_bOverlife[ 33 ], bool:g_bZombieOne[ 33 ], bool:g_bTakeDamage[ 33 ], bool:g_bFirstConnect[ 33 ];

public plugin_init( ) {
	register_plugin( "BaseBuilder: Achievement", "0.1", "master4life" );

	ACH_FRIEND        = RegisterAchievement( "Friendly", "Protect your friend 10 times for zombie", 10 );
	ACH_SPRAY        = RegisterAchievement( "My Brain!", "Spray decal on dead zombie as human 25 times.", 25 );
	ACH_DISTANCE      = RegisterAchievement( "Boink!", "Walk 10000 meters as Zombie.", 10000 );
	ACH_SURESHOT      = RegisterAchievement( "Marksman", "Kill 20 zombies as a human with Scout or Awp", 20 );
	ACH_RELOAD        = RegisterAchievement( "Reloader", "Reload your weapen 1000 times.", 1000 );
	ACH_DAMAGE        = RegisterAchievement( "Smoker", "Kill a human without taking any damage", 1 );
	ACH_ZOMBIE        = RegisterAchievement( "True Zombie", "Kill 255 humans as zombie", 255 );
	ACH_SURVIVOR      = RegisterAchievement( "Survivor", "Survive 200 rounds as a human", 200 );
	ACH_HUNTER        = RegisterAchievement( "Hunter", "Kill 255 zombies as human", 255 );
	ACH_ZOMBIE_STRIKE = RegisterAchievement( "Zombie Strike", "Kill 5 humans in a row as zombie", 1 );
	ACH_ZOMBIE_KING   = RegisterAchievement( "Zombie King", "Kill 5 humans in a row as zombie", 1 );
	ACH_LEFT4DEAD     = RegisterAchievement( "Left 4 Dead", "Survive a round with other 4 humans", 1 );
	ACH_KNIFE         = RegisterAchievement( "Im Legend", "Kill 15 zombies with knife as human", 15 );
	ACH_LEET          = RegisterAchievement( "Leet Zombie", "Kill a human while having 1337 HP", 1 );
	ACH_FLYAWAY       = RegisterAchievement( "Fly way Zombie!!!", "Kill a zombie while he is in air.", 1 );
	ACH_SPECIALLIST   = RegisterAchievement( "Zombie Speciallist!", "Kill 50 zombies with your USP.", 50 );
	ACH_PYROMANCER    = RegisterAchievement( "Pyromancer", "Make 200,000 points of total damage on zombies", 200000 );
	ACH_NIGHTMARE     = RegisterAchievement( "Nightmare", "Make 500,000 points of total damage on zombies", 200000 );
	ACH_ZOMBIE_ONE    = RegisterAchievement( "Five-Some", "Kill 5 humans as a Zombie without dying.", 1 );
	ACH_TWOHANDS      = RegisterAchievement( "Look Ma Two Hands", "Kill 5 zombies as a human with dual pistols", 5 );
	ACH_BASE_DELUXE   = RegisterAchievement( "Builder Deluxe", "Move 10,000 blocks", 10000 );
	ACH_LASTONE       = RegisterAchievement( "Last One", "Survive as the Last Human", 1 );
	ACH_NODMG         = RegisterAchievement( "Unbreakable", "Survive 15 rounds as a human without taking any damage", 15 );
	ACH_ADDICT        = RegisterAchievement( "Addict", "Join to the server 500 times", 500 );
	ACH_PLAY_AROUND   = RegisterAchievement( "Play Around", "Spent 1 hour playing on server", 1 );
	ACH_DAY_MARATHON  = RegisterAchievement( "Day Marathon", "Spent 1 day playing on server", 1 );	
	
	new const NO_RELOAD = ( 1 << 2 ) | ( 1 << CSW_KNIFE ) | ( 1 << CSW_C4 ) | ( 1 << CSW_M3 ) |
		( 1 << CSW_XM1014 ) | ( 1 << CSW_HEGRENADE ) | ( 1 << CSW_FLASHBANG ) | ( 1 << CSW_SMOKEGRENADE );
	    
	new szWeaponName[ 20 ];
	for( new i = CSW_P228; i <= CSW_P90; i++ ) {
		if( NO_RELOAD & ( 1 << i ) )
			continue;
		
		get_weaponname( i, szWeaponName, 19 );
		
		RegisterHam( Ham_Weapon_Reload, szWeaponName, "FwdHamWeaponReload", 1 );    
	}
	
	RegisterHam( Ham_Weapon_Reload, "weapon_m3",     "FwdHamShotgunReload", 1 );
	RegisterHam( Ham_Weapon_Reload, "weapon_xm1014", "FwdHamShotgunReload", 1 );
	
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage", true );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
	
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	
	register_event( "HLTV", "EventRoundStart",  "a", "1=0", "2=0" );
	register_event( "DeathMsg", "EventDeathMsg", "a", "2>0" );
	register_event( "ClCorpse", "EventClCorpse", "a" );
	register_event( "23", "EventSpray", "a", "1=112" );
}

public Achv_Unlock( const id ) {
	if( is_user_alive( id ) ) {
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
		
		message_begin( MSG_PVS, SVC_TEMPENTITY, iOrigin );
		write_byte( TE_PARTICLEBURST );
		write_coord( iOrigin[ 0 ] );
		write_coord( iOrigin[ 1 ] );
		write_coord( iOrigin[ 2 ] );
		write_short( 300 );
		write_byte( 111 ); // http://gm4.in/i/4d5808cb43a54.png
		write_byte( 40 );
		message_end( );
	}
}

public Achv_Connect( const id, const iPlayTime, const iConnects ) {
	g_bFirstConnect[ id ] = true;
	g_iPlayTime[ id ] = iPlayTime;
	ResetStats( id );
}

public FwdHamWeaponReload( const iWeapon ) {
	if( get_pdata_int( iWeapon, m_fInReload, 4 ) ) {
		new iPlayer = get_pdata_cbase( iWeapon, m_pPlayer, 4 )
		
		AchievementProgress( iPlayer, ACH_RELOAD );
	}
}

public FwdHamShotgunReload( const iWeapon ) {
	if( get_pdata_int( iWeapon, m_fInSpecialReload, 4 ) != 1 )
		return;
    
	new Float:flTimeWeaponIdle = get_pdata_float( iWeapon, m_flTimeWeaponIdle, 4 );
    
	if( flTimeWeaponIdle != 0.55 )
		return;
	
	new iPlayer = get_pdata_cbase( iWeapon, m_pPlayer, 4 )
	
	AchievementProgress( iPlayer, ACH_RELOAD );
}

public FwdHamPlayerSpawnPost( const id ) {
	if( !is_user_alive( id ) )
		return;

	if( g_bFirstConnect[ id ] ) {
		AchievementProgress( id, ACH_ADDICT );

		g_bFirstConnect[ id ] = false;
		
		if( g_iPlayTime[ id ] >= ONE_HOUR ) {
			AchievementProgress( id, ACH_PLAY_AROUND );
		
			if( g_iPlayTime[ id ] >= ONE_DAY )
				AchievementProgress( id, ACH_DAY_MARATHON );
		}
	}
	
	set_task( 2.0, "AddStats", id );
	
	g_bTakeDamage[ id ] = false;
}

public AddStats( id ) {
	if( !is_user_connected( id ) )
		return;

	new iDistance = floatround( UnitsToMeters( g_flDistance[ id ] ) );
	
	if( iDistance > 0 && cs_get_user_team( id ) == CS_TEAM_T )
		AchievementProgress( id, ACH_DISTANCE, iDistance );
		
	ResetStats( id );
}

public client_PreThink( id ) {
	if( is_user_alive( id ) && cs_get_user_team( id ) == CS_TEAM_T ) {
		new Float:vOrigin[ 3 ];
		entity_get_vector( id, EV_VEC_origin, vOrigin );
		
		vOrigin[ 2 ] = 0.0;
		
		if( !xs_vec_equal( g_vOldOrigin[ id ], g_vNullOrigin ) )
			g_flDistance[ id ] += get_distance_f( vOrigin, g_vOldOrigin[ id ] );
		
		xs_vec_copy( vOrigin, g_vOldOrigin[ id ] );
	}
}

ResetStats( id ) {
	g_flDistance[ id ] = 0.0;
	xs_vec_copy( g_vNullOrigin, g_vOldOrigin[ id ] );
}

public client_disconnect( id ) {
	g_bOverlife[ id ] = false;
	g_bZombieOne[ id ] = false;
	g_bTakeDamage[ id ] = false;
	g_iZombieKills[ id ] = 0;
}

public bb_grab( const id, const iEntity )
	g_iMoves[ id ]++; 

public EventClCorpse( ) {
	new id = read_data( 12 );
	get_user_origin( id, g_vOrigin[ id ], false );
}

public EventSpray( ) {
	new id = read_data( 2 );
	new vOrigin[ 3 ], iPlayers[ 32 ], iNum, iDistance, iPlayer, i;
	
	get_user_origin( id, vOrigin, false );
	get_players( iPlayers, iNum, "b" );
	for ( i = 0 ; i < iNum; i++ ) { 
		iPlayer = iPlayers[ i ];
		
		if( iPlayer != id ) { 
			iDistance = get_distance( vOrigin, g_vOrigin[ iPlayer ] ); 
			
			if( iDistance < 80 ) { 
				AchievementProgress( id, ACH_SPRAY );
				
				break;
			}
		} 
	} 	
}

public EventRoundStart( ) {
	new iPlayers[ 32 ], iNum, iPlayer, i;
	get_players( iPlayers, iNum );
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( g_iMoves[ iPlayer ] > 0 )
			AchievementProgress( iPlayer, ACH_BASE_DELUXE, g_iMoves[ iPlayer ] );
		
		g_iMoves[ iPlayer ] = 0;
	}
	
	arrayset( g_vOrigin[ 0 ], 0, 3 );
	arrayset( g_bOverlife, false, 33 );	
	arrayset( g_bZombieOne, false, 33 );
	arrayset( g_iZombieKills, 0, 33 );
}

public EventRoundEnd( ) {
	new iPlayers[ 32 ], iNum, iPlayer, i, iCount, iCts[ 4 ];
	get_players( iPlayers, iNum );
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( !is_user_alive( iPlayer )
		|| is_user_bot( iPlayer )
		|| cs_get_user_team( iPlayer ) != CS_TEAM_CT )
			continue;
		
		if( !g_bOverlife[ iPlayer ] )
			AchievementProgress( iPlayer, ACH_SURVIVOR );
		if( !g_bTakeDamage[ iPlayer] )
			AchievementProgress( iPlayer, ACH_NODMG );
		
		if( iCount < 4 )
			iCts[ iCount ] = iPlayer;
		
		iCount++;
	}
	
	if( iCount == 1 )
		AchievementProgress( iCts[ 0 ], ACH_LASTONE );
	else if( iCount == 4 ) {
		for( i = 0; i < 4; i++ )
			AchievementProgress( iCts[ i ], ACH_LEFT4DEAD );
	}
}

public EventDeathMsg( ) {
	new iVictim = read_data( 2 ), iKiller = read_data( 1 );
	get_user_origin( iVictim, g_vOrigin[ iVictim ], false );
	
	g_bOverlife[ iVictim ]  = true;
	g_bZombieOne[ iVictim ] = true;
	
	if( iVictim == iKiller || !is_user_alive( iKiller ) )

		return;
	
	new CsTeams:iTeam = cs_get_user_team( iKiller );
	
	if( iTeam == CS_TEAM_T ) {
		AchievementProgress( iKiller, ACH_ZOMBIE );
		
		new iKills = ++g_iZombieKills[ iKiller ];
		
		if( iKills == 5 ) {
			AchievementProgress( iKiller, ACH_ZOMBIE_STRIKE );
			
			if( !g_bZombieOne[ iKiller ] )
				AchievementProgress( iKiller, ACH_ZOMBIE_ONE );
		}
		else if( iKills == 10 )
			AchievementProgress( iKiller, ACH_ZOMBIE_KING );
		
		if( get_user_health( iKiller ) == 1337 )
			AchievementProgress( iKiller, ACH_LEET );
		
		if( !g_bTakeDamage[ iKiller ] )
			AchievementProgress( iKiller, ACH_DAMAGE );
	} else { // CT obviously.
		AchievementProgress( iKiller, ACH_HUNTER );
		
		if( g_iPlayer[ iVictim ] != iKiller && g_flZombieLastAttack[ iVictim ] >= get_gametime( ) )
			AchievementProgress( iKiller, ACH_FRIEND );
		
		if( IsUserInAir( iVictim ) )
			AchievementProgress( iKiller, ACH_FLYAWAY );
		
		new iWeapon = get_user_weapon( iKiller );
		
		if( iWeapon == CSW_KNIFE )
			AchievementProgress( iKiller, ACH_KNIFE );	
		
		if( iWeapon == CSW_USP )
			AchievementProgress( iKiller, ACH_SPECIALLIST );
		
		if( iWeapon == CSW_ELITE )
			AchievementProgress( iKiller, ACH_TWOHANDS );
		
		if( iWeapon == CSW_SCOUT || iWeapon == CSW_AWP )
			AchievementProgress( iKiller, ACH_SURESHOT );
	}
}

public FwdHamPlayerTakeDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits ) {
	g_bTakeDamage[ id ] = true;
	
	if( iAttacker == id || iDamageBits & DMG_FALL )
		return;
	
	new iTeam = get_user_team( iAttacker );
	
	if( iTeam == 1 ) {
		g_flZombieLastAttack[ iAttacker ] = get_gametime( ) + 5.0; 
	
		g_iPlayer[ id ] = iAttacker;
	}
	
	if( iTeam == 2 && iTeam != get_user_team( id ) )
		AchievementProgress( iAttacker, !HaveAchievement( iAttacker, ACH_PYROMANCER ) ? ACH_PYROMANCER : ACH_NIGHTMARE, floatround( flDamage ) );
}
