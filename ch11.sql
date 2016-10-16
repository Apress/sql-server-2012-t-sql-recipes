11-1. Representing Integers

DECLARE @bip bigint, @bin bigint
DECLARE @ip int, @in int
DECLARE @sip smallint, @sin smallint
DECLARE @ti tinyint

SET @bip =  9223372036854775807  /*  2^63-1 */
SET @bin = -9223372036854775808  /* -2^63   */
SET @ip =            2147483647  /*  2^31-1 */
SET @in =           -2147483648  /* -2^31   */
SET @sip =                32767  /*  2^15-1 */
SET @sin =               -32768  /* -2^15   */
SET @ti =                   255  /*  2^8-1  */

SELECT 'bigint' AS type_name, @bip AS max_value, @bin AS min_value
UNION ALL
SELECT 'int', @ip, @in
UNION ALL
SELECT 'smallint', @sip, @sin
UNION ALL
SELECT 'tinyint', @ti, 0
ORDER BY max_value DESC


11-2. Representing Decimal Amounts

DECLARE @x0 decimal(7,0) = 1234567.
DECLARE @x1 decimal(7,1) = 123456.7
DECLARE @x2 decimal(7,2) = 12345.67
DECLARE @x3 decimal(7,3) = 1234.567
DECLARE @x4 decimal(7,4) = 123.4567
DECLARE @x5 decimal(7,5) = 12.34567
DECLARE @x6 decimal(7,6) = 1.234567
DECLARE @x7 decimal(7,7) = .1234567

SELECT @x0
SELECT @x1
SELECT @x2
SELECT @x3
SELECT @x4
SELECT @x5
SELECT @x6
SELECT @x7


11-3. Representing Monetary Amounts

Solution #1

DECLARE @account_balance decimal(12,2)

Solution #2

DECLARE @mp money, @mn money
DECLARE @smp smallmoney, @smn smallmoney
SET @mp = 922337203685477.5807
SET @mn = -922337203685477.5808
SET @smp = 214748.3647
SET @smn = -214748.3648
SELECT 'money' AS type_name, @mp AS max_value, @mn AS min_value
UNION ALL
SELECT 'smallmoney', @smp, @smn


11-4. Representincg Floating-Point Values

DECLARE @x1 real  /* same as float(24) */
DECLARE @x2 float /* same as float(53) */
DECLARE @x3 float(53)
DECLARE @x4 float(24)


11-5. Writing Mathematical Expressions

DECLARE @cur_bal decimal(7,2) = 94235.49
DECLARE @new_bal decimal(7,2)

SET @new_bal = @cur_bal - (500.00 - ROUND(@cur_bal * 0.06 / 12.00, 2))
SELECT @new_bal


11-6. Guarding Against Errors in Expressions with Mixed Data Types

SELECT 6/100, 
       CAST(6 AS DECIMAL(1,0)) / CAST(100 AS DECIMAL(3,0)),
       CAST(6.0/100.0 AS DECIMAL(3,2))

SELECT 6/100, 
       CONVERT(DECIMAL(1,0), 6) / CONVERT(DECIMAL(3,0), 100),
       CONVERT(DECIMAL(3,2), 6.0/100.0)


11-7. Rounding

SELECT EndOfDayRate,
       ROUND(EndOfDayRate,0) AS EODR_Dollar,
       ROUND(EndOfDayRate,2) AS EODR_Cent
FROM Sales.CurrencyRate


11-8. Rounding Always Up or Down

SELECT CEILING(-1.23), FLOOR(-1.23), CEILING(1.23), FLOOR(1.23)


11-9. Discarding Decimal Places

SELECT ROUND(123.99,0,1), ROUND(123.99,1,1), ROUND(123.99,-1,1)


11-10. Testing Equality of Binary Floating-Point Values

DECLARE @r1 real = 0.95
DECLARE @f1 float = 0.95
IF ABS(@r1-@f1) < 0.000001
   SELECT 'Equal'
ELSE
   SELECT 'Not Equal'


11-11. Treating Nulls as Zeros

SELECT SpecialOfferID, MaxQty, COALESCE(MaxQty, 0) AS MaxQtyAlt
FROM Sales.SpecialOffer


11-12. Generating a Row Set of Sequential Numbers

WITH ones AS (
    SELECT * 
    FROM (VALUES (0), (1), (2), (3), (4), 
                 (5), (6), (7), (8), (9)) AS numbers(x) 
)
SELECT 1000*o1000.x + 100*o100.x + 10*o10.x + o1.x x
FROM ones o1, ones o10, ones o100, ones o1000
ORDER BY x


11-13. Generting Random Integers in a Row Set

DECLARE @rmin int, @rmax int;
SET @rmin = 900;
SET @rmax = 1000;
SELECT Name,
       CAST(RAND(CHECKSUM(NEWID())) * (@rmax-@rmin) AS INT) + @rmin
FROM Production.Product;

11-14. Reducing Space Used by Decimal Storage

EXEC sp_db_vardecimal_storage_format 'AdventureWorks2012', 'ON'

EXEC sys.sp_estimated_rowsize_reduction_for_vardecimal 'Production.BillOfMaterials'

sp_tableoption 'Production.BillOfMaterials', 'vardecimal storage format', 1

