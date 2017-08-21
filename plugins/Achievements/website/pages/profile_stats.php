<?php
	if( !isset( $SteamId ) ) Exit;
	
	$SqlJlog = @MySql_Connect( $config->jlog_db_host, $config->jlog_db_user, $config->jlog_db_pass ) or Die_Error( MySql_Error( ) );
	@MySql_Select_Db( $config->jlog_db_name, $SqlJlog ) or Die_Error( MySql_Error( ) );
	
	// Find player in jlog db
	$SqlQuery = MySql_Query( "SELECT `uid` FROM `jlog_users` WHERE `steamid` = '{$SteamId}'", $SqlJlog ) or Die_Error( MySql_Error( ) );
	$Player = MySql_Fetch_Assoc( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
	
	if( !$Player[ 'uid' ] ) {
		$Message = "Requested player has been not found in our database. [3]";
		require 'error.php';
		goto EndOfInclude;
	}
	
	// Select most used nicks
	$Nicks    = Array( );
	$Kills    = Array( );
	$Kills2   = Array( );
	$SqlQuery = MySql_Query( "SELECT `nick`, `timesused` FROM `jlog_nick` WHERE `uid` = '{$Player[ 'uid' ]}' ORDER BY `timesused` DESC LIMIT 0, 5", $SqlJlog ) or Die_Error( MySql_Error( ) );
	while( $Nick = MySql_Fetch_Row( $SqlQuery ) ) {
		$Nicks[ ] = $Nick;
	}
	MySql_Free_Result( $SqlQuery );
	
	// Select victims
	$SqlQuery = MySql_Query( "SELECT COUNT(*) as a, cid, (SELECT `ignick` FROM `jlog_users` WHERE `uid` = `cid`) FROM `jlog_kills` WHERE `tid` != `cid` AND `tid` = '{$Player[ 'uid' ]}' GROUP BY `cid` ORDER BY `a` DESC LIMIT 0, 5", $SqlJlog ) or Die_Error( MySql_Error( ) );
	while( $Nick = MySql_Fetch_Row( $SqlQuery ) ) {
		$Kills[ ] = $Nick;
	}
	MySql_Free_Result( $SqlQuery );
	
	// Select killers
	$SqlQuery = MySql_Query( "SELECT COUNT(*) as a, tid, (SELECT `ignick` FROM `jlog_users` WHERE `uid` = `tid`) as b FROM `jlog_kills` WHERE `tid` != `cid` AND `cid` = '{$Player[ 'uid' ]}' GROUP BY `tid` ORDER BY `a` DESC LIMIT 0, 5", $SqlJlog ) or Die_Error( MySql_Error( ) );
	while( $Nick = MySql_Fetch_Row( $SqlQuery ) ) {
		$Kills2[ ] = $Nick;
	}
	MySql_Free_Result( $SqlQuery );
	
	// Select kills and deaths
	$SqlQuery = MySql_Query( "SELECT (SELECT COUNT(*) FROM `jlog_kills` WHERE `tid` != `cid` AND `tid` = '{$Player[ 'uid' ]}'),
	(SELECT COUNT(*) FROM `jlog_kills` WHERE `cid` = '{$Player[ 'uid' ]}'), (SELECT COUNT(*) FROM `jlog_kills` WHERE `tid` != `cid` AND `cid` = '{$Player[ 'uid' ]}')", $SqlJlog ) or Die_Error( MySql_Error( ) );
	$Stats = MySql_Fetch_Row( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
	
	$Stats[ 'KD' ] = Number_Format( ( $Stats[ 0 ] / $Stats[ 1 ] ), 2, '.', '' );
	$Stats[ 2 ]    = $Stats[ 1 ] - $Stats[ 2 ];
	
	MySql_Close( $SqlJlog );
?>
				<li><a href="?server=<?php echo $Server."&steamid=".$SteamId; ?>">Achievements</a></li>
				<li><a href="?server=<?php echo $Server."&steamid=".$SteamId; ?>&page=stats" class="current">Records & Stats</a></li>
			</ul>
		</div>
	</div>
	
	<div class="column-half">
		<h3><img src="images/demo.png" alt=""> Not so funny facts</h3>
		<table class="stats" width="100%">
			<tbody>
				<tr class="even">
					<td>Kills</td>
					<td><?php echo $Stats[ 0 ]; ?></td>
				</tr>
				<tr class="odd">
					<td>Deaths</td>
					<td><?php echo $Stats[ 1 ]; ?></td>
				</tr>
				<tr class="even">
					<td>Suicides</td>
					<td><?php echo $Stats[ 2 ]; ?></td>
				</tr>
				<tr class="odd">
					<td>K/D Ratio</td>
					<td><?php echo $Stats[ 'KD' ]; ?></td>
				</tr>
			</tbody>
		</table>
	</div>
	
	<div class="column-half last">
		<h3><img src="images/demo.png" alt=""> 5 Most used nicknames</h3>
		<table class="stats">
			<thead>
				<tr>
					<th style="width:40px;" class="header">#</th>
					<th style="width:235px;" class="header">Name</th>
					<th style="width:80px;" class="header">Times used</th>
				</tr>
			</thead>
			<tbody>
<?php
	$Count = 0;
	
	ForEach( $Nicks as $Nick ) {
		echo "				<tr class=\"".( ++$Count % 2 == 0 ? "even" : "odd" )."\">\n";
		echo "					<td><b>{$Count}.</b></td>\n";
		echo "					<td>".HtmlEntities( $Nick[ 0 ] )."</td>\n";
		echo "					<td><b>{$Nick[ 1 ]}</b></td>\n";
		echo "				</tr>\n";
	}
?>
			</tbody>
		</table>
	</div>
	
	<div class="clear" style="margin-bottom:30px;"></div>
	
	<div class="column-half">
		<h3><img src="images/demo.png" alt=""> Top Victims</h3>
		<table class="stats">
			<thead>
				<tr>
					<th style="width:40px;" class="header">#</th>
					<th style="width:235px;" class="header">Name</th>
					<th style="width:80px;" class="header">Times killed</th>
				</tr>
			</thead>
			<tbody>
<?php
	$Count = 0;
	
	ForEach( $Kills as $Nick ) {
		echo "				<tr class=\"".( ++$Count % 2 == 0 ? "even" : "odd" )."\">\n";
		echo "					<td><b>{$Count}.</b></td>\n";
		echo "					<td>".HtmlEntities( $Nick[ 2 ] )."</td>\n";
		echo "					<td><b>{$Nick[ 0 ]}</b></td>\n";
		echo "				</tr>\n";
	}
?>
			</tbody>
		</table>
	</div>
	
	<div class="column-half last">
		<h3><img src="images/demo.png" alt=""> Top Killers</h3>
		<table class="stats">
			<thead>
				<tr>
					<th style="width:40px;" class="header">#</th>
					<th style="width:235px;" class="header">Name</th>
					<th style="width:80px;" class="header">Times killed</th>
				</tr>
			</thead>
			<tbody>
<?php
	$Count = 0;
	
	ForEach( $Kills2 as $Nick ) {
		echo "				<tr class=\"".( ++$Count % 2 == 0 ? "even" : "odd" )."\">\n";
		echo "					<td><b>{$Count}.</b></td>\n";
		echo "					<td>".HtmlEntities( $Nick[ 2 ] )."</td>\n";
		echo "					<td><b>{$Nick[ 0 ]}</b></td>\n";
		echo "				</tr>\n";
	}
?>
			</tbody>
		</table>
	</div>
	
	<div class="clear" style="margin-bottom:9px;"></div>
</div> <!-- /stats main -->
<?php
	EndOfInclude: { /* */ }
?>