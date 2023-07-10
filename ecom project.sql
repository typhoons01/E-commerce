DROP TABLE IF EXISTS coupons;
DROP TABLE IF EXISTS payment;
DROP TABLE IF EXISTS shipping;
DROP TABLE IF EXISTS cart;
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS product;
DROP TABLE IF EXISTS customer_payment_info;
DROP TABLE IF EXISTS customer_address;
DROP TABLE IF EXISTS customer;


CREATE TABLE customer (
    id binary(16) PRIMARY KEY,
    username varchar(255) NOT NULL UNIQUE,
    email varchar(255) NOT NULL,
    password varchar(255) NOT NULL
);


CREATE TABLE customer_address (
    customer_id binary(16),
    home_number varchar(255) NOT NULL,
    street varchar(255) NOT NULL,
    city varchar(255) NOT NULL,
    state varchar(255) NOT NULL,
    zip_code INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);


CREATE TABLE customer_payment_info (
   id int NOT NULL PRIMARY KEY AUTO_INCREMENT,
   customer_id binary(16) NOT NULL,
   card_number varchar(255) NOT NULL,
   card_holder_name varchar(255) NOT NULL,
   expiration_date date NOT NULL,
   cvv int NOT NULL,
   FOREIGN KEY (customer_id) REFERENCES customer(id)
);


CREATE TABLE product (
    id int PRIMARY KEY AUTO_INCREMENT,
    name varchar(255) NOT NULL,
    description varchar(255) NOT NULL,
    price decimal(10,2) NOT NULL,
    quantity int NOT NULL CHECK (quantity >= 0),
    category enum ('electronics', 'clothes', 'books', 'furniture', 'sports', 'toys', 'others') NOT NULL,
    discount decimal(10, 2) NOT NULL
);


CREATE TABLE cart (
    id int PRIMARY KEY AUTO_INCREMENT,
    customer_id binary(16) NOT NULL,
    product_id int NOT NULL,
    quantity int NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);


CREATE TABLE orders (
    id int PRIMARY KEY AUTO_INCREMENT,
    customer_id binary(16) NOT NULL,
    amount decimal(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id)
);


CREATE TABLE order_details (
    id int PRIMARY KEY AUTO_INCREMENT,
    order_id int NOT NULL,
    product_id int NOT NULL,
    quantity int NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);


CREATE TABLE shipping (
    id int PRIMARY KEY AUTO_INCREMENT,
    order_id int NOT NULL,
    shipping_method enum('standard', 'express') NOT NULL,
    stat enum('pending', 'shipping', 'delivered', 'refunded', 'cancelled') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE TABLE payment (
    id int PRIMARY KEY AUTO_INCREMENT,
    order_id int NOT NULL,
    payment_method enum ('cash on delivery', 'credit card', 'paypal') NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id)
);


CREATE TABLE review (
    id int PRIMARY KEY AUTO_INCREMENT,
    customer_id binary(16) NOT NULL,
    product_id int NOT NULL,
    rating int NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment varchar(255) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customer(id),
    FOREIGN KEY (product_id) REFERENCES product(id)
);


CREATE TABLE coupons (
    code char(8) PRIMARY KEY,
    valid_till timestamp NOT NULL,
    discount decimal(10, 2) NOT NULL
);

DROP PROCEDURE IF EXISTS add_customer;
delimiter #
CREATE PROCEDURE add_customer(
    username varchar(255),
    email varchar(255),
    password varchar(255),
    state varchar(255),
    city varchar(255),
    street varchar(255),
    home_number varchar(255),
    zip_code int,
    card_number varchar(255),
    card_holder_name varchar(255),
    expiration_date date,
    cvv int
)
BEGIN
   SET @cid = UUID_TO_BIN(UUID());
   INSERT INTO customer (id, username, email, password)
   VALUES (@cid, username, email, password);
   INSERT INTO customer_address (customer_id, state, city, street, home_number, zip_code)
   VALUES (@cid, state, city, street, home_number, zip_code);
   INSERT INTO customer_payment_info (customer_id, card_number, card_holder_name, expiration_date, cvv)
   VALUES (@cid, card_number, card_holder_name, expiration_date, cvv);
END#
delimiter ;

