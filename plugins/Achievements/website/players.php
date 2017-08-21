<?php
	$Timer_Start = MicroTime( True );
	
	define( 'LEGIT', TRUE );
	
	require 'config.inc.php';
	require 'geoip.inc.php';
	
	require '_header.php';
	
	switch( $_GET[ 'page' ] ) {
		case 'top15':
			$Page = 'top15';
			break;
		
		default:
			$Page = 'players';
	}
?>
<div class="box">
	<div class="stats-nav box-nav">
		<div class="left">
			<ul>
				<li><a href="players.php?server=<?php echo $Server; ?>" class="current">Online Players</a></li>
				<li><a href="players.php?server=<?php echo $Server; ?>&page=top15">Top15</a></li>
			</ul>
		</div>
	</div>
	
<?php
	// switch( page )
	
	require 'pages/'.$Page.'.php';
	
	MySql_Close( $Sql );
	
	require '_footer.php';
?>