#include < amxmodx >
#include < fakemeta >

#define RADIO_DELAY 5.0

#define m_flNextRadioGameTime 191

new g_iMsgSendAudio;
new g_iSendAudioEvent;
new Float:g_flRoundStartGameTime;

public plugin_init( )
{
	register_plugin( "No Radio Flood", "1.0", "xPaw" );
	
	register_event( "SendAudio", "EventSendAudio", "b", "2&%!MRAD_" );
	
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	
	g_iMsgSendAudio = get_user_msgid( "SendAudio" );
}

public EventSendAudio( const id )
{
	if( id != read_data( 1 ) )
	{
		return;
	}
	
	new Float:flGameTime = get_gametime( );
	
	if( flGameTime != g_flRoundStartGameTime )
	{
		set_pdata_float( id, m_flNextRadioGameTime, flGameTime + RADIO_DELAY );
	}
}

public EventRoundStart( )
{
	g_flRoundStartGameTime = get_gametime( );
	
	if( !g_iSendAudioEvent )
	{
		g_iSendAudioEvent = register_message( g_iMsgSendAudio, "MessageSendAudio" );
	}
}

public MessageSendAudio( )
{
	if( g_flRoundStartGameTime != get_gametime( ) )
	{
		unregister_message( g_iMsgSendAudio, g_iSendAudioEvent );
		
		g_iSendAudioEvent = 0;
		
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}
