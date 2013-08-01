/*
Navicat MySQL Data Transfer

Source Server         : rpi-lab
Source Server Version : 50531
Source Host           : 10.0.1.201:3306
Source Database       : dsmr

Target Server Type    : MYSQL
Target Server Version : 50531
File Encoding         : 65001

Date: 2013-08-01 14:10:46
*/

SET FOREIGN_KEY_CHECKS=0;

-- Create database 
DROP DATABASE IF EXISTS dsmr;
CREATE DATABASE IF NOT EXISTS dsmr CHARACTER SET = utf8 COLLATE  = utf8_general_ci;

USE dsmr;
-- ---------------------------

-- ----------------------------
-- Table structure for `energy`
-- ----------------------------
DROP TABLE IF EXISTS `energy`;
CREATE TABLE `energy` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `batchID` char(14) DEFAULT NULL COMMENT 'Batch ID',
  `yy` smallint(4) unsigned NOT NULL DEFAULT '0' COMMENT 'Year',
  `mm` smallint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'Month',
  `dd` smallint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'Day',
  `hh` smallint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'Hour',
  `min` smallint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'Minute',
  `sec` smallint(2) unsigned NOT NULL DEFAULT '0' COMMENT 'Second',
  `ecl` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Electricity Consumption Tariff Low',
  `ech` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Electricity Consumption Tariff High',
  `edl` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Electricity Delivery Tariff Low',
  `edh` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Electricity Delivery Tariff High',
  `tc` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Tariff Code; 0=High, 1=Low',
  `cec` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Current Electricity Consumption kWh',
  `ced` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Current Electricity Delivery kWh',
  `gc` decimal(9,4) unsigned NOT NULL DEFAULT '0.0000' COMMENT 'Gas Consumption',
  `gr` datetime DEFAULT NULL COMMENT 'Last Gas Reading ',
  `gt` tinyint(1) unsigned NOT NULL DEFAULT '0' COMMENT 'Gas throttle 0=Closed, 1=Open',
  `type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `Timestamp` (`Timestamp`),
  KEY `YY` (`yy`,`mm`,`dd`,`hh`,`min`,`sec`),
  KEY `batchID` (`batchID`,`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of energy
-- ----------------------------

-- ----------------------------
-- Table structure for `portdata`
-- ----------------------------
DROP TABLE IF EXISTS `portdata`;
CREATE TABLE `portdata` (
  `ID` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,
  `Timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `batchID` char(14) DEFAULT NULL COMMENT 'batch id',
  `portdata` varchar(255) DEFAULT NULL COMMENT 'raw data from port p1 of smartmeter',
  PRIMARY KEY (`ID`),
  KEY `Timestamp` (`Timestamp`),
  KEY `batchID` (`batchID`)
) ENGINE=MEMORY DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of portdata
-- ----------------------------

-- ----------------------------
-- Procedure structure for `sp_portdata`
-- ----------------------------
DROP PROCEDURE IF EXISTS `sp_portdata`;
DELIMITER ;;
CREATE DEFINER=`root`@`10.%` PROCEDURE `sp_portdata`(IN `ibatchID` char(14))
BEGIN

	declare rc int default 0;
	declare cTimestamp datetime;
	declare cID INT;
	declare cbatchID,cportdata text;
	declare raw CURSOR FOR select ID,`Timestamp`,batchID,portdata  from portdata where batchID=ibatchID order by ID;
	declare continue handler for not found set rc=1;

	open raw;
	set @f=0;

	while rc=0 DO

		fetch raw into cID,cTimestamp,cbatchID,cportdata;

		set @yy	=	year(now());
		set @mm	=	month(now());
		set @dd	=	day(now());
		set @hh	=	hour(now());
		set @min	=	minute(now());
		set @sec	=	second(now());

		IF 			substr(cportdata,1,1)="/" 				then  set @type	=	substr(cportdata,1);set @f=@f+1;						# meter type
		ELSEIF 		substr(cportdata,1,9)="1-0:1.8.1" 		then  set @ecl		=	substr(cportdata,11,9);set @f=@f+1;					# electric power consumption low 
		ELSEIF		substr(cportdata,1,9)="1-0:1.8.2" 		then  set @ech		=	substr(cportdata,11,9);set @f=@f+1;					# electric power consumption high
		ELSEIF		substr(cportdata,1,9)="1-0:2.8.1" 		then  set @edl		=	substr(cportdata,11,9);set @f=@f+1;					# electric power delivery low 
		ELSEIF 		substr(cportdata,1,9)="1-0:2.8.2" 		then  set @edh	=	substr(cportdata,11,9);set @f=@f+1;					# electric power delivery high
		ELSEIF		substr(cportdata,1,11)="0-0:96.14.0" 	then  set @tc		=	substr(cportdata,13,4);set @f=@f+1;					# tarieffcode - 0=hoog;1=laag
		ELSEIF 		substr(cportdata,1,9)="1-0:1.7.0" 		then  set @cec		=	substr(cportdata,11,7);set @f=@f+1;					# current electric power consumption
		ELSEIF 		substr(cportdata,1,9)="1-0:2.7.0" 		then  set @ced		= 	substr(cportdata,11,7);set @f=@f+1;					# current electric power delivery
		ELSEIF 		substr(cportdata,1,10)="0-1:24.3.0" 	then  set @gr		= 	substr(cportdata,12,12);set @f=@f+1;					# timestamp reading last gas consumption
		ELSEIF 		substr(cportdata,1,1)="(" and substr(cportdata,11,1)=")" then  set @gc=substr(cportdata,2,9);set @f=@f+1;			# gas consumption in m3
		ELSEIF 		substr(cportdata,1,10)="0-1:24.4.0" 	then  set @gt		=	substr(cportdata,12,1);set @f=@f+1;					# gas throttle - 0=closed, 1=open
		else 		set @a=0;
		end if;

	end while;

	if @f=11 THEN
		start transaction;
		# insert data into energy table
		insert ignore into energy 
			(batchID,yy,mm,dd,hh,`min`,`sec`, ecl,ech,edl,edh,tc,cec,ced,gc,gr,gt,type) 
			values(ibatchID,@yy,@mm,@dd,@hh,@min,@sec,@ecl,@ech,@edl,@edh,@tc,@cec,@ced,@gc,@gr,@gt,@type);
		# truncate (empty) portdata table
		truncate portdata;
		commit;
	end if;

END
;;
DELIMITER ;
