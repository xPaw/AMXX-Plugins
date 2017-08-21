<?php
class ServerInfo {
	/********************************************************************************
	 * Class written by xPaw <xpaw.crannk.de>
	 *
	 * Version: 1.1
	 * Last updated: 13th December 2010
	 * Reference: http://developer.valvesoftware.com/wiki/Server_queries
	 *
	 ********************************************************************************
	 * KNOWN BUGS / INFORMATION:
	 * - Invalid packets or GetRules() breaks answers from HLTV, need workaround
	 * - GetRules() looses the answer if GetPlayers() didn't return anything ...
	 *
	 * - If server is HLTV, bots == spectators (You can know that by comparing 'Dedicated' == 'p')
	 * - GetPlayers() for HLTV returns players on game server, and their time will be always 1 second
	 * - Source RCON uses TCP, probably will create new class for it ...
	 ********************************************************************************/
	
	var $resource;
	var $Connected;
	var $RconPassword;
	var $RconChallenge;
	var $Challenge;
	var $IsSource;
	var $RconId;
	
	function ServerInfo( ) {
		$this->Connected = false;
		$this->resource  = false;
	}
	
	function Connect( $Ip, $Port, $Password = "" ) {
		$this->Disconnect( );
		$this->RconPassword  = $Password;
		$this->RconChallenge = 0;
		$this->Challenge     = 0;
		$this->IsSource      = 0;
		$this->RconId        = 0;
		
		if( ( $this->resource = @FSockOpen( 'udp://' . GetHostByName( $Ip ), (int)$Port ) ) ) {
			$this->Connected = true;
			Socket_Set_TimeOut( $this->resource, 3 );
			
			if( !$this->Ping( ) )
				$this->Disconnect( );
		}
		
		return $this->Connected;
	}
	
	function Disconnect( ) {
		if( !$this->Connected )
			return false;
		
		FClose( $this->resource );
		
		$this->Connected = false;
	}
	
	private function Ping( ) {
		if( !$this->Connected )
			return false;
		
		$this->WriteData( 'i' );
		$Type = $this->ReadData( );
		
		if( $Type && $Type[ 4 ] == 'j' ) {
			$this->IsSource = ( $Type[ 5 ] == "0" );
			
			return true;
		}
		
		return false;
	}
	
	function GetPlayers( ) {
		if( !$this->Connected )
			return false;
		
		$this->WriteData( 'U' . $this->GetChallenge( ) );
		$Buffer = $this->ReadData( );
		
		if( $this->_CutByte( $Buffer, 5 ) != "\xFF\xFF\xFF\xFFD" )
			return false;
		
		$Count = Ord( $this->_CutByte( $Buffer ) );
		
		if( $Count <= 0 ) // No players
			return false;
		
		For( $i = 0; $i < $Count; $i++ ) {
			$this->_CutByte( $Buffer ); // player id, but always equals to 0 (tested on HL1)
			
			$Players[ $i ][ 'Name' ]    = $this->_CutString( $Buffer );
			$Players[ $i ][ 'Frags' ]   = $this->_UnPack( 'L', $this->_CutByte( $Buffer, 4 ) );
			$Time                       = (int)$this->_UnPack( 'f', $this->_CutByte( $Buffer, 4 ) );
			$Players[ $i ][ 'IntTime' ] = $Time;
			$Players[ $i ][ 'Time' ]    = GMDate( ( $Time > 3600 ? "H:i:s" : "i:s" ), $Time );
		}
		
		return $Players;
	}
	
