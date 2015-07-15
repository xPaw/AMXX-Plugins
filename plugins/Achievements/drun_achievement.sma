#include < amxmodx >
#include < achievements >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >
#include < chatcolor >

new ACH_STRIKER,
    ACH_ENEMIES_HATER,
    ACH_ASSASSIN,
    ACH_GRENADE_MAN,
    ACH_BAD_FRIEND,
    ACH_ADDICT,
    ACH_SECRET_PHRASE,
    ACH_PLAY_AROUND,
    ACH_1HP_HERO,
    ACH_SLEEPER,
    ACH_FLASHER,
    ACH_KID_WITH_GUN,
    ACH_AIMBOT,
    ACH_WAR_HERO,
    ACH_SUICIDER,
    ACH_DAY_MARATHON,
    ACH_JESUS,
    ACH_ROAD_KING,
    ACH_CASPER,
    ACH_EVOLUTION,
    ACH_NOBEL_PRIZE,
    ACH_WHATZ_UP,
    ACH_DOMINATOR,
    ACH_HEAD_HUNTER,
    ACH_MILLIONAIRE,
    ACH_ACTIVATOR,
    ACH_HELLRAISER,
    ACH_PYROMANCER,
    ACH_DEALER,
    ACH_STANDALONE,
    ACH_GUNNER,
    ACH_UBERMENSCH,
    ACH_DISTANCE_1,
    ACH_DISTANCE_2,
    ACH_DISTANCE_3,
    ACH_VANDALISM,
    ACH_EASY_MAPS,
    ACH_HARD_MAPS,
    ACH_1TH_MAPS,
    ACH_2TH_MAPS,
    ACH_3TH_MAPS,
    ACH_MONEY,
	ACH_HARD_JUMP,
	ACH_SYNERGY,
	ACH_4TH_MAPS,
	ACH_BEHIND,
	ACH_DOJO,
	ACH_5TH_MAPS,
	ACH_BACKSTABER;

#define IsUserAdmin(%1)   ( get_user_flags( %1 ) & ADMIN_KICK )
#define IsPlayer(%1)      ( 1 <= %1 <= g_iMaxPlayers )
#define UnitsToMeters(%1) ( %1 * 0.0254 )

const m_iToggleState = 41;
const ITEM_HEALTH    = 0;
const ITEM_STEALTH   = 7;
const ITEM_RESPAWN   = 8;
const ONE_HOUR       = 60;
const ONE_DAY        = 1440;

new const Float:g_vNullOrigin[ 3 ];
new bool:g_bSynergy, Float:g_flCasper[ 33 ], bool:g_bDojo;
new Float:g_flDistance[ 33 ], Float:g_vOldOrigin[ 33 ][ 3 ], bool:g_bTransfered[ 33 ], bool:g_bHardJump[ 33 ];
new CsTeams:g_iFlasherTeam, g_iFlasher, bool:g_bEvolution, g_iTeamkills[ 33 ], g_iPlayTime[ 33 ];
new Float:g_flFlashedAt[ 33 ], bool:g_bFirstConnect[ 33 ], Float:g_flWeaponTouch[ 33 ], g_iMaxPlayers;
new g_szMapName[ 32 ], g_iAchv, g_iNumber = -1;
	
