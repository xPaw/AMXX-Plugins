#include < amxmodx >
#include < orpheu >

public plugin_init( )
{
	register_plugin( "FootSteps Vol Reducer", "1.0", "xPaw" );
	
	OrpheuRegisterHook( OrpheuGetFunction( "PM_PlayStepSound" ), "PM_PlayStepSound" );
}

public OrpheuHookReturn:PM_PlayStepSound( const iStep, const Float:flVol )
{
	OrpheuSetParam( 2, 0.25 );
}
