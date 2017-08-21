<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	require 'servers_query.inc.php';
	
	$SqlJlog = @MySql_Connect( $config->jlog_db_host, $config->jlog_db_user, $config->jlog_db_pass ) or Die_Error( MySql_Error( ) );
	@MySql_Select_Db( $config->jlog_db_name, $SqlJlog ) or Die_Error( MySql_Error( ) );
	
	// Take ip, port, rcon of this server
	$SqlQuery = MySql_Query( "SELECT ip,port,rcon FROM `jlog_server` WHERE `serverid` = '{$config->jlog_id}'", $SqlJlog ) or Die_Error( MySql_Error( ) );
	$ServerData = MySql_Fetch_Assoc( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
	
	MySql_Close( $SqlJlog );
	
	$Players = Array( 'dummy' => true );
	
	if( $ServerData[ 'ip' ] )
	{
		$ServerInfo = new ServerInfo( );
		if( $ServerInfo->Connect( $ServerData[ 'ip' ], $ServerData[ 'port' ], $ServerData[ 'rcon' ] ) )
		{
			$ServerData = $ServerInfo->RconGetPlayers( );
			$ServerInfo->Disconnect( );
			
			if( $ServerData )
				$Players = $ServerData;
		}
	}
	
	if( $Players[ 'dummy' ] )
	{
		$ServerData = Array( );
		$SqlQuery   = MySql_Query( "SELECT `Id` FROM `{$config->table_players}` WHERE `Status` = '1' ORDER BY `LastJoin` ASC", $Sql ) or Die_Error( MySql_Error( ) );
		
		while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) )
		{
			$ServerData[ ] = $SqlResult;
		}
		
		MySql_Free_Result( $SqlQuery );
		
		$Players = $ServerData;
	}
	
	// Select achievements
	$SqlQuery     = MySql_Query( "SELECT Id, NeededToGain FROM `{$config->table_achievs}`", $Sql ) or Die_Error( MySql_Error( ) );
	$Achievements = Array( );
	
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) )
		$Achievements[ $SqlResult[ 'Id' ] ] = $SqlResult[ 'NeededToGain' ];
	
	MySql_Free_Result( $SqlQuery );
?>
	<div align="center">
	<table class="leaderboard" style="width:550px;">
		<thead>
			<tr>
				<th style="width:30px;">Pos.</td>
				<th colspan="2">Player</th>
				<th style="width:90px;">Time</th>
				<th style="width:80px;">Unlocks</th>
			</tr>
		</thead>
		<tbody>
<?php
	// Select online players
	$GeoIp    = new GeoIp( $config->geoip_file );
//	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_players}` WHERE `Status` = '1' ORDER BY `LastJoin` ASC", $Sql ) or Die_Error( MySql_Error( ) );
	
	$Count = 1;
	$Time  = Time( );
	$AchTotal = Count( $Achievements );
	
//	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) ) {
	ForEach( $Players AS $Player2 ) {
		if( $Player2[ 'Id' ] )
			$SqlGlb = MySql_Query( "SELECT `Id`,({$Time}-`LastJoin`) as `Time`,`Ip`,`Nick`,`SteamId` FROM `{$config->table_global}` WHERE `Id` = '{$Player2[ 'Id' ]}' ORDER BY `LastJoin`", $Sql ) or Die_Error( MySql_Error( ) );
		else
			$SqlGlb = MySql_Query( "SELECT `Id`,({$Time}-`LastJoin`) as `Time`,`Ip`,`Nick`,`SteamId` FROM `{$config->table_global}` WHERE `SteamId` = '{$Player2[ 'SteamId' ]}' ORDER BY `LastJoin`", $Sql ) or Die_Error( MySql_Error( ) );
		
		$Player = MySql_Fetch_Assoc( $SqlGlb );
		MySql_Free_Result( $SqlGlb );
		
		if( $Player2[ 'SteamId' ] )
		{
			$PlayTime = $Player2[ 'Time' ];
			
			$Player[ 'SteamId' ] = $Player2[ 'SteamId' ];
			$Player[ 'Nick' ]    = $Player2[ 'Name' ];
		} else {
			$PlayTime = GetPlayTime( $Player[ 'Time' ], true );
		}
		
		$AchPlayer = 0;
		$Country   = $GeoIp->Country( $Player[ 'Ip' ] );
		$Name      = HtmlEntities( $Player[ 'Nick' ] );
		
		$SqlGlb = MySql_Query( "SELECT `Achievement`, `Progress` FROM `{$config->table_progress}` WHERE `Id` = '{$Player[ 'Id' ]}'", $Sql ) or Die( MySql_Error( ) );
		while( $Ach = MySql_Fetch_Assoc( $SqlGlb ) ) if( $Ach[ 'Progress' ] >= $Achievements[ $Ach[ 'Achievement' ] ] ) $AchPlayer++;
		MySql_Free_Result( $SqlGlb );
		
		if( IsUserVip( $Player[ 'SteamId' ] ) )
			$Name .= " <img src=\"images/star.png\" alt=\"\" style=\"vertical-align:middle\">";
?>
			<tr<?php if( $Count % 2 == 0 ) echo " class=\"odd\""; ?>>
				<td class="l-position"><?php echo $Count++; ?>.</td>
				<td class="l-country"><img src="http://my-run.de/images/flags/<?php echo $Country[ 'code' ].".gif\" title=\"{$Country[ 'name' ]}"; ?>" alt=""></td>
				<td class="l-name"><a href="index.php?server=<?php echo $Server."&steamid=".$Player[ 'SteamId' ]; ?>"><?php echo $Name; ?></a></td>
				<td><?php echo $PlayTime; ?></td>
				<td><?php echo $AchPlayer." / ".$AchTotal; ?></td>
			</tr>
<?php
	}
	
//	MySql_Free_Result( $SqlQuery );
	$GeoIp->Close( );
?>
		</tbody>
		<thead>
			<tr>
				<th colspan="5" style="text-align:right;">Players: <?php echo $Count - 1; ?></th>
			</tr>
		</thead>
	</table>
	</div>
</div>