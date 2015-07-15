#include < amxmodx >
#include < hamsandwich >
#include < chatcolor >

#define FFADE_IN  0x0000
#define FFADE_OUT 0x0001 | 0x0004

new g_iRounds;
new g_iHudSync;
new g_iMsgScreenFade;
new g_szMessage[ 128 ];
new bool:g_bIgnore;

public plugin_init( )
{
	register_plugin( "Jail: Days info", "1.2", "xPaw" );	
	
	register_event( "TextMsg", "EventRoundRestart", "a", "2&#Game_C", "2&#Game_w" );
	
	register_message( get_user_msgid( "ScreenFade" ), "MessageScreenFade" );
	
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", true );
	
	g_iHudSync       = CreateHudSyncObj( );
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
}

public EventRoundEnd( )
{
	g_bIgnore = true;
	
	UTIL_ScreenFade( 0, false );
}

public EventRoundRestart( )
{
	g_bIgnore = true;
	g_iRounds = 0;
	
	UTIL_ScreenFade( 0, false );
}

public EventRoundStart( )
{
	g_bIgnore = false;
	g_iRounds++;
	
	new iTimeLeft = get_timeleft( );
	
	if( iTimeLeft > 0 )
	{
		formatex( g_szMessage, charsmax( g_szMessage ), "[ Day %i ]^n[ Timeleft %d:%02d ]", g_iRounds, iTimeLeft / 60, iTimeLeft % 60 );
	}
	else
	{
		formatex( g_szMessage, charsmax( g_szMessage ), "[ Day %i ]^n[ Last Round ]", g_iRounds );
	}
}

public FwdHamPlayerSpawn( id )
{
	set_task( 0.2, "TaskFade", id );
}

public TaskFade( const id )
{
	if( is_user_alive( id ) )
	{
		UTIL_ScreenFade( id, true );
		
		set_hudmessage( 128, 128, 128, -1.0, 0.7, 0, 3.2, 3.2, 0.2, 1.0, -1 );
		ShowSyncHudMsg( id, g_iHudSync, g_szMessage );
	}
}

public MessageScreenFade( )
{
	return g_bIgnore ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

UTIL_ScreenFade( const id, const bool:bRoundStart )
{
	new iTime = bRoundStart ? ( 3 << 12 ) : ( 2 << 12 )
	
	if( bRoundStart && get_user_team( id ) == 2 )
	{
		iTime = ( 1 << 12 );
	}
	
	message_begin( id ? MSG_ONE : MSG_BROADCAST, g_iMsgScreenFade, _, id );
	write_short( iTime );
	write_short( iTime );
	write_short( bRoundStart ? FFADE_IN : FFADE_OUT );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 255 );
	message_end( );
}
