CREATE TABLE IF NOT EXISTS `KreedzTop` (
  `Id` int(11) NOT NULL,
  `Map` varchar(32) NOT NULL DEFAULT '',
  `Type` int(2) NOT NULL DEFAULT '0',
  `Name` varchar(32) NOT NULL DEFAULT '',
  `SteamId` varchar(26) NOT NULL DEFAULT '',
  `Time` float unsigned NOT NULL DEFAULT '0',
  `Ip` varchar(16) NOT NULL DEFAULT '',
  `Country` varchar(3) NOT NULL DEFAULT 'n-a',
  `Date` int(20) NOT NULL DEFAULT '0',
  `Weapon` varchar(15) NOT NULL DEFAULT '',
  `Cps` int(5) NOT NULL DEFAULT '0',
  `Gcs` int(5) NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;

ALTER TABLE `KreedzTop`
 ADD PRIMARY KEY (`Id`), ADD UNIQUE KEY `Map` (`Map`,`Type`,`SteamId`);
