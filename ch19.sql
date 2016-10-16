-- 19-1. Creating an AFTER DML Trigger
-- Create a table to Track all Inserts and Deletes 
CREATE TABLE Production.ProductInventoryAudit
       (
        ProductID INT NOT NULL,
        LocationID SMALLINT NOT NULL,
        Shelf NVARCHAR(10) NOT NULL,
        Bin TINYINT NOT NULL,
        Quantity SMALLINT NOT NULL,
        rowguid UNIQUEIDENTIFIER NOT NULL,
        ModifiedDate DATETIME NOT NULL,
        InsertOrDelete CHAR(1) NOT NULL
       );
GO
-- Create trigger to populate Production.ProductInventoryAudit table
CREATE TRIGGER Production.trg_id_ProductInventoryAudit ON Production.ProductInventory
       AFTER INSERT, DELETE
AS
BEGIN
       SET NOCOUNT ON;
-- Inserted rows
       INSERT   Production.ProductInventoryAudit
                (ProductID,
                 LocationID,
                 Shelf,
                 Bin,
                 Quantity,
                 rowguid,
                 ModifiedDate,
                 InsertOrDelete)
                SELECT DISTINCT
                        i.ProductID,
                        i.LocationID,
                        i.Shelf,
                        i.Bin,
                        i.Quantity,
                        i.rowguid,
                        GETDATE(),
                        'I'
                FROM    inserted i
                UNION ALL
                SELECT  d.ProductID,
                        d.LocationID,
                        d.Shelf,
                        d.Bin,
                        d.Quantity,
                        d.rowguid,
                        GETDATE(),
                        'D'
                FROM    deleted d;

END
GO

-- Insert a new row 
INSERT  Production.ProductInventory
        (ProductID,
         LocationID,
         Shelf,
         Bin,
         Quantity)
VALUES  (316,
         6,
         'A',
         4,
         22);

-- Delete a row
DELETE  Production.ProductInventory
WHERE   ProductID = 316
        AND LocationID = 6;

-- Check the audit table
SELECT  ProductID,
        LocationID,
        InsertOrDelete
FROM    Production.ProductInventoryAudit;

-- 19-2. Creating an INSTEAD OF DML Trigger
-- Create Department "Approval" table 
CREATE TABLE HumanResources.DepartmentApproval
       (
        Name NVARCHAR(50) NOT NULL
                          UNIQUE,
        GroupName NVARCHAR(50) NOT NULL,
        ModifiedDate DATETIME NOT NULL
                              DEFAULT GETDATE()
       ) ;
GO
-- Create view to see both approved and pending approval departments
CREATE VIEW HumanResources.vw_Department
AS
       SELECT   Name,
                GroupName,
                ModifiedDate,
                'Approved' Status
       FROM     HumanResources.Department
       UNION
       SELECT   Name,
                GroupName,
                ModifiedDate,
                'Pending Approval' Status
       FROM     HumanResources.DepartmentApproval ;
GO

-- Create an INSTEAD OF trigger on the new view
CREATE TRIGGER HumanResources.trg_vw_Department ON HumanResources.vw_Department
       INSTEAD OF INSERT
AS
       SET NOCOUNT ON
       INSERT   HumanResources.DepartmentApproval
                (Name,
                 GroupName)
                SELECT  i.Name,
                        i.GroupName
                FROM    inserted i
                WHERE   i.Name NOT IN (
                        SELECT  Name
                        FROM    HumanResources.DepartmentApproval) ;
GO

-- Insert into the new view, even though view is a UNION
-- of two different tables
INSERT  HumanResources.vw_Department
        (Name,
         GroupName)
VALUES  ('Print Production',
         'Manufacturing') ;

-- Check the view's contents 
SELECT  Status,
        Name
FROM    HumanResources.vw_Department
WHERE   GroupName = 'Manufacturing' ;

-- 19-3. Handling Transactions in Triggers
ALTER TRIGGER Production.trg_id_ProductInventoryAudit ON Production.ProductInventory
       AFTER INSERT, DELETE
AS
       SET NOCOUNT ON ;
       IF EXISTS ( SELECT   Shelf
                   FROM     inserted
                   WHERE    Shelf = 'A' ) 
          BEGIN
                PRINT 'Shelf ''A'' is closed for new inventory.' ;
                ROLLBACK ;
          END
-- Inserted rows
       INSERT   Production.ProductInventoryAudit
                (ProductID,
                 LocationID,
                 Shelf,
                 Bin,
                 Quantity,
                 rowguid,
                 ModifiedDate,
                 InsertOrDelete)
                SELECT DISTINCT
                        i.ProductID,
                        i.LocationID,
                        i.Shelf,
                        i.Bin,
                        i.Quantity,
                        i.rowguid,
                        GETDATE(),
                        'I'
                FROM    inserted i ;
