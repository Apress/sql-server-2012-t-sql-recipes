/* 21-1. Capturing Executing Queries */

SELECT r.session_id, r.status, r.start_time, r.command, s.text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.status = 'running';

/* 21-2. Viewing Estimated Query Execution Plans */

--example one
USE AdventureWorks2012;
GO
SET SHOWPLAN_TEXT ON;
GO
SELECT p.Name, p.ProductNumber, r.ReviewerName
FROM Production.Product p
INNER JOIN Production.ProductReview r 
ON p.ProductID = r.ProductID 
WHERE r.Rating > 2;
GO
SET SHOWPLAN_TEXT OFF;
GO

--example two
USE AdventureWorks2012;
GO
SET SHOWPLAN_XML ON;
GO
SELECT p.Name, p.ProductNumber, r.ReviewerName
FROM Production.Product p
INNER JOIN Production.ProductReview r 
ON p.ProductID = r.ProductID 
WHERE r.Rating > 2;
GO
SET SHOWPLAN_XML OFF;
GO

/* 21-3. Viewing Execution Runtime Information */

USE AdventureWorks2012;
GO
SET STATISTICS IO ON;
GO
SELECT t.Name TerritoryNM,
SUM(TotalDue) TotalDue 
FROM Sales.SalesOrderHeader h 
INNER JOIN Sales.SalesTerritory t 
ON h.TerritoryID = t.TerritoryID 
WHERE OrderDate BETWEEN '1/1/2008' AND '12/31/2008' 
GROUP BY t.Name 
ORDER BY t.Name
SET STATISTICS IO OFF;
GO

/* 21-4. Viewing Statistics for Cached Plans */

--isolate a simple query
DBCC FREEPROCCACHE;
GO
USE AdventureWorks2012;
GO
SELECT BusinessEntityID, TerritoryID, SalesQuota
FROM Sales.SalesPerson;

--find the query in cache
USE AdventureWorks2012;
GO
SELECT  t.text,
st.total_logical_reads,
st.total_physical_reads,
st.total_elapsed_time/1000000 Total_Time_Secs,
st.total_logical_writes 
FROM sys.dm_exec_query_stats st 
CROSS APPLY sys.dm_exec_sql_text(st.sql_handle) t;

/* 21-5. Viewing Record Counts for Cached Plans */

USE AdventureWorks2012;
GO
SELECT BusinessEntityID, TerritoryID, SalesQuota
FROM Sales.SalesPerson;

USE AdventureWorks2012;
GO
SELECT  t.text,
st.total_rows,
st.last_rows,
st.min_rows,
st.max_rows
FROM sys.dm_exec_query_stats st 
CROSS APPLY sys.dm_exec_sql_text(st.sql_handle) t;

/* 21-6. Viewing Aggregated Performance Statistics Based on Query or Plan Patterns */

USE AdventureWorks2012;
GO
SELECT BusinessEntityID
FROM Purchasing.vVendorWithContacts
WHERE EmailAddress = 'cheryl1@adventure-works.com';
SELECT BusinessEntityID
FROM Purchasing.vVendorWithContacts
WHERE EmailAddress = 'stuart2@adventure-works.com';
SELECT BusinessEntityID
FROM Purchasing.vVendorWithContacts
WHERE EmailAddress = 'suzanne0@adventure-works.com';

USE AdventureWorks2012;
GO
SELECT  t.text,
st.total_logical_reads 
FROM sys.dm_exec_query_stats st 
CROSS APPLY sys.dm_exec_sql_text(st.sql_handle) t 
WHERE t.text LIKE '%Purchasing.vVendorWithContacts%';

USE AdventureWorks2012;
GO
SELECT st.query_hash,
COUNT(t.text) query_count,
SUM(st.total_logical_reads) total_logical_reads 
FROM sys.dm_exec_query_stats st 
CROSS APPLY sys.dm_exec_sql_text(st.sql_handle) t 
WHERE text LIKE '%Purchasing.vVendorWithContacts%' 
GROUP BY st.query_hash;

