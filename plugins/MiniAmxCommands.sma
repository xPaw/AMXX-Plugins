#include < amxmodx >
#include < amxmisc >
#include < engine >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < chatcolor >

#define DAMAGE_SHOWER // Uncomment to enable 'Damage Shower'

#define EXTEND_MAX  9
#define EXTEND_TIME 15

/*
	COMMAND									STATUS		@all	@team 	CON MSG

	amx_revive <nick>						DONE		DONE	-		DONE
	amx_heal <nick> <hp>					DONE		DONE	-		DONE
	amx_sethp <nick> <hp>					DONE		DONE	-		DONE
	amx_exec <nick> <cmd>					DONE		DONE	-		DONE
	amx_noclip <nick> <0/1/on/off>			DONE		DONE	-		DONE
	amx_godmode <nick> <0/1/on/off>			DONE		DONE	-		DONE
	amx_money <nick> <amount>				DONE		DONE	-		DONE
	amx_teleport <x> <y> <z>				DONE		NO		-		DONE
	amx_extend <minutes>					DONE		NO		-		DONE
	amx_team <nick> <team>					DONE		-		-		DONE
	amx_glow <nick> <color>					DONE		DONE	-		DONE
	
	amx_goto <nick>							-			NO		-		-
	amx_frags <nick> <frags>				-			-		-		-
*/

#if defined DAMAGE_SHOWER
	new g_iHudSync1, g_iHudSync2;
#endif

new g_iExtends;
new g_pTimeLimit;

SetRendering(entity, Float:RenderColor[3], fx = kRenderFxNone) {
	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, kRenderNormal);
	set_pev(entity, pev_renderamt, 16.0);
}

public plugin_init( ) {
	register_plugin( "AMXX Commands", "1.0", "xPaw" );
	
	register_dictionary( "common.txt" );
	
	register_concmd( "amx_godmode",        "CmdGodmode",    ADMIN_RCON,    "<nick> <0/1>" );
	register_concmd( "amx_noclip",         "CmdNoclip",     ADMIN_RCON,    "<nick> <0/1>" );
	register_concmd( "amx_money",          "CmdMoney",      ADMIN_RCON,    "<nick> <amount>" );
	register_concmd( "amx_extend",         "CmdExtend",     ADMIN_RCON,    "<added time to extend>" );
	register_concmd( "amx_heal",           "CmdHeal",       ADMIN_RCON,    "<nick> <amount>" );
	register_concmd( "amx_sethp",          "CmdSetHp",      ADMIN_RCON,    "<nick> <amount>" );
	register_concmd( "amx_exec",           "CmdExec",       ADMIN_RCON,    "<nick> <command>" );
	register_concmd( "amx_teleport",       "CmdTeleport",   ADMIN_RCON,    "<x> <y> <z>" );
	
	register_concmd( "amx_team",           "CmdTransfer",   ADMIN_KICK,    "<nick> <newteam>" );
	register_concmd( "amx_revive",         "CmdRevive",     ADMIN_KICK,    "<nick>" );
	register_concmd( "amx_glow",           "CmdGlow",       ADMIN_KICK,    "<nick> <g/r/b/o/c/m/y/w>" );
	
	register_clcmd( "fullupdate",          "CmdFullUpdate" );
	//register_clcmd( "say /admin",         "CmdOnlineAdmins" );
	//register_clcmd( "say /admins",        "CmdOnlineAdmins" );
	
	//register_clcmd( "say /revive",        "CmdRespawn" );
	//register_clcmd( "say /respawn",       "CmdRespawn" );
	
#if defined DAMAGE_SHOWER
	register_event( "Damage", "EventDamage", "b", "2!0", "3=0", "4!0" );
	
	g_iHudSync1 = CreateHudSyncObj( );
	g_iHudSync2 = CreateHudSyncObj( );
#endif
}

//public CmdRespawn( const id )
//	if( !is_user_alive( id ) && cs_get_user_team( id ) == CS_TEAM_CT )
//		ExecuteHamB( Ham_CS_RoundRespawn, id );

