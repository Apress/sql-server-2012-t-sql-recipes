-- 14-1. Creating a View
IF OBJECT_ID('dbo.v_Product_TransactionHistory','V') IS NOT NULL
   DROP VIEW dbo.v_Product_TransactionHistory;
GO
CREATE VIEW dbo.v_Product_TransactionHistory
AS
SELECT  p.Name AS ProductName,
        p.ProductNumber,
        pc.Name AS ProductCategory,
        ps.Name AS ProductSubCategory,
        pm.Name AS ProductModel,
        th.TransactionID,
        th.ReferenceOrderID,
        th.ReferenceOrderLineID,
        th.TransactionDate,
        th.TransactionType,
        th.Quantity,
        th.ActualCost,
        th.Quantity * th.ActualCost AS ExtendedPrice
 FROM    Production.TransactionHistory th
        INNER JOIN Production.Product p
            ON th.ProductID = p.ProductID
        INNER JOIN Production.ProductModel pm
            ON pm.ProductModelID = p.ProductModelID
        INNER JOIN Production.ProductSubcategory ps
            ON ps.ProductSubcategoryID = p.ProductSubcategoryID
        INNER JOIN Production.ProductCategory pc
            ON pc.ProductCategoryID = ps.ProductCategoryID
WHERE   pc.Name = 'Bikes';
GO
SELECT  ProductName,
        ProductNumber,
        ReferenceOrderID,
        ActualCost
FROM    dbo.v_Product_TransactionHistory
ORDER BY ProductName;


-- 14-2. Querying a View’s Definition
SELECT  definition
FROM    sys.sql_modules AS sm
WHERE   object_id = OBJECT_ID('dbo.v_Product_TransactionHistory');

SELECT  OBJECT_DEFINITION(OBJECT_ID('dbo.v_Product_TransactionHistory'));


-- 14-3. Obtaining a List of All Views in a Database
SELECT  OBJECT_SCHEMA_NAME(v.object_id) AS SchemaName,
        v.name
FROM    sys.views AS v ;

SELECT  OBJECT_SCHEMA_NAME(o.object_id) AS SchemaName,
        o.name
FROM    sys.objects AS o
WHERE   type = 'V' ;

-- 14-4. Obtaining a List of All Columns in a View
SELECT  name,
        column_id
FROM    sys.columns
WHERE   object_id = OBJECT_ID('dbo.v_Product_TransactionHistory');


-- 14-5. Refreshing the Definition of a View
EXECUTE dbo.sp_refreshview N'dbo.v_Product_TransactionHistory';
EXECUTE sys.sp_refreshsqlmodule @name = N'dbo.v_Product_TransactionHistory';


-- 14-6. Modifying a View
ALTER VIEW dbo.v_Product_TransactionHistory
AS
SELECT  p.Name AS ProductName,
        p.ProductNumber,
        pc.Name AS ProductCategory,
        ps.Name AS ProductSubCategory,
        pm.Name AS ProductModel,
        th.TransactionID,
        th.ReferenceOrderID,
        th.ReferenceOrderLineID,
        th.TransactionDate,
        th.TransactionType,
        th.Quantity,
        th.ActualCost,
        th.Quantity * th.ActualCost AS ExtendedPrice
FROM    Production.TransactionHistory th
        INNER JOIN Production.Product p
            ON th.ProductID = p.ProductID
        INNER JOIN Production.ProductModel pm
            ON pm.ProductModelID = p.ProductModelID
        INNER JOIN Production.ProductSubcategory ps
            ON ps.ProductSubcategoryID = p.ProductSubcategoryID
        INNER JOIN Production.ProductCategory pc
            ON pc.ProductCategoryID = ps.ProductCategoryID
WHERE   pc.Name IN ('Bikes', 'Bicycles');
GO


-- 14-7. Modifying Data Through a View
SELECT  ProductName,
        ProductNumber,
        ReferenceOrderID,
        ActualCost
FROM    dbo.v_Product_TransactionHistory
ORDER BY ProductName;
BEGIN TRANSACTION;
SELECT  ProductName,
        ProductNumber,
        ReferenceOrderID,
        Quantity,
        ActualCost,
        ExtendedPrice
FROM    dbo.v_Product_TransactionHistory
WHERE   ReferenceOrderID = 53463
ORDER BY ProductName;

UPDATE  dbo.v_Product_TransactionHistory
SET     Quantity = 3
WHERE   ReferenceOrderID = 53463;

SELECT  ProductName,
        ProductNumber,
        ReferenceOrderID,
        Quantity,
        ActualCost,
        ExtendedPrice
FROM    dbo.v_Product_TransactionHistory
WHERE   ReferenceOrderID = 53463
ORDER BY ProductName;

ROLLBACK TRANSACTION;


-- 14-8. Encrypting a View
IF OBJECT_ID('dbo.v_Product_TopTenListPrice','V') IS NOT NULL
   DROP VIEW dbo.v_Product_TopTenListPrice;
GO

CREATE VIEW dbo.v_Product_TopTenListPrice
WITH ENCRYPTION
AS
SELECT TOP 10
        p.Name,
        p.ProductNumber,
        p.ListPrice
