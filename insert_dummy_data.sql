

CREATE SCHEMA app;

CREATE TABLE IF NOT EXISTS app.order(
    order_id VARCHAR(10),
    customer_id VARCHAR(10),
    status VARCHAR(10)
);

INSERT INTO app.order(order_id, customer_id, status)
    VALUES (
            'order_1',
            'customer_1',
            'delivered'
           );

INSERT INTO app.order(order_id, customer_id, status)
    VALUES (
            'order_2',
            'customer_2',
            'on-route'
           );

INSERT INTO app.order(order_id, customer_id, status)
    VALUES (
            'order_3',
            'customer_2',
            'on-route'
           );