DROP PROCEDURE IF EXISTS login;
delimiter #
CREATE PROCEDURE login(
    name varchar(255),
    pass varchar(255),
    out cid binary(16)
)
BEGIN
    SELECT id INTO cid FROM customer WHERE username = name AND password = pass;
END#
delimiter ;


DROP PROCEDURE IF EXISTS browse_category;
delimiter #
CREATE PROCEDURE browse_category(
    cat varchar(255)
)
BEGIN
    SELECT * FROM product WHERE category = cat;
END#
delimiter ;


DROP PROCEDURE IF EXISTS get_similar_products;
delimiter #
CREATE PROCEDURE get_similar_products(
    product_id int
)
BEGIN
    SELECT * FROM product WHERE category = (SELECT category FROM product WHERE id = product_id);
END#
delimiter ;


DROP PROCEDURE IF EXISTS track_order;
delimiter #
CREATE PROCEDURE track_order(
    orderid int
)
BEGIN
    SELECT * FROM shipping WHERE order_id = orderid;
END#
delimiter ;


DROP PROCEDURE IF EXISTS get_products_on_sale;
delimiter #
CREATE PROCEDURE get_products_on_sale()
BEGIN
    SELECT * FROM product WHERE discount > 0;
END#
delimiter ;

DROP PROCEDURE IF EXISTS add_to_cart;
delimiter #
CREATE PROCEDURE add_to_cart(
    cid binary(16),
    pid int,
    quant int
)
BEGIN
    -- if already exists in cart then change quantity
    IF EXISTS (SELECT * FROM cart WHERE customer_id = cid AND product_id = pid) THEN
        UPDATE cart SET quantity = quantity + quant WHERE customer_id = cid AND product_id = pid;
    ELSE
        INSERT INTO cart (customer_id, product_id, quantity)
        VALUES (cid, pid, quant);
    END IF;
END#
delimiter ;


DROP PROCEDURE IF EXISTS leave_review;
delimiter #
CREATE PROCEDURE leave_review(
    customer_id binary(16),
    product_id int,
    rating int,
    comment varchar(255)
)
BEGIN
    INSERT INTO review (customer_id, product_id, rating, comment)
    VALUES (customer_id, product_id, rating, comment);
END#
delimiter ;


DROP PROCEDURE IF EXISTS change_quantity;
delimiter #
CREATE PROCEDURE change_quantity(
    cid binary(16),
    pid int,
    quantity int
)
BEGIN
    UPDATE cart SET quantity = quantity WHERE customer_id = cid AND product_id = pid;
END#
delimiter ;


DROP PROCEDURE IF EXISTS get_trending_products;
delimiter #
CREATE PROCEDURE get_trending_products()
BEGIN
    SELECT name, description, price, discount, AVG(rating) FROM review
    JOIN product ON product.id = product_id
    GROUP BY product_id
    ORDER BY AVG(rating) DESC;
END#
delimiter ;


DROP PROCEDURE IF EXISTS change_shipping_address;
delimiter #
CREATE PROCEDURE change_shipping_address(
   cid binary(16),
   home_number varchar(255),
   street varchar(255),
   city varchar(255),
   state varchar(255),
   zipcode int
)
BEGIN
   UPDATE customer_address SET home_number=home_number, street=street, city=city, state=state, zip_code=zipcode WHERE customer_id=cid;
END#
delimiter ;


DROP PROCEDURE IF EXISTS change_payment_info;
delimiter #
CREATE PROCEDURE change_payment_info(
   cid binary(16),
   card_number varchar(255),
   card_holder_name varchar(255),
   expiration_date date,
   cvv int
)
BEGIN
   UPDATE customer_payment_info SET card_number=card_number, card_holder_name=card_holder_name, expiration_date=expiration_date, cvv=cvv WHERE customer_id=cid;
END#
delimiter ;

DROP PROCEDURE IF EXISTS change_shipping_status;
delimiter #
CREATE PROCEDURE change_shipping_status(
    order_id int,
    st enum ('pending', 'shipping', 'delivered', 'refunded', 'cancelled')
)
BEGIN
    UPDATE shipping SET stat = st WHERE order_id = order_id;
END#
delimiter ;

DROP PROCEDURE IF EXISTS get_order_history;
delimiter #
CREATE PROCEDURE get_order_history(
    cid binary(16)
)
BEGIN
    SELECT * FROM orders WHERE customer_id = cid;
