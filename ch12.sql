/* 12-1. Using Explicit Transactions */

USE AdventureWorks2012;
GO
/* -- Before count */
SELECT BeforeCount = COUNT(*)  
FROM HumanResources.Department;
/* -- Variable to hold the latest error integer value */
DECLARE @Error int;
BEGIN TRANSACTION
INSERT INTO HumanResources.Department (Name, GroupName)
    VALUES ('Accounts Payable', 'Accounting');
SET @Error = @@ERROR;
IF (@Error<> 0) 
    GOTO Error_Handler;
INSERT INTO HumanResources.Department (Name, GroupName)
    VALUES ('Engineering', 'Research and Development');
SET @Error = @@ERROR;
IF (@Error <> 0) 
    GOTO Error_Handler;
COMMIT TRANSACTION
Error_Handler: 
IF @Error <> 0 
BEGIN
ROLLBACK TRANSACTION;
END
/* -- After count */
SELECT AfterCount = COUNT(*) 
FROM HumanResources.Department;  
GO

/* 12-2. Displaying the Oldest Active Transaction */

USE AdventureWorks2012;
GO
BEGIN TRANSACTION
DELETE Production.ProductProductPhoto 
WHERE ProductID = 317;

DBCC OPENTRAN('AdventureWorks2012');

ROLLBACK TRANSACTION;
GO

/* 12-3. Querying Transaction Information by Session */
--in first query window
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
USE AdventureWorks2012;
GO
BEGIN TRAN
SELECT *
FROM HumanResources.Department
INSERT HumanResources.Department (Name, GroupName) 
    VALUES ('Test', 'QA');


--in second query window
SELECT session_id, transaction_id, is_user_transaction, is_local 
FROM sys.dm_tran_session_transactions 
WHERE is_user_transaction = 1;
GO

SELECT s.text
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) s
WHERE c.most_recent_session_id = 51;--use the session_id returned by the previous query
GO

SELECT transaction_begin_time
,tran_type = CASE transaction_type
    WHEN 1 THEN 'Read/write transaction'
    WHEN 2 THEN 'Read-only transaction'
    WHEN 3 THEN 'System transaction'
    WHEN 4 THEN 'Distributed transaction' 
    END 
,tran_state = CASE transaction_state
    WHEN 0 THEN 'not been completely initialized yet'
    WHEN 1 THEN 'initialized but has not started'
    WHEN 2 THEN 'active'
    WHEN 3 THEN 'ended (read-only transaction)'
    WHEN 4 THEN 'commit initiated for distributed transaction'
    WHEN 5 THEN 'transaction prepared and waiting resolution'
    WHEN 6 THEN 'committed'
    WHEN 7 THEN 'being rolled back'
    WHEN 8 THEN 'been rolled back' 
    END  
FROM sys.dm_tran_active_transactions 
WHERE transaction_id = 145866; -- change this value to the transaction_id returned in the first 
--query of this recipe
GO

--return to first query window and execute the following
ROLLBACK TRANSACTION;

/* 12-4. Viewing Lock Activity */

--first query window
USE AdventureWorks2012;
BEGIN TRAN
SELECT ProductID, ModifiedDate 
FROM Production.ProductDocument WITH (TABLOCKX);

--second query window
SELECT sessionid = request_session_id ,
ResType = resource_type ,
ResDBID = resource_database_id ,
ObjectName = OBJECT_NAME(resource_associated_entity_id, resource_database_id) ,
RMode = request_mode ,
RStatus = request_status  
FROM sys.dm_tran_locks 
WHERE resource_type IN ('DATABASE', 'OBJECT');
GO

--return to first query window and execute the following
ROLLBACK TRANSACTION;

/* 12-5. Controlling a Table’s Lock Escalation Behavior */

USE AdventureWorks2012;
GO
ALTER TABLE Person.Address 
    SET ( LOCK_ESCALATION = AUTO );

SELECT lock_escalation,lock_escalation_desc 
FROM sys.tables WHERE name='Address';
GO

USE AdventureWorks2012;
GO
ALTER TABLE Person.Address
SET ( LOCK_ESCALATION = DISABLE);

SELECT lock_escalation,lock_escalation_desc 
FROM sys.tables WHERE name='Address';
GO

/* 12-6. Configuring a Session’s Transaction Locking Behavior */

--first query window
USE AdventureWorks2012;
GO
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
GO
BEGIN TRAN

SELECT  AddressTypeID, Name
FROM Person.AddressType
WHERE AddressTypeID BETWEEN 1 AND 6;
GO

