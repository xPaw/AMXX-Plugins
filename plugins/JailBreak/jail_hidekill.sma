#include < amxmodx >
#include < cstrike >

public plugin_init( ) {
	register_plugin( "Jail: Hide Kill", "1.0", "xPaw" );
	register_message( get_user_msgid( "DeathMsg" ), "MessageDeathMsg" );
}

public MessageDeathMsg( ) {
	new iKiller = get_msg_arg_int( 1 );
	
	if( is_user_alive( iKiller ) && cs_get_user_team( iKiller ) == CS_TEAM_T ) {
		set_msg_arg_int( 1, ARG_BYTE, 0 );
		set_msg_arg_int( 3, ARG_BYTE, 0 );
		set_msg_arg_string( 4, "worldspawn" );
	}
}
