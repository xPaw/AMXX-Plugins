#include < amxmodx >
#include < achievements >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < xs >

/*
	Forward: Knife_FreeHit( const id );
	Forward: Knife_Distance( const id, Float:iDistance, bool:bStabbed );
*/

#define UnitsToMeters(%1)	( %1 * 0.0254 )
#define IsUserInAir(%1)		( ~entity_get_int( %1, EV_INT_flags ) & FL_ONGROUND )

const ONE_HOUR       = 60;
const ONE_DAY        = 1440;

new ACH_ADDICT,
	ACH_PLAY_AROUND,
	ACH_DAY_MARATHON,
	ACH_PRO_KNIFER,
	ACH_LAMER,
	ACH_SPENT,
	ACH_VANDALISM,
	ACH_1HP_HERO,
	ACH_PYROMANCER,
	ACH_DISTANCE,
	ACH_DISTANCE_2TH,
	ACH_KNIFER,
	ACH_KNIFER_2,
	ACH_HUMILIATE,
	ACH_1HP_STAR,
	ACH_BOINK,
	ACH_JUMPED,
	ACH_SPRAY,
	ACH_100HP;

new const Float:g_vNullOrigin[ 3 ];
new Float:g_flDistance[ 33 ], Float:g_vOldOrigin[ 33 ][ 3 ];
new bool:g_b1HP, bool:g_b100HP, Float:g_vDeathOrigin[ 33 ][ 3 ];
new bool:g_bFirstConnect[ 33 ], g_iPlayTime[ 33 ], g_iHeadshotKills[ 33 ];

