#include < amxmodx >
#include < engine >
#include < hamsandwich >

const FM_NULLENT = -1;

new const BLOCKS[ ][ ] = {
	"block_pink",
	"block_green",
	"block_blue",
	"block_orange",
	"block_black",
	"block_red",
	"block_yellow",
	"block_brown",
	"block_purple"
};

new const WORDS[ ][ ] = {
	"word_left",
	"word_right",
	"word_back",
	"word_orange",
	"word_black",
	"word_brown",
	"word_red",
	"word_pink",
	"word_yellow",
	"word_blue",
	"word_purple",
	"word_green",
	"word_front",
	"word_middle"
};

enum _:BLOCKZ {
	BLOCK_PINK = 0,
	BLOCK_GREEN,
	BLOCK_BLUE,
	BLOCK_ORANGE,
	BLOCK_BLACK,
	BLOCK_RED,
	BLOCK_YELLOW,
	BLOCK_BROWN,
	BLOCK_PURPLE
};

enum _:WORD_COMBOS {
	WORD_LEFT = 0,
	WORD_RIGHT,
	WORD_BACK,
	WORD_ORANGE,
	WORD_BLACK,
	WORD_BROWN,
	WORD_RED,
	WORD_PINK,
	WORD_YELLOW,
	WORD_BLUE,
	WORD_PURPLE,
	WORD_GREEN,
	WORD_FRONT,
	WORD_MIDDLE
};

new g_iWords[ WORD_COMBOS ], g_iBlocks[ BLOCKZ ], g_iEntities[ WORD_COMBOS ][ 3 ];
new bool:g_bPlaying, g_iBreak, Float:g_flDelay;

public plugin_init( ) {
	register_plugin( "Simon Says", "1.0", "xPaw" );
	
	new szMap[ 12 ];
	get_mapname( szMap, 11 )
	
	if( !equali( szMap, "simon_says" ) )
		set_fail_state( "Hi." );
	
	register_logevent( "EventRoundStart", 2, "1=Round_Start" );
	register_logevent( "EventRoundEnd", 2, "1=Round_End" );
	register_event( "TextMsg", "EventRoundEnd", "a", "2&#Game_C", "2&#Game_w" );
	
	register_clcmd( "radio1", "FwdImpulse201" );
	register_clcmd( "radio2", "FwdImpulse201" );
	register_clcmd( "radio3", "FwdImpulse201" );
	
	register_impulse( 201, "FwdImpulse201" );
	
	g_iBreak = find_ent_by_tname( FM_NULLENT, "simon_break" );
	
	new iEntity, i;
	
	for( i = 0; i <= WORD_MIDDLE; i++ ) {
		g_iWords[ i ] = iEntity = find_ent_by_tname( FM_NULLENT, WORDS[ i ] );
		
		if( !iEntity )
			log_amx( "Not found %s", WORDS[ i ] );
		else
			HideEntity( iEntity );
	}
	
	for( i = 0; i <= BLOCK_PURPLE; i++ ) {
		iEntity = find_ent_by_tname( FM_NULLENT, BLOCKS[ i ] );
		
		if( !iEntity )
			log_amx( "Not found %s", BLOCKS[ i ] );
		else
			g_iBlocks[ i ] = iEntity;
	}
	
	for( i = 0; i <= WORD_MIDDLE; i++ ) {
		switch( i ) {
			case WORD_LEFT: {
				g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_GREEN ];
				g_iEntities[ i ][ 1 ] = g_iBlocks[ BLOCK_BROWN ];
				g_iEntities[ i ][ 2 ] = g_iBlocks[ BLOCK_BLACK ];
			}
			case WORD_RIGHT: {
				g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_BLUE ];
				g_iEntities[ i ][ 1 ] = g_iBlocks[ BLOCK_PINK ];
				g_iEntities[ i ][ 2 ] = g_iBlocks[ BLOCK_YELLOW ];
			}
			case WORD_BACK: {
				g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_PINK ];
				g_iEntities[ i ][ 1 ] = g_iBlocks[ BLOCK_BLACK ];
				g_iEntities[ i ][ 2 ] = g_iBlocks[ BLOCK_ORANGE ];
			}
			case WORD_ORANGE: g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_ORANGE ];
			case WORD_BLACK:  g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_BLACK ];
			case WORD_BROWN:  g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_BROWN ];
			case WORD_RED, WORD_MIDDLE: g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_RED ];
			case WORD_PINK:   g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_PINK ];
			case WORD_YELLOW: g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_YELLOW ];
			case WORD_BLUE:   g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_BLUE ];
			case WORD_PURPLE: g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_PURPLE ];
			case WORD_GREEN:  g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_GREEN ];
			case WORD_FRONT: {
				g_iEntities[ i ][ 0 ] = g_iBlocks[ BLOCK_GREEN ];
				g_iEntities[ i ][ 1 ] = g_iBlocks[ BLOCK_BLUE ];
				g_iEntities[ i ][ 2 ] = g_iBlocks[ BLOCK_PURPLE ];
			}
		}
	}
}

