<?php
	Header( "Content-type: text/html; charset=UTF-8" );
	
	$Timer_Start = MicroTime( True );
	
	define( 'LEGIT', TRUE );
	
	require 'config.inc.php';
	require 'geoip.inc.php';
	
	// Get steamid
	$SteamId = $_GET[ 'steamid' ];
	if( isset( $SteamId ) )
		$SteamId = CheckSteamId( $SteamId );
	
	if( !Preg_Match( "/^STEAM_0:[0-1]:[0-9]{1,9}$/", $SteamId ) )
		UnSet( $SteamId );
	
	require '_header.php';
	
	if( isset( $SteamId ) )
		require 'pages/profile.php';
	else
		require 'pages/main.php';
	
	MySql_Close( $Sql );
	
	require '_footer.php';
?>