USE AdventureWorks2012;
GO

-- 6-1. Avoiding Duplicate Results
-- solution 1
SELECT  DISTINCT HireDate
FROM    HumanResources.Employee
ORDER BY HireDate;

-- solution 2
SELECT  HireDate
FROM    HumanResources.Employee
GROUP BY HireDate
ORDER BY HireDate;USE AdventureWorks2012;
GO

-- 6-2. Returning the Top N Rows
SELECT  TOP (5) HireDate
FROM    HumanResources.Employee
GROUP BY HireDate
ORDER BY HireDate DESC;
GO

SELECT  TOP (5) PERCENT HireDate
FROM    HumanResources.Employee
GROUP BY HireDate
ORDER BY HireDate DESC;
GO

-- 6-3. Renaming a Column in the Output
SELECT ss.name AS SchemaName,
       TableName = st.name,
       st.object_id ObjectId
FROM sys.schemas AS ss
     JOIN sys.tables st
       ON ss.schema_id = st.schema_id
ORDER BY SchemaName, TableName;
USE AdventureWorks2012;
GO

-- 6-4. Retrieving Data Directly into Variables
DECLARE @FirstHireDate DATE,
        @LastHireDate  DATE;

SELECT @FirstHireDate = MIN(HireDate),
       @LastHireDate = MAX(HireDate)
FROM    HumanResources.Employee;

SELECT @FirstHireDate AS FirstHireDate,
       @LastHireDate AS LastHireDate;USE AdventureWorks2012;
GO

-- 6-5. Creating a New Table with the Results from a Query
IF OBJECT_ID('tempdb..#Sales') IS NOT NULL 
   DROP TABLE #Sales;

SELECT  *
INTO    #Sales
FROM    Sales.SalesOrderDetail
WHERE   ModifiedDate = '2005-07-01';
GO

SELECT  COUNT(*) AS QtyOfRows
FROM    #Sales;
USE AdventureWorks2012;
GO

-- 6-6. Filtering on the Results from a Subquery
SELECT  s.PurchaseOrderNumber
FROM    Sales.SalesOrderHeader s
WHERE   EXISTS ( SELECT SalesOrderID
                 FROM   Sales.SalesOrderDetail
                 WHERE  UnitPrice BETWEEN 1900 AND 2000
                        AND SalesOrderID = s.SalesOrderID );
GO

SELECT DISTINCT sh.PurchaseOrderNumber 
FROM Sales.SalesOrderHeader AS sh
     JOIN Sales.SalesOrderDetail AS sd
     ON sh.SalesOrderID = sd.SalesOrderID
WHERE sd.UnitPrice BETWEEN 1900 AND 2000;
GO

-- 6-7. Selecting from the Results of Another Query
WITH cte AS 
(
    SELECT    SalesOrderID
    FROM      Sales.SalesOrderDetail
    WHERE     UnitPrice BETWEEN 1900 AND 2000
)
SELECT s.PurchaseOrderNumber
FROM   Sales.SalesOrderHeader AS s
WHERE  EXISTS ( SELECT SalesOrderId
                FROM   cte
                WHERE  SalesOrderID = s.SalesOrderID );
GO

SELECT DISTINCT
        s.PurchaseOrderNumber
FROM    Sales.SalesOrderHeader s
        INNER JOIN (SELECT  SalesOrderID
                    FROM    Sales.SalesOrderDetail
                    WHERE   UnitPrice BETWEEN 1900 AND 2000
                   ) dt
            ON s.SalesOrderID = dt.SalesOrderID;
GO

-- 6-8. Passing Rows Through a Function
IF OBJECT_ID('dbo.fn_WorkOrderRouting') IS NOT NULL 
   DROP FUNCTION dbo.fn_WorkOrderRouting;
GO

CREATE FUNCTION dbo.fn_WorkOrderRouting (@WorkOrderID INT)
RETURNS TABLE
       AS
RETURN
       SELECT   WorkOrderID,
                ProductID,
                OperationSequence,
                LocationID
       FROM     Production.WorkOrderRouting
       WHERE    WorkOrderID = @WorkOrderID;
GO

SELECT TOP (5)
        w.WorkOrderID,
        w.OrderQty,
        r.ProductID,
        r.OperationSequence
FROM    Production.WorkOrder w
        CROSS APPLY dbo.fn_WorkOrderRouting(w.WorkOrderID) AS r
