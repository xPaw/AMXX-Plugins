#include < amxmodx >
#include < cstrike >

#pragma library csdm

forward csdm_PostDeath( killer, victim, headshot, const weapon[] );
forward csdm_PostSpawn( player, bool:fake );

new bool:g_bConnected[ 33 ];
new bool:g_bImmunity[ 33 ];
new CsTeams:g_iNewTeam[ 33 ];

new g_pCvar;
new g_iMaxClients;
new g_iMsgSayText;
new g_iMsgScreenFade;
new g_iPlayers;

public plugin_init( )
{
	register_plugin( "CSDM Auto Balance", "1.0", "xPaw" );
	
	/*
		csdm_auto_balance
			0: Disabled
			1: Enabled
			2: Enabled, obey immunity
	*/
	
	g_pCvar = register_cvar( "csdm_auto_balance", "1" );
	
	g_iMsgScreenFade = get_user_msgid( "ScreenFade" );
	g_iMsgSayText    = get_user_msgid( "SayText" );
	g_iMaxClients    = get_maxplayers( );
}

public client_authorized( id )
{
	g_bImmunity[ id ] = bool:( get_user_flags( id ) & ADMIN_IMMUNITY );
}

public client_putinserver( id )
{
	g_bConnected[ id ] = true; // bool:!is_user_bot( id );
	g_iPlayers++;
}

public client_disconnect( id )
{
	g_iNewTeam[ id ]   = CS_TEAM_UNASSIGNED;
	g_bImmunity[ id ]  = false;
	g_bConnected[ id ] = false;
	g_iPlayers--;
}

public csdm_PostDeath( iKiller, id, bHeadShot, const szWeapon[ ] )
{
	if( g_iPlayers < 4 || iKiller == id || !g_bConnected[ id ] )
	{
		return;
	}
	
	new iCvar = get_pcvar_num( g_pCvar );
	
	if( !iCvar || ( iCvar == 2 && g_bImmunity[ id ] ) )
	{
		return;
	}
	
	new iTerrorists, iCT;
	
	for( new i = 1; i <= g_iMaxClients; i++ )
	{
		if( !g_bConnected[ i ] )
		{
			continue;
		}
		
		switch( cs_get_user_team( i ) )
		{
			case CS_TEAM_T : iTerrorists++;
			case CS_TEAM_CT: iCT++;
		}
	}
	
	new iDifference = iTerrorists - iCT;
	
	if( iDifference && abs( iDifference ) > 1 )
	{
		g_iNewTeam[ id ] = iDifference > 0 ? CS_TEAM_T : CS_TEAM_CT;
	}
}

public csdm_PostSpawn( id, bool:bFake )
{
	new CsTeams:iNewTeam = g_iNewTeam[ id ];
	
	if( iNewTeam != CS_TEAM_UNASSIGNED )
	{
		cs_set_user_team( id, iNewTeam );
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		UTIL_GreenPrintAll( id, "^4[CSDM]^3 %s^1 has been transfered to^3 %s^1.", szName,
			iNewTeam == CS_TEAM_T ? "Terrorists" : "Counter-Terrorists" );
		
		UTIL_ScreenFade( id, iNewTeam == CS_TEAM_T ? 175 : 0, 0, iNewTeam == CS_TEAM_CT ? 175 : 0 );
		
		set_hudmessage( 0, 127, 255, 0.42, 0.53, 2, 6.0, 4.0, 0.1, 0.2, -1 );
		show_hudmessage( id, "You have been transfered to %s!", iNewTeam == CS_TEAM_T ? "Terrorists" : "Counter-Terrorists" );
		
		g_iNewTeam[ id ] = CS_TEAM_UNASSIGNED;
	}
}

UTIL_GreenPrintAll( const iSender, const Message[ ], any:... )
{
	new szMessage[ 192 ];
	vformat( szMessage, 191, Message, 3 );
	
	message_begin( MSG_BROADCAST, g_iMsgSayText );
	write_byte( iSender );
	write_string( szMessage );
	message_end( );
}

UTIL_ScreenFade( const id, const iRed, const iGreen, const iBlue )
{
	message_begin( MSG_ONE_UNRELIABLE, g_iMsgScreenFade, _, id );
	write_short( 2000 );
	write_short( 2000 );
	write_short( 0 );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( 175 );
	message_end( );
}
