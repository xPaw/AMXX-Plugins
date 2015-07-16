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

INSERT INTO `Drun_Achievements` (`Id`, `Name`, `Description`, `NeededToGain`, `ProgressModule`, `Icon`) VALUES
(1, 'Striker', 'Kill 100 enemies', 100, 25, 'drun/striker'),
(2, 'Enemies Hater', 'Kill 250 enemies', 250, 50, 'drun/enemieshater'),
(3, 'Assassin', 'Kill 20 enemies with headshot from knife', 20, 5, 'drun/assassin'),
(4, 'Grenade Man', 'Kill 10 enemies with grenade', 10, 0, 'drun/grenademan'),
(5, 'Bad Friend', 'Kill 5 teammates in one round', 1, 0, 'drun/badfriend'),
(6, 'Addict', 'Join to server 500 times', 500, 125, 'drun/addict'),
(7, 'Secret Phrase', 'Say secret phrase', 1, 0, 'drun/secretphrase'),
(8, 'Play Around', 'Spent 1 hour playing on server', 1, 0, 'drun/playaround'),
(9, '1 HP Hero', 'Kill enemy while having 1 HP', 1, 0, 'drun/1hphero'),
(10, 'Sleeper', 'Flash yourself 50 times', 50, 10, 'drun/sleeper'),
(11, 'Flasher', 'Flash 5 enemies with one flashbang', 1, 0, 'drun/flasher'),
(12, 'Kid With Gun', '10 Kills with a TMP', 10, 0, 'drun/kidwithgun'),
(13, 'Aimbot', '25 Kills with headshot', 25, 5, 'drun/aimbot'),
(14, 'War Hero', 'Kill 555 enemies', 555, 185, 'drun/warhero'),
(15, 'Suicider', 'Get killed 500 times', 500, 125, 'drun/suicider'),
(16, 'Day Marathon', 'Spent 1 day playing on server', 1, 0, 'drun/daymarathon'),
(17, 'Jesus', 'Transfer 50 players ( say /transfer )', 50, 10, 'drun/jesus'),
(18, 'Road King', 'Kill 50 terrorists', 50, 10, 'drun/roadking'),
(19, 'Casper', 'Buy stealth 10 times in deathrun shop', 10, 0, 'drun/casper'),
(20, 'Evolution', 'Finish deathrun_evolution atleast once', 1, 0, 'drun/evolution'),
(21, 'Nobel Prize', 'Unlock 42 achievements', 1, 0, 'drun/nobelprize'),
(22, 'W...Whatz Up?!', 'Kill atleast one enemy while flashed', 1, 0, 'drun/whatzup'),
(23, 'Dominator', 'Kill 10 counter-terrorists (no traps)', 10, 0, 'drun/dominator'),
(24, 'Head Hunter', 'Kill 5 enemies with stationary gun', 5, 0, 'drun/headhunter'),
(25, 'Millionaire', 'Buy 150 items in deathrun shop', 150, 50, 'drun/millionaire'),
(26, 'Activator', 'Activate 500 buttons', 500, 125, 'drun/activator'),
(27, 'Hellraiser', 'Buy respawn 10 times in deathrun shop', 10, 0, 'drun/hellraiser'),
(28, 'Pyromancer', 'Make 200,000 points of total damage', 200000, 50000, 'drun/pyromancer'),
(29, 'Dealer', 'Win 15 successfull bets with prize over 10000$', 15, 5, 'drun/dealer'),
(30, 'Stand-Alone', 'Die 15 times as the latest guy in team. (As CT only)', 15, 5, 'drun/standalone'),
(31, 'Death-Gunner', 'Find 500 weapons as CT', 500, 125, 'drun/deathgunner'),
(32, 'Im ze ubermench!', 'Buy HP 250 times', 250, 50, 'drun/ubermench'),
(33, 'Boink', 'Walk 2500 meters', 2500, 625, 'drun/boink'),
(34, 'Marathon!', 'Walk 15000 meters', 15000, 3750, 'drun/marathon'),
(35, 'Tour de France', 'Walk 50000 meters', 50000, 12500, 'drun/france'),
(36, 'Vandalism', 'Destroy 200 breakables on map', 200, 50, 'drun/vandalism'),
(37, 'You Never Studied!', 'Finish deathrun_dgs, deathrun_luxus_n1 and deathrun_bleak atleast once', 3, 0, 'drun/neverstudied'),
(38, 'We Have the Talent!', 'Finish deathrun_darkside, deathrun_ijumping_beta7 and deathrun_state3_winter atleast once', 3, 0, 'drun/talent'),
(39, 'We''re Just Getting Started', 'Finish deathrun_midnight_beta3, deathrun_nightmare and deathrun_4life_rmk atleast once', 3, 0, 'drun/getting_started'),
(40, 'Float Like a Butterfly', 'Finish deathrun_junbee_beta5, deathrun_hotel and deathrun_industry atleast once', 3, 0, 'drun/butterfly'),
(41, 'Mission Impossible', 'Finish deathrun_fixxor.', 1, 0, 'drun/mission_impossible'),
(42, 'Spoils Of War', 'Win total of 500,000$ using bet system', 500000, 125000, 'drun/spoilsofwar'),
(43, 'Synergy Speedrun', 'Complete deathrun_death in 1m50s or less', 1, 0, 'drun/synergy'),
(44, 'Trauma Queen', 'Do extreme jump on deathrun_somwhera and succesfully win the round', 1, 0, 'drun/trauma_queen'),
(45, 'Camp Fire', 'Finish deathrun_dojo, deathrun_trap_canyon and deathrun_burnzone atleast once', 3, 0, 'drun/camp_fire'),
(46, 'Counter Espionage', 'Kill 15 enemies while under effects of Casper', 15, 5, 'drun/casper2'),
(47, 'Joint Operation', 'Pickup elites on deathrun_dojo and kill 10 enemies with them', 10, 0, 'drun/joint_op'),
(48, 'Taringacs Family', 'Finish two of taringa maps (taringacs_lostrome, taringacs_inthetetris)', 2, 0, 'drun/taringacs'),
(50, 'Is It Safe?', 'Kill your teammates 100 times', 100, 25, 'drun/isitsafe'),
(51, 'The Big Hurt', 'Get secret armor suite on TerrorLabs and survive', 1, 0, 'default');

