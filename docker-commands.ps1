# PowerShell script for Docker PostgreSQL setup on Windows

# Set environment variables
$env:POSTGRES_PASSWORD = "YourSecurePassword123!"

# 1. Start PostgreSQL container using docker-compose
Write-Host "Starting PostgreSQL container..." -ForegroundColor Green
docker-compose up -d

# 2. Check if container is running
Write-Host "`nChecking container status..." -ForegroundColor Yellow
docker ps --filter "name=logistica-postgres"

# 3. Wait for PostgreSQL to be ready
Write-Host "`nWaiting for PostgreSQL to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# 4. Test connection
Write-Host "`nTesting PostgreSQL connection..." -ForegroundColor Green
docker exec logistica-postgres psql -U postgres -d logistica_db -c "SELECT version();"

# 5. Create dbt profile directory if it doesn't exist
$dbtProfileDir = "$env:USERPROFILE\.dbt"
if (-not (Test-Path $dbtProfileDir)) {
    New-Item -ItemType Directory -Path $dbtProfileDir -Force
    Write-Host "Created dbt profile directory: $dbtProfileDir" -ForegroundColor Green
}

# 6. Create profiles.yml template
$profilesYml = @"
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: postgres
      pass: $env:POSTGRES_PASSWORD
      port: 5432
      dbname: logistica_db
      schema: raw
      threads: 4
      keepalives_idle: 0
      sslmode: prefer
"@

$profilesPath = "$dbtProfileDir\profiles.yml"
if (-not (Test-Path $profilesPath)) {
    $profilesYml | Out-File -FilePath $profilesPath -Encoding UTF8
    Write-Host "Created dbt profiles.yml at: $profilesPath" -ForegroundColor Green
}

# 7. Instructions for next steps
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Green
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "`nNext steps:"
Write-Host "1. Run dbt to load data:" -ForegroundColor Yellow
Write-Host "   cd logistica_dbt"
Write-Host "   dbt debug          # Test connection"
Write-Host "   dbt seed           # Load CSV data"
Write-Host "   dbt run            # Build models"
Write-Host "   dbt test           # Run data quality tests"
Write-Host ""
Write-Host "2. Connect Power BI:" -ForegroundColor Yellow
Write-Host "   Server: localhost"
Write-Host "   Database: logistica_db"
Write-Host "   Username: postgres"
Write-Host "   Password: $env:POSTGRES_PASSWORD"
Write-Host ""
Write-Host "3. Useful Docker commands:" -ForegroundColor Yellow
Write-Host "   docker-compose logs          # View logs"
Write-Host "   docker-compose down          # Stop container"
Write-Host "   docker-compose up -d         # Start container"
Write-Host "   docker exec -it logistica-postgres bash  # Enter container"
Write-Host ""