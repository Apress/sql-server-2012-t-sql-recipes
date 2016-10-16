/* 27-1. Restoring a Database from a Full Backup */

--create a backup
USE master;
GO

Declare @BackupDate Char(8) = Convert(Varchar,GetDate(),112)
    ,@BackupPath Varchar(50); 
	
Set @BackupPath= 'C:\Apress\TestDB_'+ @BackupDate + '.BAK';

BACKUP DATABASE TestDB
TO DISK = @BackupPath;
GO
-- Time passes, we make another backup to the same device
USE master;
GO

Declare @BackupDate Char(8) = Convert(Varchar,GetDate(),112)
    ,@BackupPath Varchar(50);
	
Set @BackupPath= 'C:\Apress\TestDB_'+ @BackupDate + '.BAK';

BACKUP DATABASE TestDB
TO DISK = @BackupPath;
GO

--restore
Declare @DeviceName Varchar(50);

Select @DeviceName = b.physical_device_name
    From msdb.dbo.backupset a
        INNER JOIN msdb.dbo.backupmediafamily b
        ON a.media_set_id = b.media_set_id
    Where a.database_name = 'TestDB'
        And a.type = 'D'
        And Convert(Varchar,a.backup_start_date,112) = Convert(Varchar,GetDate(),112);

RESTORE DATABASE TestDB
FROM DISK = @DeviceName
WITH FILE = 2, REPLACE;
GO

--example two
Declare @DeviceName Varchar(50);

Select @DeviceName = b.physical_device_name
    From msdb.dbo.backupset a
        INNER JOIN msdb.dbo.backupmediafamily b
        ON a.media_set_id = b.media_set_id
    Where a.database_name = 'TestDB'
        And a.type = 'D'
        And Convert(Varchar,a.backup_start_date,112) = Convert(Varchar,GetDate(),112);
RESTORE DATABASE TrainingDB
FROM DISK = @DeviceName
WITH FILE = 2,
MOVE 'TestDB' TO 'C:\Apress\TrainingDB.mdf',
MOVE 'TestDB_log' TO 'C:\Apress\TrainingDB_log.LDF';
GO

--example three
USE master;
GO
/* The path for each file should be changed to a path matching one
That exists on your system. */
BACKUP DATABASE TestDB
TO DISK = 'C:\Apress\Recipes\TestDB_Stripe1.bak'
    , DISK = 'D:\Apress\Recipes\TestDB_Stripe2.bak'
    , DISK = 'E:\Apress\Recipes\TestDB_Stripe3.bak'
    WITH NOFORMAT, NOINIT,  
NAME = N'AdventureWorks2012-Stripe Database Backup', 
SKIP, STATS = 20;
GO

USE master;
GO
/* You should use the same file path for each file as specified
in the backup statement. */
RESTORE DATABASE TestDB
FROM DISK = 'C:\Apress\Recipes\TestDB_Stripe1.bak'
	, DISK = 'D:\Apress\Recipes\TestDB_Stripe2.bak'
	, DISK = 'E:\Apress\Recipes\TestDB_Stripe3.bak' 
	WITH FILE = 1, REPLACE;
GO

/* 27-2. Restoring a Database from a Transaction Log Backup */

USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.databases
WHERE name = 'TrainingDB') 
BEGIN
CREATE DATABASE TrainingDB;
END 
GO
-- Add a table and some data to it
USE TrainingDB
GO
SELECT *
INTO dbo.SalesOrderDetail
FROM AdventureWorks2012.Sales.SalesOrderDetail;
GO

--full backup and t-log backups
USE master;
GO

Declare @BackupDate Char(8) = Convert(Varchar,GetDate(),112)
	,@BackupPath Varchar(50);
	
Set @BackupPath= 'C:\Apress\TrainingDB_'+ @BackupDate + '.BAK';

BACKUP DATABASE TrainingDB
TO DISK = @BackupPath;
GO
BACKUP LOG TrainingDB
TO DISK = 'C:\Apress\TrainingDB_20120430_8AM.trn';
GO
-- Two hours pass, another transaction log backup is made
BACKUP LOG TrainingDB
TO DISK = 'C:\Apress\TrainingDB_20120430_10AM.trn';
GO

--kick out connections
USE master; 
GO
-- Kicking out all other connections
ALTER DATABASE TrainingDB
SET SINGLE_USER
WITH ROLLBACK IMMEDIATE;
GO

--perform the restore
USE master;
GO
Declare @DeviceName Varchar(50);

