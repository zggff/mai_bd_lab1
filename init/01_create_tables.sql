CREATE TABLE IF NOT EXISTS dim_country (
    country_id SERIAL PRIMARY KEY,
    country VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    city VARCHAR(50) UNIQUE
);


CREATE TABLE IF NOT EXISTS dim_date (
    date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    quarter INT
);

CREATE TABLE IF NOT EXISTS dim_pet (
    pet_id SERIAL PRIMARY KEY,
    category VARCHAR(50),
    breed VARCHAR(50),
    name VARCHAR(50),
    type VARCHAR(50),
    UNIQUE(category, breed, name)
);

CREATE TABLE IF NOT EXISTS dim_customer (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    age INT,
    email VARCHAR(100) UNIQUE,
    country_id INT,
    postal_code VARCHAR(20),
    pet_id INT REFERENCES dim_pet(pet_id)
);

CREATE TABLE IF NOT EXISTS dim_seller (
    seller_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    country_id INT,
    postal_code VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    weight DECIMAL(10,2),
    color VARCHAR(30),
    size VARCHAR(20),
    brand VARCHAR(50),
    material VARCHAR(50),
    description VARCHAR(1024),
    rating DECIMAL(3,2),
    reviews INT,
    release_date DATE REFERENCES dim_date(date),
    expiry_date DATE REFERENCES dim_date(date)
);

CREATE TABLE IF NOT EXISTS dim_store (
    store_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    location VARCHAR(100),
    state VARCHAR(50),
    city_id INT,
    country_id INT,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    contact VARCHAR(100) ,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    address VARCHAR(200),
    city_id INT,
    country_id INT
);



CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES dim_customer(customer_id),
    seller_id INT NOT NULL REFERENCES dim_seller(seller_id),
    product_id INT NOT NULL REFERENCES dim_product(product_id),
    store_id INT NOT NULL REFERENCES dim_store(store_id),
    supplier_id INT NOT NULL REFERENCES dim_supplier(supplier_id),
    sale_date DATE NOT NULL REFERENCES dim_date(date),
    sale_quantity INT NOT NULL,
    sale_total_price DECIMAL(12,2) NOT NULL
);