/* 21-7. Identifying the Top Bottleneck */

USE AdventureWorks2012;
GO 
SELECT  TOP 2
wait_type, wait_time_ms 
FROM sys.dm_os_wait_stats 
WHERE wait_type NOT IN ('LAZYWRITER_SLEEP', 'SQLTRACE_BUFFER_FLUSH', 'REQUEST_FOR_DEADLOCK_SEARCH'
					, 'LOGMGR_QUEUE', 'CHECKPOINT_QUEUE', 'CLR_AUTO_EVENT','WAITFOR', 'BROKER_TASK_STOP'
					, 'SLEEP_TASK', 'BROKER_TO_FLUSH') 
ORDER BY wait_time_ms DESC;

--cleare currently accumulated wait type stats
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);

/* 21-8. Identifying I/O Contention by Database and File */

USE master;
GO 
SELECT DB_NAME(ifs.database_id) DatabaseNM,
ifs.file_id FileID,
mf.type_desc FileType,
io_stall IOStallsMs,
size_on_disk_bytes FileBytes,
num_of_bytes_written BytesWritten,
num_of_bytes_read BytesRead 
FROM sys.dm_io_virtual_file_stats(NULL, NULL) ifs
    Inner Join sys.master_files mf
        On ifs.database_id = mf.database_id
        And ifs.file_id = mf.file_id
ORDER BY io_stall DESC;

/* 21-9. Parameterizing Ad Hoc Queries */

USE AdventureWorks2012;
GO 
EXECUTE sp_executesql N'SELECT TransactionID, ProductID, TransactionType, Quantity FROM   Production.TransactionHistoryArchive WHERE   ProductID = @ProductID AND
TransactionType = @TransactionType AND Quantity > @Quantity', N'@ProductID int, @TransactionType char(1), @Quantity int', @ProductID =813, @TransactionType = 'S', @Quantity = 5
;

/* 21-10. Forcing Use of a Query Plan */

SET STATISTICS XML ON
SELECT TOP 10 Rate
FROM HumanResources.EmployeePayHistory
ORDER BY Rate DESC
SET STATISTICS XML OFF

