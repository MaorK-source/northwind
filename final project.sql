--1--
SELECT DATEPART(year, OrderDate) AS Year,
DATEPART(QUARTER, OrderDate) AS Quarter,
SUM(UNITPRICE*QUANTITY) AS GrossRevenue,
SUM(OD.UnitPrice*quantity*discount) AS TotalDiscount,
SUM(UNITPRICE*QUANTITY)-SUM(unitprice*quantity*discount) AS NetRevenue,
SUM(DISTINCT O.OrderID) AS Orders, SUM(QUANTITY) AS TotalProducts,
SUM(DISTINCT ProductID) AS UniqeProducts
FROM [Order Details] OD
JOIN Orders O ON O.OrderID=OD.OrderID
GROUP BY DATEPART(year, OrderDate), DATEPART(QUARTER, OrderDate)
order by DATEPART(year, OrderDate), DATEPART(QUARTER, OrderDate)
--2--
SELECT P.ProductName, COUNT(DISTINCT O.OrderID) AS Orders, SUM(DATEDIFF(DAY, OrderDate, ShippedDate)) AS DayToShip
FROM Products P
JOIN [Order Details] OD ON OD.ProductID=P.ProductID
JOIN Orders O ON O.OrderID=OD.OrderID
WHERE YEAR(OrderDate)= 1997
GROUP BY P.ProductName
HAVING SUM(DATEDIFF(DAY, OrderDate, ShippedDate))> 200
ORDER BY SUM(DATEDIFF(DAY, OrderDate, ShippedDate)) DESC
--3--
SELECT O.ShipCountry, SUM( OD.UNITPRICE*OD.QUANTITY) AS GrossRevenue,
SUM(OD.UNITPRICE*OD.QUANTITY*Discount) AS Discount,
SUM( OD.UNITPRICE*OD.QUANTITY)-SUM(OD.UNITPRICE*OD.QUANTITY*Discount) AS NetRevenue,
COUNT(DISTINCT od.OrderID) AS Orders, SUM(OD.QUANTITY) AS Quantity,
COUNT(distinct ProductID) AS UniqeProducts
FROM Orders O
JOIN [Order Details] OD ON OD.OrderID=O.OrderID
where ShipCountry in('germany', 'usa', 'austria', 'brazil')
group by O.ShipCountry
--4--
SELECT DATENAME (MONTH, O.OrderDate) AS Month, SUM( OD.UNITPRICE*OD.QUANTITY) AS GrossRevenue,
COUNT(distinct O.OrderID) AS Orders
FROM Orders O
JOIN [Order Details] OD ON O.OrderID=OD.OrderID
WHERE YEAR(OrderDate)= 1997
Group by DATENAME (MONTH, O.OrderDate), MONTH(OrderDate)
ORDER BY MONTH(OrderDate)

--5--
SELECT ShipVia, COUNT(DISTINCT OrderID) as Orders, SUM(DATEDIFF(DAY, ORDERDATE, SHIPPEDDATE)) AS ShippingTime
FROM Orders
WHERE YEAR(OrderDate)= 1997
GROUP BY ShipVia
--6--
SELECT SalesRank, ProductName
FROM
(
SELECT P.PRODUCTNAME, P.ProductID,

RANK() OVER(ORDER BY SUM(Quantity)DESC) AS SalesRank
FROM [Order Details] OD
JOIN Products P ON P.ProductID=OD.ProductID
WHERE OD.OrderID IN
	(SELECT OrderID
	FROM Orders
	WHERE YEAR(OrderDate)=1997
	)
GROUP BY P.ProductName, P.ProductID
) A
WHERE SalesRank<=5 OR SalesRank>=
(SELECT COUNT(DISTINCT ProductID)-4 FROM [Order Details]
)
--7--
SELECT NAME, 'CATEGORY' AS TITLE, Orders, Quantity, GROSS_REVENUE, DISCOUNT, NET_REVENUE
FROM	(
	SELECT TOP 10 PERCENT C.CATEGORYNAME AS NAME, COUNT(DISTINCT OD.ORDERID) AS Orders,
	SUM(Quantity) as Quantity, SUM(QUANTITY*OD.UNITPRICE) AS GROSS_REVENUE,
	SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS DISCOUNT,
	SUM(QUANTITY*OD.UNITPRICE)-SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS NET_REVENUE
	FROM Categories C
	JOIN Products P ON P.CategoryID=C.CategoryID
	JOIN [Order Details] OD ON OD.ProductID=P.ProductID
	JOIN ORDERS O ON OD.ORDERID=O.ORDERID
	WHERE ORDERDATE BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY CATEGORYNAME
	ORDER BY ORDERS DESC
	)A
