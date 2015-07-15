#include < amxmodx >
#include < engine >
#include < achievements >
#include < hamsandwich >

const ONE_HOUR          = 60;
const ONE_DAY           = 600;

// Powerup consts from ricochet plugin
enum _:POWERUPS (<<=1) {
	POW_TRIPLE = 1,
	POW_FAST,
	POW_HARD,
	POW_FREEZE
};

new ACH_DESTRUCT,
	ACH_HUNTER,
	ACH_LAST,
	ACH_DISC,
	ACH_WINNER,
	ACH_TELEPORT,
	ACH_NAME,
	ACH_FREEZE,
	ACH_AIR,
	ACH_INT,
	ACH_REVENGE,
	ACH_POWER,
	ACH_PLAY_AROUND,
	ACH_DAY_MARATHON,
	ACH_ADDICT,
	ACH_POWMASTER,
	ACH_BITCH;

new g_iCount[ 33 ], g_iMyLastKiller[ 33 ], g_iPlayTime[ 33 ];
new bool:g_bHaveAchiev[ 33 ], bool:g_bFirstConnect[ 33 ];
new Float:g_flNextTime[ 33 ], Float:g_flPickup[ 33 ], g_iPowers[ 33 ];

public plugin_init( ) {
	register_plugin( "Ricochet: Achievements", "1.0", "xPaw" );
	
	ACH_DESTRUCT     = RegisterAchievement( "Destruction", "Kill or decapitate 100 enemies", 100 );
	ACH_HUNTER       = RegisterAchievement( "Headhunter", "Decapitate 100 enemies", 100 );
	ACH_LAST         = RegisterAchievement( "Last Shot", "Punch or decapitate enemy when you're falling", 1 );
	ACH_DISC         = RegisterAchievement( "Disc Is Not Illusion", "Block enemy disc with your disc", 1 );
	ACH_WINNER       = RegisterAchievement( "Ricochet King", "Win 5 rounds", 5 );
//	ACH_TELEPORT     = RegisterAchievement( "Teleport Kills", "Kill 50 enemies through teleport", 50 ); // not yet
	ACH_NAME         = RegisterAchievement( "Bloody Feet", "Stand on deflector for 3 seconds", 1 );
	ACH_FREEZE       = RegisterAchievement( "An Elegant Disc", "Freeze 100 players", 100 );
	ACH_AIR          = RegisterAchievement( "Battle in Air", "Hit an enemy when you and him in mid-air", 1 );
	ACH_INT          = RegisterAchievement( "Indestructible", "Kill 5 players in a row without dieing", 1 );
	ACH_REVENGE      = RegisterAchievement( "Revenge", "Kill players who killed you 50 times", 50 );
	ACH_POWER        = RegisterAchievement( "Powerup Thief", "Collect all powerups in single round", 1 );
	ACH_POWMASTER    = RegisterAchievement( "Powerup Master", "Grab 500 powerups", 500 );
	ACH_BITCH        = RegisterAchievement( "They've Always Been Faster", "Kill player after he picks up powerup", 1 );
	ACH_ADDICT       = RegisterAchievement( "Addict", "Join to server 100 times", 100 );
	ACH_PLAY_AROUND  = RegisterAchievement( "Play Around", "Spent 1 hour playing on the server", 1 );
	ACH_DAY_MARATHON = RegisterAchievement( "Day Marathon", "Spent 10 hours playing on the server", 1 );
	
	register_touch( "disc", "disc", "FwdDiscTouch" );
	register_touch( "trigger_push", "player", "FwdPushTouch" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
}

public Achv_Connect( const id, const iPlayTime ) {
	g_bFirstConnect[ id ] = true;
	g_iPlayTime[ id ] = iPlayTime;
	g_iCount[ id ]  = 0;
	g_iMyLastKiller[ id ] = 0;
	g_iPowers[ id ] = 0;
	
	AchievementProgress( id, ACH_ADDICT );
	
	g_bHaveAchiev[ id ] = bool:HaveAchievement( id, ACH_NAME );
}

public FwdHamPlayerSpawnPost( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	if( g_bFirstConnect[ id ] ) {
		g_bFirstConnect[ id ] = false;
		
		if( g_iPlayTime[ id ] >= ONE_HOUR ) {
			AchievementProgress( id, ACH_PLAY_AROUND );
		
			if( g_iPlayTime[ id ] >= ONE_DAY )
				AchievementProgress( id, ACH_DAY_MARATHON );
		}
	}
}

public FwdDiscTouch( iDisc, iOther ) {
	iDisc  = entity_get_edict( iDisc, EV_ENT_euser1 );
	iOther = entity_get_edict( iOther, EV_ENT_euser1 );
	
	if( iDisc != iOther ) {
		AchievementProgress( iDisc, ACH_DISC );
		AchievementProgress( iOther, ACH_DISC );
	}
}

public FwdPushTouch( iEntity, id ) {
	if( g_bHaveAchiev[ id ] ) return;
	
	new Float:flGameTime = get_gametime( ),
		Float:flDiff     = ( g_flNextTime[ id ] - flGameTime );
	
	if( flDiff >= 0.0 ) {
		if( flDiff <= 0.5 ) {
			g_bHaveAchiev[ id ] = true;
			
			AchievementProgress( id, ACH_NAME );
		}
	} else {
		g_flNextTime[ id ] = flGameTime + 3.5;
	}
}

public Rc_RoundEnd( const iRoundFinished, const iWinner ) {
	AchievementProgress( iWinner, ACH_WINNER );
	
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		g_iPowers[ iPlayer ] = 0;
		g_iCount [ iPlayer ] = 0;
	}
}