INSERT INTO `Dust2_Achievements` (`Id`, `Name`, `Description`, `NeededToGain`, `ProgressModule`, `Icon`) VALUES
(1, 'Someone Set Up Us The Bomb', 'Win a round by planting a bomb', 1, 0, 'dust2/someone_bomb'),
(2, 'Rite of First Defusal', 'Win a round by defusing a bomb', 1, 0, 'dust2/first_defusal'),
(3, 'Boomala Boomala', 'Plant 50 bombs', 50, 10, 'dust2/boomala'),
(4, 'The Hurt Blocker', 'Defuse 50 bombs', 50, 10, 'dust2/hurt_blocker'),
(5, 'Combat Ready', 'Defuse a bomb with a kit when it would have failed without one', 1, 0, 'dust2/combat_ready'),
(6, 'Counter-Counter-Terrorist', 'Kill a CT while he is defusing the bomb', 1, 0, 'dust2/cct'),
(7, 'Newb World Order', 'Win 10 rounds', 10, 0, 'dust2/newb_world'),
(8, 'Veteran', 'Win 100 rounds', 100, 25, 'dust2/veteran'),
(9, 'The Art of War', 'Spray 100 decals', 100, 25, 'dust2/art_of_war'),
(10, 'Body Bagger', 'Kill 100 enemies', 100, 25, 'dust2/body_bagger'),
(11, 'God of War', 'Kill 500 enemies', 500, 125, 'dust2/god_of_war'),
(12, 'Dead Man Stalking', 'Kill an enemy while at 1 health', 1, 0, 'dust2/dead_man'),
(13, 'The Unstoppable Force', 'Kill 5 enemy players in a single round', 1, 0, 'dust2/unstoppable'),
(14, 'Battle Sight Zero', 'Kill 250 enemy players with headshots', 250, 50, 'dust2/battle_sight'),
(15, 'Points in Your Favor', 'Inflict 2,500 total points of damage to enemy players', 2500, 0, 'dust2/points_favor'),
(16, 'You''ve Made Your Points', 'Inflict 50,000 total points of damage to enemy players', 50000, 0, 'dust2/made_points'),
(17, 'Street Fighter', 'Kill 25 enemies with an knife', 25, 5, 'dust2/street_fighter'),
(18, 'Hat Trick', 'Get 3 headshots in a row', 1, 0, 'dust2/hat_trick'),
(19, 'Bunny Hunt', 'Kill an airborne enemy', 1, 0, 'dust2/bunny_hunt'),
(20, 'Ammo Conservation', 'Kill two enemy players with a single bullet', 1, 0, 'dust2/ammo_con'),
(21, 'War Bonds', 'Earn $125,000 total cash', 125000, 31250, 'dust2/war_bonds'),
(22, 'Premature Burial', 'Kill an enemy with a grenade after you''ve died', 1, 0, 'dust2/burial'),
(23, 'Blind Ambition', 'Kill a total of 25 enemy players blinded by flashbangs', 25, 5, 'dust2/blind_ambition'),
(24, 'Defuse This!', 'Kill the defuser with an HE grenade', 1, 0, 'dust2/defuse_this'),
(25, 'Shrapnelproof', 'Take 80 points of damage from enemy grenades and still survive the round', 1, 0, 'dust2/shrapnelproof'),
(26, 'Blind Fury', 'Kill an enemy player while you are blinded from a flashbang', 1, 0, 'dust2/blind_fury'),
(27, 'Addict', 'Join to the server 500 times', 500, 0, 'dust2/addict'),
(28, 'Play Around', 'Spent 1 hour playing on the server', 1, 0, 'dust2/play_around'),
(29, 'Day Marathon', 'Spent 1 day playing on the server', 1, 0, 'dust2/day_marathon'),
(30, 'Golden Medal', 'Achieve 25 of the achievements', 1, 0, 'dust2/golden_medal'),
(31, 'Second to None', 'Successfully defuse a bomb with less than one second remaining', 1, 0, 'dust2/second_to_none'),
(32, 'The Hard Way', 'Kill two enemy players with a single grenade', 1, 0, 'dust2/hard_way'),
(33, 'Blast Will and Testament', 'Win 10 rounds by planting a bomb', 10, 0, 'dust2/blast_will'),
(35, 'Candy Coroner', 'Placeholder', 20, 5, 'jail/special_candy'),
(36, 'Short Fuse', 'Plant a bomb within 25 seconds', 1, 0, 'dust2/short_fuse'),
(37, 'Leone Gauge Super Expert', 'Kill 25 enemy players with the Leone 12 Gauge Super', 25, 5, 'dust2/shotgun1'),
(38, 'Leone Auto Shotgun Expert', 'Kill 25 enemy players with the Leone YG1265 Auto Shotgun', 25, 5, 'dust2/shotgun2'),
(39, 'Shotgun Master', 'Unlock both shotgun kill achievements', 1, 0, 'dust2/shotgun_master'),
(40, 'KM Tactical .45 Expert', 'Kill 75 enemy players with the KM Tactical .45 <i>(USP)</i>', 75, 25, 'dust2/pistol_usp'),
(41, '9x19 Sidearm Expert', 'Kill 75 enemy players with the 9x19 Sidearm <i>(Glock)</i>', 75, 25, 'dust2/pistol_glock'),
(42, 'Night Hawk .50c Expert', 'Kill 50 enemy players with the Night Hawk .50c <i>(Deagle)</i>', 50, 10, 'dust2/pistol_deagle'),
(43, '.40 Dual Elites Expert', 'Kill 25 enemy players with the .40 Dual Elites', 25, 5, 'dust2/pistol_elites'),
(44, 'ES Five-Seven Expert', 'Kill 25 enemy players with the ES Five-Seven', 25, 5, 'dust2/pistol_fiveseven'),
(45, '228 Compact Expert', 'Kill 25 enemy players with the 228 Compact', 25, 5, 'dust2/pistol_compact'),
(46, 'Serial Killer', 'Acquire 30 kills before map change', 1, 0, 'dust2/serial_killer'),
(47, 'Maverick M4A1 Carbine Expert', 'Kill 100 enemy players with the Maverick M4A1 Carbine', 100, 25, 'dust2/weapon_m4a1'),
(48, 'AK-47 Expert', 'Kill 100 enemy players with the AK-47', 100, 25, 'dust2/weapon_ak47'),
(49, 'Magnum Sniper Rifle Expert', 'Kill 50 enemy players with the Magnum Sniper Rifle', 50, 10, 'dust2/weapon_awp'),
(50, 'Schmidt Scout Expert', 'Kill 25 enemy players with the Schmidt Scout', 25, 5, 'dust2/weapon_scout'),
(51, 'Clarion 5.56 Expert', 'Kill 50 enemy players with the Clarion 5.56', 50, 10, 'dust2/weapon_famas'),
(52, 'IDF Defender Expert', 'Kill 25 enemy players with the IDF Defender', 25, 5, 'dust2/weapon_galil'),
(53, 'KM Sub-Machine Gun Expert', 'Kill 50 enemy players with the KM Sub-Machine Gun', 50, 10, 'dust2/weapon_mp5');

