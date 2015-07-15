#include < amxmodx >
#include < achievements >
#include < engine >
#include < fakemeta >
#include < cstrike >
#include < hamsandWich >
#include < xs >

/*
	Forwards:
		Jail_CreateDookie( id )         // Who use dookie command
		Jail_CreatePiss( id )           // Who use piss command
		Jail_LrWin( id )                // Who win Last Request
		Jail_LastOne( id )              // Who is the last prisioner
		Jail_Spray( id )				// Winner from Spray Contest
		Jail_Knife( id )				// Winner from Knife Battle
		Jail_LastRequest( id, iChoose ) // Who and wich Last Request option chossed
		Jail_ShotGoal( id, iDistance ) //  Who shot goal and how much is units
		Jail_RamboKill( id ) // Who kill guards
*/

#define UnitsToMeters(%1)	( %1 * 0.0254 )
#define IsUserInWater(%1) ( pev( %1, pev_waterlevel ) > 1 )

#define TIME_TO_PLAY_AS_CT 420 // 7 hours

const m_iJuice 			= 75;
const m_iTrain          = 350;
const m_flNextDecalTime = 486;
const ONE_HOUR          = 60;
const ONE_DAY           = 1440;

new ACH_KILL,
	ACH_ASSASIN,
	ACH_DOOKIE,
	ACH_KIDDY,
	ACH_REBEL,
	ACH_ADDICT,
	ACH_DRIVER,
	ACH_SPRAY,
	ACH_HE,
	ACH_DRUNK,
	ACH_WHATZ_UP,
	ACH_PLAY_AROUND,
	ACH_DAY_MARATHON,
	ACH_DONT_DIE,
	ACH_THREE,
	ACH_BLABLA,
	ACH_KID_WITH_GUN,
	ACH_GHOST_SNIPER,
	ACH_SECRET_ROOM,
	ACH_VANDALISM,
	ACH_HIGH_TEN,
	ACH_GOLD_ARM,
	ACH_SILV_ARM,
	ACH_YARD,
	ACH_ROW_SPRAY,
	ACH_SANDBAG,
	ACH_FYI,
	ACH_HEALTH,
	ACH_ARMOR,
	ACH_DESTINATION,
	ACH_BEHIND,
	ACH_FOOTBALL,
	ACH_SWIM,
	ACH_SNEAKY,
	ACH_LIFESTYLE,
	ACH_DAMAGE,
	ACH_DRIVE_THAT,
	ACH_NEW_SPRAY,
	ACH_DOOKIE_PISS,
	ACH_WALKING,
	ACH_TASTY,
	ACH_OUTLAW_PRESTIGE;

new const Float:g_vNullOrigin[ 3 ];
new Float:g_flDistance[ 33 ], Float:g_vOldOrigin[ 33 ][ 3 ];
new Float:g_flRoundStart, Float:g_flGuardHealer[ 33 ], Float:g_flDookiePiss[ 33 ], bool:g_bTerrorWin, g_iArmor[ 33 ], g_vOrigin[ 33 ][ 3 ];
new g_iPlayTime[ 33 ], g_iKills[ 33 ], g_iKillers[ 33 ], Float:g_flHealth[ 33 ], g_iSpray[ 33 ], g_iMaxPlayers, g_iTotal, bool:g_bLoaded[ 33 ];
new Float:g_flFlashedAt[ 33 ], bool:g_bFirstConnect[ 33 ], bool:g_bDead, Float:g_flWeaponTouch[ 33 ], Float:g_flDamage[ 33 ];

