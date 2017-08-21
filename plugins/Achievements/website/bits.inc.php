<?php
	Defined( 'LEGIT' ) or Die( 'Boo' );
	
	function GetAchievementBits( $Id, $Bits )
	{
		global $Server;
		$Return = "";
		
		if( $Id == 35 && $Server == "hns" )
		{
			$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"CountJump\">";
			$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"LongJump\">";
			$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"BhopJump\">";
			
			return $Return;
		}
		
		if( $Server == "drun" )
		{
			switch( $Id ) {
				case 37: {
					$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_dgs\">";
					$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_luxus_n1\">";
					$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_bleak\">";
					Break;
				}
				case 38: {
					$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_darkside\">";
					$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_ijumping_beta7\">";
					$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_state3_winter\">";
					Break;
				}
				case 39: {
					$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_midnight_beta3\">";
					$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_nightmare\">";
					$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_4life_rmk\">";
					Break;
				}
				case 40: {
					$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_junbee_beta5\">";
					$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_hotel\">";
					$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_industry\">";
					Break;
				}
				case 45: {
					$Return  = "<img src=\"achievements/led".( ( 1 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_dojo\">";
					$Return .= "<img src=\"achievements/led".( ( 2 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_trap_canyon\">";
					$Return .= "<img src=\"achievements/led".( ( 4 & $Bits ) ? "green" : "red" ).".png\" alt=\"\" title=\"deathrun_burnzone\">";
					Break;
				}
			}
		}
		
		return $Return;
	}
?>