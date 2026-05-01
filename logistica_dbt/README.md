# Logistica-ME dbt Project

## Project Structure
```
logistica_dbt/
├── models/
│   ├── staging/
│   │   └── stg_shipments.sql      # Staging: clean and cast shipment data
│   ├── marts/
│   │   ├── fact_shipments.sql     # Fact table with delay metrics
│   │   ├── dim_routes.sql         # Route dimension (origin-destination)
│   │   ├── dim_vehicles.sql       # Vehicle type dimension
│   │   ├── dim_incidents.sql      # Incident dimension (delay categories)
│   │   └── schema.yml             # Model documentation & tests
│   └── seeds/                     # CSV seeds (shipments_*.csv)
├── tests/                         # Data quality tests (shipment-focused)
├── macros/
├── analyses/
├── snapshots/
└── dbt_project.yml
```

## Data Pipeline
1. **API Download**: `API.py` downloads CSV data and validates schema
2. **Data Processing**: `data_processing_pipeline.py` cleans and standardizes data
3. **Incremental Load**: `incremental_dbt_seed.py` loads only new CSVs into PostgreSQL as seeds
4. **Transformation**:
   - `stg_shipments`: Clean and type-cast raw seed data
   - `dim_*`: Dimension tables for routes, vehicles, incidents
   - `fact_shipments`: Fact table with foreign keys and delay metrics
5. **Testing**: Data quality tests run on all models

## Usage
### 1. Download and process new data
```bash
# From project root
python API.py
python data_processing_pipeline.py
python incremental_dbt_seed.py
```

### 2. Run dbt
```bash
cd logistica_dbt
dbt run
dbt test
```

## Models
- `stg_shipments`: Selects from unified `shipments` seed (all shipments_*.csv). Casts types.
- `dim_routes`: Distinct origin-destination pairs with route name.
- `dim_vehicles`: Distinct vehicle types.
- `dim_incidents`: Delivery status combined with delay category (ON_TIME, MINOR_DELAY, MODERATE_DELAY, MAJOR_DELAY)
- `fact_shipments`: Grain = one shipment event. Links to dimensions; includes derived metrics:
   - `is_on_time`: TRUE if estimated_delay_minutes <= 0
   - `is_delayed`: TRUE if estimated_delay_minutes > 0
   - `event_date`, `event_hour`: Time conveniences.

## Tests
### Built-in (schema.yml)
- Unique and not-null constraints on keys
- Foreign key relationships
- Accepted values for categorical columns
- Positive weight

### Singular tests (dbt/test)
- `valid_timestamp_format`: Invalid timestamps
- `valid_weight_kg`: Non-positive weights
- `valid_delay_minutes`: Null delays
- `cross_file_duplicate_detection`: Duplicate shipment_id across seeds
- `timestamp_freshness`: Future timestamps
- `null_rate_analysis`: Null percentage per column
- `statistical_outlier_detection`: Outliers in weight and delay
- `data_freshness_score`: Overall freshness score

## Notes
- Seeds are loaded into the `raw` schema
- Mart models are created in the `analytics` schema (configurable in dbt_project.yml)
- All models are tagged appropriately for selective runs