public CmdGodmode( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ], bool:bGodmode;
	read_argv( 2, szArg, 3 );
	
	if( szArg[ 0 ] == '1' || szArg[ 1 ] == 'n' || szArg[ 1 ] == 'N' )
		bGodmode = true;
	else if( szArg[ 0 ] == '0' || szArg[ 1 ] == 'f' || szArg[ 1 ] == 'F' )
		bGodmode = false;
	else {
		console_print( id, "* The value can be only 0/1 or off/on." );
		
		return PLUGIN_HANDLED;
	}
	
	read_argv( 1, szArg, 31 );
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ )
			set_pev( iPlayers[ i ], pev_takedamage, bGodmode ? DAMAGE_NO : DAMAGE_AIM );
		
		ShowActivity( id, szAdmin, "%s everyone.", bGodmode ? "Set godmode on" : "Removed godmode from" );
		
		console_print( id, "* You %s everyone.", bGodmode ? "set godmode on" : "removed godmode from" );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		set_pev( iPlayer, pev_takedamage, bGodmode ? DAMAGE_NO : DAMAGE_AIM );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "%s^4 %s^1.", bGodmode ? "Set godmode on" : "Removed godmode from", szName );
		
		console_print( id, "* You %s %s.", bGodmode ? "set godmode on" : "removed godmode from", szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdNoclip( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ], bool:bNoclip;
	read_argv( 2, szArg, 3 );
	
	if( szArg[ 0 ] == '1' || szArg[ 1 ] == 'n' || szArg[ 1 ] == 'N' )
		bNoclip = true;
	else if( szArg[ 0 ] == '0' || szArg[ 1 ] == 'f' || szArg[ 1 ] == 'F' )
		bNoclip = false;
	else {
		console_print( id, "* The value can be only 0/1 or off/on." );
		
		return PLUGIN_HANDLED;
	}
	
	read_argv( 1, szArg, 31 );
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ )
			set_pev( iPlayers[ i ], pev_movetype, bNoclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK );
		
		ShowActivity( id, szAdmin, "%s everyone.", bNoclip ? "Set noclip on" : "Removed noclip from" );
		
		console_print( id, "* You %s everyone.", bNoclip ? "set noclip on" : "removed noclip from" );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		set_pev( iPlayer, pev_movetype, bNoclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "%s^4 %s^1.", bNoclip ? "Set noclip on" : "Removed noclip from", szName );
		
		console_print( id, "* You %s %s.", bNoclip ? "set noclip on" : "removed noclip from", szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdMoney( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ];
	read_argv( 2, szArg, 5 );
	
	new iAmount = str_to_num( szArg );
	
	if( iAmount <= 0 ) {
		console_print( id, "The money amount must be greater than 0!" );
		
		return PLUGIN_HANDLED;
	}
	else if( iAmount > 16000 ) {
		console_print( id, "The money amount must be lower than 16000!" );
		
		return PLUGIN_HANDLED;
	}
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	read_argv( 1, szArg, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ch" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ )
			cs_set_user_money( iPlayers[ i ], clamp( ( cs_get_user_money( iPlayers[ i ] ) + iAmount ), 0, 16000 ) );
		
		ShowActivity( id, szAdmin, "Gave^4 %i$^1 to all players.", iAmount );
		
		console_print( id, "* You gave %i$ to all players.", iAmount );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF | CMDTARGET_NO_BOTS );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		cs_set_user_money( iPlayer, clamp( ( cs_get_user_money( iPlayer ) + iAmount ), 0, 16000 ) );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "Gave^4 %i$^1 to^4 %s^1.", iAmount, szName );
		
		console_print( id, "* You gave %i$ to %s.", iAmount, szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdTransfer( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) ) {
		console_print( id, "* New team can be: T, CT or SPEC." );
		
		return PLUGIN_HANDLED;
	}
	
	new szArg[ 32 ];
	read_argv( 1, szArg, 31 );
	
	new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
	
	if( !iPlayer )
		return PLUGIN_HANDLED;
	
	new szTeamName[ 32 ];
	
	read_argv( 2, szArg, 31 );
	
	switch( szArg[ 0 ] ) {
		case 'T', 't': {
			cs_set_user_team( iPlayer, CS_TEAM_T );
			
			if( is_user_alive( iPlayer ) )
				ExecuteHamB( Ham_CS_RoundRespawn, iPlayer );
			
			szTeamName = "Terrorists";
		}
		case 'C', 'c': {
			cs_set_user_team( iPlayer, CS_TEAM_CT );
			
			if( is_user_alive( iPlayer ) )
				ExecuteHamB( Ham_CS_RoundRespawn, iPlayer );
			
			szTeamName = "Counter-Terrorists";
		}
		case 'S', 's': {
			user_silentkill( iPlayer );
			
			cs_set_user_team( iPlayer, CS_TEAM_SPECTATOR );
			
			szTeamName = "Spectators";
		}
		default: {
			console_print( id, "* Invalid team specified! Valid teams are: T, CT or SPEC." );
			
			return PLUGIN_HANDLED;
		}
	}
	
	new szAdmin[ 32 ], szName[ 32 ];
	get_user_name( id, szAdmin, 31 );
	get_user_name( iPlayer, szName, 31 );
	
	ShowActivity( id, szAdmin, "Transfered^4 %s^1 to^4 %s^1.", szName, szTeamName );
	
	console_print( id, "* You have transfered %s to %s.", szName, szTeamName );
	
	return PLUGIN_HANDLED;
}

