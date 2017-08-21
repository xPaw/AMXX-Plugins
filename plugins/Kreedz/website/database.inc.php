<?php
	$GeoIpPath  = "../files/GeoIP.dat";
	$Table      = "KreedzTop";
	$FolderPath = "/kztop/";
	
	$Navigation  = "			<a href=\"{$FolderPath}\">Map List</a>\n";
	
	define( "DB_HOST", ":/var/run/mysqld/mysqld.sock" );
	define( "DB_USER", "user" );
	define( "DB_PASS", "pass" );
	define( "DB_NAME", "name" );
	
	function OpenSql( $Second = 0 ) {
		$Sql = @MySql_Connect( DB_HOST, DB_USER, DB_PASS ) or Die( MySql_Error( ) );
		
		MySql_Select_Db( DB_NAME, $Sql ) or Die( MySql_Error( ) );
		
		return $Sql;
	}
?>