UNION ALL
SELECT PRODUCTNAME AS NAME, 'PRODUCT' AS TITLE, Orders, Quantity, GROSS_REVENUE, DISCOUNT, NET_REVENUE
FROM	(
	SELECT TOP 10 PERCENT C.CATEGORYNAME, p.productname, COUNT(DISTINCT OD.ORDERID) AS Orders,
	SUM(Quantity) as Quantity, SUM(QUANTITY*OD.UNITPRICE) AS GROSS_REVENUE,
	SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS DISCOUNT,
	SUM(QUANTITY*OD.UNITPRICE)-SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS NET_REVENUE
	FROM Categories C
	JOIN Products P ON P.CategoryID=C.CategoryID
	JOIN [Order Details] OD ON OD.ProductID=P.ProductID
	JOIN ORDERS O ON OD.ORDERID=O.ORDERID
	WHERE ORDERDATE BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY CATEGORYNAME, p.productname
	ORDER BY ORDERS DESC
	) A
--8--
SELECT CategoryName,ProductName, PRODUCT_STOCKS, PRODUCT_ORDERD,
SUM(PRODUCT_STOCKS) OVER(PARTITION BY CATEGORYNAME) AS CATEGORY_STOCKS,
SUM(PRODUCT_ORDERD) OVER(PARTITION BY CATEGORYNAME) AS CATEGORY_ORDERD
	FROM(
	SELECT C. CategoryName, P.ProductName, SUM(P.UnitsInStock) AS PRODUCT_STOCKS, SUM(P.UnitsOnOrder) AS PRODUCT_ORDERD
	FROM Categories C
	JOIN Products P ON C.CategoryID=P.CategoryID
	WHERE UnitsInStock<10
	GROUP BY CategoryName, ProductName
	) A
--9--
SELECT FirstName, PERFORMANCE, ORDERS
FROM (
	SELECT TOP 5 E.FirstName, 'TOP 5' AS PERFORMANCE, COUNT(ORDERID) ORDERS
	FROM Employees E
	JOIN Orders O ON E.EmployeeID=O.EmployeeID
	WHERE OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY FirstName
	ORDER BY ORDERS DESC
	UNION ALL
	SELECT TOP 5 E.FirstName, 'BOTTOM 5' AS PERFORMANCE, COUNT(ORDERID) ORDERS
	FROM Employees E
	JOIN Orders O ON E.EmployeeID=O.EmployeeID
	WHERE OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY FirstName
	ORDER BY ORDERS ASC
	) A
--10--
SELECT Title,EmployeeID, ORDERS, QUANTITY, GROSS_REVENUE, DISCOUNT, NET_REVENUE,
	SUM(ORDERS) OVER(PARTITION BY TITLE) AS DEPARTMENT_ORDERS, 
	SUM(QUANTITY) OVER(PARTITION BY TITLE) AS DEPARTMENT_QUANTITY,
	SUM(GROSS_REVENUE) OVER(PARTITION BY TITLE) AS DEPARTMENT_GROSS_REVENUE,
	SUM(DISCOUNT) OVER(PARTITION BY TITLE) AS DEPARTMENT_DISCOUNT,
	SUM(NET_REVENUE) OVER(PARTITION BY TITLE) AS DEPARTMENT_REVENUE
