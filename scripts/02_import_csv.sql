-- TODO: fix using correct product_id, seller_id, customer_id 
CREATE TABLE raw_data (
    id INT,
    customer_first_name VARCHAR,
    customer_last_name VARCHAR,
    customer_age INT,
    customer_email VARCHAR,
    customer_country VARCHAR,
    customer_postal_code VARCHAR,
    customer_pet_type VARCHAR,
    customer_pet_name VARCHAR,
    customer_pet_breed VARCHAR,
    seller_first_name VARCHAR,
    seller_last_name VARCHAR,
    seller_email VARCHAR,
    seller_country VARCHAR,
    seller_postal_code VARCHAR,
    product_name VARCHAR,
    product_category VARCHAR,
    product_price DECIMAL,
    product_quantity INT,
    sale_date DATE,
    sale_customer_id INT,
    sale_seller_id INT,
    sale_product_id INT,
    sale_quantity INT,
    sale_total_price DECIMAL,
    store_name VARCHAR,
    store_location VARCHAR,
    store_city VARCHAR,
    store_state VARCHAR,
    store_country VARCHAR,
    store_phone VARCHAR,
    store_email VARCHAR,
    pet_category VARCHAR,
    product_weight DECIMAL,
    product_color VARCHAR,
    product_size VARCHAR,
    product_brand VARCHAR,
    product_material VARCHAR,
    product_description TEXT,
    product_rating DECIMAL,
    product_reviews INT,
    product_release_date DATE,
    product_expiry_date DATE,
    supplier_name VARCHAR,
    supplier_contact VARCHAR,
    supplier_email VARCHAR,
    supplier_phone VARCHAR,
    supplier_address VARCHAR,
    supplier_city VARCHAR,
    supplier_country VARCHAR
);

CREATE TEMP TABLE staging_table AS SELECT * FROM raw_data WITH NO DATA;

DO $$
DECLARE
    i INT;
    offset_val INT;
    file_path TEXT;
BEGIN
    FOR i IN 0..9 LOOP
        offset_val := i * 1000;
        file_path := '/data/MOCK_DATA (' || i || ').csv';

        TRUNCATE staging_table;

        EXECUTE format('COPY staging_table FROM %L WITH (FORMAT csv, HEADER true)', file_path);

        UPDATE staging_table SET 
            id = id + offset_val, 
            sale_customer_id = sale_customer_id + offset_val, 
            sale_seller_id = sale_seller_id + offset_val, 
            sale_product_id = sale_product_id + offset_val;
        
        INSERT INTO raw_data SELECT * FROM staging_table;
        
        RAISE NOTICE 'Processed file %', file_path;
    END LOOP;
END $$;

INSERT INTO dim_country (country)
SELECT DISTINCT value FROM (
    SELECT t.seller_country AS value FROM raw_data t
    UNION ALL
    SELECT t.store_country FROM raw_data t
    UNION ALL
    SELECT t.supplier_country FROM raw_data t
    UNION ALL 
    SELECT t.customer_country FROM raw_data t
) ON CONFLICT (country) DO NOTHING;


INSERT INTO dim_city (city, country_id)
SELECT DISTINCT
    city,
    dc.id
FROM (
    SELECT t.store_city AS city, t.store_country AS country FROM raw_data t
    UNION ALL
    SELECT t.supplier_city AS city, t.supplier_country AS country FROM raw_data t
) AS cities
LEFT JOIN dim_country dc ON dc.country = cities.country
ON CONFLICT (city, country_id) DO NOTHING;


INSERT INTO dim_date (
	date,
	year,
	month,
	day,
	quarter)
SELECT 
	d,
	EXTRACT(YEAR FROM d),
	EXTRACT(MONTH FROM d),
	EXTRACT(DAY FROM d),
	EXTRACT(QUARTER FROM d)
FROM (
    SELECT t.product_release_date AS d FROM raw_data t
    UNION ALL
    SELECT t.product_expiry_date FROM raw_data t
    UNION ALL
    SELECT t.sale_date FROM raw_data t
) ON CONFLICT (date) DO NOTHING;

INSERT INTO dim_date (date, year, month, day, quarter)
SELECT 
    MAKE_DATE(year, 1, 1) AS date,
    year,
    1 AS month,
    1 AS day,
    1 AS quarter
FROM generate_series(1900, 2030) AS year
ON CONFLICT (date) DO NOTHING;


INSERT INTO dim_seller (
    id,
    first_name, 
    last_name, 
    email, 
    country_id, 
    postal_code)
SELECT
	t.sale_seller_id,
	t.seller_first_name,
	t.seller_last_name,
	t.seller_email,
	c.id,
	t.seller_postal_code 
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.seller_country;


INSERT INTO dim_customer (
    id,
    first_name, 
    last_name, 
    birth_date,
    email, 
    country_id, 
    postal_code,
    pet_breed,
    pet_type,
    pet_name)
SELECT
	t.sale_customer_id,
	t.customer_first_name,
	t.customer_last_name,
    DATE_TRUNC('year', 
        CURRENT_DATE - (t.customer_age || ' years')::INTERVAL)::DATE AS birth_date,
	t.customer_email,
	c.id,
	t.customer_postal_code,
    t.customer_pet_breed,
    t.customer_pet_type,
    t.customer_pet_name
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.customer_country;


INSERT INTO dim_product (
    id,
    name,
    category,
    price,
    weight,
    color,
    size,
    brand,
    material,
    description,
    rating,
    reviews,
    release_date,
    expiry_date)
SELECT
    t.sale_product_id,
	t.product_name,
	t.product_category,
	t.product_price,
	t.product_weight,
	t.product_color,
	t.product_size::PROD_SIZE,
	t.product_brand,
	t.product_material,
	t.product_description,
	t.product_rating,
	t.product_reviews,
    t.product_release_date,
    t.product_expiry_date
FROM raw_data t;

 
INSERT INTO dim_store (
    name, 
    location,
    state,
    city_id,
    phone,
    email)
SELECT
	t.store_name,
	t.store_location,
	t.store_state,
	cc.id,
	t.store_phone,
	t.store_email 
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.store_country
LEFT JOIN dim_city cc ON cc.city = t.store_city AND cc.country_id = c.id 
ON CONFLICT (email) DO NOTHING;


INSERT INTO dim_supplier (
	name,
	contact,
	email,
	phone,
	address,
	city_id)
SELECT
	t.supplier_name ,
	t.supplier_contact ,
	t.supplier_email ,
	t.supplier_phone ,
	t.supplier_address ,
	cc.id
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.supplier_country 
LEFT JOIN dim_city cc ON cc.city = t.supplier_city AND cc.country_id = c.id
ON CONFLICT (email) DO NOTHING;


INSERT INTO fact_sales (
	customer_id,
	seller_id,
	product_id,
	store_id,
	supplier_id,
	sale_date,
	sale_quantity,
	sale_total_price
)
SELECT
    t.sale_customer_id,
    t.sale_seller_id,
    t.sale_product_id,
	ds.id,
	ds2.id,
	t.sale_date,
	t.sale_quantity,
	t.sale_total_price
FROM raw_data t
LEFT JOIN dim_store ds ON ds.email = t.store_email 
LEFT JOIN dim_supplier ds2 ON ds2.email = t.supplier_email;