public FwdImpulse201( )
	return PLUGIN_HANDLED_MAIN;

public EventRoundStart( ) {
	remove_task( 13648 );
	
	set_task( 4.0, "TaskStart", 13648 );
}

public EventRoundEnd( ) {
	remove_task( 13648 );
	
	g_bPlaying = false;
}

public TaskStart( ) {
	GreenPrint( 0, "^4Simon game is starting!^3 Prepare to die!^1 Plugin by xPaw." );
	
	ExecuteHamB( Ham_TakeDamage, g_iBreak, 0, 0, 9999.0, DMG_GENERIC );
	
	g_bPlaying = true;
	
	g_flDelay = 2.0;
	
	set_task( 3.0, "StartGame" );
}

HideEntity( const iEntity ) {
	entity_set_int( iEntity, EV_INT_solid, SOLID_NOT );
	entity_set_int( iEntity, EV_INT_effects, entity_get_int( iEntity, EV_INT_effects ) | EF_NODRAW );
}

ShowEntity( const iEntity ) {
	if( entity_get_int( iEntity, EV_INT_solid ) == SOLID_BSP )
		return;
	
	entity_set_int( iEntity, EV_INT_solid, SOLID_BSP );
	entity_set_int( iEntity, EV_INT_effects, entity_get_int( iEntity, EV_INT_effects ) & ~EF_NODRAW );
}

public StartGame( ) {
//	static iNum;
//	if( iNum == WORD_FRONT ) iNum = -1;
//	iNum++;
	
	new iNum = random_num( 0, WORD_MIDDLE );
	
	ShowEntity( g_iWords[ iNum ] );
	
	set_task( g_flDelay, "RemoveBlocks", iNum );
	
	g_flDelay -= 0.1;
	
	if( g_flDelay < 0.5 )
		g_flDelay = 0.5;
}

public RemoveBlocks( const iNum ) {
	new j, iEntity, bool:bFound;
	
	for( new i; i <= BLOCK_PURPLE; i++ ) {
		iEntity = g_iBlocks[ i ];
		bFound  = false;
		
		for( j = 0; j < 3; j++ ) {
			if( g_iEntities[ iNum ][ j ] == iEntity ) {
				bFound = true;
				break;
			}
		}
		
		if( !bFound )
			HideEntity( iEntity );
	}
	
	set_task( 2.0, "ShowBack", iNum );
}

public ShowBack( const iNum ) {
	HideEntity( g_iWords[ iNum ] );
	
	for( new i; i <= BLOCK_PURPLE; i++ )
		ShowEntity( g_iBlocks[ i ] );
	
	if( g_bPlaying )
		StartGame( );
}

GreenPrint( id, const message[ ], any:... ) {
	new szMessage[ 192 ];
	vformat( szMessage, 191, message, 3 );
	
	static iSayText;
	if( !iSayText )
		iSayText = get_user_msgid( "SayText" );
	
	message_begin( id ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, iSayText, _, id );
	write_byte( id ? id : 1 );
	write_string( szMessage );
	message_end( );
}
