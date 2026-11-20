-- Customers
CREATE OR REPLACE VIEW customers AS SELECT * FROM '../data/olist/olist_customers_dataset.csv';

-- Geolocation
CREATE OR REPLACE VIEW geolocation AS SELECT * FROM '../data/olist/olist_geolocation_dataset.csv';

-- Order Items
CREATE OR REPLACE VIEW order_items AS SELECT * FROM '../data/olist/olist_order_items_dataset.csv';

-- Order Payments
CREATE OR REPLACE VIEW order_payments AS SELECT * FROM '../data/olist/olist_order_payments_dataset.csv';

-- Reviews
CREATE OR REPLACE VIEW order_reviews AS SELECT * FROM '../data/olist/olist_order_reviews_dataset.csv';

-- Orders
CREATE OR REPLACE VIEW orders AS SELECT * FROM '../data/olist/olist_orders_dataset.csv';

-- Products
CREATE OR REPLACE VIEW products AS SELECT * FROM '../data/olist/olist_products_dataset.csv';

-- Sellers
CREATE OR REPLACE VIEW sellers AS SELECT * FROM '../data/olist/olist_sellers_dataset.csv';

-- Product Category Name Translation
CREATE OR REPLACE VIEW product_category_name_translation AS SELECT * FROM '../data/olist/product_category_name_translation.csv';