#include < amxmodx >
#include < achievements >
#include < fun >
#include < LastRequest >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >

new g_iGameId, g_iLrGuy, g_hMenu, ACH_KNIFER, ACH_LR_KNIFE;
new bool:g_bKnifeBattle, bool:g_bToggle, bool:g_bToggle2;
new HamHook:NoDamage;
new HamHook:NoSlash;

public plugin_init( ) {
	register_plugin( "[LR] Knife Battle", "1.0", "master4life" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be", "2!29" );
	register_event( "DeathMsg", "EventPlayerDeath", "a" );
	
	RegisterHam( Ham_Touch, "weaponbox", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Touch, "armoury_entity", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Use,   "game_player_equip", "FwdHamPickupWeaponPre", false );
	
	NoDamage	= RegisterHam( Ham_TraceAttack, "player", "HamTraceAttack", false );
	NoSlash 	= RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_knife", "FwdHamKnifePrimaryAttack" );
	
	DisableHamForward( NoDamage );
	DisableHamForward( NoSlash );
	
	g_iGameId 	= Lr_RegisterGame( "Knife Battle", "FwdGameBattle", true );
	ACH_KNIFER	= RegisterAchievement( "Shiny knife", "Start 50 knife duels", 50 );
	ACH_LR_KNIFE	= RegisterAchievement( "Pro Assassin", "Win 100 knife battles", 100 );
	
	Lr_WaitForMe( g_iGameId );
}

public EventPlayerDeath( ) {
	new iKiller = read_data( 1 ), iVictim = read_data( 2 );
	
	if( iKiller != iVictim && iKiller == g_iLrGuy && is_user_alive( iKiller ) )
		AchievementProgress( iKiller, ACH_LR_KNIFE );
}

public FwdHamPickupWeaponPre( const iWeapon, const id )
	return g_bKnifeBattle ? HAM_SUPERCEDE : HAM_IGNORED;

public EventCurWeapon( id )
	if( g_bKnifeBattle )
		engclient_cmd( id, "weapon_knife" );

public Lr_GameSelected( const id, const iGameId ) {
	if( iGameId == g_iGameId ) {
		AchievementProgress( id, ACH_KNIFER );
		HandleKnifeMenu( id );
	}
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	DisableHamForward( NoDamage );
	DisableHamForward( NoSlash );
	
	g_bKnifeBattle = false;
	g_bToggle2 = false;	
	g_bToggle = false;
	g_iLrGuy = 0;
	
	if( g_hMenu > 0 ) {
		menu_destroy( g_hMenu );
		g_hMenu = 0;
	}
}

public FwdGameBattle( const id, const iVictim ) {
	g_bKnifeBattle = true;
	g_iLrGuy = id;
	
	Lr_RestoreHealth( id );	
	give_item( id, "weapon_knife" );
	engclient_cmd( id, "weapon_knife" );
	
	if( iVictim ) {
		Lr_RestoreHealth( iVictim );
		give_item( iVictim, "weapon_knife" );
		engclient_cmd( iVictim, "weapon_knife" );
		
		if( g_bToggle2 ) {
			set_user_health( id, 1 );
			set_user_health( iVictim, 1 );
		} else {
			set_user_health( id, 100 );
			set_user_health( iVictim, 100 );
		}
	}
}

public HandleKnifeMenu( id ) {
	g_hMenu = menu_create( "Choose the options", "HandleStart" );
	menu_additem( g_hMenu, "Normal", "0" );
	menu_additem( g_hMenu, "Headshot Only", "1" );
	
	new szTemp[ 32 ];
	formatex( szTemp, charsmax( szTemp ), "Health [\d %shp\w ]", ( g_bToggle2 ? "1" : "100" ) );
	menu_additem( g_hMenu, szTemp, "2" );
	
	formatex( szTemp, charsmax( szTemp ), "Knife Mode [\d %sSlash\w ]", ( g_bToggle ? "No " : "" ) );
	menu_additem( g_hMenu, szTemp, "3" );
	
	menu_display( id, g_hMenu, 0 );
}

public HandleStart( const id, menu, item ) {
	if( item == MENU_EXIT || !is_user_alive( id ) ) {
		menu_destroy( menu );
		g_hMenu = 0;
		return;
	}
	
	new szKey[ 2 ], Trash, iKey;
	menu_item_getinfo( menu, item, Trash, szKey, 1, _, _, Trash );
	menu_destroy( menu );
	
	g_hMenu = 0;
	iKey = str_to_num( szKey );
	
	if( iKey == 0 || iKey == 1 ) {
		new szMessage[ 96 ];
		formatex( szMessage, charsmax( szMessage ), "Knife Rules:^n%s^n%s^nHealth: %s^n"
		, iKey == 0 ? "Normal" : "Headshot Only", g_bToggle ? "Only Stab" : "Slash allowed",  g_bToggle2 ? "1" : "100" );
		ColorChat( 0, Red, "[ mY.RuN ]^1 Knife Rules:^4 %s^1 -^4 %s - Health: %s"
		,iKey == 0 ? "Normal" : "Headshot Only", g_bToggle ? "Only Stab" : "Slash allowed",  g_bToggle2 ? "1" : "100" );
			
		UTIL_DirectorMessage(
			.index       = 0, 
			.message     = szMessage,
			.red         = 90,
			.green       = 30,
			.blue        = 0,
			.x           = 0.77,
			.y           = 0.17,
			.effect      = 0,
			.fxTime      = 5.0,
			.holdTime    = 5.0,
			.fadeInTime  = 0.5,
			.fadeOutTime = 0.3
		);
	}
	
	switch( iKey ) {
		case 0: {
			Lr_MoveAlong( );
			
		}
		case 1: {
			Lr_MoveAlong( );
			
			EnableHamForward( NoDamage );
		}
		case 2: {
			g_bToggle2 = !g_bToggle2;
			
			HandleKnifeMenu( id );
		}
		case 3: {
			g_bToggle = !g_bToggle;
			
			if( g_bToggle )
				EnableHamForward( NoSlash );
			else 
				DisableHamForward( NoSlash );
			
			HandleKnifeMenu( id );
		}
	}
}

public HamTraceAttack( const iVict, const iKiller, Float:dmg, Float:dir[3], traceresult, dmgbits )
	return( get_tr2( traceresult, TR_iHitgroup ) != HIT_HEAD ) ?
		HAM_SUPERCEDE : HAM_IGNORED;
		
public FwdHamKnifePrimaryAttack( iKnife ) {
	ExecuteHam( Ham_Weapon_SecondaryAttack, iKnife );
	
	return HAM_SUPERCEDE;
}

stock UTIL_DirectorMessage( const index, const message[], const red = 0, const green = 160, const blue = 0, 
					  const Float:x = -1.0, const Float:y = 0.65, const effect = 2, const Float:fxTime = 6.0, 
					  const Float:holdTime = 3.0, const Float:fadeInTime = 0.1, const Float:fadeOutTime = 1.5 )
{
	#define pack_color(%0,%1,%2) ( %2 + ( %1 << 8 ) + ( %0 << 16 ) )
	#define write_float(%0) write_long( _:%0 )
	
	message_begin( index ? MSG_ONE : MSG_BROADCAST, SVC_DIRECTOR, .player = index );
	{
		write_byte( strlen( message ) + 31 ); // size of write_*
		write_byte( DRC_CMD_MESSAGE );
		write_byte( effect );
		write_long( pack_color( red, green, blue ) );
		write_float( x );
		write_float( y );
		write_float( fadeInTime );
		write_float( fadeOutTime );
		write_float( holdTime );
		write_float( fxTime );
		write_string( message );
	}
	message_end( );
}
