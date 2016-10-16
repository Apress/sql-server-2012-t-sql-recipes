SET NOCOUNT ON
--Compressed Full Backup
BACKUP DATABASE AdventureWorks2012
TO DISK = 'C:\Backups\AdventureWorks2012.bak'
WITH COMPRESSION;
GO

--Uncompressed Full Backup
BACKUP DATABASE AdventureWorks2012
TO DISK = 'C:\Backups\UnAdventureWorks2012.bak'
WITH COMPRESSION;
GO

--Retrieve the compression ratio
SELECT TOP 2 backup_size,compressed_backup_size,
	   backup_size/compressed_backup_size
FROM msdb..backupset
ORDER BY backup_start_date DESC;
GO

SELECT *
FROM msdb..backupset
ORDER BY backup_start_date DESC;

--Backup database with checksum and restore verify only
BACKUP DATABASE [AdventureWorks2012] 
TO  DISK = N'C:\Backups\AdventureWorks2012.bak' 
WITH CHECKSUM
GO

RESTORE VERIFYONLY 
FROM  DISK = N'C:\Backups\AdventureWorks2012.bak'
WITH CHECKSUM;
GO

USE master;
GO

--log file growth of Logging database in Simple recovery
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Logging')
BEGIN
DROP DATABASE Logging;
CREATE DATABASE Logging;
END
GO

ALTER DATABASE Logging
SET RECOVERY SIMPLE;
GO

USE Logging;

CREATE TABLE FillErUp(
RowInfo	CHAR(150)
);
GO

SELECT type_desc,
	   size
FROM sys.database_files;
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

DECLARE @count INT = 10000
WHILE @count > 0
BEGIN
   INSERT FillErUp
   SELECT 'This is row # ' + CONVERT(CHAR(4), @count)
   SET @count -= 1
END;
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name AS name,
	   log_reuse_wait_desc AS reuse_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

--Effects of an open transaction
BEGIN TRAN

DECLARE @count INT = 10000
WHILE @count > 0
BEGIN
   INSERT FillErUp
   SELECT 'This is row # ' + CONVERT(CHAR(4), @count)
   SET @count -= 1
END;
GO

DBCC SQLPERF(LOGSPACE);
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name AS name,
	   log_reuse_wait_desc AS reuse_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

COMMIT TRAN;
GO
CHECKPOINT;
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO
SELECT name AS name,
	   log_reuse_wait_desc AS reuse_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

DBCC SQLPERF(LOGSPACE);
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO
SELECT name AS name,
	   log_reuse_wait_desc AS reuse_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

--Full recovery model with no t-log backup
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Logging')
BEGIN
DROP DATABASE Logging;
CREATE DATABASE Logging;
END
GO

ALTER DATABASE Logging
SET RECOVERY FULL;
GO

USE Logging;

CREATE TABLE FillErUp(
RowInfo	CHAR(150)
);
GO

USE Logging;
GO

SELECT type_desc,
	   size
FROM sys.database_files;
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

DECLARE @count INT = 10000
WHILE @count > 0
BEGIN
   INSERT FillErUp
   SELECT 'This is row # ' + CONVERT(CHAR(4), @count)
   SET @count -= 1
END;
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

BACKUP DATABASE Logging
TO DISK = 'C:\Backups\Logging.bak';
GO

DECLARE @count INT = 10000
WHILE @count > 0
BEGIN
   INSERT FillErUp
   SELECT 'This is row # ' + CONVERT(CHAR(4), @count)
   SET @count -= 1
END;
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO


--Bulk logged recovery example
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Logging')
BEGIN
DROP DATABASE Logging;
CREATE DATABASE Logging;
END
GO

ALTER DATABASE Logging
SET RECOVERY FULL;
GO

USE Logging;

CREATE TABLE FillErUp(
RowInfo	CHAR(150)
);
GO

USE Logging;
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

BACKUP DATABASE Logging
TO DISK = 'C:\Backups\Logging.bak';
GO

DECLARE @count INT = 100
WHILE @count > 0
BEGIN
   INSERT FillErUp
   SELECT 'This is row # ' + CONVERT(CHAR(4), @count)
   BACKUP LOG Logging
   TO DISK = 'C:\Backups\Logging.trn'
   SET @count -= 1
END;
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

--Bulk logged backup example
USE master;
GO

sp_configure 'Show Advanced Option', 1
GO

RECONFIGURE;
GO

sp_configure 'xp_cmdshell', 1
GO

RECONFIGURE;
GO

DECLARE @cmd NVARCHAR(300)
SELECT @cmd = 'bcp AdventureWorks2012.Sales.Currency out "c:\Backups\currency.dat" -T -c'
PRINT @cmd
EXEC sp_executesql @cmd

GO

sp_configure 'xp_cmdshell', 0
RECONFIGURE;
GO

sp_configure 'Show Advanced Option', 0
GO

RECONFIGURE;
GO

USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Logging')
BEGIN
DROP DATABASE Logging;
CREATE DATABASE Logging;
END
GO

ALTER DATABASE Logging
SET RECOVERY BULK_LOGGED;
GO

USE Logging;

CREATE TABLE Currency(
CurrencyCode CHAR(3) NOT NULL,
Name CHAR(500) NOT NULL,
ModifiedDate CHAR(500) NOT NULL);
GO

BACKUP DATABASE Logging
TO DISK = 'C:\Backups\Logging.bak';
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

BULK INSERT Logging.dbo.Currency
   FROM 'C:\Backups\Currency.dat'
   WITH 
      (
         FIELDTERMINATOR =',',
         ROWTERMINATOR ='\n'
      );
