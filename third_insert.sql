INSERT INTO site_user (email, password_hash, phone, is_active)
SELECT 
    CONCAT(external_user_id, '@amazon.com') AS email,
    CONCAT('hash_', external_user_id) AS password_hash,
    NULL AS phone,
    1 AS is_active
FROM amazon_main
WHERE external_user_id IS NOT NULL
GROUP BY external_user_id;


INSERT INTO product_category (category_name)
SELECT DISTINCT category
FROM amazon_main
WHERE category IS NOT NULL;


INSERT INTO product (category_id, product_name,
            about_product, rating, rating_count, img_link, product_link)
SELECT 
    pc.category_id,
    am.product_name,
    LEFT(am.about_product, 4000) AS about_product, 
    am.rating,
    am.rating_count,
    LEFT(am.img_link, 1000) AS img_link,
    LEFT(am.product_link, 1000) AS product_link
FROM amazon_main am
LEFT JOIN product_category pc ON am.category = pc.category_name
GROUP BY 
    am.product_id, am.product_name, am.about_product, am.rating, 
    am.rating_count, am.img_link, am.product_link, pc.category_id;


INSERT INTO product_item (product_id, sku, qty_in_stock, unit_price)
SELECT 
    p.product_id,
    CONCAT(am.product_id, '-', ROW_NUMBER() OVER (PARTITION BY am.product_id ORDER BY am.actual_price)) AS sku, 
    10 AS qty_in_stock, 
    am.actual_price AS unit_price
FROM amazon_main am
JOIN product p ON am.product_name = p.product_name;


INSERT INTO user_review (external_review_id, user_id, product_id, review_title, 
                         review_content, external_user_id, is_verified_purchase, created_at)
SELECT 
    am.review_id AS external_review_id,
    su.user_id,
    p.product_id,
    LEFT(am.review_title, 500) AS review_title,
    LEFT(am.review_content, 4000) AS review_content,
    am.external_user_id,
    am.is_verified_purchase,
    am.created_at
FROM amazon_main am
JOIN site_user su ON am.external_user_id =  REPLACE(su.email COLLATE SQL_Latin1_General_CP1_CI_AS, '@amazon.com', '')
JOIN product p ON am.product_name = p.product_name;






INSERT INTO shopping_cart (user_id)
SELECT DISTINCT user_id
FROM site_user;


INSERT INTO shopping_cart_item (cart_id, product_item_id, quantity)
SELECT 
    sc.cart_id,
    pi.product_item_id,
    ABS(CHECKSUM(NEWID())) % 5 + 1 AS quantity 
FROM shopping_cart sc
CROSS JOIN (
    SELECT TOP 3 product_item_id 
    FROM product_item 
    ORDER BY NEWID()
) pi; 


INSERT INTO shipping_method (name, price, estimated_days, is_active)
VALUES
    ('Standard Shipping', 4.99, '3-5 business days', 1),
    ('Express Shipping', 9.99, '1-2 business days', 1),
    ('Next Day Delivery', 19.99, 'Next business day', 1);


INSERT INTO payment_type (value, is_active)
VALUES
    ('Credit Card', 1),
    ('PayPal', 1),
    ('Amazon Pay', 1),
    ('Apple Pay', 1);


INSERT INTO user_payment_method (user_id, payment_type_id, provider, account_number, expiry_date, is_default)
SELECT user_id, payment_type_id, provider, account_number, expiry_date, is_default
FROM (
    SELECT 
        su.user_id,
        pt.payment_type_id,
        CASE pt.value 
            WHEN 'Credit Card' THEN 'VISA'
            WHEN 'PayPal' THEN 'PayPal'
            ELSE pt.value 
        END AS provider,
        CONCAT('****-****-****-', RIGHT(CONCAT('0000', su.user_id), 4)) AS account_number,
        DATEADD(YEAR, 1, GETDATE()) AS expiry_date,
        1 AS is_default,
        ROW_NUMBER() OVER (PARTITION BY su.user_id ORDER BY NEWID()) AS rn
    FROM site_user su
    CROSS JOIN payment_type pt
    WHERE pt.value IN ('Credit Card', 'PayPal')
) t
WHERE rn = 1;


INSERT INTO order_status (status_name, description)
VALUES
    ('Pending', 'Order received, awaiting payment'),
    ('Processing', 'Payment confirmed, preparing for shipment'),
    ('Shipped', 'Order shipped to customer'),
    ('Delivered', 'Order delivered successfully'),
    ('Cancelled', 'Order cancelled by user or system');


WITH cte AS (
SELECT 
    su.user_id,
    ROW_NUMBER() OVER (PARTITION BY su.user_id ORDER BY NEWID()) AS rn,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()) AS order_date,
    upm.user_payment_id AS payment_method_id,
    sm.shipping_method_id,
    ROUND((ABS(CHECKSUM(NEWID())) % 500) + 49.99, 2) AS order_total,
    os.status_id
FROM site_user su
LEFT JOIN user_payment_method upm ON su.user_id = upm.user_id
CROSS JOIN shipping_method sm
CROSS JOIN order_status os
WHERE os.status_name IN ('Delivered', 'Shipped', 'Processing')
)
INSERT INTO shop_order (user_id, order_number, order_date, payment_method_id, 
                       shipping_method_id, order_total, status_id)
SELECT user_id, CONCAT('ORD-', FORMAT(GETDATE(), 'yyyyMMdd'), '-', user_id, '-', rn) AS order_number, order_date, payment_method_id, shipping_method_id, order_total, status_id
FROM cte
WHERE rn <= 2;