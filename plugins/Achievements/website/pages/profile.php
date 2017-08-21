<?php
	if( !isset( $SteamId ) ) Exit;
	
	$Steam = GetProfileSteam( GetProfileId( $SteamId ) );
	
	// Find player in global table
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_global}` WHERE `SteamId` = '{$SteamId}'", $Sql ) or Die_Error( MySql_Error( ) );
	$Player = MySql_Fetch_Assoc( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
	
	if( !$Player[ 'Id' ] ) {
		$Message = "Requested player has been not found in our database.";
		require 'error.php';
		goto EndOfInclude;
	}
	
	// Find player in server table
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_players}` WHERE `Id` = '{$Player[ 'Id' ]}'", $Sql ) or Die_Error( MySql_Error( ) );
	$Player2 = MySql_Fetch_Assoc( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
	
	if( !$Player2[ 'Id' ] ) {
		$Message = "Requested player has been not found in our database. [2]";
		require 'error.php';
		goto EndOfInclude;
	}
	
	require 'bits.inc.php';
	
	// Get player progress
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_progress}` WHERE `Id` = '{$Player[ 'Id' ]}'", $Sql ) or Die_Error( MySql_Error( ) );
	$Progress = Array( );
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) ) {
		$Progress[ $SqlResult[ 'Achievement' ] ] = $SqlResult;
	}
	MySql_Free_Result( $SqlQuery );
	
	$AchievementsDone = Array( );
	$Achievements = Array( );
	
	// Get all achievements
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_achievs}`", $Sql ) or Die_Error( MySql_Error( ) );
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) ) {
		if( $Progress[ $SqlResult[ 'Id' ] ][ 'Progress' ] >= $SqlResult[ 'NeededToGain' ] ) {
			$AchievementsDone[ ] = $SqlResult;
			continue;
		}
		
		$Achievements[ ] = $SqlResult;
	}
	MySql_Free_Result( $SqlQuery );
	
	// Count achievements
	$AchDone  = Count( $AchievementsDone );
	$AchTotal = Count( $Achievements ) + $AchDone;
	
	// Get player country
	$GeoIp = new GeoIp( $config->geoip_file );
	$Country = $GeoIp->Country( $Player[ 'Ip' ] );
	$GeoIp->Close( );
	
	// Format name
	$Player[ 'Nick' ] = HtmlEntities( $Player[ 'Nick' ] );
	$Name = $Steam[ 0 ];
	
	if( $Name == "<font color=\"darkpink\">Unknown</font>" )
		$Name = $Player[ 'Nick' ];
	else
		$Name = UTF8_Encode( $Name );
	
	if( IsUserVip( $SteamId ) )
		$Name .= " <img src=\"images/star.png\" alt=\"VIP\" style=\"vertical-align:middle\">";
?>
<div class="stats-top box">
<?php if( !$FromGame ) { ?>
	<div class="h2-right"><div class="info"><b><?php echo $Country[ 'name' ]; ?></b></div></div>
<?php } ?>
	<h2><img src="http://my-run.de/images/flags/<?php echo $Country[ 'code' ].".gif\" title=\"{$Country[ 'name' ]}"; ?>" alt="" style="vertical-align:middle"> <?php echo $Name; ?></h2>
	<div class="avatar">
		<img src="<?php echo $Steam[ 2 ]; ?>" alt="">
	</div>
	<ul class="stats">
		<li class="odd"><span class="label">Achievements:</span><span class="single"><b><?php echo $AchDone." / ".$AchTotal; ?></b> (<?php echo Round( ( $AchDone / $AchTotal ) * 100, 0 ); ?>%)</span></li>
		<li>			<span class="label">PlayTime:</span><span class="single"><b><?php echo GetPlayTime( $Player2[ 'PlayTime' ] ); ?></b> on record</span></li>
		<li class="odd"><span class="label">Total PlayTime:</span><span class="single"><b><?php echo GetPlayTime( $Player[ 'PlayTime' ] ); ?></b> on record</span></li>
		<li>			<span class="label">Last seen as:</span><span class="single"><?php echo SubStr( $Player[ 'Nick' ], 0, 29 ); ?></span></li>
		<li class="odd"><span class="label">Last seen:</span><span class="single"><?php echo Date( 'M j, o g:i:sa', $Player2[ 'LastJoin' ] ); ?></span></li>
		<li>			<span class="label">First seen:</span><span class="single"><?php echo Date( 'M j, o g:i:sa', $Player2[ 'FirstJoin' ] ); ?></span></li>
		<li class="odd"><span class="label">Connections:</span><span class="single"><?php echo $Player2[ 'Connects' ]; ?></span></li>
	</ul>
	<div class="clear"></div>
