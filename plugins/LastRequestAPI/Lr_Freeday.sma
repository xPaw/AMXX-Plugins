#include < amxmodx >
#include < fun >
#include < hamsandwich >
#include < LastRequest >
#include < chatcolor >

#define IsFD(%0)     ( g_iFreeday & %0 )
#define SetFD(%0)    ( g_iFreeday |= %0 )
#define RemoveFD(%0) ( g_iFreeday &= ~%0 )

new g_iUpcoming, g_iFreeday;

public plugin_init( )
{
	register_plugin( "[LR] Freeday", "1.0", "master4life" );
	
	Lr_RegisterGame( "Freeday", "FwdGameBattle", false );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamSpawnPlayerPost", true );
	RegisterHam( Ham_Use, "func_button", "FwdHamPressButtonsPre" );
}

public Lr_Menu_PreDisplay( const id )
{
	return IsFD( id ) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}
	
public FwdHamPressButtonsPre( const iEntity, const id )
{
	return IsFD( id ) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public FwdGameBattle( const id, const iVictim )
{
	g_iUpcoming = id;
}

public FwdHamSpawnPlayerPost( const id )
{
	if( g_iUpcoming == id )
	{
		g_iUpcoming = 0;
		
		new szName[ 32 ];
		get_user_name( id, szName, charsmax( szName ) );
		
		if( get_user_team( id ) == 2 )
		{
			ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 was going to have freeday, but he switched to^3 CT^1!", szName );
			
			return;
		}
		
		SetFD( id );
		
		set_user_rendering( id, kRenderFxGlowShell, 255, 140, 0, kRenderNormal, 25 );
		
		ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 has a freeday this round!", szName );
	}
	else if( IsFD( id ) )
	{
		RemoveFD( id );
		
		set_user_rendering( id, kRenderFxNone, 255, 255, 255, kRenderNormal, 16 );
	}
}

public client_disconnect( id )
{
	if( g_iUpcoming == id )
	{
		g_iUpcoming = 0;
		
		new szName[ 32 ];
		get_user_name( id, szName, 31 );
		
		ColorChat( 0, Red, "[ mY.RuN ]^4 %s^1 was going to have a^4 free day^1, but he decided to leave!", szName );
	}
	else if( IsFD( id ) )
	{
		RemoveFD( id );
	}
}
