# PostgreSQL Setup for Logística-ME Project

## Database Location Requirements

**For Power BI Server Compatibility**:
- PostgreSQL **must** run in Docker on Windows Server (recommended)
- Power BI Server requires Windows Server OS
- Power BI Desktop works on Windows 10/11 but Server requires Windows Server
- Docker Desktop must be installed on Windows

## Installation Options

### Option 1: Docker PostgreSQL on Windows (RECOMMENDED)
1. Install Docker Desktop for Windows: https://docs.docker.com/desktop/install/windows-install/
2. Enable WSL 2 backend in Docker settings
3. Run PostgreSQL container:

```powershell
# PowerShell command for Windows
docker run --name logistica-postgres `
  -e POSTGRES_USER=postgres `
  -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} `
  -e POSTGRES_DB=logistica_db `
  -p 5432:5432 `
  -v C:\docker-data\postgres-logistica:/var/lib/postgresql/data `
  -d postgres:latest
```

Or using CMD:
```cmd
docker run --name logistica-postgres ^
  -e POSTGRES_USER=postgres ^
  -e POSTGRES_PASSWORD=%POSTGRES_PASSWORD% ^
  -e POSTGRES_DB=logistica_db ^
  -p 5432:5432 ^
  -v C:\docker-data\postgres-logistica:/var/lib/postgresql/data ^
  -d postgres:latest
```

4. Verify container is running:
```powershell
docker ps
docker logs logistica-postgres
```

### Option 2: Native Windows PostgreSQL
1. Download PostgreSQL for Windows: https://www.postgresql.org/download/windows/
2. Install with default settings
3. During installation, set:
   - Superuser: `postgres`
   - Password: Use secure password from `.env`
   - Port: `5432`

### Option 3: Existing PostgreSQL Server
If PostgreSQL is already installed:
1. Create database:
```sql
CREATE DATABASE logistica_db;
CREATE USER logistica_user WITH PASSWORD '${POSTGRES_PASSWORD}';
GRANT ALL PRIVILEGES ON DATABASE logistica_db TO logistica_user;
```

## Configuration Files

### 1. Environment Variables (.env)
```bash
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=your_secure_password_here
```

### 2. dbt Profiles (~/.dbt/profiles.yml)
```yaml
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: ${POSTGRES_USERNAME}
      pass: ${POSTGRES_PASSWORD}
      port: 5432
      dbname: logistica_db
      schema: raw
      threads: 4
```

## Verification Steps

1. **Test Connection**:
```bash
psql -h localhost -U postgres -d logistica_db -c "SELECT version();"
```

2. **Run dbt**:
```bash
cd logistica_dbt
dbt debug  # Test connection
dbt seed   # Load CSV data
dbt run    # Build models
dbt test   # Run data quality tests
```

## Power BI Connection

1. Open Power BI Desktop
2. Get Data → PostgreSQL
3. Enter connection details:
   - Server: `localhost`
   - Database: `logistica_db`
   - Username: `postgres`
   - Password: From `.env`

4. Key tables for Power BI:
   - `test_results`: Consolidated test outcomes
   - `fact_log_events`: Main fact table
   - `dim_endpoints`: Endpoint statistics
   - `dim_time_periods`: Time-based aggregations

## Migration to Docker PostgreSQL on Windows

### From Linux PostgreSQL to Docker on Windows:
1. Dump database from Linux:
```bash
pg_dump -h linux-server -U postgres logistica_db > backup.sql
```

2. Start Docker PostgreSQL on Windows (see Option 1 above)
3. Copy backup file to Windows
4. Restore to Docker container:
```powershell
# Copy backup file to container
docker cp backup.sql logistica-postgres:/tmp/backup.sql

# Restore database
docker exec -it logistica-postgres bash -c "psql -U postgres -d logistica_db -f /tmp/backup.sql"
```

### From Native Windows PostgreSQL to Docker:
1. Dump from native installation:
```powershell
pg_dump -h localhost -U postgres logistica_db > backup.sql
```

2. Stop native PostgreSQL service:
```powershell
net stop postgresql-x64-16
```

3. Start Docker PostgreSQL
4. Restore as above

## Security Notes
- Never commit `.env` file with real passwords
- Use environment variables in production
- Configure PostgreSQL to only accept local connections
- Set appropriate firewall rules