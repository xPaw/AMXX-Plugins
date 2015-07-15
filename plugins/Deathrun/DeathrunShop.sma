#include < amxmodx >
#include < fun >
#include < cstrike >
#include < hamsandwich >
#include < chatcolor >

enum _:ITEMS {
	ITEM_HP = 0,
	ITEM_AP,
	ITEM_HE,
	ITEM_HEFLASH,
	ITEM_NOBLIND,
	ITEM_SPEED,
	ITEM_GRAVITY,
	ITEM_STEALTH,
	ITEM_RESPAWN
};

new const g_iCosts[ ITEMS ] = {
	7000,	// HP
	5000,	// AP
	5000,	// HE
	7000,	// HE FLASH
	5000,	// NO BLIND
	14000,	// SPEED
	15000,	// GRAVITY
	16000,	// STEALTH
	16000	// RESPAWN
};

new const g_iDelays[ ITEMS ] = {
	0,	// HP
	0,	// AP
	0,	// HE
	0,	// HE FLASH
	0,	// NO BLIND
	60,	// SPEED
	60,	// GRAVITY
	20,	// STEALTH
	0	// RESPAWN
};

new const g_szNames[ ITEMS ][ ] = {
	"255 HP",
	"900 AP",
	"HE Grenade",
	"HE + 2 Flashbangs",
	"No Flash Blinding",
	"Faster speed",
	"Low Gravity",
	"Stealth",
	"Respawn"
};

new g_szMenu[ 512 ], g_iKeys;
new bool:g_bHave[ 33 ][ ITEMS ];
new bool:g_bUsed[ 33 ][ ITEMS ];

public plugin_init( ) {
	register_plugin( "Deathrun Shop", "2.1", "xPaw" );
	
	register_clcmd( "say /shop",   "CmdShop" );
	register_clcmd( "say /drshop", "CmdShop" );
	register_clcmd( "nightvision", "CmdShop" );
	
	register_event( "CurWeapon", "EventCurWeapon", "be" );
	register_message( get_user_msgid( "ScreenFade" ), "MsgScreenFade" );
	register_menucmd( register_menuid( "DeathrunShop" ), 1023, "HandleShop" );
	
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 );
	RegisterHam( Ham_Killed, "player", "FwdHamKilledPlayer", 1 );
	
	set_task( 100.0, "PrintMessage", _, _, _, "b" );
	
	// Generate menu
	new szPrefix[ 25 ], iLen; g_iKeys = ( 1 << 9 );
	
	iLen = formatex( g_szMenu, charsmax( g_szMenu ), "\rmY.RuN\w - Deathrun Shop^n^n");
	
	for( new i = 0; i < ITEMS; i++ ) {
		g_iKeys |= ( 1 << i );
		
		switch( i ) {
			case ITEM_STEALTH: szPrefix = " \d(Only T)";
			case ITEM_RESPAWN: szPrefix = " \d(Only CT) \r(2 frags)";
			default: szPrefix = "";
		}
		
		if( g_iDelays[ i ] > 0 )
			iLen += formatex( g_szMenu[ iLen ], charsmax( g_szMenu ) - iLen, "\r%i. \w%s%s\r (%i seconds)\y\R%i$^n", i + 1, g_szNames[ i ], szPrefix, g_iDelays[ i ], g_iCosts[ i ] );
		else
			iLen += formatex( g_szMenu[ iLen ], charsmax( g_szMenu ) - iLen, "\r%i. \w%s%s\y\R%i$^n", i + 1, g_szNames[ i ], szPrefix, g_iCosts[ i ] );
	}
	
	iLen += formatex( g_szMenu[ iLen ], charsmax( g_szMenu ) - iLen, "^n\r0. \wExit" );
}

public plugin_precache( ) {
	precache_sound( "items/medshot4.wav" );
	precache_sound( "items/ammopickup2.wav" );
}

public PrintMessage( )
	ColorChat( 0, Red, "[ mY.RuN ]^1 This server is running^4 Deathrun Shop^1, say^4 /shop^1 or press^3 'N'^1 (nvg key)" );

public client_putinserver( id )
	ResetItems( id );

public client_disconnect( id )
	remove_task( id );

public FwdHamPlayerSpawn( id )
	if( is_user_alive( id ) ) {
		set_user_gravity( id, 1.0 );
		set_user_maxspeed( id, 250.0 );
		cs_set_user_armor( id, 0, CS_ARMOR_NONE );
		
		if( g_bHave[ id ][ ITEM_STEALTH ] ) {
			set_user_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255 );
		}
		
		ResetItems( id );
	}

public FwdHamKilledPlayer( id, iAttacker, iShouldGib )
	remove_task( id );

public EventCurWeapon( id ) {
	if( g_bHave[ id ][ ITEM_SPEED ] )
		set_user_maxspeed( id, 320.0 );
	
	if( g_bHave[ id ][ ITEM_GRAVITY ] )
		set_user_gravity( id, 0.63 );
}

