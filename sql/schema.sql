DROP TABLE IF EXISTS purchases;

CREATE TABLE purchases (
    purchase_date DATE NOT NULL,
    customer_id INT NOT NULL,
    purchase_amount DECIMAL(10,2) NOT NULL
);
