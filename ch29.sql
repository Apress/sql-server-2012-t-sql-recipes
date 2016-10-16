/* 29-1. Reporting SQL Server Assignable Permissions */

--first example
USE master;
GO

SELECT class_desc, permission_name, covering_permission_name, parent_class_desc, parent_covering_permission_name 
    FROM sys.fn_builtin_permissions(DEFAULT) 
    ORDER BY class_desc, permission_name; 
GO

--second example
USE master;
GO

SELECT permission_name, covering_permission_name, parent_class_desc 
    FROM sys.fn_builtin_permissions('schema') 
    ORDER BY permission_name;
GO

/* 29-2. Managing Server Permissions */

--first example
USE master;
GO
/*
-- Create recipe login if it doesn't exist 
*/
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Apollo') 
BEGIN
CREATE LOGIN [Apollo] 
    WITH PASSWORD=N'test!#l', DEFAULT_DATABASE=[AdventureWorks2012], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF 
END;

GRANT ALTER TRACE TO Apollo 
WITH GRANT OPTION;
GO

--second example
USE master;
GO
GRANT CREATE ANY DATABASE, VIEW ANY DATABASE TO [ROIS\Frederic];
GO

--third example
USE master;
GO
DENY SHUTDOWN TO [ROIS\Frederic];
GO

--fourth example
USE master;
GO
REVOKE ALTER TRACE FROM Apollo 
CASCADE;
GO

/* 29-3. Querying Server-Level Permissions */

USE master;
GO
CREATE LOGIN TestUser2
WITH PASSWORD = 'abcdelllllll!';
GO

USE master;
GO
DENY SHUTDOWN TO TestUser2;
GRANT CREATE ANY DATABASE TO TestUser2;
GO

USE master;
GO
SELECT p.class_desc, p.permission_name, p.state_desc 
    FROM sys.server_permissions p 
    INNER JOIN sys.server_principals s 
        ON p.grantee_principal_id = s.principal_id 
    WHERE s.name = 'TestUser2';
GO

/* 29-4. Managing Database Permissions */

--setup example
USE master;
GO
/*
-- Create DB for recipe if it doesn't exist
*/
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TestDB')
BEGIN
CREATE DATABASE TestDB 
END 
GO
/*
Create recipe login if it doesn't exist 
*/
IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = 'Phantom') 
BEGIN
CREATE LOGIN [Phantom] 
    WITH PASSWORD=N'test!#23', DEFAULT_DATABASE=[TestDB], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF 
END;
GO

USE TestDB;
GO
/*
-- Create db users if they don't already exist
*/
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Apollo')
BEGIN
CREATE USER Apollo FROM LOGIN Apollo 
END;
GO
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'Phantom') 
BEGIN
CREATE USER Phantom FROM LOGIN Phantom 
END;
GO

--first example
USE TestDB;
GO
GRANT ALTER ANY ASSEMBLY, ALTER ANY CERTIFICATE TO APOLLO;
GO

--second example
USE TestDB;
GO
DENY ALTER ANY DATABASE DDL TRIGGER TO Phantom;
GO

--third example
Use TestDB;
GO
REVOKE CONNECT FROM Phantom;
GO

/* 29-5. Querying Database Permissions */

--example setup
USE master;
GO
CREATE LOGIN TestUser WITH PASSWORD = 'abcdelllllll!'
USE AdventureWorks2012;
GO
CREATE USER TestUser FROM LOGIN TestUser;
GO

USE AdventureWorks2012;
GO
GRANT SELECT ON HumanResources.Department TO TestUser;
DENY SELECT ON Production.ProductPhoto TO TestUser;
GRANT EXEC ON HumanResources.uspUpdateEmployeeHireInfo TO TestUser;
GRANT CREATE ASSEMBLY TO TestUser;
GRANT SELECT ON Schema::Person TO TestUser;
DENY IMPERSONATE ON USER::dbo TO TestUser;
DENY SELECT ON HumanResources.Employee(BirthDate) TO TestUser;
GO

