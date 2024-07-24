WITH
Latest_order_date AS(
SELECT
MAX(Orderdate) AS MAXLatest_order_date
FROM
`adwentureworks_db.salesorderheader` ),


Latest_address AS(
SELECT
CustomerID,
MAX(addressID) AS Latest_addressid
FROM
`adwentureworks_db.customeraddress` AS latest_customer_address
GROUP BY
CustomerID),

Customer_detail AS(
SELECT
sales_info.CustomerID AS Customer_id,
contact_info.Firstname AS First_name,
contact_info.LastName AS Last_name,
CONCAT(contact_info.Firstname,' ', contact_info.LastName) AS Full_name,
CASE
WHEN contact_info.Title IS NULL THEN 'Dear'
ELSE contact_info.Title
END
|| ' ' || contact_info.LastName AS Addressing_title,
contact_info.emailaddress AS Email,
contact_info.Phone AS Phone,
customer_info.accountnumber AS Account_num,
customer_info.customertype AS Customer_type,
address.city AS City,
address.addressline1 AS Address_line1,
-- added aditional columns as requested dividing street number and street name
LEFT(addressline1, STRPOS(addressline1, ' ') -1) AS Address_num,
RIGHT(addressline1, LENGTH(addressline1) - STRPOS(addressline1, ' ')) AS Street_name,
address.addressline2 AS Address_line2,
state_province.name AS State,
country.name AS Country,
sales_teritory.Group AS Continent, --
COUNT(sales_info.salesorderID) AS Number_orders,
ROUND(SUM(sales_info.totaldue), 2) AS Total_amount,
MAX(sales_info.orderdate) AS Last_order_made
FROM
`adwentureworks_db.contact` AS contact_info
JOIN
`adwentureworks_db.salesorderheader` AS sales_info
ON
contact_info.ContactId = sales_info.ContactID
JOIN
`adwentureworks_db.customer` AS customer_info
ON
customer_info.CustomerID = sales_info.CustomerID
-- added another join which I have got the continent data (North America)
JOIN
`adwentureworks_db.salesterritory` AS sales_teritory
ON
sales_teritory.TerritoryID = customer_info.TerritoryID
JOIN
`adwentureworks_db.customeraddress` AS customer_address_join
ON
customer_info.CustomerID = Customer_address_join.CustomerID
INNER JOIN
Latest_address
ON
Latest_address.customerId = customer_address_join.CustomerID
JOIN
`adwentureworks_db.address` AS address
ON
address.AddressID = customer_address_join.AddressID
JOIN
`adwentureworks_db.stateprovince` AS state_province
ON
state_province.StateProvinceID = address.StateProvinceID
JOIN
`adwentureworks_db.countryregion` AS country
ON
country.CountryRegionCode = state_province.CountryRegionCode
-- filtered data by the customer type and continent
WHERE
customer_info.CustomerType = 'I'
AND
sales_teritory.Group = 'North America'
GROUP BY ALL
-- for the aggregated functions used HAVING function
HAVING
ROUND(SUM(sales_info.totaldue), 2) > 2500
OR
COUNT(sales_info.salesorderID) > 5 ),


Filtered_customers AS (
SELECT
*,
CASE
WHEN DATE_DIFF(Latest_order_date.MAXLatest_order_date, Last_order_made, DAY) >= 365 THEN "Non-active"
ELSE 'Active'
END
AS Customer_activity
FROM
Customer_detail,
Latest_order_date
)


SELECT
*
FROM
Filtered_customers
WHERE
Filtered_customers.Customer_activity = 'Active'
ORDER BY
Country,
State,
Last_order_made;