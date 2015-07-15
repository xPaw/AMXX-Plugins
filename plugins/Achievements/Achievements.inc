#if defined _achievements_included
	#endinput
#endif
#define _achievements_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib Achievements
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib Achievements
	#endif
#else
	#pragma library Achievements
#endif

/* 
 * Registers a new achievement
 * 
 * @param		Name - The display name of the achievement
 * @param		Description - The description of the achievement
 * @param		NeededToGain - The amount needed to unlock this achievement
 * 
 * @return		Returns the unique achievement id (iAchievement)
 */
native RegisterAchievement( Name[ 32 ], Description[ 128 ], Achv_NeededToGain );

/*
 * Checks if a player has unlocked an achievement already
 * 
 * @param		id - Player id
 * @param		iAchievement - The unique id of the achievement
 * 
 * @return		true if unlocked, false if not
 * 
 */
native HaveAchievement( id, iAchievement );

/*
 * Adds amount to players stats
 * 
 * @param		id - Player id
 * @param		iAchievement - The unique id of the achievement
 * @param		iHowMuchToAdd - amount how much to give
 * 
 * @return		No return
 * 
 */
native AchievementProgress( id, iAchievement, iHowMuchToAdd = 1 );

/*
 * Gets player's amount for achievement
 * 
 * @param		id - Player id
 * @param		iAchievement - The unique id of the achievement
 * 
 * @return		Returns player's progress for this achievement
 * 
 */
native GetProgress( id, iAchievement );

/*
 * Gets player's amount for achievement
 * 
 * @param		id - Player id
 * 
 * @return		Returns how many achievements player has unlocked
 *				If 0 is passed as 0, returns total achievements count
 * 
 */
native GetUnlocksCount( id );

/*
 * Sets the specified component bit # if it is not already.
 * 
 * @param		id - Player id
 * @param		iAchievement - The unique id of the achievement
 * @param		iBitNumber - Component bit number
 * 
 * @return		No return
 * 
 */
native SetAchievementComponentBit( id, iAchievement, iBitNumber );

/*
 * Called when player is connected and initialized his achievements
 * 
 * @param		id - Player id
 * @param		iPlayTime - how long player has played on this server (minutes)
 * 
 */
forward Achv_Connect( const id, const iPlayTime, const iConnects );

/*
 * Called when player unlocks achievement
 * 
 * @param		id - Player id
 * @param		iAchievement - The unique id of the achievement
 * 
 */
forward Achv_Unlock( const id, const iAchievement );

/*
 * Sets new value in leaderboards
 * 
 * @param		id     - Player id
 * @param		szName - The unique name for leaderboard
 * @param       iCount - New value (if it's lower than current, it won't be updated)
 * 
 * @return		No return
 * 
 */
native SetLeaderBoard( id, szName[ 32 ], iCount );

/*
 * Gets player's PlayerId from GlobalPlayers table
 * This can be used in Achv_Connect() forward
 * 
 * @param		id     - Player id
 * 
 * @return		Returns player sql id from GlobalPlayers table
 *              If it returns 0, it means that this player didn't get his PlayerId yet
 * 
 */
native GetPlayerId( id );

/*
 * Called when something goes completely wrong in core plugin.
 * 
 */
forward Achv_CoreGoneWrong( );

public Achv_CoreGoneWrong( )
	set_fail_state( "Core plugin has failed." );
