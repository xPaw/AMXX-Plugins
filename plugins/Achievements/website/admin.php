<?php
	Exit;
	$Timer_Start = MicroTime( True );
	
	// Change me
	$Password = "changeme";
	
	if( Empty( $_SERVER[ 'PHP_AUTH_DIGEST' ] ) )
	{
		DigestAuth( );
	}
	
	$Data = DigestAuthParse( $_SERVER[ 'PHP_AUTH_DIGEST' ] );
	
	if( !$Data || $Data[ 'username' ] != 'admin' )
	{
		DigestAuth( );
	}
	
	// generate the valid response
	$A1 = MD5( $Data[ 'username' ] . ':' . $Data[ 'realm' ] . ':' . $Password );
	$A2 = MD5( $_SERVER[ 'REQUEST_METHOD' ] . ':' . $Data[ 'uri' ] );
	$ValidResponse = MD5( $A1 . ':' . $Data[ 'nonce' ] . ':' . $Data[ 'nc' ] . ':' . $Data[ 'cnonce' ] . ':' . $Data[ 'qop' ] . ':' . $A2 );
	
	if( $Data[ 'response' ] != $ValidResponse )
	{
		DigestAuth( );
	}
	
	define( 'LEGIT', 1 );
	
	include 'config.inc.php';
	
	require '_header.php';
?>
<div class="box">
	<h2>Edit Achievements</h2>
	
	<div align="center">
	<table class="leaderboard" style="width:600px;">
		<thead>
			<tr>
				<th style="width:70px;"></td>
				<th></th>
				<th>Name</th>
			</tr>
		</thead>
		<tbody>
<?php
	$SqlQuery = MySql_Query( "SELECT * FROM `{$config->table_achievs}`", $Sql ) or Die( MySql_Error( ) );
	$Count = 0;
	
	while( $Achievement = MySql_Fetch_Assoc( $SqlQuery ) ) {
		$ImgName = ( $Achievement[ 'Icon' ] == 'default' ) ? 'images/default.png' : ( "achievements/".$Achievement[ 'Icon' ].'.png' );
		
	//	echo "	<tr".( $Count % 2 == 0 ) ? echo " class=\"odd\"").">>\n";
		echo "	<tr>\n";
		echo "		<td class=\"l-country\"><img src=\"{$ImgName}\" width=\"64\" height=\"64\" border=\"0\" alt=\"\"></td>\n";
		echo "		<td><a href=\"?server={$Server}&id={$Achievement[ 'Id' ]}&act=edit\"><img src=\"images/edit.png\" alt=''></a> ";
		echo "<a href=\"?server={$Server}&id={$Achievement[ 'Id' ]}&act=delete\"><img src=\"images/delete.png\" alt=''></a></td>\n";
		echo "		<td>&nbsp;&nbsp;<strong>".HtmlEntities( $Achievement[ 'Name' ] )."</strong><br>&nbsp;&nbsp;".EscapeString( $Achievement[ 'Description' ] )."</td>\n";
		echo "	</tr>";
	}
	
	MySql_Free_Result( $SqlQuery );
?>
		</tbody>
	</table>
	</div>
</div>
<?php
	MySql_Close( $Sql );
	
	require '_footer.php';
?>
<!DOCTYPE HTML SYSTEM>
<html>
<head>
	<title>Achievements Admin Panel</title>
	<meta http-equiv="Content-type" content="text/html; charset=UTF-8">
	<link rel='stylesheet' href='lgsl_files/lgsl_style.css' type='text/css'>
</head>

<body>
<div align="center">
<h1>Achievements Admin Panel</h1>

<div id="navigation" style="height: 20px;">
	<ul><li>
		<a href="index.php?server=<?php echo $Server; ?>">Main page</a>
		<a href="?server=<?php echo $Server; ?>&act=manage_achvs">Manage Achievements</a>
		<a href="?server=<?php echo $Server; ?>&act=clean_cache" onClick="javascript:return confirm('Are you sure?')">Clear profiles cache</a>
		<a href="?server=<?php echo $Server; ?>&act=search">Search Players</a>
	</li></ul>