public CmdExtend( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 5 ];
	read_argv( 1, szArg, 4 );
	
	if( g_iExtends > EXTEND_MAX ) {
		console_print( id, "* No user may extend any map more than %i times.", EXTEND_MAX );
		
		return PLUGIN_HANDLED;
	}
	else if( !is_str_num( szArg ) ) {
		console_print( id, "* The value must be in minutes (digits only)." );
		
		return PLUGIN_HANDLED;
	}
	
	new iTime = abs( str_to_num( szArg ) );
	
	if( iTime > EXTEND_TIME ) {
		console_print( id, "* No map may be extended longer than %i minutes at a time.", EXTEND_TIME );
		
		iTime = EXTEND_TIME;
	}
	
	if( !g_pTimeLimit )
		g_pTimeLimit = get_cvar_pointer( "mp_timelimit" );
	
	set_pcvar_float( g_pTimeLimit, get_pcvar_float( g_pTimeLimit ) + iTime );
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	
	ShowActivity( id, szAdmin, "Extended the map time by^4 %i^1 minutes.", iTime );
	
	console_print( id, "* You have extended the map time by %i minutes.", iTime );
	
	g_iExtends++;
	
	return PLUGIN_HANDLED;
}

public CmdGlow( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ], szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	
	new Float:flColors[ 3 ], bool:bReset = false;
	read_argv( 2, szArg, 2 );
	
	switch( szArg[ 0 ] )
	{
		case 'g': flColors = Float:{ 0.0, 255.0, 0.0 };
		case 'r': flColors = Float:{ 255.0, 0.0, 0.0 };
		case 'b': flColors = Float:{ 0.0, 0.0, 255.0 };
		case 'o': flColors = Float:{ 227.0, 96.0, 8.0 };
		case 'c': flColors = Float:{ 0.0, 255.0, 255.0 };
		case 'm': flColors = Float:{ 255.0, 0.0, 255.0 };
		case 'y': flColors = Float:{ 255.0, 255.0, 0.0 };
		case 'w': flColors = Float:{ 255.0, 255.0, 255.0 };
		default: bReset = true;
	}
	
	read_argv( 1, szArg, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "a" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ ) {
			if( bReset )
				SetRendering( iPlayers[ i ], Float:{255.0, 255.0, 255.0} );
			else
				SetRendering( iPlayers[ i ], flColors, kRenderFxGlowShell );
		}
		
		ShowActivity( id, szAdmin, bReset ? "Reset glow on all players." : "Set glow on all players." );
		
		console_print( id, "* You have set glow on all players." );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		if( !is_user_alive( iPlayer ) ) {
			console_print( id, "* User is not alive!" );
			
			return PLUGIN_HANDLED;
		}
		
		if( bReset )
			SetRendering( iPlayer, Float:{255.0, 255.0, 255.0} );
		else
			SetRendering( iPlayer, flColors, kRenderFxGlowShell );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, bReset ? "Reset glow on^4 %s^1." : "Set glow on^4 %s^1.", szName );
		
		console_print( id, "* You have set glow on %s.", szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdRevive( id, level, cid ) {
	if( !cmd_access( id, level, cid, 2 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ], szAdmin[ 32 ];
	read_argv( 1, szArg, 31 );
	get_user_name( id, szAdmin, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "bch" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		new CsTeams:iTeam;
		
		for( new i; i < iNum; i++ ) {
			iTeam = cs_get_user_team( iPlayers[ i ] );
			
			if( iTeam == CS_TEAM_T || iTeam == CS_TEAM_CT )
				ExecuteHamB( Ham_CS_RoundRespawn, iPlayers[ i ] );
		}
		
		ShowActivity( id, szAdmin, "Revived all players." );
		
		console_print( id, "* You have revived all players." );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ALLOW_SELF );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		if( is_user_alive( iPlayer ) ) {
			console_print( id, "* User is already alive!" );
			
			return PLUGIN_HANDLED;
		}
		
		ExecuteHamB( Ham_CS_RoundRespawn, iPlayer );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "Revived^4 %s^1.", szName );
		
		console_print( id, "* You have revived %s.", szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdHeal( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ];
	read_argv( 2, szArg, 5 );
	
	new iAmount = str_to_num( szArg );
	
	if( iAmount <= 0 ) {
		console_print( id, "The hp amount must be greater than 0!" );
		
		return PLUGIN_HANDLED;
	}
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	read_argv( 1, szArg, 31 );
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ )
			set_pev( iPlayers[ i ], pev_health, float( iAmount ) + pev( iPlayers[ i ], pev_health ) );
		
		ShowActivity( id, szAdmin, "Gave^4 %i^1 health to all players.", iAmount );
		
		console_print( id, "* You gave %i health to all players.", iAmount );
	} else {
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		set_pev( iPlayer, pev_health, float( iAmount ) + pev( iPlayer, pev_health ) );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "Gave^4 %i^1 health to^4 %s^1.", iAmount, szName );
		
		console_print( id, "* You gave %i health to %s.", iAmount, szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdSetHp( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ];
	read_argv( 2, szArg, 5 );
	
	new iAmount = str_to_num( szArg );
	
	if( iAmount <= 0 ) {
		console_print( id, "The hp amount must be greater than 0!" );
		
		return PLUGIN_HANDLED;
	}
	
	new szAdmin[ 32 ];
	get_user_name( id, szAdmin, 31 );
	read_argv( 1, szArg, 31 );
	
	if( szArg[ 0 ] == '@' )
	{
		// This will suck if player's name begins with "@"
		
		new i, iPlayer, iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		
		// This code is not the best, but should be fine on CPU
		switch( szArg[ 1 ] )
		{
			case 'a', 'A':
			{
				//
			}
			case 'c', 'C':
			{
				new iTemp[ 32 ], iTempNum;
				
				for( i = 0; i < iNum; i++ )
				{
					iPlayer = iPlayers[ i ];
					
					if( cs_get_user_team( iPlayer ) == CS_TEAM_CT )
					{
						iTemp[ iTempNum++ ] = iPlayer;
					}
				}
				
				iPlayers = iTemp;
				iNum = iTempNum;
			}
			case 't', 'T':
			{
				new iTemp[ 32 ], iTempNum;
				
				for( i = 0; i < iNum; i++ )
				{
					iPlayer = iPlayers[ i ];
					
					if( cs_get_user_team( iPlayer ) == CS_TEAM_T )
					{
						iTemp[ iTempNum++ ] = iPlayer;
					}
				}
				
				iPlayers = iTemp;
				iNum = iTempNum;
			}
			default:
			{
				console_print( id, "Unknown team!" );
				
				return PLUGIN_HANDLED;
			}
		}
	}
	/*if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ach" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ )
			set_pev( iPlayers[ i ], pev_health, float( iAmount ) );
		
		ShowActivity( id, szAdmin, "Set^4 %i^1 health on all players.", iAmount );
		
		console_print( id, "* You set %i health on all players.", iAmount );*/
	else
	{
		new iPlayer = cmd_target( id, szArg, CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		set_pev( iPlayer, pev_health, float( iAmount ) );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "Set^4 %i^1 health on^4 %s^1.", iAmount, szName );
		
		console_print( id, "* You set %i health on %s.", iAmount, szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdExec( id, level, cid ) {
	if( !cmd_access( id, level, cid, 3 ) )
		return PLUGIN_HANDLED;
	
	new szArg[ 32 ], szCommand[ 64 ], szAdmin[ 32 ], iPlayer;
	get_user_name( id, szAdmin, 31 );
	read_argv( 1, szArg, 31 );
	read_argv( 2, szCommand, 63 );
	remove_quotes( szCommand );
	
//	while( replace( szCommand, 63, "\'", "^"" ) ) { }
	
	if( equali( szArg, "@all" ) ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ch" );
		
		if( !iNum ) {
			console_print( id, "* No players found." );
			
			return PLUGIN_HANDLED;
		}
		
		for( new i; i < iNum; i++ ) {
			iPlayer = iPlayers[ i ];
			
			if( get_user_flags( iPlayer ) & ADMIN_IMMUNITY )
				continue;
			else if( iPlayer == id )
				continue;
			
			client_cmd( iPlayer, szCommand );
		}
		
		ShowActivity( id, szAdmin, "Used command^4 ^"%s^"^1 on everyone.", szCommand );
		
		console_print( id, "* You used command ^"%s^" on everyone.", szCommand );
	} else {
		iPlayer = cmd_target( id, szArg, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_NO_BOTS );
		
		if( !iPlayer )
			return PLUGIN_HANDLED;
		
		client_cmd( iPlayer, szCommand );
		
		new szName[ 32 ];
		get_user_name( iPlayer, szName, 31 );
		
		ShowActivity( id, szAdmin, "Used command^4 ^"%s^"^1 on^4 %s^1.", szCommand, szName );
		
		console_print( id, "* You used command ^"%s^" on %s.", szCommand, szName );
	}
	
	return PLUGIN_HANDLED;
}

public CmdTeleport( id, level, cid ) {
	if( !cmd_access( id, level, cid, 4 ) )
		return PLUGIN_HANDLED;
	
	if( !is_user_alive( id ) ) {
		console_print( id, "* You should be alive!" );
		
		return PLUGIN_HANDLED;
	}
	
	new szCoord[ 3 ][ 6 ], Float:vOrigin[ 3 ];
	
	read_argv( 1, szCoord[ 0 ], 5 );
	read_argv( 2, szCoord[ 1 ], 5 );
	read_argv( 3, szCoord[ 2 ], 5 );
	
	vOrigin[ 0 ] = str_to_float( szCoord[ 0 ] );
	vOrigin[ 1 ] = str_to_float( szCoord[ 1 ] );
	vOrigin[ 2 ] = str_to_float( szCoord[ 2 ] );
	
	entity_set_origin( id, vOrigin );
	
	console_print( id, "* Teleported to %i %i %i", floatround( vOrigin[ 0 ] ), floatround( vOrigin[ 1 ] ), floatround( vOrigin[ 2 ] ) );
	
	return PLUGIN_HANDLED;
}

#if defined DAMAGE_SHOWER
	public EventDamage( id ) {
		new iAttacker = get_user_attacker( id );
		
		if( is_user_connected( iAttacker ) ) {
			new iDamage = read_data( 2 );
			
			set_hudmessage( 255, 0, 0, 0.45, 0.50, 2, 0.1, 4.0, 0.1, 0.1, -1 );
			ShowSyncHudMsg( id, g_iHudSync1, "%i^n", iDamage );
			
			set_hudmessage( 0, 100, 200, -1.0, 0.55, 2, 0.1, 4.0, 0.02, 0.02, -1 );
			ShowSyncHudMsg( iAttacker, g_iHudSync2, "%i^n", iDamage );
		}
	}
#endif

/*public CmdOnlineAdmins( id ) {
	new szMessage[ 192 ], szNicks[ 33 ][ 25 ], iPlayers[ 32 ], iNum, iCount, i, iLen;
	get_players( iPlayers, iNum );
	
	for( i = 0; i < iNum; i++ )
		if( get_user_flags( iPlayers[ i ] ) & ADMIN_KICK )
			get_user_name( iPlayers[ i ], szNicks[ iCount++ ], charsmax( szNicks[ ] ) );
	
	iLen = formatex( szMessage, 191, "^3Admins Online:^4 " );
	
	if( iCount > 0 ) {
		for( i = 0; i < iCount; i++ ) {
			iLen += formatex( szMessage[ iLen ], 191, "%s%s ", szNicks[ i ], i < ( iCount - 1 ) ? "^1,^4 " : "" );
			
			if( iLen > 96 ) {
				ColorChat( id, Red, szMessage );
				iLen = formatex( szMessage, 191, "^3Admins Online:^4 " );
			}
		}
		ColorChat( id, Red, szMessage );
	} else {
		iLen += formatex( szMessage[ iLen ], 191, "None" );
		
		ColorChat( id, Red, szMessage );
	}
}*/

public CmdFullUpdate( id )
	return PLUGIN_HANDLED_MAIN;

ShowActivity( id, const szName[ ], const szString[ ], any:... ) {
	new szBuffer[ 190 ], iColor;
	vformat( szBuffer, 189, szString, 4 );
	
	switch( get_user_team( id ) ) {
		case 2: iColor = Blue;
		case 3: iColor = Grey;
		default: iColor = Red;
	}
	
	ColorChat( 0, iColor, "^4Admin^3 %s^1: %s", szName, szBuffer );
}