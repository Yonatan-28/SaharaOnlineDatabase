CREATE database Sahara;

-- add amazon_fixed table from the csv file

CREATE TABLE Tem(
    product_id NVARCHAR(50),
    user_id NVARCHAR(50)
);

INSERT INTO Tem(product_id, user_id)
VALUES 
('B0BMVWKZ8G', 'AFDCKNT7PKHIXJGOE5KTS2T543DQ'),
('B0BMVWKZ8G', 'AG77NL56ZZCL5IZXNPYYVIMOGNHA'),
('B0117H7GZ6', 'AH3DPBR7M2QD4UAT3SOYSFP4WTAQ'),
('B0141EZMAI', 'AHWQK2QNBGWHI7PRLYLJLBEE5LVA'),
('B09MT84WV5', 'AHDNZMNGM6UT4M2VPRPLZ7EBWCOQ'),
('B08CF3B7N1', 'AHDNZMNGM6UT4M2VPRPLZ7EBWCOQ'),
('B071Z8M4KX', 'AEPIRPEEOWBOSQVYCEWRUCZJFSAQ'),
('B086Q3QMFS', 'AFVP63GD2YFUXERJWKNLUY3NZSKQ'),
('B00N1U9AJS', 'AGFEBW3IPRHJNCKQUJTJQ2GBB3RQ'),
('B0B9BXKBC7', 'AFI2AGCYNXV2A3SKAJRTFFX65HFQ');

SELECT * FROM Tem;

CREATE TABLE amazon_main
(
    [product_id] NVARCHAR (50) NOT NULL,
    [product_name] NVARCHAR (450) NOT NULL,
    [category] NVARCHAR (200) NOT NULL,
    [actual_price] DECIMAL(10,2 ) NULL,
    [rating] DECIMAL(3,2) NULL,
    [rating_count] INT NULL,
    [about_product] NVARCHAR (MAX) NOT NULL,
    [user_id] NVARCHAR (50) NOT NULL,
    [user_name] NVARCHAR (100) NOT NULL,
    [review_id] NVARCHAR (100) NOT NULL,
    [review_title] NVARCHAR (200) NOT NULL,
    [review_content] NVARCHAR (MAX) NOT NULL,
    [img_link] NVARCHAR (700) NOT NULL,
    [product_link] NVARCHAR (MAX) NOT NULL,
    [is_verified_purchase] BIT DEFAULT 0, -- Added
    [created_at] DATETIME2 DEFAULT SYSUTCDATETIME(),
    [external_user_id] NVARCHAR(100) NULL,
);



WITH user_ids   AS(
    SELECT LTRIM(RTRIM(value)) AS user_id, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM amazon_fixed
    CROSS APPLY STRING_SPLIT(user_id, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
user_names AS(
    SELECT LTRIM(RTRIM(value)) AS user_name, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM amazon_fixed
    CROSS APPLY STRING_SPLIT(user_name, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
review_ids AS(
    SELECT LTRIM(RTRIM(value)) AS review_id, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM amazon_fixed
    CROSS APPLY STRING_SPLIT(review_id, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
review_titles AS(
    SELECT LTRIM(RTRIM(value)) AS review_title, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM amazon_fixed
    CROSS APPLY STRING_SPLIT(review_title, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
),
review_contents AS(
    SELECT LTRIM(RTRIM(value)) AS review_content, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn
    FROM amazon_fixed
    CROSS APPLY STRING_SPLIT(review_content, ',')
    WHERE LTRIM(RTRIM(value)) <> ''
)
INSERT INTO amazon_main
    (product_id, product_name, category, actual_price, rating,
    rating_count, about_product, user_id, user_name, review_id,
    review_title, review_content, img_link, product_link,
    is_verified_purchase, created_at, external_user_id)

SELECT product_id, product_name, category, actual_price, rating, rating_count,
    about_product, user_id, user_name, review_id, review_title, review_content,
    img_link, product_link,
    CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 70 THEN 1 ELSE 0 END AS is_verified_purchase,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 730, GETDATE()) AS created_at,
    user_id AS external_user_id
from (
    SELECT distinct
        a.product_id,
        a.product_name,
        a.category,
        a.actual_price,
        a.rating,
        a.rating_count,
        a.about_product,
        ui.user_id,
        un.user_name,
        ri.review_id,
        rt.review_title,
        rc.review_content,
        a.img_link,
        a.product_link
    FROM amazon_fixed a
    JOIN user_ids ui ON 1=1
    JOIN user_names un ON ui.rn = un.rn
    JOIN review_ids ri ON ui.rn = ri.rn
    JOIN review_titles rt ON ui.rn = rt.rn
    JOIN review_contents rc ON ui.rn = rc.rn
    where EXISTS (
        SELECT *
        FROM Tem t
        WHERE t.product_id = a.product_id
        -- And t.user_id = ui.user_id
        AND CHARINDEX(t.user_id, ui.user_id) > 0
    )
    -- WHERE a.product_id = 'B00N1U9AJS'
) AS sub