ORDER BY w.WorkOrderID,
        w.OrderQty,
        r.ProductID;
GO

BEGIN TRANSACTION;
INSERT  INTO Production.WorkOrder
        (ProductID,
         OrderQty,
         ScrappedQty,
         StartDate,
         EndDate,
         DueDate,
         ScrapReasonID,
         ModifiedDate)
VALUES  (1,
         1,
         1,
         GETDATE(),
         GETDATE(),
         GETDATE(),
         1,
         GETDATE());

SELECT  w.WorkOrderID,
        w.OrderQty,
        r.ProductID,
        r.OperationSequence
FROM    Production.WorkOrder AS w
        CROSS APPLY dbo.fn_WorkOrderRouting(w.WorkOrderID) AS r
WHERE   w.WorkOrderID IN (SELECT    MAX(WorkOrderID)
                          FROM      Production.WorkOrder);

SELECT  w.WorkOrderID,
        w.OrderQty,
        r.ProductID,
        r.OperationSequence
FROM    Production.WorkOrder AS w
        OUTER APPLY dbo.fn_WorkOrderRouting(w.WorkOrderID) AS r
WHERE   w.WorkOrderID IN (SELECT    MAX(WorkOrderID)
                          FROM      Production.WorkOrder);

SELECT TOP (5)
        w.WorkOrderID,
        w.OrderQty,
        r.ProductID,
        r.OperationSequence
FROM    Production.WorkOrder w
        CROSS APPLY (SELECT WorkOrderID,
                            ProductID,
                            OperationSequence,
                            LocationID
                     FROM   Production.WorkOrderRouting
                     WHERE  WorkOrderID = w.WorkOrderId
                    ) AS r
ORDER BY w.WorkOrderID,
        w.OrderQty,
        r.ProductID;

ROLLBACK TRANSACTION;
GO

-- 6-9. Returning Random Rows from a Table
SELECT  FirstName,
        LastName
FROM    Person.Person 
TABLESAMPLE SYSTEM (2 PERCENT);
GO

-- 6-10. Converting Rows into Columns
SELECT  s.Name AS ShiftName,
        h.BusinessEntityID,
        d.Name AS DepartmentName
FROM    HumanResources.EmployeeDepartmentHistory h
        INNER JOIN HumanResources.Department d
            ON h.DepartmentID = d.DepartmentID
        INNER JOIN HumanResources.Shift s
            ON h.ShiftID = s.ShiftID
WHERE   EndDate IS NULL
        AND d.Name IN ('Production', 'Engineering', 'Marketing')
ORDER BY ShiftName;

SELECT  ShiftName,
        Production,
        Engineering,
        Marketing
FROM    (SELECT s.Name AS ShiftName,
                h.BusinessEntityID,
                d.Name AS DepartmentName
         FROM   HumanResources.EmployeeDepartmentHistory h
                INNER JOIN HumanResources.Department d
                    ON h.DepartmentID = d.DepartmentID
                INNER JOIN HumanResources.Shift s
                    ON h.ShiftID = s.ShiftID
         WHERE  EndDate IS NULL
                AND d.Name IN ('Production', 'Engineering', 'Marketing')
        ) AS a 
PIVOT
(
 COUNT(BusinessEntityID) 
 FOR DepartmentName IN ([Production], [Engineering], [Marketing]) 
)  AS b
ORDER BY ShiftName;


-- use SQL "Black Arts"
SELECT  s.Name AS ShiftName,
        SUM(CASE WHEN d.Name = 'Production' THEN 1 ELSE 0 END) AS Production,
        SUM(CASE WHEN d.Name = 'Engineering' THEN 1 ELSE 0 END) AS Engineering,
        SUM(CASE WHEN d.Name = 'Marketing' THEN 1 ELSE 0 END) AS Marketing
FROM    HumanResources.EmployeeDepartmentHistory h
        INNER JOIN HumanResources.Department d
            ON h.DepartmentID = d.DepartmentID
        INNER JOIN HumanResources.Shift s
            ON h.ShiftID = s.ShiftID
WHERE   h.EndDate IS NULL
        AND d.Name IN ('Production', 'Engineering', 'Marketing')
GROUP BY s.Name;

-- 6-11. Converting Columns into Rows
USE tempdb;
GO
IF OBJECT_ID('dbo.Contact','U') IS NOT NULL DROP TABLE dbo.Contact;
GO