	function GetInfo( ) {
		if( !$this->Connected )
			return false;
		
		$this->WriteData( 'TSource Engine Query' );
		$Buffer = $this->ReadData( );
		
		$Type = $this->_CutByte( $Buffer, 5 );
		$Type = $Type[ 4 ];
		
		if( $Type != 'I' ) {
			if( $Type == 'm' ) { // Old HL1 protocol, HLTV uses it
				$Server[ 'Address' ]    = $this->_CutString( $Buffer );
				$Server[ 'HostName' ]   = $this->_CutString( $Buffer );
				$Server[ 'Map' ]        = $this->_CutString( $Buffer );
				$Server[ 'ModDir' ]     = $this->_CutString( $Buffer );
				$Server[ 'ModDesc' ]    = $this->_CutString( $Buffer );
				$Server[ 'Players' ]    = Ord( $this->_CutByte( $Buffer ) );
				$Server[ 'MaxPlayers' ] = Ord( $this->_CutByte( $Buffer ) );
				$Server[ 'Protocol' ]   = Ord( $this->_CutByte( $Buffer ) );
				$Server[ 'Dedicated' ]  = $this->_CutByte( $Buffer );
				$Server[ 'Os' ]         = $this->_CutByte( $Buffer );
				$Server[ 'Password' ]   = Ord( $this->_CutByte( $Buffer ) );
				$Server[ 'IsMod' ]      = Ord( $this->_CutByte( $Buffer ) );
				
				if( $Server[ 'IsMod' ] ) { // Needs testing
					$Mod[ 'Url' ]        = $this->_CutString( $Buffer );
					$Mod[ 'Download' ]   = $this->_CutString( $Buffer );
					$this->_CutByte( $Buffer ); // NULL byte
					$Mod[ 'Version' ]    = Ord( $this->_CutByte( $Buffer ) );
					$Mod[ 'Size' ]       = Ord( $this->_CutByte( $Buffer ) );
					$Mod[ 'ServerSide' ] = Ord( $this->_CutByte( $Buffer ) );
					$Mod[ 'CustomDLL' ]  = Ord( $this->_CutByte( $Buffer ) );
				}
				
				$Server[ 'Secure' ]   = Ord( $this->_CutByte( $Buffer ) );
				$Server[ 'Bots' ]     = Ord( $this->_CutByte( $Buffer ) );
				
				if( isset( $Mod ) )
					$Server[ 'Mod' ] = $Mod;
				
				return $Server;
			}
			
			return false;
		}
		
		$Server[ 'Protocol' ]   = Ord( $this->_CutByte( $Buffer ) );
		$Server[ 'HostName' ]   = $this->_CutString( $Buffer );
		$Server[ 'Map' ]        = $this->_CutString( $Buffer );
		$Server[ 'ModDir' ]     = $this->_CutString( $Buffer );
		$Server[ 'ModDesc' ]    = $this->_CutString( $Buffer );
		$Server[ 'AppID' ]      = $this->_UnPack( 'S', $this->_CutByte( $Buffer, 2 ) );
		$Server[ 'Players' ]    = Ord( $this->_CutByte( $Buffer ) );
		$Server[ 'MaxPlayers' ] = Ord( $this->_CutByte( $Buffer ) );
		$Server[ 'Bots' ]       = Ord( $this->_CutByte( $Buffer ) );
		$Server[ 'Dedicated' ]  = $this->_CutByte( $Buffer );
		$Server[ 'Os' ]         = $this->_CutByte( $Buffer );
		$Server[ 'Password' ]   = Ord( $this->_CutByte( $Buffer ) );
		$Server[ 'Secure' ]     = Ord( $this->_CutByte( $Buffer ) );
		
		if( $Server[ 'AppID' ] == 2400 ) { // The Ship
			$Server[ 'GameMode' ]     = Ord( $this->_CutByte( $Buffer ) );
			$Server[ 'WitnessCount' ] = Ord( $this->_CutByte( $Buffer ) );
			$Server[ 'WitnessTime' ]  = Ord( $this->_CutByte( $Buffer ) );
		}
		
		$Server[ 'Version' ] = $this->_CutString( $Buffer );
		/*$Flags               = Ord( $this->_CutByte( $Buffer ) );
		
		if( $Flags & 0x80 ) // The server's game port # is included
			$Server[ 'EDF' ][ 'GamePort' ] = $this->_UnPack( 'S', $this->_CutByte( $Buffer, 2 ) );
		
		if( $Flags & 0x10 ) { // The server's SteamID is included
			$this->_CutByte( $Buffer, 8 ); // what the fuck is server's steamid
		}
		
		if( $Flags & 0x40 ) { // The spectator port # and then the spectator server name are included
			$Server[ 'EDF' ][ 'SpecPort' ] = $this->_UnPack( 'S', $this->_CutByte( $Buffer, 2 ) );
			$Server[ 'EDF' ][ 'SpecName' ] = $this->_CutString( $Buffer );
		}
		
		if( $Flags & 0x20 ) // The game tag data string for the server is included
			$Server[ 'EDF' ][ 'GameTags' ] = $this->_CutString( $Buffer );*/
		
		/*if( $Flags & 0x01 ) {
			The Steam Application ID again + several 0x00 bytes
			$this->_UnPack( 'S', $this->_CutByte( $Buffer, 2 ) );
		}*/
		
		return $Server;
	}
	
