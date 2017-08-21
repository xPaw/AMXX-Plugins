<?php
	if( !$ItsPlayerz ) Exit;
	
	$Player = GetSteamNameAvatar( GetProfileId( $SteamId ) );
?>
	<div id="banner_img"><div style="text-align:center;margin-top: 25px;"><img src="<?php echo $Player[ 1 ]; ?>" alt=""></div></div>
	<div id="banner">
		<div id="banner_text"><?php echo $Player[ 0 ]; ?></div>
		<div id="navigation">
			<?php echo $Navigation; ?>
		</div>
	</div>
	
	<div class="title">Maps finished</div>
	<div class="content">
	<table cellspacing="1">
		<tr class="kzTable">
			<td style="width: 35px;">#</td>
			<td>Map</td>
			<td>Time</td>
			<td>Top</td>
			<td>Rank</td>
			<td style="text-align: center;">Weapon</td>
		</tr>
<?php
		$Count = 0;
		While( $KzRecord = MySql_Fetch_Assoc( $SqlResult ) ) {
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
			<td><b><?php echo ++$Count; ?>.</b></td>
			<td><a href="<?php echo $FolderPath; ?>?map=<?php echo $KzRecord[ 'Map' ]; ?>"><?php echo $KzRecord[ 'Map' ]; ?></a></td>
			<td><span class="kzTime"><?php echo $KzMinutes.':'.$KzSeconds; ?>.<span class="kzMs"><?php echo $KzMiliSeconds; ?></span></span></td>
			<td><?php echo ( $KzRecord[ 'Type' ] == 1 ? "<font color=\"red\">Nub15</font>" : "<font color=\"green\">Pro15</font>" ); ?></td>
			<td><?php echo $Rank[ 'b' ]; ?></td>
			<td style="text-align: center;"><img src="/files/img/weapons/<?php echo $KzRecord[ 'Weapon' ] ? $KzRecord[ 'Weapon' ] : 'unknown'; ?>.gif" alt=""></td>
		</tr>
<?php
		}
?>
	</table>
	</div>
<?php
	function GetSteamNameAvatar( $CommunityId ) {
		$Xml = @SimpleXML_Load_File( 'http://steamcommunity.com/profiles/'.$CommunityId.'?xml=1', 'SimpleXMLElement', LIBXML_NOCDATA );
		
		$Name = $Avatar = "";
		
		if( isset( $Xml->steamID64 ) && BcComp( $Xml->steamID64, '76561197960265728' ) == 1 ) {
			$Name   = $Xml->steamID;
			$Avatar = $Xml->avatarMedium;
		}
		
		return Array( $Name, $Avatar );
	}
	
	function GetProfileId( $SteamId ) {
		$Parts = Explode( ':', Str_Replace( 'STEAM_', '', $SteamId ) );
		
		return BcAdd( BcAdd( '76561197960265728', $Parts[ '1' ] ), BcMul( $Parts[ '2' ], '2' ) );
	}
?>