<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
?>
<div class="box">
	<h2>Select a server please</h2>
	
	<div align="center">
	<table class="leaderboard" style="width:550px;">
		<thead>
			<tr>
				<th style="width:120px;">Server</th>
				<th style="width:90px;text-align:center;">Achievements</th>
				<th style="width:80px;text-align:center;">Players</th>
				<th style="width:100px;text-align:center;">Avg. PlayTime</th>
			</tr>
		</thead>
		<tbody>
<?php
	$Count = 1;
	
	ForEach( $Servers as $Name => $Data ) {
		$SqlQuery = MySql_Query( "SELECT COUNT(*) FROM `{$Data[ 'tbl_achievs' ]}`", $Sql ) or Die_Error( MySql_Error( ) );
		$Total    = MySql_Fetch_Row( $SqlQuery );
		$Achievs  = $Total[ 0 ];
		MySql_Free_Result( $SqlQuery );
		
		$SqlQuery = MySql_Query( "SELECT COUNT(*), AVG(`PlayTime`) FROM `{$Data[ 'tbl_players' ]}`", $Sql ) or Die_Error( MySql_Error( ) );
		$Total    = MySql_Fetch_Row( $SqlQuery );
		MySql_Free_Result( $SqlQuery );
		
		
?>
		<tr<?php if( $Count++ % 2 == 0 ) echo " class=\"odd\""; ?>>
				<td class="l-name"><a href="?server=<?php echo $Name; ?>"><?php echo $Data[ 'name' ]; ?></a></td>
				<td><?php echo $Achievs; ?></td>
				<td><?php echo $Total[ 0 ]; ?></td>
				<td><?php echo Number_Format( $Total[ 1 ], 1, '.', '' ); ?> hrs</td>
			</tr>
<?php
	}
	
	$SqlQuery = MySql_Query( "SELECT COUNT(*), AVG(`PlayTime`) FROM `{$config->table_global}`", $Sql ) or Die_Error( MySql_Error( ) );
	$Total    = MySql_Fetch_Row( $SqlQuery );
	MySql_Free_Result( $SqlQuery );
?>
		</tbody>
		<thead>
			<tr><th colspan="4" style="text-align:right;">
				Total players: <?php echo $Total[ 0 ]; ?> - 
				Averange global playtime: <?php echo Number_Format( $Total[ 1 ], 1, '.', '' ); ?> hrs
			</th></tr>
		</thead>
	</table>
	</div>
</div>