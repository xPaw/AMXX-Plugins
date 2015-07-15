#include < amxmodx >
#include < fun >
#include < cstrike >
#include < fakemeta >
#include < engine >
#include < LastRequest >

new g_iForward;
new g_iMaxPlayers;

public plugin_init( ) {
	register_plugin( "[LR] Gun Toss", "1.0", "xPaw" );
	
	Lr_RegisterGame( "Gun Toss", "FwdGameBattle", true );
	
	g_iMaxPlayers = get_maxplayers( );
}

public Lr_GameFinished( const id, const bool:bDidTerroristWin )
{
	if( g_iForward )
	{
		unregister_forward( FM_SetModel, g_iForward, true );
		
		g_iForward = 0;
	}
}

public FwdGameBattle( const id, const iVictim )
{
	if( !g_iForward )
	{
		g_iForward = register_forward( FM_SetModel, "FwdSetModel", true );
	}
	
	Lr_RestoreHealth( id );
	
	if( iVictim )
	{
		Lr_RestoreHealth( iVictim );
		
		GiveWeapons( id, iVictim );
	}
}

public FwdSetModel( const iEntity, const szModel[ ] )
{
	if( pev_valid( iEntity ) )
	{
		new id = pev( iEntity, pev_owner );
		
		if( 1 <= id <= g_iMaxPlayers )
		{
			static const DeagleModel[ ] = "models/w_deagle.mdl" ;
			
			if( equal( szModel, DeagleModel ) )
			{
				entity_set_int( iEntity, EV_INT_renderfx, kRenderFxGlowShell );
				entity_set_int( iEntity, EV_INT_rendermode, kRenderNormal );
				entity_set_float( iEntity, EV_FL_renderamt, 16.0 );
				
				if( get_user_team( id ) == 1 )
				{
					entity_set_vector( iEntity, EV_VEC_rendercolor, Float:{ 255.0, 0.0, 0.0 } );
				}
				else
				{
					entity_set_vector( iEntity, EV_VEC_rendercolor, Float:{ 0.0, 0.0, 255.0 } );
				}
			}			
		}
	}
}

GiveWeapons( const iPlayer1, const iPlayer2 )
{
	static const Deagle[ ] = "weapon_deagle";
	
	give_item( iPlayer1, Deagle );
	cs_set_user_bpammo( iPlayer1, CSW_DEAGLE, 0 );
	cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_deagle", iPlayer1 ), 7 );
	
	give_item( iPlayer2, Deagle );
	cs_set_user_bpammo( iPlayer2, CSW_DEAGLE, 0 );
	cs_set_weapon_ammo( find_ent_by_owner( -1, "weapon_deagle", iPlayer2 ), 7 );
}
