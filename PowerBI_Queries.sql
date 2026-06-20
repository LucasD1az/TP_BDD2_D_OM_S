-- ============================================================
-- THE DRINKING COMPANY - CONSULTAS POWER BI
-- Base: TDC_DataWarehouse
-- ============================================================

USE TDC_DataWarehouse;
GO

-- ============================================================
-- TABLAS PLANAS PARA EL MODELO DE POWER BI
-- Importar cada bloque como una tabla separada en Power BI
-- ============================================================

-- ------------------------------------------------------------
-- [1] DIMENSIÓN FECHA (calendario completo)
-- ------------------------------------------------------------
SELECT
    date,
    year,
    month,
    month_name,
    day,
    weekday,
    weekday_name,
    trimester,
    semester,
    holiday
FROM dDate
ORDER BY date;


-- ------------------------------------------------------------
-- [2] DIMENSIÓN CLIENTE
-- ------------------------------------------------------------
SELECT
    customer_sk,
    customer_id,
    first_name + ' ' + last_name   AS full_name,
    first_name,
    last_name,
    birth_date,
    city,
    state,
    zipcode,
    CASE WHEN is_retail = 1 THEN 'Retail' ELSE 'Mayorista' END AS customer_type
FROM dCustomer;


-- ------------------------------------------------------------
-- [3] DIMENSIÓN EMPLEADO
-- ------------------------------------------------------------
SELECT
    employee_sk,
    employee_id,
    first_name + ' ' + last_name   AS full_name,
    first_name,
    last_name,
    gender,
    category,
    employment_date,
    birth_date,
    education_level
FROM dEmployee;


-- ------------------------------------------------------------
-- [4] DIMENSIÓN PRODUCTO
-- ------------------------------------------------------------
SELECT
    product_sk,
    product_id,
    detail                                         AS product_name,
    package,
    category,
    CASE WHEN is_can  = 1 THEN 'Lata' ELSE 'Botella' END AS container_type,
    CASE WHEN is_diet = 1 THEN 'Diet' ELSE 'Regular' END AS diet_type,
    volume_liters
FROM dProducts;


-- ------------------------------------------------------------
-- [5] DIMENSIÓN GRUPO ETARIO
-- ------------------------------------------------------------
SELECT
    age_group_id,
    [group]   AS age_group_name,
    min_age,
    max_age
FROM dAgeGroup;


-- ------------------------------------------------------------
-- [6] FACT - FACTURACIÓN (hBilling + todas las dimensiones aplanadas)
-- Tabla principal para análisis de ventas
-- ------------------------------------------------------------
SELECT
    b.billing_sk,
    b.billing_id,

    -- Tiempo
    b.date,
    d.year,
    d.month,
    d.month_name,
    d.trimester,
    d.semester,
    d.weekday_name,
    d.holiday,

    -- Geografía / Sucursal
    b.region,
    b.branch_id,

    -- Cliente
    b.customer_sk,
    c.first_name + ' ' + c.last_name   AS customer_name,
    c.city                              AS customer_city,
    c.state                             AS customer_state,
    CASE WHEN c.is_retail = 1 THEN 'Retail' ELSE 'Mayorista' END AS customer_type,
    b.customer_age,
    ag.[group]                          AS customer_age_group,

    -- Empleado
    b.employee_sk,
    e.first_name + ' ' + e.last_name   AS employee_name,
    e.category                          AS employee_category,
    e.gender                            AS employee_gender,
    b.employee_age,
    b.employee_seniority,

    -- Métricas financieras
    b.subtotal,
    b.discount_percentage,
    b.discount_amount,
    b.final_billing,
    b.volume_sold_liters

FROM hBilling b
LEFT JOIN dDate     d  ON b.date                  = d.date
LEFT JOIN dCustomer c  ON b.customer_sk           = c.customer_sk
LEFT JOIN dAgeGroup ag ON b.customer_age_group_id = ag.age_group_id
LEFT JOIN dEmployee e  ON b.employee_sk           = e.employee_sk;


-- ------------------------------------------------------------
-- [7] FACT - DETALLE DE FACTURA (línea por producto)
-- Unir con [6] por billing_sk para análisis a nivel producto
-- ------------------------------------------------------------
SELECT
    bd.detail_sk,
    bd.billing_sk,

    -- Producto
    bd.product_sk,
    p.detail        AS product_name,
    p.category      AS product_category,
    p.package,
    CASE WHEN p.is_can  = 1 THEN 'Lata' ELSE 'Botella' END AS container_type,
    CASE WHEN p.is_diet = 1 THEN 'Diet' ELSE 'Regular' END AS diet_type,
    p.volume_liters,

    -- Métricas de línea
    bd.unit_price,
    bd.quantity,
    bd.unit_price * bd.quantity                                     AS line_total,
    bd.quantity   * p.volume_liters                                 AS volume_line_liters

