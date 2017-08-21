<?php
	require_once 'error.inc.php';
	
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	BCScale( 0 ); // bugfix
	
	// Full path to your site, '/' at the end is required
	$config->full_url = "http://achievements.my-run.de/";
	
	// How long steam cache exists before refresing (seconds)
	$config->steam_cache_time = 1800;
	
	// Name of table where all players are stored (global)
	$config->table_global = "GlobalPlayers";
	
	// Path to GeoIP.dat file
	$config->geoip_file = "css/GeoIP.dat";
	
	// Default value in search box
	$config->search_default = "Search (Name/SteamId)";
	
	// Database connection data
//	$config->db_host = "gs.my-run.de";
	$config->db_host = "localhost";
	$config->db_user = "myrun";
	$config->db_name = "achievements";
	$config->db_pass = "pass";
	
	// JLOG Database connection data
	$config->jlog_db_host = "localhost";
	$config->jlog_db_user = "interface";
	$config->jlog_db_name = "cs";
	$config->jlog_db_pass = "pass";
	
	// All servers
	$Servers = Array(
		'drun' => Array(
			'name' => 'Deathrun',
			'name_stats' => 'mY.RuN Deathrun',
			'tbl_achievs' => 'Drun_Achievements',
			'tbl_players' => 'Drun_Players',
			'tbl_progress' => 'Drun_Progress',
			'golden_medal' => 'Nobel Prize',
			'jlog_id' => 145
		),
		'jail' => Array(
			'name' => 'JailBreak',
			'name_stats' => 'mY.RuN JailBreak',
			'tbl_achievs' => 'Jail_Achievements',
			'tbl_players' => 'Jail_Players',
			'tbl_progress' => 'Jail_Progress',
			'golden_medal' => 'Outlaw Prestige',
			'jlog_id' => 48
		),
		'dust2' => Array(
			'name' => 'Dust2',
			'name_stats' => 'mY.RuN Dust2 Public',
			'tbl_achievs' => 'Dust2_Achievements',
			'tbl_players' => 'Dust2_Players',
			'tbl_progress' => 'Dust2_Progress',
			'golden_medal' => 'Golden Medal',
			'jlog_id' => 64
		),
	/*	'bb' => Array(
			'name' => 'BaseBuilder',
			'name_stats' => 'mY.RuN BaseBuilder',
			'tbl_achievs' => 'Base_Achievements',
			'tbl_players' => 'Base_Players',
			'tbl_progress' => 'Base_Progress',
			'golden_medal' => 'Golden Medal',
			'jlog_id' => 52
		),	*/
		'knife' => Array(
			'name' => 'Knife',
			'name_stats' => 'mY.RuN Knife',
			'tbl_achievs' => 'Knife_Achievements',
			'tbl_players' => 'Knife_Players',
			'tbl_progress' => 'Knife_Progress',
			'golden_medal' => 'Golden Medal',
			'jlog_id' => 53
		),
		'hns' => Array(
			'name' => 'HideNSeek',
			'name_stats' => 'mY.RuN HideNSeek',
			'tbl_achievs' => 'Hns_Achievements',
			'tbl_players' => 'Hns_Players',
			'tbl_progress' => 'Hns_Progress',
			'golden_medal' => 'Golden Medal',
			'jlog_id' => 55
		)
	);
	
	if( !defined( 'IGNORE_SQL' ) ) {
		$Sql = @MySql_Connect( $config->db_host, $config->db_user, $config->db_pass ) or Die_Error( MySql_Error( ) );
		@MySql_Select_Db( $config->db_name, $Sql ) or Die_Error( MySql_Error( ) );
	}
	
	if( isset( $_GET[ 'server' ] ) && $_GET[ 'server' ] )
		$Server = HtmlEntities( $_GET[ 'server' ] );
	
	if( !defined( 'IGNORE_SERVER' ) ) {
		if( !isset( $Server ) ) {
			require '_header.php';
			require 'pages/stats.php';
			require '_footer.php';
			
			MySql_Close( $Sql );
			
			Exit( );
		} else {
			ForEach( $Servers AS $Name => $Data ) {
				if( $Name == $Server ) {
					$config->table_achievs  = $Data[ 'tbl_achievs' ];
					$config->table_players  = $Data[ 'tbl_players' ];
					$config->table_progress = $Data[ 'tbl_progress' ];
					$config->golden_achiev  = $Data[ 'golden_medal' ];
					$config->using_csstats  = isset( $Data[ 'csstats' ] ) ? true : false;
					$config->stats_name     = $Data[ 'name_stats' ];
					$config->server_name    = $Data[ 'name' ];
					$config->jlog_id        = $Data[ 'jlog_id' ];
					
					break;
				}
			}
			
			if( !isset( $config->stats_name ) )
				Die_Error( "Server \"<b>{$Server}</b>\" has been not found in our base.", $Sql );
		}
	}
	
	function IsUserVip( $SteamId ) {
		global $Vips;
		global $Sql;
		
		if( !isset( $Vips ) ) {
			$Vips      = Array( );
			$SqlResult = MySql_Query( "SELECT `SteamId`, `VipSince`, `Time` FROM `Vips`", $Sql );
			
			while( $Vip = MySql_Fetch_Row( $SqlResult ) ) {
				$Time = $Vip[ 2 ];
				
				if( $Time ) {
					$Time += $Vip[ 1 ];
					
					if( Time( ) >= $Time )
						$Time = -1;
				}
				
				if( $Time > -1 )
					$Vips[ ] = $Vip[ 0 ];
			}
			
			MySql_Free_Result( $SqlResult );
		}
		
		return (bool)In_Array( $SteamId, $Vips );
	}
	
	function GetProfileId( $SteamId ) {
		$Parts = Explode( ':', Str_Replace( 'STEAM_', '', $SteamId ) );
		
		return BcAdd( BcAdd( '76561197960265728', $Parts[ '1' ] ), BcMul( $Parts[ '2' ], '2' ) );
	}
	
	function CheckSteamId( $SteamId ) {
		if( Preg_Match( "/^7656119[0-9]{10}$/", $SteamId ) ) {
			$Server = ( SubStr( $SteamId, -1 ) % 2 == 0 ) ? 0 : 1;
			$AuthID = BcSub( $SteamId, '76561197960265728' );
			$AuthID = BcDiv( $AuthID, 2 );
			
			return 'STEAM_0:'.$Server.':'.$AuthID;
		}
		
		return $SteamId;
	}
	
	function GetProfileSteam( $CommunityId ) {
		$Xml    = GetSteamData( $CommunityId, false );
		$Online = 0;
		
		if( BcComp( $Xml->steamID64, '76561197960265728' ) == 1 ) {
			$Name       = HtmlEntities( $Xml->steamID );
			$Avatar     = $Xml->avatarMedium;
			$AvatarFull = $Xml->avatarFull;
		}
		
		if( $Name == "" ) $Name = "<font color=\"darkpink\">Unknown</font>";
		if( $Avatar == "" ) $Avatar = "images/avatar_not_found.jpg";
		if( $AvatarFull == "" ) $AvatarFull = "images/avatar_not_found2.jpg";
		
		return Array( $Name, $Avatar, $AvatarFull );
	}
	
	function GetSteamData( $CommunityId, $DontCache ) {
		$File = 'cache/'.$CommunityId.'.xml';
		
		$Exists = File_Exists( $File ) === TRUE;
		
		global $config;
		
		if( !( $Exists && FileMTime( $File ) > ( Time( ) - $config->steam_cache_time ) ) ) {
			$Link = 'http://steamcommunity.com/profiles/'.$CommunityId.'?xml=1';
			
			if( $DontCache && !$Exists ) {
				$File = $Link;
			} else {
				$Xml = GenerateSteamCache( $Link );
				
				@File_Put_Contents( $File, $Xml );
				
				//Copy( 'http://steamcommunity.com/profiles/'.$CommunityId.'?xml=1', $File );
			}
		}
		
		$Xml = @SimpleXML_Load_File( $File, 'SimpleXMLElement', LIBXML_NOCDATA );
		
		return $Xml;
	}
	
	function GenerateSteamCache( $Link ) {
		$Xml = @SimpleXML_Load_File( $Link, 'SimpleXMLElement', LIBXML_NOCDATA );
		
		$Xml2  = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?><profile>\n";
		$Xml2 .= "	<steamID64>".$Xml->steamID64."</steamID64>\n";
		$Xml2 .= "	<steamID><![CDATA[".$Xml->steamID."]]></steamID>\n";
		$Xml2 .= "	<visibilityState>".$Xml->visibilityState."</visibilityState>\n";
		$Xml2 .= "	<vacBanned>".$Xml->vacBanned."</vacBanned>\n";
		$Xml2 .= "	<isLimitedAccount>".$Xml->isLimitedAccount."</isLimitedAccount>\n";
		$Xml2 .= "	<customURL><![CDATA[".$Xml->customURL."]]></customURL>\n";
		$Xml2 .= "	<memberSince>".$Xml->memberSince."</memberSince>\n";
		$Xml2 .= "	<avatarIcon><![CDATA[".$Xml->avatarIcon."]]></avatarIcon>\n";
		$Xml2 .= "	<avatarMedium><![CDATA[".$Xml->avatarMedium."]]></avatarMedium>\n";
		$Xml2 .= "	<avatarFull><![CDATA[".$Xml->avatarFull."]]></avatarFull>\n";
		$Xml2 .= "</profile>\n";
		
		return $Xml2;
	}
	
	function GetPlayTime( $Time, $NotLikeSteam = false ) {
		if( $NotLikeSteam )
			return GMDate( ( $Time > 3600 ? "H:i:s" : "i:s" ), $Time );
		
		return Number_Format( ( $Time / 60 ), 1, '.', '' ) . ' hrs';
	}
	
	function EscapeString( $String ) {
		$Search  = Array( "&lt;b&gt;", "&lt;/b&gt;", "&lt;i&gt;", "&lt;/i&gt;", "&lt;s&gt;", "&lt;/s&gt;" );
		$Replace = Array( "<b>",       "</b>",       "<i>",       "</i>",       "<s>",       "</s>" );
		
		$String = HtmlEntities( $String );
		$String = Str_Replace( $Search, $Replace, $String );
		
		return $String;
	}
?>
