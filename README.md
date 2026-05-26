# Loading T-SQL Data to Power BI — Full Project Walkthrough

**Database:** `warehouse_mockup` | **Tools:** SQL Server 2022, SSMS, sqlcmd, Power BI Desktop | **OS:** Windows (with Mac notes where relevant)

---

## Project Overview

This project documents the full process of building a warehouse management analytics system from scratch on a fresh Windows machine — starting from zero installed tools, through database design, scripted data loading, T-SQL view creation, and ending with a live Power BI dashboard connected directly to SQL Server.

Everything in this walkthrough was done in real time: every install issue, error, and fix is documented as it happened. The result is a complete, repeatable workflow that anyone can follow to go from a blank Windows machine to a working BI dashboard backed by a properly designed relational database.

---

## Part 1 — Environment Setup

### Starting Point

Fresh Windows machine. No SQL Server, no SSMS, no development tools. Coming from a Mac/Postgres background, so the mental model shifts are documented throughout.

**Key differences from Mac/Postgres:**

| Concept | Mac / Postgres | Windows / SQL Server |
|---|---|---|
| Start server | `brew services start postgresql` | `net start MSSQLSERVER` (or auto-starts on boot) |
| CLI tool | `psql -U postgres` | `sqlcmd -S localhost` |
| Execute query | Semicolon + Enter | `GO` on its own line |
| GUI tool | pgAdmin / TablePlus | SSMS |
| Root user | `postgres` | `sa` |
| Default port | 5432 | 1433 |
| Config files | `/usr/local/var/postgres/` | SQL Server Configuration Manager (GUI) |

---

### Step 1 — Verify winget

`winget` is Windows' built-in package manager — the equivalent of `brew` on Mac. Verified it was already available:

```powershell
winget --version
# v1.28.240
```

If it's missing, it comes bundled with the **App Installer** package from the Microsoft Store.

---

### Step 2 — Install SQL Server Developer Edition

SQL Server Developer Edition is the full-featured version, free for development and non-production use.

```powershell
winget install Microsoft.SQLServer.2022.Developer
```

When prompted about the Microsoft Store source agreement, type `Y` — this is standard on any fresh Windows machine and is legitimate. The download is ~1.17GB pulled from Microsoft's official servers.

When the GUI installer launches:

| Prompt | What to select |
|---|---|
| Installation type | **Custom** (not Basic) |
| Authentication mode | **Mixed Mode** (enables both Windows Auth and SQL logins) |
| SA password | Set a strong one and write it down |
| Instance name | Leave as `MSSQLSERVER` (default) |

**Issue encountered:** The installer GUI closed before we could interact with it. Solution was to locate and relaunch the setup directly:

```powershell
& "C:\SQLServerFull\Setup.exe"
```

Turned out SQL Server was already installed — the initial install had completed in the background. Running `sqlcmd -S localhost` and getting `1>` confirmed the engine was up.

---

### Step 3 — Install SSMS (GUI Tool)

SSMS = SQL Server Management Studio. The standard GUI for SQL Server, equivalent to pgAdmin or TablePlus on Mac.

**First attempt via winget failed** with exit code 1626 (corrupted installer cached by winget):

```powershell
winget install Microsoft.SQLServerManagementStudio
# Installer failed with exit code: 1626
```

**Solution:** Downloaded fresh from the official Microsoft shortlink and ran it manually as Administrator:

```
https://aka.ms/ssmsfullsetup
```

> **Note on `aka.ms`:** This is Microsoft's official URL shortener — only Microsoft can create links on this domain. If you see `aka.ms/anything` it's a Microsoft-created link going to a Microsoft destination, equivalent to `apple.co` for Apple.

```powershell
Start-Process "$env:USERPROFILE\Downloads\SSMS-Setup-ENU.exe" -Verb RunAs
```

The installer showed "Repair / Uninstall / Close" — meaning SSMS was already installed on the machine. Closed and launched directly.

---

### Step 4 — Launch SSMS from CLI

```powershell
SSMS.exe
```

> SSMS.exe gets added to PATH during install, so this works from any terminal.

**Connection settings used:**