--second query window
SELECT resource_associated_entity_id, resource_type,
request_mode, request_session_id 
FROM sys.dm_tran_locks;
GO

--execute the following in the first query window
COMMIT TRAN

--example two
--first query window
USE AdventureWorks2012;
GO
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
BEGIN TRAN

SELECT  AddressTypeID, Name
FROM Person.AddressType
WHERE AddressTypeID BETWEEN 1 AND 6;
GO

--second query window
SELECT resource_associated_entity_id, resource_type,
request_mode, request_session_id 
FROM sys.dm_tran_locks;
GO

--execute the following in the first query window
COMMIT TRAN

--example three
--first query window
ALTER DATABASE AdventureWorks2012
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO
USE AdventureWorks2012;
GO
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
GO
BEGIN TRAN
SELECT  CurrencyRateID,EndOfDayRate 
FROM Sales.CurrencyRate 
WHERE CurrencyRateID = 8317;

--second query window
USE AdventureWorks2012;
GO
UPDATE Sales.CurrencyRate 
SET EndOfDayRate = 1.00 
WHERE CurrencyRateID = 8317;
GO

--back in the first query window
SELECT  CurrencyRateID,EndOfDayRate 
FROM Sales.CurrencyRate 
WHERE CurrencyRateID = 8317;
GO

--in the first query window
COMMIT TRAN
SELECT  CurrencyRateID,EndOfDayRate 
FROM Sales.CurrencyRate 
WHERE CurrencyRateID = 8317;
GO

/* 12-6. Identifying and Resolving Blocking Issues */

--first query window
USE AdventureWorks2012;
GO
BEGIN TRAN
UPDATE Production.ProductInventory 
SET Quantity = 400 
WHERE ProductID = 1 AND LocationID = 1;

--second query window
USE AdventureWorks2012;
GO
BEGIN TRAN
UPDATE Production.ProductInventory 
SET Quantity = 406 
WHERE ProductID = 1 AND LocationID = 1;

--third query window
SELECT blocking_session_id, wait_duration_ms, session_id
FROM sys.dm_os_waiting_tasks
WHERE blocking_session_id IS NOT NULL;
GO

SELECT t.text
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) t
WHERE c.session_id = 53; --your spid may be different
GO

KILL 53; --your spid may be different

/* 12-7. Configuring How Long a Statement Will Wait for a Lock to Be Released */

--first query window
USE AdventureWorks2012;
GO
BEGIN TRAN
UPDATE Production.ProductInventory 
SET Quantity = 400 
WHERE ProductID = 1 AND LocationID = 1;

--second query window
USE AdventureWorks2012;
GO
SET LOCK_TIMEOUT 1000;
UPDATE Production.ProductInventory 
SET Quantity = 406 
WHERE ProductID = 1 AND LocationID = 1;

--from the first query window
ROLLBACK TRANSACTION;

/* 12-8. Identifying Deadlocks with a Trace Flag */

--first query window
USE AdventureWorks2012;
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
WHILE 1=1 
BEGIN 
BEGIN TRAN
UPDATE Purchasing.Vendor
SET CreditRating = 1
WHERE BusinessEntityID = 1494;
UPDATE Purchasing.Vendor
SET CreditRating = 2
WHERE BusinessEntityID = 1492;
COMMIT TRAN 
END

--second query window
USE AdventureWorks2012;
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
WHILE 1=1 
BEGIN 
BEGIN TRAN
UPDATE Purchasing.Vendor
SET CreditRating = 2
WHERE BusinessEntityID = 1492;
UPDATE Purchasing.Vendor
SET CreditRating = 1
WHERE BusinessEntityID = 1494;
COMMIT TRAN 
END

--third query window
DBCC TRACEON (1222, -1)
GO
DBCC TRACESTATUS

--examine log and disable trace flag
DBCC TRACEOFF (1222, -1)
GO
DBCC TRACESTATUS

--return to the first window
ROLLBACK TRANSACTION;

/* 12-9. Setting Deadlock Priority */

USE AdventureWorks2012;
GO
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SET DEADLOCK_PRIORITY LOW;
WHILE 1=1 
BEGIN

BEGIN TRAN
UPDATE Purchasing.Vendor
SET CreditRating = 1
WHERE BusinessEntityID = 2;

UPDATE Purchasing.Vendor
SET CreditRating = 2
WHERE BusinessEntityID = 1;

COMMIT TRAN
END
GO
