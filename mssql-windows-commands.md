# MSSQL Server — Windows CLI Cheatsheet

---

## SSMS (SQL Server Management Studio)

> SSMS.exe is on PATH — these commands work from any terminal without needing the full install path.

Launch SSMS

```powershell
SSMS.exe
```

Launch SSMS connected to a specific server

```powershell
SSMS.exe -S localhost
```

Force close SSMS

```powershell
Stop-Process -Name "SSMS" -Force
```

Find SSMS install path (useful after upgrades or if PATH breaks)

```powershell
Get-ChildItem "C:\Program Files", "C:\Program Files (x86)" -Recurse -Filter "Ssms.exe" 2>$null
```

Add SSMS to PATH permanently (run in admin terminal)

```powershell
[System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Microsoft SQL Server Management Studio 21\Release\Common7\IDE", [System.EnvironmentVariableTarget]::Machine)
```

---

## SQL Server Service (the engine)

Check if SQL Server is running

```powershell
Get-Service -Name MSSQLSERVER
```

Start SQL Server

```powershell
net start MSSQLSERVER
```

Stop SQL Server

```powershell
net stop MSSQLSERVER
```

Restart SQL Server

```powershell
net stop MSSQLSERVER && net start MSSQLSERVER
```

---

## sqlcmd — Connect

Connect with Windows Authentication

```powershell
sqlcmd -S localhost -d warehouse_mockup
```

Connect with SQL Authentication

```powershell
sqlcmd -S localhost -d warehouse_mockup -U myuser -P YourPasswordHere
```

Connect to a named instance

```powershell
sqlcmd -S localhost\SQLEXPRESS
```

Run a single query and exit

```powershell
sqlcmd -S localhost -d warehouse_mockup -Q "SELECT name FROM sys.databases;"
```

Run a .sql script file

```powershell
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\myscript.sql
```

Run a script and save output to a file

```powershell
sqlcmd -S localhost -d warehouse_mockup -i C:\Users\%USERNAME%\Documents\warehouse-mockup\myscript.sql -o C:\Users\%USERNAME%\Documents\warehouse-mockup\results.txt
```

---

## sqlcmd — Inside the prompt

> Statements don't execute until you type `GO` on its own line and hit Enter.

List all databases

```sql
SELECT name FROM sys.databases;
GO
```

Switch database

```sql
USE myproject;
GO
```

List all tables in current database

```sql
SELECT * FROM INFORMATION_SCHEMA.TABLES;
GO
```

Exit

```sql
EXIT
```

---

## Database Management (T-SQL)

Create a database

```sql
CREATE DATABASE myproject;
GO
```

Delete a database

```sql
DROP DATABASE myproject;
GO
```

Create a server login

```sql
CREATE LOGIN myuser WITH PASSWORD = 'StrongPass123!';
GO
```

Create a database user and grant full access (run after switching to your DB)

```sql
USE myproject;
GO
CREATE USER myuser FOR LOGIN myuser;
GO
ALTER ROLE db_owner ADD MEMBER myuser;
GO
```

List all logins

```sql
SELECT name FROM sys.server_principals WHERE type = 'S';
GO
```

List all users in current database

```sql
SELECT name FROM sys.database_principals WHERE type = 'S';
GO
```

---

## Diagnostics

Check SQL Server version

```sql
SELECT @@VERSION;
GO
```

Check current database

```sql
SELECT DB_NAME();
GO
```

Check current user

```sql
SELECT SYSTEM_USER;
GO
```

List active connections

```sql
SELECT * FROM sys.dm_exec_sessions WHERE is_user_process = 1;
GO
```
