/* 23-1. Displaying Index Fragmentation */

USE AdventureWorks2012;
GO
SELECT OBJECT_NAME(object_id) ObjectName,
index_id,
index_type_desc,
avg_fragmentation_in_percent 
FROM sys.dm_db_index_physical_stats (DB_ID('AdventureWorks2012'),NULL, NULL, NULL, 'LIMITED') 
WHERE avg_fragmentation_in_percent > 30 
ORDER BY OBJECT_NAME(object_id);

--second example
USE AdventureWorks2012;
GO
SELECT OBJECT_NAME(f.object_id) ObjectName,
        i.name IndexName,
        f.index_type_desc,
        f.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats
        (DB_ID('AdventureWorks2012'), OBJECT_ID('Production.ProductDescription'), 2, NULL, 'LIMITED')  f
INNER JOIN sys.indexes i 
        ON i.object_id = f.object_id 
        AND i.index_id = f.index_id;

/* 23-2. Rebuilding Indexes */

--specific index
USE AdventureWorks2012;
GO
ALTER INDEX PK_ShipMethod_ShipMethodID ON Purchasing.ShipMethod REBUILD;

-- Rebuild all indexes on a specific table
USE AdventureWorks2012;
GO
ALTER INDEX ALL
ON Purchasing.PurchaseOrderHeader REBUILD;

-- Rebuild an index, while keeping it available -- for queries (requires Enterprise Edition)
USE AdventureWorks2012;
GO
ALTER INDEX PK_ProductReview_ProductReviewID 
ON Production.ProductReview REBUILD WITH (ONLINE = ON);

-- Rebuild an index, using a new fill factor and -- sorting in tempdb
USE AdventureWorks2012;
GO
ALTER INDEX PK_TransactionHistory_TransactionID 
ON Production.TransactionHistory REBUILD WITH (FILLFACTOR = 75, SORT_IN_TEMPDB = ON);

-- Rebuild an index with page-level data compression enabled 
USE AdventureWorks2012;
GO
ALTER INDEX PK_ShipMethod_ShipMethodID 
ON Purchasing.ShipMethod REBUILD WITH (DATA_COMPRESSION = PAGE);

/* 23-3. Defragmenting Indexes */

-- Reorganize a specific index
USE AdventureWorks2012;
GO
ALTER INDEX PK_TransactionHistory_TransactionID
ON Production.TransactionHistory
REORGANIZE;
-- Reorganize all indexes for a table
-- Compact large object data types
USE AdventureWorks2012;
GO
ALTER INDEX ALL
ON HumanResources.JobCandidate
REORGANIZE
WITH (LOB_COMPACTION=ON);

/* 23-4. Rebuilding a Heap */

--create heap table
USE AdventureWorks2012;
GO
-- Create an unindexed table based on another table 
SELECT ShiftID, Name, StartTime, EndTime, ModifiedDate 
INTO dbo.Heap_Shift FROM HumanResources.Shift;

--validate that the new table is a heap
USE AdventureWorks2012;
GO
SELECT type_desc FROM sys.indexes 
WHERE object_id = OBJECT_ID('Heap_Shift');

--rebuild the heap
USE AdventureWorks2012;
GO
ALTER TABLE dbo.Heap_Shift REBUILD;

/* 23-5. Displaying Index Usage */

USE AdventureWorks2012;
GO
SELECT *
FROM Sales.Customer;

USE AdventureWorks2012;
GO
SELECT AccountNumber 
FROM Sales.Customer 
WHERE TerritoryID = 4;

--see index usage from executing previous two queries
USE AdventureWorks2012;
GO
SELECT i.name IndexName, user_seeks, user_scans, last_user_seek, last_user_scan 
FROM sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i 
ON s.object_id = i.object_id 
AND s.index_id = i.index_id 
WHERE database_id = DB_ID('AdventureWorks2012') 
AND s.object_id = OBJECT_ID('Sales.Customer');

/* 23-6. Manually Creating Statistics */

USE AdventureWorks2012;
GO
CREATE STATISTICS Stats_Customer_AccountNumber 
ON Sales.Customer (AccountNumber) WITH FULLSCAN;

/* 23-7. Creating Statistics on a Subset of Rows */

USE AdventureWorks2012;
GO
CREATE STATISTICS Stats_SalesOrderDetail_UnitPrice_Filtered ON Sales.SalesOrderDetail (UnitPrice) 
WHERE UnitPrice >= 1000.00 AND UnitPrice <= 1500.00 
WITH FULLSCAN;

/* 23-8. Updating Statistics */

USE AdventureWorks2012;
GO
UPDATE STATISTICS Sales.Customer 
WITH FULLSCAN;

/* 23-9. Generating Statistics Across All Tables */

USE AdventureWorks2012;
GO
EXECUTE sp_createstats;
GO

/* 23-10. Updating Statistics Across All Tables */

USE AdventureWorks2012;
GO
EXECUTE sp_updatestats;
GO

/* 23-11. Viewing Statistics Details */

USE AdventureWorks2012;
GO
DBCC SHOW_STATISTICS ( 'Sales.Customer' , Stats_Customer_AccountNumber);

/* 23-12. Removing Statistics */

USE AdventureWorks2012;
GO
DROP STATISTICS Sales.Customer.Stats_Customer_AccountNumber;

