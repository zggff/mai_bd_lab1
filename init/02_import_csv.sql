CREATE TABLE raw_data (
    sale_id SERIAL PRIMARY KEY,
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

DO $$
DECLARE
    i INT;
BEGIN
    FOR i IN 0..9 LOOP
        EXECUTE format('
            COPY raw_data (
                id, customer_first_name, customer_last_name, customer_age,
                customer_email, customer_country, customer_postal_code,
                customer_pet_type, customer_pet_name, customer_pet_breed,
                seller_first_name, seller_last_name, seller_email,
                seller_country, seller_postal_code, product_name,
                product_category, product_price, product_quantity, sale_date,
                sale_customer_id, sale_seller_id, sale_product_id, sale_quantity,
                sale_total_price, store_name, store_location, store_city,
                store_state, store_country, store_phone, store_email,
                pet_category, product_weight, product_color, product_size,
                product_brand, product_material, product_description,
                product_rating, product_reviews, product_release_date,
                product_expiry_date, supplier_name, supplier_contact,
                supplier_email, supplier_phone, supplier_address,
                supplier_city, supplier_country
            )
            FROM ''/docker-entrypoint-initdb.d/raw_data/MOCK_DATA (%1$s).csv''
            DELIMITER '',''
            CSV HEADER;
        ', i);
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


INSERT INTO dim_city (city)
SELECT DISTINCT value FROM (
    SELECT t.store_city AS value FROM raw_data t
    UNION ALL
    SELECT t.supplier_city FROM raw_data t
) ON CONFLICT (city) DO NOTHING;


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


INSERT INTO dim_seller (
    first_name, 
    last_name, 
    email, 
    country_id, 
    postal_code)
SELECT DISTINCT
	t.seller_first_name,
	t.seller_last_name,
	t.seller_email,
	c.country_id,
	t.seller_postal_code 
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.seller_country 
ON CONFLICT (email) DO NOTHING;


INSERT INTO dim_pet(
	category,
	breed,
	name,
	type)
SELECT
t.pet_category,
t.customer_pet_breed,
t.customer_pet_name,
t.customer_pet_type
FROM raw_data t
ON CONFLICT (category, breed, name) DO NOTHING;


INSERT INTO dim_customer (
    first_name, 
    last_name, 
    age,
    email, 
    country_id, 
    postal_code,
    pet_id)
SELECT DISTINCT
	t.customer_first_name,
	t.customer_last_name,
	t.customer_age,
	t.customer_email,
	c.country_id,
	t.customer_postal_code,
    pet.pet_id
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.customer_country 
LEFT JOIN dim_pet pet 
	ON  pet.category = t.pet_category
	AND pet.breed = t.customer_pet_breed
	AND pet.name = t.customer_pet_name
	AND pet.type = t.customer_pet_type

ON CONFLICT (email) DO NOTHING;


INSERT INTO dim_product (
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
SELECT DISTINCT
	t.product_name,
	t.product_category,
	t.product_price,
	t.product_weight,
	t.product_color,
	t.product_size,
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
    country_id,
    phone,
    email)
SELECT
	t.store_name,
	t.store_location,
	t.store_state,
	cc.city_id,
	c.country_id,
	t.store_phone,
	t.store_email 
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.store_country 
LEFT JOIN dim_city cc ON cc.city = t.store_city 
ON CONFLICT (email) DO NOTHING;


INSERT INTO dim_supplier (
	name,
	contact,
	email,
	phone,
	address,
	city_id,
	country_id)
SELECT
	t.supplier_name ,
	t.supplier_contact ,
	t.supplier_email ,
	t.supplier_phone ,
	t.supplier_address ,
	cc.city_id,
	c.country_id
FROM raw_data t
LEFT JOIN dim_country c ON c.country = t.supplier_country 
LEFT JOIN dim_city cc ON cc.city = t.supplier_city 
ON CONFLICT (email) DO NOTHING;


INSERT INTO fact_sales (
    sale_id,
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
    t.sale_id,
	sc.customer_id,
    ss.seller_id,
	prod.product_id,
	ds.store_id,
	ds2.supplier_id,
	t.sale_date,
	t.sale_quantity,
	t.sale_total_price
FROM raw_data t
LEFT JOIN dim_customer sc ON sc.email = t.customer_email 
LEFT JOIN dim_seller ss ON ss.email = t.seller_email 
LEFT JOIN dim_product prod 
    ON prod.price = t.product_price 
    AND prod.brand = t.product_brand
    AND prod.weight = t.product_weight
LEFT JOIN dim_store ds ON ds.email = t.store_email 
LEFT JOIN dim_supplier ds2 ON ds2.email = t.supplier_email 
ON CONFLICT (sale_id) DO NOTHING;
