# T-SQL Questions & Answers

All questions use the `warehouse_mockup` database.

---

## Basic SELECT & WHERE

**Q1.** List all products in the Tools category with their SKU and price, ordered by price descending.

```sql
SELECT sku, name, unit_price FROM products WHERE category = 'Tools' ORDER BY unit_price DESC;
GO
```

**Q2.** Which suppliers are based in the USA and have a lead time under 7 days?

```sql
SELECT name, lead_time_days FROM suppliers WHERE country = 'USA' AND lead_time_days < 7;
GO
```

**Q3.** List all outbound orders that have been cancelled or are still pending.

```sql
SELECT id, customer_name, order_date, status FROM outbound_orders WHERE status IN ('cancelled', 'pending');
GO
```

---

## JOINs

**Q4.** Show all purchase orders with the supplier name and warehouse location instead of IDs.

```sql
SELECT po.id, s.name AS supplier, w.location AS warehouse, po.order_date, po.status
FROM purchase_orders po
JOIN suppliers s ON po.supplier_id = s.id
JOIN warehouses w ON po.warehouse_id = w.id
ORDER BY po.order_date;
GO
```

**Q5.** List all inventory records showing the product name, SKU, bin code, and quantity.

```sql
SELECT p.name, p.sku, b.bin_code, i.quantity
FROM inventory i
JOIN products p ON i.product_id = p.id
JOIN bin_locations b ON i.bin_location_id = b.id
ORDER BY i.quantity DESC;
GO
```

**Q6.** Show all inbound shipments with the supplier name, warehouse location, and the employee who received them.

```sql
SELECT s.name AS supplier, w.location AS warehouse, e.name AS received_by, ins.received_date
FROM inbound_shipments ins
JOIN purchase_orders po ON ins.purchase_order_id = po.id
JOIN suppliers s ON po.supplier_id = s.id
JOIN warehouses w ON po.warehouse_id = w.id
JOIN employees e ON ins.received_by = e.id
ORDER BY ins.received_date;
GO
```

**Q7.** List all products that currently have zero stock in inventory.

```sql
SELECT p.name, p.sku, p.category
FROM products p
LEFT JOIN inventory i ON p.id = i.product_id
WHERE i.quantity = 0 OR i.quantity IS NULL;
GO
```

---

## Aggregates & GROUP BY

**Q8.** How many purchase orders has each supplier fulfilled, ordered by most to least?

```sql
SELECT s.name AS supplier, COUNT(po.id) AS total_orders
FROM suppliers s
LEFT JOIN purchase_orders po ON s.id = po.supplier_id
GROUP BY s.name
ORDER BY total_orders DESC;
GO
```

**Q9.** What is the total inventory value per product category?

```sql
SELECT p.category, SUM(i.quantity * p.unit_price) AS total_value
FROM inventory i
JOIN products p ON i.product_id = p.id
GROUP BY p.category
ORDER BY total_value DESC;
GO
```

**Q10.** Which customers have placed more than 3 outbound orders?

```sql
SELECT customer_name, COUNT(*) AS total_orders
FROM outbound_orders
GROUP BY customer_name
HAVING COUNT(*) > 3
ORDER BY total_orders DESC;
GO
```

**Q11.** What is the average, minimum, and maximum salary per role across all employees?

```sql
SELECT role, AVG(salary) AS avg_salary, MIN(salary) AS min_salary, MAX(salary) AS max_salary
FROM employees
GROUP BY role
ORDER BY avg_salary DESC;
GO
```

---

## Subqueries

**Q12.** List all products priced above the average product price.

```sql
SELECT name, category, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY unit_price DESC;
GO
```

**Q13.** Which suppliers have never had a purchase order placed with them?

```sql
SELECT name, country
FROM suppliers
WHERE id NOT IN (SELECT DISTINCT supplier_id FROM purchase_orders);
GO
```

**Q14.** Find all employees who earn more than the average salary of their role.

```sql
SELECT e.name, e.role, e.salary
FROM employees e
WHERE e.salary > (
    SELECT AVG(salary) FROM employees WHERE role = e.role
)
ORDER BY e.role, e.salary DESC;
GO
```

---

## CTEs

**Q15.** Using a CTE, show each warehouse's total number of received purchase orders and total number of outbound shipped orders side by side.

```sql
WITH inbound AS (
    SELECT warehouse_id, COUNT(*) AS received_orders
    FROM purchase_orders
    WHERE status = 'received'
    GROUP BY warehouse_id
),
outbound AS (
    SELECT warehouse_id, COUNT(*) AS shipped_orders
    FROM outbound_orders
    WHERE status = 'shipped'
    GROUP BY warehouse_id
)
SELECT w.name, i.received_orders, o.shipped_orders
FROM warehouses w
LEFT JOIN inbound i ON w.id = i.warehouse_id
LEFT JOIN outbound o ON w.id = o.warehouse_id
ORDER BY w.name;
GO
```

**Q16.** Using a CTE, find the top 3 most stocked products by quantity.

```sql
WITH stock_ranked AS (
    SELECT p.name, p.category, i.quantity,
           RANK() OVER (ORDER BY i.quantity DESC) AS stock_rank
    FROM inventory i
    JOIN products p ON i.product_id = p.id
)
SELECT name, category, quantity, stock_rank
FROM stock_ranked
WHERE stock_rank <= 3;
GO
```

---

## Window Functions

**Q17.** Rank products by unit price within each category.

```sql
SELECT name, category, unit_price,
       RANK() OVER (PARTITION BY category ORDER BY unit_price DESC) AS price_rank
FROM products
ORDER BY category, price_rank;
GO
```

**Q18.** Show each employee, their salary, and the difference between their salary and the highest salary in their role.

```sql
SELECT name, role, salary,
       MAX(salary) OVER (PARTITION BY role) - salary AS gap_from_top
FROM employees
ORDER BY role, gap_from_top;
GO
```

---

## Date Functions

**Q19.** For all received purchase orders, calculate how many days late or early the shipment arrived compared to the expected date. Positive = late, negative = early.

```sql
SELECT po.id, s.name AS supplier, po.expected_date, ins.received_date,
       DATEDIFF(day, po.expected_date, ins.received_date) AS days_variance
FROM inbound_shipments ins
JOIN purchase_orders po ON ins.purchase_order_id = po.id
JOIN suppliers s ON po.supplier_id = s.id
ORDER BY days_variance DESC;
GO
```

**Q20.** How many outbound orders were shipped per month in 2024?

```sql
SELECT MONTH(shipped_date) AS month, COUNT(*) AS orders_shipped
FROM outbound_orders
WHERE status = 'shipped' AND YEAR(shipped_date) = 2024
GROUP BY MONTH(shipped_date)
ORDER BY month;
GO
```
