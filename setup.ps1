# ============================================================
# SETUP SCRIPT
# Loading T-SQL Data to Power BI
# Run this first in Windows Terminal as Administrator
# Win + X → A to open admin terminal
# ============================================================

Write-Host "Installing SQL Server Developer Edition..."
winget install Microsoft.SQLServer.2022.Developer

Write-Host "Installing SSMS..."
winget install Microsoft.SQLServerManagementStudio

Write-Host "Installing sqlcmd..."
winget install Microsoft.Sqlcmd

Write-Host "Installing Power BI Desktop..."
winget install Microsoft.PowerBIDesktop

Write-Host "Adding SSMS to PATH..."
[System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\Microsoft SQL Server Management Studio 21\Release\Common7\IDE", [System.EnvironmentVariableTarget]::Machine)

Write-Host "All done. Close and reopen your terminal, then continue with the README."
