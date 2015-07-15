#include < amxmodx >

#define HIDE_USELESS_CVARS // most of cvars
#define HIDE_MODS          // amx_client_languages, metamod_version, amxmodx_version
#define BLOCK_COMMANDS     // vote, votemap, timeleft, listmaps

public plugin_init( )
{
	register_plugin( "Hide", "1.1", "xPaw" );
	
#if defined HIDE_MODS
	set_cvar_flags( "amx_client_languages", 0 );
	//set_cvar_flags( "metamod_version", FCVAR_SPONLY );
	//set_pcvar_flags( get_cvar_pointer( "amxmodx_version" ), FCVAR_SPONLY ); // set_cvar_flags blocks amxmodx_version 
#endif // HIDE_MODS
	
#if defined HIDE_USELESS_CVARS
	new const szCvars[ ] =
	{
		"allow_spectators",
		"coop",
		"deathmatch",
		"decalfrequency",
		"edgefriction",
		"hostage_debug",
		"hostage_stop",
		"humans_join_team",
		"max_queries_sec",
		"max_queries_sec_global",
		"max_queries_window",
		"mp_allowmonsters",
		"mp_autokick",
		"mp_chattime",
		"mp_flashlight",
		"mp_footsteps",
		"mp_fragsleft",
		"mp_ghostfrequency",
		"mp_hostagepenalty",
		"mp_kickpercent",
		"mp_limitteams",
		"mp_logdetail",
		"mp_logfile",
		"mp_logmessages",
		"mp_mapvoteratio",
		"mp_maxrounds",
		"mp_mirrordamage",
		"mp_playerid",
		"mp_roundtime",
		"mp_startmoney",
		"mp_timeleft",
		"mp_timelimit",
		"mp_tkpunish",
		"mp_windifference",
		"mp_winlimit",
		"mp_consistency",
		"pausable",
		"sv_accelerate",
		"sv_aim",
		"sv_airaccelerate",
		"sv_airmove",
		"sv_allowupload",
		"sv_alltalk",
		"sv_bounce",
		"sv_cheats",
		"sv_clienttrace",
		"sv_clipmode",
		"sv_friction",
		"sv_gravity",
		"sv_logblocks",
		"sv_maxrate",
		"sv_maxspeed",
		"sv_minrate",
		"sv_password",
		"sv_restart",
		"sv_restartround",
		"sv_stepsize",
		"sv_stopspeed",
		"sv_uploadmax",
		"sv_voiceenable",
		"sv_wateraccelerate",
		"sv_waterfriction",
		"_tutor_bomb_viewable_check_interval",
		"_tutor_debug_level",
		"_tutor_examine_time",
		"_tutor_hint_interval_time",
		"_tutor_look_angle",
		"_tutor_look_distance",
		"_tutor_message_character_display_time_coefficient",
		"_tutor_message_minimum_display_time",
		"_tutor_message_repeats",
		"_tutor_view_distance"
	};
	
	new pCvar;
	
	for( new i; i < sizeof szCvars; i++ )
	{
		pCvar = get_cvar_pointer( szCvars[ i ] );
		
		if( pCvar )
		{
			set_pcvar_flags( pCvar, get_pcvar_flags( pCvar ) & ~FCVAR_SERVER );
		}
	}
#endif // HIDE_USELESS_CVARS

#if defined BLOCK_COMMANDS
	register_clcmd( "vote", "CmdBlock" );
	//register_clcmd( "votemap", "CmdBlock" );
	//register_clcmd( "timeleft", "CmdBlock" );
	register_clcmd( "listmaps", "CmdBlock" );
}

public CmdBlock( const id )
{
	return PLUGIN_HANDLED_MAIN;
#endif // BLOCK_COMMANDS
}
