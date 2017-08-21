new const GameName[ ] = "[ my-run.de ]";
new const Prefix[ ] = "^3[ mY.RuN ]";
new g_szHTML[ 224 ] = "<html><head><meta http-equiv='Refresh' content='0; URL=http://example.com/kztop/?map=%m%&r'></head><body bgcolor=black><center><img src=http://example.com/l.png>";
new const SqlTable[ ] = "KreedzTop";
new const LogFile [ ] = "Kreedz.log";

#define HOOK_SPEED 660.0

#define m_iTeam       114
#define m_iRadiosLeft 192

const FL_ONGROUND2 = ( FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER | FL_CONVEYOR | FL_FLOAT );

// Tries / Handles
new Trie:g_tRestrictedWeapons;
new Trie:g_tWaterEntities;
new Trie:g_tSounds;
new Trie:g_tStarts;
new Trie:g_tStops;
new Handle:g_hSqlTuple;

// Just integers ...
new g_iMsgScreenFade;
new g_iMsgFlashLight;
new g_iMsgRoundTime;
new g_iMsgTeamInfo;
new g_iMsgDeathMsg;
new g_iMaxPlayers;
new g_iHudSync;
new g_iBeam;
new g_iLeet;

// Forwards
new g_iFwdTimerStart;
new g_iFwdTimerStop;
new g_iFwdCheatDetected;

// Strings / Arrays
new g_szStartFile[ 128 ];
new g_szMap[ 32 ];

new g_szLeetSteamId[ 30 ];
new g_szLeetName[ 33 ];

new g_iSpectateId[ 33 ];
new g_iGoChecks[ 33 ];
new g_iCheckPoints[ 33 ];
new g_iHookOrigin[ 33 ][ 3 ];

// Booleans
new bool:g_bCpAlternate[ 33 ];
new bool:g_bProDisabled[ 33 ];
new bool:g_bFinishedMap[ 33 ];
new bool:g_bNightVision[ 33 ];
new bool:g_bAfterHook[ 33 ];
new bool:g_bAdmin[ 33 ];
new bool:g_bHook[ 33 ];
new bool:g_bInvisWater[ 33 ];
new bool:g_bInvisPlayers[ 33 ];
new bool:g_bConnected[ 33 ];
new bool:g_bBetaMsg[ 33 ];
new bool:g_bAutoHeal;

// Floats
new Float:g_vCheckPoints[ 33 ][ 2 ][ 3 ];
new Float:g_vCheckAngles[ 33 ][ 2 ][ 3 ];
new Float:g_vSavedOrigin[ 33 ][ 3 ];
new Float:g_vSavedAngles[ 33 ][ 3 ];
new Float:g_vUserStart[ 33 ][ 3 ];
new Float:g_vUserAngle[ 33 ][ 3 ];
new Float:g_flLastThink[ 33 ];
new Float:g_flStartTime[ 33 ];
new Float:g_flLastCmd[ 33 ];
new Float:g_flPaused[ 33 ];
new Float:g_flLeetTime;

#if !defined SURF_BUILD
	new g_szWR[ 200 ];
	new Float:g_flWRTime;
#endif

new Float:g_vStartOrigin[ 3 ];
new Float:g_vStartAngles[ 3 ];

// Variables
/*
#define BIT_INV_PLAYERS       ( 1 << 0 )
#define BIT_INV_WATER         ( 1 << 1 )
#define BIT_NIGHTVISION       ( 1 << 2 )
#define BIT_PRO_DISABLED      ( 1 << 3 )
#define BIT_MAP_FINISHED      ( 1 << 4 )
#define BIT_CP_ALTERNATE      ( 1 << 5 )
#define BIT_HOOK_ALLOWED      ( 1 << 6 )
#define BIT_AFTER_HOOK        ( 1 << 7 )
#define BIT_HOOKING           ( 1 << 8 )
#define BIT_ADMIN             ( 1 << 9 )
#define BIT_VIP               ( 1 << 10 )

new g_iBits[ 33 ];

#define CheckBits(%1,%2)  ( g_iBits[ %1 ] & %2 )
#define SetBits(%1,%2)    ( g_iBits[ %1 ] |= %2 )
#define RemoveBits(%1,%2) ( g_iBits[ %1 ] &= ~%2 )
#define SwitchBits(%1,%2) ( g_iBits[ %1 ] ^= %2 )
*/