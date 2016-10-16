USE AdventureWorks2012
GO

-- 7-1. Computing an Average
SELECT  ProductID,
        AVG(Rating) AS AvgRating
FROM    Production.ProductReview
GROUP BY ProductID;
GO

SELECT  StudentId,
        AVG(Grade) AS AvgGrade,
        AVG(DISTINCT Grade) AS AvgDistinctGrade
FROM    (VALUES (1, 100),
                (1, 100),
                (1, 100),
                (1, 99),
                (1, 99),
                (1, 98),
                (1, 98),
                (1, 95),
                (1, 95),
                (1, 95)
        ) dt (StudentId, Grade)
GROUP BY StudentID;
GO

-- 7-2. Counting the Rows in a Group
SELECT  TOP (5)
        Shelf,
        COUNT(ProductID) AS ProductCount,
        COUNT_BIG(ProductID) AS ProductCountBig
FROM    Production.ProductInventory
GROUP BY Shelf
ORDER BY Shelf;
GO

-- 7-3. Summing the Values in a Group
SELECT  TOP (5)
        AccountNumber,
        SUM(TotalDue) AS TotalDueByAccountNumber
FROM    Sales.SalesOrderHeader
GROUP BY AccountNumber
ORDER BY AccountNumber;
GO

-- 7-4. Finding the High and Low Values in a Group
SELECT  MIN(Rating) MinRating,
        MAX(Rating) MaxRating
FROM    Production.ProductReview;
GO

-- 7-5. Detecting Changes in a Table
SELECT  StudentId,
        CHECKSUM_AGG(Grade) AS GradeChecksumAgg
FROM    (VALUES (1, 100),
                (1, 100),
                (1, 100),
                (1, 99),
                (1, 99),
                (1, 98),
                (1, 98),
                (1, 95),
                (1, 95),
                (1, 95)
        ) dt (StudentId, Grade)
GROUP BY StudentID;
GO

SELECT  StudentId,
        CHECKSUM_AGG(Grade) AS GradeChecksumAgg
FROM    (VALUES (1, 100),
                (1, 100),
                (1, 100),
                (1, 99),
                (1, 99),
                (1, 98),
                (1, 98),
                (1, 95),
                (1, 95),
                (1, 90)
        ) dt (StudentId, Grade)
GROUP BY StudentID;

GO

-- 7-6. Finding the Statistical Variance in the Values of a Column
SELECT  VAR(TaxAmt)  AS Variance_Sample,
        VARP(TaxAmt) AS Variance_EntirePopulation
FROM    Sales.SalesOrderHeader;
GO

-- 7-7. Finding the Standard Deviation in the Values of a Column
SELECT  STDEV(UnitPrice)  AS StandDevUnitPrice,
        STDEVP(UnitPrice) AS StandDevPopUnitPrice
FROM    Sales.SalesOrderDetail;

-- Windowed Aggregate Functions
IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL 
   DROP TABLE #Transactions;
CREATE TABLE #Transactions
       (
        AccountId INTEGER,
        TranDate DATE,
        TranAmt NUMERIC(8, 2)
       );
INSERT  INTO #Transactions
SELECT  *
FROM    ( VALUES ( 1, '2011-01-01', 500), 
                 ( 1, '2011-01-15', 50),
                 ( 1, '2011-01-22', 250), 
                 ( 1, '2011-01-24', 75),
                 ( 1, '2011-01-26', 125), 
                 ( 1, '2011-01-28', 175),
                 ( 2, '2011-01-01', 500), 
                 ( 2, '2011-01-15', 50),
                 ( 2, '2011-01-22', 25), 
                 ( 2, '2011-01-23', 125),
                 ( 2, '2011-01-26', 200), 
                 ( 2, '2011-01-29', 250),
                 ( 3, '2011-01-01', 500), 
                 ( 3, '2011-01-15', 50 ),
                 ( 3, '2011-01-22', 5000), 
                 ( 3, '2011-01-25', 550),
                 ( 3, '2011-01-27', 95 ), 
                 ( 3, '2011-01-30', 2500) 
        ) dt (AccountId, TranDate, TranAmt);

-- 7-8. Calculating Totals Based Upon the Prior Row
SELECT  AccountId,
        TranDate,
        TranAmt,
       -- running total of all transactions
        RunTotalAmt = SUM(TranAmt) OVER (PARTITION BY AccountId ORDER BY TranDate)
FROM    #Transactions AS t
ORDER BY AccountId,
        TranDate;
GO