-- Deleted rows
       INSERT   Production.ProductInventoryAudit
                (ProductID,
                 LocationID,
                 Shelf,
                 Bin,
                 Quantity,
                 rowguid,
                 ModifiedDate,
                 InsertOrDelete)
                SELECT  d.ProductID,
                        d.LocationID,
                        d.Shelf,
                        d.Bin,
                        d.Quantity,
                        d.rowguid,
                        GETDATE(),
                        'D'
                FROM    deleted d ;
       IF EXISTS ( SELECT   Quantity
                   FROM     deleted
                   WHERE    Quantity > 0 ) 
          BEGIN
                PRINT 'You cannot remove positive quantity rows!' ;
                ROLLBACK ;
          END
GO


INSERT  Production.ProductInventory
        (ProductID,
         LocationID,
         Shelf,
         Bin,
         Quantity)
VALUES  (316,
         6,
         'A',
         4,
         22) ;


BEGIN TRANSACTION ;
-- Deleting a row with a zero quantity 
DELETE  Production.ProductInventory
WHERE   ProductID = 853
        AND LocationID = 7 ;
-- Deleting a row with a non-zero quantity 
DELETE  Production.ProductInventory
WHERE   ProductID = 999
        AND LocationID = 60 ;
COMMIT TRANSACTION ;


-- 19-4. Linking Trigger Execution to Modified Columns 

CREATE TRIGGER HumanResources.trg_U_Department ON HumanResources.Department
       AFTER UPDATE
AS
       IF UPDATE(GroupName) 
          BEGIN
                PRINT 'Updates to GroupName require DBA involvement.' ;
                ROLLBACK  ;
          END 
GO

UPDATE  HumanResources.Department
SET     GroupName = 'Research and Development'
WHERE   DepartmentID = 10 ;

-- 19-5. Viewing DML Trigger Metadata
-- Show the DML triggers in the current database 
SELECT  OBJECT_NAME(parent_id) Table_or_ViewNM,
        name TriggerNM,
        is_instead_of_trigger,
        is_disabled
FROM    sys.triggers
WHERE   parent_class_desc = 'OBJECT_OR_COLUMN'
ORDER BY OBJECT_NAME(parent_id),
        Name ;

-- Displays the trigger SQL definition --(if the trigger is not encrypted) 
SELECT  o.name,
        m.definition
FROM    sys.sql_modules m
        INNER JOIN sys.objects o
            ON m.object_id = o.object_id
WHERE   o.type = 'TR'
        AND o.name = 'trg_id_ProductInventoryAudit'

-- 19-6. Creating a DDL Trigger

CREATE TABLE dbo.DDLAudit
              (
              EventData XML NOT NULL,
              AttemptDate DATETIME NOT NULL
                          DEFAULT GETDATE(),
              DBUser CHAR(50) NOT NULL
              ) ;
GO


CREATE TRIGGER db_trg_INDEXChanges ON DATABASE
       FOR CREATE_INDEX, ALTER_INDEX, DROP_INDEX
AS
       SET NOCOUNT ON ;
       INSERT   dbo.DDLAudit
                (EventData, DBUser)
       VALUES   (EVENTDATA(), USER) ;
GO

CREATE NONCLUSTERED INDEX ni_DDLAudit_DBUser ON
dbo.DDLAudit(DBUser) ;
GO

SELECT  EventData
FROM    dbo.DDLAudit

-- 19-7. Creating a Logon Trigger

CREATE LOGIN nightworker WITH PASSWORD = 'pass@word1' ;
GO


CREATE DATABASE ExampleAuditDB ;
GO
USE ExampleAuditDB ;
GO
CREATE TABLE dbo.RestrictedLogonAttempt
       (
        LoginNM SYSNAME NOT NULL,
        AttemptDT DATETIME NOT NULL
       ) ;
GO

USE master ;
GO
CREATE TRIGGER trg_logon_attempt ON ALL SERVER
 WITH EXECUTE AS 'sa'
       FOR LOGON
AS
       BEGIN
             IF ORIGINAL_LOGIN() = 'nightworker'
                AND DATEPART(hh, GETDATE()) BETWEEN 7 AND 18 
                BEGIN
                      ROLLBACK ;
                      INSERT    ExampleAuditDB.dbo.RestrictedLogonAttempt
                                (LoginNM, AttemptDT)
                      VALUES    (ORIGINAL_LOGIN(), GETDATE()) ;
                END 
       END 
GO

SELECT  LoginNM,
        AttemptDT
FROM    ExampleAuditDB.dbo.RestrictedLogonAttempt