--query for permissions
USE AdventureWorks2012;
GO
SELECT principal_id
FROM sys.database_principals
WHERE name = 'TestUser';
GO

Use AdventureWorks2012;
GO
SELECT
    p.class_desc,
    p.permission_name,
    p.state_desc,
    ISNULL(o.type_desc,'') type_desc,
    CASE p.class_desc
    WHEN 'SCHEMA'
    THEN schema_name(major_id)
    WHEN 'OBJECT_OR_COLUMN'
    THEN CASE
        WHEN minor_id = 0
        THEN object_name(major_id)
        ELSE (SELECT
        object_name(object_id) + '.' + name
        FROM sys.columns
        WHERE object_id = p.major_id 
        AND column_id = p.minor_id) END
    ELSE '' END AS object_name
FROM sys.database_permissions p
LEFT OUTER JOIN sys.objects o 
    ON o.object_id = p.major_id
WHERE grantee_principal_id = 5; --your principal id may be different
GO

/* 29-6. Managing Schemas */

--first example
USE TestDB;
GO
CREATE SCHEMA Publishers AUTHORIZATION db_owner;
GO

Use TestDB;
GO
CREATE TABLE Publishers.ISBN (ISBN char(13) NOT NULL PRIMARY KEY, CreateDT datetime NOT NULL DEFAULT GETDATE());
GO

--second example
USE master
GO
CREATE LOGIN Florence
WITH PASSWORD=N'testl23',
DEFAULT_DATABASE=TestDB,
CHECK_EXPIRATION=OFF,
CHECK_POLICY=OFF;
GO

--create new user
USE TestDB;
GO
CREATE USER Florence FOR LOGIN Florence;
GO

USE TestDB;
GO
ALTER USER Florence WITH DEFAULT_SCHEMA=Publishers;
GO

Use TestDB;
GO
ALTER SCHEMA dbo TRANSFER Publishers.ISBN;
GO
DROP SCHEMA Publishers;
GO

/* 29-7. Managing Schema Permissions */

--first example
USE AdventureWorks2012;
GO
SELECT s.name SchemaName, d.name SchemaOwnerName
FROM sys.schemas s
INNER JOIN sys.database_principals d 
ON s.principal_id= d.principal_id 
ORDER BY s.name;
GO

Use AdventureWorks2012;
GO
GRANT TAKE OWNERSHIP ON SCHEMA ::Person TO TestUser;
GO

--second example
Use AdventureWorks2012;
GO
GRANT ALTER, EXECUTE, SELECT ON SCHEMA ::Production TO TestUser 
WITH GRANT OPTION;
GO

--third example
Use AdventureWorks2012;
GO
DENY INSERT, UPDATE, DELETE ON SCHEMA ::Production TO TestUser;
GO

--fourth example
Use AdventureWorks2012;
GO
REVOKE ALTER, SELECT ON SCHEMA ::Production TO TestUser CASCADE;
GO

/* 29-8. Managing Object Permissions */

--first example
USE AdventureWorks2012;
GO
GRANT DELETE, INSERT, SELECT, UPDATE ON HumanResources.Department TO TestUser;
GO

--second example
Use AdventureWorks2012;
GO
CREATE ROLE ReportViewers
GRANT EXECUTE, VIEW DEFINITION ON dbo.uspGetManagerEmployees TO ReportViewers;
GO

--third example
USE AdventureWorks2012;
GO
DENY ALTER ON HumanResources.Department TO TestUser;
GO

--fourth example
USE AdventureWorks2012;
GO
REVOKE INSERT, UPDATE, DELETE ON HumanResources.Department TO TestUser;
GO

/* 29-9. Determining Permissions to a Securable */

USE AdventureWorks2012;
GO
SELECT HAS_PERMS_BY_NAME ('AdventureWorks2012', 'DATABASE', 'ALTER');
GO

