DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    last_modified TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION update_last_modified()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.last_modified := CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_last_modified ON products;

CREATE TRIGGER trg_update_last_modified
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_last_modified();

INSERT INTO products (name, price)
VALUES
    ('Laptop', 1500.00),
    ('Mouse', 25.50),
    ('Keyboard', 45.00);

SELECT id, name, price, last_modified
FROM products
ORDER BY id;

UPDATE products
SET price = price + 10.00
WHERE name IN ('Mouse', 'Keyboard');

SELECT id, name, price, last_modified
FROM products
ORDER BY id;