public plugin_init( ) {
	register_plugin( "Knife: Achievements", "0.1", "master4life" );
	
	ACH_100HP         = RegisterAchievement( "Medic is useless!", "Kill 50 enemies on 100hp map", 50 );
	ACH_SPRAY         = RegisterAchievement( "Urban designer", "Spray 300 decals.", 300 );
	ACH_JUMPED        = RegisterAchievement( "Players can't fly!", " Kill 50 enemies while they are in air", 50 );
	ACH_BOINK         = RegisterAchievement( "Run forest run!", "Walk 25000 meters.", 25000 );
	ACH_1HP_STAR     = RegisterAchievement( "1 HP Star", "Kill 1000 enemies on 1HP Map", 1000 );
	ACH_KNIFER        = RegisterAchievement( "Keep It Clean", "Kill 100 enemies", 100 );
	ACH_KNIFER_2      = RegisterAchievement( "Crazy Knifer", "Kill 255 enemies", 255 );
	ACH_HUMILIATE     = RegisterAchievement( "Enemie Humiliate", "Spray decal on the your killing person 100 times.", 100 ); 
	ACH_DISTANCE      = RegisterAchievement( "Longarm!", "Kill a enemie with 31-21m Stab 15 times", 15 );	
	ACH_DISTANCE_2TH  = RegisterAchievement( "Yes, Sensei!", "Kill a enemie with 31-21m Stab 100 times", 100 );	
	ACH_1HP_HERO      = RegisterAchievement( "1 HP Hero", "Kill enemy while having 1 HP", 1 );
	ACH_PYROMANCER    = RegisterAchievement( "Pyromancer", "Make 10,000 points of total damage", 10000 );
	ACH_PRO_KNIFER    = RegisterAchievement( "Pro Knifer", "Kill 5 enemys in one round with headshot.", 1 );
	ACH_SPENT         = RegisterAchievement( "Jesus", "Spent 100 enemys freehits", 100 );
	ACH_VANDALISM     = RegisterAchievement( "Vandalism", "Destroy 100 objects on map", 100 );
	ACH_LAMER         = RegisterAchievement( "Sneaky", " Kill 50 players while they dont see you", 50 );
	ACH_ADDICT        = RegisterAchievement( "Addict", "Join to server 500 times", 500 );
	ACH_PLAY_AROUND   = RegisterAchievement( "Play Around", "Spent 1 hour playing on server", 1 );
	ACH_DAY_MARATHON  = RegisterAchievement( "Day Marathon", "Spent 1 day playing on server", 1 );
	
	register_event( "DeathMsg", "EventDeathMsg", "a" );
	register_event( "HLTV", "EventRoundStart",  "a", "1=0", "2=0" );
	register_event( "23", "EventSpray", "a", "1=112" );
	register_event( "ClCorpse", "EventClCorpse", "a" );
	
	RegisterHam( Ham_TakeDamage, "player", "FwdHamPlayerDamagePre", false );
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawnPost", true );
	RegisterHam( Ham_TakeDamage, "func_breakable", "FwdBreakableThink", true );
	RegisterHam( Ham_TakeDamage, "func_pushable", "FwdBreakableThink", true );
	
	new szMap[ 32 ]; get_mapname( szMap, charsmax( szMap ) );
	g_b1HP = ( szMap[ 0 ] == '1' && szMap[ 1 ] == 'h' ) ? true : false;
	g_b100HP = ( szMap[ 0 ] == '1' && szMap[ 1 ] == '0' ) ? true : false;

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

public EventRoundStart( )
	arrayset( g_iHeadshotKills, 0, 33 );

public EventSpray( ) {
	new id = read_data( 2 );
	new Float:vOrigin[ 3 ], iPlayers[ 32 ], iNum, iPlayer;
	
	AchievementProgress( id, ACH_SPRAY );
	
	entity_get_vector( id, EV_VEC_origin, vOrigin );
	get_players( iPlayers, iNum, "b" );
	
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
	
	g_vDeathOrigin[ id ][ 0 ] /= 128;
	g_vDeathOrigin[ id ][ 1 ] /= 128;
	g_vDeathOrigin[ id ][ 2 ] /= 128;
}

public Knife_FreeHit( const id )
	AchievementProgress( id, ACH_SPENT );
	
public Knife_Distance( const id, Float:flDistance, bool:bSlashed )	
	if( !bSlashed && 31.00 < flDistance < 32.1 )
		AchievementProgress( id, !HaveAchievement( id, ACH_DISTANCE ) ? ACH_DISTANCE : ACH_DISTANCE_2TH );
	
public FwdBreakableThink( const iEntity, const iInflictor, const id )
	if( is_user_alive( id ) && entity_get_float( iEntity, EV_FL_health ) <= 0 )
		AchievementProgress( id, ACH_VANDALISM );
	
public FwdHamPlayerDamagePre( const id, const iInflictor, const iAttacker, Float:flDamage, iDamageBits ) {
	if( iDamageBits & DMG_FALL )
		return;
		
	if( get_user_team( iAttacker ) != get_user_team( id ) && is_user_alive( iAttacker ) )
		AchievementProgress( iAttacker, ACH_PYROMANCER, floatround( flDamage ) );
}
	

public EventDeathMsg( ) {
	new iKiller = read_data( 1 ), iVictim = read_data( 2 );
	new szWeapon[ 14 ]; read_data( 4, szWeapon, 13 );
        
        if( !equal( szWeapon, "knife" ) || iKiller == iVictim ) 
		return;
		
	entity_get_vector( iVictim, EV_VEC_origin, g_vDeathOrigin[ iVictim ]  );
	
	g_b1HP ? AchievementProgress( iKiller, ACH_1HP_STAR ) : AchievementProgress( iKiller, !HaveAchievement( iKiller, ACH_KNIFER ) ? ACH_KNIFER : ACH_KNIFER_2 );
	
	if( g_b100HP )
		AchievementProgress( iKiller, ACH_100HP );
	
	new bHeadshot = bool:read_data( 3 );
	
	g_iHeadshotKills[ iVictim ] = 0;
	
	if( bHeadshot && ++g_iHeadshotKills[ iKiller ] == 5 )
		AchievementProgress( iKiller, ACH_PRO_KNIFER );
	
	new Float:vOrigin[ 3 ];
	pev( iKiller, pev_origin, vOrigin );

	if( !is_in_viewcone( iVictim, vOrigin ) )
		AchievementProgress( iKiller, ACH_LAMER );

	if( !g_b1HP && pev( iKiller, pev_health ) == 1 )
		AchievementProgress( iKiller, ACH_1HP_HERO );
		
	if( IsUserInAir( iVictim ) )
			AchievementProgress( iKiller, ACH_JUMPED );
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
	
	new iDistance = floatround( UnitsToMeters( g_flDistance[ id ] ) );
	
	if( iDistance > 0 )
		AchievementProgress( id, ACH_BOINK, iDistance );
	
	ResetStats( id );
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

ResetStats( const id ) {
	g_flDistance[ id ] = 0.0;
	xs_vec_copy( g_vNullOrigin, g_vOldOrigin[ id ] );
}
