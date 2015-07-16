SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;


CREATE TABLE IF NOT EXISTS `Drun_Achievements` (
`Id` int(11) NOT NULL,
  `Name` varchar(32) NOT NULL DEFAULT '',
  `Description` varchar(128) NOT NULL DEFAULT '',
  `NeededToGain` int(10) NOT NULL DEFAULT '0',
  `ProgressModule` int(10) NOT NULL DEFAULT '0',
  `Icon` varchar(64) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB AUTO_INCREMENT=52 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Drun_Players` (
  `Id` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT '0',
  `PlayTime` int(10) NOT NULL,
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Connects` int(6) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Drun_Progress` (
  `Id` int(11) NOT NULL DEFAULT '0',
  `Achievement` int(11) NOT NULL DEFAULT '0',
  `Progress` int(11) NOT NULL DEFAULT '0',
  `Bits` int(11) NOT NULL DEFAULT '0',
  `Date` int(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Dust2_Achievements` (
`Id` int(11) NOT NULL,
  `Name` varchar(32) NOT NULL DEFAULT '',
  `Description` varchar(128) NOT NULL DEFAULT '',
  `NeededToGain` int(10) NOT NULL DEFAULT '0',
  `ProgressModule` int(10) NOT NULL DEFAULT '0',
  `Icon` varchar(64) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB AUTO_INCREMENT=54 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Dust2_Players` (
  `Id` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT '0',
  `PlayTime` int(10) NOT NULL,
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Connects` int(6) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Dust2_Progress` (
  `Id` int(11) NOT NULL DEFAULT '0',
  `Achievement` int(11) NOT NULL DEFAULT '0',
  `Progress` int(11) NOT NULL DEFAULT '0',
  `Bits` int(11) NOT NULL DEFAULT '0',
  `Date` int(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `GlobalPlayers` (
`Id` int(11) NOT NULL,
  `SteamId` varchar(34) NOT NULL DEFAULT '',
  `Ip` varchar(16) NOT NULL DEFAULT '',
  `Nick` varchar(64) NOT NULL,
  `PlayTime` int(10) NOT NULL DEFAULT '0',
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Invited` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB AUTO_INCREMENT=155070 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Hns_Achievements` (
`Id` int(11) NOT NULL,
  `Name` varchar(32) NOT NULL DEFAULT '',
  `Description` varchar(128) NOT NULL DEFAULT '',
  `NeededToGain` int(10) NOT NULL DEFAULT '0',
  `ProgressModule` int(10) NOT NULL DEFAULT '0',
  `Icon` varchar(64) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Hns_Players` (
  `Id` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT '0',
  `PlayTime` int(10) NOT NULL,
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Connects` int(6) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Hns_Progress` (
  `Id` int(11) NOT NULL DEFAULT '0',
  `Achievement` int(11) NOT NULL DEFAULT '0',
  `Progress` int(11) NOT NULL DEFAULT '0',
  `Bits` int(11) NOT NULL DEFAULT '0',
  `Date` int(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Jail_Achievements` (
`Id` int(11) NOT NULL,
  `Name` varchar(32) NOT NULL DEFAULT '',
  `Description` varchar(128) NOT NULL DEFAULT '',
  `NeededToGain` int(10) NOT NULL DEFAULT '0',
  `ProgressModule` int(10) NOT NULL DEFAULT '0',
  `Icon` varchar(64) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Jail_Players` (
  `Id` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT '0',
  `PlayTime` int(10) NOT NULL,
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Connects` int(6) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Jail_Progress` (
  `Id` int(11) NOT NULL DEFAULT '0',
  `Achievement` int(11) NOT NULL DEFAULT '0',
  `Progress` int(11) NOT NULL DEFAULT '0',
  `Bits` int(11) NOT NULL DEFAULT '0',
  `Date` int(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Knife_Achievements` (
`Id` int(11) NOT NULL,
  `Name` varchar(32) NOT NULL DEFAULT '',
  `Description` varchar(128) NOT NULL DEFAULT '',
  `NeededToGain` int(10) NOT NULL DEFAULT '0',
  `ProgressModule` int(10) NOT NULL DEFAULT '0',
  `Icon` varchar(64) NOT NULL DEFAULT 'default'
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Knife_Players` (
  `Id` int(11) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT '0',
  `PlayTime` int(10) NOT NULL,
  `LastJoin` int(20) NOT NULL DEFAULT '0',
  `FirstJoin` int(20) NOT NULL DEFAULT '0',
  `Connects` int(6) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `Knife_Progress` (
  `Id` int(11) NOT NULL DEFAULT '0',
  `Achievement` int(11) NOT NULL DEFAULT '0',
  `Progress` int(11) NOT NULL DEFAULT '0',
  `Bits` int(11) NOT NULL DEFAULT '0',
  `Date` int(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE `Drun_Achievements`
 ADD PRIMARY KEY (`Id`);

ALTER TABLE `Drun_Players`
 ADD UNIQUE KEY `Id` (`Id`) USING BTREE;

ALTER TABLE `Drun_Progress`
 ADD UNIQUE KEY `Id` (`Id`,`Achievement`) USING BTREE;

ALTER TABLE `Dust2_Achievements`
 ADD PRIMARY KEY (`Id`);

ALTER TABLE `Dust2_Players`
 ADD UNIQUE KEY `Id` (`Id`) USING BTREE;

ALTER TABLE `Dust2_Progress`
 ADD UNIQUE KEY `Id` (`Id`,`Achievement`) USING BTREE;

ALTER TABLE `GlobalPlayers`
 ADD PRIMARY KEY (`Id`), ADD UNIQUE KEY `SteamId` (`SteamId`) USING BTREE;

ALTER TABLE `Hns_Achievements`
 ADD PRIMARY KEY (`Id`);

ALTER TABLE `Hns_Players`
 ADD UNIQUE KEY `Id` (`Id`) USING BTREE;

ALTER TABLE `Hns_Progress`
 ADD UNIQUE KEY `Id` (`Id`,`Achievement`) USING BTREE;

ALTER TABLE `Jail_Achievements`
 ADD PRIMARY KEY (`Id`);

ALTER TABLE `Jail_Players`
 ADD UNIQUE KEY `Id` (`Id`) USING BTREE;

ALTER TABLE `Jail_Progress`
 ADD UNIQUE KEY `Id` (`Id`,`Achievement`) USING BTREE;

ALTER TABLE `Knife_Achievements`
 ADD PRIMARY KEY (`Id`);

ALTER TABLE `Knife_Players`
 ADD UNIQUE KEY `Id` (`Id`) USING BTREE;

ALTER TABLE `Knife_Progress`
 ADD UNIQUE KEY `Id` (`Id`,`Achievement`) USING BTREE;


ALTER TABLE `Drun_Achievements`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=52;
ALTER TABLE `Dust2_Achievements`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=54;
ALTER TABLE `GlobalPlayers`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=155070;
ALTER TABLE `Hns_Achievements`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=40;
ALTER TABLE `Jail_Achievements`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=58;
ALTER TABLE `Knife_Achievements`
MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT,AUTO_INCREMENT=25;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
