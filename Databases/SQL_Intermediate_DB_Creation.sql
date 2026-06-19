-- ============================================================
-- THE DRINKING COMPANY - INTERMEDIATE DB
-- Propósito: Recibir datos transformados, calcular montos 
-- y limpiar errores antes de pasar al Data Warehouse.
-- ============================================================

USE TDC_Intermediate;
GO

-- ============================================================
-- 1. TABLAS AUXILIARES PARA CÁLCULOS
-- ============================================================
CREATE TABLE Prices (
    product_id INT,
    date DATETIME,
    price DECIMAL(18,2)
);

CREATE TABLE Discounts (
    discount_id INT,
    date_from DATETIME, 
    date_until DATETIME,
    total_billing DECIMAL(18,2),
    percentage DECIMAL(5,2)
);

-- ============================================================
-- 2. TABLAS DE DIMENSIONES (Con Identidades y Miembros Especiales)
-- ============================================================

CREATE TABLE dDate (
    date          DATE         NOT NULL,
    year          INT          NOT NULL,
    month         INT          NOT NULL,
    day           INT          NOT NULL,
    weekday       INT          NOT NULL,
    month_name    NVARCHAR(20) NOT NULL,
    weekday_name  NVARCHAR(20) NOT NULL,
    trimester     INT          NOT NULL,
    semester      INT          NOT NULL,
    holiday       BIT          NOT NULL DEFAULT 0,
    CONSTRAINT PK_Intermediate_dDate PRIMARY KEY (date)
);

CREATE TABLE dCustomer (
    customer_sk   INT IDENTITY(1,1) NOT NULL,
    customer_id   INT               NOT NULL,
    first_name    NVARCHAR(100)     NOT NULL,
    last_name     NVARCHAR(100)     NOT NULL,
    birth_date    DATE              NULL,
    city          NVARCHAR(100)     NULL,
    state         NVARCHAR(100)     NULL,
    zipcode       NVARCHAR(20)      NULL,
    is_retail     BIT               NULL,
    CONSTRAINT PK_Intermediate_dCustomer PRIMARY KEY (customer_sk)
);

CREATE TABLE dEmployee (
    employee_sk      INT IDENTITY(1,1) NOT NULL,
    employee_id      INT               NOT NULL,
    first_name       NVARCHAR(100)     NOT NULL,
    last_name        NVARCHAR(100)     NOT NULL,
    gender           NVARCHAR(10)      NULL,
    category         NVARCHAR(100)     NULL,
    employment_date  DATE              NULL,
    birth_date       DATE              NULL,
    education_level  NVARCHAR(50)      NULL,
    CONSTRAINT PK_Intermediate_dEmployee PRIMARY KEY (employee_sk)
);

CREATE TABLE dAgeGroup (
    age_group_id  INT IDENTITY(1,1) NOT NULL,
    [group]       NVARCHAR(25)      NOT NULL,
    min_age       INT               NOT NULL,
    max_age       INT               NOT NULL,
    CONSTRAINT PK_Intermediate_dAgeGroup PRIMARY KEY (age_group_id)
);

CREATE TABLE dProducts (
    product_sk    INT IDENTITY(1,1) NOT NULL,
    product_id    INT               NOT NULL,
    detail        VARCHAR(200)      NOT NULL,
    package       VARCHAR(100)      NULL,
    category      VARCHAR(15)       NULL,
    is_can        BIT               NOT NULL DEFAULT 0,
    is_diet       BIT               NOT NULL DEFAULT 0,
    volume_liters DECIMAL(3,2)      NULL,
    CONSTRAINT PK_Intermediate_dProducts PRIMARY KEY (product_sk)
);


INSERT INTO dDate (date, year, month, day, weekday, month_name, weekday_name, trimester, semester, holiday)
VALUES 
('1900-01-01', 1900, 1, 1, 1, 'Fecha Nula', 'Fecha Nula', 1, 1, 0),
('1901-01-01', 1901, 1, 1, 1, 'Fecha Inconsistente', 'Fecha Inconsistente', 1, 1, 0);
GO

-- Configurar el rango de tiempo real para la empresa (Ejemplo: 2005 a 2030)
DECLARE @StartDate DATE = '2000-01-01';
DECLARE @EndDate   DATE = '2020-12-31';

DECLARE @CurrentDate DATE = @StartDate;

-- Forzar que las funciones de texto devuelvan nombres en Español
SET LANGUAGE Spanish;