INSERT INTO `Hns_Achievements` (`Id`, `Name`, `Description`, `NeededToGain`, `ProgressModule`, `Icon`) VALUES
(1, 'Catch me if you can', 'Survive 50 rounds as a Terrorist', 50, 10, 'hns/catch_me'),
(2, 'Far, far away', 'Walk 10000 meters', 10000, 2500, 'hns/far_far'),
(3, 'Air Show', 'Kill 50 enemies while they are in air', 50, 10, 'hns/air_show'),
(4, 'Blind Ambition', 'Kill 5 Terrorists while they are fully flashed', 5, 0, 'hns/blind_ambition'),
(5, 'Double Cross', 'Kill 2 Terrorists in 2 seconds or less', 1, 0, 'hns/double_cross'),
(6, 'Ladderlicious', 'Kill 15 Terrorists while they are on a ladder', 15, 5, 'hns/ladderlicious'),
(7, 'Does It Hurt When I Do This?', 'Get killed 100 times by environmental damage', 100, 25, 'hns/does_it_hurt'),
(8, 'Your Experience', 'Kill 500 Terrorists', 500, 125, 'hns/your_experience'),
(9, 'No Hard Feelings', 'Kill 15 Counter-Terrorists with a grenade', 15, 5, 'hns/no_hard_feelings'),
(10, 'Urban Designer', 'Spray 100 decals', 100, 25, 'hns/urban_designer'),
(11, 'Who Cares? They''re dead!', 'Spray 15 decals on dead bodies of Counter-Terrorists', 15, 5, 'hns/who_cares'),
(12, 'Eviction Notice', 'Get 3 headshots in a row', 1, 0, 'hns/eviction_notice'),
(13, 'Wounded But Steady', 'Survive a round while having 1 HP left', 1, 0, 'hns/wounded'),
(14, 'Against The Odds', 'Survive a round against 3 or more Counter-Terrorists', 1, 0, 'hns/against_the_odds'),
(15, 'Still Alive', 'Survive 10 rounds before a map change', 1, 0, 'hns/still_alive'),
(16, 'Super Mario Brothers', 'Make 2000 jumps before map change', 1, 0, 'hns/super_mario'),
(17, 'Old School', 'Make a edgebug and jumpbug in same round', 1, 0, 'hns/old_school'),
(18, 'Asking for Trouble', 'Make a edgebug from a height of 1000 units while at 1 HP', 1, 0, 'hns/asking_for_trouble'),
(19, 'Basic Science', 'Make a edgebug from a height of 1500 or higher', 1, 0, 'hns/basic_science'),
(20, 'Edgebug Veteran', 'Perform 25 successful edgebugs', 25, 5, 'hns/eb_veteran'),
(21, 'New Innovation', 'Make a double edgebug', 1, 0, 'hns/new_innovation'),
(22, 'Double Edgebug Veteran', 'Perform 10 successful double edgebugs', 10, 0, 'hns/dbl_eb_veteran'),
(23, 'Preservation of Mass', 'Make a jumpbug while at 1 HP', 1, 0, 'hns/preservation'),
(24, 'Pit Boss', 'Make a jumpbug', 1, 0, 'hns/pit_boss'),
(25, 'Jumpbug Veteran', 'Perform 25 successful jumpbugs', 25, 5, 'hns/jb_veteran'),
(26, 'Serial Killer', 'Acquire 30 kills before map change', 1, 0, 'hns/serial_killer'),
(27, 'Party of Three', 'Acquire 3 kills within 60 seconds after round start', 1, 0, 'hns/party_of_three'),
(28, 'Take No Prisoners', 'Get 5 kills in single round', 1, 0, 'hns/take_no_prisoners'),
(29, 'Vertically Unchallenged', 'Kill 5 Terrorists that are on ladder, while you are in air', 5, 0, 'hns/unchallenged'),
(30, 'Potato Layer', 'Throw 1000 grenades', 1000, 250, 'hns/potato_layer'),
(31, 'Stranger Than Friction', 'Get prestrafe speed of 299 on bhop and successfully make the jump', 1, 0, 'hns/strange_friction'),
(32, 'Count Jump', 'Jump 260 countjump 5 times', 5, 0, 'hns/count_jump'),
(33, 'Long Jump', 'Jump 250 longjump 5 times', 5, 0, 'hns/long_jump'),
(34, 'Bhop Jump', 'Jump 240 bhopjump 5 times', 5, 0, 'hns/bhop_jump'),
(35, 'Triple Crown', 'Unlock 3 achievements: Count Jump, Long Jump and Bhop Jump', 3, 0, 'hns/triple_crown'),
(36, 'Addict', 'Join to the server 500 times', 500, 125, 'hns/addict'),
(37, 'Play Around', 'Spent 1 hour playing on server', 1, 0, 'hns/play_around'),
(38, 'Day Marathon', 'Spent 1 day playing on server', 1, 0, 'hns/day_marathon'),
(39, 'Gift Grab 2011 - HideNSeek', 'Collect seven gifts dropped by opponents', 7, 1, 'jail/giftgrab');

