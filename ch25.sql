-- 25-0. Chapter setup
IF DB_ID('BookStoreArchive') IS NOT NULL DROP DATABASE BookStoreArchive;
GO

CREATE DATABASE BookStoreArchive 
ON PRIMARY
(NAME = 'BookStoreArchive', 
 FILENAME = 'N:\Apress\BookStoreArchive.MDF', 
 SIZE = 3MB, 
 MAXSIZE = UNLIMITED, 
 FILEGROWTH = 10MB)
LOG ON
(NAME = 'BookStoreArchive_log', 
 FILENAME = 'P:\Apress\BookStoreArchive_log.LDF', 
 SIZE = 512KB, 
 MAXSIZE = UNLIMITED, 
 FILEGROWTH = 512KB);


-- 25-1. Adding a Data File or a Log File
ALTER DATABASE BookStoreArchive
ADD FILE
(  NAME = 'BookStoreArchive2',
FILENAME = 'O:\Apress\BookStoreArchive2.NDF' ,
SIZE = 1MB ,
MAXSIZE = 10MB,
FILEGROWTH = 1MB ) 
TO FILEGROUP [PRIMARY];

ALTER DATABASE BookStoreArchive
ADD LOG FILE
(  NAME = 'BookStoreArchive2Log',
FILENAME = 'P:\Apress\BookStoreArchive2_log.LDF' ,
SIZE = 1MB ,
MAXSIZE = 5MB,
FILEGROWTH = 1MB );
GO


-- 25-2. Removing a Data File or a Log File
USE BookStoreArchive; 
GO
SELECT  name
FROM    sys.database_files;

DBCC SHRINKFILE(BookStoreArchive2, EMPTYFILE);

ALTER DATABASE BookStoreArchive REMOVE FILE BookStoreArchive2;

SELECT  name
FROM    sys.database_files;


-- 25-3. Relocating a Data File or a Log File
ALTER DATABASE BookStoreArchive
MODIFY FILE
(NAME = 'BookStoreArchive', FILENAME = 'O:\Apress\BookStoreArchive.mdf')
GO

USE master;
GO
ALTER DATABASE BookStoreArchive SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE BookStoreArchive SET OFFLINE;
GO
-- Move BookStoreArchive.mdf file from N:\Apress\ to O:\Apress now.
-- On my Windows 7 PC, I had to use Administrator access to move the file.
-- On other systems, you may have to modify file/folder permissions
-- to prevent an access denied error.
USE master;
GO
ALTER DATABASE BookStoreArchive SET ONLINE;
GO
ALTER DATABASE BookStoreArchive SET MULTI_USER WITH ROLLBACK IMMEDIATE;
GO


-- 25-4. Changing a File’s Logical Name
IF EXISTS ( SELECT  name
            FROM    sys.database_files
            WHERE   name = 'BookStoreArchive_Data' ) 
   ALTER DATABASE BookStoreArchive
   MODIFY FILE
   (NAME = 'BookStoreArchive_Data', NEWNAME = 'BookStoreArchive');

SELECT  name
FROM    sys.database_files;

ALTER DATABASE BookStoreArchive
MODIFY FILE
(NAME = 'BookStoreArchive',
NEWNAME = 'BookStoreArchive_Data');

SELECT  name
FROM    sys.database_files;


-- 25-5. Increasing the Size of a Database File
SELECT name, size FROM BookStoreArchive.sys.database_files;

ALTER DATABASE BookStoreArchive
MODIFY FILE
(NAME = 'BookStoreArchive_Data',
 SIZE = 5MB);

SELECT name, size FROM BookStoreArchive.sys.database_files;


-- 25-6. Adding a Filegroup
ALTER DATABASE BookStoreArchive
ADD FILEGROUP FG2;


-- 25-7. Adding a File to a Filegroup
ALTER DATABASE BookStoreArchive
ADD FILE
(  NAME = 'BW2',
FILENAME = 'N:\Apress\FG2_BookStoreArchive.NDF' ,
SIZE = 1MB ,
MAXSIZE = 50MB,
FILEGROWTH = 5MB ) 
TO FILEGROUP [FG2];
GO


-- 25-8. Setting the Default Filegroup
ALTER DATABASE BookStoreArchive
MODIFY FILEGROUP FG2 DEFAULT;


-- 25-9. Adding Data to a Specific Filegroup
CREATE TABLE dbo.Test
       (
        TestID  INT IDENTITY,
        Column1 INT,
        Column2 INT,
        Column3 INT
       )
ON     [FG2];
/*
SELECT name, data_space_id FROM sys.filegroups;
SELECT file_id, name, data_space_id, physical_name FROM sys.database_files;
SELECT * FROM sys.tables;
*/



-- 25-10. Moving Data to a Different Filegroup
-- Solution 1
ALTER TABLE dbo.Test
ADD CONSTRAINT PK_Test PRIMARY KEY CLUSTERED (TestId)
ON [PRIMARY];

-- Solution 2
CREATE TABLE dbo.Test2
       (
        TestID INT IDENTITY
                   CONSTRAINT PK__Test2 PRIMARY KEY CLUSTERED,
        Column1 INT,
        Column2 INT,
        Column3 INT
       )
ON     [FG2];
GO

ALTER TABLE dbo.Test2
DROP CONSTRAINT PK__Test2;
ALTER TABLE dbo.Test2
ADD CONSTRAINT PK__Test2 PRIMARY KEY CLUSTERED (TestId)
ON [PRIMARY];

-- Solution 3
CREATE TABLE dbo.Test3
       (
        TestID INT IDENTITY,
        Column1 INT,
        Column2 INT,
        Column3 INT
       )