FROM    Production.Product p
ORDER BY p.ListPrice DESC;
GO

SELECT  definition
FROM    sys.sql_modules AS sm
WHERE   object_id = OBJECT_ID('dbo.v_Product_TopTenListPrice');

SELECT  OBJECT_DEFINITION(OBJECT_ID('dbo.v_Product_TopTenListPrice')) AS definition;


-- 14-9. Indexing a View
SET STATISTICS IO OFF;
GO
IF OBJECT_ID('dbo.v_Product_Sales_By_LineTotal','V') IS NOT NULL 
   DROP VIEW dbo.v_Product_Sales_By_LineTotal;
GO

CREATE VIEW dbo.v_Product_Sales_By_LineTotal
WITH SCHEMABINDING
AS
SELECT  p.ProductID,
        p.Name AS ProductName,
        SUM(LineTotal) AS LineTotalByProduct,
        COUNT_BIG(*) AS LineItems
FROM    Sales.SalesOrderDetail s
        INNER JOIN Production.Product p
            ON s.ProductID = p.ProductID
GROUP BY p.ProductID,
        p.Name;
GO

SET STATISTICS IO ON;
GO

SELECT TOP 5
        ProductName,
        LineTotalByProduct
FROM    dbo.v_Product_Sales_By_LineTotal
ORDER BY LineTotalByProduct DESC ;
GO

SET STATISTICS IO OFF;
GO

CREATE UNIQUE CLUSTERED INDEX UCI_v_Product_Sales_By_LineTotal
ON dbo.v_Product_Sales_By_LineTotal (ProductID);
GO

CREATE NONCLUSTERED INDEX NI_v_Product_Sales_By_LineTotal
ON dbo.v_Product_Sales_By_LineTotal (ProductName); 
GO

SET STATISTICS IO ON;
GO

SELECT TOP 5
        ProductName,
        LineTotalByProduct
FROM    dbo.v_Product_Sales_By_LineTotal
ORDER BY LineTotalByProduct DESC ;
GO


-- 14-10. Creating a Partitioned View
USE master;
GO

IF DB_ID('TSQLRecipe_A') IS NOT NULL 
   DROP DATABASE TSQLRecipe_A;
GO

IF DB_ID('TSQLRecipe_A') IS NULL 
   CREATE DATABASE TSQLRecipe_A;
GO
USE TSQLRecipe_A;
GO
CREATE TABLE dbo.WebHits_201201
       (
        HitDt DATETIME
            NOT NULL
            CONSTRAINT PK__WebHits_201201 PRIMARY KEY
            CONSTRAINT CK__WebHits_201201__HitDt
            CHECK (HitDt >= '2012-01-01'
                   AND HitDt < '2012-02-01'),
        WebSite VARCHAR(20) NOT NULL
       );
GO
CREATE TABLE dbo.WebHits_201202
       (
        HitDt DATETIME
            NOT NULL
            CONSTRAINT PK__WebHits_201202 PRIMARY KEY
            CONSTRAINT CK__WebHits_201202__HitDt
            CHECK (HitDt >= '2012-02-01'
                   AND HitDt < '2012-03-01'),
        WebSite VARCHAR(20) NOT NULL
       );
GO
CREATE TABLE dbo.WebHits_201203
       (
        HitDt DATETIME
            NOT NULL
            CONSTRAINT PK__WebHits_201203 PRIMARY KEY
            CONSTRAINT CK__WebHits_201203__HitDt
            CHECK (HitDt >= '2012-03-01'
                   AND HitDt < '2012-04-01'),
        WebSite VARCHAR(20) NOT NULL
       );
GO

CREATE VIEW dbo.WebHits
AS
SELECT  HitDt,
        WebSite
FROM    dbo.WebHits_201201
UNION ALL
SELECT  HitDt,
        WebSite
FROM    dbo.WebHits_201202
UNION ALL
SELECT  HitDt,
        WebSite
FROM    dbo.WebHits_201203;
GO

RAISERROR ('Insert #1 dbo.WebHits;', 10, 1) WITH NOWAIT;
SET STATISTICS IO ON;
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-01-15T13:22:18.456',
         'MegaCorp');
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-02-15T13:22:18.456',
         'MegaCorp');
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-03-15T13:22:18.456',
         'MegaCorp');
GO

RAISERROR ('DELETE FROM dbo.WebHits;', 10, 1) WITH NOWAIT;
DELETE FROM dbo.WebHits;
GO

RAISERROR ('Insert #2 dbo.WebHits;', 10, 1) WITH NOWAIT;
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-01-15T13:22:18.456',
         'MegaCorp');
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-02-15T13:22:18.456',
         'MegaCorp');
INSERT  INTO dbo.WebHits
        (HitDt,
         WebSite)
VALUES  ('2012-03-15T13:22:18.456',
         'MegaCorp');
GO

SELECT  *
FROM    dbo.WebHits_201201;

SELECT  *
FROM    dbo.WebHits_201202;

SELECT  *
FROM    dbo.WebHits_201203;

SET STATISTICS IO ON;
GO
SELECT  *
FROM    dbo.WebHits
WHERE   HitDt >= '2012-02-01'
        AND HitDt < '2012-03-01';