public MsgScreenFade( iMsgId, iMsgDest, id ) {
	if( get_msg_arg_int( 4 ) == 255 && get_msg_arg_int( 5 ) == 255 && get_msg_arg_int( 6 ) == 255 )
		if( g_bUsed[ id ][ ITEM_NOBLIND ] )
			return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public RemoveSpeed( id ) {
	g_bHave[ id ][ ITEM_SPEED ] = false;
	
	if( is_user_alive( id ) ) {
		set_user_maxspeed( id, 250.0 );
		
		ColorChat( id, Red, "[ mY.RuN ]^1 Your speed is normal now." );
	}
}

public RemoveGravity( id ) {
	g_bHave[ id ][ ITEM_GRAVITY ] = false;
	
	if( is_user_alive( id ) ) {
		set_user_gravity( id, 1.0 );
		
		ColorChat( id, Red, "[ mY.RuN ]^1 Your gravity is normal now." );
	}
}

public RemoveStealth( id ) {
	g_bHave[ id ][ ITEM_STEALTH ] = false;
	
	if( is_user_alive( id ) ) {
		set_user_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 255 );
		
		ColorChat( id, Red, "[ mY.RuN ]^1 You are visible like others now." );
	}
}

public CmdShop( id ) {
	show_menu( id, g_iKeys, g_szMenu, -1, "DeathrunShop" );
	
	return PLUGIN_HANDLED;
}

public HandleShop( id, iKey ) {
	if( 0 <= iKey <= 8 )
		if( !CanBuy( id, iKey ) )
			return PLUGIN_HANDLED;
	
	switch( iKey ) {
		case ITEM_HP: {
			emit_sound( id, CHAN_ITEM, "items/medshot4.wav", 0.8, ATTN_NORM, 0, PITCH_LOW );
			
			set_user_health( id, 255 );
		}
		case ITEM_AP: {
			emit_sound( id, CHAN_ITEM, "items/ammopickup2.wav", 0.8, ATTN_NORM, 0, PITCH_LOW );
			
			cs_set_user_armor( id, 900, CS_ARMOR_VESTHELM );
		}
		case ITEM_HE: give_item( id, "weapon_hegrenade" );
		case ITEM_HEFLASH: {
			give_item( id, "weapon_hegrenade" );
			give_item( id, "weapon_flashbang" );
			cs_set_user_bpammo( id, CSW_FLASHBANG, 2 );
		}
		case ITEM_SPEED: {
			set_user_maxspeed( id, 320.0 );
			
			set_task( float( g_iDelays[ iKey ] ), "RemoveSpeed", id );
		}
		case ITEM_GRAVITY: {
			set_user_gravity( id, 0.63 );
			
			set_task( float( g_iDelays[ iKey ] ), "RemoveGravity", id );
		}
		case ITEM_STEALTH: {
			set_user_rendering( id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 2 );
			
			set_task( float( g_iDelays[ iKey ] ), "RemoveStealth", id );
		}
		case ITEM_RESPAWN: ExecuteHamB( Ham_CS_RoundRespawn, id );
		default: return PLUGIN_HANDLED;
	}
	
	return PLUGIN_HANDLED;
}

CanBuy( id, iItem ) {
	new bool:bIsAlive = bool:is_user_alive( id );
	
	if( iItem != ITEM_RESPAWN && !bIsAlive ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You need to be alive!" );
		
		return 0;
	}
	else if( g_bUsed[ id ][ iItem ] ) {
		ColorChat( id, Red, "[ mY.RuN ]^1 You already bought^4 %s^1.", g_szNames[ iItem ] );
		
		return 0;
	}
	
	new iFrags = get_user_frags( id );
	
	if( iItem == ITEM_STEALTH ) {
		if( cs_get_user_team( id ) != CS_TEAM_T ) {
			ColorChat( id, Red, "[ mY.RuN ]^4 %s^1 is only for terrorists!", g_szNames[ iItem ] );
			
			return 0;
		}
	}
	else if( iItem == ITEM_RESPAWN ) {
		if( cs_get_user_team( id ) != CS_TEAM_CT ) {
			ColorChat( id, Red, "[ mY.RuN ]^4 %s^1 is only for counter-terrorists!", g_szNames[ iItem ] );
			
			return 0;
		}
		else if( bIsAlive ) {
			ColorChat( id, Red, "[ mY.RuN ]^4 %s^1 is only for dead people!", g_szNames[ iItem ] );
			
			return 0;
		}
		else if( iFrags < 2 ) {
			ColorChat( id, Red, "[ mY.RuN ]^1 You don't have enough frags to buy^4 %s^1.", g_szNames[ iItem ] );
			
			return 0;
		}
	}
	
	new iMoney = cs_get_user_money( id );
	new iCost = g_iCosts[ iItem ];
	
	if( iMoney >= iCost ) {
		cs_set_user_money( id, clamp( ( iMoney - iCost ), 0, 16000 ) );
		
		if( iItem == ITEM_RESPAWN )
			set_user_frags( id, iFrags - 2 );
		
		g_bUsed[ id ][ iItem ] = true;
		
		if( g_iDelays[ iItem ] > 0 )
			g_bHave[ id ][ iItem ] = true;
		
		ColorChat( id, Red, "[ mY.RuN ]^1 You purchased^4 %s^1.", g_szNames[ iItem ] );
		
		if( callfunc_begin( "JustBoughtItem", "Achievements.amxx" ) == 1 ) {
			callfunc_push_int( id );
			callfunc_push_int( iItem );
			callfunc_end( );
		}
		
		return 1;
	} else
		ColorChat( id, Red, "[ mY.RuN ]^1 You don't have enough money to buy^4 %s^1.", g_szNames[ iItem ] );
	
	return 0;
}

ResetItems( id ) {
	for( new i = 0; i < ITEMS; i++ ) {
		g_bHave[ id ][ i ] = false;
		g_bUsed[ id ][ i ] = false;
	}
	
	remove_task( id );
}