-- 19-8. Viewing DDL Trigger Metadata	
SELECT  name TriggerNM,
        is_disabled
FROM    sys.triggers
WHERE   parent_class_desc = 'DATABASE'
ORDER BY OBJECT_NAME(parent_id),
        Name ;

SELECT  name,
        s.type_desc S0L_or_CLR,
        is_disabled,
        e.type_desc FiringEvents
FROM    sys.server_triggers s
        INNER JOIN sys.server_trigger_events e
            ON s.object_id = e.object_id ;

SELECT  t.name,
        m.Definition
FROM    sys.triggers AS t
        INNER JOIN sys.sql_modules m
            ON t.object_id = m.object_id
WHERE   t.parent_class_desc = 'DATABASE' ;

SELECT  t.name,
        m.definition
FROM    sys.server_sql_modules m
        INNER JOIN sys.server_triggers t
            ON m.object_id = t.object_id ;

-- 19-9. Modifying a Trigger
USE master ;
GO
ALTER TRIGGER trg_logon_attempt ON ALL SERVER
 WITH EXECUTE AS 'sa'
       FOR LOGON
AS
       BEGIN
             IF ORIGINAL_LOGIN() = 'nightworker'
                AND DATEPART(hh, GETDATE()) BETWEEN 7 AND 18 
                BEGIN
                      --ROLLBACK ;
                      INSERT    ExampleAuditDB.dbo.RestrictedLogonAttempt
                                (LoginNM, AttemptDT)
                      VALUES    (ORIGINAL_LOGIN(), GETDATE()) ;
                END 
       END 
GO

SELECT  LoginNM,
        AttemptDT
FROM    ExampleAuditDB.dbo.RestrictedLogonAttempt ;


-- 19-10. Enabling and Disabling a Trigger
CREATE TRIGGER HumanResources.trg_Department ON HumanResources.Department
       AFTER INSERT
AS
       PRINT 'The trg_Department trigger was fired' ;
GO

DISABLE TRIGGER HumanResources.trg_Department 

INSERT  HumanResources.Department
        (Name,
         GroupName)
VALUES  ('Construction',
         'Building Services') ;

19-11. Nesting Triggers
USE master ;
GO
-- Disable nesting
EXEC sp_configure 'nested triggers', 0 ;
RECONFIGURE WITH OVERRIDE ;
GO
-- Enable nesting
EXEC sp_configure 'nested triggers', 1 ;
RECONFIGURE WITH OVERRIDE ;
GO

-- 19-12. Controlling Recursion

-- Allow recursion
ALTER DATABASE AdventureWorks2012
SET RECURSIVE_TRIGGERS ON ;

-- View the db setting
SELECT  is_recursive_triggers_on
FROM    sys.databases
WHERE   name = 'AdventureWorks2012' ;

-- Prevents recursion
ALTER DATABASE AdventureWorks2012
SET RECURSIVE_TRIGGERS OFF ;

-- View the db setting
SELECT  is_recursive_triggers_on
FROM    sys.databases
WHERE   name = 'AdventureWorks2012' ;


-- 19-13. Specifying the Firing Order
CREATE TABLE dbo.TestTriggerOrder (TestID INT NOT NULL) ;
GO

CREATE TRIGGER dbo.trg_i_TestTriggerOrder ON dbo.TestTriggerOrder
       AFTER INSERT
AS
       PRINT 'I will be fired first.' ;
GO

CREATE TRIGGER dbo.trg_i_TestTriggerOrder2 ON dbo.TestTriggerOrder
       AFTER INSERT
AS
       PRINT 'I will be fired last.' ;
GO

CREATE TRIGGER dbo.trg_i_TestTriggerOrder3 ON dbo.TestTriggerOrder
       AFTER INSERT
AS
       PRINT 'I will be somewhere in the middle.' ;
GO

EXEC sp_settriggerorder 'trg_i_TestTriggerOrder', 'First', 'INSERT' ;
EXEC sp_settriggerorder 'trg_i_TestTriggerOrder2', 'Last', 'INSERT' ;

INSERT  dbo.TestTriggerOrder
        (TestID)
VALUES  (1) ;

-- 19-14. Dropping a Trigger
-- Switch context back to the AdventureWorks2012 database
USE AdventureWorks2012 ;
GO
-- Drop a DML trigger
DROP TRIGGER dbo.trg_i_TestTriggerOrder ;
-- Drop multiple DML triggers
DROP TRIGGER dbo.trg_i_TestTriggerOrder2, dbo.trg_i_TestTriggerOrder3 ;
-- Drop a DDL trigger
DROP TRIGGER db_trg_INDEXChanges 
ON DATABASE ;

