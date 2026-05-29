CREATE TABLE `hBilling` (
  `billing_id` integer PRIMARY KEY,
  `date` date,
  `date_t` datetime,
  `region` varchar(7),
  `branch_id` integer,
  `customer_id` integer,
  `customer_age` integer,
  `customer_age_group_id` integer,
  `employee_id` integer,
  `employee_age` integer,
  `employee_seniority` integer,
  `subtotal` double(7,2),
  `discount_percentage` integer,
  `discount_amount` double(7,2),
  `final_billing` double(7,2),
  `volume_sold_liters` double(6,2)
);

CREATE TABLE `hBillingDetail` (
  `billing_id` integer,
  `product_id` integer,
  `unit_price` double(7,2),
  `quantity` integer,
  PRIMARY KEY (`billing_id`, `product_id`)
);

CREATE TABLE `hStock` (
  `product_id` integer,
  `date` datetime,
  `variation` integer,
  PRIMARY KEY (`product_id`, `date`)
);

CREATE TABLE `dDate` (
  `date` date PRIMARY KEY,
  `year` integer,
  `month` integer,
  `day` integer,
  `weekday` integer,
  `month_name` varchar(255),
  `weekday_name` varchar(255),
  `trimester` integer,
  `semester` integer,
  `holiday` bit
);

CREATE TABLE `dEmployee` (
  `employee_id` integer PRIMARY KEY,
  `first_name` varchar(255),
  `last_name` varchar(255),
  `gender` varchar(255),
  `category` varchar(255),
  `employment_date` date,
  `birth_date` date,
  `education_level` varchar(255)
);

CREATE TABLE `dCustomer` (
  `customer_id` integer PRIMARY KEY,
  `first_name` varchar(255),
  `last_name` varchar(255),
  `birth_date` date,
  `city` varchar(255),
  `state` varchar(255),
  `zipcode` varchar(255)
);

CREATE TABLE `dProducts` (
  `product_id` integer PRIMARY KEY,
  `detail` varchar(25),
  `package` varchar(15),
  `category` varchar(15),
  `is_can` bit,
  `is_diet` bit,
  `volume_liters` double(3,2)
);

CREATE TABLE `dAgeGroup` (
  `age_group_id` integer PRIMARY KEY,
  `group` varchar(25),
  `min_age` integer,
  `max_age` integer
);

ALTER TABLE `hBilling` ADD FOREIGN KEY (`customer_id`) REFERENCES `dCustomer` (`customer_id`);

ALTER TABLE `hBilling` ADD FOREIGN KEY (`employee_id`) REFERENCES `dEmployee` (`employee_id`);

ALTER TABLE `hBilling` ADD FOREIGN KEY (`date`) REFERENCES `dDate` (`date`);

ALTER TABLE `hBilling` ADD FOREIGN KEY (`customer_age_group_id`) REFERENCES `dAgeGroup` (`age_group_id`);

ALTER TABLE `hBillingDetail` ADD FOREIGN KEY (`product_id`) REFERENCES `dProducts` (`product_id`);

ALTER TABLE `hBillingDetail` ADD FOREIGN KEY (`billing_id`) REFERENCES `hBilling` (`billing_id`);

ALTER TABLE `hStock` ADD FOREIGN KEY (`date`) REFERENCES `dDate` (`date`);

ALTER TABLE `hStock` ADD FOREIGN KEY (`product_id`) REFERENCES `dProducts` (`product_id`);
