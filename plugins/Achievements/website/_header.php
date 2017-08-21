<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
//	debug( $_SERVER );
//	debug( "http://{$_SERVER[ 'HTTP_HOST' ]}{$_SERVER[ 'REQUEST_URI' ]}" );
//	debug( get_browser( null, true ) );
	
	if( !isset( $config ) ) {
		define( 'LEGIT', TRUE );
		define( 'IGNORE_SQL', TRUE );
		define( 'IGNORE_SERVER', TRUE );
		
		require_once 'config.inc.php';
	}
	
	if( !isset( $Servers ) ) $Servers = Array( ); //debugfix
	if( !$config->server_name ) $config->server_name = "Select a server";
	
//	$FromGame = $_SERVER[ 'HTTP_USER_AGENT' ] == 'Half-Life' ? true : false; // Doesn't work dammit
//	$FromGame = isset( $_GET[ 'r' ] );
	$FromGame = false;
	
	// search box ->
	// $(this).removeClass('inactive');
	
	if( !$FromGame ) {
?>
<!DOCTYPE html>
<?php } ?>
<html>
<head>
	<title>mY.RuN Achievements</title>
	<meta http-equiv="Content-Type" content="text/html;charset=utf-8">
	<link rel="stylesheet" type="text/css" href="css/reset.css">
	<link rel="stylesheet" type="text/css" href="css/style.css">
<?php if( $FromGame ) { ?>
	<!--[if lte IE 7]>
		<link rel="stylesheet" type="text/css" href="css/fuck_you_ie.css">
	<![endif]-->
<?php } else { ?>
	<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
<?php } ?>
</head>
<body>

<div id="top-container">
	<div id="top">
		<div class="left">
			<ul id="sv-nav">
				<li><a href="#" class="c" onclick="return false;"><?php echo $config->server_name; ?></a></li>
<?php
	if( isset( $SteamId ) )
		$Link = "&steamid=".$SteamId;
	
	ForEach( $Servers AS $Name => $Data )
		if( $Name != $Server )
			echo "\t\t\t\t<li><a href=\"index.php?server={$Name}{$Link}\">{$Data[ 'name' ]}</a></li>\n";
	
	if( isset( $Server ) )
		$Link = "?server=".$Server;
?>
			</ul>
		</div>
<?php if( !$FromGame ) { ?>
		<div class="right">
			<div class="searchBox">
				<form action="search.php" method="GET">
					<input type="hidden" name="server" value="<?php echo $Server; ?>">
					<input type="text" class="input-text inactive" name="search" value="<?php echo $config->search_default; ?>" maxlength="32" onfocus="if(this.value == this.defaultValue){this.value = '';}">
					<input type="image" class="input-image" src="images/arrow_right_24x24.png" alt="">
				</form>
			</div>
		</div>
<?php } ?>
	</div>
</div>

<div id="container">
	<div id="header">
		<a href="/" id="header-link"><img src="images/logo.png" alt=""></a>
		
		<div id="header-bottom">
			<div class="left">
				<ul id="site-nav">
					<li><a href="index.php<?php echo $Link; ?>">Home</a></li>
					<li><a href="players.php<?php echo $Link; ?>">Players</a></li>
					<li><a href="leaderboards.php<?php echo $Link; ?>">Leaderboards</a></li>
					<li><a href="http://my-run.de/">Forum</a></li>
				</ul>
			</div>
		</div>
	</div>
	
<div id="content">

<?php
	EndOfInclude: { /* */ }
?>