Select @DeviceName = b.physical_device_name
	From msdb.dbo.backupset a
		INNER JOIN msdb.dbo.backupmediafamily b
			ON a.media_set_id = b.media_set_id
	Where a.database_name = 'TrainingDB'
		And a.type = 'D'
		And Convert(Varchar,a.backup_start_date,112) = Convert(Varchar,GetDate(),112);
RESTORE DATABASE TrainingDB
FROM DISK = @DeviceName
WITH NORECOVERY, REPLACE;
RESTORE LOG TrainingDB
FROM DISK = 'C:\Apress\ TrainingDB_20120430_8AM.trn'
WITH NORECOVERY, REPLACE

RESTORE LOG TrainingDB
FROM DISK = 'C:\Apress\ TrainingDB_20120430_10AM.trn'
WITH RECOVERY, REPLACE

--example two
USE master;
GO
BACKUP DATABASE TrainingDB
TO DISK = 'C:\Apress\TrainingDB_StopAt.bak';
GO

--delete some rows
USE TrainingDB;
GO
DELETE dbo.SalesOrderDetail
WHERE ProductID = 776;
GO
SELECT GETDATE();
GO

--backup log
BACKUP LOG TrainingDB
TO DISK = 'C:\Apress\TrainingDB_20120430_2022.trn';
GO

--restore database
USE master;
GO
RESTORE DATABASE TrainingDB
FROM DISK = 'C:\Apress\TrainingDB_StopAt.bak'
WITH FILE = 1, NORECOVERY,
STOPAT = '2012-04-30 22:17:10.563';
GO
--restore log
RESTORE LOG TrainingDB
FROM DISK = 'C:\Apress\TrainingDB_20120430_2022.trn'
WITH RECOVERY,
STOPAT = '2012-04-30 22:17:10.563';
GO

--confirm the restore
USE TrainingDB;
GO
SELECT COUNT(*)
FROM dbo.SalesOrderDetail
WHERE ProductID = 776;
GO

/* 27-3. Restoring a Database from a Differential Backup */

--setup the example
USE master;
GO
BACKUP DATABASE TrainingDB
TO DISK = 'C:\Apress\TrainingDB_DiffExample.bak';
GO
-- Time passes
BACKUP DATABASE TrainingDB
TO DISK = 'C:\Apress\TrainingDB_DiffExample.diff'
WITH DIFFERENTIAL;
GO

-- More time passes
BACKUP LOG TrainingDB
TO DISK = 'C:\Apress\TrainingDB_DiffExample_tlog.trn';
GO

--perform the restore
USE master;
GO
-- Full database restore
RESTORE DATABASE TrainingDB
FROM DISK = 'C:\Apress\TrainingDB_DiffExample.bak'
WITH NORECOVERY, REPLACE;
GO
-- Differential
RESTORE DATABASE TrainingDB
FROM DISK = 'C:\Apress\TrainingDB_DiffExample.diff'
WITH NORECOVERY;
GO
-- Transaction log
RESTORE LOG TrainingDB
FROM DISK = 'C:\Apress\TrainingDB_DiffExample_tlog.trn'
WITH RECOVERY;
GO

/* 27-4. Restoring a File or Filegroup */

USE master;
GO
If Not Exists (Select name from sys.databases where name = 'VLTestDB')
Begin
CREATE DATABASE VLTestDB
ON PRIMARY
     ( NAME = N'VLTestDB',FILENAME =N'c:\Apress\VLTestDB.mdf' 
    ,SIZE = 4072KB , FILEGROWTH = 0 ),
FILEGROUP FG2 
     ( NAME = N'VLTestDB2', FILENAME =N'c:\Apress\VLTestDB2.ndf'
    , SIZE = 3048KB , FILEGROWTH = 1024KB )
    ,( NAME = N'VLTestDB3', FILENAME =N'c:\Apress\VLTestDB3.ndf'
    , SIZE = 3048KB , FILEGROWTH = 1024KB )
LOG ON 
     ( NAME = N'VLTestDBLog', FILENAME =N'c:\Apress\VLTestDB_log.ldf' 
    , SIZE = 1024KB , FILEGROWTH = 10%);

Alter DATABASE VLTestDB
Modify FILEGROUP FG2 Default;

END
GO

USE master;
GO
BACKUP DATABASE VLTestDB
FILEGROUP = 'FG2'
TO DISK = 'C:\Apress\VLTestDB_FG2.bak'
WITH NAME = N'VLTestDB-Full Filegroup Backup',
SKIP, STATS = 20;
GO

--tlog backup after a bit of time
BACKUP LOG VLTestDB
TO DISK = 'C:\Apress\VLTestDB_FG_Example.trn';
GO