INSERT INTO `Jail_Achievements` (`Id`, `Name`, `Description`, `NeededToGain`, `ProgressModule`, `Icon`) VALUES
(1, 'Rebel', 'Kill 100 Guards as Prisoner', 100, 25, 'jail/rebel'),
(2, 'Assassin', ' Kill 25 guards with a knife headshot', 25, 5, 'jail/assassin'),
(3, 'Shit Police!', 'Poop 100 times', 100, 25, 'jail/shit_police'),
(4, 'Desecrate the Dead', 'Piss 100 times on the floor or corpses', 100, 25, 'jail/piss'),
(5, 'Duel King', 'Win 25 Last Request games', 25, 5, 'jail/duel_king'),
(6, 'Dealer', 'Find 100 weapons as prisoner', 100, 25, 'jail/dealer'),
(7, 'Survivor', 'Be the last prisoner for 30 rounds', 30, 10, 'jail/survivor'),
(8, 'Shot Dueler', 'Start 25 "Shot to Shot fights"', 25, 5, 'jail/shot_to_shot'),
(9, 'Shiny knife', 'Start 50 knife duels', 50, 10, 'jail/shiny_knife'),
(10, 'Addict', 'Join to server 500 times', 500, 125, 'jail/addict'),
(11, 'GET OUT OF MY WAY!', 'Kill 20 enemies using a car', 20, 5, 'jail/get_out_of_my_way'),
(12, 'Urban designer', 'Spray 300 decals.', 300, 75, 'jail/urban_designer'),
(13, 'Danger Close', 'Kill 25 guards with a granade', 25, 5, 'jail/danger_close'),
(14, 'Drunk Driver', 'Crush 20 team mates while driving a car', 20, 5, 'jail/drunk_driver'),
(15, 'Gravity Junkie', 'Win 100 spray contests', 100, 25, 'jail/gravity_junkie'),
(16, 'Pro Assassin', 'Win 100 knife battles', 100, 25, 'jail/pro_assassin'),
(17, 'W...Whatz Up?!', 'Kill atleast one Guard while flashed as Prisoner', 1, 0, 'jail/whatz_up'),
(19, 'Victory', 'Win a round as Guard without any guards dying <b>(atleast 3 Guards required)</b>', 1, 0, 'jail/victory'),
(20, 'Three-some', 'Kill 3 Guards in a single life', 1, 0, 'jail/three-some'),
(21, 'Kid with gun', 'Kill 25 Guards with a TMP', 25, 5, 'jail/kid_with_gun'),
(22, 'Blabla', 'BLABLA', 1, 0, 'jail/blabla'),
(23, 'Ghost Sniper', 'Kill 10 Guards with a AWP', 10, 0, 'jail/ghost_sniper'),
(24, 'Play Around', 'Spent 1 hour playing on server', 1, 0, 'jail/play_around'),
(25, 'Day Marathon', 'Spent 1 day playing on server', 1, 0, 'jail/day_marathon'),
(26, 'Michael Scofield', 'Press secret button after secret longjump on jail_ms_shawshank', 1, 0, 'jail/scotfield'),
(27, 'Vandalism', 'Destroy 200 objects on map', 200, 50, 'jail/vandalism'),
(28, 'High Tension', 'Score 50 goals', 50, 10, 'jail/high_tension'),
(29, 'Golden Foot', 'Score a goal from a distance of 2000 units', 1, 0, 'jail/golden_foot'),
(30, 'Silver Foot', 'Score a goal from a distance of 1750 units', 1, 0, 'jail/silver_foot'),
(31, 'Rocky Balboa', 'Kill 50 guards while in rambo mode', 50, 5, 'jail/rocky'),
(32, 'Outlaw Prestige', 'Earn all achievements', 1, 0, 'jail/prestige'),
(33, 'Get out of my yard, boy!', 'Kill 25 guards with shotgun', 25, 5, 'jail/my_yard'),
(34, 'Zeus', 'Kill Rambo 5 times', 5, 0, 'jail/zeus'),
(35, 'Graffiti is my second name', 'Spray 8 times in one round', 1, 0, 'jail/graffity'),
(36, 'Candy Coroner', 'Collect 40 Halloween pumpkins from dead players to unlock a hat <b>(Not Available)</b>', 40, 5, 'jail/special_candy'),
(37, 'Masked Mann', 'Collect 5 secret presents dropped randomly on the map <b>(Not Available)</b>', 5, 0, 'jail/present'),
(38, 'Santa''s Little Helper', 'Find five presents that Santa lost while travelling <b>(Not Available)</b>', 5, 1, 'drun/winter'),
(39, 'Sandbag', 'Suffer 10000 Total points of damage', 10000, 0, 'jail/sandbag'),
(40, 'Fyi I Am A Spy', 'Kill 10 guards while they can''t see you', 10, 0, 'jail/spy'),
(41, 'Medical Intervention', 'Heal yourself for total of 10000 HP', 10000, 2500, 'jail/medical'),
(42, 'Surgical Prep', 'Get yourself total of 1000 armor points using wall rechargers', 1000, 250, 'jail/surgical'),
(43, 'Agent Provocateur', 'Win a round as a Prisoner before time hits 4:30 <b>(atleast 3 Guards required)</b>', 1, 0, 'jail/agent_prov'),
(44, 'Preventive Medicine', 'Kill a Guard while he is healing himself', 1, 0, 'jail/preventive'),
(45, 'Football Star', 'Score 20 goals while all CTs are dead', 20, 5, 'jail/footballstar'),
(46, 'No guards in pool!', 'Kill 5 guards as T while they are in pool', 5, 0, 'jail/nopool'),
(47, 'Say hello to my little friend', 'Kill 25 guards with deagle', 25, 5, 'jail/littlefriend'),
(48, 'Specialist', 'Kill 10 guards in one map', 1, 0, 'jail/specialist'),
(49, 'Does It Hurt When I Do This?', 'Get killed 100 times by environmental damage', 100, 25, 'jail/doithurt'),
(50, 'Drive This!', 'Kill 20 guards while they are driving a vehicle', 20, 5, 'jail/drivethis'),
(51, 'Now the art is better!', 'Kill a guard standing on his own spray', 1, 0, 'jail/artisbetter'),
(52, 'Caught with your pants down', 'Kill a CT that recently made a dookie or a piss', 1, 0, 'jail/pantsdown'),
(53, 'Hard work pays off', 'Get last request while being on 1HP', 1, 0, 'jail/hardwork'),
(54, 'hu?..Freeday?', 'Walk 25000 meters', 25000, 6250, 'jail/freeday'),
(55, 'That was Tasty!', 'Kill 5 guards when you have walked less than 12 meters after spawning', 5, 1, 'jail/tasty'),
(56, 'The Melbourne Supremacy', 'Kill 50 guards with your bare hands <b>(This achievement will grant you access to old knife skin)</b>', 50, 10, 'jail/melbourne'),
(57, 'Gift Grab 2011 - JailBreak', 'Collect seven gifts dropped by opponents', 7, 1, 'jail/giftgrab');

