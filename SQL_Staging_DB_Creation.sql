USE TDC_Staging_DB;

CREATE TABLE Holidays (
	date DATE,
	holiday NVARCHAR(50)
);

CREATE TABLE Employees (
	employee_id INT,
	full_name NVARCHAR(100),
	gender NVARCHAR(10),
	category NVARCHAR(100),
	employment_date DATE,
	birth_date DATE,
	education_level NVARCHAR(50)
);

CREATE TABLE Customers (
	customer_id INT,
	full_name NVARCHAR(255),
	birth_date NVARCHAR(20),
	city NVARCHAR(255),
	state NVARCHAR(255),
	zipcode NVARCHAR(20)
);

CREATE TABLE HistorySales (
	id INT,
	billing_id INT,
	date DATETIME,
	customer_id INT,
	employee_id INT,
	product_id INT,
	quantity INT
);

CREATE TABLE Billing (
	billing_id INT,
	region NVARCHAR(50),
	branch_id INT,
	date DATETIME,
	customer_id INT,
	employee_id INT
);

CREATE TABLE Billing_Detail (
	billing_id INT,
	product_id INT,
	quantity INT
);

CREATE TABLE Discounts (
	discount_id INT,
	date_from DATETIME, 
	date_until DATETIME,
	total_billing DECIMAL(18,2),
	percentage DECIMAL(5,2)
);

CREATE TABLE Prices (
	product_id INT,
	date DATETIME,
	price DECIMAL(18,2)
);

CREATE TABLE Regions (
	region VARCHAR(50),
	state VARCHAR(100),
	city VARCHAR(100),
	zipcode VARCHAR(20)
);

CREATE TABLE Products (
	product_id INT,
	detail VARCHAR(200),
	package VARCHAR(100)
);

CREATE TABLE Stock (
	product_id INT,
	date VARCHAR(100),
	variation INT
);