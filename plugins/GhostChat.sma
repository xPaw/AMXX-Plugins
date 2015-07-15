#include < amxmodx >

new g_iMsgSayText;

public plugin_init( )
{
	register_plugin( "Ghost Chat", "1.0", "xPaw" );
	
	g_iMsgSayText = get_user_msgid( "SayText" );
	
	register_event( "SayText", "EventSayText", "b", "2&#Cstrike_Chat_All" );
}

public EventSayText( const id )
{
	if( id != read_data( 1 ) )
	{
		return;
	}
	
	new szChannel[ 22 ], iPlayers[ 32 ], iNum;
	read_data( 2, szChannel, 21 );
	
	get_players( iPlayers, iNum, szChannel[ 17 ] ? "ach" : "bch" );
	
	if( !iNum )
	{
		return;
	}
	
	new szMessage[ 192 ];
	read_data( 4, szMessage, 191 );
	
	for( new i; i < iNum; i++ )
	{
		message_begin( MSG_ONE_UNRELIABLE, g_iMsgSayText, _, iPlayers[ i ] );
		write_byte( id );
		write_string( szChannel );
		write_string( "" );
		write_string( szMessage );
		message_end( );
	}
}