END#
delimiter ;

DROP PROCEDURE IF EXISTS place_order;
delimiter #
CREATE PROCEDURE place_order(
    cid binary(16),
    payment_method enum ('credit card', 'paypal', 'cash on delivery'),
    shipping_method enum ('standard', 'express')
)
BEGIN
    START TRANSACTION;
        INSERT INTO orders (customer_id, amount)
        VALUES (cid, (SELECT SUM((SELECT price * (1 - discount) FROM product WHERE id = cart.product_id) * quantity) FROM cart WHERE customer_id = cid));
        SET @order_id = LAST_INSERT_ID();

        INSERT INTO order_details (order_id, product_id, quantity)
        SELECT @order_id, product_id, quantity
        FROM cart
        WHERE customer_id = cid;

        INSERT INTO shipping (order_id, shipping_method, stat)
        VALUES (@order_id, shipping_method, 'pending');

        INSERT INTO payment (order_id, payment_method)
        VALUES (@order_id, payment_method);

        UPDATE product
        SET quantity = quantity - (SELECT quantity FROM cart WHERE customer_id = cid AND product_id = product.id)
        WHERE id IN (SELECT product_id FROM cart WHERE customer_id = cid);

        DELETE FROM cart WHERE customer_id = cid;
    COMMIT;
END#
delimiter ;

DROP PROCEDURE IF EXISTS place_order_with_coupon;
delimiter #
CREATE PROCEDURE place_order_with_coupon(
    cid binary(16),
    payment_method enum ('credit card', 'paypal', 'cash on delivery'),
    shipping_method enum ('standard', 'express'),
    coupon char(8)
)
BEGIN
    CALL place_order(cid, payment_method, shipping_method);
    UPDATE orders
    SET amount=amount * (1 - (SELECT discount
    FROM coupons WHERE code=coupon AND NOW() <= valid_till))
    WHERE customer_id=cid AND id=LAST_INSERT_ID();
END#
delimiter ;

DROP PROCEDURE IF EXISTS get_products_purchased_together;
delimiter #
CREATE PROCEDURE get_products_purchased_together(
    pid int
)
BEGIN
    SELECT name, price, category, COUNT(*) AS count FROM order_details
    INNER JOIN product ON product.id = product_id
    WHERE order_id IN (SELECT order_id FROM order_details WHERE product_id = pid)
    AND product_id != pid
    GROUP BY product_id
    ORDER BY count DESC;
END#
delimiter ;

DROP PROCEDURE IF EXISTS cancel_order;
delimiter #
CREATE PROCEDURE cancel_order(
    orderid int
)
BEGIN
    UPDATE shipping SET stat='cancelled' WHERE order_id=orderid AND (stat='pending' OR stat='shipping');
    UPDATE product p
    INNER JOIN order_details od ON p.id = od.product_id
    SET p.quantity = p.quantity + od.quantity
    WHERE od.order_id = orderid;
END#
delimiter ;

DROP PROCEDURE IF EXISTS refund_order;
delimiter #
CREATE PROCEDURE refund_order(
    orderid int
)
BEGIN
    UPDATE shipping SET stat='refunded' WHERE order_id=orderid AND (stat='pending' OR stat='shipping' OR stat='delivered');
    UPDATE product p
    INNER JOIN order_details od ON p.id = od.product_id
    SET p.quantity = p.quantity + od.quantity
    WHERE od.order_id = orderid;
END#
delimiter ;