public plugin_init( ) {
	register_plugin( "Deathrun: Achievement", "1.0", "xPaw & master4life" );

	ACH_STRIKER       = RegisterAchievement( "Striker", "Kill 100 enemies", 100 );
	ACH_MONEY         = RegisterAchievement( "Spoils Of War", "Win total of 500,000$ using bet system.", 500000 );
	ACH_ENEMIES_HATER = RegisterAchievement( "Enemies Hater", "Kill 250 enemies", 250 );
	ACH_ASSASSIN      = RegisterAchievement( "Assassin", "Kill 20 enemies with headshot from knife", 20 );
	ACH_GRENADE_MAN   = RegisterAchievement( "Grenade Man", "Kill 10 enemies with grenade", 10 );
	ACH_BAD_FRIEND    = RegisterAchievement( "Bad Friend", "Kill 5 teammates in one round", 1 );
	ACH_ADDICT        = RegisterAchievement( "Addict", "Join to server 500 times", 500 );
	ACH_SECRET_PHRASE = RegisterAchievement( "Secret Phrase", "Say secret phrase", 1 );
	ACH_PLAY_AROUND   = RegisterAchievement( "Play Around", "Spent 1 hour playing on server", 1 );
	ACH_1HP_HERO      = RegisterAchievement( "1 HP Hero", "Kill enemy while having 1 HP", 1 );
	ACH_SLEEPER       = RegisterAchievement( "Sleeper", "Flash yourself 50 times", 50 );
	ACH_FLASHER       = RegisterAchievement( "Flasher", "Flash 5 enemies with one flashbang", 1 );
	ACH_KID_WITH_GUN  = RegisterAchievement( "Kid With Gun", "10 Kills with a TMP", 10 );
	ACH_AIMBOT        = RegisterAchievement( "Aimbot", "25 Kills with headshot", 25 );
	ACH_WAR_HERO      = RegisterAchievement( "War Hero", "Kill 555 enemies", 555 );
	ACH_SUICIDER      = RegisterAchievement( "Suicider", "Get killed 500 times", 500 );
	ACH_DAY_MARATHON  = RegisterAchievement( "Day Marathon", "Spent 1 day playing on server", 1 );
	ACH_JESUS         = RegisterAchievement( "Jesus", "Transfer 50 players ( say /transfer )", 50 );
	ACH_ROAD_KING     = RegisterAchievement( "Road King", "Kill 50 terrorists", 50 );
	ACH_CASPER        = RegisterAchievement( "Casper", "Buy stealth 10 times in deathrun shop", 10 );
	ACH_EVOLUTION     = RegisterAchievement( "Evolution", "Finish deathrun_evolution atleast once", 1 ); // 20
	ACH_NOBEL_PRIZE   = RegisterAchievement( "Nobel Prize", "Earn all achievements", 1 );
	ACH_WHATZ_UP      = RegisterAchievement( "W...Whatz Up?!", "Kill atleast one enemy while flashed", 1 );
	ACH_DOMINATOR     = RegisterAchievement( "Dominator", "Kill 10 counter-terrorists (no traps)", 10 );
	ACH_HEAD_HUNTER   = RegisterAchievement( "Head Hunter", "Kill 5 enemies with stationary gun", 5 );
	ACH_MILLIONAIRE   = RegisterAchievement( "Millionaire", "Buy 150 items in deathrun shop", 150 );
	ACH_ACTIVATOR     = RegisterAchievement( "Activator", "Activate 500 buttons", 500 );
	ACH_HELLRAISER    = RegisterAchievement( "Hellraiser", "Buy respawn 10 times in deathrun shop", 10 );
	ACH_PYROMANCER    = RegisterAchievement( "Pyromancer", "Make 200,000 points of total damage", 200000 );
	ACH_DEALER        = RegisterAchievement( "Dealer", "Win 15 successfull bets with prize over 10000$", 15 );
	ACH_STANDALONE    = RegisterAchievement( "Stand-Alone", "Die 15 times as the latest guy in team. (As CT only)", 15 );
	ACH_GUNNER        = RegisterAchievement( "Death-Gunner", " Find 500 weapons as CT", 500 );
	ACH_UBERMENSCH    = RegisterAchievement( "Im ze ubermench!", "Buy HP 250 times", 250 );
	ACH_DISTANCE_1    = RegisterAchievement( "Boink", "Walk 2500 meters.", 2500 );
	ACH_DISTANCE_2    = RegisterAchievement( "Marathon!", "Walk 15000 meters.", 15000 );
	ACH_DISTANCE_3    = RegisterAchievement( "Tour de France", "Walk 50000 meters.", 50000 );
	ACH_VANDALISM     = RegisterAchievement( "Vandalism", "Destroy 200 breakables on map", 200 );
	ACH_EASY_MAPS     = RegisterAchievement( "You Never Studied!", "Finish deathrun_dgs, deathrun_luxus_n1 and deathrun_bleak atleast once", 3 ),
	ACH_HARD_MAPS     = RegisterAchievement( "We Have the Talent!", "Finish deathrun_darkside, deathrun_ijumping_beta7 and deathrun_state3_winter atleast once", 3 );
	ACH_1TH_MAPS      = RegisterAchievement( "Float Like a Butterfly", "Finish deathrun_junbee_beta5, deathrun_hotel and deathrun_industry atleast once.", 3 );
	ACH_2TH_MAPS      = RegisterAchievement( "We're Just Getting Started", "Finish deathrun_midnight_beta3, deathrun_nightmare and deathrun_4life_rmk atleast once.", 3 );
	ACH_3TH_MAPS      = RegisterAchievement( "Mission Impossible", "Finish deathrun_fixxor.", 1 ); // 40
	ACH_4TH_MAPS      = RegisterAchievement( "Camp Fire", "Finish deathrun_dojo, deathrun_trap_canyon and deathrun_burnzone atleast once", 3 );
	ACH_5TH_MAPS      = RegisterAchievement( "Taringacs Family", "finish they taringacs maps ( taringacs_lostrome, taringacs_inthetetris )", 2 );
	ACH_HARD_JUMP     = RegisterAchievement( "Trauma Queen", "Do extreme jump on deathrun_somwhera and succesfully win the round", 1 );
	ACH_SYNERGY       = RegisterAchievement( "Synergy Speedrun", "Complete deathrun_death in 1m50s or less", 1 );
	ACH_BEHIND        = RegisterAchievement( "Counter Espionage", "Kill 15 enemies while under effects of Casper", 15 );
	ACH_DOJO          = RegisterAchievement( "Joint Operation", "Pickup elites on deathrun_dojo and kill 10 enemies with them", 10 );
	ACH_BACKSTABER     = RegisterAchievement( "Is It Safe?", "Kill your teammates 100 times", 100 ); // 8
	
	RegisterHam( Ham_Think, "grenade", "FwdHamGrenadeThink", false );
	RegisterHam( Ham_Spawn, "player",  "FwdHamPlayerSpawnPost", true );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerTakeDamage", true );
	RegisterHam( Ham_Use, "func_button", "FwdHamButtonUse", false );	
	RegisterHam( Ham_AddPlayerItem, "player", "FwdHamAddPlayerItem", true );
	RegisterHam( Ham_TakeDamage, "func_breakable", "FwdBreakableThink", true );
	RegisterHam( Ham_TakeDamage, "func_pushable", "FwdBreakableThink", true );
	
	register_touch( "armoury_entity", "player", "FwdPlayerArmouryTouch" );
	
	register_event( "DeathMsg",   "EventDeathMsg",   "a",  "2>0" );
	register_event( "ScreenFade", "EventScreenFade", "be", "1>4096", "4=255", "5=255", "6=255", "7>199" );
	
	register_logevent( "EventNewRound", 2, "1=Round_Start" );
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	
	register_clcmd( "say", "CmdSay" );
	
	g_iMaxPlayers = get_maxplayers( );
	
	get_mapname( g_szMapName, 31 );
	strtolower( g_szMapName );
	
	if( equali( g_szMapName, "deathrun_evolution" ) )
		g_bEvolution = true;
	else if( equali( g_szMapName, "deathrun_death" ) )
		g_bSynergy = true;
	else if( equali( g_szMapName, "deathrun_dojo" ) ) {
		register_touch( "trigger_teleport", "player", "FwdPlayerTeleportTouch" );
		g_bDojo = true;
	}
	else if( equali( g_szMapName, "deathrun_dgs" )
		|| equali( g_szMapName, "deathrun_somwhera" ) 
		|| equali( g_szMapName, "deathrun_trap_canyon" ) 
		|| equali( g_szMapName, "deathrun_dojo" ) )
		register_touch( "trigger_teleport", "player", "FwdPlayerTeleportTouch" );
	else if( equali( g_szMapName, "deathrun_luxus_n1" ) ) {
		g_iNumber = 1;
		g_iAchv = ACH_EASY_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_bleak" ) ) {
		g_iNumber = 2;
		g_iAchv = ACH_EASY_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_darkside" ) 
		|| equali( g_szMapName, "deathrun_taringacs_lostrome" ) )
		register_touch( "trigger_multiple", "player", "FwdPlayerMultipleTouch" );
	else if( equali( g_szMapName, "deathrun_ijumping_beta7" ) ) {
		g_iNumber = 1;
		g_iAchv = ACH_HARD_MAPS;
	} 
	else if( equali( g_szMapName, "deathrun_state3_winter" ) ) {
		g_iNumber = 2;
		g_iAchv = ACH_HARD_MAPS;
	} 
	else if( equali( g_szMapName, "deathrun_junbee_beta5" ) ) {
		g_iNumber = 0;
		g_iAchv = ACH_1TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_hotel" ) ) {
		g_iNumber = 1;
		g_iAchv = ACH_1TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_industry" ) ) {
		g_iNumber = 2;
		g_iAchv = ACH_1TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_midnight_beta3" ) ) {
		g_iNumber = 0;
		g_iAchv = ACH_2TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_nightmare" ) ) {
		g_iNumber = 1;
		g_iAchv = ACH_2TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_4life_rmk" ) ) {
		g_iNumber = 2;
		g_iAchv = ACH_2TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_burnzone" ) ) {
		g_iNumber = 2;
		g_iAchv = ACH_4TH_MAPS;
	}
	else if( equali( g_szMapName, "deathrun_fixxor" ) )
		register_touch( "trigger_hurt", "player", "FwdPlayerHurtTouch" );
	else if( equali( g_szMapName, "deathrun_taringacs_inthetetris" ) )
		register_touch( "trigger_push", "player", "FwdPlayerPushTouch" );
}

