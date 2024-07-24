WITH
-- finding the maximum tax rate for each state within a country
Max_tax_rates AS (
SELECT
State_province.CountryRegionCode AS Country_region_code,
State_province.StateProvinceID,
Tax_rate.StateProvinceID AS Tax_provinces,
MAX(Tax_rate.TaxRate) AS Max_tax_rate
FROM
`adwentureworks_db.salestaxrate` AS Tax_rate
JOIN
`adwentureworks_db.stateprovince` AS State_province
ON
State_province.StateProvinceID = Tax_rate.StateProvinceID
GROUP BY
State_province.CountryRegionCode,
State_province.StateProvinceID,
Tax_rate.StateProvinceID
),


Country_tax_info AS (
SELECT
Max_tax_rates.Country_region_code AS Country_region_code,
AVG(max_tax_rate) AS Mean_tax_rate,
IFNULL( COUNT( DISTINCT(Max_tax_rates.Tax_provinces )),0) AS Taxed_provinces -- ensures provinces without tax rates don't affect the percentage calculation (they are counted as 0)
FROM
Max_tax_rates
GROUP BY
Country_region_code
),

-- total number of provinces in each country
Country_provinces AS (
SELECT
CountryRegionCode AS Country_region_code,
COUNT(DISTINCT StateProvinceID) AS Provinces_num
FROM
`adwentureworks_db.stateprovince`
GROUP BY
CountryRegionCode
),


Tax_info AS (
SELECT
Country_tax_info.Country_region_code AS Country_region_code,
Country_tax_info.mean_tax_rate,
Country_tax_info.taxed_provinces,
Country_provinces.Provinces_num,
ROUND(Country_tax_info.taxed_provinces / Country_provinces.Provinces_num, 2) AS perc_provinces_w_tax,
FROM
Country_tax_info
JOIN
Country_provinces
ON
Country_tax_info.Country_region_code = Country_provinces.Country_region_code
),


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
JOIN
`adwentureworks_db.stateprovince` AS State_province
ON
State_province.TerritoryID = sales_territory.TerritoryID
GROUP BY
sales_info.OrderDate,
sales_territory.CountryRegionCode,
sales_territory.Name
)

-- joining Tax_info CTE to get Mean_tax_rate and perc_provinces_w_tax for each country (left join ensures data for countries without tax info is included)
SELECT
*,
SUM(Total_with_taxes) OVER (PARTITION BY Sales_by_month.Country_region_code, Region ORDER BY Order_month) AS Cumulative_total,
RANK() OVER(PARTITION BY Sales_by_month.Country_region_code, Region ORDER BY Total_with_taxes DESC) AS Country_rank,
tax_info.Mean_tax_rate,
tax_info.perc_provinces_w_tax
FROM
Sales_by_month
LEFT JOIN
Tax_info
ON
Sales_by_month.Country_region_code = Tax_info.Country_region_code
;