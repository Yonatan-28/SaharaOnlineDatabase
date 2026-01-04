CREATE TABLE site_user (
    user_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    email          VARCHAR(255) COLLATE Latin1_General_CI_AI NOT NULL,
    password_hash  VARCHAR(500) NOT NULL,
    phone          VARCHAR(20),
    created_at     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    is_active      BIT NOT NULL DEFAULT 1,
    deleted_at     DATETIME NULL
);

CREATE INDEX idx_user_email_active
ON site_user(email)
WHERE is_active = 1;

-- PRODUCT_CATALOG 
CREATE TABLE product_category (
    category_id    INT IDENTITY(1,1) PRIMARY KEY,
    parent_category_id INT NULL,
    category_name  VARCHAR(200) NOT NULL,
    created_at     DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_category_id)
        REFERENCES product_category(category_id)
);

CREATE TABLE product (
    product_id     INT IDENTITY(1,1) PRIMARY KEY,
    category_id    INT NULL,
    product_name   VARCHAR(500) NOT NULL,
    about_product  VARCHAR(4000),
    rating         DECIMAL(3,2) NULL,
    rating_count   INT DEFAULT 0,
    img_link       VARCHAR(1000),
    product_link   VARCHAR(1000),
    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
        REFERENCES product_category(category_id)
);


CREATE TABLE product_item (
    product_item_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id     INT NOT NULL,
    sku            VARCHAR(50) UNIQUE NOT NULL,
    qty_in_stock   INT DEFAULT 0,
    unit_price DECIMAL(10,2) NULL,        
    CONSTRAINT fk_proditem_product 
        FOREIGN KEY (product_id) 
        REFERENCES product(product_id)
);

CREATE INDEX idx_product_item_price ON product_item(unit_price);


CREATE TABLE user_review (
    review_id      INT IDENTITY(1,1) PRIMARY KEY,
    external_review_id VARCHAR(100) NULL, 
    user_id        BIGINT NOT NULL,
    product_id     INT NOT NULL,
    review_title   VARCHAR(500) NULL,   
    review_content  VARCHAR(4000) NOT NULL,
    external_user_id VARCHAR(100) NULL,    
    is_verified_purchase BIT DEFAULT 0,
    created_at     DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_review_user 
        FOREIGN KEY (user_id) 
        REFERENCES site_user(user_id),
    CONSTRAINT fk_review_product 
        FOREIGN KEY (product_id) 
        REFERENCES product(product_id)
);

CREATE INDEX idx_user_review_product ON user_review(product_id);
CREATE INDEX idx_external_review_id ON user_review(external_review_id);
CREATE INDEX idx_external_user_id ON user_review(external_user_id);


-- CARTS
CREATE TABLE shopping_cart (
    cart_id        INT IDENTITY(1,1) PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    created_at     DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_shopcart_user 
        FOREIGN KEY (user_id) 
        REFERENCES site_user(user_id)
);

CREATE TABLE shopping_cart_item (
    cart_item_id   INT IDENTITY(1,1) PRIMARY KEY,
    cart_id        INT NOT NULL,
    product_item_id INT NOT NULL,
    quantity       INT NOT NULL DEFAULT 1,
    added_at       DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_shopcartitem_shopcart 
        FOREIGN KEY (cart_id) 
        REFERENCES shopping_cart(cart_id),
    CONSTRAINT fk_shopcartitem_proditem 
        FOREIGN KEY (product_item_id)
        REFERENCES product_item(product_item_id)
);


CREATE TABLE shipping_method (
    shipping_method_id INT IDENTITY(1,1) PRIMARY KEY,
    name           VARCHAR(100) NOT NULL,
    price          DECIMAL(10,2) NOT NULL,
    estimated_days VARCHAR(50),
    is_active      BIT DEFAULT 1
);

CREATE TABLE payment_type (
    payment_type_id INT IDENTITY(1,1) PRIMARY KEY,
    value          VARCHAR(100) NOT NULL,
    is_active      BIT DEFAULT 1
);

CREATE TABLE user_payment_method (
    user_payment_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    payment_type_id INT NOT NULL,
    provider       VARCHAR(100),
    account_number VARCHAR(50),
    expiry_date    DATE,
    is_default     BIT DEFAULT 0,
    created_at     DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_userpm_user 
        FOREIGN KEY (user_id) 
        REFERENCES site_user(user_id),
    CONSTRAINT fk_userpm_paytype 
        FOREIGN KEY (payment_type_id)
        REFERENCES payment_type(payment_type_id)
);


CREATE TABLE order_status (
    status_id      INT IDENTITY(1,1) PRIMARY KEY,
    status_name    VARCHAR(100) NOT NULL,
    description    VARCHAR(500)
);

CREATE TABLE shop_order (
    order_id       INT IDENTITY(1,1) PRIMARY KEY,
    user_id        BIGINT NOT NULL,
    order_number   VARCHAR(50) UNIQUE NOT NULL,
    order_date     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    payment_method_id INT,
    shipping_method_id INT,
    order_total    DECIMAL(10,2) NOT NULL,
    status_id      INT NOT NULL,
    created_at     DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT fk_shoporder_user 
        FOREIGN KEY (user_id) 
        REFERENCES site_user(user_id),
    CONSTRAINT fk_shoporder_paymethod 
        FOREIGN KEY (payment_method_id) 
        REFERENCES user_payment_method(user_payment_id),
    CONSTRAINT fk_shoporder_shipmethod 
        FOREIGN KEY (shipping_method_id)
        REFERENCES shipping_method(shipping_method_id),
    CONSTRAINT fk_shoporder_status 
        FOREIGN KEY (status_id) 
        REFERENCES order_status(status_id)
);

CREATE INDEX idx_shop_order_user ON shop_order(user_id);
CREATE INDEX idx_shop_order_date ON shop_order(order_date);
