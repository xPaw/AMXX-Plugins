<?php
class GeoIP {
	private $GEOIP_COUNTRY_NAMES = Array(
		"", "Asia/Pacific Region", "Europe", "Andorra", "United Arab Emirates",
		"Afghanistan", "Antigua and Barbuda", "Anguilla", "Albania", "Armenia",
		"Netherlands Antilles", "Angola", "Antarctica", "Argentina", "American Samoa",
		"Austria", "Australia", "Aruba", "Azerbaijan", "Bosnia and Herzegovina",
		"Barbados", "Bangladesh", "Belgium", "Burkina Faso", "Bulgaria", "Bahrain",
		"Burundi", "Benin", "Bermuda", "Brunei Darussalam", "Bolivia", "Brazil",
		"Bahamas", "Bhutan", "Bouvet Island", "Botswana", "Belarus", "Belize",
		"Canada", "Cocos (Keeling) Islands", "Congo, The Democratic Republic of the",
		"Central African Republic", "Congo", "Switzerland", "Cote D'Ivoire", "Cook Islands",
		"Chile", "Cameroon", "China", "Colombia", "Costa Rica", "Cuba", "Cape Verde",
		"Christmas Island", "Cyprus", "Czech Republic", "Germany", "Djibouti",
		"Denmark", "Dominica", "Dominican Republic", "Algeria", "Ecuador", "Estonia",
		"Egypt", "Western Sahara", "Eritrea", "Spain", "Ethiopia", "Finland", "Fiji",
		"Falkland Islands (Malvinas)", "Micronesia, Federated States of", "Faroe Islands",
		"France", "France, Metropolitan", "Gabon", "United Kingdom",
		"Grenada", "Georgia", "French Guiana", "Ghana", "Gibraltar", "Greenland",
		"Gambia", "Guinea", "Guadeloupe", "Equatorial Guinea", "Greece",
		"South Georgia and the South Sandwich Islands", "Guatemala", "Guam", "Guinea-Bissau",
		"Guyana", "Hong Kong", "Heard Island and McDonald Islands", "Honduras",
		"Croatia", "Haiti", "Hungary", "Indonesia", "Ireland", "Israel", "India",
		"British Indian Ocean Territory", "Iraq", "Iran, Islamic Republic of",
		"Iceland", "Italy", "Jamaica", "Jordan", "Japan", "Kenya", "Kyrgyzstan",
		"Cambodia", "Kiribati", "Comoros", "Saint Kitts and Nevis", "Korea, Democratic People's Republic of",
		"Korea, Republic of", "Kuwait", "Cayman Islands",
		"Kazakhstan", "Lao People's Democratic Republic", "Lebanon", "Saint Lucia",
		"Liechtenstein", "Sri Lanka", "Liberia", "Lesotho", "Lithuania", "Luxembourg",
		"Latvia", "Libyan Arab Jamahiriya", "Morocco", "Monaco", "Moldova, Republic of",
		"Madagascar", "Marshall Islands", "Macedonia",
		"Mali", "Myanmar", "Mongolia", "Macau", "Northern Mariana Islands",
		"Martinique", "Mauritania", "Montserrat", "Malta", "Mauritius", "Maldives",
		"Malawi", "Mexico", "Malaysia", "Mozambique", "Namibia", "New Caledonia",
		"Niger", "Norfolk Island", "Nigeria", "Nicaragua", "Netherlands", "Norway",
		"Nepal", "Nauru", "Niue", "New Zealand", "Oman", "Panama", "Peru", "French Polynesia",
		"Papua New Guinea", "Philippines", "Pakistan", "Poland", "Saint Pierre and Miquelon",
		"Pitcairn Islands", "Puerto Rico", "Palestinian Territory",
		"Portugal", "Palau", "Paraguay", "Qatar", "Reunion", "Romania",
		"Russian Federation", "Rwanda", "Saudi Arabia", "Solomon Islands",
		"Seychelles", "Sudan", "Sweden", "Singapore", "Saint Helena", "Slovenia",
		"Svalbard and Jan Mayen", "Slovakia", "Sierra Leone", "San Marino", "Senegal",
		"Somalia", "Suriname", "Sao Tome and Principe", "El Salvador", "Syrian Arab Republic",
		"Swaziland", "Turks and Caicos Islands", "Chad", "French Southern Territories",
		"Togo", "Thailand", "Tajikistan", "Tokelau", "Turkmenistan",
		"Tunisia", "Tonga", "Timor-Leste", "Turkey", "Trinidad and Tobago", "Tuvalu",
		"Taiwan", "Tanzania, United Republic of", "Ukraine",
		"Uganda", "United States Minor Outlying Islands", "United States", "Uruguay",
		"Uzbekistan", "Holy See (Vatican City State)", "Saint Vincent and the Grenadines",
		"Venezuela", "Virgin Islands, British", "Virgin Islands, U.S.",
		"Vietnam", "Vanuatu", "Wallis and Futuna", "Samoa", "Yemen", "Mayotte",
		"Serbia", "South Africa", "Zambia", "Montenegro", "Zimbabwe",
		"Anonymous Proxy","Satellite Provider","Other",
		"Aland Islands","Guernsey","Isle of Man","Jersey","Saint Barthelemy","Saint Martin"
	);
	
