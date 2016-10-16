--Batch directive
USE master;

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'Errors')
BEGIN
DROP DATABASE Errors;
CREATE DATABASE Errors;
END;
ELSE CREATE DATABASE Errors;

USE Errors;

CREATE TABLE Works(
number	INT);

INSERT Works
VALUES(1), 
	  ('A'),
	  (3);

SELECT *
FROM Works;

USE master;

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'Errors')
BEGIN
DROP DATABASE Errors;
CREATE DATABASE Errors;
END;
ELSE CREATE DATABASE Errors;
GO

USE Errors;

CREATE TABLE Works(
number	INT);
GO

INSERT Works
VALUES(1), 
	  ('A'),
	  (3);
GO

INSERT Works
VALUES(1), 
	  (2),
	  (3);
GO

SELECT *
FROM Works;

GO SELECT *
FROM Works;
GO

--Select all error messages from an instance of SQL 
SELECT *
FROM sys.messages
WHERE language_id = 1033;
GO

--Structured error handling
BEGIN TRY
SELECT 1/0 --This will raise a divide by zero error if not handled
END TRY
BEGIN CATCH
END CATCH;
GO

BEGIN TRY
  SELECT 1/0 --This will raise a divide by zero error if not handled
END TRY
BEGIN CATCH
  SELECT ERROR_LINE() AS 'Line',
		 ERROR_MESSAGE() AS 'Message',
		 ERROR_NUMBER() AS 'Number',
		 ERROR_PROCEDURE() AS 'Procedure',
		 ERROR_SEVERITY() AS 'Severity',
		 ERROR_STATE() AS 'State'
END CATCH;
GO

BEGIN TRY
  SELCT
END TRY
BEGIN CATCH
END CATCH;
GO

BEGIN TRY
  SELECT NoSuchTable
END TRY
BEGIN CATCH
END CATCH;
GO

BEGIN TRY
  RAISERROR('Information ONLY', 10, 1)
END TRY
BEGIN CATCH
END CATCH;
GO



BEGIN TRY
   SELECT 1/0
END TRY
BEGIN CATCH
    PRINT 'In catch block.';
    THROW;
END CATCH;

BEGIN TRY
   SELECT 1/0
END TRY
BEGIN CATCH
	IF (SELECT @@ERROR) = 8134
	BEGIN;
	THROW 51000, 'Divide by zero error occurred', 10;
	END 
	ELSE
	THROW 5000, 'Unknown error occurred', 10;
END CATCH;

BEGIN TRY
  SELECT 1/0 --This will raise a divide by zero error if not handled
	BEGIN TRY
	 	PRINT 'INNER TRY'
	END TRY
    	BEGIN CATCH
		PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch' 
   	END CATCH
END TRY
BEGIN CATCH 
  PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch' 
END CATCH;	
GO

BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	SELECT 1/0 --This will raise a divide by zero error if not handled
	END TRY
    BEGIN CATCH
		PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch' 
   	END CATCH
END TRY
BEGIN CATCH 
  PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch' 
END CATCH;	
GO

BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	SELECT 1/0 --This will raise a divide by zero error if not handled
	END TRY
    BEGIN CATCH
		PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch' 
   	END CATCH
END TRY
BEGIN CATCH 
  PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch' 
END CATCH;	
GO

BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	PRINT ERROR_NUMBER() + ' Inner try'
	END TRY
    BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'INITIAL Catch';
		 --THROW
		END
END CATCH
	PRINT 'Inner try'
END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'OUTER Catch';
		 THROW
		END
	END CATCH

 
BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	PRINT ERROR_NUMBER() + ' Inner try'
	END TRY
    BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'INITIAL Catch';
		 THROW
		END
END CATCH
	PRINT 'Inner try'
END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'OUTER Catch';
		 THROW
		END
	END CATCH

  BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	PRINT ERROR_NUMBER() + ' Inner try'
	END TRY
    BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' ' + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'INITIAL Catch';
		 THROW --This THROW is added in the initial CATCH
		END