INSERT INTO `Knife_Achievements` (`Id`, `Name`, `Description`, `NeededToGain`, `ProgressModule`, `Icon`) VALUES
(1, 'Medic is useless!', 'Kill 50 enemies on 100hp map', 50, 10, 'knife/medicisuseless'),
(2, 'Urban designer', 'Spray 300 decals.', 300, 75, 'knife/urban'),
(3, 'Players can''t fly!', ' Kill 50 enemies while they are in air', 50, 10, 'knife/cantfly'),
(4, 'Run forest run!', 'Walk 25000 meters.', 25000, 6250, 'knife/runforestrun'),
(5, '1 HP Star', 'Kill 1000 enemies on 1HP Map', 1000, 250, 'knife/1hpstar'),
(6, 'Keep It Clean', 'Kill 100 enemies', 100, 25, 'knife/knifer'),
(7, 'Crazy Knifer', 'Kill 255 enemies', 255, 85, 'knife/crazy'),
(8, 'Enemie Humiliate', 'Spray decal on the your killing person 100 times.', 100, 25, 'knife/humiliate'),
(9, 'Longarm!', 'Kill a enemie with 31-32m Stab 15 times', 15, 5, 'knife/longarm'),
(11, '1 HP Hero', 'Kill enemy while having 1 HP', 1, 0, 'knife/1hp'),
(12, 'Pyromancer', 'Make 10,000 points of total damage', 10000, 2500, 'knife/pyromancer'),
(13, 'Pro Knifer', 'Kill 5 enemys in one round with headshot.', 1, 0, 'knife/pro_knifer'),
(14, 'Jesus', 'Spent 100 enemys freehits', 100, 25, 'knife/jesus'),
(15, 'Vandalism', 'Destroy 100 objects on map', 100, 25, 'knife/vandalism'),
(16, 'Sneaky', ' Kill 50 players while they dont see you', 50, 10, 'knife/sneaky'),
(17, 'Addict', 'Join to server 500 times', 500, 125, 'knife/addict'),
(18, 'Play Around', 'Spent 1 hour playing on server', 1, 0, 'knife/playaround'),
(19, 'Day Marathon', 'Spent 1 day playing on server', 1, 0, 'knife/daymarathon'),
(22, 'Yes, Sensei!', 'Kill a enemie with 31-21m Stab 100 times', 100, 25, 'knife/fucking'),
(23, 'Oldsql Knifer', 'Kill 100 Enemies with CS 1.5 Knife', 100, 25, 'knife/oldsql'),
(24, 'Third-Person', 'Kill 25 enemies with 3rd-view', 25, 5, 'knife/3rd');