</div> <!-- /stats top -->

<div class="box stats-main">
	<div class="stats-nav box-nav">
		<div class="left">
			<ul>
<?php
	if( $_GET[ 'page' ] == 'stats' ) {
		include 'profile_stats.php';
		goto EndOfInclude;
	}
?>
				<li><a href="?server=<?php echo $Server."&steamid=".$SteamId; ?>" class="current">Achievements</a></li>
				<li><a href="?server=<?php echo $Server."&steamid=".$SteamId; ?>&page=stats">Records & Stats</a></li>
			</ul>
		</div>
	</div>
<?php
	ForEach( $AchievementsDone AS $Ach ) {
		$AchProgress = $Progress[ $Ach[ 'Id' ] ];
?>
	
	<div class="achiev">
		<div class="image"><img src="achievements/<?php echo $Ach[ 'Icon' ]; ?>.png" alt=""></div>
		<div class="txtHolder">
			<div class="right">Unlocked: <?php echo Date( 'M j, o g:ia', $AchProgress[ 'Date' ] ); ?></div>
			<div class="name"><?php echo HtmlEntities( $Ach[ 'Name' ] ); ?></div>
			<div class="desc"><?php echo EscapeString( $Ach[ 'Description' ] ); ?></div>
		</div>
	</div>
<?
	}
	
	echo "\n\n\t<br><br><br>\n";
	
	// NOT FINISHED ACHIEVEMENTS ->
	
	if( $AchDone < $AchTotal ) {
		ForEach( $Achievements AS $Ach ) {
			if( !$Ach[ 'Description' ][ 0 ] )
				continue;
			
			$Needed       = $Ach[ 'NeededToGain' ];
			$AchProgress  = isset( $Progress[ $Ach[ 'Id' ] ] ) ? $Progress[ $Ach[ 'Id' ] ][ 'Progress' ] : 0;
			$Bits         = isset( $Progress[ $Ach[ 'Id' ] ] ) ? $Progress[ $Ach[ 'Id' ] ][ 'Bits' ] : 0;
			$ShowProgress = (bool)( $Needed > 1 && $AchProgress > 0 );
			
			if( $Bits > 0 )
				$Bits = "<div class=\"right\">".GetAchievementBits( $Ach[ 'Id' ], $Bits )."</div>\n";
			else
				$Bits = "";
?>
	
	<div class="achiev">
		<div class="image disabled"><img src="achievements/<?php echo $Ach[ 'Icon' ]; ?>.png" alt=""></div>
		<div class="txtHolder<?php if( $ShowProgress ) echo " withProgress"; ?>">
			<?php echo $Bits; ?>
			<div class="name"><?php echo HtmlEntities( $Ach[ 'Name' ] ); ?></div>
			<div class="desc"><?php echo EscapeString( $Ach[ 'Description' ] ); ?></div>
<?php
	if( $ShowProgress ) {
		$ShowProgress = Round( ( $AchProgress / $Needed ) * 100, 0 );
		echo "				<div class=\"progresstxt\">".Number_Format($AchProgress)." / ".Number_Format($Needed)."</div>\n";
		echo "				<div class=\"progressbar\"><div style=\"width:{$ShowProgress}%;\"></div></div>\n";
	}
?>
		</div>
	</div>
<?php
		}
	}
?>
</div> <!-- /stats main -->
<?php
	EndOfInclude: { /* */ }
?>