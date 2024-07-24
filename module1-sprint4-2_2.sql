WITH
Sales_by_month AS (
SELECT
LAST_DAY(DATE(sales_info.OrderDate)) AS Order_month,
sales_territory.CountryRegionCode AS Country_region_code,
sales_territory.Name AS Region,
COUNT(sales_info.SalesOrderID) AS Oders_number,
COUNT(DISTINCT(sales_info.CustomerID)) AS Customers_number,
COUNT(DISTINCT(sales_info.SalesPersonID)) AS Sales_person_number,
ROUND(SUM(sales_info.TotalDue), 2) AS Total_with_taxes
FROM
`adwentureworks_db.salesorderheader` AS sales_info
JOIN
`adwentureworks_db.salesterritory` AS sales_territory
ON
sales_info.TerritoryID = sales_territory.TerritoryID
GROUP BY
LAST_DAY(DATE(sales_info.OrderDate)),
sales_territory.CountryRegionCode,
sales_territory.Name
ORDER BY
sales_territory.CountryRegionCode DESC
)


SELECT
*,
SUM(Total_with_taxes) OVER (PARTITION BY Country_region_code, Region ORDER BY Order_month) AS Cumulative_total
FROM
Sales_by_month;