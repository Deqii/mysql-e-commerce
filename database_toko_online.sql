CREATE DATABASE toko_online;
USE toko_online;

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  phone VARCHAR(30),
  address TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  category_id INT,
  name VARCHAR(200) NOT NULL,
  price INT NOT NULL DEFAULT 0,
  stock INT NOT NULL DEFAULT 0,
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  order_status ENUM('pending','paid','completed','cancelled') DEFAULT 'pending',
  total_amount INT NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id INT NOT NULL,
  product_id INT NOT NULL,
  quantity INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price INT NOT NULL DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_orderitems_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- DROP TABLE users

CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','staff','customer') DEFAULT 'staff',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

ALTER TABLE users
    ADD COLUMN email VARCHAR(150);

CREATE TABLE audit_logs (
  log_id INT  AUTO_INCREMENT PRIMARY KEY,
  action VARCHAR(50),
  table_name VARCHAR(50),
  record_id VARCHAR(100),
  description TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO customers (full_name, email, phone, address) VALUES
  ('Tio Prayuda', 'tio@gmail.com', '081234567890', 'Bandung, Jawa Barat'),
  ('John Doe', 'john@gmail.com', '082345678901', 'Jakarta, Jawa Barat');

INSERT INTO categories (name, description) VALUES
  ('Elektronik', 'Gadget & aksesori'),
  ('Pakaian', 'Baju pria & wanita'),
  ('Rumah Tangga', 'Peralatan rumah');

INSERT INTO products (category_id, name, price, stock, description) VALUES
  (1, 'Smartphone Z1', 3500000, 25, 'Smartphone layar 6.5 inch'),
  (1, 'Headphone BassPro', 450000, 100, 'Headphone wireless'),
  (2, 'Kaos Polos Putih', 75000, 200, 'Kaos katun 100%'),
  (3, 'Set Panci 3pcs', 250000, 40, 'Set panci anti lengket');

INSERT INTO orders (customer_id, order_status) VALUES
  (1, 'pending'),
  (2, 'paid');

SELECT * FROM products;

UPDATE products 
SET price = 100000,
    stock = stock + 10,
    updated_at = NOW()
WHERE name = 'Kaos Polos Putih';

DELETE FROM orders WHERE order_id = 999;

SELECT product_id, name, stock FROM products WHERE stock < 50 ORDER BY stock ASC;

CREATE USER 'web_tio'@'localhost' IDENTIFIED BY '123456';
GRANT SELECT, INSERT, UPDATE, DELETE ON toko_online.* TO 'web_tio'@'localhost';

-- REVOKE DELETE ON toko_online.* FROM 'web_tio'@'localhost'

-- View order summary
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
  o.order_id,
  o.customer_id,
  c.full_name AS customer_name,
  o.order_status,
  o.total_amount,
  o.created_at
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id;

-- FUNCTION total order
DELIMITER $$
CREATE FUNCTION fn_calc_order_total_int(p_order_id INT) RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
  DECLARE v_total INT DEFAULT 0;
  SELECT IFNULL(SUM(quantity * unit_price), 0) INTO v_total
  FROM order_items
  WHERE order_id = p_order_id;
  RETURN v_total;
END $$
DELIMITER ;

-- TRIGGER setelah insert order
DELIMITER $$
CREATE TRIGGER trg_orders_after_insert
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
  INSERT INTO audit_logs (action, table_name, record_id, description)
  VALUES ('INSERT', 'orders', CAST(NEW.order_id AS CHAR), CONCAT('Order dibuat, status=', NEW.order_status));
END $$
DELIMITER ;

SELECT 
  p.product_id,
  p.name AS product_name,
  c.name AS category_name,
  p.price,
  p.stock
FROM products AS p
INNER JOIN categories AS c ON p.category_id = c.category_id
ORDER BY c.name, p.name;

