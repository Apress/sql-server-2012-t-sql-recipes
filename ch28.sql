/* 28-1. Creating a Windows Login */

--first example
USE master;
GO
CREATE LOGIN [ROIS\Frederic]
FROM WINDOWS
WITH DEFAULT_DATABASE = AdventureWorks2012,
DEFAULT_LANGUAGE = English;
GO

--second example
USE master;
GO
CREATE LOGIN [ROIS\DuMonde]
FROM WINDOWS
WITH DEFAULT_DATABASE= AdventureWorks2012;
GO

/* 28-2. Viewing Windows Logins */

USE master;
GO
SELECT name, sid
FROM sys.server_principals
WHERE type_desc IN ('WINDOWS_LOGIN', 'WINDOWS_GROUP')
ORDER BY type_desc;
GO

/* 28-3. Altering a Windows Login */

--first example
USE master;
GO
ALTER LOGIN [ROIS\Frederic] DISABLE;
GO

--second example
USE master;
GO
ALTER LOGIN [ROIS\Frederic] ENABLE;
GO

--third example
USE master;
GO
ALTER LOGIN [ROIS\DuMonde] 
    WITH DEFAULT_DATABASE = master;
GO

/* 28-4. Dropping a Windows Login */

USE master;
GO
-- Windows Group login
DROP LOGIN [ROIS\DuMonde];
-- Windows user login 
DROP LOGIN [ROIS\Frederic];
GO

/* 28-5. Denying SQL Server Access to a Windows User or Group */

USE master;
GO
DENY CONNECT SQL TO [ROIS\Francois];
GO

USE master;
GO
GRANT CONNECT SQL TO [ROIS\Francois];
GO

/* 28-6. Creating a SQL Server Login */

USE master;
GO
CREATE LOGIN Pipo
WITH PASSWORD = 'BigTr3e',
DEFAULT_DATABASE = AdventureWorks2012;
GO

USE master;
GO
CREATE LOGIN Marcus 
WITH PASSWORD = 'ChangeMe' MUST_CHANGE
, CHECK_EXPIRATION = ON
, CHECK_POLICY = ON;
GO

/* 28-7. Viewing SQL Server Logins */

USE master;
GO
SELECT name, sid 
FROM sys.server_principals 
WHERE type_desc IN ('SQL_LOGIN') 
ORDER BY name;
GO

/* 28-8. Altering a SQL Server Login */

--first example
USE master;
GO
ALTER LOGIN Pipo
WITH PASSWORD = 'TwigSlayer'
OLD_PASSWORD = 'BigTr3e';
GO

--second example
USE master;
GO
ALTER LOGIN Pipo
WITH DEFAULT_DATABASE = [AdventureWorks2012];
GO

--third example
USE master;
GO
ALTER LOGIN Pipo 
WITH NAME = Patmos, PASSWORD = 'AN!celIttul@isl3';
GO

/* 28-9. Managing a Login’s Password */

USE master;
GO
SELECT p.name, ca.IsLocked, ca.IsExpired, ca.IsMustChange, ca.BadPasswordCount, ca.BadPasswordTime, ca.HistoryLength, ca.LockoutTime,ca.PasswordLastSetTime,ca.DaysUntilExpiration
    From sys.server_principals p
        CROSS APPLY (SELECT  IsLocked = LOGINPROPERTY(p.name,  'IsLocked') ,
        IsExpired = LOGINPROPERTY(p.name,  'IsExpired') ,
        IsMustChange = LOGINPROPERTY(p.name,  'IsMustChange') ,
        BadPasswordCount = LOGINPROPERTY(p.name,  'BadPasswordCount') ,
        BadPasswordTime = LOGINPROPERTY(p.name,  'BadPasswordTime') ,
        HistoryLength = LOGINPROPERTY(p.name,  'HistoryLength') ,
        LockoutTime = LOGINPROPERTY(p.name,  'LockoutTime') ,
        PasswordLastSetTime = LOGINPROPERTY(p.name,  'PasswordLastSetTime') ,
        DaysUntilExpiration = LOGINPROPERTY(p.name,  'DaysUntilExpiration') 
    ) ca
    WHERE p.type_desc = 'SQL_LOGIN'
        AND p.is_disabled = 0;
