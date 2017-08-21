<?php
	require 'database.inc.php';
	require '../files/GeoIP.php';
	
	$Sql         = OpenSql( );
	$Timer_Start = MicroTime( True );
	$InGame      = isset( $_GET[ 'r' ] ) ? true : false;
	
	if( !$InGame ) {
?>
<!DOCTYPE html>
<?php } ?>
<html lang="en">
<head>
	<meta charset="utf-8">
	<link href="styles.css" rel="stylesheet" type="text/css">
<?php
	if( $InGame ) {
?>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="Pragma" content="no-cache">
	<meta http-equiv="Expires" content="-1">
	<!--[if IE]>
	<style type="text/css">
		#container { width: 620px }
		#banner { height: 126px }
		div.title, div.content { width: 103% }
	</style>
	<![endif]-->
<?php } ?>
<?php
	$GeoIp   = new GeoIp( $GeoIpPath );
	$SteamId = isset( $_GET[ 'steamid' ] ) ? filter_input( INPUT_GET, 'steamid', FILTER_SANITIZE_STRING ) : null;
	
	if( isset( $SteamId ) && Preg_Match( "/^STEAM_0:[0-1]:[0-9]{1,9}$/", $SteamId ) ) {
		$SqlResult = MySql_Query( "SELECT * FROM `{$Table}` WHERE SteamId='".$SteamId."'", $Sql );
		
		if( MySql_Num_Rows( $SqlResult ) ) {
?>
	<title>Kreedz Top15 :: <?php echo $SteamId; ?> :: by xPaw</title>
</head>

<body>
<div id="container">
<?php
			$ItsPlayerz = true;
			require 'player.php';
			
			$GeoIp->Close( );
			
			MySql_Free_Result( $SqlResult );
			MySql_Close( $Sql );
			
			Footer( $Timer_Start );
			
			Exit;
		}
	}
	
	// ADD HERE if anything with Steamid OR map failed, print an error div in cool style :)
	
	$MapName = isset( $_GET[ 'map' ] ) ? filter_input( INPUT_GET, 'map', FILTER_SANITIZE_STRING ) : null;
	
	if( isset( $MapName ) ) {
		$MapName   = MySql_Real_Escape_String( SubStr( $MapName, 0, 32 ) );
		$SqlResult = MySql_Query( "SELECT * FROM `{$Table}` WHERE Map='".$MapName."' AND Type='0' OR Map='".$MapName."' AND Type='2' ORDER BY Time, Date LIMIT 0,15", $Sql );
		
		if( !MySql_Num_Rows( $SqlResult ) ) $MapName = false;
		
	//	MySql_Free_Result( $SqlResult );
	}
	
	if( $MapName ) {
?>
	<title>Kreedz Top15 :: <?php echo $MapName; ?> :: by xPaw</title>
</head>

<body>
<div id="container">
<?php
	//	$SqlResult = MySql_Query( "SELECT * FROM `{$Table}` WHERE Map='".$MapName."' AND Type='0' OR Map='".$MapName."' AND Type='2' ORDER BY Time, Date LIMIT 0,16", $Sql );
		
		$W  = MySql_Query( "SELECT * FROM `{$Table}` WHERE Map='".$MapName."' AND Type='2'", $Sql );
		$WR = MySql_Fetch_Assoc( $W );
		MySql_Free_Result( $W );
		
		if( $WR[ 'Id' ] ) {
			$KzTime        = IntVal( $WR[ "Time" ] );
			$KzMinutes     = Floor( $KzTime / 60 );
			$KzSeconds     = $KzTime % 60;
			$KzMiliSeconds = Floor( ( $WR[ "Time" ] - $KzTime ) * 100 );
			
			if( $KzSeconds < 10 ) $KzSeconds = "0".$KzSeconds;
			if( $KzMiliSeconds < 10 ) $KzMiliSeconds = "0".$KzMiliSeconds;
			
			$World  = "			<div class=\"tsblTitle\">World Record:</div>\n";
			$World .= "			<div class=\"kzTime\"><td><img src=\"/files/img/p.gif\" width=\"16\" height=\"11\" class=\"flag flag-{$WR[ 'Country' ]}\" alt=\"\"></td> {$WR[ 'Name' ]}</div>\n";
			$World .= "			<div class=\"tsblTitle\">Time:</div>\n";
			$World .= "			<div class=\"kzTime\">{$KzMinutes}:{$KzSeconds}.<span class=\"kzMs\">{$KzMiliSeconds}</span></div>\n";
			
			if( $WR[ 'Ip' ] ) {
				$World .= "			<div class=\"tsblTitle\">Route:</div>\n";
				$World .= "			<div class=\"kzTime\">{$WR[ 'Ip' ]}</div>\n";
			}
		} else {
			$World  = "			<div class=\"tsblTitle\">World Record:</div>\n";
			$World .= "			<div class=\"kzTime\">No record found.</div>\n";
		}
?>
	<div id="banner_img"><img width="160" height="120" src="/files/maps/<?php echo $MapName; ?>.jpg" alt="<?php echo $MapName; ?>"></div>
	<div id="banner">
		<div id="banner_text"><?php echo $MapName; ?></div>
		<div id="banner_subtext">
			<?php echo $World; ?>
		</div>
		<div id="navigation">
			<?php echo $Navigation; ?>
		</div>
	</div>
	
	<div class="title">Pro15</div>
	<div class="content">
	<table cellspacing="1">
		<tr class="kzTable">
			<td style="width: 35px;">#</td>
			<td style="width: 20px;">&nbsp;</td>
			<td>Jumper</td>
			<td>Time</td>
			<td style="text-align: center;">Weapon</td>
		</tr>
<?php
		$Count = 0;
		While( $KzRecord = MySql_Fetch_Assoc( $SqlResult ) ) {
			if( $KzRecord[ 'Country' ] == "n-a" ) {
				$Country = $GeoIp->Country( $KzRecord[ 'Ip' ] );
			} else {
				$Country[ 'code' ] = $KzRecord[ 'Country' ];
				$Country[ 'name' ] = "";
			}
			
			$WR            = ( $KzRecord[ 'Type' ] == 2 );
			$Rank          = $WR ? "WR" : ++$Count.".";
			$KzTime        = IntVal( $KzRecord[ "Time" ] );
			$KzMinutes     = Floor( $KzTime / 60 );
			$KzSeconds     = $KzTime % 60;
			$KzMiliSeconds = Floor( ( $KzRecord[ "Time" ] - $KzTime ) * 100 );
			
			if( $KzSeconds < 10 ) $KzSeconds = "0".$KzSeconds;
			if( $KzMiliSeconds < 10 ) $KzMiliSeconds = "0".$KzMiliSeconds;
?>
		<tr>
			<td><b><?php echo $Rank; ?></b></td>
			<td><img src="/files/img/p.gif" width="16" height="11" class="flag flag-<?php echo $Country[ 'code' ]; ?>" title="<?php echo $Country[ 'name' ]; ?>" alt=""></td>
			<td><a href="?steamid=<?php echo $KzRecord[ 'SteamId' ]; ?>"><b><?php echo Get_Name( $KzRecord[ 'Name' ] ); ?></b></a></td>
			<td><span class="kzTime"><?php echo $KzMinutes.':'.$KzSeconds; ?>.<span class="kzMs"><?php echo $KzMiliSeconds; ?></span></span></td>
			<td style="text-align: center;"><img src="/files/img/weapons/<?php echo $KzRecord[ 'Weapon' ] ? $KzRecord[ 'Weapon' ] : 'unknown'; ?>.gif" alt=""></td>
		</tr>
<?php
		}
		
		MySql_Free_Result( $SqlResult );
		
		if( !$Count && !$WR )
			echo "		<tr>\n			<td style=\"text-align: center;\" colspan=\"5\"><b>No records found.</b></td>\n		</tr>\n";
?>
	</table>
	</div>

	<div class="title">Nub15</div>
	<div class="content">
	<table cellspacing="1">
		<tr class="kzTable">
			<td style="width: 35px;">#</td>
			<td style="width: 20px;">&nbsp;</td>
			<td>Jumper</td>
			<td>Time</td>
			<td>Cps</td>
			<td>Gcs</td>
			<td style="text-align: center;">Weapon</td>
		</tr>
<?php
		$SqlResult = MySql_Query( "SELECT * FROM `{$Table}` WHERE Map='".$MapName."' AND Type='1' ORDER BY Time, Date LIMIT 0,15", $Sql );
		
		$Count = 0;
		While( $KzRecord = MySql_Fetch_Assoc( $SqlResult ) ) {
			if( $KzRecord[ 'Country' ] == "n-a" ) {
				$Country = $GeoIp->Country( $KzRecord[ 'Ip' ] );
			} else {
				$Country[ 'code' ] = $KzRecord[ 'Country' ];
				$Country[ 'name' ] = "";
			}
			
			$WR            = ( $KzRecord[ 'Type' ] == 2 );
			$Rank          = $WR ? "WR" : ++$Count.".";
			$KzTime        = IntVal( $KzRecord[ "Time" ] );
			$KzMinutes     = Floor( $KzTime / 60 );
			$KzSeconds     = $KzTime % 60;
			$KzMiliSeconds = Floor( ( $KzRecord[ "Time" ] - $KzTime ) * 100 );
			
			if( $KzSeconds < 10 ) $KzSeconds = "0".$KzSeconds;
			if( $KzMiliSeconds < 10 ) $KzMiliSeconds = "0".$KzMiliSeconds;
?>
		<tr>
			<td><b><?php echo $Rank; ?></b></td>
			<td><img src="/files/img/p.gif" width="16" height="11" class="flag flag-<?php echo $Country[ 'code' ]; ?>" title="<?php echo $Country[ 'name' ]; ?>" alt=""></td>
			<td><a href="?steamid=<?php echo $KzRecord[ 'SteamId' ]; ?>"><b><?php echo Get_Name( $KzRecord[ 'Name' ] ); ?></b></a></td>
			<td><span class="kzTime"><?php echo $KzMinutes.':'.$KzSeconds; ?>.<span class="kzMs"><?php echo $KzMiliSeconds; ?></span></span></td>
			<td><?php echo $KzRecord[ 'Cps' ]; ?></td>
			<td><?php echo $KzRecord[ 'Gcs' ]; ?></td>
			<td style="text-align: center;"><img src="/files/img/weapons/<?php echo $KzRecord[ 'Weapon' ] ? $KzRecord[ 'Weapon' ] : 'unknown'; ?>.gif" alt=""></td>
		</tr>
<?php
		}
		
		MySql_Free_Result( $SqlResult );
		
		if( !$Count )
			echo "		<tr>\n			<td style=\"text-align: center;\" colspan=\"7\"><b>No records found.</b></td>\n		</tr>\n";
?>
	</table>
	</div>
<?php
	} else {
?>
	<title>Kreedz Top15 :: Maps :: by xPaw</title>
</head>

<body>
<div id="container">
	<div class="title">Latest Kreedz Top Entries</div>
	<div class="content">
	<table cellspacing="1">
		<tr class="kzTable">
			<td>&nbsp;</td>
			<td>Jumper</td>
			<td>Map</td>
			<td>Time</td>
			<td>Top</td>
			<td>Rank</td>
			<td style="text-align: center;">Weapon</td>
		</tr>
<?php
	$SqlResult = MySql_Query( "SELECT * FROM `{$Table}` WHERE `Type` < 2 ORDER BY `Date` DESC LIMIT 5", $Sql );
	
	While( $KzRecord = MySql_Fetch_Assoc( $SqlResult ) ) {
		if( $KzRecord[ 'Country' ] == "n-a" ) {
			$Country = $GeoIp->Country( $KzRecord[ 'Ip' ] );
		} else {
			$Country[ 'code' ] = $KzRecord[ 'Country' ];
			$Country[ 'name' ] = "";
		}
		
		$KzTime        = IntVal( $KzRecord[ "Time" ] );
		$KzMinutes     = Floor( $KzTime / 60 );
		$KzSeconds     = $KzTime % 60;
		$KzMiliSeconds = Floor( ( $KzRecord[ "Time" ] - $KzTime ) * 100 );
		
		if( $KzSeconds < 10 ) $KzSeconds = "0".$KzSeconds;
		if( $KzMiliSeconds < 10 ) $KzMiliSeconds = "0".$KzMiliSeconds;
		
		$RankS = MySql_Query( "SELECT Time as a, (SELECT count(Time)+1 from {$Table} where Time<a AND Map='{$KzRecord[ 'Map' ]}' AND Type={$KzRecord[ 'Type' ]} ) as b, SteamId from {$Table} WHERE SteamId='{$KzRecord[ 'SteamId' ]}' AND Map='{$KzRecord[ 'Map' ]}' AND Type={$KzRecord[ 'Type' ]}", $Sql );
		$Rank  = MySql_Fetch_Assoc( $RankS );
		MySql_Free_Result( $RankS );
?>
		<tr>
			<td><img src="/files/img/p.gif" width="16" height="11" class="flag flag-<?php echo $Country[ 'code' ]; ?>" title="<?php echo $Country[ 'name' ]; ?>" alt=""></td>
			<td><a href="?steamid=<?php echo $KzRecord[ 'SteamId' ]; ?>"><b><?php echo Get_Name( $KzRecord[ 'Name' ] ); ?></b></a></td>
			<td><a href="?map=<?php echo $KzRecord[ 'Map' ]; ?>"><?php echo $KzRecord[ 'Map' ]; ?></a></td>
			<td><span class="kzTime"><?php echo $KzMinutes.':'.$KzSeconds; ?>.<span class="kzMs"><?php echo $KzMiliSeconds; ?></span></span></td>
			<td><?php echo ( $KzRecord[ 'Type' ] == 1 ? "<font color=\"red\">Nub15</font>" : "<font color=\"green\">Pro15</font>" ); ?></td>
			<td><?php echo $Rank[ 'b' ]; ?></td>
			<td style="text-align: center;"><img src="/files/img/weapons/<?php echo $KzRecord[ 'Weapon' ] ? $KzRecord[ 'Weapon' ] : 'unknown'; ?>.gif" alt=""></td>
		</tr>
<?php
	}
	
	MySql_Free_Result( $SqlResult );
?>
	</table>
	</div>
	
	<div class="title">Maps</div>
	<div class="content">
	<table cellspacing="1">
		<tr class="kzTable">
			<td>#</td>
			<td>Map</td>
			<td>&nbsp;</td>
			<td>Leet Jumper</td>
			<td>Time</td>
			<td>Date</td>
		</tr>
<?php
		$SqlResult = MySql_Query( "SELECT * FROM ( SELECT * FROM `{$Table}` WHERE `Type` < 2 ORDER BY `Time` ) as a GROUP BY `Map` ORDER BY `Map`", $Sql );
		$Count = 0;
		
		While( $KzRecord = MySql_Fetch_Assoc( $SqlResult ) ) {
			if( $KzRecord[ 'Country' ] == "n-a" ) {
				$Country = $GeoIp->Country( $KzRecord[ 'Ip' ] );
			} else {
				$Country[ 'code' ] = $KzRecord[ 'Country' ];
				$Country[ 'name' ] = "";
			}
			
			$KzTime        = IntVal( $KzRecord[ "Time" ] );
			$KzMinutes     = Floor( $KzTime / 60 );
			$KzSeconds     = $KzTime % 60;
			$KzMiliSeconds = Floor( ( $KzRecord[ "Time" ] - $KzTime ) * 100 );
			
			if( $KzSeconds < 10 ) $KzSeconds = "0".$KzSeconds;
			if( $KzMiliSeconds < 10 ) $KzMiliSeconds = "0".$KzMiliSeconds;
?>
		<tr>
			<td><b><?php echo ++$Count; ?>.</b></td>
			<td><a href="?map=<?php echo $KzRecord[ 'Map' ]; ?>"><?php echo $KzRecord[ 'Map' ]; ?></a></td>
<?php
			if( $KzRecord[ 'Type' ] ) {
				echo "<td colspan=\"4\">&nbsp;</td>\n";
			} else {
?>
			<td><img src="/files/img/p.gif" width="16" height="11" class="flag flag-<?php echo $Country[ 'code' ]; ?>" title="<?php echo $Country[ 'name' ]; ?>" alt=""></td>
			<td><a href="?steamid=<?php echo $KzRecord[ 'SteamId' ]; ?>"><b><?php echo Get_Name( $KzRecord[ 'Name' ] ); ?></b></a></td>
			<td><span class="kzTime"><?php echo $KzMinutes.':'.$KzSeconds; ?>.<span class="kzMs"><?php echo $KzMiliSeconds; ?></span></span></td>
			<td><?php echo Get_Date( $KzRecord[ 'Date' ] ); ?></td>
		</tr>
<?php
			}
		}
?>
	</table>
	</div>
<?php
		MySql_Free_Result( $SqlResult );
	}
	
	$GeoIp->Close( );
	MySql_Close( $Sql );
	
	Footer( $Timer_Start );
	
	function Get_Date( $TimeStamp ) {
		return StrFTime( "%d-%m-%Y - %H:%M:%S", $TimeStamp );
	}
	
	function Get_Name( $Name ) {
		return HtmlEntities( SubStr( $Name, 0, 20 ) );
	}
	
	function Footer( $Timer_Start ) {
		$ShowTime = Number_Format( ( MicroTime( True ) - $Timer_Start ), 4, '.', '' );
?>
	
	<div id="footer">
		Page generated in <span class="kzTime"><?php echo $ShowTime; ?></span> seconds.<br>
		Kreedz Top &copy; 2011-2012 by <a href="http://xpaw.ru">xPaw</a>.<br>
	</div>
</div>
</body>
</html>
<?php
	}
?>