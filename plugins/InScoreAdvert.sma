#include < amxmodx >
#include < fakemeta >

new const g_szAdvert[ ] = "You are playing on^nmY.RuN Server^n^nPlease visit^nwww.my-run.eu.com";

enum {
	TUTOR_RED = 1,	// FRIEND DIED
	TUTOR_BLUE,		// ENEMY DIED
	TUTOR_YELLOW,	// SCENARIO
	TUTOR_GREEN,	// BUY
};

new g_iOldButtons[ 33 ], g_iMsgTutorText, g_iMsgTutorClose;

public plugin_init( ) {
	register_plugin( "Advert @ Scoreboard", "1.0", "xPaw" );
	
	register_forward( FM_CmdStart, "FwdCmdStart" );
	
	register_event( "DeathMsg", "EventDeath", "a", "2>0" );
	
	g_iMsgTutorText  = get_user_msgid( "TutorText" );
	g_iMsgTutorClose = get_user_msgid( "TutorClose" );
}

public plugin_precache( ) {
	new const szTutorPrecache[ ][ ] = {
		"gfx/career/icon_!.tga",
		"gfx/career/icon_!-bigger.tga",
		"gfx/career/icon_i.tga",
		"gfx/career/icon_i-bigger.tga",
		"gfx/career/icon_skulls.tga",
		"gfx/career/round_corner_ne.tga",
		"gfx/career/round_corner_nw.tga",
		"gfx/career/round_corner_se.tga",
		"gfx/career/round_corner_sw.tga",
		"resource/TutorScheme.res",
		"resource/UI/TutorTextWindow.res"
	};
	
	for( new i; i < sizeof szTutorPrecache; i++ )
		precache_generic( szTutorPrecache[ i ] );
}

public EventDeath( )
	CloseTutor( read_data( 2 ) );

public FwdCmdStart( id, UcHandle, Seed ) {
	if( !is_user_alive( id ) )
		return FMRES_IGNORED;
	
	static iButtons;
	iButtons = get_uc( UcHandle, UC_Buttons );
	
	if( iButtons & IN_SCORE && !( g_iOldButtons[ id ] & IN_SCORE ) )
		MakeTutor( id, g_szAdvert, TUTOR_BLUE );
	else if( !( iButtons & IN_SCORE ) && g_iOldButtons[ id ] & IN_SCORE )
		CloseTutor( id );
	
	g_iOldButtons[ id ] = iButtons;
	
	return FMRES_IGNORED;
}

CloseTutor( const id ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgTutorClose, _, id );
	message_end( );
}

MakeTutor( const id, const szText[ ], const iColor ) {
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgTutorText, _, id );
	write_string( szText );
	write_byte( 0 );
	write_short( 0 );
	write_short( 0 );
	write_short( 1<<iColor );
	message_end( );
}