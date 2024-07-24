-- new CTE finds Latest_order_date which I will use to filter out active (difference from their last order <=365) and non-active customers (>=365)
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
address.addressline2 AS Address_line2,
state_province.name AS State,
country.name AS Country,
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
WHERE
customer_info.CustomerType = 'I'
GROUP BY ALL
),


Ordered_customers AS(
SELECT
*
FROM
Customer_detail
ORDER BY
Total_amount DESC),

Filtered_customers AS (
SELECT
*
FROM
Ordered_customers,
Latest_order_date
WHERE DATE_DIFF(Latest_order_date.MAXLatest_order_date, Last_order_made, DAY) >= 365 -- identifying non-active customers who did not place an order in 365 days
)


SELECT
*
FROM
Filtered_customers
ORDER BY
Total_amount DESC
LIMIT
200;