ON     [FG2];
GO

CREATE CLUSTERED INDEX IX_Test3 ON dbo.Test3 (TestId) 
ON [FG2];
GO

CREATE CLUSTERED INDEX IX_Test3 ON dbo.Test3 (TestId)
WITH (DROP_EXISTING = ON)
ON [PRIMARY];



-- 25-11. Removing a Filegroup
/*
SELECT * FROM sys.database_files;
SELECT * FROM sys.filegroups;
*/
ALTER DATABASE BookStoreArchive
MODIFY FILEGROUP [PRIMARY] DEFAULT;
GO

ALTER DATABASE BookStoreArchive 
REMOVE FILE BW2;
GO

ALTER DATABASE BookStoreArchive
REMOVE FILEGROUP FG2;
GO



-- 25-12. Making a Database or a Filegroup Read-Only
SELECT * FROM sys.filegroups;
SELECT * FROM sys.database_files;

/*
ALTER DATABASE BookStoreArchive SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO
alter database BookStoreArchive modify filegroup FG3 READ_WRITE;
GO
alter database BookStoreArchive remove file ArchiveData;
GO
alter database BookStoreArchive remove filegroup FG3;
GO
ALTER DATABASE BookStoreArchive SET MULTI_USER;
GO
*/

ALTER DATABASE BookStoreArchive SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE BookStoreArchive
ADD FILEGROUP FG3;
GO

ALTER DATABASE BookStoreArchive
ADD FILE
(  NAME = 'ArchiveData',
FILENAME = 'N:\Apress\BookStoreArchiveData.NDF' ,
SIZE = 1MB ,
MAXSIZE = 10MB,
FILEGROWTH = 1MB ) 
TO FILEGROUP [FG3];
GO
-- move historical tables to this filegroup

ALTER DATABASE BookStoreArchive
MODIFY FILEGROUP FG3 READ_ONLY;
GO

ALTER DATABASE BookStoreArchive SET MULTI_USER;
GO


ALTER DATABASE BookStoreArchive SET READ_ONLY;
GO

ALTER DATABASE BookStoreArchive SET READ_WRITE;
GO


-- 25-13. Viewing Database Space Usage
--SELECT * FROM sys.tables;

EXECUTE sp_spaceused;
EXECUTE sp_spaceused 'dbo.test';
DBCC SQLPERF(LOGSPACE);



-- 25-14. Shrinking the Database or a Database File
--SELECT * FROM sys.database_files;

-- DBCC SHRINKDATABASE
ALTER DATABASE BookStoreArchive
MODIFY FILE (NAME = 'BookStoreArchive_log', SIZE = 100MB);

ALTER DATABASE BookStoreArchive
MODIFY FILE (NAME = 'BookStoreArchive_Data', SIZE = 200MB);
GO

USE BookStoreArchive;
GO

EXECUTE sp_spaceused;
GO

DBCC SHRINKDATABASE ('BookStoreArchive', 10);
GO

EXECUTE sp_spaceused;
GO


-- DBCC SHRINKFILE
ALTER DATABASE BookStoreArchive
MODIFY FILE (NAME = 'BookStoreArchive_log', SIZE = 200MB);
GO

USE BookStoreArchive;
GO

EXECUTE sp_spaceused;
GO

DBCC SHRINKFILE ('BookStoreArchive_log', 2);
GO

EXECUTE sp_spaceused;
GO


-- 25-15. Checking Consistency of Allocation Structures
DBCC CHECKALLOC ('BookStoreArchive');


-- 25-16. Checking Allocation and Structural Integrity
ALTER DATABASE BookStoreArchive SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE BookStoreArchive MODIFY FILEGROUP FG3 READ_WRITE;
ALTER DATABASE BookStoreArchive SET MULTI_USER;

DBCC CHECKDB ('BookStoreArchive');


-- 25-17. Checking Integrity of Tables in a Filegroup
USE BookStoreArchive;
GO
DBCC CHECKFILEGROUP ('PRIMARY');


-- 25-18. Checking Integrity of Specific Tables and Indexed Views
DBCC CHECKTABLE ('Production.Product');

DBCC CHECKTABLE ('Sales.SalesOrderDetail') WITH ESTIMATEONLY;

SELECT index_id
FROM  sys.indexes
WHERE  object_id = OBJECT_ID('Sales.SalesOrderDetail')
AND name = 'IX_SalesOrderDetail_ProductID';

DBCC CHECKTABLE ('Sales.SalesOrderDetail', 3) WITH PHYSICAL_ONLY;


-- 25-19. Checking Constraint Integrity
SET NOCOUNT ON;
GO
USE AdventureWorks2012;
GO
SELECT enddate FROM Production.WorkOrder AS wo WHERE WorkOrderID = 1;
GO


ALTER TABLE Production.WorkOrder NOCHECK CONSTRAINT CK_WorkOrder_EndDate; 
GO
-- Set an EndDate to earlier than a StartDate
UPDATE Production.WorkOrder
SET EndDate = '2001-01-01T00:00:00'
WHERE WorkOrderID = 1;
GO
ALTER TABLE Production.WorkOrder CHECK CONSTRAINT CK_WorkOrder_EndDate;
GO
DBCC CHECKCONSTRAINTS ('Production.WorkOrder');
GO

UPDATE Production.WorkOrder
SET EndDate = '2005-07-14T00:00:00'
WHERE WorkOrderID = 1;
GO

DBCC CHECKCONSTRAINTS ('Production.WorkOrder');
GO


-- 25-20. Checking System Table Consistency
DBCC CHECKCATALOG ('BookStoreArchive');