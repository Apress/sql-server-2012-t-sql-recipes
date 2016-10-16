-- 8-1. Inserting a New Row
INSERT  INTO Production.Location
        (Name, CostRate, Availability)
VALUES  ('Wheel Storage', 11.25, 80.00) ;

SELECT  Name,
        CostRate,
        Availability
FROM    Production.Location
WHERE   Name = 'Wheel Storage' ;

-- 8-2. Specifying Default Values
INSERT  Production.Location
        (Name,
         CostRate,
         Availability,
         ModifiedDate)
VALUES  ('Wheel Storage 2',
         11.25,
         80.00,
         '4/1/2012') ;

INSERT  Production.Location
        (Name,
         CostRate,
         Availability,
         ModifiedDate)
VALUES  ('Wheel Storage 3',
         11.25,
         80.00,
         DEFAULT) ;

INSERT  INTO Person.Address
        (AddressLine1,
         AddressLine2,
         City,
         StateProvinceID,
         PostalCode)
VALUES  ('15 Wake Robin Rd',
         DEFAULT,
         'Sudbury',
         30,
         '01776') ;

-- 8-3. Overriding an IDENTITY Column

INSERT INTO HumanResources.Department (DepartmentID, Name, GroupName)
VALUES (17, 'Database Services', 'Information Technology')

SET IDENTITY_INSERT HumanResources.Department ON

INSERT HumanResources.Department (DepartmentID, Name, GroupName)
VALUES (17, 'Database Services', 'Information Technology')

SET IDENTITY_INSERT HumanResources.Department OFF

-- 8-4. Generating a Globally Unique Identifier (GUID)

INSERT  Purchasing.ShipMethod
        (Name,
         ShipBase,
         ShipRate,
         rowguid)
VALUES  ('MIDDLETON CARGO TS1',
         8.99,
         1.22,
         NEWID()) ;

SELECT  rowguid,
        Name
FROM    Purchasing.ShipMethod
WHERE   Name = 'MIDDLETON CARGO TS1'

-- 8-5. Inserting Results from a Query
CREATE TABLE [dbo].[Shift_Archive]
       (
        [ShiftID] [tinyint] NOT NULL,
        [Name] [dbo].[Name] NOT NULL,
        [StartTime] [datetime] NOT NULL,
        [EndTime] [datetime] NOT NULL,
        [ModifiedDate] [datetime] NOT NULL
                                  DEFAULT (GETDATE()),
        CONSTRAINT [PK_Shift_ShiftID] PRIMARY KEY CLUSTERED ([ShiftID] ASC)
       ) ;
GO

INSERT  INTO dbo.Shift_Archive
        (ShiftID,
         Name,
         StartTime,
         EndTime,
         ModifiedDate)
        SELECT  ShiftID,
                Name,
                StartTime,
                EndTime,
                ModifiedDate
        FROM    HumanResources.Shift
        ORDER BY ShiftID ;

SELECT  ShiftID,
        Name
FROM    Shift_Archive ;

-- 8-6. Inserting Results from a Stored Procedure
CREATE PROCEDURE dbo.usp_SEL_Production_TransactionHistory
       @ModifiedStartDT DATETIME,
       @ModifiedEndDT DATETIME
AS 
       SELECT   TransactionID,
                ProductID,
                ReferenceOrderID,
                ReferenceOrderLineID,
                TransactionDate,
                TransactionType,
                Quantity,
                ActualCost,
                ModifiedDate
       FROM     Production.TransactionHistory
       WHERE    ModifiedDate BETWEEN @ModifiedStartDT
                             AND     @ModifiedEndDT
                AND TransactionID NOT IN (
                SELECT  TransactionID
                FROM    Production.TransactionHistoryArchive) ;
GO


EXEC dbo.usp_SEL_Production_TransactionHistory '2007-09-01', '2007-09-02'

