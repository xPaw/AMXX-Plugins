<?php
	if( Preg_Match( "/^7656119[0-9]{10}$/", $_POST[ 'get_steam' ] ) ) {
		define( 'LEGIT', true );
		define( 'IGNORE_SQL', true );
		define( 'IGNORE_SERVER', true );
		
		include 'config.inc.php';
		
		$Xml = GetSteamData( $_POST[ 'get_steam' ], true );
		
		Die( $Xml->avatarMedium == "" ? 'images/avatar_not_found.jpg' : (String)$Xml->avatarMedium );
	}
	
	$Timer_Start = MicroTime( True );
	
	define( 'LEGIT', TRUE );
	
	require 'config.inc.php';
	require 'geoip.inc.php';
	
	require '_header.php';
	
	$Search = MySql_Real_Escape_String( SubStr( $_GET[ 'search' ], 0, 32 ) );
	
	if( StrLen( $Search ) < 3 )
		Die_Error( "Your request was too short, or you didn't enter anything." );
	
	$Search = CheckSteamId( $Search );
	
	// Perform search
	$Players  = Array( );
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_global}` WHERE `SteamId` LIKE '%{$Search}%' OR `Nick` LIKE '%{$Search}%' LIMIT 0, 100", $Sql ) or Die_Error( MySql_Error( ) );
	
	while( $Player = MySql_Fetch_Assoc( $SqlQuery ) ) {
		$Players[ ] = $Player;
	}
	
	MySql_Free_Result( $SqlQuery );
	
	if( !Count( $Players ) )
		Die_Error( "We couldn't find anyone." );
?>
<div class="box">
	<h2>Search Results for <?php echo HtmlEntities( $Search ); ?></h2>
	
	<div align="center">
	<table class="leaderboard" style="width:550px;">
		<thead>
			<tr>
				<th style="width:80px;">Avatar</td>
				<th colspan="2">Player</th>
				<th style="width:140px;">SteamId</th>
			</tr>
		</thead>
		<tbody>
<?php
	$GeoIp = new GeoIp( $config->geoip_file );
	
	ForEach( $Players AS $Player ) {
		
		
		$Country = $GeoIp->Country( $Player[ 'Ip' ] );
		$Name    = HtmlEntities( $Player[ 'Nick' ] );
		
		if( IsUserVip( $Player[ 'SteamId' ] ) )
			$Name .= " <img src=\"images/star.png\" alt=\"\" style=\"vertical-align:middle\">";
?>
			<tr<?php if( ++$Count % 2 == 0 ) echo " class=\"odd\""; ?>>
				<td class="l-avatar"><img src="images/avatar_not_found.jpg" id="av<?php echo $Count; ?>" alt=""></td>
				<td class="l-country"><img src="http://my-run.de/images/flags/<?php echo $Country[ 'code' ].".gif\" title=\"{$Country[ 'name' ]}"; ?>" alt=""></td>
				<td class="l-name"><a href="index.php?server=<?php echo $Server."&steamid=".$Player[ 'SteamId' ]; ?>"><?php echo $Name; ?></a></td>
				<td><?php echo $Player[ 'SteamId' ]; ?></td>
			</tr>
<?php
	}
	
	$GeoIp->Close( );
	MySql_Close( $Sql );
?>
		</tbody>
	</table>
	</div>
</div>

<?php if( !Empty( $Players ) ) { ?>
<script type="text/javascript" src="css/jquery.js"></script>
<script type="text/javascript">
	function GetSteamInfo( ID, CommunityID ) {
		$( '#av' + ID ).attr( 'src', 'images/ajax-loader.gif' );
		
		$.ajax( {
			type: "POST",
			url: "search.php",
			data: "get_steam=" + CommunityID,
			success: function( Result ) {
				$( '#av' + ID ).fadeOut( 'fast', function( ) {
					$( '#av' + ID ).attr( 'src', Result );
					$( '#av' + ID ).fadeIn( 'slow' );
				} );
			}
		} );
	}
	
<?php
	$Count = 0;
	ForEach( $Players AS $Player ) {
		echo "	GetSteamInfo( '".++$Count."', '".GetProfileId( $Player[ 'SteamId' ] )."' );\n";
	}
?>
</script>

<?php
	}
	
	require '_footer.php';
	
	EndOfInclude: { /* */ }
?>