FROM hBillingDetail bd
LEFT JOIN dProducts p ON bd.product_sk = p.product_sk;


-- ------------------------------------------------------------
-- [8] FACT - STOCK POR PRODUCTO Y FECHA
-- ------------------------------------------------------------
SELECT
    s.stock_sk,
    s.product_sk,
    p.detail        AS product_name,
    p.category      AS product_category,
    p.package,
    CASE WHEN p.is_can  = 1 THEN 'Lata' ELSE 'Botella' END AS container_type,

    -- Fecha
    s.date,
    d.year,
    d.month,
    d.month_name,
    d.trimester,

    -- Métrica
    s.variation

FROM hStock s
LEFT JOIN dProducts p ON s.product_sk         = p.product_sk
LEFT JOIN dDate     d ON CAST(s.date AS DATE) = d.date;


-- ============================================================
-- CONSULTAS ANALÍTICAS PRECALCULADAS
-- Importar como tablas separadas o usar como vistas
-- ============================================================

-- ------------------------------------------------------------
-- [A] VENTAS MENSUALES AGREGADAS
-- ------------------------------------------------------------
SELECT
    d.year,
    d.trimester,
    d.semester,
    d.month,
    d.month_name,
    COUNT(DISTINCT b.billing_id)  AS total_invoices,
    SUM(b.subtotal)               AS total_subtotal,
    SUM(b.discount_amount)        AS total_discount,
    SUM(b.final_billing)          AS total_revenue,
    SUM(b.volume_sold_liters)     AS total_liters,
    AVG(b.final_billing)          AS avg_invoice_value
FROM hBilling b
JOIN dDate d ON b.date = d.date
GROUP BY d.year, d.trimester, d.semester, d.month, d.month_name
ORDER BY d.year, d.month;


-- ------------------------------------------------------------
-- [B] VENTAS POR REGIÓN Y SUCURSAL
-- ------------------------------------------------------------
SELECT
    b.region,
    b.branch_id,
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT b.billing_id)  AS total_invoices,
    SUM(b.final_billing)          AS total_revenue,
    SUM(b.volume_sold_liters)     AS total_liters
FROM hBilling b
JOIN dDate d ON b.date = d.date
GROUP BY b.region, b.branch_id, d.year, d.month, d.month_name
ORDER BY b.region, b.branch_id, d.year, d.month;


-- ------------------------------------------------------------
-- [C] VENTAS POR CATEGORÍA DE PRODUCTO
-- ------------------------------------------------------------
SELECT
    p.category,
    CASE WHEN p.is_diet = 1 THEN 'Diet' ELSE 'Regular' END AS diet_type,
    CASE WHEN p.is_can  = 1 THEN 'Lata' ELSE 'Botella' END AS container_type,
    d.year,
    d.month,
    SUM(bd.quantity)                        AS units_sold,
    SUM(bd.unit_price * bd.quantity)        AS total_line_revenue,
    SUM(bd.quantity * p.volume_liters)      AS total_liters
FROM hBillingDetail bd
JOIN hBilling  b  ON bd.billing_sk = b.billing_sk
JOIN dProducts p  ON bd.product_sk = p.product_sk
JOIN dDate     d  ON b.date        = d.date
GROUP BY
    p.category,
    p.is_diet,
    p.is_can,
    d.year,
    d.month
ORDER BY d.year, d.month, p.category;


-- ------------------------------------------------------------
-- [D] RANKING DE PRODUCTOS MÁS VENDIDOS (por ingresos)
-- ------------------------------------------------------------
SELECT
    p.product_sk,
    p.detail                                AS product_name,
    p.category,
    p.package,
    SUM(bd.quantity)                        AS units_sold,
    SUM(bd.unit_price * bd.quantity)        AS total_revenue,
    SUM(bd.quantity * p.volume_liters)      AS total_liters,
    RANK() OVER (ORDER BY SUM(bd.unit_price * bd.quantity) DESC) AS revenue_rank
FROM hBillingDetail bd
JOIN dProducts p ON bd.product_sk = p.product_sk
GROUP BY p.product_sk, p.detail, p.category, p.package, p.volume_liters
ORDER BY revenue_rank;


