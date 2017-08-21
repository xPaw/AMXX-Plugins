<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	$SqlQuery     = MySql_Query( "SELECT * FROM `{$config->table_achievs}`", $Sql ) or Die_Error( MySql_Error( ) );
	$Achievements = Array( );
	
	while( $SqlResult = MySql_Fetch_Assoc( $SqlQuery ) ) {
		$sq = MySql_Query( "SELECT COUNT(*) FROM `{$config->table_progress}` WHERE `Achievement` = '{$SqlResult[ 'Id' ]}' AND `Progress` >= '{$SqlResult[ 'NeededToGain' ]}'", $Sql );
		$AchTotal = MySql_Fetch_Row( $sq );
		MySql_Free_Result( $sq );
		
		$SqlResult[ 'Count' ] = $AchTotal[ 0 ];
		$Achievements[ ] = $SqlResult;
	}
	
	MySql_Free_Result( $SqlQuery );
	
	$AchTotal = Count( $Achievements );
	
	if( !$AchTotal ) {
		$Message = "<b>{$config->server_name}</b> does not have any achievements at the moment.";
		require 'error.php';
		goto EndOfInclude;
	}
	
	// Get all players count
	$SqlQuery   = MySql_Query( "SELECT COUNT(*) FROM `{$config->table_players}`", $Sql ) or Die_Error( MySql_Error( ) );
	$AllPlayers = MySql_Fetch_Row( $SqlQuery );
	$AllPlayers = $AllPlayers[ 0 ];
	MySql_Free_Result( $SqlQuery );
	
	if( !$AllPlayers ) $AllPlayers = 1; // divide by zero fix
?>
<div class="box">
	<div class="h2-right"><div class="info"><strong>Total achievements:</strong> <?php echo $AchTotal; ?></div></div>
	<h2><?php echo $config->server_name; ?> Achievements</h2>
<?php
	UaSort( $Achievements, 'SortAchievements' );
	
	ForEach( $Achievements AS $Ach ) {
		$Percent = Round( ( $Ach[ 'Count' ] / $AllPlayers * 100 ), 1 );
?>
	
	<div class="achiev">
		<div class="image"><img src="achievements/<?php echo $Ach[ 'Icon' ]; ?>.png" alt=""></div>
		<div class="txtHolder">
			<div class="right"><?php echo $Percent;?>% (<?php echo $Ach[ 'Count' ]; ?>)</div>
			<div class="name"><?php echo HtmlEntities( $Ach[ 'Name' ] ); ?></div>
			<div class="desc"><?php echo EscapeString( $Ach[ 'Description' ] ); ?></div>
		</div>
	</div>
<?php
	}
	
	function SortAchievements( $a, $b ) {
		if( $a[ 'Count' ] == $b[ 'Count' ] )
			return ( $a[ 'Id' ] > $b[ 'Id' ] ) ? 1 : -1;
		
		return ( $a[ 'Count' ] < $b[ 'Count' ] ) ? 1 : -1;
	}
?>
</div>
<?php
	EndOfInclude: { /* */ }
?>