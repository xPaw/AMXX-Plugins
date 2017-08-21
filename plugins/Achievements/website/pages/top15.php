<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	// Select achievements
	$SqlQuery     = MySql_Query( "SELECT Id, NeededToGain FROM `{$config->table_achievs}`", $Sql ) or Die_Error( MySql_Error( ) );
	$Achievements = Array( );
	
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) )
		$Achievements[ $SqlResult[ 'Id' ] ] = $SqlResult[ 'NeededToGain' ];
	
	MySql_Free_Result( $SqlQuery );
?>
	<div align="center">
	<table class="leaderboard" style="width:650px;">
		<thead>
			<tr>
				<th style="width:30px;">Pos.</td>
				<th colspan="2">Player</th>
				<th style="width:90px;">Played Time</th>
				<th style="width:90px;">Global Time</th>
				<th style="width:80px;">Unlocks</th>
			</tr>
		</thead>
		<tbody>
<?php
	// Select online players
	$GeoIp    = new GeoIp( $config->geoip_file );
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_players}` ORDER BY `PlayTime` DESC LIMIT 0, 25", $Sql ) or Die_Error( MySql_Error( ) );
	
	$Count = 1;
	$Time  = Time( );
	$AchTotal = Count( $Achievements );
	
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) ) {
		$SqlGlb = MySql_Query( "SELECT * FROM `{$config->table_global}` WHERE `Id` = '{$SqlResult[ 'Id' ]}'", $Sql ) or Die_Error( MySql_Error( ) );
		$Player = MySql_Fetch_Assoc( $SqlGlb );
		MySql_Free_Result( $SqlGlb );
		
		$AchPlayer = 0;
		$Country   = $GeoIp->Country( $Player[ 'Ip' ] );
		
		$SqlGlb = MySql_Query( "SELECT `Achievement`, `Progress` FROM `{$config->table_progress}` WHERE `Id` = '{$Player[ 'Id' ]}'", $Sql ) or Die( MySql_Error( ) );
		while( $Ach = MySql_Fetch_Assoc( $SqlGlb ) ) if( $Ach[ 'Progress' ] >= $Achievements[ $Ach[ 'Achievement' ] ] ) $AchPlayer++;
		MySql_Free_Result( $SqlGlb );
		
		$Name = HtmlEntities( $Player[ 'Nick' ] );
		
		if( IsUserVip( $Player[ 'SteamId' ] ) )
			$Name .= " <img src=\"images/star.png\" alt=\"\" style=\"vertical-align:middle\">";
?>
			<tr<?php if( $Count % 2 == 0 ) echo " class=\"odd\""; ?>>
				<td class="l-position"><?php echo $Count++; ?>.</td>
				<td class="l-country"><img src="http://my-run.de/images/flags/<?php echo $Country[ 'code' ].".gif\" title=\"{$Country[ 'name' ]}"; ?>" alt=""></td>
				<td class="l-name"><a href="index.php?server=<?php echo $Server."&steamid=".$Player[ 'SteamId' ]; ?>"><?php echo $Name; ?></a></td>
				<td><?php echo GetPlayTime( $SqlResult[ 'PlayTime' ] ); ?></td>
				<td><?php echo GetPlayTime( $Player[ 'PlayTime' ] ); ?></td>
				<td><?php echo $AchPlayer." / ".$AchTotal; ?></td>
			</tr>
<?php
	}
	
	MySql_Free_Result( $SqlQuery );
	$GeoIp->Close( );
	
	$SqlQuery = MySql_Query( "SELECT COUNT(*), AVG(`PlayTime`) FROM `{$config->table_players}`", $Sql ) or Die_Error( MySql_Error( ) );
	$Total    = MySql_Fetch_Row( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
?>
		</tbody>
		<thead>
			<tr><th colspan="6" style="text-align:right;">
				Total players on server: <?php echo $Total[ 0 ]; ?> - 
				Averange playtime: <?php echo Number_Format( $Total[ 1 ], 1, '.', '' ); ?> hrs
			</th></tr>
		</thead>
	</table>
	</div>
</div>