USE AdventureWorks2012;
GO
SELECT UpdateTable = CASE HAS_PERMS_BY_NAME ('Person.Address', 'OBJECT', 'UPDATE') WHEN 1 THEN 'Yes' ELSE 'No' END ,
SelectFromTable = CASE HAS_PERMS_BY_NAME ('Person.Address', 'OBJECT', 'SELECT') WHEN 1 THEN 'Yes' ELSE 'No' END;
GO

/* 29-10. Reporting Permissions by Securable Scope */

USE master;
GO
SELECT permission_name
FROM sys.fn_my_permissions(NULL, N'SERVER')
ORDER BY permission_name;
GO

--execute under apollo context
USE master;
GO
EXECUTE AS LOGIN = N'Apollo'
GO
SELECT permission_name
FROM sys.fn_my_permissions(NULL, N'SERVER')
ORDER BY permission_name;
GO
REVERT;
GO

--database scoped permissions
USE TestDB;
GO
EXECUTE AS USER = N'Apollo';
GO
SELECT permission_name
FROM sys.fn_my_permissions(N'TestDB', N'DATABASE')
ORDER BY permission_name;
GO
REVERT;
GO

--permissions for current connection - should be executed under the 'Apollo' context
USE AdventureWorks2012;
GO
SELECT subentity_name, permission_name
FROM sys.fn_my_permissions(N'Production.Culture', N'OBJECT')
ORDER BY permission_name, subentity_name;
GO

/* 29-11. Changing Securable Ownership */

--first example
Use AdventureWorks2012;
GO
ALTER AUTHORIZATION ON Schema::HumanResources TO TestUser;
GO

--second example
Use AdventureWorks2012;
GO
SELECT p.name OwnerName
FROM sys.endpoints e
INNER JOIN sys.server_principals p 
ON e.principal_id = p.principal_id 
WHERE e.name = 'ProductWebsite';
GO

Use AdventureWorks2012;
GO
ALTER AUTHORIZATION ON Endpoint::ProductWebSite TO TestUser;
GO

/* 29-12. Allowing Access to Non-SQL Server  */

USE master;
GO
CREATE CREDENTIAL AccountingGroup
WITH IDENTITY = N'ROIS\AccountUser',
SECRET = N'mypassword!';
GO


USE master;
GO
ALTER LOGIN Apollo
WITH CREDENTIAL = AccountingGroup;
GO

/* 29-13. Defining Audit Data Sources */

USE master;
GO
CREATE SERVER AUDIT LesROIS_Server_Audit TO FILE
( FILEPATH = 'C:\Apress\',
MAXSIZE = 500 MB,
MAX_ROLLOVER_FILES = 10,
RESERVE_DISK_SPACE = OFF) WITH ( QUEUE_DELAY = 1000,
ON_FAILURE = CONTINUE);
GO

--validate configs
USE master;
GO
SELECT audit_id,type_desc,on_failure_desc
    ,queue_delay,is_state_enabled 
FROM sys.server_audits;
GO

USE master;
GO
SELECT  name,
log_file_path,
log_file_name,
max_rollover_files,
max_file_size 
FROM sys.server_file_audits;
GO

--second example
USE master;
GO
CREATE SERVER AUDIT LesROIS_CC_Server_Audit TO FILE
     ( FILEPATH = 'C:\Apress\',
    MAXSIZE = 500 MB,
    MAX_ROLLOVER_FILES = 10,
    RESERVE_DISK_SPACE = OFF) WITH ( QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE)
WHERE database_name ='AdventureWorks2012' AND schema_name ='Sales' 
  AND object_name ='CreditCard' AND database_principal_name ='dbo';
GO

--confirm audit creation
USE master;
GO
SELECT  name,
log_file_path,
log_file_name,
max_rollover_files,
max_file_size,
predicate
FROM sys.server_file_audits;
GO

/* 29-14. Capturing SQL Instance–Scoped Events */