--forcing a plan use
USE AdventureWorks2012;
GO 
SELECT TOP 10 Rate
FROM HumanResources.EmployeePayHistory
ORDER BY Rate DESC
OPTION (USE PLAN
'<ShowPlanXML xmlns="http://schemas.microsoft.com/sqlserver/2004/07/showplan" Version="1.2" Build="11.0.1750.32">
  <BatchSequence>
    <Batch>
      <Statements>
        <StmtSimple StatementText="SELECT TOP 10 Rate&#xD;&#xA;FROM HumanResources.EmployeePayHistory&#xD;&#xA;ORDER BY Rate DESC;&#xD;" StatementId="1" StatementCompId="2" StatementType="SELECT" RetrievedFromCache="true" StatementSubTreeCost="0.019825" StatementEstRows="10" StatementOptmLevel="TRIVIAL" QueryHash="0x2B741030C68225F9" QueryPlanHash="0x705E7CF258D9C17E">
          <StatementSetOptions QUOTED_IDENTIFIER="true" ARITHABORT="true" CONCAT_NULL_YIELDS_NULL="true" ANSI_NULLS="true" ANSI_PADDING="true" ANSI_WARNINGS="true" NUMERIC_ROUNDABORT="false" />
          <QueryPlan DegreeOfParallelism="1" MemoryGrant="1024" CachedPlanSize="16" CompileTime="1" CompileCPU="1" CompileMemory="96">
            <MemoryGrantInfo SerialRequiredMemory="16" SerialDesiredMemory="24" RequiredMemory="16" DesiredMemory="24" RequestedMemory="1024" GrantWaitTime="0" GrantedMemory="1024" MaxUsedMemory="16" />
            <OptimizerHardwareDependentProperties EstimatedAvailableMemoryGrant="104190" EstimatedPagesCached="52095" EstimatedAvailableDegreeOfParallelism="4" />
            <RelOp NodeId="0" PhysicalOp="Sort" LogicalOp="TopN Sort" EstimateRows="10" EstimateIO="0.0112613" EstimateCPU="0.00419345" AvgRowSize="15" EstimatedTotalSubtreeCost="0.019825" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
              <OutputList>
                <ColumnReference Database="[AdventureWorks2012]" Schema="[HumanResources]" Table="[EmployeePayHistory]" Column="Rate" />
              </OutputList>
              <MemoryFractions Input="1" Output="1" />
              <RunTimeInformation>
                <RunTimeCountersPerThread Thread="0" ActualRows="10" ActualRebinds="1" ActualRewinds="0" ActualEndOfScans="1" ActualExecutions="1" />
              </RunTimeInformation>
              <TopSort Distinct="0" Rows="10">
                <OrderBy>
                  <OrderByColumn Ascending="0">
                    <ColumnReference Database="[AdventureWorks2012]" Schema="[HumanResources]" Table="[EmployeePayHistory]" Column="Rate" />
                  </OrderByColumn>
                </OrderBy>
                <RelOp NodeId="1" PhysicalOp="Clustered Index Scan" LogicalOp="Clustered Index Scan" EstimateRows="316" EstimateIO="0.00386574" EstimateCPU="0.0005046" AvgRowSize="15" EstimatedTotalSubtreeCost="0.00437034" TableCardinality="316" Parallel="0" EstimateRebinds="0" EstimateRewinds="0" EstimatedExecutionMode="Row">
                  <OutputList>
                    <ColumnReference Database="[AdventureWorks2012]" Schema="[HumanResources]" Table="[EmployeePayHistory]" Column="Rate" />
                  </OutputList>
                  <RunTimeInformation>
                    <RunTimeCountersPerThread Thread="0" ActualRows="316" ActualEndOfScans="1" ActualExecutions="1" />
                  </RunTimeInformation>
                  <IndexScan Ordered="0" ForcedIndex="0" ForceScan="0" NoExpandHint="0">
                    <DefinedValues>
                      <DefinedValue>
                        <ColumnReference Database="[AdventureWorks2012]" Schema="[HumanResources]" Table="[EmployeePayHistory]" Column="Rate" />
                      </DefinedValue>
                    </DefinedValues>
                    <Object Database="[AdventureWorks2012]" Schema="[HumanResources]" Table="[EmployeePayHistory]" Index="[PK_EmployeePayHistory_BusinessEntityID_RateChangeDate]" IndexKind="Clustered" />
                  </IndexScan>
                </RelOp>
              </TopSort>
            </RelOp>
          </QueryPlan>
        </StmtSimple>
      </Statements>
    </Batch>
  </BatchSequence>
</ShowPlanXML>');

/* 21-11. Applying Hints Without Modifying a SQL Statement */

USE AdventureWorks2012;
GO
EXEC sp_executesql
N'SELECT v.Name ,a.City
FROM Purchasing.Vendor v
INNER JOIN [Person].BusinessEntityAddress bea
ON bea.BusinessEntityID = v.BusinessEntityID 
INNER JOIN Person.Address a
ON a.AddressID = bea.AddressID';

--create plan guide
USE AdventureWorks2012;
GO
EXEC sp_create_plan_guide
@name = N'Vendor_Query_Loop_to_Merge', 
@stmt = N'SELECT v.Name ,a.City FROM Purchasing.Vendor v INNER JOIN [Person].BusinessEntityAddress bea
ON bea.BusinessEntityID = v.BusinessEntityID INNER JOIN Person.Address a
ON a.AddressID = bea.AddressID',
@type = N'SQL', @module_or_batch = NULL, @params = NULL, @hints = N'OPTION (MERGE JOIN)';

--verify plan guide
USE AdventureWorks2012;
GO
SELECT name, is_disabled, scope_type_desc, hints 
FROM sys.plan_guides;

--drop plan guide
USE AdventureWorks2012;
GO
EXEC sp_control_plan_guide N'DROP', N'Vendor_Query_Loop_to_Merge';

/* 21-12. Creating Plan Guides from Cache */

USE AdventureWorks2012;
GO
SELECT
p.Title,
p.FirstName,
p.MiddleName,
p.LastName 
FROM HumanResources.Employee e 
INNER JOIN Person.Person p
ON p.BusinessEntityID = e.BusinessEntityID 
WHERE Title = 'Ms.';
GO

--retrieve plan handle
USE AdventureWorks2012;
GO
SELECT plan_handle 
FROM sys.dm_exec_query_stats qs 
CROSS APPLY sys.dm_exec_sql_text(plan_handle) t 
WHERE t.text LIKE 'SELECT%p.Title%' 
AND t.text LIKE '%Ms%';

--create plan guide from cache
EXEC sp_create_plan_guide_from_handle 'PlanGuide_EmployeeContact', 
@plan_handle = 0x06000600AEC426269009DAFC0200000001000000000000000000000000000000000000000000000000000000, 
@statement_start_offset = NULL;

--query plan guide
USE AdventureWorks2012;
GO
SELECT name, query_text, hints 
FROM sys.plan_guides;

/* 21-13. Checking the Validity of a Plan Guide */

USE AdventureWorks2012;
GO
SELECT pg.plan_guide_id, pg.name, v.msgnum,
v.severity, v.state, v.message 
FROM sys.plan_guides pg 
CROSS APPLY sys.fn_validate_plan_guide(pg.plan_guide_id) v;


/* 21-14. Parameterizing a Nonparameterized Query Using Plan Guides */

USE AdventureWorks2012;
GO
SELECT cp.objtype, st.text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
WHERE st.text LIKE 'SELECT BusinessEntityID%'
GO

DECLARE @sql  nvarchar(max) DECLARE @parms nvarchar(max)
EXEC sp_get_query_template
N'SELECT BusinessEntitylD FROM HumanResources.Employee WHERE NationallDNumber = 295847284',
@sql OUTPUT,
@parms OUTPUT

EXEC sp_create_plan_guide N'PG_Employee_Contact_Ouery', @sql,
N'TEMPLATE', NULL, @parms, N'OPTION(PARAMETERIZATION FORCED)';

--test the plan guide
USE AdventureWorks2012;
GO
SELECT BusinessEntityID
        FROM HumanResources.Employee
        WHERE NationalIDNumber = 509647174;
GO
SELECT BusinessEntityID
        FROM HumanResources.Employee
        WHERE NationalIDNumber = 245797967;
GO
SELECT BusinessEntityID
        FROM HumanResources.Employee
        WHERE NationalIDNumber = 295847284;
GO

--confirm plan guide use
USE AdventureWorks2012;
GO
SELECT usecounts,objtype,text 
FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
WHERE st.text LIKE '%SELECT BusinessEntityID%' AND objtype = 'Prepared';

/* 21-15. Limiting Competing Query Resource Consumption */

USE master;
GO
CREATE RESOURCE POOL priority_app_queries WITH ( MIN_CPU_PERCENT = 25,
MAX_CPU_PERCENT = 75,
MIN_MEMORY_PERCENT = 25,
MAX_MEMORY_PERCENT = 75);
GO

USE master;
GO
CREATE RESOURCE POOL ad_hoc_queries WITH ( MIN_CPU_PERCENT = 5,
MAX_CPU_PERCENT = 25,
MIN_MEMORY_PERCENT = 5,
MAX_MEMORY_PERCENT = 25);
GO

USE master;
GO
ALTER RESOURCE POOL ad_hoc_queries WITH ( MIN_MEMORY_PERCENT = 10, MAX_MEMORY_PERCENT = 50);
GO

--confirm settings
USE master;
GO
SELECT pool_id,name,min_cpu_percent,max_cpu_percent,
min_memory_percent,max_memory_percent 
FROM sys.resource_governor_resource_pools;
GO

--max memory change
USE master;
GO
CREATE WORKLOAD GROUP application_alpha WITH
( IMPORTANCE = HIGH,
REQUEST_MAX_MEMORY_GRANT_PERCENT = 75,
REQUEST_MAX_CPU_TIME_SEC = 75,
REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 120,
MAX_DOP = 8,
GROUP_MAX_REQUESTS = 8 ) USING priority_app_queries;
GO

--second resource pool
USE master;
GO
CREATE WORKLOAD GROUP application_beta WITH
( IMPORTANCE = LOW,
REQUEST_MAX_MEMORY_GRANT_PERCENT = 50,
REQUEST_MAX_CPU_TIME_SEC = 50,
REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 360,
MAX_DOP = 1,
GROUP_MAX_REQUESTS = 4 ) USING priority_app_queries;
GO

--alter workload group
USE master;
GO
ALTER WORKLOAD GROUP application_beta WITH ( IMPORTANCE = MEDIUM);
GO

--third workload group
USE master;
GO
CREATE WORKLOAD GROUP adhoc_users WITH
( IMPORTANCE = LOW,
REQUEST_MAX_MEMORY_GRANT_PERCENT = 100,
REQUEST_MAX_CPU_TIME_SEC = 120,
REQUEST_MEMORY_GRANT_TIMEOUT_SEC = 360,
MAX_DOP = 1,
GROUP_MAX_REQUESTS = 5 ) USING ad_hoc_queries;
GO

--confirm configs
USE master;
GO
SELECT name,
Importance impt,
request_max_memory_grant_percent max_m_g,
request_max_cpu_time_sec max_cpu_sec,
request_memory_grant_timeout_sec m_g_to,
max_dop,
group_max_requests max_req,
pool_id 
FROM sys.resource_governor_workload_groups;

--classifier function
USE master;
GO
CREATE FUNCTION dbo.RECIPES_classifier()
RETURNS sysname
WITH SCHEMABINDING
AS
BEGIN
DECLARE @resource_group_name sysname;
IF SUSER_SNAME() IN ('AppLoginl', 'AppLogin2') 
SET @resource_group_name = 'application_alpha';
IF SUSER_SNAME() IN ('AppLogin3', 'AppLogin4') 
SET @resource_group_name = 'application_beta';
IF HOST_NAME() IN ('Workstationl234', 'Workstation4235') 
SET @resource_group_name = 'adhoc_users';
-- If the resource group is still unassigned, use default 
IF @resource_group_name IS NULL 
SET @resource_group_name = 'default';
RETURN @resource_group_name;
END
GO

--assign classifier function
USE master;
GO
-- Assign the classifier function
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION = dbo.RECIPES_classifier)
GO

--enable configuration
USE master;
GO
ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

--validate settings
USE master;
GO
SELECT OBJECT_NAME(classifier_function_id,DB_ID('master')) Fn_Name,
is_enabled 
FROM sys.resource_governor_configuration;

--disable the settings
USE master;
GO
ALTER RESOURCE GOVERNOR DISABLE;
GO

--remove workload groups
USE master;
GO
DROP WORKLOAD GROUP application_alpha;
DROP WORKLOAD GROUP application_beta;
DROP WORKLOAD GROUP adhoc_users;
DROP RESOURCE POOL ad_hoc_queries;
DROP RESOURCE POOL priority_app_queries;

--drop classifier function
USE master;
GO
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION = NULL);
DROP FUNCTION dbo.RECIPES_classifier;
GO