public Rc_PlayerDeath( const id, const iKiller, bool:bDecapitate, bool:bTeleported ) {
	g_iMyLastKiller[ id ] = iKiller;
	g_iCount[ id ] = 0;
	
	if( !iKiller ) return;
	
	AchievementProgress( iKiller, ACH_DESTRUCT );
	
	if( ++g_iCount[ iKiller ] == 5 )
		AchievementProgress( iKiller, ACH_INT );
	
	if( bDecapitate )
		AchievementProgress( iKiller, ACH_HUNTER );
	
	if( bTeleported )
		AchievementProgress( iKiller, ACH_TELEPORT );
	
	if( g_iMyLastKiller[ iKiller ] == id ) {
		g_iMyLastKiller[ iKiller ] = 0;
		
		AchievementProgress( iKiller, ACH_REVENGE );
	}
}

public Rc_DiscHit( const iDisc, const iVictim, const iOwner ) {
	if( iOwner != iVictim && g_flPickup[ iVictim ] >= get_gametime( ) )
		AchievementProgress( iOwner, ACH_BITCH );
	
	if( entity_get_int( iDisc, EV_INT_iuser1 ) & POW_FREEZE )
		AchievementProgress( iOwner, ACH_FREEZE );
	
	if( entity_get_float( iOwner, EV_FL_flFallVelocity ) > 0 )
		AchievementProgress( iOwner, ACH_LAST );
	
	if( ~entity_get_int( iOwner,  EV_INT_flags ) & FL_ONGROUND
	&&  ~entity_get_int( iVictim, EV_INT_flags ) & FL_ONGROUND )
		AchievementProgress( iOwner, ACH_AIR );
}

public Rc_GainPowerup( const id, iPower ) {
	g_flPickup[ id ] = get_gametime( ) + 2.5;
	
	AchievementProgress( id, ACH_POWMASTER );
	
	if( ~g_iPowers[ id ] & iPower ) {
		g_iPowers[ id ] |= iPower;
		
		if( g_iPowers[ id ] == ( POW_TRIPLE | POW_FAST | POW_HARD | POW_FREEZE ) )
			AchievementProgress( id, ACH_POWER );
	}
}