-- add customers
    CALL add_customer('John Smith', 'johnsmith@gmail.com', 'J0hnSmi7hP@$$', 'California', 'Los Angeles', 'Main St', '123', 90001, '1234567812345678', 'John Smith', '2025-01-01', 123);
    CALL add_customer('Jane Doe', 'janedoe@gmail.com', 'Jan3DoeP@$$', 'New York', 'New York City', 'Broadway', '456', 10001, '5678567856785678', 'Jane Doe', '2026-02-01', 456);
    CALL add_customer('Bob Johnson', 'bobjohnson@gmail.com', 'B0bJ0hnsonP@$$', 'Texas', 'Houston', 'Washington Ave', '789', 77002, '9012901290129012', 'Bob Johnson', '2027-03-01', 789);
    CALL add_customer('Mary Williams', 'marywilliams@gmail.com', 'M@ryWilli4msP@$$', 'Florida', 'Miami', 'Collins Ave', '1011', 33139, '1010101010101010', 'Mary Williams', '2028-04-01', 101);
    CALL add_customer('Tom Davis', 'tomdavis@gmail.com', 'T0mD@visP@$$', 'Illinois', 'Chicago', 'State St', '1213', 60602, '1212121212121212', 'Tom Davis', '2029-05-01', 121);
    CALL add_customer('Sarah Brown', 'sarahbrown@gmail.com', 'S@r@hBr0wnP@$$', 'Georgia', 'Atlanta', 'Peachtree St', '1415', 30303, '1414141414141414', 'Sarah Brown', '2030-06-01', 141);
    CALL add_customer('David Lee', 'davidlee@gmail.com', 'D@vidL33P@$$', 'North Carolina', 'Raleigh', 'Fayetteville St', '1617', 27601, '1616161616161616', 'David Lee', '2031-07-01', 161);
    CALL add_customer('Ava Jackson', 'avajackson@gmail.com', 'Av@J@cks0nP@$$', 'Michigan', 'Detroit', 'Woodward Ave', '1819', 48201, '1818181818181818', 'Ava Jackson', '2032-08-01', 181);
    CALL add_customer('Kevin Wilson', 'kevinwilson@gmail.com', 'K3vinWils0nP@$$', 'Ohio', 'Columbus', 'High St', '2021', 43215, '2020202020202020', 'Kevin Wilson', '2033-09-01', 202);
    CALL add_customer('Olivia Garcia', 'oliviagarcia@gmail.com', '0liv!@G@rci@P@$$', 'Arizona', 'Phoenix', 'Central Ave', '2223', 85004, '2222222222222222', 'Olivia Garcia', '2034-10-01', 222);
    CALL add_customer('Michael Johnson', 'michaeljohnson@gmail.com', 'M1ch@elJ0hnsonP@$$', 'New Jersey', 'Jersey City', 'Newark Ave', '345', 07306, '3456345634563456', 'Michael Johnson', '2025-01-01', 123);
    CALL add_customer('Emily Taylor', 'emilytaylor@gmail.com', 'Em!lyT@yl0rP@$$', 'Texas', 'Dallas', 'Main St', '678', 75201, '6789678967896789', 'Emily Taylor', '2026-02-01', 456);
    CALL add_customer('William Martinez', 'williammartinez@gmail.com', 'W!ll!amM@rt!nezP@$$', 'California', 'San Francisco', 'Market St', '910', 94103, '9101910191019101', 'William Martinez', '2027-03-01', 789);
    CALL add_customer('Grace Hernandez', 'gracehernandez@gmail.com', 'Gr@ceH3rn@nd3zP@$$', 'Florida', 'Orlando', 'Orange Ave', '1112', 32801, '1111111111111111', 'Grace Hernandez', '2028-04-01', 101);
    CALL add_customer('James Brown', 'jamesbrown@gmail.com', 'J@m3sBr0wnP@$$', 'Illinois', 'Springfield', 'Adams St', '1314', 62701, '1313131313131313', 'James Brown', '2029-05-01', 121);

