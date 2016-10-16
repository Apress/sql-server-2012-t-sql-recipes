/* 16-1. Creating a Table Index */

USE AdventureWorks2012;
GO
If Not Exists (Select 1 from sys.objects where name = 'TerminationReason' and SCHEMA_NAME(schema_id) = 'HumanResources')
BEGIN
CREATE TABLE HumanResources.TerminationReason(
  TerminationReasonID smallint IDENTITY(1,1) NOT NULL, 
  TerminationReason varchar(50) NOT NULL, 
  DepartmentID smallint NOT NULL, 
  CONSTRAINT FK_TerminationReason_DepartmentID FOREIGN KEY (DepartmentID) 
REFERENCES HumanResources.Department(DepartmentID) 
	);
END

USE AdventureWorks2012;
GO
ALTER TABLE HumanResources.TerminationReason
ADD CONSTRAINT PK_TerminationReason PRIMARY KEY CLUSTERED (TerminationReasonID);

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NCI_TerminationReason_DepartmentID ON HumanResources.TerminationReason (DepartmentID);

/* 16-2. Enforcing Uniqueness on Non-key Columns */

--create Unique Index
USE AdventureWorks2012;
GO
CREATE UNIQUE NONCLUSTERED INDEX UNI_TerminationReason ON HumanResources.TerminationReason (TerminationReason);

--Insert records with success
USE AdventureWorks2012;
GO
INSERT INTO HumanResources.TerminationReason (DepartmentID, TerminationReason) 
  VALUES (1, 'Bad Engineering Skills')
  ,(2, 'Breaks Expensive Tools');

--Insert records - fail
USE AdventureWorks2012;
GO
INSERT INTO HumanResources.TerminationReason (DepartmentID, TerminationReason) 
	VALUES (2, 'Bad Engineering Skills');

--Select to confirm
USE AdventureWorks2012;
GO
SELECT TerminationReasonID, TerminationReason, DepartmentID 
	FROM HumanResources.TerminationReason;

/* 16-3. Creating an Index on Multiple Columns */

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason(TerminationReason, DepartmentID);

/* 16-4. Defining Index Column Sort Direction */

USE AdventureWorks2012;
GO
ALTER TABLE HumanResources.TerminationReason
ADD ViolationSeverityLevel smallint;
GO
CREATE NONCLUSTERED INDEX NI_TerminationReason_ViolationSeverityLevel 
  ON HumanResources.TerminationReason (ViolationSeverityLevel DESC);

/* 16-5. Viewing Index Metadata */

USE AdventureWorks2012;
GO
EXEC sp_helpindex 'HumanResources.Employee';

USE AdventureWorks2012;
GO
SELECT index_name = SUBSTRING(name, 1,30) ,
		allow_row_locks,
		allow_page_locks,
		is_disabled,
		fill_factor,
		has_filter 
	FROM sys.indexes 
	WHERE object_id = OBJECT_ID('HumanResources.Employee');

/* 16-6. Disabling an Index */

USE AdventureWorks2012;
GO
ALTER INDEX UNI_TerminationReason 
  ON HumanResources.TerminationReason DISABLE

/* 16-7. Dropping Indexes */

USE AdventureWorks2012;
GO
DROP INDEX HumanResources.TerminationReason.UNI_TerminationReason;

/* 16-8. Changing an Existing Index */

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason(TerminationReason, DepartmentID)
WITH (DROP_EXISTING = ON);
GO

--add column to existing nonclustered index
USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason(TerminationReason, ViolationSeverityLevel, DepartmentID DESC)
WITH (DROP_EXISTING = ON);
GO

/* 16-9. Sorting in Tempdb */

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_Address_PostalCode 
  ON Person.Address (PostalCode) 
  WITH (SORT_IN_TEMPDB = ON);

/* 16-10. Controlling Index Creation Parallelism */

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_Address_AddressLine1 
  ON Person.Address (AddressLine1) 
  WITH (MAXDOP = 4);

/* 16-11. User Table Access During Index Creation */

USE AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NCI_ProductVendor_MinOrderQty 
  ON Purchasing.ProductVendor(MinOrderQty) 
  WITH (ONLINE = ON); -- Online option is an Enterprise Edition feature