--first example
USE master;
GO
SELECT name
FROM sys.dm_audit_actions
WHERE class_desc = 'SERVER' 
AND configuration_level = 'Group' 
ORDER BY name;
GO

--second example
USE master;
GO
CREATE SERVER AUDIT SPECIFICATION LesROIS_Server_Audit_Spec FOR SERVER AUDIT LesROIS_Server_Audit
ADD (SERVER_ROLE_MEMBER_CHANGE_GROUP),
ADD (DBCC_GROUP),
ADD (BACKUP_RESTORE_GROUP) WITH (STATE = ON);
GO

--validate settings
USE master;
GO
SELECT server_specification_id,name,is_state_enabled 
FROM sys.server_audit_specifications;
GO

USE master;
GO
SELECT server_specification_id,audit_action_name 
FROM sys.server_audit_specification_details 
WHERE server_specification_id = 65536;
GO

/* 29-15. Capturing Database-Scoped Events */

USE master;
GO
SELECT name
FROM sys.dm_audit_actions
WHERE configuration_level = 'Action' 
AND class_desc = 'OBJECT' 
ORDER BY name;
GO

USE master;
GO
SELECT name
FROM sys.dm_audit_actions
WHERE configuration_level = 'Group' 
AND class_desc = 'DATABASE' 
ORDER BY name;
GO

USE AdventureWorks2012;
GO
CREATE DATABASE AUDIT SPECIFICATION AdventureWorks2012_DB_Spec 
    FOR SERVER AUDIT LesROIS_Server_Audit 
    ADD (DATABASE_PRINCIPAL_IMPERSONATION_GROUP)
    , ADD (INSERT, UPDATE, DELETE ON Sales.CreditCard BY public) 
WITH (STATE = ON);
GO

--validate settings
USE AdventureWorks2012;
GO
SELECT database_specification_id,name,is_state_enabled 
FROM sys.database_audit_specifications;
GO

--detailed look
USE AdventureWorks2012;
GO
SELECT audit_action_name, class_desc, is_group
,ObjectNM = CASE
    WHEN major_id > 0 THEN OBJECT_NAME(major_id, DB_ID()) ELSE 'N/A' END  
FROM sys.database_audit_specification_details 
WHERE database_specification_id = 65536;
GO

/* 29-16. Querying Captured Audit Data */

USE master;
GO
ALTER SERVER AUDIT [LesROIS_Server_Audit] WITH (STATE = ON);
GO

--perform some actions covered by the audit
USE master;
GO
/*
-- Create new login (not auditing this, but using it for recipe) 
*/
CREATE LOGIN TestAudit WITH PASSWORD = 'C83D7F50-9B9E';
GO
/*
-- Add to server role bulkadmin
*/
EXECUTE sp_addsrvrolemember 'TestAudit', 'bulkadmin';
GO
/*
-- Back up AdventureWorks2012 database 
*/
BACKUP DATABASE AdventureWorks2012 TO DISK = 'C:\Apress\Example_AW.BAK';
GO
/*
-- Perform a DBCC on AdventureWorks2012 
*/
DBCC CHECKDB('AdventureWorks2012');
GO
/*
-- Perform some AdventureWorks2012 actions
*/
USE AdventureWorks2012
GO
/*
-- Create a new user and then execute under that
-- user's context
*/
CREATE USER TestAudit FROM LOGIN TestAudit
EXECUTE AS USER = 'TestAudit'
/*
-- Revert back to me (in this case a login with sysadmin perms) 
*/
REVERT;
GO
/*
-- Perform an INSERT, UPDATE, and DELETE -- from Sales.CreditCard
*/
INSERT Into Sales.CreditCard (CardType, CardNumber,ExpMonth,ExpYear,ModifiedDate)
    VALUES('Vista', '8675309153332145',11,2003,GetDate());

UPDATE Sales.CreditCard SET CardType = 'Colonial'
    WHERE CardNumber = '8675309153332145';