-- Bucle de generación de fechas
WHILE @CurrentDate <= @EndDate
BEGIN
    INSERT INTO dDate (date, year, month, day, weekday, month_name, weekday_name, trimester, semester)
    SELECT 
        @CurrentDate,
        YEAR(@CurrentDate) AS [year],
        MONTH(@CurrentDate) AS [month],
        DAY(@CurrentDate) AS [day],
        DATEPART(WEEKDAY, @CurrentDate) AS [weekday],
        DATENAME(MONTH, @CurrentDate) AS [month_name],
        DATENAME(WEEKDAY, @CurrentDate) AS [weekday_name],
        DATEPART(QUARTER, @CurrentDate) AS [trimester], -- Retorna de 1 a 4
        CASE WHEN MONTH(@CurrentDate) <= 6 THEN 1 ELSE 2 END AS [semester];

    -- Avanzar al día siguiente
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END;
GO

INSERT INTO dCustomer (customer_id, first_name, last_name, birth_date, city, state, zipcode)
VALUES 
(-1, 'Cliente', 'Nulo', NULL, NULL, NULL, NULL),
(-2, 'Cliente', 'Inconsistente / Error', NULL, NULL, NULL, NULL),
(-3, 'Cliente', 'No Registrado', NULL, NULL, NULL, NULL);

INSERT INTO dEmployee (employee_id, first_name, last_name, gender, category, employment_date, birth_date, education_level)
VALUES 
(-1, 'Empleado', 'Nulo', NULL, NULL, NULL, NULL, NULL),
(-2, 'Empleado', 'Inconsistente / Error', NULL, NULL, NULL, NULL, NULL),
(-3, 'Empleado', 'No Registrado', NULL, NULL, NULL, NULL, NULL);

INSERT INTO dAgeGroup ([group], min_age, max_age)
VALUES
('Adolescentes', 13, 19),
('Adultos medios', 40, 50),
('Edad del gerente', 66, 66);
GO

INSERT INTO dProducts(product_id, detail, package, category, is_can, is_diet, volume_liters)
VALUES 
(-1, 'Producto nulo', NULL, NULL, 0, 0, NULL),
(-2, 'Producto inconsistente/erróneo', NULL, NULL, 0, 0, NULL),
(-3, 'Producto no registrado', NULL, NULL, 0, 0, NULL);

-- ============================================================
-- 3. TABLAS DE HECHOS (Sin Foreign Keys)
-- ============================================================

CREATE TABLE hBilling (
    billing_sk             INT IDENTITY(1,1) NOT NULL,
    billing_id             INT               NOT NULL,
    date                   DATE              NOT NULL,
    date_t                 DATETIME          NULL,
    region                 NVARCHAR(7)       NULL,
    branch_id              INT               NULL,
    customer_sk            INT               NULL,
    customer_age           INT               NULL,
    customer_age_group_id  INT               NULL,
    employee_sk            INT               NULL,
    employee_age           INT               NULL,
    employee_seniority     INT               NULL,
	employee_gender		   VARCHAR(10)		 NULL,
    subtotal               DECIMAL(7,2)      NULL,
    discount_percentage    INT               NULL,
    discount_amount        DECIMAL(7,2)      NULL,
    final_billing          DECIMAL(7,2)      NULL,
    volume_sold_liters     DECIMAL(6,2)      NULL,
    CONSTRAINT PK_Intermediate_hBilling PRIMARY KEY (billing_sk)
);

CREATE TABLE hBillingDetail (
    detail_sk     INT IDENTITY(1,1) NOT NULL,
    billing_sk    INT               NOT NULL,
    product_sk    INT               NOT NULL,
    unit_price    DECIMAL(7,2)      NULL,
    quantity      INT               NULL,
    CONSTRAINT PK_Intermediate_hBillingDetail PRIMARY KEY (detail_sk)
);

CREATE TABLE hStock (
    stock_sk      INT IDENTITY(1,1) NOT NULL,
    product_sk    INT               NOT NULL,
    date          DATE              NOT NULL,  
    date_t        DATETIME          NULL,     
    variation     INT               NULL,
    CONSTRAINT PK_Intermediate_hStock PRIMARY KEY (stock_sk)
);


-- ------------------------------------------------------------
-- dCustomer_error
-- ------------------------------------------------------------
CREATE TABLE dCustomer_error (

    customer_id   VARCHAR(100) NOT NULL,
    first_name    NVARCHAR(100) NULL,
    last_name     NVARCHAR(100) NULL,
    birth_date    NVARCHAR(100) NULL,
    city          NVARCHAR(100) NULL,
    state         NVARCHAR(100) NULL,
    zipcode       NVARCHAR(100) NULL,
	is_retail	  NVARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_dCustomer_error PRIMARY KEY (customer_id, error_timestamp)
);
GO

