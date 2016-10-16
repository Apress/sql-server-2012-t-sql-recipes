2-1. Declaring Variables.

DECLARE @AddressLine1 nvarchar(60) = 'Heiderplatz';
SELECT AddressID, AddressLine1
FROM Person.Address
WHERE AddressLine1 LIKE '%' + @AddressLine1 + '%';


2-2. Retrieving a Value Into A Variable

DECLARE @AddressLine1 nvarchar(60); 
DECLARE @AddressLine2 nvarchar(60);
SELECT @AddressLine1 = AddressLine1, @AddressLine2 = AddressLine2
FROM Person.Address
WHERE AddressID = 66;
SELECT @AddressLine1 AS Address1, @AddressLine2 AS Address2; 


2-3. Writin an IF...THEN...ELSE Statement

DECLARE @QuerySelector int = 3;
IF @QuerySelector = 1 
BEGIN
   SELECT TOP 3 ProductID, Name, Color
   FROM Production.Product
   WHERE Color = 'Silver'
   ORDER BY Name
END
   ELSE 
BEGIN
   SELECT TOP 3 ProductID, Name, Color
   FROM Production.Product
   WHERE Color = 'Black'
   ORDER BY Name
END;


2-4. Writing a Simple CASE Expression

SELECT DepartmentID AS DeptID, Name, GroupName,
       CASE GroupName
          WHEN 'Research and Development' THEN 'Room A' 
          WHEN 'Sales and Marketing' THEN 'Room B' 
          WHEN 'Manufacturing' THEN 'Room C'
       ELSE 'Room D'
       END AS ConfRoom
FROM HumanResources.Department


2-5. Writing a Searched CASE Expression

SELECT DepartmentID, Name,
       CASE
          WHEN Name = 'Research and Development' THEN 'Room A' 
          WHEN (Name = 'Sales and Marketing' OR DepartmentID = 10) THEN 'Room B' 
          WHEN Name LIKE 'T%'THEN 'Room C' 
       ELSE 'Room D' END AS ConferenceRoom
FROM HumanResources.Department;


2-6. Writing a WHILE Statement

-- Declare variables
DECLARE @AWTables TABLE (SchemaTable varchar(100));
DECLARE @TableName varchar(100);

-- Insert table names into the table variable
INSERT @AWTables (SchemaTable)
   SELECT TABLE_SCHEMA + '.' + TABLE_NAME
   FROM INFORMATION_SCHEMA.tables
   WHERE TABLE_TYPE = 'BASE TABLE'
   ORDER BY TABLE_SCHEMA + '.' + TABLE_NAME;

-- Report on each table using sp_spaceused
WHILE (SELECT COUNT(*) FROM @AWTables) > 0
BEGIN
   SELECT TOP 1 @TableName = SchemaTable
   FROM @AWTables
   ORDER BY SchemaTable;

   EXEC sp_spaceused @TableName;
   DELETE @AWTables
   WHERE SchemaTable = @TableName;
END;


2-7. Returning from the Current Execution Scope

Solution #1

IF NOT EXISTS
   (SELECT ProductID
    FROM Production.Product
    WHERE Color = 'Pink')
BEGIN
   RETURN;
END;

SELECT ProductID
FROM Production.Product
WHERE Color = 'Pink';

Solution #2

CREATE PROCEDURE ReportPink AS
IF NOT EXISTS
   (SELECT ProductID
    FROM Production.Product
    WHERE Color = 'Pink')
BEGIN
   --Return the value 100 to indicate no pink products
   RETURN 100; 
END;

SELECT ProductID
FROM Production.Product
WHERE Color = 'Pink';


2-8. Going to a Label in a Transact-SQL Batch

DECLARE @Name nvarchar(50) = 'Engineering';
DECLARE @GroupName nvarchar(50) = 'Research and Development';
DECLARE @Exists bit = 0;

IF EXISTS (
   SELECT Name
   FROM HumanResources.Department 
   WHERE Name = @Name)
BEGIN
   SET @Exists = 1;
   GOTO SkipInsert; 
END;

INSERT INTO HumanResources.Department 
   (Name, GroupName)
   VALUES(@Name , @GroupName);

SkipInsert: IF @Exists = 1
BEGIN
   PRINT @Name + ' already exists in HumanResources.Department'; 
END
ELSE 
BEGIN
  PRINT 'Row added';
END;


2-9. Pausing Execution for a Period of Time

WAITFOR DELAY '00:00:10';
BEGIN
   SELECT TransactionID, Quantity
   FROM Production.TransactionHistory;
END;

WAITFOR TIME '12:22:00';
BEGIN
   SELECT COUNT(*)
   FROM Production.TransactionHistory;
END;


2-10. Creating and Using Cursors

-- Do not show rowcounts in the results 
SET NOCOUNT ON;

DECLARE @session_id smallint;

-- Declare the cursor 
DECLARE session_cursor CURSOR FORWARD_ONLY READ_ONLY FOR 
   SELECT session_id
   FROM sys.dm_exec_requests
   WHERE status IN ('runnable', 'sleeping', 'running');

-- Open the cursor 
OPEN session_cursor;

-- Retrieve one row at a time from the cursor
FETCH NEXT
   FROM session_cursor
   INTO @session_id;

-- Process and retrieve new rows until no more are available
WHILE @@FETCH_STATUS = 0
BEGIN
   PRINT 'Spid #: ' + STR(@session_id);
   EXEC ('sp_who ' + @session_id); 

   FETCH NEXT 
      FROM session_cursor
      INTO @session_id;
END;

-- Close the cursor 
CLOSE session_cursor;

-- Deallocate the cursor
DEALLOCATE session_cursor