public EventNewRound( ) {
	arrayset( g_iTeamkills, 0, 33 );
	arrayset( g_bTransfered, false, 33 );
	arrayset( g_bHardJump, false, 33 );
	arrayset( _:g_flCasper, _:0.0, 33 );
}

public EventRoundEnd( ) {
	new iPlayers[ 32 ], iNum, iPlayer;
	get_players( iPlayers, iNum );
	
	for( new i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( !is_user_alive( iPlayer ) || !g_bTransfered[ iPlayer ] )
			continue;
		
		if( g_bHardJump[ iPlayer ] )
			AchievementProgress( iPlayer, ACH_HARD_JUMP );
	}
}

public Achv_Unlock( const id, const iAchievement ) {
	if( GetUnlocksCount( id ) == 41 )
		AchievementProgress( id, ACH_NOBEL_PRIZE );
	
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
	g_bTransfered[ id ] = false;
	g_iPlayTime[ id ] = iPlayTime;
	g_iTeamkills[ id ] = 0;
	ResetStats( id );
	
	AchievementProgress( id, ACH_ADDICT );
}

public FwdHamAddPlayerItem( const id, const iEntity )
	 if( g_flWeaponTouch[ id ] + 0.01 >= get_gametime( ) )
		AchievementProgress( id, ACH_GUNNER );
		