GO

USE master;
GO
SELECT p.name,ca.DefaultDatabase,ca.DefaultLanguage,ca.PasswordHash
    ,PasswordHashAlgorithm = Case ca.PasswordHashAlgorithm 
        WHEN 1
        THEN 'SQL7.0'
        WHEN 2
        THEN 'SHA-1'
        WHEN 3
        THEN 'SHA-2'
        ELSE 'login is not a valid SQL Server login'
        END
    FROM sys.server_principals p
    CROSS APPLY (SELECT  PasswordHash = LOGINPROPERTY(p.name,  'PasswordHash') ,
        DefaultDatabase = LOGINPROPERTY(p.name,  'DefaultDatabase') ,
        DefaultLanguage = LOGINPROPERTY(p.name,  'DefaultLanguage') ,
        PasswordHashAlgorithm = LOGINPROPERTY(p.name,  'PasswordHashAlgorithm')
    ) ca
    WHERE p.type_desc = 'SQL_LOGIN'
        AND p.is_disabled = 0;
GO

/* 28-10. Dropping a SQL Login */

USE master;
GO
DROP LOGIN Patmos;
GO

/* 28-11. Managing Server Role Members */

--first example
USE master;
GO
CREATE LOGIN Apollo WITH PASSWORD = 'De3pd@rkCave';
GO
ALTER SERVER ROLE diskadmin
    ADD MEMBER [Apollo];
GO

--second example
USE master;
GO
ALTER SERVER ROLE diskadmin
    DROP MEMBER [Apollo];
GO

/* 28-12. Reporting Fixed Server Role Information */

USE master;
GO
SELECT name
FROM sys.server_principals
WHERE type_desc = 'SERVER_ROLE';
GO

USE master;
GO
EXECUTE sp_helpsrvrole;
GO

EXECUTE sp_helpsrvrolemember 'sysadmin'

USE master;
GO
SELECT SUSER_NAME(SR.role_principal_id) AS ServerRole
        , SUSER_NAME(SR.member_principal_id) AS PrincipalName
        , SP.sid
    FROM sys.server_role_members SR
    INNER JOIN sys.server_principals SP
        ON SR.member_principal_id = SP.principal_id
    WHERE SUSER_NAME(SR.role_principal_id) = 'sysadmin';
GO

/* 28-13. Creating Database Users */

--first example
USE master;
GO
IF NOT EXISTS (SELECT name FROM sys.databases
    WHERE name = 'TestDB')
BEGIN
    CREATE DATABASE TestDB
END 
GO
USE TestDB;
GO
CREATE USER Apollo;
GO

--second example
USE TestDB;
GO
CREATE USER Helen
FOR LOGIN [ROIS\Helen]
WITH DEFAULT_SCHEMA = HumanResources;
GO

/* 28-14. Reporting Database User Information */

USE TestDB;
GO
EXECUTE sp_helpuser 'Apollo';
GO

/* 28-15. Modifying a Database User */

--first example
USE TestDB;
GO
ALTER USER Apollo
WITH DEFAULT_SCHEMA = Production;
GO

--second example
USE [master]
GO
CREATE LOGIN [ROIS\SQLTest] FROM WINDOWS 
WITH DEFAULT_DATABASE=[TestDB];
GO
USE [TestDB]
GO
CREATE USER [ROIS\SQLTest] 
FOR LOGIN [ROIS\SQLTest];
GO
ALTER USER [ROIS\SQLTest]
WITH DEFAULT_SCHEMA = Production;
GO

--third example
USE TestDB;
GO
ALTER USER Apollo 
WITH NAME = Phoebus;
GO

/* 28-16. Removing a Database User from the Database */

USE TestDB;
GO
DROP USER Phoebus;
GO

/* 28-17. Fixing Orphaned Database Users */

USE AdventureWorks2012;
GO
If not exists (select name from sys.server_principals
            where name ='Apollo')
Begin
CREATE LOGIN Apollo
WITH PASSWORD = 'BigTr3e',
DEFAULT_DATABASE = AdventureWorks2012;
End
GO
If not exists (select name from sys.database_principals
            where name = 'Apollo')