public plugin_init( ) {
	register_plugin( "Jail: Achievements", "1.0", "xPaw / master4life" );
	
	register_event( "HLTV", "EventRoundStart",  "a", "1=0", "2=0" );
	register_event( "23", "EventSpray", "a", "1=112" );
	register_event( "ScreenFade", "EventScreenFade", "be", "1>4096", "4=255", "5=255", "6=255", "7>199" );
	register_event( "SendAudio", "EventSendAudio", "a", "2=%!MRAD_terwin" );
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	register_event( "DeathMsg",   "EventDeathMsg",   "a" );
	
	ACH_HIGH_TEN        = RegisterAchievement( "High Tension", "Score 50 goals", 50 );
	ACH_GOLD_ARM        = RegisterAchievement( "Golden Foot", "Score a goal from a distance of 2000 units", 1 );
	ACH_SILV_ARM        = RegisterAchievement( "Silver Foot", "Score a goal from a distance of 1750 units", 1 );
	ACH_KILL            = RegisterAchievement( "Rebel", "Kill 100 Guards as Prisoner.", 100 );
	ACH_ASSASIN         = RegisterAchievement( "Assassin", " Kill 25 guards with a knife headshot", 25 );
	ACH_DOOKIE          = RegisterAchievement( "Shit Police!", "Make 100 dookies", 100 );
	ACH_KIDDY           = RegisterAchievement( "Desecrate the Dead", "Piss 100 times on the floor or corpses", 100 );
	ACH_REBEL           = RegisterAchievement( "Dealer", " Find 100 weapons as prisoner", 100 );
	ACH_VANDALISM       = RegisterAchievement( "Vandalism", "Destroy 200 breakables on map", 200 );
	ACH_ADDICT          = RegisterAchievement( "Addict", "Join to server 500 times", 500 );
	ACH_DRIVER          = RegisterAchievement( "GET OUT OF MY WAY!", "Kill 25 enemys using a car", 25 );
	ACH_SPRAY           = RegisterAchievement( "Urban designer", "Spray 300 decals.", 300 );
	ACH_HE              = RegisterAchievement( "Danger Close", "Kill 25 guards with a granade", 25 );
	ACH_DRUNK           = RegisterAchievement( "Drunk Driver", "Crush 100 team mates while driving a car", 100 );
	ACH_WHATZ_UP        = RegisterAchievement( "W...Whatz Up?!", "Kill atleast one enemy while flashed as Prisoner", 1 );
	ACH_DONT_DIE        = RegisterAchievement( "Victory", "Win a round as Guard without any guards dying (atleast 3 Guards)", 1 ); // FIXME IN MYSQL !!
	ACH_THREE           = RegisterAchievement( "Three-some", "Kill 3 Guards in single life", 1 );
	ACH_KID_WITH_GUN    = RegisterAchievement( "Kid with gun", "Kill 25 Guards with a TMP", 25 );
	ACH_BLABLA          = RegisterAchievement( "Blabla", "BLABLA", 1 );
	ACH_SECRET_ROOM     = RegisterAchievement( "Michael Scofield", "Press secret button after secret longjump on jail_ms_shawshank", 1 );
	ACH_GHOST_SNIPER    = RegisterAchievement( "Ghost Sniper", "Kill 10 Guards with a AWP", 10 );
	ACH_PLAY_AROUND     = RegisterAchievement( "Play Around", "Spent 1 hour playing on server", 1 );
	ACH_DAY_MARATHON    = RegisterAchievement( "Day Marathon", "Spent 1 day playing on server", 1 );
	ACH_YARD            = RegisterAchievement( "Get out of my yard, boy!", "Kill 25 guard  with shotgun", 25 ); ///////////////
	ACH_ROW_SPRAY       = RegisterAchievement( "Graffiti is my second name", "Spray 8 times in one round", 1 );
	ACH_SANDBAG         = RegisterAchievement( "Sandbag", "Suffer 10000 Total points of damage.", 10000 );
	ACH_FYI             = RegisterAchievement( "Fyi I Am A Spy", "Kill 10 guards while they can't see you.", 10 );
	ACH_HEALTH          = RegisterAchievement( "Medical Intervention", "Heal yourself for total of 10000 HP", 10000 );
	ACH_ARMOR           = RegisterAchievement( "Surgical Prep", "Get yourself total of 1000 armor points using wall rechargers", 1000 );
	ACH_DESTINATION     = RegisterAchievement( "Agent Provocateur", "Win a round as a Prisoner before time hits 4:30 (atleast 3 Guards required)", 1 );
	ACH_BEHIND          = RegisterAchievement( "Preventive Medicine", "Kill a Guard while he is healing himself", 1 );
	ACH_FOOTBALL        = RegisterAchievement( "Football Star", "Score 20 goals while all CTs are dead", 25 );
	ACH_SWIM            = RegisterAchievement( "No guards in pool!", "Kill 5 guards as T while they are in pool", 5 );
	ACH_SNEAKY          = RegisterAchievement( "Say hello to my little friend", "Kill 25 guards with deagle", 25 );
	ACH_LIFESTYLE       = RegisterAchievement( "Specialist", "Kill 10 guards in one map", 10 );
	ACH_DAMAGE          = RegisterAchievement( "Does It Hurt When I Do This?", "Get killed 100 times by environmental damage", 100 );
	ACH_DRIVE_THAT      = RegisterAchievement( "Drive This!", "Kill 20 guard's while they are driving a car", 20 );
	ACH_NEW_SPRAY       = RegisterAchievement( "Now the art is better!", "Kill a guard standing on his own spray", 1 );
	ACH_DOOKIE_PISS     = RegisterAchievement( "Caught with your pants down", "Kill a CT that recently made a dookie or a piss", 1 );
	ACH_WALKING			= RegisterAchievement( "hu?..Freeday?", "Walk 25000 meters.", 25000 );
	//ACH_INCOMMING       = RegisterAchievement( "Incomming!", "Drive 2500 Meters.", 2500 );
	ACH_TASTY           = RegisterAchievement( "That was Tasty!", "Kill 5 guards while you're after spawning 50meters or lower moved.", 5 );
	ACH_OUTLAW_PRESTIGE = RegisterAchievement( "Outlaw Prestige", "Earn all achievements", 1 );
	
	// Dummies
	RegisterAchievement( "Masked Mann", "", 1 );
	RegisterAchievement( "Candy Coroner", "", 1 );
	RegisterAchievement( "Santa's Little Helper", "", 1 );
	
	g_iTotal = GetUnlocksCount( 0 ) - 4; // Cut special achievements (3)
	
	register_clcmd( "say BLABLA", "CmdBla" );
	
	register_touch( "armoury_entity", "player", "FwdPlayerArmouryTouch" );
	
	RegisterHam( Ham_AddPlayerItem, "player", "FwdHamAddPlayerItem", true );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
	RegisterHam( Ham_Use, "func_recharge", "FwdHamRechargeArmorPlayer", true );
	RegisterHam( Ham_Use, "func_vehicle", "FwdHamVehicleUsePre" );
	RegisterHam( Ham_TakeHealth, "player", "FwdHamPlayerHealthPre", false );
	RegisterHam( Ham_TakeDamage, "func_breakable", "FwdBreakableThink", true );
	RegisterHam( Ham_TakeDamage, "func_pushable", "FwdBreakableThink", true );
	RegisterHam( Ham_TakeDamage, "player", "FwdHamTakeDamagePost", true );
	RegisterHam( Ham_Killed, "player", "FwdHamPlayerKilledPre" );
	
	new szMap[ 32 ]; get_mapname( szMap, charsmax( szMap ) );
	if( equali( szMap, "jail_ms_shawshank" ) )
		RegisterHam( Ham_Use, "func_button", "FwdHamUseButtonPre", false );
	
	g_iMaxPlayers = get_maxplayers( );
}