CREATE TABLE dbo.Contact
       (
        EmployeeID INT NOT NULL,
        PhoneNumber1 BIGINT,
        PhoneNumber2 BIGINT,
        PhoneNumber3 BIGINT
       )
GO

INSERT  dbo.Contact
        (EmployeeID, PhoneNumber1, PhoneNumber2, PhoneNumber3)
VALUES  (1, 2718353881, 3385531980, 5324571342),
        (2, 6007163571, 6875099415, 7756620787),
        (3, 9439250939, NULL, NULL);

SELECT  EmployeeID,
        PhoneType,
        PhoneValue
FROM    dbo.Contact c 
UNPIVOT
( PhoneValue FOR PhoneType IN ([PhoneNumber1], [PhoneNumber2], [PhoneNumber3]) )  AS p;
GO

-- 6-12. Reusing Common Subqueries in a Query
WITH cte AS
(
SELECT SalesOrderID
FROM   Sales.SalesOrderDetail
WHERE  UnitPrice BETWEEN 1900 AND 2000
)
SELECT  s.PurchaseOrderNumber
FROM    Sales.SalesOrderHeader s
WHERE   EXISTS (SELECT SalesOrderID
                FROM cte
                WHERE SalesOrderID = s.SalesOrderID );

SET STATISTICS IO ON;
RAISERROR('CTE #1', 10, 1) WITH NOWAIT;
WITH VendorSearch(RowNumber, VendorName, AccountNumber) AS 
(
SELECT    ROW_NUMBER() OVER (ORDER BY Name) RowNum,
          Name,
          AccountNumber
FROM      Purchasing.Vendor
)
SELECT * 
FROM VendorSearch;

RAISERROR('CTE #2', 10, 1) WITH NOWAIT;
WITH VendorSearch(RowNumber, VendorName, AccountNumber) AS 
(
SELECT    ROW_NUMBER() OVER (ORDER BY Name) RowNum,
          Name,
          AccountNumber
FROM      Purchasing.Vendor
)
SELECT RowNumber,
       VendorName,
       AccountNumber
FROM   VendorSearch
WHERE  RowNumber BETWEEN 1 AND 5
UNION
SELECT RowNumber,
       VendorName,
       AccountNumber
FROM   VendorSearch
WHERE  RowNumber BETWEEN 100 AND 104;

SET STATISTICS IO OFF;
GO

-- 6-13. Querying Recursive Tables
USE tempdb;
GO
IF OBJECT_ID('dbo.Company', 'U') IS NOT NULL 
   DROP TABLE dbo.Company;
GO

CREATE TABLE dbo.Company
       (
        CompanyID INT NOT NULL
                      PRIMARY KEY,
        ParentCompanyID INT NULL,
        CompanyName VARCHAR(25) NOT NULL
       );

INSERT  dbo.Company
        (CompanyID, ParentCompanyID, CompanyName)
VALUES  (1, NULL, 'Mega-Corp'),
        (2, 1, 'Mediamus-Corp'),
        (3, 1, 'KindaBigus-Corp'),
        (4, 3, 'GettinSmaller-Corp'),
        (5, 4, 'Smallest-Corp'),
        (6, 5, 'Puny-Corp'),
        (7, 5, 'Small2-Corp');
GO

WITH  CompanyTree(ParentCompanyID, CompanyID, CompanyName, CompanyLevel) AS 
(
SELECT    ParentCompanyID,
          CompanyID,
          CompanyName,
          0 AS CompanyLevel
FROM      dbo.Company
WHERE     ParentCompanyID IS NULL
UNION ALL
SELECT    c.ParentCompanyID,
          c.CompanyID,
          c.CompanyName,
          p.CompanyLevel + 1
FROM      dbo.Company c
          INNER JOIN CompanyTree p
              ON c.ParentCompanyID = p.CompanyID
)
SELECT ParentCompanyID,
       CompanyID,
       CompanyName,
       CompanyLevel
FROM   CompanyTree;
GO

-- 6-14. Hard-Coding the Results from a Query
SELECT * 
FROM (VALUES ('George', 'Washington'),
             ('Thomas', 'Jefferson'),
             ('John', 'Adams'),
             ('James', 'Madison'),
             ('James', 'Monroe'),
             ('John Quincy', 'Adams'),
             ('Andrew', 'Jackson'),
             ('Martin', 'Van Buren'),
             ('William', 'Harrison'),
             ('John', 'Tyler')
      ) dtPresidents(FirstName, LastName);
GO
