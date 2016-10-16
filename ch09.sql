-- 9.1 Concatenating Multiple Strings
SELECT TOP 5
        FullName = CONCAT(LastName, ', ', FirstName, ' ', MiddleName)
FROM    Person.Person p ; 

SELECT TOP 5 
        FullName = CONCAT(LastName, ', ', FirstName, ' ', MiddleName),
		FullName2 = LastName + ', ' + FirstName + ' ' + MiddleName,
		FullName3 = LastName + ', ' + FirstName + 
				IIF(MiddleName IS NULL, '', ' ' + MiddleName)
FROM Person.Person p 
WHERE MiddleName IS NULL ;

-- 9.2 Finding a Character’s ASCII Value
SELECT  ASCII('H'),
        ASCII('e'),
        ASCII('l'),
        ASCII('l'),
        ASCII('o') ;

SELECT  CHAR(72),
        CHAR(101),
        CHAR(108),
        CHAR(108),
        CHAR(111) ;

-- 9.3 Returning Integer and Character Unicode Values
SELECT  UNICODE('G'),
        UNICODE('o'),
        UNICODE('o'),
        UNICODE('d'),
        UNICODE('!') ;

SELECT  NCHAR(71),
        NCHAR(111),
        NCHAR(111),
        NCHAR(100),
        NCHAR(33) ;

-- 9.4 Locating a Substring 
SELECT CHARINDEX('string to find','This is the bigger string to find something in.');

SELECT TOP 10
        AddressID,
        AddressLine1,
        PATINDEX('%[0]%Olive%', AddressLine1)
FROM    Person.Address
WHERE   PATINDEX('%[0]%Olive%', AddressLine1) > 0 ;


-- 9.5 Determining the Similarity of Strings
SELECT  DISTINCT 
SOUNDEX(LastName),
        SOUNDEX('Smith'),
        LastName
FROM    Person.Person
WHERE   SOUNDEX(LastName) = SOUNDEX('Smith') ;

SELECT  DISTINCT
        SOUNDEX(LastName),
        SOUNDEX('smith'),
        DIFFERENCE(LastName, 'Smith'),
        LastName
FROM    Person.Person
WHERE   DIFFERENCE(LastName, 'Smith') = 4 ;

-- 9.6 
SELECT LEFT('I only want the leftmost 10 characters.', 10) ;

SELECT RIGHT('I only want the rightmost 10 characters.', 10) ;

SELECT TOP 5
        ProductNumber,
        ProductName = LEFT(Name, 10)
FROM    Production.Product ;

SELECT TOP 5
        CustomerID,
        AccountNumber = CONCAT('AW', RIGHT(REPLICATE('0', 8)
                                     + CAST(CustomerID AS VARCHAR(10)), 8))
FROM    Sales.Customer ;


-- 9.6 Returning Part of a String


SELECT TOP 3
        PhoneNumber,
        AreaCode = LEFT(PhoneNumber, 3),
        Exchange = SUBSTRING(PhoneNumber, 5, 3)
FROM    Person.PersonPhone
WHERE   PhoneNumber LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' ;


-- 9.7 Counting Characters or Bytes in a String 

SELECT LEN(N'She sells sea shells by the sea shore.  ') ;

SELECT DATALENGTH(N'She sells sea shells by the sea shore.  ') ; 

-- 9.8 Replacing Part of a String
SELECT REPLACE('The Classic Roadie is a stunning example of the bikes that AdventureWorks have been producing for years – Order your classic Roadie today and experience AdventureWorks history.', 'Classic', 'Vintage');

-- 9.9 Stuffing a String into a String

SELECT STUFF ( 'My cat''s name is X. Have you met him?', 18, 1, 'Edgar' );

-- 9.10 Changing Between Lower- and Uppercase
SELECT  DocumentSummary
FROM    Production.Document
WHERE   FileName = 'Installing Replacement Pedals.doc';

SELECT  LOWER(DocumentSummary)
FROM    Production.Document
WHERE   FileName = 'Installing Replacement Pedals.doc';

SELECT  UPPER(DocumentSummary)
FROM    Production.Document
WHERE   FileName = 'Installing Replacement Pedals.doc';

-- 9.11 Removing Leading and Trailing Blanks
SELECT CONCAT('''', LTRIM('     String with leading and trailing blanks.     '), '''' ); 
SELECT CONCAT('''', RTRIM('     String with leading and trailing blanks.     '), '''' ); 
SELECT CONCAT('''', LTRIM(RTRIM('   String with leading and trailing blanks    ')), '''' );

-- 9.12 Repeating an Expression N Times
SELECT REPLICATE ('W', 30) ;
SELECT REPLICATE ('W_', 30) ;

-- 9.13 Repeating a Blank Space N Times
DECLARE @string1 NVARCHAR(20) = 'elephant',
        @string2 NVARCHAR(20) = 'dog',
        @string3 NVARCHAR(20) = 'giraffe' ;

SELECT  *
FROM    ( VALUES
        ( CONCAT(@string1, SPACE(20 - LEN(@string1)), @string2,
                 SPACE(20 - LEN(@string2)), @string3,
                 SPACE(20 - LEN(@string3))))
	,
        ( CONCAT(@string2, SPACE(20 - LEN(@string2)), @string3,
                 SPACE(20 - LEN(@string3)), @string1,
                 SPACE(20 - LEN(@string1)))) ) AS a (formatted_string) ;


-- 9.14 Reversing the order of Characters in a String
SELECT  Path = LEFT(filename, LEN(filename) - CHARINDEX('\', REVERSE(filename)) + 1),
        FileName = RIGHT(filename, CHARINDEX('\', REVERSE(filename)) - 1)
FROM    sys.sysfiles ;


