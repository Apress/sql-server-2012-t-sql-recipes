/* 18-1. Creating Scalar Functions */

Use AdventureWorks2012;
GO

Create Function dbo.udf_CheckForSQLInjection (@TSQLString varchar(max))
Returns bit

AS

BEGIN

DECLARE  @IsSuspect  bit;

--  UDF  assumes  string  will  be  left  padded  with  a  single  space
SET  @TSQLString  =  '  '  +  @TSQLString;

IF        (PATINDEX('%  xp_%'  ,  @TSQLString  )  <>  0 OR
      PATINDEX('%  sp_%'  ,  @TSQLString  )  <>  0      OR
      PATINDEX('%  DROP %'  ,  @TSQLString  )  <>  0   OR
      PATINDEX('%  GO %'  ,  @TSQLString  )  <>  0  OR
      PATINDEX('%  INSERT %'  ,  @TSQLString  )  <>  0 OR
      PATINDEX('%  UPDATE %'  ,  @TSQLString  )  <>  0 OR
      PATINDEX('%  DBCC %'  ,  @TSQLString  )  <>  0   OR
      PATINDEX('%  SHUTDOWN %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  ALTER %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  CREATE %'  ,  @TSQLString  )  <>  0 OR
      PATINDEX('%;%'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  EXECUTE %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  BREAK %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  BEGIN %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  CHECKPOINT %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  BREAK %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  COMMIT %'  ,  @TSQLString  )<>  0   OR
      PATINDEX('%  TRANSACTION %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  CURSOR %'  ,  @TSQLString  )<>  0   OR
      PATINDEX('%  GRANT %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  DENY %'  ,  @TSQLString  )<>  0     OR
      PATINDEX('%  ESCAPE %'  ,  @TSQLString  )<>  0   OR
      PATINDEX('%  WHILE %'  ,  @TSQLString  )<>  0    OR
      PATINDEX('%  OPENDATASOURCE %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  OPENQUERY %'  ,  @TSQLString  )<>  0  OR
      PATINDEX('%  OPENROWSET %'  ,  @TSQLString  )<>  0      OR
      PATINDEX('%  EXEC %'  ,  @TSQLString  )<>  0)

BEGIN
      SELECT  @IsSuspect  =     1;
END
ELSE
BEGIN
      SELECT  @IsSuspect  =     0;
END
      RETURN  (@IsSuspect);
END

GO

--test the udf
Use AdventureWorks2012;
GO
SELECT dbo.udf_CheckForSQLInjection ('SELECT * FROM HumanResources.Department');

--test the udf
Use AdventureWorks2012;
GO
SELECT dbo.udf_CheckForSQLInjection (';SHUTDOWN');

--test the udf
Use AdventureWorks2012;
GO
SELECT dbo.udf_CheckForSQLInjection ('DROP HumanResources.Department');


--example two
Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_ProperCase(@UnCased varchar(max))
RETURNS varchar(max)
AS
BEGIN
SET @UnCased = LOWER(@UnCased)
DECLARE @C int
SET @C = ASCII('a')
WHILE @C <= ASCII('z') BEGIN
SET @UnCased = REPLACE( @UnCased, ' ' + CHAR(@C), ' ' + CHAR(@C-32)) SET @C = @C + 1
END
SET @UnCased = CHAR(ASCII(LEFT(@UnCased, 1))-32) + RIGHT(@UnCased, LEN(@UnCased)-1)

RETURN @UnCased END
GO

--test the udf
SELECT dbo.udf_ProperCase(DocumentSummary)
FROM Production.Document
WHERE FileName = 'Installing Replacement Pedals.doc';

/* 18-2. Creating Inline Functions */

Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_ReturnAddress
(@BusinessEntityID int) 
RETURNS TABLE
AS RETURN (
SELECT t.Name AddressTypeNM, a.AddressLine1, a.City,
a.StateProvinceID, a.PostalCode 
FROM Person.Address a 
INNER JOIN Person.BusinessEntityAddress e 
ON a.AddressID = e.AddressID 
INNER JOIN Person.AddressType t 
ON e.AddressTypeID = t.AddressTypeID 
WHERE e.BusinessEntityID = @BusinessEntityID )
;
GO

--test the udf
Use AdventureWorks2012;
GO
SELECT AddressTypeNM, AddressLine1, City, PostalCode 
FROM dbo.udf_ReturnAddress(332);
GO

/* 18-3. Creating Multi-Statement User-Defined Functions */

-- Creates a UDF that returns a string array as a table result set 
Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_ParseArray
( @StringArray varchar(max), @Delimiter char(1) ) RETURNS @StringArrayTable TABLE (Val varchar(50)) 
AS 
BEGIN
DECLARE @Delimiter_position int
IF RIGHT(@StringArray,1) != @Delimiter
SET @StringArray = @StringArray + @Delimiter
WHILE CHARINDEX(@Delimiter, @StringArray) <> 0 
BEGIN 
SELECT @Delimiter_position = CHARINDEX(@Delimiter, @StringArray)
INSERT INTO @StringArrayTable (Val)
      VALUES (LEFT(@StringArray, @Delimiter_position - 1));

SELECT @StringArray = STUFF(@StringArray, 1, @Delimiter_position, '') ;
END

RETURN 
END
GO

--test the udf
SELECT Val
FROM dbo.udf_ParseArray('A,B,C,D,E,F,G', ',');
GO

/* 18-4. Modifying User-Defined Functions */

Use AdventureWorks2012;
GO
ALTER FUNCTION dbo.udf_ParseArray ( @StringArray varchar(max),
@Delimiter char(1) ,
@MinRowSelect int,
@MaxRowSelect int)
RETURNS @StringArrayTable TABLE (RowNum int IDENTITY(1,1), Val varchar(50)) 
AS 
BEGIN

DECLARE @Delimiter_position int
IF RIGHT(@StringArray,1) != @Delimiter
      SET @StringArray = @StringArray + @Delimiter;
WHILE CHARINDEX(@Delimiter, @StringArray) <> 0 
BEGIN
SELECT @Delimiter_position = CHARINDEX(@Delimiter, @StringArray);

INSERT INTO @StringArrayTable (Val)
      VALUES (LEFT(@StringArray, @Delimiter_position - 1));

SELECT @StringArray = STUFF(@StringArray, 1, @Delimiter_position, '');
END
DELETE @StringArrayTable 
      WHERE RowNum < @MinRowSelect OR RowNum > @MaxRowSelect;
RETURN 
END
GO

--test the modification
Use AdventureWorks2012;
GO
SELECT RowNum,Val
FROM dbo.udf_ParseArray('A,B,C,D,E,F,G', ',',3,5);
GO

/* 18-5. Viewing UDF Metadata */

Use AdventureWorks2012;
GO
SELECT name, o.type_desc
      , (Select definition as [processing-instruction(definition)]
            FROM sys.sql_modules
            Where object_id = s.object_id
            FOR XML PATH(''), TYPE
      )
FROM sys.sql_modules s 
INNER JOIN sys.objects o
      ON s.object_id = o.object_id 
WHERE o.type IN ('IF', -- Inline Table UDF
      'TF', -- Multistatement Table UDF
      'FN') -- Scalar UDF
;

/* 18-6. Maintaining Reusable Code */

Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_GET_AssignedEquipment (@Title nvarchar(50), @HireDate datetime, @SalariedFlag bit) 
RETURNS nvarchar(50) 
AS 
BEGIN
DECLARE @EquipmentType nvarchar(50)
IF @Title LIKE 'Chief%' OR
      @Title LIKE 'Vice%' OR
      @Title = 'Database Administrator' 
BEGIN
      SET @EquipmentType = 'PC Build A' ;
END
IF @EquipmentType IS NULL AND @SalariedFlag = 1 
BEGIN
      SET @EquipmentType = 'PC Build B' ;
END
IF @EquipmentType IS NULL AND @HireDate < '1/1/2002' 
BEGIN
      SET @EquipmentType = 'PC Build C' ;
END
IF @EquipmentType IS NULL 
BEGIN
      SET @EquipmentType = 'PC Build D' ;
END
RETURN @EquipmentType ;
END
GO

--test the udf
Use AdventureWorks2012;
GO
SELECT PC_Build = dbo.udf_GET_AssignedEquipment(JobTitle, HireDate, SalariedFlag) 
      , Employee_Count = COUNT(*)  
FROM HumanResources.Employee 
GROUP BY dbo.udf_GET_AssignedEquipment(JobTitle, HireDate, SalariedFlag) 
ORDER BY dbo.udf_GET_AssignedEquipment(JobTitle, HireDate, SalariedFlag);

--test the udf
Use AdventureWorks2012;
GO
SELECT JobTitle,BusinessEntityID
      ,PC_Build = dbo.udf_GET_AssignedEquipment(JobTitle, HireDate, SalariedFlag)  
FROM HumanResources.Employee 
WHERE dbo.udf_GET_AssignedEquipment(JobTitle, HireDate, SalariedFlag) 
      IN ('PC Build A', 'PC Build B');

/* 18-7. Cross-Referencing Natural Key Values */

Use AdventureWorks2012;
GO
CREATE TABLE dbo.DimProductSalesperson
(DimProductSalespersonID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
ProductCD char(10) NOT NULL,
CompanyNBR int NOT NULL,
SalespersonNBR int NOT NULL );
GO

--create staging table
Use AdventureWorks2012;
GO
CREATE TABLE dbo.Staging_PRODSLSP ( ProductCD char(10) NOT NULL,
CompanyNBR int NOT NULL,
SalespersonNBR int NOT NULL );
GO

--insert records
Use AdventureWorks2012;
GO
INSERT dbo.Staging_PRODSLSP (ProductCD, CompanyNBR, SalespersonNBR) 
      VALUES ('2391A23904', 1, 24);
INSERT dbo.Staging_PRODSLSP (ProductCD, CompanyNBR, SalespersonNBR) 
      VALUES ('X129483203', 1, 34);
GO

--insert records to prod table
Use AdventureWorks2012;
GO
INSERT Into dbo.DimProductSalesperson (ProductCD, CompanyNBR, SalespersonNBR) 
      SELECT s.ProductCD, s.CompanyNBR, s.SalespersonNBR 
            FROM dbo.Staging_PRODSLSP s 
            LEFT OUTER JOIN dbo.DimProductSalesperson d 
                  ON s.ProductCD = d.ProductCD 
                  AND s.CompanyNBR = d.CompanyNBR 
                  AND s.SalespersonNBR = d.SalespersonNBR 
      WHERE d.DimProductSalespersonID IS NULL;
GO

--create udf as alternative
Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_GET_Check_NK_DimProductSalesperson (@ProductCD char(10), @CompanyNBR int, @SalespersonNBR int ) 
RETURNS bit 
AS 
BEGIN
DECLARE @Exists bit
IF EXISTS (SELECT DimProductSalespersonID 
            FROM dbo.DimProductSalesperson 
            WHERE @ProductCD = @ProductCD 
            AND @CompanyNBR = @CompanyNBR 
            AND @SalespersonNBR = @SalespersonNBR) 
BEGIN
      SET @Exists = 1;
END 
ELSE 
BEGIN
      SET @Exists = 0;
END
RETURN @Exists 
END
GO

--insert records
Use AdventureWorks2012;
GO
INSERT INTO dbo.DimProductSalesperson(ProductCD, CompanyNBR, SalespersonNBR)
      SELECT ProductCD, CompanyNBR, SalespersonNBR
      FROM dbo.Staging_PRODSLSP
      WHERE dbo.udf_GET_Check_NK_DimProductSalesperson
       (ProductCD, CompanyNBR, SalespersonNBR) = 0;
GO

/* 18-8. Replacing a View with a Function */

Use AdventureWorks2012;
GO
CREATE FUNCTION dbo.udf_SEL_SalesQuota ( @BusinessEntityID int, @ShowHistory bit ) 
RETURNS @SalesQuota TABLE (BusinessEntityID int, QuotaDate datetime, SalesQuota money)

AS 
BEGIN
INSERT Into @SalesQuota(BusinessEntityID, QuotaDate, SalesQuota)
      SELECT BusinessEntityID, ModifiedDate, SalesQuota
      FROM Sales.SalesPerson
      WHERE BusinessEntityID = @BusinessEntityID;
IF @ShowHistory = 1 
BEGIN
INSERT Into @SalesQuota(BusinessEntityID, QuotaDate, SalesQuota)
      SELECT BusinessEntityID, QuotaDate, SalesQuota
      FROM Sales.SalesPersonQuotaHistory
      WHERE BusinessEntityID = @BusinessEntityID;
END
RETURN 
END
GO

--test the udf
Use AdventureWorks2012;
GO

SELECT BusinessEntityID, QuotaDate, SalesQuota 
      FROM dbo.udf_SEL_SalesQuota (275,0);

--test the udf
Use AdventureWorks2012;
GO

SELECT BusinessEntityID, QuotaDate, SalesQuota 
      FROM dbo.udf_SEL_SalesQuota (275,1);

/* 18-9. Dropping a Function */

Use AdventureWorks2012;
GO
DROP FUNCTION dbo.udf_ParseArray;

/* 18-10. Creating and Using User-Defined Types */

Use AdventureWorks2012;
GO
/*
-- In this example, we assume the company's Account number will 
-- be used in multiple tables, and that it will always have a fixed 
-- 14 character length and will never allow NULL values
*/

CREATE TYPE dbo.AccountNBR FROM char(14) NOT NULL;
GO

--use this newly defined type
Use AdventureWorks2012;
GO
-- The new data type is now used in two different tables
CREATE TABLE dbo.InventoryAccount
(InventoryAccountID int NOT NULL,
InventoryID int NOT NULL,
InventoryAccountNBR AccountNBR);
GO
CREATE TABLE dbo.CustomerAccount
(CustomerAccountID int NOT NULL,
CustomerID int NOT NULL,
CustomerAccountNBR AccountNBR);
GO

--use type in variable definition
Use AdventureWorks2012;
GO
CREATE PROCEDURE dbo.usp_SEL_CustomerAccount
@CustomerAccountNBR AccountNBR 

AS
SELECT CustomerAccountID, CustomerID, CustomerAccountNBR
FROM dbo.CustomerAccount
WHERE CustomerAccountNBR = CustomerAccountNBR;
GO

--test the new type
Use AdventureWorks2012;
GO
DECLARE @CustomerAccountNBR AccountNBR 
SET @CustomerAccountNBR = '1294839482';
EXECUTE dbo.usp_SEL_CustomerAccount @CustomerAccountNBR;
GO

--view underlying base type
Use AdventureWorks2012;
GO
EXECUTE sp_help 'dbo.AccountNBR';
GO

/* 18-11. Identifying Dependencies on User-Defined Types */

--objects the use an UDT
Use AdventureWorks2012;
GO
SELECT Table_Name = OBJECT_NAME(c.object_id) , Column_name = c.name 
FROM sys.columns c
      INNER JOIN sys.types t 
      ON c.user_type_id = t.user_type_id 
WHERE t.name = 'AccountNBR';

--queries that use an UDT
Use AdventureWorks2012;
GO
/*
-- Now see what parameters reference the AccountNBR data type 
*/
SELECT ProcFunc_Name = OBJECT_NAME(p.object_id) , Parameter_Name = p.name  
FROM sys.parameters p 
      INNER JOIN sys.types t 
      ON p.user_type_id = t.user_type_id 
WHERE t.name = 'AccountNBR';

/* 18-12. Passing Table-Valued Parameters */

--old style
Use AdventureWorks2012;
GO
CREATE PROCEDURE dbo.usp_INS_Department_Oldstyle
@Name_l nvarchar(50),
@GroupName_l nvarchar(50),
@Name_2 nvarchar(50),
@GroupName_2 nvarchar(50),
@Name_3 nvarchar(50),
@GroupName_3 nvarchar(50),
@Name_4 nvarchar(50),
@GroupName_4 nvarchar(50),
@Name_5 nvarchar(50),
@GroupName_5 nvarchar(50) 

AS
INSERT INTO HumanResources.Department(Name, GroupName)
      VALUES (@Name_l, @GroupName_l)
INSERT INTO HumanResources.Department(Name, GroupName)
      VALUES (@Name_2, @GroupName_2);
INSERT INTO HumanResources.Department(Name, GroupName)
      VALUES (@Name_3, @GroupName_3);
INSERT INTO HumanResources.Department (Name, GroupName)
      VALUES (@Name_4, @GroupName_4);
INSERT INTO HumanResources.Department (Name, GroupName)
      VALUES (@Name_5, @GroupName_5);
GO

--singleton insert
Use AdventureWorks2012;
GO
CREATE PROCEDURE dbo.usp_INS_Department_Oldstyle_V2
@Name nvarchar(50),
@GroupName nvarchar(50) 
AS
INSERT INTO HumanResources.Department (Name, GroupName)
      VALUES (@Name, @GroupName);
GO

--create tvp
Use AdventureWorks2012;
GO
CREATE TYPE Department_TT AS TABLE (Name nvarchar(50), GroupName nvarchar(50));
GO

--reference tvp
Use AdventureWorks2012;
GO
CREATE PROCEDURE dbo.usp_INS_Department_NewStyle
      @DepartmentTable as Department_TT 
READONLY 
AS

INSERT INTO HumanResources.Department (Name, GroupName)
      SELECT Name, GroupName 
            FROM @DepartmentTable;
GO

--use the tvp
Use AdventureWorks2012;
GO
/*
-- I can declare our new type for use within a T-SQL batch 
-- Insert multiple rows into this table-type variable
*/

DECLARE @StagingDepartmentTable as Department_TT
INSERT INTO @StagingDepartmentTable(Name, GroupName)
      VALUES ('Archivists', 'Accounting');
INSERT INTO @StagingDepartmentTable(Name, GroupName)
      VALUES ('Public Media', 'Legal');
INSERT @StagingDepartmentTable(Name, GroupName)
      VALUES ('Internal Admin', 'Office Administration');
/*
-- Pass this table-type variable to the procedure in a single call
*/
EXECUTE dbo.usp_INS_Department_NewStyle @StagingDepartmentTable;
GO

/* 18-13. Dropping User-Defined Types */

--remove references to udt
Use AdventureWorks2012;
GO
ALTER TABLE dbo.InventoryAccount
ALTER COLUMN InventoryAccountNBR char(14);
GO
ALTER TABLE dbo.CustomerAccount
ALTER COLUMN CustomerAccountNBR char(14);
GO

ALTER PROCEDURE dbo.usp_SEL_CustomerAccount
@CustomerAccountNBR char(14) 

AS

SELECT CustomerAccountID, CustomerID, CustomerAccountNBR
FROM dbo.CustomerAccount
WHERE CustomerAccountNBR = @CustomerAccountNBR;
GO

--drop udt
Use AdventureWorks2012;
GO
DROP TYPE dbo.AccountNBR;