GO


BULK INSERT Logging.dbo.Currency
   FROM 'C:\Backups\Currency.dat'
   WITH 
      (
         FIELDTERMINATOR =',',
         ROWTERMINATOR ='\n'
      );
GO

BULK INSERT Logging.dbo.Currency
   FROM 'C:\Backups\Currency.dat'
   WITH 
      (
         FIELDTERMINATOR =',',
         ROWTERMINATOR ='\n'
      );
GO

BULK INSERT Logging.dbo.Currency
   FROM 'C:\Backups\Currency.dat'
   WITH 
      (
         FIELDTERMINATOR =',',
         ROWTERMINATOR ='\n'
      );
GO
--26
BULK INSERT Logging.dbo.Currency
   FROM 'C:\Backups\Currency.dat'
   WITH 
      (
         FIELDTERMINATOR =',',
         ROWTERMINATOR ='\n'
      );
GO

SELECT type_desc AS filetype,
	   size AS size
FROM sys.database_files
WHERE type_desc = 'LOG';
GO

SELECT name,
	   log_reuse_wait_desc
FROM sys.databases
WHERE database_id = DB_ID('Logging');
GO

--Differential backup
BACKUP DATABASE AdventureWorks2012
TO DISK = 'C:\Backups\AdventureWorks2012.dif'
WITH DIFFERENTIAL;
GO

USE master;
GO

--Granular recovery
USE master;
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'Original')
BEGIN
DROP DATABASE Original;
END
CREATE DATABASE Original;
GO

USE Original;
GO

SELECT BusinessEntityID,
	   FirstName,
	   MiddleName,
	   LastName
INTO People
FROM AdventureWorks2012.Person.Person;
GO

CREATE DATABASE Original_SS ON
( NAME = Original, FILENAME = 
'C:\Program Files\Microsoft SQL Server\MSSQL11.RCO\MSSQL\DATA\Original_SS.ss' )
AS SNAPSHOT OF Original;
GO

USE Original;

SELECT sd.name,
	   type_desc,
	   size
FROM sys.database_files sf JOIN sys.databases sd
ON DB_ID() = sd.database_id
GO

USE Original_SS;

SELECT sd.name,
	   type_desc,
	   size
FROM sys.database_files sf JOIN sys.databases sd
ON DB_ID() = sd.database_id
GO

USE Original_SS;

SELECT *
FROM People
WHERE LastName = 'Abercrombie';
GO

USE Original;

UPDATE People
SET LastName = 'Abercromny'
WHERE LastName = 'Abercrombie';
GO

SELECT *
FROM People
WHERE LastName = 'Abercrombie';
GO

USE Original_SS

SELECT *
FROM People
WHERE LastName = 'Abercrombie';
GO

USE Original;

UPDATE People
SET LastName = ss.LastName
FROM People p JOIN Original_SS.dbo.People ss
ON p.LastName <> ss.LastName
AND p.BusinessEntityID = ss.BusinessEntityID;
GO

SELECT *
FROM People
WHERE LastName = 'Abercrombie';
GO

USE master;

RESTORE DATABASE Original
FROM DATABASE_SNAPSHOT = 'Original_SS';
GO

--Backup filegroup/file
CREATE DATABASE BackupFiles
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'BackupFiles', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.RCO\MSSQL\DATA\BackupFiles.mdf' , SIZE = 4096KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [Current] 
( NAME = N'CurrentData', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.RCO\MSSQL\DATA\CurrentData.ndf' , SIZE = 4096KB , FILEGROWTH = 1024KB ), 
 FILEGROUP [Historic] 
( NAME = N'HistoricData', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.RCO\MSSQL\DATA\HistoricData.ndf' , SIZE = 4096KB , FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'BackupFiles_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.RCO\MSSQL\DATA\BackupFiles_log.ldf' , SIZE = 1024KB , FILEGROWTH = 10%);
GO
ALTER DATABASE [BackupFiles] SET RECOVERY FULL; 
GO

BACKUP DATABASE BackupFiles
FILE = 'HistoricData'
TO DISK = 'C:\Backups\Historic.bak';
GO

BACKUP DATABASE BackupFiles
FILEGROUP = 'Historic'
TO DISK = 'C:\Backups\HistoricGroup.bak';
GO

BACKUP DATABASE AdventureWorks2012
TO DISK = 'C:\Backups\AdventureWorks2012.bak'
MIRROR TO DISK = 'C:\MirroredBackup\AdventureWorks2012.bak'
WITH
   FORMAT,
   MEDIANAME = 'AdventureWorksSet1';
GO

--Copy only
USE master;

BACKUP DATABASE AdventureWorks2012
TO DISK = 'C:\Backups\AdventureWorks2012COPY.bak'
WITH COPY_ONLY;
GO

--Querying backup information
USE msdb;

SELECT database_name,
	   CONVERT(DATE, backup_start_date) AS date,
	   CASE type
	     WHEN 'D' THEN 'Database'
	     WHEN 'I' THEN 'Differential database' 
	     WHEN 'L' THEN 'Log' 
	     WHEN 'F' THEN 'File or filegroup' 
	     WHEN 'G' THEN 'Differential file'
	     WHEN 'P' THEN 'Partial'
	     WHEN 'Q' THEN 'Differential partial'
	     ELSE 'Unknown'
	   END AS type,
	   physical_device_name
FROM backupset s JOIN backupmediafamily f
ON s.media_set_id = f.media_set_id
ORDER BY backup_start_date DESC;
GO