/* 16-12. Using an Index INCLUDE */

USE AdventureWorks2012;
GO
ALTER TABLE HumanResources.TerminationReason 
  ADD LegalDescription varchar(max);
Go
DROP INDEX HumanResources.TerminationReason.NI_TerminationReason_TerminationReason_DepartmentID;
Go
CREATE NONCLUSTERED INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason (TerminationReason, DepartmentID) 
  INCLUDE (LegalDescription);

/* 16-13. Using PADINDEX and FILLFACTOR */

USE AdventureWorks2012;
GO
DROP INDEX HumanResources.TerminationReason.NI_TerminationReason_TerminationReason_DepartmentID;
GO
CREATE NONCLUSTERED INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason (TerminationReason ASC, DepartmentID ASC) 
  WITH (PAD_INDEX=ON, FILLFACTOR=50);
GO

/* 16-14. Disabling Page and/or Row Index Locking */

USE AdventureWorks2012;
GO
-- Disable page locks. Table and row locks can still be used. 
CREATE INDEX NI_EmployeePayHistory_Rate 
  ON HumanResources.EmployeePayHistory (Rate) 
  WITH (ALLOW_PAGE_LOCKS=OFF);
-- Disable page and row locks. Only table locks can be used.
ALTER INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason
  SET (ALLOW_PAGE_LOCKS=OFF,ALLOW_ROW_LOCKS=OFF );
-- Allow page and row locks.
ALTER INDEX NI_TerminationReason_TerminationReason_DepartmentID 
  ON HumanResources.TerminationReason
  SET (ALLOW_PAGE_LOCKS=ON,ALLOW_ROW_LOCKS=ON );

/* 16-15. Creating an Index on a Filegroup */

Use master;
GO
ALTER DATABASE AdventureWorks2012 
  ADD FILEGROUP FG2;

Use AdventureWorks2012;
GO	
ALTER DATABASE AdventureWorks2012
  ADD FILE
--Please ensure the Apress directory exists or change the path in the FILENAME statement
  ( NAME = AW2,FILENAME = 'c:\Apress\aw2.ndf',SIZE = 1MB ) 
  TO FILEGROUP FG2;

Use AdventureWorks2012;
GO
CREATE INDEX NI_ProductPhoto_ThumnailPhotoFileName 
  ON Production.ProductPhoto (ThumbnailPhotoFileName) 
  ON [FG2];

/* 16-16. Implementing Index Partitioning */

Use AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NI_WebSiteHits_WebSitePage 
  ON Sales.WebSiteHits (WebSitePage) 
  ON [HitDateRangeScheme] (HitDate);

/* 16-17. Indexing a Subset of Rows */

Use AdventureWorks2012;
GO
SELECT SalesOrderID
  FROM Sales.SalesOrderDetail
  WHERE UnitPrice BETWEEN 150.00 AND 175.00;

Use AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NCI_UnitPrice_SalesOrderDetail
  ON Sales.SalesOrderDetail(UnitPrice)
  WHERE UnitPrice >= 150.00 AND UnitPrice <= 175.00;

Use AdventureWorks2012;
GO
SELECT SalesOrderDetailID 
  FROM Sales.SalesOrderDetail 
  WHERE ProductID IN (776, 777) 
  AND OrderQty > 10;

Use AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NCI_ProductID_SalesOrderDetail 
  ON Sales.SalesOrderDetail(ProductID,OrderQty) 
  WHERE ProductID IN (776, 777);

/* 16-18. Reducing Index Size */

Use AdventureWorks2012;
GO
CREATE NONCLUSTERED INDEX NCI_SalesOrderDetail_CarrierTrackingNumber 
  ON Sales.SalesOrderDetail (CarrierTrackingNumber) 
  WITH (DATA_COMPRESSION = PAGE);

Use AdventureWorks2012;
GO
ALTER INDEX NCI_SalesOrderDetail_CarrierTrackingNumber
ON Sales.SalesOrderDetail
REBUILD
WITH (DATA_COMPRESSION = ROW);
