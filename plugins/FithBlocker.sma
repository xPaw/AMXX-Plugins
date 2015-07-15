#include < amxmodx >

enum _:CvarBits (<<=1) {
	BLOCK_RADIO = 1,
	BLOCK_MSG
};

new g_pCvar;

public plugin_init( ) {
	register_plugin( "'Fire in the hole' blocker", "1.0", "xPaw" );
	
	g_pCvar = register_cvar( "sv_fith_block", "3" );
	
	register_message( get_user_msgid( "TextMsg" ),   "MessageTextMsg" );
	register_message( get_user_msgid( "SendAudio" ), "MessageSendAudio" );
}

public MessageTextMsg( )
	return ( get_msg_args( ) == 5 && IsBlocked( BLOCK_MSG ) ) ? GetReturnValue( 5, "#Fire_in_the_hole" ) : PLUGIN_CONTINUE;

public MessageSendAudio( )
	return IsBlocked( BLOCK_RADIO ) ? GetReturnValue( 2, "%!MRAD_FIREINHOLE" ) : PLUGIN_CONTINUE;

GetReturnValue( const iParam, const szString[ ] ) {
	new szTemp[ 18 ];
	get_msg_arg_string( iParam, szTemp, 17 );
	
	return ( equal( szTemp, szString ) ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

bool:IsBlocked( const iType ) {
	new iCvar = get_pcvar_num( g_pCvar );
	
	return bool:( iCvar & iType );
}
