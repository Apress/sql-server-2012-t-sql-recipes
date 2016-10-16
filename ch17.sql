17-1. Selling the Benefits

No code for this recipe.


17-2. Creating a Stored Procedure

CREATE PROCEDURE dbo.ListCustomerNames
AS 
       SELECT   CustomerID,
                LastName,
                FirstName
       FROM     Sales.Customer sc
                INNER JOIN Person.Person pp
                    ON sc.CustomerID = pp.BusinessEntityID
       ORDER BY LastName,
                FirstName;

EXEC dbo.ListCustomerNames;


17-3. Generalizing a Stored Procedure

CREATE PROCEDURE dbo.LookupByAccount
(@AccountNumber VARCHAR(10),
 @UpperFlag CHAR(1))
AS 
       SELECT   CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(FirstName)
                  ELSE FirstName
                END AS FirstName,
                CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(LastName)
                  ELSE LastName
                END AS LastName
       FROM     Person.Person
       WHERE    BusinessEntityID IN (SELECT CustomerID
                                     FROM   Sales.Customer
                                     WHERE  AccountNumber = @AccountNumber) ;

EXEC LookupByAccount 'AW00000019', 'u';


17-4. Making Parameters Optional

DROP PROCEDURE dbo.LookupByAccount;

CREATE PROCEDURE dbo.LookupByAccount
(@AccountNumber VARCHAR(10),
 @UpperFlag CHAR(1) = 'x')
AS 
       SELECT   CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(FirstName)
                  ELSE FirstName
                END AS FirstName,
                CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(LastName)
                  ELSE LastName
                END AS LastName
       FROM     Person.Person
       WHERE    BusinessEntityID IN (SELECT CustomerID
                                     FROM   Sales.Customer
                                     WHERE  AccountNumber = @AccountNumber) ;

EXEC LookupByAccount 'AW00000019';


17-5. Making Early Parameters Optional

CREATE PROCEDURE dbo.LookupByAccount2
(@UpperFlag CHAR(1) = 'x',
@AccountNumber VARCHAR(10))
AS 
       SELECT   CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(FirstName)
                  ELSE FirstName
                END AS FirstName,
                CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(LastName)
                  ELSE LastName
                END AS LastName
       FROM     Person.Person
       WHERE    BusinessEntityID IN (SELECT CustomerID
                                     FROM   Sales.Customer
                                     WHERE  AccountNumber = @AccountNumber) ;

EXEC LookupByAccount2 @AccountNumber = 'AW00000019';


17-6. Returning Output

CREATE PROCEDURE dbo.EL_Department
       @GroupName NVARCHAR(50),
       @DeptCount INT OUTPUT
AS 
       SELECT   Name
       FROM     HumanResources.Department
       WHERE    GroupName = @GroupName
       ORDER BY Name;
       SELECT   @DeptCount = @@ROWCOUNT;

DECLARE @DeptCount INT;
EXEC dbo.SEL_Department 'Executive General and Administration',
    @DeptCount OUTPUT;
PRINT @DeptCount;


17-7. Modifying a Stored Procedure

ALTER PROCEDURE dbo.SEL_Department
      @GroupName NVARCHAR(50)
AS 
      SELECT    Name
      FROM      HumanResources.Department
      WHERE     GroupName = @GroupName
      ORDER BY  Name;
      SELECT    @@ROWCOUNT AS DepartmentCount;

EXEC dbo.SEL_Department 'Research and Development';


17-8. Removing a Stored Procedure

DROP PROCEDURE dbo.SEL_Department;


17-9. Automatically Run a Stored Procedure at Start-Up

CREATE TABLE dbo.SQLStartupLog
       (
        SQLStartupLogID INT IDENTITY(1, 1)
                            NOT NULL
                            PRIMARY KEY,
        StartupDateTime DATETIME NOT NULL
       );

CREATE PROCEDURE dbo.INS_TrackSQLStartups
AS 
       INSERT   dbo.SQLStartupLog
                (StartupDateTime)
       VALUES   (GETDATE());

EXEC sp_procoption @ProcName = 'INS_TrackSQLStartups',
    @OptionName = 'startup', @OptionValue = 'true';


17-10. Viewing a Stored Procedure's Definition

EXEC sp_helptext 'LookupByAccount';

SELECT  definition
FROM    sys.sql_modules m
        INNER JOIN sys.objects o
            ON m.object_id = o.object_id
WHERE   o.type = 'P'
        AND o.name = 'LookupByAccount';


17-11. Documenting Stored Procedures

CREATE PROCEDURE dbo.IMP_DWP_FactOrder AS
-- Purpose: Populates the data warehouse, Called by Job
-- Maintenance Log
-- Update By   Update Date
Description
-- Joe Sack     8/15/2008   Created
-- Joe Sack     8/16/2008   A new column was added to
--the base table, so it was added here as well.
... Transact-SQL code here


17-12. Determining the Current Nesting Level

-- First procedure
CREATE PROCEDURE dbo.QuickAndDirty
AS
SELECT @@NESTLEVEL;
GO
-- Second procedure
CREATE PROCEDURE dbo.Call_QuickAndDirty
AS
SELECT @@NESTLEVEL
EXEC dbo.QuickAndDirty;
GO

SELECT @@NESTLEVEL;
EXEC dbo.Call_QuickAndDirty;


17-13. Encrypting a Stored Procedure

CREATE PROCEDURE dbo.SEL_EmployeePayHistory
       WITH ENCRYPTION
AS 
       SELECT   BusinessEntityID,
                RateChangeDate,
                Rate,
                PayFrequency,
                ModifiedDate
       FROM     HumanResources.EmployeePayHistory;

SELECT  definition
FROM    sys.sql_modules m
        INNER JOIN sys.objects o
            ON m.object_id = o.object_id
WHERE   o.type = 'P'
        AND o.name = 'SEL_EmployeePayHistory';


17-14. Specifying a Security Context

CREATE PROCEDURE HumanResources.SEL_Department 
      @GroupName NVARCHAR(50)
WITH EXECUTE AS OWNER
AS 
      SELECT    Name
      FROM      HumanResources.Department
      WHERE     GroupName = @GroupName
      ORDER BY  Name;
      SELECT    @@ROWCOUNT AS DepartmentCount;


11-15. Avoiding Cached Query Plans

ALTER PROCEDURE dbo.LookupByAccount2
      (
       @UpperFlag VARCHAR(1) = 'x',
       @AccountNumber VARCHAR(10)
      )
      WITH RECOMPILE
AS 
      SELECT    CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(FirstName)
                  ELSE FirstName
                END AS FirstName,
                CASE UPPER(@UpperFlag)
                  WHEN 'U' THEN UPPER(LastName)
                  ELSE LastName
                END AS LastName
      FROM      Person.Person
      WHERE     BusinessEntityID IN (SELECT CustomerID
                                     FROM   Sales.Customer
                                     WHERE  AccountNumber = @AccountNumber);


11-16. Flushing the Procedure Cache

SELECT  COUNT(*) 'CachedPlansBefore'
FROM    sys.dm_exec_cached_plans;

DBCC FREEPROCCACHE;
SELECT  COUNT(*) 'CachedPlansAfter'
FROM    sys.dm_exec_cached_plans;


