# Loading T-SQL Data to Power BI

This project walks through setting up a SQL Server database on Windows and connecting it to Power BI for live reporting. It covers environment setup, schema design, data loading, analytical view creation, and dashboard connection — start to finish, with everything you need included in the repo.

The database models a multi-warehouse distribution operation: suppliers, products, employees, purchase orders, inventory, outbound fulfillment, and stock movements across five warehouses. It's a realistic enough domain to write meaningful queries at every level, and the included practice set covers basic SELECT through window functions and CTEs. All scripts run via sqlcmd from the Windows terminal and are designed to be executed in sequence.

Windows is required for this guide — SQL Server Developer Edition and Power BI Desktop are both Windows-native. Mac users can run SQL Server locally via Docker and connect through VS Code with the MSSQL extension, which is a solid alternative worth exploring.

---

## What You'll Build

By the end of this guide you will have a SQL Server database called `warehouse_mockup` with 14 fully populated tables, five analytical views built on top of that data, and a Power BI Desktop report connected directly to those views and ready for dashboard development. You will also have a reusable Windows CLI cheatsheet for managing SQL Server day to day, and a set of 20 practice T-SQL queries you can run against the live database.

---

## Prerequisites

This project is designed for Windows — SQL Server Developer Edition and Power BI Desktop are both Windows-native tools. If you're on a Mac, the closest equivalent setup would use Docker to run SQL Server locally and VS Code with the MSSQL extension as your GUI, though that workflow isn't covered here.

You will also need **Git** installed before you can clone the repository. You can check whether it's already available by running:

```powershell
git --version
```

If Git isn't installed yet, you can add it through winget:

```powershell
winget install Git.Git
```

Close and reopen Windows Terminal after the install completes so the PATH updates correctly.

---

## Quickstart — Install Everything at Once

If you'd like to get all the required tools installed in a single step, open Windows Terminal as Administrator (`Win + X → A`) and run the setup script included in the repo:

```powershell
.\setup.ps1
```

This will install SQL Server Developer Edition, SSMS, sqlcmd, and Power BI Desktop via winget, and will also add SSMS to your system PATH so it's accessible from any terminal window. Once the script finishes, close and reopen Windows Terminal and skip ahead to **Part 2**.

If you'd prefer to install each tool manually, or if you run into issues with the script, Part 1 walks through every step individually.

---

## Part 1 — Installing the Required Tools

### 1.1 — Verify winget is available

`winget` is the Windows package manager that comes built into Windows 10 and 11 — it works similarly to `brew` on Mac and lets you install software directly from the terminal. Before installing anything else, confirm it's working:

```powershell
winget --version
```

If a version number prints out (for example, `v1.28.240`), you're ready to go. If the command isn't recognized, open the Microsoft Store, search for "App Installer", and update it from there.

### 1.2 — Install SQL Server Developer Edition

SQL Server Developer Edition is the full-featured version of SQL Server, available for free for development and non-production use. Install it with:

```powershell
winget install Microsoft.SQLServer.2022.Developer
```

When Windows asks whether you agree to the Microsoft Store source terms, type `Y` and press Enter — this is a standard prompt on any fresh Windows machine and is completely normal.

The download is around 1.17GB, so it will take a few minutes depending on your connection. Once the download completes, a GUI installer will launch automatically. When it does, make the following selections:

| Prompt | What to select |
|---|---|
| Installation type | **Custom** |
| Authentication mode | **Mixed Mode** |
| SA password | Set a strong password and write it down somewhere safe |
| Instance name | Leave as `MSSQLSERVER` |

> **If the installer window disappears before you can interact with it**, the SQL Server engine may have already installed silently in the background. Move on to step 1.4 to verify it's running.
>
> **If winget appears to be reinstalling everything from scratch**, stop it with `Ctrl + C` and launch the installer directly instead:
> ```powershell
> & "C:\SQLServerFull\Setup.exe"
> ```

### 1.3 — Install SSMS

SSMS (SQL Server Management Studio) is the standard GUI tool for managing SQL Server — it lets you browse databases, run queries, inspect tables, and manage users through a visual interface.

```powershell
winget install Microsoft.SQLServerManagementStudio
```

**If the install fails with exit code 1626**, this means the installer package that winget downloaded was corrupted. The straightforward fix is to download a fresh copy directly from Microsoft and run it manually:

1. Go to `https://aka.ms/ssmsfullsetup` in your browser and download `SSMS-Setup-ENU.exe`

   > `aka.ms` is Microsoft's official URL shortener — it works the same way `apple.co` does for Apple. Only Microsoft can create links on that domain, so any `aka.ms` link is going to a Microsoft destination.