</div>
<?php
	$Action = isset( $_GET[ 'act' ] ) ? $_GET[ 'act' ] : '';
	
	if( $Action ) {
		if( $Action == 'clean_cache' )
		{
			$Dir = OpenDir( 'cache/' );
			
			if( $Dir ) {
				$Time = Time( );
				
				While( ( $File = ReadDir( $Dir ) ) !== FALSE ) {
					$File = "cache/".$File;
					if( FileType( $File ) != "dir" ) {
						$PathInfo = PathInfo( $File );
						
						if( StrToLower( $PathInfo[ "extension" ] ) == "xml" ) {
							$LastCache = $Time - FileMTime( $File );
							
							$Caches++;
							
							if( $LastCache > STEAM_CACHE_TIME ) {
								if( UnLink( $File ) )
									$Deleted++;
								else
									echo "Failed to delete <b>{$File}</b><br>\n";
							}
						}
					}
				}
				
				CloseDir( $Dir );
			}
			
			echo "<b>{$Caches}</b> total cached profiles.<br>\n<b>{$Deleted}</b> of them were deleted.<br><br>\n";
		}
		else if( $Action == 'edit' )
		{
			$Id = (int)$_GET[ 'id' ];
			
			$SqlQuery    = MySql_Query( "SELECT * FROM `{$Table_Achievs}` WHERE `Id` = '{$Id}'", $Sql ) or Die( MySql_Error( ) );
			$Achievement = MySql_Fetch_Assoc( $SqlQuery );
			
			if( !$Achievement[ 'Id' ] ) {
				MySql_Close( $Sql );
				
				Die( "Hacking attempt." ); // Later to make normal error printing out blah..
			}
			
			if( $_POST[ 'cancel_x' ] ) {
			//	MySql_Close( $Sql );
				
				echo "Cancel.";
				
			//	OB_Clean( );
			//	header( 'Location: '.GetAddress( ).'&act=manage_achvs' );
			}
			else if( $_POST[ 'edit_x' ] ) {
				$Desc = MySql_Real_Escape_String( $_POST[ 'achv_desc' ] );
				$Icon = MySql_Real_Escape_String( $_POST[ 'achv_image' ] );
				$NeededToGain = $_POST[ 'achv_need2gain' ];
				$ProgressModule = $_POST[ 'achv_progressmodule' ];
				
				MySql_Query( "UPDATE `{$Table_Achievs}` SET `Description` = '{$Desc}', `NeededToGain` = '{$NeededToGain}', `ProgressModule` = '{$ProgressModule}', `Icon` = '{$Icon}' WHERE `Id` = '{$Id}'", $Sql );
				
				echo "Done.";
			}
			
			echo "<h2>Editing achievement: ".HtmlEntities( $Achievement[ 'Name' ] )."</h2>\n";
			echo "<form method=\"POST\">\n";
			echo "<table cellspacing=\"0\" cellpadding=\"3px\">\n";
			echo "	<tr bgcolor=\"#7293B3\">\n";
			echo "		<th class=\"center\" style=\"min-width:200px;\" colspan=\"2\">&nbsp;</th>\n";
			echo "	</tr>\n";
			echo "	<tr>\n";
			echo "		<td style=\"text-align:left\" style=\"min-width:90px;\">Unique ID:</td>\n";
			echo "		<td style=\"text-align:left\"><b>{$Achievement[ 'Id' ]}</b></td>\n";
			echo "	</tr>\n";
			echo "	<tr bgcolor=\"#FFFFFF\">\n";
			echo "		<td style=\"text-align:left\">Name:</td>\n";
			echo "		<td style=\"text-align:left\"><b>".HtmlEntities( $Achievement[ 'Name' ] )."</b></td>\n";
			echo "	</tr>\n";
			echo "	<tr>\n";
			echo "		<td style=\"text-align:left\">Description:</td>\n";
			echo "		<td style=\"text-align:left\"><input type='text' name='achv_desc' value='".EscapeString( $Achievement[ 'Description' ] )."' size='20' maxlength='128'></td>\n";
			echo "	</tr>\n";
			echo "	<tr bgcolor=\"#FFFFFF\">\n";
			echo "		<td style=\"text-align:left\">Needed To Gain:</td>\n";
			echo "		<td style=\"text-align:left\"><input type='text' name='achv_need2gain' value='{$Achievement[ 'NeededToGain' ]}' size='5' maxlength='6'></td>\n";
			echo "	</tr>\n";
			echo "	<tr>\n";
			echo "		<td style=\"text-align:left\">Progress Module:</td>\n";
			echo "		<td style=\"text-align:left\"><input type='text' name='achv_progressmodule' value='{$Achievement[ 'ProgressModule' ]}' size='5' maxlength='6'></td>\n";
			echo "	</tr>\n";
			echo "	<tr bgcolor=\"#FFFFFF\">\n";
			echo "		<td style=\"text-align:left\">Image:</td>\n";
			echo "		<td style=\"text-align:left\"><input type='text' name='achv_image' value='{$Achievement[ 'Icon' ]}' size='20' maxlength='30'></td>\n";
			echo "	</tr>\n";
			echo "</table><br>\n";
			
			echo "<input type='image' src='images/badge_save.png' name='edit' onClick=\"javascript:return confirm('Are you sure?')\"> <input type='image' src='images/badge_cancel.png' name='cancel'>\n";
			echo "</form>\n";
			
			MySql_Free_Result( $SqlQuery );
		}
		else if( $Action == 'delete' )
		{
			$Id = $_GET[ 'id' ];
			
			echo "DELETING ZOMG!";
		}
		else if( $Action == 'manage_achvs' )
		{
			echo "<table cellspacing=\"0\" cellpadding=\"3px\">\n";
			
			$SqlQuery = MySql_Query( "SELECT * FROM `{$Table_Achievs}`", $Sql ) or Die( MySql_Error( ) );
			$Count = 0;
			
			while( $Achievement = MySql_Fetch_Assoc( $SqlQuery ) ) {
				$ImgName = ( $Achievement[ 'Icon' ] == 'default' ) ? 'images/default.png' : ( "achievements/".$Achievement[ 'Icon' ].'.png' );
				
				echo "	<tr".( ( ++$Count % 2 ) == 0 ? " bgcolor=\"#FFFFFF\"" : "" ).">\n";
				echo "		<td class=\"center\"><img src=\"{$ImgName}\" width=\"64\" height=\"64\" border=\"0\" alt=\"\"></td>\n";
				echo "		<td class=\"center\"><a href=\"?server={$Server}&id={$Achievement[ 'Id' ]}&act=edit\"><img src=\"images/edit.png\" alt=''></a> ";
				echo "<a href=\"?server={$Server}&id={$Achievement[ 'Id' ]}&act=delete\"><img src=\"images/delete.png\" alt=''></a></td>\n";
				echo "		<td>&nbsp;&nbsp;<strong>".HtmlEntities( $Achievement[ 'Name' ] )."</strong><br>&nbsp;&nbsp;".EscapeString( $Achievement[ 'Description' ] )."</td>\n";
				echo "	</tr>";
			}
			
			echo "</table>\n";
			
		//	MySql_Free_Result( $Achievement );
		}
		else if( $Action == 'search' )
		{
			echo "Not finished.";
		}
		else
		{
			echo "Welcome to the damn achievement admin panel!";
		}
	}
