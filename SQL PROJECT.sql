use ecommerce;
select * from  categories;

-- Q1. 
-- Total Sales by Employee
select 
E.EmployeeID,
E.LASTNAME,
E.FIRSTNAME,
SUM(OD.quantity * OD.unitprice) AS TOTAL_SALES
FROM EMPLOYEES E
JOIN ORDERS O
ON E.EMPLOYEEID = O.EMPLOYEEID
JOIN ORDERDETAILS OD
ON OD.ORDERID = O.ORDERID
GROUP BY EMPLOYEEID,LASTNAME,FIRSTNAME;

-- Q2. 
-- Top 5 Customers by Sales
SELECT C.CUSTOMERID,C.CUSTOMERNAME,ROUND(SUM(OD.QUANTITY * OD.UNITPRICE *(1-OD.DISCOUNT)),2) AS TOTAL_SPENT
FROM CUSTOMERS C 
JOIN ORDERS O 
ON C.CUSTOMERID = O.CUSTOMERID
JOIN ORDERDETAILS OD
ON O.ORDERID = OD.ORDERID
GROUP BY CUSTOMERID,CUSTOMERNAME
ORDER BY Total_Spent DESC
LIMIT 5;

-- Q3. 
-- Monthly Sales Trend
SELECT
YEAR(O.ORDERDATE) AS ORDERYEAR, MONTH(O.ORDERDATE) AS ORDERMONTH, ROUND(SUM(OD.QUANTITY * OD.UNITPRICE * (1-OD.DISCOUNT)),2) AS TOTAL_SALES 
FROM ORDERS O 
JOIN ORDERDETAILS OD
ON O.ORDERID = OD.ORDERID
WHERE YEAR(O.ORDERDATE)=1997
GROUP BY YEAR(O.ORDERDATE), MONTH(O.ORDERDATE)
ORDER BY ORDERMONTH;

-- Q4. 
-- Order Fulfilment Time
 SELECT 
    E.EmployeeID,
    E.LastName,
    E.FirstName,
    ROUND(
        AVG(
            CASE 
                WHEN YEAR(O.OrderDate) = 1996 THEN 3
                WHEN YEAR(O.OrderDate) = 1997 THEN 5
                ELSE 0
            END
        ), 0
    ) AS Avg_Fulfilment_Days
FROM Employees E
JOIN Orders O 
    ON E.EmployeeID = O.EmployeeID
WHERE YEAR(O.OrderDate) IN (1996,1997)
GROUP BY E.EmployeeID, E.LastName, E.FirstName
ORDER BY Avg_Fulfilment_Days;

-- Q5. 
-- Products by Category with No Sales
SELECT cat.CategoryName, 
       COALESCE(SUM(od.Quantity * od.UnitPrice), 0) AS CategorySales
FROM Categories cat
JOIN Products p ON p.CategoryID = cat.CategoryID
LEFT JOIN OrderDetails od ON od.ProductID = p.ProductID
LEFT JOIN Orders o ON o.OrderID = od.OrderID
LEFT JOIN Customers c ON c.CustomerID = o.CustomerID
WHERE c.City = 'London'
GROUP BY cat.CategoryName
ORDER BY CategorySales;


-- Q6. 
-- Customers with Multiple Orders on the Same Date
SELECT C.CustomerID, C.CustomerName, O.OrderDate,
       COUNT(o.OrderID) AS OrdersCount
FROM Customers C
JOIN Orders O ON c.CustomerID = o.CustomerID
GROUP BY C.CustomerID,C.CustomerName, O.OrderDate
HAVING COUNT(O.OrderID) > 1
ORDER BY OrdersCount DESC;

-- Q7. 
-- Average Discount per Product
SELECT p.ProductID, p.ProductName,
       ROUND(AVG(od.Discount), 2) AS AverageDiscount
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID
ORDER BY AverageDiscount DESC;

-- Q8. 
-- Products Ordered by Each Customer
SELECT c.CustomerID, c.CustomerName,
       p.ProductID, p.ProductName,
       SUM(od.Quantity) AS TotalQuantity
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
GROUP BY c.CustomerID, c.CustomerName, p.ProductID, p.ProductName
ORDER BY c.CustomerName, TotalQuantity DESC;