public client_disconnect( id ) {
	g_bLoaded[ id ] = false;
	g_iPlayTime[ id ] = 0;
	g_iKillers[ id ] = 0;
	g_flHealth[ id ] = 0.0;
	g_iArmor[ id ] = 0;
	
	if( g_flDamage[ id ] > 0.0 ) {
		AchievementProgress( id, ACH_SANDBAG, floatround( g_flDamage[ id ] ) );
		
		g_flDamage[ id ] = 0.0;
	}
	
	AddStats( id );
}

public Achv_Connect( const id, const iPlayTime, const iConnects ) {
	g_bLoaded[ id ] = true;
	g_bFirstConnect[ id ] = true;
	g_iPlayTime[ id ] = iPlayTime;
	
	if( g_iPlayTime[ id ] <= TIME_TO_PLAY_AS_CT && is_user_alive( id ) && cs_get_user_team( id ) == CS_TEAM_CT ) {
		cs_set_user_team( id, CS_TEAM_T );
		ExecuteHamB( Ham_CS_RoundRespawn, id );
		
		client_print( id, print_center, "** YOU CAN'T PLAY AS GUARD! **" );
	}
}

public Achv_Unlock( const id, const iAchievement ) {
	new iUserAchs = GetUnlocksCount( id );
	
	if( iUserAchs == g_iTotal )
		AchievementProgress( id, ACH_OUTLAW_PRESTIGE );
		
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

public CmdBla( const id ) {
	AchievementProgress( id, ACH_BLABLA );
	
	return PLUGIN_HANDLED;
}

public EventRoundStart( ) {
	g_bDead = false;
	g_bTerrorWin = false;
	arrayset( g_iKills, 0, 33 );
	arrayset( g_iSpray, 0, 33 );
	arrayset( _:g_flGuardHealer, _:0.0, 33 );
	g_flRoundStart = get_gametime( ) + 60.0;
	
	for( new i = 1; i <= g_iMaxPlayers; i++ ) {
		if( g_flDamage[ i ] > 0.0 ) {
			AchievementProgress( i, ACH_SANDBAG, floatround( g_flDamage[ i ] ) );
			
			g_flDamage[ i ] = 0.0;
		}
	}
}

public EventRoundEnd( ) {
	new iPlayers[ 32 ], CsTeams:iTeams[ 32 ], iNum, i, iPlayer, iCT;
	get_players( iPlayers, iNum );
	
	for( i = 0; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		iTeams[ i ] = cs_get_user_team( iPlayer );
		
		if( iTeams[ i ] == CS_TEAM_CT )
			iCT++;
	}
	
	if( iCT >= 3 ) {
		new Float:flGameTime = get_gametime( );
		
		for( i = 0; i < iNum; i++ ) {
			iPlayer = iPlayers[ i ];
			
			switch( iTeams[ i ] ) {
				case CS_TEAM_T: {
					if( g_flRoundStart >= flGameTime )
						AchievementProgress( iPlayer, ACH_DESTINATION );
				}
				case CS_TEAM_CT: {
					if( !g_bDead )
						AchievementProgress( iPlayer, ACH_DONT_DIE );
				}
			}
		}
	}
}

public EventSpray( ) {
	new iPlayer = read_data( 2 );
	get_user_origin( iPlayer, g_vOrigin[ iPlayer ], false );	
	
	if( ++g_iSpray[ iPlayer ] == 8 )
		AchievementProgress( iPlayer, ACH_ROW_SPRAY );
	
	AchievementProgress( iPlayer, ACH_SPRAY );
}

public EventSendAudio( )
	g_bTerrorWin = true;

public FwdHamRechargeArmorPlayer( const iEntity, const iCaller ) {
	if( !( 1 <= iCaller <= g_iMaxPlayers ) )
		return;
	
//	else if( get_user_health( iCaller ) == 100 ) // Sound bug fix
//		return; // Check armor?
	
	new Float:flGameTime = get_gametime( );
	static Float:flLast[ 33 ];
	
	if( flLast[ iCaller ] > flGameTime )
		return;
	
	flLast[ iCaller ] = flGameTime + 0.1;
	
	if( get_pdata_int( iEntity, m_iJuice, 5 ) <= 0 )
		return;
	
	g_iArmor[ iCaller ]++;
}

public FwdBreakableThink( const iEntity, const iInflictor, const id )
	if( entity_get_float( iEntity, EV_FL_health ) <= 0 && is_user_connected( id ) )
		AchievementProgress( id, ACH_VANDALISM );
 
public EventScreenFade( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	g_flFlashedAt[ id ] = get_gametime( ) + 3.0;
}

public FwdPlayerArmouryTouch( const iEntity, const id )
	g_flWeaponTouch[ id ] = get_gametime( );

public FwdHamAddPlayerItem( const id, const iEntity )
	if( g_flWeaponTouch[ id ] + 0.01 >= get_gametime( ) && get_user_team( id ) == 1 )
		AchievementProgress( id, ACH_REBEL );
		
public FwdHamTakeDamagePost( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits )
	if( get_user_team( id ) != get_user_team( iAttacker ) )
		g_flDamage[ id ] += flDamage;

public FwdHamPlayerSpawnPost( const id ) {
	if( !is_user_alive( id ) )
		return;
	
	g_flFlashedAt[ id ] = 0.0;
	
	if( g_bFirstConnect[ id ] ) {
		AchievementProgress( id, ACH_ADDICT );

		g_bFirstConnect[ id ] = false;
		
		if( g_iPlayTime[ id ] >= ONE_HOUR ) {
			AchievementProgress( id, ACH_PLAY_AROUND );
		
			if( g_iPlayTime[ id ] >= ONE_DAY )
				AchievementProgress( id, ACH_DAY_MARATHON );
		}
	}
	
	if( g_flHealth[ id ] >= 1.0 ) {
		AchievementProgress( id, ACH_HEALTH, floatround( g_flHealth[ id ] ) );
		
		g_flHealth[ id ] = 0.0;
	}
	
	if( g_iArmor[ id ] >= 1 ) {
		AchievementProgress( id, ACH_ARMOR, g_iArmor[ id ] );
		
		g_iArmor[ id ] = 0;
	}
	
	if( g_bLoaded[ id ] && g_iPlayTime[ id ] <= TIME_TO_PLAY_AS_CT && cs_get_user_team( id ) == CS_TEAM_CT ) {
		cs_set_user_team( id, CS_TEAM_T );
		ExecuteHamB( Ham_CS_RoundRespawn, id );
		
		client_print( id, print_center, "** YOU CAN'T PLAY AS GUARD! **" );
	}
	
	set_task( 2.0, "AddStats", id );
}

public AddStats( id ) {
	if( !is_user_connected( id ) )
		return;
	
	new iDistance = floatround( UnitsToMeters( g_flDistance[ id ] ) );
	
	if( iDistance > 0 && cs_get_user_team( id ) == CS_TEAM_T )
		AchievementProgress( id, ACH_WALKING, iDistance );
	
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

public FwdHamPlayerHealthPre( const id, const Float:flHealth ) {
	if( flHealth >= 1.0 && get_user_health( id ) <= 99 ) {
		// if( flHealth > 100 ) flHealth = 100; xpaw hate me -,-'

		if( cs_get_user_team( id ) == CS_TEAM_CT )
			g_flGuardHealer[ id ] = get_gametime( ) + 3.0;
			
		g_flHealth[ id ] += flHealth;
	}
}

public FwdHamUseButtonPre( const iEntity, const id, const iActivator, const iUseType, const Float:flValue ) {
	if( iUseType == 2 && flValue == 1.0 && is_user_alive( id ) ) {
		new szModel[ 6 ];
		entity_get_string( iEntity, EV_SZ_model, szModel, 5 );

		if( equal( szModel, "*178" ) )
			AchievementProgress( id, ACH_SECRET_ROOM );
	}

	return HAM_IGNORED;
}

public FwdHamVehicleUsePre( const iEntity, const id, iActivator, iUseType, Float:flValue ) {
	if( !is_user_alive( id ) || iUseType != 2 || flValue != 1.0 )
		return;
	
	set_pev( iEntity, pev_iuser4, id );
}

public EventDeathMsg( ) {
	new iVictim = read_data( 2 );
	new iKiller = read_data( 1 );
	new iTeam = get_user_team( iKiller );
	new Float:flGameTime = get_gametime( );
	new szWeapon[ 8 ]; read_data( 4, szWeapon, 7 );
	
	if( !iKiller && !equal( szWeapon, "worldspawn" ) )
		AchievementProgress( iVictim, ACH_DAMAGE );
	
	if( iVictim != iKiller && iTeam == 1 ) {
		AchievementProgress( iKiller, ACH_KILL );
	
		if( g_flGuardHealer[ iVictim ] >= flGameTime ) 
			AchievementProgress( iKiller, ACH_BEHIND );
	
		if( g_flFlashedAt[ iKiller ] > flGameTime )
			AchievementProgress( iKiller, ACH_WHATZ_UP );
			
		if( ++g_iKills[ iKiller ] == 3 )
			AchievementProgress( iKiller, ACH_THREE );
		
		if( ++g_iKillers[ iKiller ] == 10 )
			AchievementProgress( iKiller, ACH_LIFESTYLE );
		
		if( g_flDookiePiss[ iVictim ] >= flGameTime )
			AchievementProgress( iKiller, ACH_DOOKIE_PISS );
			
		if( g_flDistance[ iKiller ] <= 600.0 )
			AchievementProgress( iKiller, ACH_TASTY );
		
		if( equal( szWeapon, "knife" ) )
			AchievementProgress( iKiller, ACH_ASSASIN );
		else if( equal( szWeapon, "grenade" ) )
			AchievementProgress( iKiller, ACH_HE );
		else if( equal( szWeapon, "tmp" ) )
			AchievementProgress( iKiller, ACH_KID_WITH_GUN );
		else if( equal( szWeapon, "awp" ) )
			AchievementProgress( iKiller, ACH_GHOST_SNIPER );
		else if( equal( szWeapon, "m3" ) || equal( szWeapon, "xm1014" ) )
			AchievementProgress( iKiller, ACH_YARD );
		else if( equal( szWeapon, "deagle" ) )
			AchievementProgress( iKiller, ACH_SNEAKY );
		
		new vOrigin[ 3 ]; 
		get_user_origin( iVictim, vOrigin, 0 );
		
		if( get_distance( g_vOrigin[ iVictim ], vOrigin ) < 80 )
			AchievementProgress( iKiller, ACH_NEW_SPRAY );
		
		if( cs_get_user_driving( iVictim ) )		
			AchievementProgress( iKiller, ACH_DRIVE_THAT );
			
		new Float:vOrigin2[ 3 ];
		pev( iKiller, pev_origin, vOrigin );

		if( !is_in_viewcone( iVictim, vOrigin2 ) )
			AchievementProgress( iKiller, ACH_FYI );
			
		if( IsUserInWater( iVictim ) )
			AchievementProgress( iKiller, ACH_SWIM );
	}
	
	if( get_user_team( iVictim ) == 2 )
		g_bDead = true;
}

public FwdHamPlayerKilledPre( const iVictim, const  iKiller, iShouldGib ) {
	if( !( 1 <= iKiller <= g_iMaxPlayers ) && pev_valid( iKiller ) ) {
		new szClassname[ 32 ];
		pev( iKiller, pev_classname, szClassname, charsmax( szClassname ) );
		
		if( !equal( szClassname, "func_vehicle" ) )
			return;
		
		new iOwner = pev( iKiller, pev_iuser4 );
		
		if( !is_user_alive( iOwner ) )
			return;
		
		if( get_pdata_int( iOwner, m_iTrain ) )
			AchievementProgress( iOwner, ( get_user_team( iOwner ) == get_user_team( iVictim ) ) ? ACH_DRUNK : ACH_DRIVER );
	}
}

// Forwards

public Jail_CreateDookie( const id ) {
	if( cs_get_user_team( id ) == CS_TEAM_CT ) 
		g_flDookiePiss[ id ] = get_gametime( ) + 3.0;
		
	AchievementProgress( id, ACH_DOOKIE );
}
public Jail_CreatePiss( const id ) {
	if( cs_get_user_team( id ) == CS_TEAM_CT ) 
		g_flDookiePiss[ id ] = get_gametime( ) + 3.0;
		
	AchievementProgress( id, ACH_KIDDY );
}

public Jail_ShotGoal( const id, const iDistance ) {
	AchievementProgress( id, g_bTerrorWin == true ? ACH_FOOTBALL : ACH_HIGH_TEN );
	
	if( iDistance >= 2000 )
		AchievementProgress( id, ACH_GOLD_ARM );
	else if( iDistance >= 1750 )
		AchievementProgress( id, ACH_SILV_ARM );
}
