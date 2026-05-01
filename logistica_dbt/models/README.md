# Data Models

## Staging Layer (`staging/`)
- **`stg_shipments.sql`**: Cleans and transforms raw CSV data into structured format
  - Converts timestamp strings to timestamp type (`event_timestamp`)
  - Casts numeric fields (`weight_kg`, `estimated_delay_minutes`) to appropriate types
  - Maintains all original columns with proper data types

## Marts Layer (`marts/`)
### Fact Tables
- **`fact_shipments.sql`**: Main fact table with delay metrics
  - Surrogate keys to dimensions: `route_id`, `vehicle_id`, `incident_id`
  - Derived metrics: `is_on_time`, `is_delayed`
  - Time conveniences: `event_date`, `event_hour`
  - Includes all shipment data with calculated fields

### Dimension Tables
- **`dim_routes.sql`**: Route dimension (origin-destination pairs)
  - `route_id` surrogate key
  - `origin`, `destination`, `route_name`
- **`dim_vehicles.sql`**: Vehicle type dimension
  - `vehicle_id` surrogate key
  - `vehicle_type`
- **`dim_incidents.sql`**: Incident dimension based on delivery status and delay category
  - `incident_id` surrogate key
  - `delivery_status`, `delay_category`, `is_on_time`, `is_delayed`, `incident_type`

## Data Flow
```
CSV Files → stg_shipments → fact_shipments
                   ↓
      dim_routes, dim_vehicles, dim_incidents
```

## Testing
See `../tests/` directory for data quality tests including:
- Unique `shipment_id` validation
- Not null constraints on key columns
- Valid weight (> 0)
- Delay minutes not null
- Timestamp freshness and format
- Cross-file duplicate detection
- Null rate analysis
- Statistical outlier detection

## Column Reference
### Original CSV Columns
- `shipment_id`: Unique identifier (UUID format)
- `timestamp`: Event timestamp (ISO 8601 format)
- `origin`: Origin location
- `destination`: Destination location
- `weight_kg`: Weight in kilograms
- `delivery_status`: Delivery status (e.g., DELIVERED, IN_TRANSIT)
- `vehicle_type`: Type of vehicle
- `estimated_delay_minutes`: Estimated delay in minutes (can be negative)

### Calculated Fields (fact_shipments)
- `event_date`: Date portion of timestamp
- `event_hour`: Hour portion of timestamp
- `is_on_time`: TRUE if delay ≤ 0
- `is_delayed`: TRUE if delay > 0