public FwdBreakableThink( const iEntity, const iInflictor, const id )
	if( is_user_alive( id ) && entity_get_float( iEntity, EV_FL_health ) <= 0 )
		AchievementProgress( id, ACH_VANDALISM );
		
public FwdHamGrenadeThink( const iEntity ) { // Credits to ConnorMcLeod <3
	if(	entity_get_float( iEntity, EV_FL_dmgtime ) <= get_gametime( )
	&& get_pdata_int( iEntity, 114, 5 ) == 0
	&& !( get_pdata_int( iEntity, 96, 5 ) & ( 1 << 8 ) ) ) {
		static iCount;
		
		if( ++iCount == 2 ) {
			g_iFlasher = entity_get_edict( iEntity, EV_ENT_owner );
			
			if( g_iFlasher > 0 )
				g_iFlasherTeam = cs_get_user_team( g_iFlasher );
		} else {
			g_iFlasher = 0;
			
			if( iCount == 3 )
				iCount = 0;
		}
	}
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
	
	set_task( 0.1, "GivePrizes", id );
	
	new iDistance = floatround( UnitsToMeters( g_flDistance[ id ] ) );
	
	if( iDistance > 0 ) {
		AchievementProgress( id, ACH_DISTANCE_1, iDistance );
		AchievementProgress( id, ACH_DISTANCE_2, iDistance );
		AchievementProgress( id, ACH_DISTANCE_3, iDistance );
	}
	
	ResetStats( id );

	g_flFlashedAt[ id ] = 0.0;
}