2. Once the file is in your Downloads folder, run it as Administrator:

```powershell
Start-Process "$env:USERPROFILE\Downloads\SSMS-Setup-ENU.exe" -Verb RunAs
```

If the installer opens and shows options for **Repair**, **Uninstall**, or **Close**, that means SSMS is already installed on the machine. Click Close and move on.

### 1.4 — Install sqlcmd

sqlcmd is the command-line tool for connecting to SQL Server and running T-SQL directly from the terminal — it's the Windows equivalent of `psql` on Postgres.

```powershell
winget install Microsoft.Sqlcmd
```

After the install finishes, close and reopen Windows Terminal to make sure the PATH is updated, then verify it's working:

```powershell
sqlcmd --version
```

### 1.5 — Verify SQL Server is running

With sqlcmd installed, you can confirm the SQL Server engine is up and accepting connections:

```powershell
sqlcmd -S localhost
```

If the engine is running, you'll see `1>` — that's your interactive T-SQL prompt. Type `EXIT` to leave it for now.

If the connection fails, the SQL Server service may not have started yet. Open an admin terminal (`Win + X → A`) and start it manually:

```powershell
net start MSSQLSERVER
```

> **Important — coming from Postgres or MySQL:** In sqlcmd, pressing Enter doesn't execute a statement. Statements accumulate in a buffer until you type `GO` on its own line and press Enter. This is the single most common source of confusion for anyone new to SQL Server, so keep it in mind as you work through this guide.

### 1.6 — Add SSMS to PATH

Adding SSMS to your system PATH means you can launch it from any terminal window by simply typing `SSMS.exe`, without needing to know or remember the full installation path. Open an admin terminal (`Win + X → A`) and run:

```powershell
[System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Microsoft SQL Server Management Studio 21\Release\Common7\IDE", [System.EnvironmentVariableTarget]::Machine)
```

Close and reopen Windows Terminal, then confirm it worked:

```powershell
SSMS.exe
```

SSMS should launch. If it doesn't open, the install path on your machine may be slightly different. Run this to find the correct one:

```powershell
Get-ChildItem "C:\Program Files", "C:\Program Files (x86)" -Recurse -Filter "Ssms.exe" 2>$null
```

Take whatever path it returns and substitute it into the `SetEnvironmentVariable` command above.

> **Note:** If you have SSMS 20 rather than SSMS 21, the install path will be under `C:\Program Files (x86)` instead of `C:\Program Files`. Make sure the path in the command matches your actual version.

### 1.7 — Set up the `admin` shortcut

A number of commands throughout this guide need to run in an elevated (Administrator) terminal. Rather than hunting through menus every time, you can add a shortcut to your PowerShell profile that opens an admin terminal with a single word.

First, check whether a PowerShell profile already exists:

```powershell
Test-Path $PROFILE
```

If it returns `True`, append the function to the existing profile:

```powershell
Add-Content $PROFILE "`nfunction admin { Start-Process wt -Verb RunAs }"
```

If it returns `False`, create the profile file first and then add the function:

```powershell
New-Item -Path $PROFILE -Force | Out-Null; Add-Content $PROFILE "`nfunction admin { Start-Process wt -Verb RunAs }"
```

Reload the profile to make the change take effect immediately:

```powershell
. $PROFILE
```

From this point forward, typing `admin` in any terminal will open a new admin terminal window.

### 1.8 — Install Power BI Desktop

```powershell
winget install Microsoft.PowerBIDesktop
```

Alternatively, you can download it directly from `https://powerbi.microsoft.com/desktop` if you prefer.

---

## Part 2 — Connect to SSMS

With everything installed, launch SSMS and connect to your local SQL Server instance:

```powershell
SSMS.exe
```

When the connection dialog opens, fill it in as follows:

