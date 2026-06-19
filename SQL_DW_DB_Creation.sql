-- ============================================================
-- THE DRINKING COMPANY - DATA WAREHOUSE
-- Creación de tablas: Dimensiones y Hechos
-- Motor: SQL Server
-- ============================================================

USE TDC_DataWarehouse;  
GO

-- ============================================================
-- TABLAS DE DIMENSIONES
-- Se crean primero porque las tablas de hechos las referencian
-- ============================================================

-- ------------------------------------------------------------
-- dDate: Dimensión Tiempo
-- ------------------------------------------------------------
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

    CONSTRAINT PK_dDate PRIMARY KEY (date)
);
GO

-- ------------------------------------------------------------
-- dCustomer: Dimensión Cliente
-- ------------------------------------------------------------
CREATE TABLE dCustomer (
	customer_sk	  INT IDENTITY(1,1) NOT NULL,
    customer_id   INT           NOT NULL,
    first_name    NVARCHAR(100) NOT NULL,
    last_name     NVARCHAR(100) NOT NULL,
    birth_date    DATE          NULL,
    city          NVARCHAR(100) NULL,
    state         NVARCHAR(100) NULL,
    zipcode       NVARCHAR(20)  NULL,
	is_retail	  BIT           NULL,

    CONSTRAINT PK_dCustomer PRIMARY KEY (customer_sk)
);
GO

-- ------------------------------------------------------------
-- dEmployee: Dimensión Empleado
-- ------------------------------------------------------------
CREATE TABLE dEmployee (
	employee_sk		 INT IDENTITY(1,1) NOT NULL,
    employee_id      INT           NOT NULL,
    first_name       NVARCHAR(100) NOT NULL,
    last_name        NVARCHAR(100) NOT NULL,
    gender           NVARCHAR(10)  NULL,
    category         NVARCHAR(100) NULL,
    employment_date  DATE          NULL,
    birth_date       DATE          NULL,
    education_level  NVARCHAR(50)  NULL,

    CONSTRAINT PK_dEmployee PRIMARY KEY (employee_sk)
);
GO

-- ------------------------------------------------------------
-- dAgeGroup: Dimensión Grupo Etario
-- ------------------------------------------------------------
CREATE TABLE dAgeGroup (
    age_group_id  INT IDENTITY(1,1) NOT NULL,
    [group]       NVARCHAR(25)  NOT NULL,
    min_age       INT           NOT NULL,
    max_age       INT           NOT NULL,

    CONSTRAINT PK_dAgeGroup PRIMARY KEY (age_group_id)
);
GO

-- ------------------------------------------------------------
-- dProducts: Dimensión Productos
-- Incluye atributos desnormalizados (package, category, is_can,
-- is_diet, volume_liters) tal como está en el diagrama
-- ------------------------------------------------------------
CREATE TABLE dProducts (
	product_sk	   INT IDENTITY(1,1) NOT NULL,
    product_id     INT           NOT NULL,
    detail         VARCHAR(200)  NOT NULL,
    package        VARCHAR(100)  NULL,
    category       VARCHAR(15)  NULL,
    is_can         BIT           NOT NULL DEFAULT 0,
    is_diet        BIT           NOT NULL DEFAULT 0,
    volume_liters  DECIMAL(3,2)  NULL,

    CONSTRAINT PK_dProducts PRIMARY KEY (product_sk)
);
GO

-- ============================================================
-- TABLAS DE HECHOS
-- Se crean después de las dimensiones
-- ============================================================

-- ------------------------------------------------------------
-- hBilling: Tabla de Hechos principal de Facturación
-- Granularidad: una fila por factura
-- ------------------------------------------------------------
CREATE TABLE hBilling (
	billing_sk			   INT IDENTITY(1,1) NOT NULL,
    billing_id             INT            NOT NULL,
    date                   DATE           NOT NULL,      -- FK -> dDate
    date_t                 DATETIME       NULL,
    region                 NVARCHAR(7)    NULL,
    branch_id              INT            NULL,
    customer_sk            INT            NULL,          -- FK -> dCustomer
    customer_age           INT            NULL,
    customer_age_group_id  INT            NULL,          -- FK -> dAgeGroup
    employee_sk            INT            NULL,          -- FK -> dEmployee
    employee_age           INT            NULL,
    employee_seniority     INT            NULL,
	employee_gender		   VARCHAR(10)    NULL,
    subtotal               DECIMAL(7,2)   NULL,
    discount_percentage    INT            NULL,
    discount_amount        DECIMAL(7,2)   NULL,
    final_billing          DECIMAL(7,2)   NULL,
    volume_sold_liters     DECIMAL(6,2)   NULL,

    CONSTRAINT PK_hBilling PRIMARY KEY (billing_sk),

    CONSTRAINT FK_hBilling_dDate
        FOREIGN KEY (date) REFERENCES dDate (date),

    CONSTRAINT FK_hBilling_dCustomer
        FOREIGN KEY (customer_sk) REFERENCES dCustomer (customer_sk),

    CONSTRAINT FK_hBilling_dAgeGroup
        FOREIGN KEY (customer_age_group_id) REFERENCES dAgeGroup (age_group_id),

    CONSTRAINT FK_hBilling_dEmployee
        FOREIGN KEY (employee_sk) REFERENCES dEmployee (employee_sk)
);
GO

-- ------------------------------------------------------------
-- hBillingDetail: Tabla de Hechos de Detalle de Factura
-- Granularidad: una fila por producto dentro de cada factura
-- PK compuesta: (billing_id, product_id)
-- ------------------------------------------------------------
CREATE TABLE hBillingDetail (
	detail_sk	  INT IDENTITY(1,1) NOT NULL,
    billing_sk    INT           NOT NULL,   -- FK -> hBilling
    product_sk    INT           NOT NULL,   -- FK -> dProducts
    unit_price    DECIMAL(7,2)  NULL,
    quantity      INT           NULL,

    CONSTRAINT PK_hBillingDetail PRIMARY KEY (detail_sk),

    CONSTRAINT FK_hBillingDetail_hBilling
        FOREIGN KEY (billing_sk) REFERENCES hBilling (billing_sk),

    CONSTRAINT FK_hBillingDetail_dProducts
        FOREIGN KEY (product_sk) REFERENCES dProducts (product_sk)
);
GO

-- ------------------------------------------------------------
-- hStock: Tabla de Hechos de Stock
-- Granularidad: una fila por producto y fecha de movimiento
-- PK compuesta: (product_id, date)
-- ------------------------------------------------------------
CREATE TABLE hStock (
	stock_sk	INT IDENTITY(1,1) NOT NULL,
    product_sk  INT       NOT NULL,   -- FK -> dProducts
    date        DATE      NOT NULL,   -- FK -> dDate (cast a DATE al hacer join) 
    date_t      DATETIME  NULL,    
    variation   INT       NULL,

    CONSTRAINT PK_hStock PRIMARY KEY (stock_sk),

    CONSTRAINT FK_hStock_dProducts
        FOREIGN KEY (product_sk) REFERENCES dProducts (product_sk),
		
    CONSTRAINT FK_hStock_dDate
        FOREIGN KEY (date) REFERENCES dDate (date)

    -- NOTA: date en hStock es DATETIME (con hora), mientras que dDate.date es DATE.
    -- Por eso NO se agrega FK directa a dDate aquí.
    -- En el ETL se hace el join casteando: CAST(hStock.date AS DATE).
);
GO

-- ============================================================
-- VERIFICACIÓN: listar tablas creadas
-- ============================================================
SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;
GO