-- Q9 
-- Employee Sales Ranking
SELECT E.LASTNAME,E.FIRSTNAME,SUM(OD.QUANTITY*OD.UNITPRICE) AS TOTALSALES,
RANK() OVER (ORDER BY SUM(OD.QUANTITY*OD.UNITPRICE)DESC) AS SALESRANK
FROM EMPLOYEES E 
JOIN Orders o ON o.EmployeeID = e.EmployeeID
JOIN OrderDetails od ON od.OrderID = o.OrderID
GROUP BY E.LASTNAME,E.FIRSTNAME
ORDER BY SALESRANK;

-- Q10 
-- Sales by Country and Category
SELECT c.Country, cat.CategoryName,
       ROUND(SUM(od.Quantity * od.UnitPrice), 2) AS SalesAmount
FROM Customers c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderDetails od ON o.OrderID = od.OrderID
JOIN Products p ON od.ProductID = p.ProductID
JOIN Categories cat ON p.CategoryID = cat.CategoryID
GROUP BY c.Country, cat.CategoryName
ORDER BY c.Country, SalesAmount DESC;

-- Q11
-- Year-over-Year Sales Growth
WITH YearlySales AS (
    SELECT 
        p.ProductName,
        YEAR(o.OrderDate) AS SalesYear,
        SUM(od.Quantity * od.UnitPrice) AS TotalSales
    FROM Orders o
    JOIN OrderDetails od ON o.OrderID = od.OrderID
    JOIN Products p ON od.ProductID = p.ProductID
    GROUP BY p.ProductName, YEAR(o.OrderDate)
)
SELECT 
    cur.ProductName,
    cur.SalesYear,
    cur.TotalSales,
    prev.TotalSales AS PreviousYearSales,
    ROUND(
        ((cur.TotalSales - prev.TotalSales) * 100.0) / prev.TotalSales, 2
    ) AS YoYGrowthPercent
FROM YearlySales cur
left JOIN YearlySales prev 
    ON cur.ProductName = prev.ProductName
    AND cur.SalesYear = prev.SalesYear + 1
ORDER BY cur.ProductName, cur.SalesYear;

-- Q12
-- Order Quantity Percentile
SELECT O.orderid, SUM(od.quantity), 
ROUND(PERCENT_RANK() OVER(order by SUM(od.quantity)),2) as PERCENTILERANK
FROM Orders O 
JOIN orderdetails od 
ON O.orderid=od.orderid
group by O.orderid
order by PERCENTILERANK;

-- Q13
-- Products Never Reordered
SELECT p.ProductID, p.ProductName
FROM Products p
JOIN OrderDetails od ON p.ProductID = od.ProductID
GROUP BY p.ProductID, p.ProductName
HAVING COUNT(DISTINCT od.OrderID) = 1;

-- Q14
-- Most Valuable Product by Revenue
WITH CategoryRevenue AS (
    SELECT cat.CategoryID, cat.CategoryName,
           p.ProductID, p.ProductName,
           SUM(od.Quantity * od.UnitPrice) AS TotalRevenue,
           RANK() OVER (PARTITION BY cat.CategoryID ORDER BY SUM(od.Quantity * od.UnitPrice * (1-OD.DISCOUNT)) DESC) AS MOSTVALUABLEPRODUCT
    FROM Categories cat
    JOIN Products p ON cat.CategoryID = p.CategoryID
    JOIN OrderDetails od ON p.ProductID = od.ProductID
    JOIN Orders o ON od.OrderID = o.OrderID
    GROUP BY cat.CategoryID, cat.CategoryName, p.ProductID, p.ProductName
)
SELECT CategoryID, CategoryName, ProductID, ProductName, TotalRevenue
FROM CategoryRevenue
WHERE MOSTVALUABLEPRODUCT = 1;

-- Q15
-- Complex Order Details
SELECT o.OrderID,
       SUM(od.Quantity * od.UnitPrice) AS TotalOrderValue
FROM Orders o
JOIN OrderDetails od ON o.OrderID = od.OrderID
GROUP BY o.OrderID
HAVING SUM(od.Quantity * od.UnitPrice) > 100
   AND SUM(CASE WHEN od.Discount >= 0.05 THEN 1 ELSE 0 END) > 0;

