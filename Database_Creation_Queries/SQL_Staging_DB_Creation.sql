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
	zipcode NVARCHAR(20),
	is_retail BIT
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

USE TDC_Staging_DB;
GO

-- ==============================================================================
-- Detección de inconsistencias en HistorySales
-- (Esto lo ejecutamos una vez cargado para ver si hay facturas con fecha/clientes/empleados cruzados)
-- ==============================================================================
SELECT billing_id, COUNT(DISTINCT customer_id) AS Clientes_Distintos, COUNT(DISTINCT employee_id) AS Empleados_Distintos, COUNT(DISTINCT date) AS Fechas_Distintas
FROM HistorySales
GROUP BY billing_id
HAVING COUNT(DISTINCT customer_id) > 1 OR COUNT(DISTINCT employee_id) > 1 OR COUNT(DISTINCT date) > 1;
GO

-- ==============================================================================
-- Estandarización de Estructuras (Unificando Fuentes)
-- Para evitar colisiones de IDs, a las facturas históricas les sumamos 100,000,000
-- ==============================================================================

-- CABECERAS UNIFICADAS
CREATE OR ALTER VIEW vw_Base_Billing_Header AS
    -- Actuales
    SELECT billing_id, date, region, branch_id, customer_id, employee_id, 'Current' AS source
    FROM Billing
    UNION ALL
    -- Históricas (Aplicamos DISTINCT porque vienen denormalizadas por línea)
    SELECT DISTINCT 
        billing_id + 100000000 AS billing_id, 
        date, 
        NULL AS region, 
        NULL AS branch_id, 
        customer_id, 
        employee_id, 
        'Historical' AS source
    FROM HistorySales;
GO

-- DETALLES UNIFICADOS
CREATE OR ALTER VIEW vw_Base_Billing_Detail AS
    -- Actuales
    SELECT billing_id, product_id, quantity 
    FROM Billing_Detail
    UNION ALL
    -- Históricas
    SELECT billing_id + 100000000 AS billing_id, product_id, quantity 
    FROM HistorySales;
GO

-- ==============================================================================
-- 3. VISTA ENRIQUECIDA DETALLE (Calculando Precios Históricos y Subtotales)
-- ==============================================================================
CREATE OR ALTER VIEW vw_Priced_Billing_Detail AS
SELECT 
    d.billing_id,
    d.product_id,
    d.quantity,
    h.date,
    -- Buscar el último precio válido a la fecha de la factura
    ISNULL((
        SELECT TOP 1 p.price 
        FROM Prices p 
        WHERE p.product_id = d.product_id AND p.date <= h.date 
        ORDER BY p.date DESC
    ), 0) AS unit_price,
    
    -- Subtotal por línea
    d.quantity * ISNULL((
        SELECT TOP 1 p.price 
        FROM Prices p 
        WHERE p.product_id = d.product_id AND p.date <= h.date 
        ORDER BY p.date DESC
    ), 0) AS line_subtotal
FROM vw_Base_Billing_Detail d
INNER JOIN vw_Base_Billing_Header h ON d.billing_id = h.billing_id;
GO

-- ==============================================================================
-- 4. VISTA FINAL CABECERA (Agregaciones, Descuentos, Edades y Antigüedad)
-- Esta es la vista que leerá SSIS para tu hBilling
-- ==============================================================================
CREATE OR ALTER VIEW vw_Fact_Billing_Header AS
WITH Totals AS (
    -- Calculamos el subtotal agrupando las líneas
    SELECT billing_id, SUM(line_subtotal) AS subtotal, SUM(quantity) AS volume_sold_liters
    FROM vw_Priced_Billing_Detail
    GROUP BY billing_id
)
SELECT 
    h.billing_id,
    CAST(h.date AS DATE) AS date,
    h.date AS date_t,
    h.region,
    h.branch_id,
    h.customer_id,
    
    -- Cálculo de Edades y Seniority al momento de la venta usando DATEDIFF
    DATEDIFF(YEAR, c.birth_date, h.date) AS customer_age,
    h.employee_id,
    DATEDIFF(YEAR, e.birth_date, h.date) AS employee_age,
    DATEDIFF(YEAR, e.employment_date, h.date) AS employee_seniority,
    
    t.subtotal,
    t.volume_sold_liters,
    
    -- Magia SQL: Cruce con Descuentos (Por fecha y por Monto Total)
    ISNULL(disc.percentage, 0) AS discount_percentage,
    (t.subtotal * ISNULL(disc.percentage, 0) / 100.0) AS discount_amount,
    t.subtotal - (t.subtotal * ISNULL(disc.percentage, 0) / 100.0) AS final_billing

FROM vw_Base_Billing_Header h
INNER JOIN Totals t ON h.billing_id = t.billing_id
LEFT JOIN Customers c ON h.customer_id = c.customer_id
LEFT JOIN Employees e ON h.employee_id = e.employee_id
-- LEFT JOIN a la tabla de Descuentos con múltiples condiciones
LEFT JOIN Discounts disc 
    ON h.date >= disc.date_from 
   AND h.date <= disc.date_until 
   AND t.subtotal > disc.total_billing;
GO