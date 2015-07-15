#include < amxmodx >
#include < fun >
#include < LastRequest >
#include < cstrike >
#include < hamsandwich >

new g_iLrGuy, g_iLrVictim;
new bool:g_bNade;

public plugin_init( ) {
	register_plugin( "[LR] NadeBattle", "1.0", "master4life" );
	
	Lr_RegisterGame( "Nade Battle", "FwdGameBattle", true );
	
	RegisterHam( Ham_Touch, "weaponbox", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Touch, "armoury_entity", "FwdHamPickupWeaponPre", false );
	RegisterHam( Ham_Use,   "game_player_equip", "FwdHamPickupWeaponPre", false );
	
	register_event( "CurWeapon",   "EventCurWeapon",   "be", "1=1" );
	register_event( "TextMsg", "MsgTextMsg", "b", "3&#Game_radio", "5&#Fire_in_the_hole" );
	
	register_message( get_user_msgid( "SendAudio" ), "Message_SendAudio" );
}

public FwdHamPickupWeaponPre( const iWeapon, const id )
	return g_bNade ? HAM_SUPERCEDE : HAM_IGNORED;

public Lr_GameFinished( const id, const bool:bDidTerroristWin ) {
	g_bNade = false;
	g_iLrVictim = 0;
	g_iLrGuy = 0;
}

public FwdGameBattle( const id, const iVictim ) {
	Lr_RestoreHealth( id );

	g_bNade = true;
	g_iLrGuy = id;
	
	//strip_user_weapons( id );
	give_item( id, "weapon_hegrenade" );
	engclient_cmd( id, "weapon_hegrenade" );
	
	if( iVictim ) {
		Lr_RestoreHealth( iVictim );
		
		//strip_user_weapons( iVictim );
		give_item( iVictim, "weapon_hegrenade" );
		engclient_cmd( iVictim, "weapon_hegrenade" );
		
		g_iLrVictim = iVictim;
	}
}

public EventCurWeapon( const id ) {
	if( g_bNade ) {
		new iWeapon = read_data( 2 );
		
		if( iWeapon != CSW_HEGRENADE )
			engclient_cmd( id, "weapon_hegrenade" );
	}
}

public Message_SendAudio( const iMsgID, const iMsgDest, const iEntity ) {
	if( !g_bNade )
		return PLUGIN_CONTINUE;

	new szString[ 18 ];
	get_msg_arg_string( 2, szString, charsmax( szString ) );
	
	return equal( szString, "%!MRAD_FIREINHOLE" ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public MsgTextMsg( const id ) {
	if( !g_bNade )
		return;
	
	set_task( 1.0, "ThrowHeEvent", id );
}

public ThrowHeEvent( const id ) {
	if( !g_bNade )
		return;
	if( g_iLrVictim == id  || g_iLrGuy == id ) {
		give_item( id, "weapon_hegrenade" );
		cs_set_user_bpammo( id, CSW_HEGRENADE, 1 );
	}
}
