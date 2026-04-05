CREATE TABLE IF NOT EXISTS dim_country (
    id SERIAL PRIMARY KEY,
    country VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_city (
    id SERIAL PRIMARY KEY,
    city VARCHAR(50),
    country_id INT REFERENCES dim_country(id),
    UNIQUE(city, country_id)
);

-- существует как в примере по ссылке 
CREATE TABLE IF NOT EXISTS dim_date (
    date DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    quarter INT
);

CREATE TABLE IF NOT EXISTS dim_customer (
    id INT PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    birth_date date REFERENCES dim_date(date),
    email VARCHAR,
    country_id INT REFERENCES dim_country(id),
    postal_code VARCHAR,
    pet_type VARCHAR,
    pet_breed VARCHAR,
    pet_name VARCHAR
);

CREATE TABLE IF NOT EXISTS dim_seller (
    id INT PRIMARY KEY,
    first_name VARCHAR,
    last_name VARCHAR,
    email VARCHAR,
    country_id INT REFERENCES dim_country(id),
    postal_code VARCHAR
);

CREATE TYPE PROD_SIZE AS ENUM('Small', 'Medium', 'Large');

CREATE TABLE IF NOT EXISTS dim_product (
    id INT PRIMARY KEY,
    name VARCHAR,
    category VARCHAR,
    price DECIMAL,
    weight DECIMAL,
    color VARCHAR,
    size PROD_SIZE,
    brand VARCHAR,
    material VARCHAR,
    description VARCHAR,
    rating DECIMAL, -- в теории могут зависить друг от друга
    reviews INT, -- возможно, что не зависят
    release_date DATE REFERENCES dim_date(date),
    expiry_date DATE REFERENCES dim_date(date)
);

CREATE TABLE IF NOT EXISTS dim_store (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    name VARCHAR,
    location VARCHAR,
    state VARCHAR,
    phone VARCHAR,
    city_id INT REFERENCES dim_city(id)
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    id SERIAL PRIMARY KEY,
    email VARCHAR UNIQUE,
    name VARCHAR,
    contact VARCHAR ,
    phone VARCHAR,
    address VARCHAR,
    city_id INT REFERENCES dim_city(id)
);



CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES dim_customer(id),
    seller_id INT NOT NULL REFERENCES dim_seller(id),
    product_id INT NOT NULL REFERENCES dim_product(id),
    store_id INT NOT NULL REFERENCES dim_store(id),
    supplier_id INT NOT NULL REFERENCES dim_supplier(id),
    sale_date DATE NOT NULL REFERENCES dim_date(date),
    sale_quantity INT NOT NULL,
    sale_total_price DECIMAL(12,2) NOT NULL,
    pet_category VARCHAR
);