public client_PreThink( id ) {
	if( is_user_alive( id ) ) {
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

public CmdSay( const id ) {
	new szSaid[ 50 ];
	read_args( szSaid, 49 );
	remove_quotes( szSaid );
	
	new const PHRASE[ ] = "i love my.run, and this is secret phrase!";
	
	if( equali( szSaid, PHRASE ) ) {
		AchievementProgress( id, ACH_SECRET_PHRASE );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public EventScreenFade( const id ) {
	if( g_iFlasher == 0 || !is_user_alive( id ) )
		return PLUGIN_CONTINUE;
	
	static Float:flLastFlash, Float:flGametime, iFlashes;
	flGametime = get_gametime( );
	
	g_flFlashedAt[ id ] = flGametime + ( read_data( 1 ) >> 12 );
	
	if( flLastFlash == flGametime ) {
		if( cs_get_user_team( id ) != g_iFlasherTeam ) {
			iFlashes++;
			
			if( iFlashes >= 5 )
				AchievementProgress( g_iFlasher, ACH_FLASHER );
		}
	} else {
		flLastFlash = flGametime;
		iFlashes = ( cs_get_user_team( id ) != g_iFlasherTeam ? 1 : 0 );
	}
	
	if( id == g_iFlasher )
		AchievementProgress( id, ACH_SLEEPER );
	
	return PLUGIN_CONTINUE;
}

public FwdPlayerArmouryTouch( const iEntity, const id )
	g_flWeaponTouch[ id ] = get_gametime( );

public FwdPlayerHurtTouch( const iEntity, const id ) {
	if( g_bTransfered[ id ] )
		return;
	
	new szModel[ 6 ];
	entity_get_string( iEntity, EV_SZ_model, szModel, 5 );
	
	if( equal( szModel, "*144" ) )
		AchievementProgress( id, ACH_3TH_MAPS );
}

public FwdPlayerMultipleTouch( const iEntity, const id ) {
	if( g_bTransfered[ id ] )
		return;
	
	new szModel[ 6 ];
	entity_get_string( iEntity, EV_SZ_model, szModel, 5 );
	
	if( equal( szModel, "*205" ) && cs_get_user_team( id ) == CS_TEAM_CT )
		SetAchievementComponentBit( id, ACH_HARD_MAPS, 0 );
	else if( equal( szModel, "*107" ) && cs_get_user_team( id ) == CS_TEAM_CT )
		SetAchievementComponentBit( id, ACH_5TH_MAPS, 0 );
}

public FwdPlayerPushTouch( const iEntity, const id ) {
	if( g_bTransfered[ id ] )
		return;
	
	new szModel[ 6 ];
	entity_get_string( iEntity, EV_SZ_model, szModel, 5 );
	
	if( equal( szModel, "*167" ) && cs_get_user_team( id ) == CS_TEAM_CT )
		SetAchievementComponentBit( id, ACH_5TH_MAPS, 1 );
}

public FwdPlayerTeleportTouch( const iEntity, const id ) {
	if( g_bTransfered[ id ] )
		return;
	
	new szModel[ 6 ];
	entity_get_string( iEntity, EV_SZ_model, szModel, 5 );
	
	if( equal( szModel, "*87" ) )
		SetAchievementComponentBit( id, ACH_EASY_MAPS, 0 );
	else if( equal( szModel, "*170" ) ) // deathrun_dojo
		SetAchievementComponentBit( id, ACH_4TH_MAPS, 0 );
	else if( equal( szModel, "*247" ) || equal( szModel, "*255" ) ) // deathrun_trap_canyon
		SetAchievementComponentBit( id, ACH_4TH_MAPS, 1 );
	else if( equal( szModel, "*95" ) )
		g_bHardJump[ id ] = true;
}

public FwdHamButtonUse( const iEntity, const id, const iActivator, const iUseType, const Float:flValue ) {
	if( iUseType == 2 && flValue == 1.0 && is_user_alive( id ) && get_pdata_int( iEntity, m_iToggleState, 4 ) == 1 ) {
		if( !( pev( iEntity, pev_spawnflags ) & SF_BUTTON_TOGGLE ) )
			AchievementProgress( id, ACH_ACTIVATOR );
		
		if( !g_bTransfered[ id ] && cs_get_user_team( id ) == CS_TEAM_CT ) {
			new szModel[ 6 ];
			entity_get_string( iEntity, EV_SZ_model, szModel, 5 );
			
			if( g_bEvolution ) {
				if( equal( szModel, "*62" ) )
					AchievementProgress( id, ACH_EVOLUTION );
			}
			else if( g_bSynergy ) {
				// [ .. ]
				static Float:flTime[ 33 ];
				
				if( equal( szModel, "*170" ) ) {
					flTime[ id ] = get_gametime( );
					ColorChat( id, Red, "[ mY.RuN ]^1 Your timer has been started!" );
				}
				else if( flTime[ id ] && equal( szModel, "*169" ) ) {
					new Float:flGameTime = get_gametime( ) - flTime[ id ];
					ColorChat( id, Red, "[ mY.RuN ]^1 You have finished in^4 %.2f^1 seconds.", flGameTime ); 
					flTime[ id ] = 0.0;
					
					if( flGameTime <= 110.0 )
						AchievementProgress( id, ACH_SYNERGY );
				}
			}
			else if( g_iAchv > 0 ) {
				switch( g_iNumber ) {
					case 0: {
						if( g_iAchv == ACH_1TH_MAPS && equal( szModel, "*57" ) )
								SetAchievementComponentBit( id, ACH_1TH_MAPS, 0 );
						else if( g_iAchv == ACH_2TH_MAPS && equal( szModel, "*141" ) )
								SetAchievementComponentBit( id, ACH_2TH_MAPS, 0 );
					}
					case 1: {
						if( g_iAchv == ACH_EASY_MAPS && equal( szModel, "*74" ) )
								SetAchievementComponentBit( id, ACH_EASY_MAPS, 1 );	
						else if( g_iAchv == ACH_HARD_MAPS && equal( szModel, "*91" ) )
								SetAchievementComponentBit( id, ACH_HARD_MAPS, 1 );
						else if( g_iAchv == ACH_1TH_MAPS && equal( szModel, "*263" ) )
								SetAchievementComponentBit( id, ACH_1TH_MAPS, 1 );
						else if( g_iAchv == ACH_2TH_MAPS && equal( szModel, "*97" ) )
								SetAchievementComponentBit( id, ACH_2TH_MAPS, 1 );
					}
					case 2: {
						if( g_iAchv == ACH_EASY_MAPS && equal( szModel, "*134" ) )
								SetAchievementComponentBit( id, ACH_EASY_MAPS, 2 );	
						else if( g_iAchv == ACH_HARD_MAPS && equal( szModel, "*161" ) )
								SetAchievementComponentBit( id, ACH_HARD_MAPS, 2 );
						else if( g_iAchv == ACH_1TH_MAPS && equal( szModel, "*179" ) )
								SetAchievementComponentBit( id, ACH_1TH_MAPS, 2 );
						else if( g_iAchv == ACH_2TH_MAPS && equal( szModel, "*92" ) )
								SetAchievementComponentBit( id, ACH_2TH_MAPS, 2 );
						else if( g_iAchv == ACH_4TH_MAPS && equal( szModel, "*197" ) )
								SetAchievementComponentBit( id, ACH_4TH_MAPS, 2 );
					}
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public FwdHamPlayerTakeDamage( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits ) {
	if( iDamageBits & DMG_FALL )
		return;
	
	new iRealAttacker = !IsPlayer( iAttacker ) ? entity_get_int( iAttacker, EV_INT_iuser3 ) : iAttacker;
	
	if( id == iRealAttacker || !IsPlayer( iRealAttacker ) || get_user_team( iRealAttacker ) == get_user_team( id ) )
		return;
	
	if( flDamage > 5000.0 )
		flDamage = 5000.0;
	
	AchievementProgress( iRealAttacker, ACH_PYROMANCER, floatround( flDamage ) );
}

public GivePrizes( const id ) {
	if( is_user_alive( id ) ) {
		if( HaveAchievement( id, ACH_NOBEL_PRIZE ) ) {
			cs_set_user_money( id, clamp( cs_get_user_money( id ) + 500, 0, 16000 ), 1 );
			
			cs_set_user_armor( id, 200, CS_ARMOR_VESTHELM );
		}
	}
}

public JustWonBet( const id, const iMoney ) { // Called from bets plugin
	AchievementProgress( id, ACH_MONEY, iMoney );
	
	if( iMoney >= 10000 )
		AchievementProgress( id, ACH_DEALER );
}

public JustTransferedPlayer( const iTransfer, const id ) { // Called from /transfer plugin
	g_bTransfered[ id ] = true;

	AchievementProgress( iTransfer, ACH_JESUS );	
}

public JustBoughtItem( const id, const iItem ) { // Called from deathrun shop
	AchievementProgress( id, ACH_MILLIONAIRE );
	
	switch( iItem ) {
		case ITEM_HEALTH: AchievementProgress( id, ACH_UBERMENSCH );
		case ITEM_STEALTH:
		{
			g_flCasper[ id ] = get_gametime( ) + 15.0;
			AchievementProgress( id, ACH_CASPER );
		}
		case ITEM_RESPAWN: AchievementProgress( id, ACH_HELLRAISER );
	}
}

public EventDeathMsg( ) {
	new iVictim = read_data( 2 );
	new iAttacker = read_data( 1 );
	
	new CsTeams:iTeam = cs_get_user_team( iVictim );
	
	if( iTeam == CS_TEAM_CT ) {
		new iPlayers[ 32 ], iNum, i, bool:bAnyoneAlive;
		get_players( iPlayers, iNum, "ac" );
		
		for( i = 0; i < iNum; i++ ) {
			if( cs_get_user_team( iPlayers[ i ] ) == CS_TEAM_CT ) {
				bAnyoneAlive = true;
				
				break;
			}
		}
		
		if( !bAnyoneAlive )
			AchievementProgress( iVictim, ACH_STANDALONE );
	}
	
	if( iAttacker != iVictim )
		AchievementProgress( iVictim, ACH_SUICIDER );
	
	if( iAttacker == iVictim || !is_user_connected( iAttacker ) )
		return PLUGIN_CONTINUE;
	
	AchievementProgress( iAttacker, ACH_PYROMANCER, 100 );
	
	if( iTeam == cs_get_user_team( iAttacker ) ) {
		AchievementProgress( iAttacker, ACH_BACKSTABER );
		
		if( ++g_iTeamkills[ iAttacker ] >= 5 )
			AchievementProgress( iAttacker, ACH_BAD_FRIEND );
		
		return PLUGIN_CONTINUE;
	}
	
	if( g_flCasper[ iAttacker ] >= get_gametime( ) )
		AchievementProgress( iAttacker, ACH_BEHIND );
	
	if( !HaveAchievement( iAttacker, ACH_STRIKER ) )
		AchievementProgress( iAttacker, ACH_STRIKER );
	else if( !HaveAchievement( iAttacker, ACH_ENEMIES_HATER ) )
		AchievementProgress( iAttacker, ACH_ENEMIES_HATER );
	else if( !HaveAchievement( iAttacker, ACH_WAR_HERO ) )
		AchievementProgress( iAttacker, ACH_WAR_HERO );
	
	new szWeapon[ 8 ];
	read_data( 4, szWeapon, 7 );
	
	if( equal( szWeapon, "grenade" ) )
		AchievementProgress( iAttacker, ACH_GRENADE_MAN );
	
	if( !is_user_alive( iAttacker ) )
		return PLUGIN_CONTINUE;
	
	if( g_flFlashedAt[ iAttacker ] > get_gametime( ) )
		AchievementProgress( iAttacker, ACH_WHATZ_UP );
	
	if( read_data( 3 ) == 1 ) {
		if( equal( szWeapon, "knife" ) )
			AchievementProgress( iAttacker, ACH_ASSASSIN );
		
		AchievementProgress( iAttacker, ACH_AIMBOT );
	}
	
	switch( iTeam ) {
		case CS_TEAM_CT:{ if( equal( szWeapon, "knife" ) ) AchievementProgress( iAttacker, ACH_DOMINATOR ); }
		case CS_TEAM_T: AchievementProgress( iAttacker, ACH_ROAD_KING );
	}
	
	if( pev( iAttacker, pev_health ) == 1 )
		AchievementProgress( iAttacker, ACH_1HP_HERO );
	
	if( szWeapon[ 0 ] == 't' && szWeapon[ 1 ] == 'm' && szWeapon[ 2 ] == 'p' )
		AchievementProgress( iAttacker, ACH_KID_WITH_GUN );
	else if( szWeapon[ 1 ] == 'a' && szWeapon[ 2 ] == 'n' )
		AchievementProgress( iAttacker, ACH_HEAD_HUNTER );
	
	if( g_bDojo && szWeapon[ 0 ] == 'e'
	&& szWeapon[ 1 ] == 'l' && szWeapon[ 2 ] == 'i' )
		AchievementProgress( iAttacker, ACH_DOJO );
	
	return PLUGIN_CONTINUE;
}
