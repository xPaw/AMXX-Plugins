<?php
	$Timer_Start = MicroTime( True );
	
	define( 'IGNORE_SERVER', TRUE );
	define( 'LEGIT', TRUE );
	
	require 'config.inc.php';
	require 'geoip.inc.php';
	
	Die_Error( "Leaderboards are under construction." );
	
	require '_header.php';
?>
<div class="box">
	<div class="h2-right">
		<div class="info">
			<select id="selectServer">
				<option value="none">Edgebug</option>
				<option value="#">Hey</option>
				<option value="#">I</option>
				<option value="#">Love</option>
				<option value="#">You</option>
				<option value="#">Little</option>
				<option value="#">Wanker</option>
				<option value="#">:3</option>
			</select>
		</div>
	</div>
	<h2>Leaderboards</h2>
	
	<div align="center">
	<table class="leaderboard" style="width:550px;">
		<thead>
			<tr>
				<th style="width:30px;">Pos.</td>
				<th colspan="2">Player</th>
				<th style="width:90px;">Value</th>
			</tr>
		</thead>
		<tbody>
		
		</tbody>
		<thead>
			<tr>
				<th colspan="4" style="text-align:right;">Sup, bro?</th>
			</tr>
		</thead>
	</table>
	</div>
</div>
<?php
	MySql_Close( $Sql );
	
	require '_footer.php';
?>