-- add products
INSERT INTO product (name, description, price, quantity, category, discount) VALUES 
    ('Apple iPhone 12 Pro Max', '6.7 inch Super Retina XDR display', 1099, 1000, 'electronics', 0.1),
    ('Samsung Galaxy S21 Ultra', '6.8 inch Dynamic AMOLED 2X display', 1199, 1000, 'electronics', 0.05),
    ('Sony PlayStation 5', 'Ultra-High-Speed SSD, Tempest 3D AudioTech', 499, 1000, 'electronics', 0),
    ('Nintendo Switch', 'Handheld mode and TV mode', 299, 1000, 'electronics', 0.15),
    ('Nike Air Zoom Pegasus 38', 'Running Shoes', 120, 1000, 'clothes', 0.2),
    ('Adidas Ultraboost 21', 'Running Shoes', 180, 1000, 'clothes', 0.1),
    ('The Hunger Games Box Set', 'Suzanne Collins', 50, 1000, 'books', 0.3),
    ('IKEA MALM Bed Frame', 'Queen Size Bed Frame', 399, 1000, 'furniture', 0),
    ('Spalding NBA Zi/O Indoor Basketball', 'Official NBA size and weight', 29, 1000, 'sports', 0.05),
    ('LEGO Star Wars Imperial Star Destroyer', '4784 pieces', 699, 1000, 'toys', 0.1),
    ('Chia Pet Golden Girls Rose', 'Decorative planter', 15, 1000, 'others', 0.25),
    ('Apple MacBook Pro 16-inch', '16-inch Retina Display, 8-Core CPU', 2399, 1000, 'electronics', 0.1),
    ('Sony WH-1000XM4 Wireless Headphones', 'Noise Canceling Headphones', 349, 1000, 'electronics', 0.05),
    ('Kindle Paperwhite', 'Waterproof, 8GB storage', 129, 1000, 'electronics', 0),
    ('Canon EOS R6 Mirrorless Camera', '20.1 Megapixel, 4K Video', 2499, 1000, 'electronics', 0),
    ("Levi's 501 Original Fit Jeans", 'Straight Leg Jeans', 59, 1000, 'clothes', 0.2),
    ('Nike Dri-FIT Academy Soccer Pants', 'Dri-FIT technology, tapered design', 45, 1000, 'clothes', 0.1),
    ('To Kill a Mockingbird', 'Harper Lee', 10, 1000, 'books', 0.25),
    ('IKEA BILLY Bookcase', '5 shelves, height extension unit available', 79, 1000, 'furniture', 0),
    ('Spalding NBA Street Basketball', 'Intermediate size and weight', 19, 1000, 'sports', 0.1),
    ('Barbie Dreamhouse', '3 stories, 8 rooms, elevator', 199, 1000, 'toys', 0),
    ('Succulent Plants', 'Set of 4', 25, 1000, 'others', 0.3),
    ('Apple Watch Series 6', 'GPS + Cellular, Always-On Retina display', 499, 1000, 'electronics', 0.05),
    ('Bose QuietComfort 35 II Wireless Headphones', 'Noise Canceling Headphones', 299, 1000, 'electronics', 0),
    ('Fitbit Charge 4', 'GPS, Heart Rate and Sleep Monitor', 149, 1000, 'electronics', 0.1),
    ('Dell XPS 13 Laptop', '13.4 inch FHD+ InfinityEdge Touch Display', 1199, 1000, 'electronics', 0.05),
    ("Calvin Klein Men\'s Cotton Classics Multipack Boxer Briefs", 'Pack of 3', 39, 1000, 'clothes', 0.2),
    ('Lululemon Align Leggings', 'High-rise, buttery soft fabric', 98, 1000, 'clothes', 0.15),
    ('The Lord of the Rings Boxed Set', 'J.R.R. Tolkien', 60, 1000, 'books', 0.3),
    ('IKEA POÄNG Armchair', 'Soft, durable and easy care leather', 199, 110005, 'furniture', 0),
    ('Wilson NFL MVP Junior Football', 'Junior size and weight', 15, 1000, 'sports', 0.1),
    ('LEGO Architecture Statue of Liberty', '1685 pieces', 119, 1000, 'toys', 0.2),
    ('Wine Tumbler with Lid', '12 oz Double Wall Vacuum Insulated', 20, 1000, 'others', 0.25),
    ("The North Face Men\'s Resolve Waterproof Jacket", 'Breathable and lightweight', 90, 1000, 'clothes', 0),
    ('Adidas Ultraboost 21 Running Shoes', 'Responsive Boost midsole, Primeblue', 180, 1000, 'clothes', 0),
    ('Harry Potter Box Set: The Complete Collection', 'J.K. Rowling', 70, 1000, 'books', 0.2),
    ('IKEA HEMNES 8-drawer Dresser', 'Solid wood, black-brown', 299, 1000, 'furniture', 0),
    ('Spalding NBA Zi/O Indoor/Outdoor Basketball', 'Official size and weight', 39, 1000, 'sports', 0),
    ('LEGO Star Wars Millennium Falcon', '7541 pieces', 799, 1000, 'toys', 0.3),
    ('Fruit Infuser Water Bottle', '32oz Leak Proof Flip Top Lid', 15, 1000, 'others', 0.15);

