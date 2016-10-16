1.1. Connecting to a Database

USE AdventureWorks2008R2;


1.2. Retrieving Specific Columns

SELECT  NationalIDNumber,
        LoginID,
        JobTitle
FROM    HumanResources.Employee;


1.3. Retrieving All Columns

SELECT  *
FROM    HumanResources.Employee;


1.4. Specifying Rows to Be Returned

SELECT  Title,
        FirstName,
        LastName
FROM    Person.Person
WHERE   Title = 'Ms.';

SELECT  Title, 
        FirstName, 
        LastName
FROM  Person.Person 
WHERE Title = 'Ms.' AND 
        LastName = 'Antrim';


1.5. Renaming the Output Columns

SELECT  BusinessEntityID AS "Employee ID",
        VacationHours AS "Vacation",
        SickLeaveHours AS "Sick Time"
FROM    HumanResources.Employee; 


1.6. Building a Column from an Expression

SELECT  BusinessEntityID AS EmployeeID,
        VacationHours + SickLeaveHours AS AvailableTimeOff
FROM    HumanResources.Employee; 


1.7. Providing Shorthand Names for Tables

SELECT  E.BusinessEntityID AS "Employee ID",
        E.VacationHours AS "Vacation",
        E.SickLeaveHours AS "Sick Time"
FROM    HumanResources.Employee AS E;


1.8. Negating a Search Condition

SELECT  Title,
        FirstName,
        LastName FROM  Person.Person 
WHERE NOT (Title = 'Ms.' OR Title = 'Mrs.');


1.9. Specifying a Range of Values

SELECT  SalesOrderID,
        ShipDate
FROM    Sales.SalesOrderHeader
WHERE   ShipDate BETWEEN '2005-07-23T00:00:00'
                 AND     '2005-07-24T23:59:59'; 


1.10. Checking for NULL Values

SELECT  ProductID,
        Name,
        Weight
FROM    Production.Product
WHERE   Weight IS NULL;


1.11. Providing a List of Values

SELECT  ProductID,
        Name,
        Color
FROM    Production.Product
WHERE   Color IN ('Silver', 'Black', 'Red');


1.12. Performing Wildcard Searches

SELECT  ProductID,
        Name
FROM    Production.Product
WHERE   Name LIKE 'B%';

UPDATE  Production.ProductDescription
SET     Description = 'Chromoly steel. High % of defects'
WHERE   ProductDescriptionID = 3;

SELECT  ProductDescriptionID,
        Description
FROM    Production.ProductDescription
WHERE   Description LIKE '%/%%' ESCAPE '/';


1.13. Sorting Your Results

SELECT  p.Name,
        h.EndDate,
        h.ListPrice
FROM    Production.Product AS p
        INNER JOIN Production.ProductListPriceHistory AS h
            ON p.ProductID = h.ProductID
ORDER BY p.Name,
        h.EndDate;

1.14. Specifying Sort Order

SELECT  p.Name,
        h.EndDate,
        h.ListPrice
FROM    Production.Product AS p
        INNER JOIN Production.ProductListPriceHistory AS h
            ON p.ProductID = h.ProductID
ORDER BY p.Name DESC,
        h.EndDate DESC;

1.15. Sorting by Columns Not Selected

SELECT  p.Name
FROM    Production.Product AS p
ORDER BY p.Color; 


1.16. Forcing Unusual Sort Orers

SELECT  p.ProductID,
        p.Name,
        p.Color
FROM    Production.Product AS p
WHERE   p.Color IS NOT NULL
ORDER BY CASE p.Color
           WHEN 'Red' THEN NULL
           ELSE p.Color
         END;


1.17. Paging Through A Result Set

SELECT ProductID, Name
FROM Production.Product
ORDER BY Name
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY; 

SELECT ProductID, Name
FROM Production.Product
ORDER BY Name
OFFSET 8 ROWS FETCH NEXT 10 ROWS ONLY;