FROM (
	SELECT TITLE,E.EMPLOYEEID, COUNT(DISTINCT OD.OrderID) AS ORDERS, SUM(OD.QUANTITY) AS QUANTITY,
	SUM(QUANTITY*OD.UNITPRICE) AS GROSS_REVENUE,
	SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS DISCOUNT,
	SUM(QUANTITY*OD.UNITPRICE)-SUM(DISCOUNT*QUANTITY*OD.UNITPRICE) AS NET_REVENUE
	FROM Employees E
	JOIN Orders O ON E.EmployeeID=O.EmployeeID
	JOIN [Order Details] OD ON O.OrderID=OD.OrderID
	WHERE O.OrderDate BETWEEN '1997-01-01' AND '1997-12-31'
	GROUP BY TITLE,E.EMPLOYEEID
	) A
--11--
select r.RegionDescription, count(distinct od.orderid) as OrderPerRegion, sum(od.UnitPrice*od.Quantity) as RegionGrossRev,
		sum(od.UnitPrice*od.Quantity)/count(distinct od.orderid) as RevenuePerOrder
from [Order Details] od
join Orders o on od.OrderID=o.OrderID
join EmployeeTerritories et on o.EmployeeID=et.EmployeeID
join Territories t on t.TerritoryID=et.TerritoryID
join Region r on r.RegionID=t.RegionID
group by r.RegionDescription
order by RevenuePerOrder desc
--12--
select  OrderDate, Month, Quarter,
CustomerID, Country, City,
ShipperID, ShippingCompany, 
EmployeeID, Title, FirstName,
ProductName, CategoryName,
sum(gross_revenue) as gross_revenue, 
sum(Discount) as Discount,
sum(Quantity) as Quantity,
sum(days_to_ship) as days_to_ship,
sum(products) as products,
count(OrderID) as orders
from (
select OrderID, ProductName, CategoryName,OrderDate, Month, Quarter, 
   CustomerID, Country, City,
   ShipperID, ShippingCompany, EmployeeID, Title, FirstName,
   sum(UnitPrice*Quantity) as gross_revenue,  
   sum(unit_discount*Quantity) as Discount,
   sum(Quantity) as Quantity,
   count(ProductID) as products,
   max(days_to_ship) as days_to_ship
from (
select od.OrderID, OrderDate, 
   DATENAME(MONTH, OrderDate) as Month, DATENAME(QUARTER, OrderDate) as Quarter,
   s.CustomerID, s.Country, s.City, od.ProductID, ProductName, CategoryName,
   h.ShipperID, h.CompanyName as ShippingCompany,
   e.EmployeeID, e.Title, e.FirstName,
   od.UnitPrice, od.Quantity, od.Discount, 
   od.UnitPrice*od.Discount as unit_discount,
   DATEDIFF(dd,OrderDate,ShippedDate) as days_to_ship
from [Order Details] od 
join Orders o on od.OrderID=o.OrderID
join Customers s on o.CustomerID=s.CustomerID
join Employees e on o.EmployeeID=e.EmployeeID
join Shippers h on o.ShipVia=h.ShipperID
join Products p on od.ProductID=p.ProductID
join Categories c on p.CategoryID=c.CategoryID
--where OrderDate between '1997-01-01' and '1997-12-31'
) a
group by OrderID, OrderDate, Month, QUARTER, CustomerID, Country, City,
   ShipperID, ShippingCompany, EmployeeID, Title, FirstName, ProductName, CategoryName
) a
group by OrderDate, Month, QUARTER, CustomerID, Country, City,
 ShipperID, ShippingCompany, EmployeeID, Title, FirstName, ProductName, CategoryName
order by OrderDate