INSERT  Production.TransactionHistoryArchive
        (TransactionID,
         ProductID,
         ReferenceOrderID,
         ReferenceOrderLineID,
         TransactionDate,
         TransactionType,
         Quantity,
         ActualCost,
         ModifiedDate)
        EXEC dbo.usp_SEL_Production_TransactionHistory '2007-09-01',
            '2007-09-02' ;

-- 8-7. Inserting Multiple Rows at Once
CREATE TABLE HumanResources.Degree
       (
        DegreeID INT NOT NULL
                     IDENTITY(1, 1)
                     PRIMARY KEY,
        DegreeName VARCHAR(30) NOT NULL,
        DegreeCode VARCHAR(5) NOT NULL,
        ModifiedDate DATETIME NOT NULL
       ) ;
GO

INSERT  INTO HumanResources.Degree
        (DegreeName, DegreeCode, ModifiedDate)
VALUES  ('Bachelor of Arts', 'B.A.', GETDATE()),
     ('Bachelor of Science', 'B.S.', GETDATE()),
     ('Master of Arts', 'M.A.', GETDATE()),
     ('Master of Science', 'M.S.', GETDATE()),
     ('Associate" s Degree', 'A.A.', GETDATE()) ;
GO

-- 8-8. Inserting Rows and Returning the Inserted Rows
INSERT  Purchasing.ShipMethod
        (Name, ShipBase, ShipRate)
OUTPUT  INSERTED.ShipMethodID, INSERTED.Name
VALUES  ('MIDDLETON CARGO TS11', 10, 10),
        ('MIDDLETON CARGO TS12', 10, 10),
        ('MIDDLETON CARGO TS13', 10, 10) ;

-- 8-9. Updating a Single Row or Set of Rows
UPDATE <table_or_view_name>
SET    column_name = {expression | DEFAULT | NULL} [ ,...n ]
WHERE  <search_condition>

SELECT  DiscountPct
FROM    Sales.SpecialOffer
WHERE   SpecialOfferID = 10 ;

UPDATE  Sales.SpecialOffer
SET     DiscountPct = 0.15
WHERE   SpecialOfferID = 10 ;

SELECT  DiscountPct
FROM    Sales.SpecialOffer
WHERE   SpecialOfferID = 10 ;

-- 8-10. Updating with a Second Table as the Data Source 
UPDATE  Sales.ShoppingCartItem
SET     Quantity = 2,
        ModifiedDate = GETDATE()
FROM    Sales.ShoppingCartItem c
        INNER JOIN Production.Product p
            ON c.ProductID = p.ProductID
WHERE   p.Name = 'Full-Finger Gloves, M '
        AND c.Quantity > 2 ;

-- 8-11. Updating Data and Returning the Affected Rows
UPDATE  Sales.SpecialOffer
SET     DiscountPct *= 1.05
OUTPUT  inserted.SpecialOfferID,
        deleted.DiscountPct AS old_DiscountPct,
        inserted.DiscountPct AS new_DiscountPct
WHERE   Category = 'Customer' ;

-- 8-12. Updating Large-Value Columns
CREATE TABLE dbo.RecipeChapter
       (
        ChapterID INT NOT NULL,
        Chapter VARCHAR(MAX) NOT NULL
       ) ;
GO

INSERT  INTO dbo.RecipeChapter
        (ChapterID,
         Chapter)