-- add coupons
INSERT INTO coupons(code, discount, valid_till) VALUES
    ('WELCME10', 0.1, '2025-12-31'),
    ('WELCME20', 0.2, '2025-12-31'),
    ('WELCME30', 0.3, '2025-12-31'),
    ('WELCME40', 0.4, '2025-12-31'),
    ('WELCME50', 0.5, '2025-12-31'),
    ('WELCME60', 0.6, '2025-12-31'),
    ('WELCME70', 0.7, '2025-12-31'),
    ('WELCME80', 0.8, '2025-12-31'),
    ('WELCME90', 0.9, '2025-12-31'),
    ('WELCME11', 0.95, '2025-12-31');

-- add reviews
DROP PROCEDURE IF EXISTS generate_random_reviews;
delimiter #
CREATE PROCEDURE generate_random_reviews()
BEGIN
    SET @i = 0;
    WHILE(@i < 100) DO

    INSERT INTO review(customer_id, product_id, rating, comment) VALUES
        ((SELECT id FROM customer ORDER BY RAND() LIMIT 1),
        (SELECT id FROM product ORDER BY RAND() LIMIT 1),
        FLOOR(RAND() * 5) + 1,
        CASE
            WHEN RAND() < 0.2 THEN 'Great product!'
            WHEN RAND() < 0.4 THEN 'Excellent quality!'
            WHEN RAND() < 0.6 THEN 'Good value for money!'
            WHEN RAND() < 0.8 THEN 'Fast shipping!'
            ELSE 'Satisfied with the purchase.'
        END
    );
    SET @i = @i + 1;
    END WHILE;
END#
delimiter ;
CALL generate_random_reviews();

-- add orders
DROP PROCEDURE IF EXISTS generate_random_orders;
delimiter #
CREATE PROCEDURE generate_random_orders()
BEGIN
    SET @i = 0;
    WHILE(@i < 20) DO

    SET @id = (SELECT id FROM customer ORDER BY RAND() LIMIT 1);
    CALL add_to_cart(
        @id, (SELECT id FROM product ORDER BY RAND() LIMIT 1), FLOOR(RAND() * 3) + 1
    );
    CALL add_to_cart(
        @id, (SELECT id FROM product ORDER BY RAND() LIMIT 1), FLOOR(RAND() * 3) + 1
    );
    CALL add_to_cart(
        @id, (SELECT id FROM product ORDER BY RAND() LIMIT 1), FLOOR(RAND() * 3) + 1
    );
    CALL place_order(@id,
        CASE
            WHEN RAND() < 0.5 THEN 'credit card'
            ELSE 'paypal'
        END,
        CASE
            WHEN RAND() < 0.5 THEN 'standard'
            ELSE 'express'
        END
    );
    SET @i = @i + 1;
    END WHILE;
END#
delimiter ;
CALL generate_random_orders();


CALL add_customer(
    'Evelyn Perez', 'evelynperez@gmail.com', '3v3lynP3r3zP@$$',
    'California', 'San Diego', 'Broadway', '4344', 92101, '4343434343434343', 'Evelyn Perez', '2044-08-01', 424
);
SELECT * FROM customer;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL change_shipping_address(@id, '4344', 'Seattle', 'Broadway', 'Washington', 92101);
SELECT * FROM customer_address;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL change_payment_info(@id, '4343434343434343', 'Evelyn Perez', '2044-08-01', 424);
SELECT * FROM customer_payment_info;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL add_to_cart(@id, 1, 2);
SELECT * FROM cart;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL change_quantity(@id, 1, 3);
SELECT * FROM cart;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL place_order(@id, 'credit card', 'standard');

SELECT * FROM cart;
SELECT * FROM orders;

CALL cancel_order(21);
CALL track_order(21);

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL add_to_cart(@id, 1, 2);
CALL place_order_with_coupon(@id, 'credit card', 'standard', 'WELCME90');
SELECT * FROM order_details;

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL get_order_history(@id);

CALL login("Evelyn Perez", "3v3lynP3r3zP@$$", @id);
CALL leave_review(@id, 1, 5, 'Great product!');
SELECT * FROM review;


CALL change_shipping_status(21, 'delivered');
CALL refund_order(21);
CALL track_order(21);

CALL get_products_on_sale();
CALL get_trending_products();
CALL browse_category('clothes');
SELECT * FROM product WHERE id = 1;
CALL get_similar_products(1);
CALL get_products_purchased_together(1);