| Field | Value |
|---|---|
| Server name | `localhost` (or the machine's hostname — both work) |
| Authentication | Windows Authentication |
| Encryption | Mandatory (default) |
| Trust server certificate | ✅ Checked |

Windows Authentication logs in as the current Windows user — no username or password needed for local connections. Encryption set to Mandatory with Trust Server Certificate checked is fine for local dev since SQL Server generates a self-signed cert automatically.

---

### Step 5 — Install sqlcmd

sqlcmd is a standalone CLI tool for running T-SQL from the terminal — the equivalent of `psql` on Postgres.

```powershell
winget install Microsoft.Sqlcmd
```

After install, close and reopen the terminal so PATH updates, then verify:

```powershell
sqlcmd --version
```

**Key sqlcmd behavior (different from psql):** Statements don't execute immediately. They go into a buffer. You must type `GO` on a new line and press Enter to execute. This is the most common source of confusion for anyone coming from Postgres.

---

### Step 6 — Add `admin` shortcut to PowerShell profile

Several commands (`net start`, `net stop`) require an admin terminal. Added a convenience function to the PowerShell profile to open an admin terminal in one word:

```powershell
# Check if profile exists
Test-Path $PROFILE

# If True:
Add-Content $PROFILE "`nfunction admin { Start-Process wt -Verb RunAs }"

# If False:
New-Item -Path $PROFILE -Force | Out-Null; Add-Content $PROFILE "`nfunction admin { Start-Process wt -Verb RunAs }"

# Reload profile
. $PROFILE
```

After this, typing `admin` in any terminal opens a new admin terminal window.

---

## Part 2 — Database Design

### Domain Selection

The goal was a realistic, business-focused dataset — not toy data. Options considered:

- Basic e-commerce (customers, orders, products) — common but thin
- Football/sports — rejected as too domain-specific
- **Warehouse management** — selected for depth and realism

Warehouse management was chosen because it covers a wide range of SQL concepts naturally: multi-level JOINs, self-referencing tables, date math, status distributions, partial fulfillments, and enough entity relationships to write meaningful queries at every skill level.

---

### Schema Design — 14 Tables

The schema was designed in layers:

**Physical structure:**
- `warehouses` — 5 warehouses across the US, each with a manager and capacity
- `zones` — 3 zones per warehouse (receiving, storage, shipping)
- `aisles` — aisle codes within each zone
- `bin_locations` — individual storage bins with weight limits and active status

**Supplier and product layer:**
- `suppliers` — 15 suppliers with country and lead time data
- `products` — 50 products across 7 categories with SKU, weight, and price

**Inventory:**
- `inventory` — current quantity per product per bin location

**Procurement:**
- `purchase_orders` — orders placed with suppliers, assigned to warehouses
- `purchase_order_items` — line items with ordered vs received quantities
- `inbound_shipments` — actual receipt records linked to POs and receiving employees

**Fulfillment:**
- `outbound_orders` — customer orders with status and shipped date
- `outbound_order_items` — line items pulled from specific bin locations

**Operations:**
- `stock_movements` — every receive, pick, transfer, and adjustment event
- `employees` — 25 employees with role, warehouse assignment, manager hierarchy, and salary

---

### Key Design Decisions

**Circular foreign key between `employees` and `warehouses`:**

`warehouses` references `employees` (manager_id) and `employees` references `warehouses` (warehouse_id). This creates a circular dependency that can't be resolved by table creation order alone. The solution: create `employees` first with `warehouse_id` as nullable and no FK constraint, create `warehouses` next, then use `ALTER TABLE` to add the FK after both tables exist:

```sql
ALTER TABLE employees
ADD CONSTRAINT fk_employees_warehouse
FOREIGN KEY (warehouse_id) REFERENCES warehouses(id);
```

**Self-referencing `employees` table:**

`manager_id` references `employees(id)` — the table references itself for the management hierarchy. Solved by inserting employees in strict hierarchy order: regional directors first with `manager_id = NULL`, then warehouse managers referencing director IDs, then supervisors, then workers. Explicit IDs make every reference predictable before the script runs.

**Insertion dependency order:**

Tables were inserted in strict dependency order to satisfy all foreign key constraints without disabling them:

1. employees (top-level managers first, then workers)
2. warehouses
3. zones
4. aisles
5. bin_locations
6. suppliers
7. products
8. purchase_orders
9. purchase_order_items
10. inbound_shipments
11. inventory
12. outbound_orders
13. outbound_order_items
14. stock_movements

---

### Realism Decisions

Several choices were made to make the data analytically meaningful rather than trivially clean:

**Temporal consistency:** PO dates precede expected dates (order_date + supplier lead_time_days). Expected dates precede received dates. Outbound orders ship after they're placed. All dates fall within 2024 with Q4 volume heavier than other quarters to reflect a realistic holiday season spike.

**Status distribution:** Not all orders are completed. Mix of received, in_transit, pending, and cancelled statuses on purchase orders. Mix of pending, picking, packed, shipped, and cancelled on outbound orders.

**Partial fulfillments:** Some PO items have `quantity_received < quantity_ordered` — realistic supplier shortfalls.

**Intentional NULLs:** Some nullable columns left NULL where real data would be empty (e.g. `shipped_date` on an order that hasn't shipped yet, `contact_email` for suppliers who didn't provide one).

**Out-of-stock products:** Some products have zero inventory — allows LEFT JOIN practice to surface them.

---

## Part 3 — Data Loading

### Script Structure

Split into 3 scripts to isolate concerns and make debugging easier. If script 3 fails, the schema and reference data from scripts 1 and 2 don't need to be rebuilt.

**Script 1 — Schema:** All `CREATE TABLE` statements with constraints, foreign keys, data types.

**Script 2 — Reference data:** Warehouses, employees, zones, aisles, bin locations, suppliers, products. Static lookup data that everything else depends on.

**Script 3 — Transactional data:** Purchase orders, shipments, inventory, outbound orders, stock movements. The bulk of the rows with all the logical consistency baked in.

**Script 4 — Views:** 5 analytical views for Power BI (covered in Part 4).

---

### Running the Scripts

Create the database first:

```powershell
sqlcmd -S localhost
```

```sql
CREATE DATABASE warehouse_mockup;
GO
EXIT
```

Then run each script in order:

```powershell
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\script1_schema.sql
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\script2_reference_data.sql
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\script3_transactional_data.sql
```

**Successful output from script 2:**

```
Changed database context to 'warehouse_mockup'.
(25 rows affected)   ← employees
(5 rows affected)    ← warehouses
(10 rows affected)   ← warehouse assignments updated
(5 rows affected)    ← zones (partial)
(40 rows affected)   ← aisles
(100 rows affected)  ← bin locations
(15 rows affected)   ← suppliers
(50 rows affected)   ← products
```

Total dataset: ~7,000 rows across all 14 tables.

---

### File Path Convention

Scripts reference `C:\Users\%USERNAME%\Documents\warehouse-mockup\` throughout. This path:
- Exists by default on any Windows machine
- Is user-scoped — no admin rights required to read or write
- Maps directly to where the cloned repo would live

> **Note:** `%USERNAME%` is a Windows environment variable — it resolves automatically to the current user's name in PowerShell and Command Prompt.

---

## Part 4 — Analytical Views

### Why Views Instead of Raw Tables in Power BI

The transformation layer was built in SQL Server as views rather than in Power BI for three reasons:

1. Logic lives in the database — not scattered across Power BI's query editor
2. Any consumer of the view gets consistent, pre-validated numbers
3. When underlying data changes, the view reflects it automatically without modifying the BI layer

A view looks like a table to Power BI. Every dataset refresh re-executes the view logic against live SQL Server data.

---

### The 5 Views

**View 1 — `vw_stock_levels`**

Current inventory per product with stock status classification:

```sql
CASE
    WHEN COALESCE(i.quantity, 0) = 0 THEN 'Out of Stock'
    WHEN COALESCE(i.quantity, 0) < 10 THEN 'Low Stock'
    WHEN COALESCE(i.quantity, 0) < 50 THEN 'Moderate'
    ELSE 'Well Stocked'
END AS stock_status
```

Uses `COALESCE` to handle products with no inventory record (returns 0 instead of NULL). Joins through the full physical hierarchy: inventory → bin_locations → aisles → zones → warehouses.

---

**View 2 — `vw_supplier_performance`**

On-time delivery rate, average days variance, and order counts per supplier:

```sql
CASE
    WHEN COUNT(CASE WHEN po.status = 'received' THEN 1 END) = 0 THEN NULL
    ELSE CAST(
        SUM(CASE WHEN ins.received_date <= po.expected_date THEN 1 ELSE 0 END) * 100.0
        / COUNT(CASE WHEN po.status = 'received' THEN 1 END)
    AS DECIMAL(5,2))
END AS on_time_rate_pct
```

Guards against division by zero for suppliers with no received orders. Uses conditional aggregation with `CASE WHEN` inside `SUM` and `COUNT` — a common T-SQL pattern for pivot-style metrics without actual PIVOT syntax.

---

**View 3 — `vw_employee_activity`**

Shipments received and stock movements broken down by movement type per employee:

```sql
SUM(CASE WHEN sm.movement_type = 'receive' THEN 1 ELSE 0 END) AS receive_movements,
SUM(CASE WHEN sm.movement_type = 'pick' THEN 1 ELSE 0 END) AS pick_movements,
SUM(CASE WHEN sm.movement_type = 'transfer' THEN 1 ELSE 0 END) AS transfer_movements,
SUM(CASE WHEN sm.movement_type = 'adjustment' THEN 1 ELSE 0 END) AS adjustment_movements
```

---

**View 4 — `vw_order_fulfillment`**

Outbound order status with days-to-ship calculation and overdue flagging:

```sql
CASE
    WHEN oo.status NOT IN ('shipped', 'cancelled') AND DATEDIFF(day, oo.order_date, GETDATE()) > 7
    THEN 'Overdue'
    WHEN oo.status NOT IN ('shipped', 'cancelled')
    THEN 'In Progress'
    ELSE oo.status
END AS fulfillment_flag
```

Uses `GETDATE()` to calculate whether open orders are overdue relative to today's date — a live calculation that changes every time the view is queried.

---

**View 5 — `vw_warehouse_throughput`**

Monthly inbound vs outbound volume per warehouse using `UNION ALL`:

```sql
-- Inbound
SELECT w.name, YEAR(po.order_date), MONTH(po.order_date),
       COUNT(DISTINCT po.id) AS inbound_orders,
       SUM(poi.quantity_received) AS units_received,
       SUM(poi.quantity_received * poi.unit_cost) AS inbound_cost
FROM warehouses w
LEFT JOIN purchase_orders po ON w.id = po.warehouse_id AND po.status = 'received'
...

UNION ALL

-- Outbound
SELECT w.name, YEAR(oo.order_date), MONTH(oo.order_date),
       COUNT(DISTINCT oo.id) AS outbound_orders,
       SUM(oi.quantity) AS units_shipped,
       SUM(oi.quantity * p.unit_price) AS outbound_revenue
FROM warehouses w
LEFT JOIN outbound_orders oo ON w.id = oo.warehouse_id AND oo.status = 'shipped'
...
```

`UNION ALL` combines two separate aggregations (inbound procurement and outbound fulfillment) into a single result set. This view took slightly longer to load in Power BI due to the dual aggregation — expected behavior.

---

### Running the Views Script

Via SSMS (GUI):
1. Open SSMS → connect to localhost
2. Click **New Query**
3. Make sure the database dropdown shows `warehouse_mockup`
4. Paste the contents of `script4_views.sql`
5. Press **F5**

Via sqlcmd (CLI):

```powershell
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\script4_views.sql
```

**Issue encountered:** After running the script, querying `vw_stock_levels` returned "Invalid object name." Root cause: connected to the wrong database (default database instead of `warehouse_mockup`). Fix:

```powershell
sqlcmd -S localhost -d warehouse_mockup
```

Always specify `-d warehouse_mockup` explicitly when connecting via sqlcmd.

---

### Verifying All Views

```sql
SELECT * FROM vw_stock_levels ORDER BY quantity_on_hand ASC;
GO

SELECT * FROM vw_supplier_performance ORDER BY on_time_rate_pct ASC;
GO

SELECT * FROM vw_employee_activity ORDER BY stock_movements DESC;
GO

SELECT * FROM vw_order_fulfillment ORDER BY order_date ASC;
GO

SELECT * FROM vw_warehouse_throughput ORDER BY warehouse_name, year, month;
GO
```

All 5 returned data cleanly.

---

## Part 5 — Power BI Integration

### Check if Power BI Desktop is Installed

```powershell
Get-StartApps | Where-Object {$_.Name -like "*Power BI*"}
```

Returned:

```
Name             AppID
----             -----
Power BI Desktop Microsoft.MicrosoftPowerBIDesktop_8wekyb3d8bbwe!...
```

### Launch Power BI from CLI

```powershell
Start-Process "shell:AppsFolder\Microsoft.MicrosoftPowerBIDesktop_8wekyb3d8bbwe!Microsoft.MicrosoftPowerBIDesktop"
```

---

### Connecting Power BI to SQL Server

1. Click **Get Data** in the top toolbar
2. Search for and select **SQL Server Database**
3. Click **Connect**
4. Server: `localhost`
5. Database: leave blank (select in Navigator)
6. Data Connectivity mode: **Import**
7. Click **OK**

Power BI connected and opened the Navigator showing all tables and views in `warehouse_mockup`.

---

### Loading the Views

In the Navigator, checked all 5 views:

- vw_stock_levels
- vw_supplier_performance
- vw_employee_activity
- vw_order_fulfillment
- vw_warehouse_throughput

Clicked **Load**. The `vw_warehouse_throughput` view (which uses `UNION ALL`) took a few minutes to evaluate — this is expected on first load. Power BI caches the data locally after that, so subsequent refreshes are faster.

---

### First Visual — Stock Value by Category

1. Click **Report view** (bar chart icon in left sidebar)
2. In the Visualizations pane, click **Bar chart**
3. Expand **vw_stock_levels** in the Data pane
4. Drag `category` → Y-axis
5. Drag `stock_value` → X-axis

Result: horizontal bar chart showing total stock value per product category.

---

### Power BI Automation (CLI Limitations)

Building visuals in Power BI has no meaningful CLI equivalent — the report canvas is GUI-only. However, everything underneath Power BI can be automated:

```
SQL Server Agent (scheduled T-SQL jobs)
→ updates data in SQL Server
→ Power BI Service (scheduled refresh)
→ dashboard always current for anyone with the link
```

Tools for the automation layer:
- **SQL Server Agent** — schedule T-SQL jobs to run at any interval
- **Power BI REST API** — trigger dataset refreshes programmatically
- **pbi-tools** — deploy Power BI reports to Power BI Service from CLI

The GUI work in Power BI Desktop is a one-time build. Once published to Power BI Service, everything downstream can be automated.

---

## Part 6 — T-SQL Practice Queries

20 queries written against the warehouse data, covering the full T-SQL analytics spectrum. All queries are in `T-SQL Questions & Answers.md`.

**Topics covered:**

| Topic | Example |
|---|---|
| Basic SELECT / WHERE / ORDER BY | Products in the Tools category by price |
| Multi-table JOINs | Purchase orders with supplier name and warehouse location |
| LEFT JOIN (surfacing nulls) | Products with zero stock in inventory |
| Aggregates (COUNT, SUM, AVG, MIN, MAX) | Inventory value per category, salary stats per role |
| GROUP BY + HAVING | Customers with more than 3 outbound orders |
| Correlated subqueries | Employees earning above average for their role |
| Non-correlated subqueries | Suppliers who have never had a PO placed |
| CTEs (WITH clause) | Warehouse inbound vs outbound totals side by side |
| CTE + Window Function | Top 3 most stocked products using RANK |
| PARTITION BY | Rank products by price within each category |
| MAX OVER PARTITION BY | Salary gap from the top earner per role |
| DATEDIFF | Days late or early for each supplier shipment |
| MONTH / YEAR | Outbound orders shipped per month in 2024 |

---

## Part 7 — Project Files

| File | Description |
|---|---|
| `script1_schema.sql` | CREATE TABLE statements for all 14 tables |
| `script2_reference_data.sql` | Warehouses, employees, zones, aisles, bins, suppliers, products |
| `script3_transactional_data.sql` | Purchase orders, shipments, inventory, outbound orders, stock movements |
| `script4_views.sql` | 5 analytical views for Power BI |
| `T-SQL Questions & Answers.md` | 20 practice queries with answers |
| `mssql-windows-commands.md` | Full Windows CLI cheatsheet for SSMS and SQL Server |
| `README.md` | Setup and replication guide |

---

## Skills Demonstrated

- Relational database design with normalized schema, enforced referential integrity, and real-world edge cases (circular FKs, self-referencing hierarchy tables)
- T-SQL scripting from schema creation through analytical view development
- Handling partial fulfillments, intentional NULLs, and temporal consistency across ~7,000 rows of seed data
- CLI-driven development workflow using sqlcmd and PowerShell on Windows
- T-SQL analytical patterns: conditional aggregation, window functions, CTEs, date math, UNION ALL
- BI tool integration — connecting SQL Server to Power BI and designing the transformation layer in SQL rather than the BI tool
- Troubleshooting real installation issues on a fresh Windows environment
- Version control and project documentation with Git and GitHub

---

## Repository

[github.com/YOUR_USERNAME/Loading-T-SQL-Data-to-Power-BI-Tutorial](https://github.com/YOUR_USERNAME/Loading-T-SQL-Data-to-Power-BI-Tutorial)