	function GetRules( ) {
		if( !$this->Connected )
			return false;
		
		$this->WriteData( 'V' . $this->GetChallenge( ) );
		$Buffer = $this->ReadData( );
		
		if( $this->_CutByte( $Buffer, 5 ) != "\xFF\xFF\xFF\xFFE" )
			return false;
		
		$Count = $this->_UnPack( 'S', $this->_CutByte( $Buffer, 2 ) );
		
		if( $Count <= 0 ) // Can this even happen?
			return false;
		
		$Rules = Array( );
		
		For( $i = 0; $i < $Count; $i++ )
			$Rules[ $this->_CutString( $Buffer ) ] = $this->_CutString( $Buffer );
		
		return $Rules;
	}
	
	function GetChallenge( $IsRcon = false ) {
		if( $IsRcon ) {
			if( $this->RconChallenge )
				return $this->RconChallenge;
			
			$this->WriteData( 'challenge rcon' );
			$Data = $this->ReadData( );
			
			if( $Data && $Data[ 4 ] != 'c' )
				return false;
			
			return ( $this->RconChallenge = RTrim( SubStr( $Data, 19 ) ) );
		}
		
		if( $this->Challenge )
			return $this->Challenge;
		
		$this->WriteData( "\x55\xFF\xFF\xFF\xFF" );
		$Data = $this->ReadData( );
		
		if( $Data && $Data[ 4 ] != 'A' ) {	
			if( $Data[ 4 ] == 'D' ) {
				echo "47 Protocol, DProto? What is it??<br>\n";
			}
			
			return false;
		}
		
		return $this->Challenge;
	}
	
	// ==========================================================
	// RCON
	function RconCareless( $Command ) {
		if( $this->IsSource || !$this->Connected || !$this->RconPassword || !$this->GetChallenge( true ) )
			return false;
		
		return $this->WriteData( 'rcon ' . $this->RconChallenge . ' "' . $this->RconPassword . '" ' . $Command );
	}
	
	function Rcon( $Command ) {
		if( $this->IsSource )
			return "Source rcon protocol is not supported.";
		
		if( !$this->Connected || !$this->RconPassword || !$this->GetChallenge( true ) )
			return false;
		
		$this->WriteData( 'rcon ' . $this->RconChallenge . ' "' . $this->RconPassword . '" ' . $Command );
		
		Socket_Set_TimeOut( $this->resource, 1 );
		
		$Buffer = "";
		
		while( $Type = FRead( $this->resource, 5 ) ) {
			if( Ord( $Type[ 0 ] ) == 254 ) // More than one datagram
				$Data = SubStr( $this->_ReadSplitPackets( 3 ), 4 );
			else {
				$Status = Socket_Get_Status( $this->resource );
				$Data   = FRead( $this->resource, $Status[ 'unread_bytes' ] );
			}
			
			$Buffer .= RTrim( $Data, "\0" );
		}
		
		Socket_Set_TimeOut( $this->resource, 3 );
		
		return $Buffer;
	}
	
	function RconGetPlayers( ) {
		$Buffer = $this->Rcon( "status" );
		
		if( !$Buffer )
			return false;
		
		$Lines  = Explode( "\n", $Buffer );
		$Active = Explode( " ", Trim( SubStr( $Lines[ 4 ], StrPos( $Lines[ 4 ], ":" ) + 1 ) ) );
		$Active = $Active[ 0 ];
		$Count  = 0;
		
		For( $i = 1; $i <= $Active; $i++ ) {
			$Line = Trim( $Lines[ $i + 6 ] );
			
			if( SubStr_Count( $Line, '#' ) <= 0 )
				break;
			
			// Name
			$Begin = StrPos( $Line, '"' ) + 1;
			$End   = StrrPos( $Line, '"' );
			$Players[ $Count ][ 'Name' ] = SubStr( $Line, $Begin, $End - $Begin );
			$Line  = Trim( SubStr( $Line, $End + 1 ) );
			
			$this->_CutStringRcon( $Line ); // ID
			$Players[ $Count ][ 'SteamId' ] = $this->_CutStringRcon( $Line );
			$Players[ $Count ][ 'Frags' ]   = $this->_CutStringRcon( $Line );
			$Players[ $Count ][ 'Time' ]    = $this->_CutStringRcon( $Line );
			$this->_CutStringRcon( $Line ); // Ping
			$this->_CutStringRcon( $Line ); // Loss
			
			$Time = Explode( ":", $Players[ $Count ][ 'Time' ] );
			
			if( $Time[ 2 ] )
				$Time = ( $Time[ 1 ] * 3600 ) + ( $Time[ 1 ] * 60 ) + $Time[ 2 ];
			else
				$Time = ( $Time[ 0 ] * 60 ) + $Time[ 1 ];
			
			$Players[ $Count ][ 'IntTime' ] = $Time;
			
			// Ip - strip port
			$Line                      = Explode( ':', $Line );
			$Players[ $Count ][ 'Ip' ] = $Line[ 0 ];
			
			$Count++;
		}
		
		return $Players;
	}
	
