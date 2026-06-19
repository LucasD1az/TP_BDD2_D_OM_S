
Table "dDate" {
  "date" DATE [not null]
  "year" INT [not null]
  "month" INT [not null]
  "day" INT [not null]
  "weekday" INT [not null]
  "month_name" NVARCHAR(20) [not null]
  "weekday_name" NVARCHAR(20) [not null]
  "trimester" INT [not null]
  "semester" INT [not null]
  "holiday" BIT [not null, default: 0]

  Indexes {
    date [pk, name: "PK_dDate"]
  }
}

Table "dCustomer" {
  "customer_sk" "INT IDENTITY(1,1)" [not null]
  "customer_id" INT [not null]
  "first_name" NVARCHAR(100) [not null]
  "last_name" NVARCHAR(100) [not null]
  "birth_date" DATE
  "city" NVARCHAR(100)
  "state" NVARCHAR(100)
  "zipcode" NVARCHAR(20)
  "is_retail" BIT

  Indexes {
    customer_sk [pk, name: "PK_dCustomer"]
  }
}

Table "dEmployee" {
  "employee_sk" "INT IDENTITY(1,1)" [not null]
  "employee_id" INT [not null]
  "first_name" NVARCHAR(100) [not null]
  "last_name" NVARCHAR(100) [not null]
  "gender" NVARCHAR(10)
  "category" NVARCHAR(100)
  "employment_date" DATE
  "birth_date" DATE
  "education_level" NVARCHAR(50)

  Indexes {
    employee_sk [pk, name: "PK_dEmployee"]
  }
}

Table "dAgeGroup" {
  "age_group_id" "INT IDENTITY(1,1)" [not null]
  "group" NVARCHAR(25) [not null]
  "min_age" INT [not null]
  "max_age" INT [not null]

  Indexes {
    age_group_id [pk, name: "PK_dAgeGroup"]
  }
}

Table "dProducts" {
  "product_sk" "INT IDENTITY(1,1)" [not null]
  "product_id" INT [not null]
  "detail" VARCHAR(200) [not null]
  "package" VARCHAR(100)
  "category" VARCHAR(15)
  "is_can" BIT [not null, default: 0]
  "is_diet" BIT [not null, default: 0]
  "volume_liters" DECIMAL(3,2)

  Indexes {
    product_sk [pk, name: "PK_dProducts"]
  }
}

Table "hBilling" {
  "billing_sk" "INT IDENTITY(1,1)" [not null]
  "billing_id" INT [not null]
  "date" DATE [not null]
  "date_t" DATETIME
  "region" NVARCHAR(7)
  "branch_id" INT
  "customer_sk" INT
  "customer_age" INT
  "customer_age_group_id" INT
  "employee_sk" INT
  "employee_age" INT
  "employee_seniority" INT
  "employee_gender" VARCHAR(10)
  "subtotal" DECIMAL(7,2)
  "discount_percentage" INT
  "discount_amount" DECIMAL(7,2)
  "final_billing" DECIMAL(7,2)
  "volume_sold_liters" DECIMAL(6,2)

  Indexes {
    billing_sk [pk, name: "PK_hBilling"]
  }
}

Table "hBillingDetail" {
  "detail_sk" "INT IDENTITY(1,1)" [not null]
  "billing_sk" INT [not null]
  "product_sk" INT [not null]
  "unit_price" DECIMAL(7,2)
  "quantity" INT

  Indexes {
    detail_sk [pk, name: "PK_hBillingDetail"]
  }
}

Table "hStock" {
  "stock_sk" "INT IDENTITY(1,1)" [not null]
  "product_sk" INT [not null]
  "date" DATE [not null]
  "date_t" DATETIME
  "variation" INT

  Indexes {
    stock_sk [pk, name: "PK_hStock"]
  }
}

Ref "FK_hBilling_dDate":"dDate"."date" < "hBilling"."date"

Ref "FK_hBilling_dCustomer":"dCustomer"."customer_sk" < "hBilling"."customer_sk"

Ref "FK_hBilling_dAgeGroup":"dAgeGroup"."age_group_id" < "hBilling"."customer_age_group_id"

Ref "FK_hBilling_dEmployee":"dEmployee"."employee_sk" < "hBilling"."employee_sk"

Ref "FK_hBillingDetail_hBilling":"hBilling"."billing_sk" < "hBillingDetail"."billing_sk"

Ref "FK_hBillingDetail_dProducts":"dProducts"."product_sk" < "hBillingDetail"."product_sk"

Ref "FK_hStock_dProducts":"dProducts"."product_sk" < "hStock"."product_sk"

Ref "FK_hStock_dDate":"dDate"."date" < "hStock"."date"