SELECT  AccountId,
        TranDate,
        TranAmt,
       -- running average of all transactions
        RunAvg = AVG(TranAmt) 
                 OVER (PARTITION BY AccountId 
                           ORDER BY TranDate),
       -- running total # of transactions
        RunTranQty = COUNT(*) 
                     OVER (PARTITION BY AccountId 
                               ORDER BY TranDate),
       -- smallest of the transactions so far
        RunSmallAmt = MIN(TranAmt) 
                      OVER (PARTITION BY AccountId 
                                ORDER BY TranDate),
       -- largest of the transactions so far
        RunLargeAmt = MAX(TranAmt) 
                      OVER (PARTITION BY AccountId 
                                ORDER BY TranDate),
       -- running total of all transactions
        RunTotalAmt = SUM(TranAmt) 
                      OVER (PARTITION BY AccountId 
                                ORDER BY TranDate)
FROM    #Transactions AS t
ORDER BY AccountId,
        TranDate;
GO

-- 7-9. Calculating Totals Based Upon a Subset of Rows
SELECT AccountId ,
       TranDate ,
       TranAmt,
       -- average of the current and previous 2 transactions
       SlideAvg      = AVG(TranAmt) 
                       OVER (PARTITION BY AccountId
                                 ORDER BY TranDate
                                  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
       -- total # of the current and previous 2 transactions
       SlideQty  = COUNT(*)     
                    OVER (PARTITION BY AccountId 
                              ORDER BY TranDate
                               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
       -- smallest of the current and previous 2 transactions
       SlideMin = MIN(TranAmt) 
                  OVER (PARTITION BY AccountId 
                            ORDER BY TranDate
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
       -- largest of the current and previous 2 transactions
       SlideMax = MAX(TranAmt) 
                  OVER (PARTITION BY AccountId 
                            ORDER BY TranDate
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
       -- total of the current and previous 2 transactions
       SlideTotal = SUM(TranAmt) 
                    OVER (PARTITION BY AccountId 
                              ORDER BY TranDate
                               ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
FROM    #Transactions AS t
ORDER BY AccountId,
        TranDate;
GO

-- 7-10. Using a Logical Window
DECLARE @Test TABLE
        (
         RowID INT IDENTITY,
         FName VARCHAR(20),
         Salary SMALLINT
        );

INSERT INTO @Test (FName, Salary)
VALUES ('George',       800),
       ('Sam',          950),
       ('Diane',       1100),
       ('Nicholas',    1250),
       ('Samuel',      1250),
       ('Patricia',    1300),
       ('Brian',       1500),
       ('Thomas',      1600),
       ('Fran',        2450),
       ('Debbie',      2850),
       ('Mark',        2975),
       ('James',       3000),
       ('Cynthia',     3000),
       ('Christopher', 5000);

SELECT RowID,
       FName,
       Salary,
       SumByRows  = SUM(Salary) 
                    OVER (ORDER BY Salary 
                           ROWS UNBOUNDED PRECEDING),
       SumByRange = SUM(Salary) 
                    OVER (ORDER BY Salary 
                          RANGE UNBOUNDED PRECEDING)
FROM   @Test
ORDER BY RowID;
GO

-- 7-11. Generating an Incrementing Row Number
SELECT TOP 10
        AccountNumber,
        OrderDate,
        TotalDue,
        ROW_NUMBER() OVER (PARTITION BY AccountNumber ORDER BY OrderDate) AS RN
FROM    Sales.SalesOrderHeader
ORDER BY AccountNumber;

SELECT  ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RN
FROM    sys.all_columns;

;
WITH
TENS      (N) AS (SELECT 0 UNION ALL SELECT 0 UNION ALL SELECT 0 UNION ALL 
                  SELECT 0 UNION ALL SELECT 0 UNION ALL SELECT 0 UNION ALL 
                  SELECT 0 UNION ALL SELECT 0 UNION ALL SELECT 0 UNION ALL SELECT 0),
THOUSANDS (N) AS (SELECT 1 FROM TENS t1 CROSS JOIN TENS t2 CROSS JOIN TENS t3),
MILLIONS  (N) AS (SELECT 1 FROM THOUSANDS t1 CROSS JOIN THOUSANDS t2),
TALLY     (N) AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 0)) FROM MILLIONS)
SELECT N
FROM   TALLY;
GO

-- 7-12. Returning Rows by Rank
SELECT  BusinessEntityID,
        QuotaDate,
        SalesQuota,
        RANK() OVER (ORDER BY SalesQuota DESC) AS RANK
FROM    Sales.SalesPersonQuotaHistory
WHERE   SalesQuota BETWEEN 266000.00 AND 319000.00;
GO

-- 7-13. Returning Rows by Rank Without Gaps
SELECT  BusinessEntityID,
        QuotaDate,
        SalesQuota,
        DENSE_RANK() OVER (ORDER BY SalesQuota DESC) AS DENSERANK
FROM    Sales.SalesPersonQuotaHistory
WHERE   SalesQuota BETWEEN 266000.00 AND 319000.00;
GO

-- 7-14. Sorting Rows into Buckets
SELECT  BusinessEntityID,
        QuotaDate,
        SalesQuota,
        NTILE(4) OVER (ORDER BY SalesQuota DESC) AS [NTILE]
FROM    Sales.SalesPersonQuotaHistory
WHERE   SalesQuota BETWEEN 266000.00 AND 319000.00;
GO

-- 7-15. Grouping Logically Consecutive Rows Together
DECLARE @RFID_Location TABLE (
    TagId INTEGER,
    Location VARCHAR(25),
    SensorDate DATETIME);
INSERT INTO @RFID_Location
        (TagId, Location, SensorDate)
VALUES  (1, 'Room1', '2012-01-10T08:00:01'),
        (1, 'Room1', '2012-01-10T08:18:32'),
        (1, 'Room2', '2012-01-10T08:25:42'),
        (1, 'Room3', '2012-01-10T09:52:48'),
        (1, 'Room2', '2012-01-10T10:05:22'),
        (1, 'Room3', '2012-01-10T11:22:15'),
        (1, 'Room4', '2012-01-10T14:18:58'),
        (2, 'Room1', '2012-01-10T08:32:18'),
        (2, 'Room1', '2012-01-10T08:51:53'),
        (2, 'Room2', '2012-01-10T09:22:09'),
        (2, 'Room1', '2012-01-10T09:42:17'),
        (2, 'Room1', '2012-01-10T09:59:16'),
        (2, 'Room2', '2012-01-10T10:35:18'),
        (2, 'Room3', '2012-01-10T11:18:42'),
        (2, 'Room4', '2012-01-10T15:22:18');

WITH cte AS
(
SELECT TagId, Location, SensorDate,
       ROW_NUMBER() 
       OVER (PARTITION BY TagId 
                 ORDER BY SensorDate) - 
       ROW_NUMBER()
       OVER (PARTITION BY TagId, Location
                 ORDER BY SensorDate) AS Grp
FROM   @RFID_Location
)
SELECT TagId, Location, SensorDate, Grp,
       DENSE_RANK()
       OVER (PARTITION BY TagId, Location
                 ORDER BY Grp) AS TripNbr
FROM   cte
ORDER BY TagId, SensorDate;

WITH cte AS
(
SELECT TagId, Location, SensorDate,
       ROW_NUMBER() 
       OVER (PARTITION BY TagId 
                 ORDER BY SensorDate) AS RN1,
       ROW_NUMBER()
       OVER (PARTITION BY TagId, Location
                 ORDER BY SensorDate) AS RN2
FROM   @RFID_Location
)
SELECT TagId, Location, SensorDate, 
       RN1, RN2, RN1-RN2 AS Grp
FROM   cte
ORDER BY TagId, SensorDate;

WITH cte AS
(
SELECT TagId, Location, SensorDate,
       ROW_NUMBER() 
       OVER (PARTITION BY TagId 
                 ORDER BY SensorDate) - 
       ROW_NUMBER()
       OVER (PARTITION BY TagId, Location
                 ORDER BY SensorDate) AS Grp
FROM   @RFID_Location
)
SELECT TagId, Location, SensorDate, Grp,
       DENSE_RANK()
       OVER (PARTITION BY TagId, Location
                 ORDER BY Grp) AS TripNbr,
       RANK()
       OVER (PARTITION BY TagId, Location
                 ORDER BY Grp) AS TripNbrRank
FROM   cte
ORDER BY TagId, SensorDate;
GO

-- 7-16. Accessing Values from Other Rows
WITH cte AS
(
SELECT  DATEPART(QUARTER, OrderDate) AS Qtr,
        DATEPART(YEAR, OrderDate) AS Yr,
        TotalDue
FROM    Sales.SalesOrderHeader
), cteAgg AS
(
SELECT  Yr,
        Qtr,
        SUM(TotalDue) AS TotalDue
FROM    cte
GROUP BY Yr, Qtr
)
SELECT  Yr,
        Qtr,
        TotalDue,
        TotalDue - LAG(TotalDue, 1, NULL) 
                   OVER (ORDER BY Yr, Qtr) AS DeltaPriorQtr,
        TotalDue - LAG(TotalDue, 4, NULL) 
                   OVER (ORDER BY Yr, Qtr) AS DeltaPriorYrQtr
FROM    cteAgg
ORDER BY Yr, Qtr;

-- determine the gaps in a column
DECLARE @Gaps TABLE (col1 int PRIMARY KEY CLUSTERED);
 
INSERT INTO @Gaps (col1)
VALUES (1), (2), (3),
       (50), (51), (52), (53), (54), (55),
       (100), (101), (102),
       (500),
       (950), (951), (952),
       (954);

-- Compare the value of the current row to the next row. 
-- If > 1, then there is a gap.
WITH cte AS
(
SELECT  col1 AS CurrentRow,
        LEAD(col1, 1, NULL)
        OVER (ORDER BY col1) AS NextRow
FROM    @Gaps
)
SELECT  cte.CurrentRow + 1 AS [Start of Gap],
        cte.NextRow - 1 AS [End of Gap]
FROM    cte
WHERE   cte.NextRow - cte.CurrentRow > 1;
GO

-- 7-17. Accessing the First or Last Value from a Partition
USE AdventureWorks2012;
GO
/*
In this database, there is a Sales.SalesOrderHeader table, 
which has information about each order. This information 
includes CustomerID, OrderDate, and TotalDue columns.

Let’s run a query that shows, for each CustomerID, the 
OrderDate for when they placed their least and most 
expensive orders.
*/

SELECT DISTINCT TOP (5)
       CustomerID,
       FIRST_VALUE(OrderDate)
       OVER (PARTITION BY CustomerID
                 ORDER BY TotalDue
                  ROWS BETWEEN UNBOUNDED PRECEDING
                           AND UNBOUNDED FOLLOWING) AS OrderDateLow,
       LAST_VALUE(OrderDate)
       OVER (PARTITION BY CustomerID
                 ORDER BY TotalDue
                  ROWS BETWEEN UNBOUNDED PRECEDING
                           AND UNBOUNDED FOLLOWING) AS OrderDateHigh
FROM    Sales.SalesOrderHeader
ORDER BY CustomerID;USE AdventureWorks2012;
GO

-- 7-18. Calculating the Relative Position or Rank of a Value in a Set of Values
SELECT CustomerID,
       CUME_DIST()
       OVER (PARTITION BY CustomerID
                 ORDER BY TotalDue) AS CumeDistOrderTotalDue,
       PERCENT_RANK()
       OVER (PARTITION BY CustomerID
                 ORDER BY TotalDue) AS PercentRankOrderTotalDue
FROM    Sales.SalesOrderHeader
ORDER BY CustomerID;
GO

-- 7-19. Calculating Continuous or Discrete Percentiles
DECLARE @Employees TABLE
        (
         EmplId INT PRIMARY KEY CLUSTERED,
         DeptId INT,
         Salary NUMERIC(8, 2)
        );
 
INSERT INTO @Employees
VALUES (1, 1, 10000),
       (2, 1, 11000),
       (3, 1, 12000),
       (4, 2, 25000),
       (5, 2, 35000),
       (6, 2, 75000),
       (7, 2, 100000);
 
SELECT  EmplId,
        DeptId,
        Salary,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP (ORDER BY Salary ASC)
            OVER (PARTITION BY DeptId) AS MedianCont,
        PERCENTILE_DISC(0.5)
            WITHIN GROUP (ORDER BY Salary ASC)
            OVER (PARTITION BY DeptId) AS MedianDisc,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP (ORDER BY Salary ASC)
            OVER (PARTITION BY DeptId) AS Percent75Cont,
        PERCENTILE_DISC(0.75)
            WITHIN GROUP (ORDER BY Salary ASC)
            OVER (PARTITION BY DeptId) AS Percent75Disc,
        CUME_DIST()
            OVER (PARTITION BY DeptId
                      ORDER BY Salary) AS CumeDist
FROM   @Employees
ORDER BY DeptId, EmplId;
GO

-- 7-20. Assigning Sequences in a Specified Order
USE tempdb;
GO
IF EXISTS (SELECT 1
           FROM sys.sequences AS seq
                JOIN sys.schemas AS sch
                  ON seq.schema_id = sch.schema_id
           WHERE sch.name = 'dbo'
           AND   seq.name = 'CH7Sequence')
   DROP SEQUENCE dbo.CH7Sequence;

CREATE SEQUENCE dbo.CH7Sequence AS INTEGER START WITH 1;

DECLARE @ClassRank TABLE
        (
         StudentID TINYINT,
         Grade TINYINT,
         SeqNbr INTEGER
        );
INSERT INTO @ClassRank (StudentId, Grade, SeqNbr)
SELECT StudentId, 
       Grade, 
       NEXT VALUE FOR dbo.CH7Sequence OVER (ORDER BY Grade ASC)
FROM   (VALUES (1, 100),
               (2, 95),
               (3, 85),
               (4, 100),
               (5, 99),
               (6, 98),
               (7, 95),
               (8, 90),
               (9, 89),
               (10, 89),
               (11, 85),
               (12, 82)) dt(StudentId, Grade);

SELECT * 
FROM   @ClassRank;
