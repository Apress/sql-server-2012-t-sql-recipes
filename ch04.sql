4-1. Correlating Parent and Child Rows

SELECT  PersonPhone.BusinessEntityID,
        FirstName,
        LastName,
        PhoneNumber
FROM    Person.Person
        INNER JOIN Person.PersonPhone
            ON Person.BusinessEntityID = PersonPhone.BusinessEntityID
ORDER BY LastName,
        FirstName,
        Person.BusinessEntityID;


4-2. Querying Many-to-Many Relationships

SELECT  p.Name,
        s.DiscountPct
FROM    Sales.SpecialOffer s
        INNER JOIN Sales.SpecialOfferProduct o
            ON s.SpecialOfferID = o.SpecialOfferID
        INNER JOIN Production.Product p
            ON o.ProductID = p.ProductID
WHERE   p.Name = 'All-Purpose Bike Stand';


4-3. Making One Side of a Join Optional

SELECT  s.CountryRegionCode,
        s.StateProvinceCode,
        t.TaxType,
        t.TaxRate
FROM    Person.StateProvince s
        LEFT OUTER JOIN Sales.SalesTaxRate t
            ON s.StateProvinceID = t.StateProvinceID;


4-4. Making Both Sides of a Join Optional

SELECT  soh.SalesOrderID,
        sr.SalesReasonID,
        sr.Name
FROM    Sales.SalesOrderHeader soh
        FULL OUTER JOIN Sales.SalesOrderHeaderSalesReason sohsr
            ON soh.SalesOrderID = sohsr.SalesOrderID
        FULL OUTER JOIN Sales.SalesReason sr
            ON sr.SalesReasonID = sohsr.SalesReasonID;


4-5. Generating All Possible Row Combinations

SELECT  s.CountryRegionCode,
        s.StateProvinceCode,
        t.TaxType,
        t.TaxRate
FROM    Person.StateProvince s
        CROSS JOIN Sales.SalesTaxRate t;


4-6. Selecting From A Resut Set

SELECT DISTINCT
        s.PurchaseOrderNumber
FROM    Sales.SalesOrderHeader s
        INNER JOIN (SELECT  SalesOrderID
                    FROM    Sales.SalesOrderDetail
                    WHERE   UnitPrice BETWEEN 1000 AND 2000
                   ) d
            ON s.SalesOrderID = d.SalesOrderID;


4-7. Testing for the Existence of a Row

SELECT DISTINCT
        s.PurchaseOrderNumber
FROM    Sales.SalesOrderHeader s
WHERE   EXISTS ( SELECT SalesOrderID
                 FROM   Sales.SalesOrderDetail
                 WHERE  UnitPrice BETWEEN 1000 AND 2000
                        AND SalesOrderID = s.SalesOrderID );


4-8. Testing Against the Result from A Query

SELECT  BusinessEntityID,
        SalesQuota CurrentSalesQuota
FROM    Sales.SalesPerson
WHERE   SalesQuota = (SELECT    MAX(SalesQuota)
                      FROM      Sales.SalesPerson
                     );


4-9. Comparing Subsets of a Table

SELECT  s.BusinessEntityID,
        SUM(s2008.SalesQuota) Total_2008_SQ,
        SUM(s2007.SalesQuota) Total_2007_SQ
FROM    Sales.SalesPerson s
        LEFT OUTER JOIN Sales.SalesPersonQuotaHistory s2008
            ON s.BusinessEntityID = s2008.BusinessEntityID
               AND YEAR(s2008.QuotaDate) = 2008
        LEFT OUTER JOIN Sales.SalesPersonQuotaHistory s2007
            ON s.BusinessEntityID = s2007.BusinessEntityID
               AND YEAR(s2007.QuotaDate) = 2007
GROUP BY s.BusinessEntityID;


4-10. Stacking Two Row Sets Vertically

SELECT  BusinessEntityID,
        GETDATE() QuotaDate,
        SalesQuota
FROM    Sales.SalesPerson
WHERE   SalesQuota > 0
UNION ALL
SELECT  BusinessEntityID,
        QuotaDate,
        SalesQuota
FROM    Sales.SalesPersonQuotaHistory
WHERE   SalesQuota > 0
ORDER BY BusinessEntityID DESC,
        QuotaDate DESC;


4-11. Eliminating Dupicate Values from a Union

SELECT  P1.LastName
FROM    HumanResources.Employee E
        INNER JOIN Person.Person P1
            ON E.BusinessEntityID = P1.BusinessEntityID
UNION
SELECT  P2.LastName
FROM    Sales.SalesPerson SP
        INNER JOIN Person.Person P2
            ON SP.BusinessEntityID = P2.BusinessEntityID;


4-12. Subtracting One Row Set from Another

SELECT  P.ProductID
FROM    Production.Product P
EXCEPT
SELECT  BOM.ComponentID
FROM    Production.BillOfMaterials BOM;


4-13. Finding Rows in Common Between Two Row Sets

SELECT  PR1.ProductID
FROM    Production.ProductReview PR1
WHERE   PR1.Rating >= 4
INTERSECT
SELECT  PR1.ProductID
FROM    Production.ProductReview PR1
WHERE   PR1.Rating <= 2;


4-14. Finding Rows That Are Missing

SELECT  ProductID
FROM    Production.Product
EXCEPT
SELECT  ProductID
FROM    Sales.SpecialOfferProduct;


4-15. Comparing Two Tables

SELECT  *
INTO    Person.PasswordCopy
FROM    Person.Password;

SELECT  *,
        COUNT(*) DupeCount,
        'Password' TableName
FROM    Person.Password P
GROUP BY BusinessEntityID,
        PasswordHash,
        PasswordSalt,
        rowguid,
        ModifiedDate
HAVING  NOT EXISTS ( SELECT *,
                            COUNT(*)
                     FROM   Person.PasswordCopy PC
                     GROUP BY BusinessEntityID,
                            PasswordHash,
                            PasswordSalt,
                            rowguid,
                            ModifiedDate
                     HAVING PC.BusinessEntityID = P.BusinessEntityID
                            AND PC.PasswordHash = P.PasswordHash
                            AND PC.PasswordSalt = P.PasswordSalt
                            AND PC.rowguid = P.rowguid
                            AND PC.ModifiedDate = P.ModifiedDate
                            AND COUNT(*) = COUNT(ALL P.BusinessEntityID) )
UNION
SELECT  *,
        COUNT(*) DupeCount,
        'PasswordCopy' TableName
FROM    Person.PasswordCopy PC
GROUP BY BusinessEntityID,
        PasswordHash,
        PasswordSalt,
        rowguid,
        ModifiedDate
HAVING  NOT EXISTS ( SELECT *,
                            COUNT(*)
                     FROM   Person.Password P
                     GROUP BY BusinessEntityID,
                            PasswordHash,
                            PasswordSalt,
                            rowguid,
                            ModifiedDate
                     HAVING PC.BusinessEntityID = P.BusinessEntityID
                            AND PC.PasswordHash = P.PasswordHash
                            AND PC.PasswordSalt = P.PasswordSalt
                            AND PC.rowguid = P.rowguid
                            AND PC.ModifiedDate = P.ModifiedDate
                            AND COUNT(*) = COUNT(ALL PC.BusinessEntityID) );



