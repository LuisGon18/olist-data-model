-- Profiling: orders (parent) ↔ order_items (child)
-- Run sql/00_views.sql first.

-- Check 0. Is the parent key unique? (both numbers equal = unique)
-- Result: 99,441 rows, 99,441 distinct order_id → order_id is unique.
SELECT COUNT(*) AS n_rows, COUNT(DISTINCT order_id) AS n_keys
FROM orders;

-- Check 1. Parent maximum: the most items one order has
-- Result: up to 21 items in one order → "many" on the order_items side.
SELECT order_id, COUNT(*) AS n_children
FROM order_items
GROUP BY order_id
ORDER BY n_children DESC
LIMIT 5;

-- Check 2. Parent minimum: orders with no items
-- Result: 775 orders have no items → the order_items side is optional (o{).
SELECT COUNT(*) AS parents_without_children
FROM orders AS p
LEFT JOIN order_items AS c ON c.order_id = p.order_id
WHERE c.order_id IS NULL;

-- Check 2, by status: why do those 775 orders have no items?
-- Result: unavailable 603, canceled 164, created 5, invoiced 2, shipped 1.
SELECT p.order_status, COUNT(*) AS n_orders
FROM orders AS p
LEFT JOIN order_items AS c ON c.order_id = p.order_id
WHERE c.order_id IS NULL
GROUP BY p.order_status
ORDER BY n_orders DESC;

-- Check 3a. Child minimum: items with a NULL order_id
-- Result: 0.
SELECT COUNT(*) AS null_fks
FROM order_items
WHERE order_id IS NULL;

-- Check 3b. Child minimum: orphan items whose order_id matches no order
-- Result: 0 → every item has exactly one order (||).
SELECT COUNT(*) AS orphans
FROM order_items AS c
LEFT JOIN orders AS p ON p.order_id = c.order_id
WHERE p.order_id IS NULL;
