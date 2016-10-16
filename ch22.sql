22-1. Forcincg a Join's Execution Approach

SELECT  p.Name,
        r.ReviewerName,
        r.Rating
FROM    Production.Product p
        INNER JOIN Production.ProductReview r
            ON r.ProductID = p.ProductID;

SELECT  p.Name,
        r.ReviewerName,
        r.Rating
FROM    Production.Product p
        INNER HASH JOIN Production.ProductReview r
            ON r.ProductID = p.ProductID;


22-2. Forcing a Statement Recompile

DECLARE @CarrierTrackingNumber nvarchar(25) = '5CE9-4D75-8F';

SELECT  SalesOrderID,
        ProductID,
        UnitPrice,
        OrderQty
FROM    Sales.SalesOrderDetail
WHERE   CarrierTrackingNumber = @CarrierTrackingNumber
ORDER BY SalesOrderID,
        ProductID
OPTION (RECOMPILE); 


22-3. Executing a Query Without Locking

Solution #1

SELECT  DocumentNode,
        Title
FROM    Production.Document WITH (NOLOCK)
WHERE   Status = 1;


Solution #2

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
SELECT  DocumentNode,
        Title
FROM    Production.Document
WHERE   Status = 1;


22-4. Forcing an Index Seek

SELECT DISTINCT
        TransactionID,
        TransactionDate
FROM    Production.TransactionHistory WITH (FORCESEEK)
WHERE   ReferenceOrderID BETWEEN 1000 AND 100000;

SELECT DISTINCT
        TransactionID,
        TransactionDate
FROM    Production.TransactionHistory WITH (FORCESEEK,
        INDEX (IX_TransactionHistory_ReferenceOrderID_ReferenceOrderLineID))
WHERE   ReferenceOrderID BETWEEN 1000 AND 100000;


22-5. Forcincg an Index Scan

SELECT DISTINCT
        TransactionID,
        TransactionDate
FROM    Production.TransactionHistory WITH (FORCESCAN)
WHERE   ReferenceOrderID BETWEEN 1000 AND 100000;

SELECT DISTINCT
        TransactionID,
        TransactionDate
FROM    Production.TransactionHistory WITH (FORCESCAN,
        INDEX (PK_TransactionHistory_TransactionID))
WHERE   ReferenceOrderID BETWEEN 1000 AND 100000;


22-6. Optimizing for First Rows

SELECT  ProductID, TransactionID, ReferenceOrderID
FROM    Production.TransactionHistory
ORDER BY ProductID
OPTION (FAST 20);


22-7. Specifying Join Order

SELECT  PP.FirstName, PP.LastName, PA.City
FROM    Person.Person PP
        INNER JOIN Person.BusinessEntityAddress PBA
            ON PP.BusinessEntityID = PBA.BusinessEntityID
        INNER JOIN Person.Address PA
            ON PBA.AddressID = PA.AddressID
OPTION (FORCE ORDER)


22-8. Forcing Use of a Specific Index

SELECT  ProductID, TransactionID, ReferenceOrderID
FROM    Production.TransactionHistory 
        WITH (INDEX (IX_TransactionHistory_ProductID))
ORDER BY ProductID


22-9. Optimizing for Specific Parameter Values

DECLARE @TTYPE NCHAR(1);
SET @TTYPE = 'P';

SELECT  * 
FROM    Production.TransactionHistory TH
WHERE   TH.TransactionType = @TTYPE
OPTION (OPTIMIZE FOR (@TTYPE = 'S'));






