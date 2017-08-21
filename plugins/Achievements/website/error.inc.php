<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	function debug( $Array ) {
		echo "<pre class=\"box\">";
		print_r( $Array );
		echo "</pre>";
	}
	
	function Die_Error( $Error ) {
		global $Timer_Start;
		global $Sql;
		@MySql_Close( $Sql );
		
		if( !$Timer_Start ) $Timer_Start = MicroTime( True );
		
		$Message = $Error;
		
		define( 'LEGIT', TRUE );
		
		require_once '_header.php';
		require 'pages/error.php';
		require '_footer.php';
		
		Exit;
	}
?>