-- ------------------------------------------------------------
-- dEmployee_error
-- ------------------------------------------------------------
CREATE TABLE dEmployee_error (

    employee_id      VARCHAR(100) NOT NULL,
    first_name       NVARCHAR(100) NULL,
    last_name        NVARCHAR(100) NULL,
    gender           NVARCHAR(100) NULL,
    category         NVARCHAR(100) NULL,
    employment_date  NVARCHAR(100) NULL,
    birth_date       NVARCHAR(100) NULL,
    education_level  NVARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_dEmployee_error PRIMARY KEY (employee_id, error_timestamp)
);
GO

-- ------------------------------------------------------------
-- dProducts_error
-- ------------------------------------------------------------
CREATE TABLE dProducts_error (

    product_id     VARCHAR(100) NOT NULL,
    detail         VARCHAR(100) NULL,
    package        VARCHAR(100) NULL,
    category       VARCHAR(100) NULL,
    is_can         VARCHAR(100) NULL,
    is_diet        VARCHAR(100) NULL,
    volume_liters  VARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_dProducts_error PRIMARY KEY (product_id, error_timestamp)
);
GO


-- ============================================================
-- TABLAS DE HECHOS _error
-- ============================================================

-- ------------------------------------------------------------
-- hBilling_error
-- ------------------------------------------------------------
CREATE TABLE hBilling_error (

    billing_id             VARCHAR(100) NOT NULL,
    date                   VARCHAR(100) NULL,
    date_t                 VARCHAR(100) NULL,
    region                 VARCHAR(100) NULL,
    branch_id              VARCHAR(100) NULL,
    customer_id            VARCHAR(100) NULL,
    customer_age           VARCHAR(100) NULL,
    customer_age_group_id  VARCHAR(100) NULL,
    employee_id            VARCHAR(100) NULL,
    employee_age           VARCHAR(100) NULL,
    employee_seniority     VARCHAR(100) NULL,
    subtotal               VARCHAR(100) NULL,
    discount_percentage    VARCHAR(100) NULL,
    discount_amount        VARCHAR(100) NULL,
    final_billing          VARCHAR(100) NULL,
    volume_sold_liters     VARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_hBilling_error PRIMARY KEY (billing_id, error_timestamp)
);
GO

-- ------------------------------------------------------------
-- hBillingDetail_error
-- ------------------------------------------------------------
CREATE TABLE hBillingDetail_error (

    billing_id   VARCHAR(100) NOT NULL,
    product_id   VARCHAR(100) NOT NULL,
    unit_price   VARCHAR(100) NULL,
    quantity     VARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_hBillingDetail_error PRIMARY KEY (billing_id, product_id, error_timestamp)
);
GO

-- ------------------------------------------------------------
-- hStock_error
-- ------------------------------------------------------------
CREATE TABLE hStock_error (

    product_id  VARCHAR(100) NOT NULL,
    date        VARCHAR(100) NOT NULL,
    date_t      VARCHAR(100) NULL,     
    variation   VARCHAR(100) NULL,

    error_column       VARCHAR(100)  NULL,
    error_description  VARCHAR(500)  NULL,
    error_timestamp    DATETIME      NOT NULL DEFAULT GETDATE(),

    -- CONSTRAINT PK_hStock_error PRIMARY KEY (product_id, date, error_timestamp)
);
GO

-- ============================================================
-- VERIFICACIÓN: listar todas las tablas (originales + error)
-- ============================================================
SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO


-- ============================================================
-- EJEMPLO DE USO: cómo insertar un error desde el ETL / SP
-- ============================================================
--
-- Supongamos que el ETL intenta insertar en dDate la fecha
-- '13-13-2026' (mes 13 no existe). En lugar de fallar,
-- redirige la fila a dDate_error:
--
-- INSERT INTO dDate_error
--     (date, year, month, day, weekday, month_name,
--      weekday_name, trimester, semester, holiday,
--      error_column, error_description)
-- VALUES
--     ('13-13-2026', '2026', '13', '13', NULL, NULL,
--      NULL, NULL, NULL, NULL,
--      'date',
--      'Valor de fecha inválido: mes 13 no existe. Valor recibido: 13-13-2026');
--
-- ============================================================