Begin
CREATE USER Apollo;
END
DROP LOGIN [APOLLO];
CREATE LOGIN Apollo
WITH PASSWORD = 'BigTr3e',
DEFAULT_DATABASE = AdventureWorks2012;
GO

--show association
USE AdventureWorks2012;
GO
SELECT dp.name AS OrphanUser, dp.sid AS OrphanSid
FROM sys.database_principals dp
LEFT OUTER JOIN sys.server_principals sp 
    ON dp.sid = sp.sid 
WHERE sp.sid IS NULL 
    AND dp.type_desc = 'SQL_USER' 
    AND dp.principal_id > 4;
GO

--remap orphaned user
USE TestDB;
GO
ALTER USER Apollo WITH LOGIN = Apollo;
GO

--map database user to login
USE TestDB;
GO
ALTER USER [Phoebus]
WITH LOGIN = [ROIS\Phoebus];
GO

/* 28-18. Reporting Fixed Database Roles Information */

USE TestDB;
GO
EXECUTE sp_helpdbfixedrole;
GO

USE TestDB;
GO
EXECUTE sp_helprolemember;
GO

/* 28-19. Managing Fixed Database Role Membership */

--first example
USE TestDB
GO
If not exists (select name from sys.database_principals
        where name = 'Apollo')
Begin
CREATE LOGIN Apollo
WITH PASSWORD = 'BigTr3e',
DEFAULT_DATABASE = TestDB;
CREATE USER Apollo;
END
GO
ALTER ROLE db_datawriter
    ADD MEMBER [APOLLO];
ALTER ROLE db_datareader
    ADD MEMBER [APOLLO];
GO

--second example
USE TestDB;
GO
ALTER ROLE db_datawriter
    DROP MEMBER [APOLLO];
GO

/* 28-20. Managing User-Defined Database Roles */

--list all roles
USE TestDB;
GO
EXECUTE sp_helprole;
GO

--create role
USE AdventureWorks2012;
GO
CREATE ROLE HR_ReportSpecialist AUTHORIZATION db_owner;
GO

--grant permissions
Use AdventureWorks2012;
GO
GRANT SELECT ON HumanResources.Employee TO HR_ReportSpecialist;
GO

--add principal to role
Use AdventureWorks2012;
GO
If not exists (select name from sys.server_principals
				where name ='Apollo')
Begin
CREATE LOGIN Apollo
WITH PASSWORD = 'BigTr3e',
DEFAULT_DATABASE = AdventureWorks2012;
End
GO
If not exists (select name from sys.database_principals
				where name = 'Apollo')
Begin
CREATE USER Apollo;
END
GO
EXECUTE sp_addrolemember 'HR_ReportSpecialist', 'Apollo';
GO

--change role
Use AdventureWorks2012;
GO
ALTER ROLE HR_ReportSpecialist WITH NAME = HumanResources_RS;
GO

--drop role
Use AdventureWorks2012;
GO
DROP ROLE HumanResources_RS;
GO

--drop role and its members
Use AdventureWorks2012;
GO
EXECUTE sp_droprolemember 'HumanResources_RS', 'Apollo';
GO
DROP ROLE HumanResources_RS;
GO

/* 28-21. Managing Application Roles */

--first example
USE AdventureWorks2012;
GO
CREATE APPLICATION ROLE DataWareHouseApp 
WITH PASSWORD = 'mywarehousel23!', DEFAULT_SCHEMA = dbo;
GO

--grant permissions
Use AdventureWorks2012;
GO
GRANT SELECT ON Sales.vSalesPersonSalesByFiscalYears
TO DataWareHouseApp;
GO

--enable permissions
Use AdventureWorks2012;
GO
EXECUTE sp_setapprole 'DataWareHouseApp', -- App role name 
    'mywarehousel23!' -- Password
	;
GO
-- This query Works
SELECT COUNT(*)
FROM Sales.vSalesPersonSalesByFiscalYears;
-- This query Doesn't work 
SELECT COUNT(*) FROM HumanResources.vJobCandidate;
GO

--second example
Use AdventureWorks2012;
GO
ALTER APPLICATION ROLE DataWareHouseApp
WITH NAME = DW_App, PASSWORD = 'newsecret!123';
GO

Use AdventureWorks2012;
GO
DROP APPLICATION ROLE DW_App;
GO

