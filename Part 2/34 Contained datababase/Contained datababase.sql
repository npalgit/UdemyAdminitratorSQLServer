
/*

The following demonstration will show that a regular database
which has SQL users and SQL logins DO NOT migrate to another instance
of a database, but rather become an SQL login orphan. But a contained database
when moved, retains the SQL user information so as to prevent orphans

*/

--create test db

CREATE DATABASE PROD
GO

--create sql login and sql user for prod db

USE [master]
GO


CREATE LOGIN [ANDY] WITH PASSWORD=N'password#123',   --<< create sql login
DEFAULT_DATABASE=[PROD], 
CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

USE [PROD]
GO

CREATE USER [ANDY] FOR LOGIN [ANDY]      --<< create sql user
GO

USE [PROD]
GO

ALTER ROLE [db_owner] ADD MEMBER [ANDY]   --<< add sql suer to role
GO

--backup prod database with the SQL login Andy.  Change connection in this query pane to run the restore

Use Master
go

BACKUP DATABASE [PROD] 
TO  DISK = N'C:\ProdBackup\prod.bak' 
WITH  COPY_ONLY, 
NOFORMAT, 
NOINIT,  
NAME = N'PROD-Full Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD,  
STATS = 10
GO


--Restore database Prod on different instance.  Must use a differnt connection to the Dev instance
--Notice that the SQL databse user ANDY moved, but the SQL Login DID NOT copy over!!  This is a SQL orphan

USE [master]

RESTORE DATABASE [PROD] 
FROM  DISK = N'C:\ProdBackup\prod.bak' 
WITH  FILE = 1,  
MOVE N'PROD' 
TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.DEV\MSSQL\DATA\PROD.mdf',  
MOVE N'PROD_log' 
TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.DEV\MSSQL\DATA\PROD_log.ldf',  
NOUNLOAD,  STATS = 5
GO

--Find SQL login orphans.  Run this script against the Dev database to find orphans. Change connection in this query pane

USE PROD
EXEC sp_change_users_login 'Report';

--this will fix by mapping the SQL user to the SQL Login

EXEC sp_change_users_login 'Auto_Fix', 'ANDY', NULL, 'PASSWORD'; 

---extra work needed in a non contained database to resole issues of orphans and security!!

use master
go
drop database prod 

--drop sql login in both databases

USE [master]
GO

DROP LOGIN [ANDY]
GO

------------------------------------------------------------------------

--this issue of orphans does not exist in contained databases as 
--each database has it's own meta data about security and configuration

--DROP DATABASE ContainDB
--CHANGE THE AUTHENTICATION MODE TO MIXED

--USE [master]
--GO
--EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
--N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2
--GO

----RESTART SQL SERVER

----CHANGE THE AUTHENTICATION MODE TO WINDOWS

--USE [master]
--GO
--EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', 
--N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 1
--GO

--RESTART SQL SERVER

-----------------------------------------------------------------------------------------------

--Configure a contained database via sp_configure

sp_configure


--set option on

sp_configure 'contained database authentication', 1
go
reconfigure
go

sp_configure

--set option off

sp_configure 'contained database authentication', 0
go
reconfigure
go

sp_configure


--CREATE A CONTAINED DATABASE.  SAME AS CREATING A REGUALAR DATABASE, ONLY THIS TIME ' CONTAINMENT = PARTIAL' ADDEDD

CREATE DATABASE [ContainDB]
 CONTAINMENT = PARTIAL       --<< ADDITIONAL COMMAND TO CREATE A CONTAINED DATABASE
 ON  PRIMARY 
( NAME = N'ContainDB', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ContainDB.mdf' , 
SIZE = 4096KB , 
FILEGROWTH = 1024KB )

 LOG ON 
( NAME = N'ContainDB_log', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\DATA\ContainDB_log.ldf' , 
SIZE = 1024KB , 
FILEGROWTH = 10%)
GO


--Create a SQL User to access the contained database.  Note NO SQL LOGIN!!!

USE [ContainDB]
GO

CREATE USER [Jack] WITH PASSWORD=N'password'
GO

USE [ContainDB]
GO

ALTER AUTHORIZATION ON SCHEMA::[db_owner] TO [Jack]
GO


--Information about uncontained objects or features.  We see that Jack is a SQL USER and
--has database authentication type rather than NONE - which is a reugular database

use ContainDB
go

Select name, type_desc,authentication_type_desc
from sys.database_principals

--BACKUP THE DATABASE CONTAINDB

Use Master
go

BACKUP DATABASE [CONTAINDB] 
TO  DISK = N'C:\ProdBackup\CONTAINDB.bak' 
WITH  COPY_ONLY, 
NOFORMAT, 
NOINIT,  
NAME = N'CONTAINDB-Full Database Backup', 
SKIP, 
NOREWIND, 
NOUNLOAD,  
STATS = 10
GO


--Restore database Prod on different instance.  Must use a differnt connection to the Dev instance
--Notice that the SQL databse user ANDY moved
USE [master]

RESTORE DATABASE [CONTAINDB] 
FROM  DISK = N'C:\ProdBackup\CONTAINDB.bak' 
WITH  FILE = 1,  
MOVE N'CONTAINDB' 
TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.DEV\MSSQL\DATA\CONTAINDB.mdf',  
MOVE N'CONTAINDB_log' 
TO N'C:\Program Files\Microsoft SQL Server\MSSQL12.DEV\MSSQL\DATA\CONTAINDB_log.ldf',  
NOUNLOAD,  STATS = 5
GO

--Find SQL login orphans.  Run this script against the Dev database to find orphans. Change connection in this query pane

USE CONTAINDB
EXEC sp_change_users_login 'Report';

--NO ORPHASN FOUND.  JACK MOVED WITH THE RESTORE TO THE NEW SERVER


---EXTRA WORK PREVENTED