END CATCH
END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' '  +
              CONVERT(CHAR(2), ERROR_STATE()) + 'OUTER Catch';
		 THROW
		END
	END CATCH

 RAISERROR ('User defined error', -- Message text.
               16, -- Severity.
               1 -- State.
               );

USE tempdb;

IF EXISTS(SELECT * FROM sys.tables WHERE name = 'Creditor')
BEGIN
DROP TABLE Creditor;
CREATE TABLE Creditor(
CreditorID		INT IDENTITY PRIMARY KEY,
CreditorName	VARCHAR(50)
);
END
ELSE 
CREATE TABLE Creditor(
CreditorID		INT IDENTITY PRIMARY KEY,
CreditorName	VARCHAR(50)
);
GO

INSERT Creditor
VALUES('You Owe Me'), 
	  ('You Owe Me More');
GO

SELECT *
FROM Creditor;
GO

CREATE TRIGGER Deny_Delete
ON Creditor
FOR DELETE
AS
RAISERROR('Deletions are not permitted',
		   16,
		   1)
		   ROLLBACK TRAN;
GO

DELETE Creditor
WHERE CreditorID = 1;
GO

SELECT *
FROM Creditor;
GO

--THROW
THROW 50000, 'User defined error', 1;

  BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	PRINT ERROR_NUMBER() + ' Inner try'
	END TRY
    BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' ' + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'INITIAL Catch';
		 RAISERROR --This THROW is added in the initial CATCH
		END
END CATCH
END TRY
	BEGIN CATCH
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' '  +
              CONVERT(CHAR(2), ERROR_STATE()) + 'OUTER Catch';
		 RAISERROR
		END
	END CATCH

BEGIN TRY
  PRINT 'Outer Try'
	BEGIN TRY
	 	PRINT ERROR_NUMBER() + ' Inner try'
	END TRY
    BEGIN CATCH
	DECLARE @error_message AS VARCHAR(500) = ERROR_MESSAGE()
	DECLARE @error_severity AS INT = ERROR_SEVERITY()
	DECLARE @error_state AS INT = ERROR_STATE()
		IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Inner Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' ' + 
              CONVERT(CHAR(2), ERROR_STATE()) + 'INITIAL Catch';
			  
		 RAISERROR (@error_message,
					@error_severity,
					@error_state);
		END
END CATCH
END TRY
	BEGIN CATCH
	IF ERROR_NUMBER() = 8134
		   PRINT CONVERT(CHAR(5), ERROR_NUMBER()) + 'Outer Catch Divide by zero' 
		ELSE 
		   BEGIN;
   PRINT CONVERT(CHAR(6), ERROR_NUMBER()) + ' ' + ERROR_MESSAGE() +
              CONVERT(CHAR(2), ERROR_SEVERITY()) + ' '  +
              CONVERT(CHAR(2), ERROR_STATE()) + 'OUTER Catch';
		 RAISERROR(@error_message,
					@error_severity,
					@error_state);
		END
	END CATCH

USE master
GO
EXEC sp_addmessage 50001, 16, 
   N'This is a user defined error that can be corrected by the user';
GO

SELECT message_id,	
	   text
FROM sys.messages
WHERE message_id = 50001;
GO

RAISERROR (50001,
		  16,
		  1);
GO

USE master
GO
sp_addmessage @msgnum = 50002 , 
			  @severity = 16 , 
			  @msgtext = 'User error that IS logged', 
			  @with_log = 'TRUE';
GO 

RAISERROR(50002,
		  16,
		  1);
GO

USE master
GO
EXEC sp_dropmessage 50001;
GO  

SELECT message_id,	
	 text
FROM sys.messages
WHERE message_id = 50001;
GO 

RAISERROR(50001,
		  16,
		  1);
GO

