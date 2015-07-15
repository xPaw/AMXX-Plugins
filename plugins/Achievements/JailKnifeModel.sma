#include < amxmodx >
#include < achievements >
#include < fakemeta >
#include < hamsandwich >

#define KNIFE_DRAW_ANIM 3

#define m_pPlayer        41
#define m_iId            43
#define m_flDeployedTime 76
#define m_pActiveItem    373

new bool:g_bOldKnife[ 33 ], g_iOldKnifeMdl, ACH_KNIFE;
new bool:g_bHaveAchievment[ 33 ];

public plugin_init( )
{
	register_plugin( "Knife model", "1.0", "xPaw" );
	
	register_clcmd( "drop", "CmdDrop" );
	register_event( "DeathMsg", "EventDeathMsg", "a" );
	
	RegisterHam( Ham_Item_Deploy, "weapon_knife", "FwdHamKnifeDeploy", 1 );
	
	ACH_KNIFE = RegisterAchievement( "The Melbourne Supremacy", "Kill 50 guards with your bare hands <b>(This achievement will grant you access to old knife skin)</b>", 50 );
	
	g_iOldKnifeMdl = engfunc( EngFunc_AllocString, "models/v_knife_r.mdl" );
}

public plugin_precache( )
{
	precache_model( "models/v_knife_r.mdl" );
}

public Achv_Unlock( const id, const iAchievement )
{
	if( iAchievement == ACH_KNIFE )
	{
		client_print( id, print_center, "** You just unlocked old knife model! **" );
		g_bHaveAchievment[ id ] = true;
	}
}

public Achv_Connect( const id, const iPlayTime, const iConnects )
{
	g_bHaveAchievment[ id ] = bool:HaveAchievement( id, ACH_KNIFE );
}

public client_disconnect( id ) 
{
	g_bOldKnife[ id ] = g_bHaveAchievment[ id ] = false;
}

public EventDeathMsg( ) 
{
	new iKiller = read_data( 1 );
	
	if( !g_bHaveAchievment[ iKiller ] && get_user_team( iKiller ) == 1 )
	{
		new szWeapon[ 8 ];
		read_data( 4, szWeapon, 7 );
		
		if( szWeapon[ 0 ] == 'k' && szWeapon[ 3 ] == 'f' ) // knife
		{
			AchievementProgress( iKiller, ACH_KNIFE );
		}
	}
}

public FwdHamKnifeDeploy( const iKnife )
{
	if( pev_valid( iKnife ) == 2 )
	{
		new id = get_pdata_cbase( iKnife, m_pPlayer, 4 );
		
		if( g_bOldKnife[ id ] )
		{
			if( get_user_team( id ) != 2 )
			{
				g_bOldKnife[ id ] = false;
				return;
			}
			
			set_pev( id, pev_viewmodel, g_iOldKnifeMdl );
		}
	}
}

public CmdDrop( const id )
{
	if( g_bHaveAchievment[ id ] && get_user_team( id ) == 2 && is_user_alive( id ) )
	{
		new iWeapon = get_pdata_cbase( id, m_pActiveItem, 5 );
		
		if( pev_valid( iWeapon ) == 2 && get_pdata_int( iWeapon, m_iId, 4 ) == CSW_KNIFE )
		{
			g_bOldKnife[ id ] = !g_bOldKnife[ id ];
			
			if( get_gametime( ) - get_pdata_float( iWeapon, m_flDeployedTime, 4 ) <= 1.5 )
			{
				set_pev( id, pev_weaponanim, KNIFE_DRAW_ANIM );
				
				message_begin( MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id );
				write_byte( KNIFE_DRAW_ANIM );
				write_byte( pev( id, pev_body ) );
				message_end( );
			}
			
			ExecuteHamB( Ham_Item_Deploy, iWeapon );
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}