	// ==========================================================
	// DATA WORKERS
	private function WriteData( $Command ) {
		$Command = "\xFF\xFF\xFF\xFF" . $Command . "\x00";
		
		return !!( !FWrite( $this->resource, $Command, StrLen( $Command ) ) );
	}
	
	private function ReadData( ) {
		$Data = FRead( $this->resource, 1 );
		
		switch( Ord( $Data ) ) {
			case 255: // Just one datagram
				$Status = Socket_Get_Status( $this->resource );
				$Data  .= FRead( $this->resource, $Status[ 'unread_bytes' ] );
				
				break;
			
			case 254: // More than one datagram
				$Data = $this->_ReadSplitPackets( 7 );
				break;
		}
		
		if( $Data && $Data[ 4 ] == 'l' ) {
			$Temp = RTrim( SubStr( $Data, 5, 42 ) );
			
			if( $Temp == "You have been banned from this server." )
				return false;
		}
		
		return $Data;
	}
	
	private function _ReadSplitPackets( $BytesToRead ) {
		FRead( $this->resource, $BytesToRead );
		
		// The 9th byte tells us the datagram id and the total number of datagrams.
		$Data = fread($this->resource, 1);
		
		// We need to evaluate this in bits (so convert to binary)
		$bits = sprintf("%08b",ord($Data));
		
		// The low bits denote the total number of datagrams. (1-based)
		$count = bindec(substr($bits, -4));
		
		// The high bits denote the current datagram id.
		$x = bindec(substr($bits, 0, 4));
		
		// The rest is the datagram content.
		$status = socket_get_status($this->resource);
		$datagrams[$x] = fread($this->resource, $status["unread_bytes"]);
		
		// Repeat this process for each datagram.
		// We've already done the first one, so $i = 1 to start at the next.
		for ($i=1; $i<$count; $i++) {
			// Skip the header.
			fread($this->resource, 8);
			// Evaluate the 9th byte.
			$Data = fread($this->resource, 1);
			$x = bindec(substr(sprintf("%08b",ord($Data)), 0, 4));
			// Read the datagram content.
			$status = socket_get_status($this->resource);
			$datagrams[$x] = fread($this->resource, $status["unread_bytes"]);
		}
		// Stick all of the datagrams together and pretend that it wasn't split. :)
		$Data = "";
		for ($i=0; $i<$count; $i++) {
			$Data .= $datagrams[$i];
		}
		
		return $Data;
	}
	
	private function _CutByte( &$Buffer, $Length = 1 ) {
		$String = SubStr( $Buffer, 0, $Length );
		$Buffer = SubStr( $Buffer, $Length );
		
		return $String;
	}
	
	private function _CutString( &$Buffer ) {
		$Length = StrPos( $Buffer, "\x00" );
		
		if( $Length === FALSE ) { $Length = StrLen( $Buffer ); }
		
		$String = SubStr( $Buffer, 0, $Length );
		$Buffer = SubStr( $Buffer, $Length + 1 );
		
		return $String;
	}
	
	private function _CutStringRcon( &$Line ) {
		$End    = StrPos( $Line, " " );
		$String = SubStr( $Line, 0, $End );
		$Line   = Trim( SubStr( $Line, $End ) );
		
		return $String;
	}
	
	private function _UnPack( $Format, $Buffer ) {
		List( , $Buffer ) = UnPack( $Format, $Buffer );
		
		return $Buffer;
	}
}
?>