	private $GEOIP_COUNTRY_CODES = Array(
		"",   "AP", "EU", "AD", "AE", "AF", "AG", "AI", "AL", "AM", "AN", "AO", "AQ",
		"AR", "AS", "AT", "AU", "AW", "AZ", "BA", "BB", "BD", "BE", "BF", "BG", "BH",
		"BI", "BJ", "BM", "BN", "BO", "BR", "BS", "BT", "BV", "BW", "BY", "BZ", "CA",
		"CC", "CD", "CF", "CG", "CH", "CI", "CK", "CL", "CM", "CN", "CO", "CR", "CU",
		"CV", "CX", "CY", "CZ", "DE", "DJ", "DK", "DM", "DO", "DZ", "EC", "EE", "EG",
		"EH", "ER", "ES", "ET", "FI", "FJ", "FK", "FM", "FO", "FR", "FX", "GA", "GB",
		"GD", "GE", "GF", "GH", "GI", "GL", "GM", "GN", "GP", "GQ", "GR", "GS", "GT",
		"GU", "GW", "GY", "HK", "HM", "HN", "HR", "HT", "HU", "ID", "IE", "IL", "IN",
		"IO", "IQ", "IR", "IS", "IT", "JM", "JO", "JP", "KE", "KG", "KH", "KI", "KM",
		"KN", "KP", "KR", "KW", "KY", "KZ", "LA", "LB", "LC", "LI", "LK", "LR", "LS",
		"LT", "LU", "LV", "LY", "MA", "MC", "MD", "MG", "MH", "MK", "ML", "MM", "MN",
		"MO", "MP", "MQ", "MR", "MS", "MT", "MU", "MV", "MW", "MX", "MY", "MZ", "NA",
		"NC", "NE", "NF", "NG", "NI", "NL", "NO", "NP", "NR", "NU", "NZ", "OM", "PA",
		"PE", "PF", "PG", "PH", "PK", "PL", "PM", "PN", "PR", "PS", "PT", "PW", "PY",
		"QA", "RE", "RO", "RU", "RW", "SA", "SB", "SC", "SD", "SE", "SG", "SH", "SI",
		"SJ", "SK", "SL", "SM", "SN", "SO", "SR", "ST", "SV", "SY", "SZ", "TC", "TD",
		"TF", "TG", "TH", "TJ", "TK", "TM", "TN", "TO", "TL", "TR", "TT", "TV", "TW",
		"TZ", "UA", "UG", "UM", "US", "UY", "UZ", "VA", "VC", "VE", "VG", "VI", "VN",
		"VU", "WF", "WS", "YE", "YT", "RS", "ZA", "ZM", "ME", "ZW", "A1", "A2", "O1",
		"AX", "GG", "IM", "JE", "BL", "MF"
	);
	
	private $File;
	private $Buffer;
	private $CachedMemory;
	
	function __construct( $File, $CachedMemory = false ) {
		$this->File = FOpen( $File, "rb" );
		$this->CachedMemory = !!$CachedMemory;
		
		if( $this->CachedMemory ) {
			$Stat = FStat( $this->File );
			$this->Buffer = FRead( $this->File, $Stat[ 'size' ] );
			$this->Close( ); // we don't need it anymore
		}
	}
	
	function __destruct( ) {
		$this->Close( );
	}
	
	function Close( ) {
		if( !$this->CachedMemory )
			@FClose( $this->File );
	}
	
	function Country( $Ip ) {
		if( !$this->File ) return 0;
		
		$Id = $this->_seek_country( Ip2Long( $Ip ) ) - 16776960;
		
		if( $Id <= 0 ) return Array( 'id' => 0, 'ip' => $Ip, 'code' => '', 'name' => '' );
		
		return Array( 'id' => $Id, 'ip' => $Ip,
			'code' => StrToLower( $this->GEOIP_COUNTRY_CODES[ $Id ] ),
			'name' => $this->GEOIP_COUNTRY_NAMES[ $Id ] );
	}
	
	private function _seek_country( $IpNum ) {
		$Offset = 0;
		
		For( $i = 31; $i >= 0; --$i ) {
			if( $this->CachedMemory ) {
				$Buffer = SubStr( $this->Buffer, 6 * $Offset, 6 );
			} else {
				if( FSeek( $this->File, 6 * $Offset, SEEK_SET ) )
					return 0;
				
				$Buffer = FRead( $this->File, 6 );
			}
			
			$New = Array( 0, 0 );
			
			For( $x = 0; $x < 2; ++$x )
				For( $z = 0; $z < 3; ++$z )
					$New[ $x ] += Ord( $Buffer[ 3 * $x + $z ] ) << ( $z * 8 );
			
			if( $IpNum & ( 1 << $i ) ) {
				if( $New[ 1 ] >= 16776960 )
					return $New[ 1 ];
				
				$Offset = $New[ 1 ];
			} else {
				if( $New[ 0 ] >= 16776960 )
					return $New[ 0 ];
				
				$Offset = $New[ 0 ];
			}
		}
		
		Trigger_Error( "Base corrupt?", E_USER_ERROR );
		
		return 0;
	}
}
?>