-- ------------------------------------------------------------
-- [E] ANÁLISIS DE CLIENTES (RFM simplificado)
-- ------------------------------------------------------------
SELECT
    c.customer_sk,
    c.customer_id,
    c.first_name + ' ' + c.last_name        AS customer_name,
    c.city,
    c.state,
    CASE WHEN c.is_retail = 1 THEN 'Retail' ELSE 'Mayorista' END AS customer_type,
    COUNT(DISTINCT b.billing_id)             AS total_invoices,
    SUM(b.final_billing)                     AS total_spent,
    AVG(b.final_billing)                     AS avg_invoice,
    MAX(b.date)                              AS last_purchase_date,
    MIN(b.date)                              AS first_purchase_date,
    DATEDIFF(DAY, MAX(b.date), GETDATE())    AS days_since_last_purchase
FROM hBilling b
JOIN dCustomer c ON b.customer_sk = c.customer_sk
GROUP BY
    c.customer_sk, c.customer_id, c.first_name, c.last_name,
    c.city, c.state, c.is_retail
ORDER BY total_spent DESC;


-- ------------------------------------------------------------
-- [F] RENDIMIENTO DE EMPLEADOS
-- ------------------------------------------------------------
SELECT
    e.employee_sk,
    e.employee_id,
    e.first_name + ' ' + e.last_name   AS employee_name,
    e.category,
    e.gender,
    e.education_level,
    COUNT(DISTINCT b.billing_id)        AS total_invoices,
    SUM(b.final_billing)                AS total_revenue,
    SUM(b.discount_amount)              AS total_discounts_given,
    AVG(b.discount_percentage)          AS avg_discount_pct,
    AVG(b.final_billing)                AS avg_invoice_value,
    SUM(b.volume_sold_liters)           AS total_liters
FROM hBilling b
JOIN dEmployee e ON b.employee_sk = e.employee_sk
GROUP BY
    e.employee_sk, e.employee_id, e.first_name, e.last_name,
    e.category, e.gender, e.education_level
ORDER BY total_revenue DESC;


-- ------------------------------------------------------------
-- [G] VENTAS POR GRUPO ETARIO DE CLIENTE
-- ------------------------------------------------------------
SELECT
    ag.[group]                            AS age_group,
    ag.min_age,
    ag.max_age,
    CASE WHEN c.is_retail = 1 THEN 'Retail' ELSE 'Mayorista' END AS customer_type,
    d.year,
    COUNT(DISTINCT b.billing_id)           AS total_invoices,
    SUM(b.final_billing)                   AS total_revenue,
    AVG(b.final_billing)                   AS avg_invoice
FROM hBilling b
JOIN dDate     d  ON b.date                  = d.date
JOIN dAgeGroup ag ON b.customer_age_group_id = ag.age_group_id
JOIN dCustomer c  ON b.customer_sk           = c.customer_sk
GROUP BY ag.[group], ag.min_age, ag.max_age, c.is_retail, d.year
ORDER BY d.year, ag.min_age;


-- ------------------------------------------------------------
-- [H] STOCK ACUMULADO POR PRODUCTO (útil para KPI de inventario)
-- ------------------------------------------------------------
SELECT
    p.product_sk,
    p.detail      AS product_name,
    p.category,
    p.package,
    d.year,
    d.month,
    d.month_name,
    SUM(s.variation)   AS monthly_variation,
    SUM(SUM(s.variation)) OVER (
        PARTITION BY p.product_sk
        ORDER BY d.year, d.month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )              AS cumulative_stock
FROM hStock s
JOIN dProducts p  ON s.product_sk         = p.product_sk
JOIN dDate     d  ON CAST(s.date AS DATE) = d.date
GROUP BY p.product_sk, p.detail, p.category, p.package, d.year, d.month, d.month_name
ORDER BY p.product_sk, d.year, d.month;


-- ------------------------------------------------------------
-- [I] ANÁLISIS DE DESCUENTOS POR REGIÓN Y PERÍODO
-- ------------------------------------------------------------
SELECT
    b.region,
    d.year,
    d.month,
    d.month_name,
    COUNT(CASE WHEN b.discount_percentage > 0 THEN 1 END)   AS invoices_with_discount,
    COUNT(b.billing_id)                                       AS total_invoices,
    CAST(COUNT(CASE WHEN b.discount_percentage > 0 THEN 1 END) * 100.0
         / NULLIF(COUNT(b.billing_id), 0) AS DECIMAL(5,2))   AS discount_rate_pct,
    SUM(b.discount_amount)                                    AS total_discount_amount,
    SUM(b.subtotal)                                           AS total_subtotal,
    SUM(b.final_billing)                                      AS total_revenue
FROM hBilling b
JOIN dDate d ON b.date = d.date
GROUP BY b.region, d.year, d.month, d.month_name
ORDER BY b.region, d.year, d.month;