VALUES  (1,
         'At the beginning of each chapter you will notice
that basic concepts are covered first.') ;

UPDATE  RecipeChapter
SET     Chapter.WRITE(' In addition to the basics, this chapter will also provide
recipes that can be used in your day to day development and administration.',
                      NULL, NULL)
WHERE   ChapterID = 1 ;

UPDATE  RecipeChapter
SET     Chapter.WRITE('daily', CHARINDEX('day to day', Chapter) - 1,
                      LEN('day to day'))
WHERE   ChapterID = 1 ;

SELECT  Chapter
FROM    RecipeChapter
WHERE   ChapterID = 1

-- 8-13. Deleting Rows
SELECT *
INTO   Production.Example_ProductProductPhoto
FROM   Production.ProductProductPhoto ;

DELETE Production.Example_ProductProductPhoto ;

-- Repopulate the Example_ProductProductPhoto table
INSERT  Production.Example_ProductProductPhoto
        SELECT  *
        FROM    Production.ProductProductPhoto ;

DELETE  Production.Example_ProductProductPhoto
WHERE   ProductID NOT IN (SELECT    ProductID
                          FROM      Production.Product) ;

DELETE  
FROM    ppp
FROM    Production.Example_ProductProductPhoto ppp
        LEFT OUTER JOIN Production.Product p
            ON ppp.ProductID = p.ProductID
WHERE   p.ProductID IS NULL ;

-- 8-14. Deleting Rows and Returning the Deleted Rows
SELECT *
INTO   HumanResources.Example_JobCandidate 
FROM   HumanResources.JobCandidate ;

DELETE 
FROM   HumanResources.Example_JobCandidate 
OUTPUT deleted.JobCandidateID
WHERE  JobCandidateID < 5 ;

-- 8-15. Deleting All Rows Quickly (Truncating)

SELECT *
INTO   Production.Example_TransactionHistory
FROM   Production.TransactionHistory ;

TRUNCATE TABLE Production.Example_TransactionHistory ;
SELECT COUNT(*)
FROM   Production.Example_TransactionHistory ;

-- 8-16. Merging Data (Inserting, Updating, or Deleting Values)
CREATE TABLE Sales.LastCustomerOrder
       (
        CustomerID INT,
        SalesorderID INT,
        CONSTRAINT pk_LastCustomerOrder PRIMARY KEY CLUSTERED (CustomerId)
       ) ;

DECLARE @CustomerID INT = 100,
        @SalesOrderID INT = 101 ;

MERGE INTO Sales.LastCustomerOrder AS tgt
    USING 
        (SELECT @CustomerID AS CustomerID,
                @SalesOrderID AS SalesOrderID
        ) AS src
    ON tgt.CustomerID = src.CustomerID
    WHEN MATCHED 
        THEN UPDATE
          SET       SalesOrderID = src.SalesOrderID
    WHEN NOT MATCHED 
        THEN INSERT (
                     CustomerID,
                     SalesOrderID
                    )
          VALUES    (src.CustomerID,
                     src.SalesOrderID) ;

SELECT  *
FROM    Sales.LastCustomerOrder ;

SELECT  *
FROM    Sales.LastCustomerOrder ;


CREATE TABLE Sales.LargestCustomerOrder
       (
        CustomerID INT,
        SalesorderID INT,
		TotalDue MONEY, 
        CONSTRAINT pk_LargestCustomerOrder PRIMARY KEY CLUSTERED (CustomerId)
       ) ;

DECLARE @CustomerID INT = 100,
        @SalesOrderID INT = 101 ,
        @TotalDue MONEY = 1000.00

MERGE INTO Sales.LargestCustomerOrder AS tgt
    USING 
        (SELECT @CustomerID AS CustomerID,
                @SalesOrderID AS SalesOrderID,
                @TotalDue AS TotalDue
        ) AS src
    ON tgt.CustomerID = src.CustomerID
    WHEN MATCHED AND tgt.TotalDue < src.TotalDue 
        THEN UPDATE
          SET       SalesOrderID = src.SalesOrderID
		  , TotalDue = src.TotalDue
    WHEN NOT MATCHED 
        THEN INSERT (
                     CustomerID,
                     SalesOrderID,
                     TotalDue
                    )
          VALUES    (src.CustomerID,
                     src.SalesOrderID,
                     src.TotalDue) ;

SELECT  *
FROM    Sales.LargestCustomerOrder ;

SELECT  *
FROM    Sales.LargestCustomerOrder ;