DELETE Sales.CreditCard 
    WHERE CardNumber = '8675309153332145';
GO

--investigate
USE master;
GO
SELECT af.event_time, af.succeeded,
af.target_server_principal_name, object_name 
FROM fn_get_audit_file('C:\Apress\LesROIS_Server_Audit_*', default, default) af 
INNER JOIN sys.dm_audit_actions aa 
    ON af.action_id = aa.action_id 
WHERE aa.name = 'ADD MEMBER' 
    AND aa.class_desc = 'SERVER ROLE';
GO

--second example
USE master;
GO
SELECT af.event_time,
af.database_principal_name 
FROM fn_get_audit_file('C:\Apress\LesROIS_Server_Audit_*', default, default) af 
INNER JOIN sys.dm_audit_actions aa 
    ON af.action_id = aa.action_id 
WHERE aa.name = 'DELETE' 
    AND aa.class_desc = 'OBJECT' 
    AND af.schema_name = 'Sales' 
    AND af.object_name = 'CreditCard';
GO

--investigate
USE master;
GO
SELECT event_time, statement 
FROM fn_get_audit_file('C:\Apress\LesROIS_Server_Audit_*', default, default) af 
INNER JOIN sys.dm_audit_actions aa 
    ON af.action_id = aa.action_id 
WHERE aa.name = 'BACKUP' 
    AND aa.class_desc = 'DATABASE';
GO

--query distinct events
USE master;
GO
SELECT DISTINCT
aa.name,
database_principal_name,
target_server_principal_name,
object_name 
FROM fn_get_audit_file('C:\Apress\LesROIS_Server_Audit_*', default, default) af 
INNER JOIN sys.dm_audit_actions aa 
    ON af.action_id = aa.action_id;
GO

/* 29-17. Managing, Modifying, and Removing Audit Objects */

USE master;
GO
ALTER SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec] WITH (STATE = OFF);
GO

--drop one of the audit actions
USE master;
GO
ALTER SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec] 
DROP (BACKUP_RESTORE_GROUP);
GO

--add audit action
USE master;
GO
ALTER SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec] 
ADD (LOGIN_CHANGE_PASSWORD_GROUP);
GO

--reenable server audit
USE master;
GO
ALTER SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec] 
WITH (STATE = ON);
GO

--modify database audit actions
USE AdventureWorks2012;
GO
ALTER DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec] 
WITH (STATE = OFF);
GO

--remove database audit action
USE AdventureWorks2012;
GO
ALTER DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec] 
DROP (INSERT ON [HumanResources].[Department] BY public);
GO

--add database audit action
USE AdventureWorks2012;
GO
ALTER DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec] 
ADD (DATABASE_ROLE_MEMBER_CHANGE_GROUP);
GO

--reenable database audit specification
USE AdventureWorks2012;
GO
ALTER DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec] 
WITH (STATE = ON);
GO

--modify server audit object
USE master;
GO
ALTER SERVER AUDIT [LesROIS_Server_Audit] WITH (STATE = OFF);
ALTER SERVER AUDIT [LesROIS_Server_Audit] TO APPLICATION_LOG;
ALTER SERVER AUDIT [LesROIS_Server_Audit] WITH (STATE = ON);

--remove database audit specification
Use AdventureWorks2012;
GO
ALTER DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec] WITH (STATE = OFF);
DROP DATABASE AUDIT SPECIFICATION [AdventureWorks2012_DB_Spec];
GO

--remove server audit specification
USE master;
GO
ALTER SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec] WITH (STATE = OFF);
DROP SERVER AUDIT SPECIFICATION [LesROIS_Server_Audit_Spec];
GO

--drop server audit object
USE master;
GO
ALTER SERVER AUDIT [LesROIS_Server_Audit] WITH (STATE = OFF);
DROP SERVER AUDIT [LesROIS_Server_Audit];
GO