?>
<br><font color='#4587BF'><b>
Script written by xPaw<br>
</b></font>

</div>
</body>
</html>
<?php
	function DigestAuth( $Realm = "Protected area" )
	{
		$Nonce = MD5( $_SERVER[ 'REMOTE_ADDR' ] . UniqId( ) );
		
		Header( 'HTTP/1.1 401 Unauthorized' );
		Header( 'WWW-Authenticate: Digest realm="'.$Realm.'",qop="auth",nonce="'.$Nonce.'",opaque="'.MD5( $Realm ).'",algorithm=MD5' );
		Die( 'Not this time, chief.<br><a href="index.php">Go back?</a>' );
	}
	
	function DigestAuthParse( $String )
	{
		$Needed = Array( 'nonce'=>1, 'nc'=>1, 'cnonce'=>1, 'qop'=>1, 'username'=>1, 'uri'=>1, 'response'=>1 );
		$Data   = Array( );
		$Keys   = Implode( '|', Array_Keys( $Needed ) );
		
		Preg_Match_All( '@(' . $Keys . ')=(?:([\'"])([^\2]+?)\2|([^\s,]+))@', $String, $Matches, PREG_SET_ORDER );
		
		ForEach( $Matches as $m )
		{
			$Data[ $m[ 1 ] ] = $m[ 3 ] ? $m[ 3 ] : $m[ 4 ];
			Unset( $Needed[ $m[ 1 ] ] );
		}
		
		return $Needed ? false : $Data;
	}
?>