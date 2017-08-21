<?php
	$Timer_Start = MicroTime( True );
	
	echo "<table cellspacing=\"0\" cellpadding=\"3px\">\n";
	echo "	<tr bgcolor=\"#7293B3\">\n";
	echo "		<th class=\"center\" style=\"min-width:20px;\">#</th>\n";
	echo "		<th style=\"min-width:130px;\">Map</th>\n";
	echo "		<th style=\"min-width:120px;\">Jumper</th>\n";
	echo "		<th class=\"center\" style=\"min-width:50px;\">Query</th>\n";
	echo "	</tr>\n";
	
	require 'database.inc.php';
	$Sql  = OpenSql( );
	$Maps = Array( );
	$Times = Array( );
	
	$File = @FOpen( 'http://xtreme-jumps.eu/demos.txt', 'r' );
	Stream_Set_TimeOut( $File, 5 );
	
	if( !$File ) {
		echo "	<tr>\n";
		echo "		<td class=\"center\" colspan=\"3\">Xtreme-Jumps.eu</td>\n";
		echo "		<td class=\"center\"><b><font color=\"red\">Failed</font></b></td>\n";
		echo "	</tr>\n";
	} else {
		while( $Line = FGets( $File ) ) {
			$Line = Trim( $Line );
			
			if( $Line == "Xtreme-Jumps.eu" )
				continue;
			
			$Record = Explode( ' ', $Line, 3 );
			
			$Nick   = MySql_Real_Escape_String( $Record[ 2 ], $Sql );
			$Pos    = StrrPos( $Nick, ' ', -2 );
			$Cc     = SubStr( $Nick, $Pos + 1 );
			$Nick   = SubStr( $Nick, 0, $Pos );
			$Time   = $Record[ 1 ];
			
			ParseRecord( $Record, $Nick, $Cc, $Time );
		}
		
		FClose( $File );
	}
	
	//$File = @FOpen( 'http://cosy-climbing.net/demos_info.php', 'r' );
	$File = @FOpen( 'http://cosy-climbing.net/demoz.txt', 'r' );
	Stream_Set_TimeOut( $File, 5 );
	
	if( !$File ) {
		echo "	<tr>\n";
		echo "		<td class=\"center\" colspan=\"3\">Cosy-Climbing.net</td>\n";
		echo "		<td class=\"center\"><b><font color=\"red\">Failed</font></b></td>\n";
		echo "	</tr>\n";
	} else {
		echo "	<tr>\n		<td class=\"center\" colspan=\"4\">&nbsp;</td>\n	</tr>\n";
		
		while( $Line = FGets( $File ) ) {
			$Line = Trim( $Line );
			
			if( $Line == "www.cosy-climbing.net" )
				continue;
			
			$Record = Explode( ' ', $Line, 3 );
			
			$Nick   = MySql_Real_Escape_String( $Record[ 2 ], $Sql );
			//$Cc     = 'n-a';
			$Pos    = StrrPos( $Nick, ' ', -2 );
			$Cc     = SubStr( $Nick, $Pos + 1 );
			$Nick   = SubStr( $Nick, 0, $Pos );
			$Time   = $Record[ 1 ];
			
			ParseRecord( $Record, $Nick, $Cc, $Time );
		}
		
		FClose( $File );
	}
	
	echo "</table>\n";
	
	MySql_Close( $Sql );
	
	$ShowTime = Number_Format( ( MicroTime( True ) - $Timer_Start ), 4, '.', '' );
	
	function ParseRecord( $Record, $Nick, $Cc, $Time ) {
		global $Count;
		global $Times;
		global $Maps;
		global $Sql;
		
		$Map    = MySql_Real_Escape_String( $Record[ 0 ], $Sql );
		$Pos    = StrrPos( $Map, '[' );
		$Route  = "";
		
		if( $Pos !== false ) {
			if( $Nick == "n/a" ) return;
			
			$Map2  = SubStr( $Map, 0, $Pos );
			$Route = SubStr( $Map, $Pos );
			$Map   = $Map2;
		}
		
		if( In_Array( $Map, $Maps ) && $Time > $Times[ $Map ] )
			return;
		
		$Maps[ ] = $Map;
		$Times[ $Map ] = $Time;
		
		$Query = MySql_Query( "INSERT INTO `KreedzTop` (`Map`, `Type`, `Name`, `Time`, `Country`, `SteamId`, `Ip`) VALUES ('{$Map}', '2', '{$Nick}', '{$Time}', '{$Cc}', 'WR', '{$Route}')
		ON DUPLICATE KEY UPDATE `Time` = '{$Time}', `Name` = '{$Nick}', `Country` = '{$Cc}', `Ip` = '{$Route}'", $Sql );
		$Query = $Query == 1 ? "<font color=\"green\">Ok</font>" : "<font color=\"red\">Failed</font>";
		
		if( $Route )
			$Route = " <b>" . $Route . "</b>";
		
		echo "	<tr".( ( ++$Count % 2 ) == 0 ? " bgcolor=\"#FFFFFF\"" : "" ).">\n";
		echo "		<td class=\"center\"><b>".$Count.".</b></td>\n";
		echo "		<td>\n";
		echo "			&nbsp;".$Map.$Route."\n";
		echo "		</td>\n";
		echo "		<td>\n";
		echo "			&nbsp;".$Nick."\n";
		echo "		</td>\n";
		echo "		<td class=\"center\">\n";
		echo "			<b>".$Query."</b>\n";
		echo "		</td>\n";
		echo "	</tr>\n";
	}
?>
<br><br><font color='#4587BF'><b>
Page generated in <?php echo $ShowTime; ?> seconds.<br>
Script written by xPaw<br>
</b></font>

</div>
</body>
</html>