--restore FG2
USE master;
GO
RESTORE DATABASE VLTestDB
FILEGROUP = 'FG2'
FROM DISK = 'C:\Apress\VLTestDB_FG2.bak'
WITH FILE = 1, NORECOVERY, REPLACE;
RESTORE LOG VLTestDB
FROM DISK = 'C:\Apress\VLTestDB_FG_Example.trn'
WITH FILE = 1, RECOVERY;
GO

/* 27-5. Performing a Piecemeal (PARTIAL) Restore */

--backup primary and FG2 filegroup
USE master;
GO
BACKUP DATABASE VLTestDB
FILEGROUP = 'PRIMARY'
TO DISK = 'C:\Apress\VLTestDB_Primary_PieceExmp.bak';
GO
BACKUP DATABASE VLTestDB
FILEGROUP = 'FG2'
TO DISK = 'C:\Apress\VLTestDB_FG2_PieceExmp.bak';
GO

--t-log backup after some time
BACKUP LOG VLTestDB
TO DISK = 'C:\Apress\VLTestDB_PieceExmp.trn';
GO

--piecemeal restore
USE master;
GO
RESTORE DATABASE VLTestDB
FILEGROUP = 'PRIMARY'
FROM DISK = 'C:\Apress\VLTestDB_Primary_PieceExmp.bak'
WITH PARTIAL, NORECOVERY, REPLACE;
RESTORE LOG VLTestDB
FROM DISK = 'C:\Apress\VLTestDB_PieceExmp.trn'
WITH RECOVERY;
GO

--view status
USE VLTestDB;
GO
SELECT name,state_desc 
FROM sys.database_files;
GO

/* 27-6. Restoring a Page */

--Example setup
USE master;
GO
BACKUP DATABASE TestDB
TO DISK = 'C:\Apress\TestDB_PageExample.bak'
GO

--perform a restore
USE master;
GO
RESTORE DATABASE TestDB
PAGE='1:8'
FROM DISK = 'C:\Apress\TestDB_PageExample.bak'
WITH NORECOVERY, REPLACE;
GO

--perform tlog backup
BACKUP LOG TestDB
TO DISK = 'C:\Apress\TestDB_PageExample_tlog.trn';
GO

--final restore
RESTORE LOG TestDB
FROM DISK = 'C:\Apress\TestDB_PageExample_tlog.trn'
WITH RECOVERY;

/* 27-7. Identifying Databases with Multiple Recovery Paths */

--setup example
USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RomanHistory')
BEGIN
CREATE DATABASE RomanHistory;
END
GO
BACKUP DATABASE RomanHistory
TO DISK = 'C:\Apress\RomanHistory_A.bak';
GO
USE RomanHistory;
GO
CREATE TABLE EmperorTitle
(EmperorTitleID int NOT NULL PRIMARY KEY IDENTITY(1,1), TitleNM varchar(255));
GO

INSERT Into EmperorTitle (TitleNM)
    VALUES ('Aulus'), ('Imperator'), ('Pius Felix'), ('Ouintus')
BACKUP LOG RomanHistory
TO DISK = 'C:\Apress\RomanHistory_A.trn';
GO

--get database info
USE msdb;
GO
SELECT LastLSN = last_log_backup_lsn ,Rec_Fork = recovery_fork_guid 
    ,Frst_Fork = first_recovery_fork_guid ,Fork_LSN = fork_point_lsn  
FROM sys.database_recovery_status 
WHERE database_id = DB_ID('RomanHistory');
GO

--data modifications and tlog backup
USE RomanHistory;
GO
INSERT Into EmperorTitle (TitleNM)
    VALUES ('Germanicus'), ('Lucius'), ('Maximus'), ('Titus');
GO
BACKUP LOG RomanHistory
TO DISK = 'C:\Apress\RomanHistory_B.trn';
GO

--restore db to a prior state
USE master;
GO
RESTORE DATABASE RomanHistory
FROM DISK = 'C:\Apress\RomanHistory_A.bak'
WITH NORECOVERY, REPLACE;
RESTORE DATABASE RomanHistory
FROM DISK = 'C:\Apress\RomanHistory_A.trn'
WITH RECOVERY, REPLACE;
GO

--reissue the database info query
USE msdb;
GO
SELECT LastLSN = last_log_backup_lsn ,Rec_Fork = recovery_fork_guid 
    ,Frst_Fork = first_recovery_fork_guid ,Fork_LSN = fork_point_lsn  
FROM sys.database_recovery_status 
WHERE database_id = DB_ID('RomanHistory');
GO
