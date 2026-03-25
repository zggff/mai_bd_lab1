CREATE TABLE IF NOT EXISTS dim_country (
    country_id SERIAL PRIMARY KEY,
    country VARCHAR(50) UNIQUE
);

CREATE TABLE IF NOT EXISTS dim_city (
    city_id SERIAL PRIMARY KEY,
    city VARCHAR(50),
    country_id INT REFERENCES dim_country(country_id),
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
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    birth_date date REFERENCES dim_date(date),
    email VARCHAR(100) UNIQUE,
    country_id INT REFERENCES dim_country(country_id),
    postal_code VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS dim_pet (
    pet_id SERIAL PRIMARY KEY,
    owner_id INT REFERENCES dim_customer(customer_id),
    category VARCHAR(50),
    breed VARCHAR(50),
    name VARCHAR(50),
    type VARCHAR(50),
    UNIQUE(owner_id, category, breed, name)
);

CREATE TABLE IF NOT EXISTS dim_seller (
    seller_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    country_id INT REFERENCES dim_country(country_id),
    postal_code VARCHAR(20)
);

CREATE TYPE PROD_SIZE AS ENUM('Small', 'Medium', 'Large');

CREATE TABLE IF NOT EXISTS dim_product (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    weight DECIMAL(10,2),
    color VARCHAR(30),
    size PROD_SIZE,
    brand VARCHAR(50),
    material VARCHAR(50),
    description VARCHAR(1024),
    rating DECIMAL(3,2), -- в теории могут зависить друг от друга
    reviews INT, -- возможно, что не зависят
    release_date DATE REFERENCES dim_date(date),
    expiry_date DATE REFERENCES dim_date(date)
);

CREATE TABLE IF NOT EXISTS dim_store (
    store_id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    name VARCHAR(100),
    location VARCHAR(100),
    state VARCHAR(50),
    phone VARCHAR(20),
    city_id INT REFERENCES dim_city(city_id)
);

CREATE TABLE IF NOT EXISTS dim_supplier (
    supplier_id SERIAL PRIMARY KEY,
    email VARCHAR(100) UNIQUE,
    name VARCHAR(100),
    contact VARCHAR(100) ,
    phone VARCHAR(20),
    address VARCHAR(200),
    city_id INT REFERENCES dim_city(city_id)
);



CREATE TABLE IF NOT EXISTS fact_sales (
    sale_id SERIAL PRIMARY KEY,
--    customer_id INT NOT NULL REFERENCES dim_customer(customer_id),
-- так как customer имеет уникальное поле email + у каждого питомца - один хозяин
-- но существуют питомцы со всеми одинаковыми полями, но разными хозяевами
    pet_id INT NOT NULL REFERENCES dim_pet(pet_id),
    seller_id INT NOT NULL REFERENCES dim_seller(seller_id),
    product_id INT NOT NULL REFERENCES dim_product(product_id),
    store_id INT NOT NULL REFERENCES dim_store(store_id),
    supplier_id INT NOT NULL REFERENCES dim_supplier(supplier_id),
    sale_date DATE NOT NULL REFERENCES dim_date(date),
    sale_quantity INT NOT NULL,
    sale_total_price DECIMAL(12,2) NOT NULL
);