| Field | Value |
|---|---|
| Server name | `localhost` (your machine's hostname will also work) |
| Authentication | Windows Authentication |
| Encryption | Mandatory |
| Trust server certificate | ✅ Checked |

Click **Connect**. Your server should appear in the Object Explorer panel on the left side of the screen, which means you're connected and ready to work.

> **If you get an SSL certificate error after clicking Connect**, click **Options >>** in the connection dialog, change Encryption to `Optional`, make sure Trust server certificate is checked, and try connecting again. This occasionally comes up on fresh installs and is perfectly fine for local development.

---

## Part 3 — Clone the Repository

Navigate to your Documents folder and clone the project:

```powershell
cd C:\Users\%USERNAME%\Documents
git clone https://github.com/mauriciolarroque/Loading-T-SQL-Data-to-Power-BI-Tutorial.git
cd Loading-T-SQL-Data-to-Power-BI-Tutorial
```

Once cloned, all four SQL scripts will be available at:
`C:\Users\%USERNAME%\Documents\Loading-T-SQL-Data-to-Power-BI-Tutorial\scripts\`

---

## Part 4 — Create the Database

Open a connection to SQL Server via sqlcmd:

```powershell
sqlcmd -S localhost
```

At the prompt, create the database and exit:

```sql
CREATE DATABASE warehouse_mockup;
GO
EXIT
```

To confirm the database was created successfully, you can run a quick check:

```powershell
sqlcmd -S localhost -Q "SELECT name FROM sys.databases WHERE name = 'warehouse_mockup';"
```

---

## Part 5 — Run the Scripts

The project data is split across four scripts that need to be run in order. Each script depends on the one before it, so it's important not to skip ahead or run them out of sequence.

### Script 1 — Schema

This script creates all 14 tables along with their data types, constraints, and foreign key relationships.

```powershell
sqlcmd -S localhost -d warehouse_mockup -i "C:\Users\%USERNAME%\Documents\Loading-T-SQL-Data-to-Power-BI-Tutorial\scripts\script1_schema.sql"
```

A successful run will print `Changed database context to 'warehouse_mockup'.` with no errors below it.

### Script 2 — Reference Data

This script populates the static lookup tables — warehouses, employees, zones, aisles, bin locations, suppliers, and products. These are the records that all the transactional data in Script 3 will reference.

```powershell
sqlcmd -S localhost -d warehouse_mockup -i "C:\Users\%USERNAME%\Documents\Loading-T-SQL-Data-to-Power-BI-Tutorial\scripts\script2_reference_data.sql"
```

After it completes, you should see row counts like these confirming everything loaded correctly:

```
(25 rows affected)    ← employees
(5 rows affected)     ← warehouses
(10 rows affected)    ← employee warehouse assignments updated
(15 rows affected)    ← zones
(40 rows affected)    ← aisles
(100 rows affected)   ← bin locations
(15 rows affected)    ← suppliers
(50 rows affected)    ← products
```

### Script 3 — Transactional Data

This is the main data load — purchase orders, inbound shipments, inventory records, outbound orders, and stock movements. Approximately 7,000 rows in total, spread across the full 2024 calendar year with realistic status distributions, partial fulfillments, and intentional edge cases.

```powershell
sqlcmd -S localhost -d warehouse_mockup -i "C:\Users\%USERNAME%\Documents\Loading-T-SQL-Data-to-Power-BI-Tutorial\scripts\script3_transactional_data.sql"
```

### Script 4 — Analytical Views

This script creates five T-SQL views on top of the data. These views handle all the joins, aggregations, and business logic, so that Power BI can connect directly to clean, pre-shaped data without needing any transformation on the BI side.

```powershell
sqlcmd -S localhost -d warehouse_mockup -i "C:\Users\%USERNAME%\Documents\Loading-T-SQL-Data-to-Power-BI-Tutorial\scripts\script4_views.sql"
```

Again, a clean run will print `Changed database context to 'warehouse_mockup'.` with no errors.

---

## Part 6 — Verify the Views

Before connecting Power BI, it's worth confirming that all five views are returning data as expected. Connect to the database:

```powershell
sqlcmd -S localhost -d warehouse_mockup
```

Then query each view in turn:

```sql
SELECT * FROM vw_stock_levels ORDER BY quantity_on_hand ASC;
GO
```

```sql
SELECT * FROM vw_supplier_performance ORDER BY on_time_rate_pct ASC;
GO
```

```sql
SELECT * FROM vw_employee_activity ORDER BY stock_movements DESC;
GO
```

```sql
SELECT * FROM vw_order_fulfillment ORDER BY order_date ASC;
GO
```

```sql
SELECT * FROM vw_warehouse_throughput ORDER BY warehouse_name, year, month;
GO
```

All five should return populated result sets. If any of them come back with an "Invalid object name" error, it most likely means you're connected to the wrong database — double check that you included `-d warehouse_mockup` in your sqlcmd connection command.

---

## Part 7 — Connect Power BI to SQL Server

### 7.1 — Launch Power BI Desktop

You can launch Power BI from the terminal with:

```powershell
Start-Process "shell:AppsFolder\Microsoft.MicrosoftPowerBIDesktop_8wekyb3d8bbwe!Microsoft.MicrosoftPowerBIDesktop"
```

Or simply search for "Power BI Desktop" in the Windows Start menu.

### 7.2 — Connect to the Database

Once Power BI is open, click **Get Data** in the top toolbar, search for **SQL Server Database**, and select it. In the connection dialog, enter the following:

| Field | Value |
|---|---|
| Server | `localhost` |
| Database | Leave blank |
| Data Connectivity mode | Import |

Click **OK** to proceed.

### 7.3 — Load the Views

Power BI will open a Navigator showing all the tables and views available in `warehouse_mockup`. Select all five analytical views:

- `vw_stock_levels`
- `vw_supplier_performance`
- `vw_employee_activity`
- `vw_order_fulfillment`
- `vw_warehouse_throughput`

Click **Load** to import them into Power BI.

> `vw_warehouse_throughput` combines two separate aggregations using `UNION ALL` and may take a couple of minutes to load the first time. This is normal behavior — Power BI caches the data locally after the initial import, so subsequent refreshes will be noticeably faster.

### 7.4 — Build Your First Visual

With the data loaded, you're ready to start building. To create a simple bar chart showing total stock value by product category:

1. Click the **Report view** icon in the left sidebar (it looks like a bar chart)
2. In the Visualizations pane on the right, select **Bar chart**
3. In the Data pane, expand `vw_stock_levels`
4. Drag `category` into the Y-axis field
5. Drag `stock_value` into the X-axis field

You should now have a live horizontal bar chart backed by your SQL Server data. From here you can add additional visuals using any of the five views, apply filters and slicers, and build out a full dashboard.

---

## Part 8 — Practice Queries

The `docs` folder includes a file called `T-SQL Questions & Answers.md` with 20 practice queries written against the `warehouse_mockup` database. The questions are organized by concept and cover the full range of analytical SQL:

- Basic SELECT, WHERE, and ORDER BY filtering
- INNER JOIN, LEFT JOIN, and multi-table joins across the full schema
- Aggregate functions including COUNT, SUM, AVG, MIN, and MAX
- GROUP BY with HAVING clauses for filtered aggregations
- Correlated and non-correlated subqueries
- Common Table Expressions using the WITH clause
- Window functions including RANK and PARTITION BY
- Date functions including DATEDIFF, MONTH, and YEAR

Every query runs against the live loaded data and returns meaningful results, making them useful both as learning exercises and as reference examples for writing your own queries.

---

## Database Schema

The `warehouse_mockup` database contains 14 tables organized across four layers of the warehouse management domain:

**Physical structure** — the spatial layout of the warehouses themselves
`warehouses` → `zones` → `aisles` → `bin_locations`

**Supplier and product layer** — what's being stocked and where it comes from
`suppliers` → `products` → `inventory`

**Procurement** — the inbound supply chain from order to receipt
`purchase_orders` → `purchase_order_items` → `inbound_shipments`

**Fulfillment** — the outbound flow from customer order to shipment
`outbound_orders` → `outbound_order_items`

**Operations** — the people and activity that keeps everything moving
`stock_movements` → `employees`

---

## Project Files

```
/
├── README.md                          ← this file
├── setup.ps1                          ← one-shot install script (run as Administrator)
├── .gitignore
│
├── scripts/
│   ├── script1_schema.sql             ← CREATE TABLE statements for all 14 tables
│   ├── script2_reference_data.sql     ← warehouses, employees, suppliers, products
│   ├── script3_transactional_data.sql ← orders, shipments, inventory, movements
│   └── script4_views.sql              ← 5 analytical views for Power BI
│
├── docs/
│   ├── T-SQL Questions & Answers.md   ← 20 practice queries with answers
│   └── mssql-windows-commands.md      ← full Windows CLI cheatsheet
│
└── screenshots/
    └── (Power BI dashboard screenshots)
```

---

## Common Errors

| Error | Cause | Fix |
|---|---|---|
| `sqlcmd: command not found` | sqlcmd not installed or PATH not updated | Close and reopen terminal after install |
| `Invalid object name 'vw_stock_levels'` | Connected to the wrong database | Add `-d warehouse_mockup` to the sqlcmd command |
| `System error 5: Access is denied` | Command requires Administrator privileges | Open an admin terminal with `Win + X → A` |
| `Requested registry access is not allowed` | SetEnvironmentVariable requires admin | Run the command in an admin terminal |
| SSMS installer exit code 1626 | Corrupted winget installer cache | Download the installer manually from `aka.ms/ssmsfullsetup` |
| SSL certificate error in SSMS | Self-signed certificate not trusted | Set Encryption to Optional and check Trust server certificate |
| Power BI takes several minutes to load | `vw_warehouse_throughput` uses UNION ALL | Expected on first load — Power BI caches after the first run |
