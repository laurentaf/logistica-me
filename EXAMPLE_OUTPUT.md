# Exemplos de Primeira Linha - Todos os Modelos

Este documento mostra exemplos da estrutura e dados esperados em cada tabela após execução do pipeline dbt.

---

## stg_shipments

| shipment_id | event_timestamp | origin | destination | weight_kg | delivery_status | vehicle_type | estimated_delay_minutes |
|------------|-----------------|---------|-------------|-----------|-----------------|--------------|------------------------|
| 550e8400-e29b-41d4-a716-446655440000 | 2025-05-01 14:30:00 | São Paulo | Rio de Janeiro | 245.5 | DELIVERED | TRUCK | 15 |

**Observação**: Tipos convertidos: `timestamp` → TIMESTAMP, `weight_kg` → NUMERIC, `estimated_delay_minutes` → INTEGER.

---

## dim_routes

| route_id | origin | destination | route_name |
|---------|--------|-------------|------------|
| 1 | São Paulo | Rio de Janeiro | São Paulo → Rio de Janeiro |

---

## dim_vehicles

| vehicle_id | vehicle_type |
|-----------|--------------|
| 1 | TRUCK |
| 2 | AIRPLANE |
| 3 | MOTORCYCLE |

---

## dim_incidents

| incident_id | delivery_status | delay_category | is_on_time | is_delayed | incident_type |
|------------|-----------------|----------------|------------|------------|---------------|
| 1 | DELIVERED | ON_TIME | true | false | DELIVERED - ON_TIME |
| 2 | DELIVERED | MINOR_DELAY | false | true | DELIVERED - MINOR_DELAY |
| 3 | IN_TRANSIT | MODERATE_DELAY | false | true | IN_TRANSIT - MODERATE_DELAY |
| 4 | DELAYED | MAJOR_DELAY | false | true | DELAYED - MAJOR_DELAY |

---

## fact_shipments

| shipment_id | event_timestamp | route_id | vehicle_id | incident_id | weight_kg | estimated_delay_minutes | is_on_time | is_delayed | event_date | event_hour |
|------------|-----------------|----------|------------|-------------|-----------|------------------------|------------|------------|------------|------------|
| 550e8400-e29b-41d4-a716-446655440000 | 2025-05-01 14:30:00 | 1 | 1 | 2 | 245.5 | 15 | false | true | 2025-05-01 | 14 |

**Observação**: Chaves estrangeiras apontam para as dimensões. Colunas derivadas `is_on_time` e `is_delayed` são calculadas a partir de `estimated_delay_minutes`.

---

## risk_route_analysis

| route_id | origin | destination | route_name | total_shipments | delayed_shipments | on_time_shipments | avg_delay_minutes | median_delay_minutes | max_delay_minutes | stddev_delay_minutes | q1_delay | q3_delay | pct_delayed | risk_score | risk_category |
|----------|--------|-------------|------------|-----------------|-------------------|-------------------|-------------------|---------------------|-------------------|----------------------|----------|----------|-------------|------------|---------------|
| 1 | São Paulo | Rio de Janeiro | São Paulo → Rio de Janeiro | 1500 | 450 | 1050 | 25.3 | 20 | 180 | 15.7 | 10 | 35 | 30.00 | 42.5 | MEDIUM |

**Cálculo do risk_score**: Combinação ponderada: (avg_delay/120 * 50) + (pct_delayed/100 * 50), limitado a 120 min e 100%.

---

## risk_vehicle_analysis

| vehicle_id | vehicle_type | total_shipments | delayed_shipments | on_time_shipments | avg_delay_minutes | median_delay_minutes | max_delay_minutes | stddev_delay_minutes | q1_delay | q3_delay | pct_delayed | risk_score | risk_category |
|-----------|--------------|-----------------|-------------------|-------------------|-------------------|---------------------|-------------------|----------------------|----------|----------|-------------|------------|---------------|
| 3 | MOTORCYCLE | 800 | 320 | 480 | 35.2 | 28 | 210 | 22.4 | 15 | 48 | 40.00 | 68.3 | HIGH |

**Insight**: Motocicletas podem ter maior risco de atraso em áreas urbanas congestionadas.

---

## risk_temporal_patterns

| event_date | event_hour | day_of_week | is_weekend | time_of_day_bucket | total_shipments | delayed_shipments | avg_delay_minutes | median_delay_minutes | max_delay_minutes | stddev_delay_minutes | pct_delayed |
|-----------|------------|-------------|------------|-------------------|-----------------|-------------------|-------------------|---------------------|-------------------|----------------------|-------------|
| 2025-05-01 | 8 | 4 | false | MORNING_RUSH | 200 | 60 | 22.5 | 18 | 95 | 12.3 | 30.00 |

**Interpretação**: Pico das 8h da manhã (rush hour) tem taxa de atraso de 30%.

---

## risk_delay_drivers

Exemplo de linha para `analysis_type = 'ROUTE_VEHICLE'`:

| analysis_type | factor_type | route_id | route_name | vehicle_id | vehicle_type | total_shipments | delayed_shipments | delay_rate_pct | avg_delay | median_delay | max_delay | driver_dimension |
|--------------|-------------|----------|------------|------------|--------------|-----------------|-------------------|----------------|-----------|--------------|-----------|-----------------|
| ROUTE_VEHICLE | ROUTE | 1 | São Paulo → Rio de Janeiro | 3 | MOTORCYCLE | 120 | 54 | 45.00 | 38.5 | 32 | 180 | ROUTE_VEHICLE |

**Insight**: Combinação rota X motocicleta tem taxa de atraso de 45% - fator crítico.

---

## risk_forecast_features

| event_date | route_id | vehicle_id | time_of_day_bucket | weekday_weekend | total_shipments | delayed_shipments | delay_rate_pct | route_risk_score | route_risk_category | vehicle_risk_score | vehicle_risk_category | combined_risk_level | prev_day_shipments | prev_day_avg_delay | moving_avg_7day_delay |
|-----------|----------|------------|--------------------|-----------------|-----------------|-------------------|----------------|------------------|--------------------|-------------------|----------------------|----------------------|---------------------|-------------------|--------------------|------------------------|
| 2025-05-01 | 1 | 3 | MORNING_RUSH | WEEKDAY | 120 | 54 | 45.00 | 42.5 | MEDIUM | 68.3 | HIGH | HIGH | 115 | 36.2 | 34.8 |

**Features de forecasting**:
- `prev_day_*`: lag de 1 dia paradetecção de tendência
- `moving_avg_7day_delay`: média móvel para suavização
- `combined_risk_level`: risco combinado da rota + veículo

---

## test_registry

| test_name | test_type | phase | tool | metric | description | model_name |
|-----------|-----------|-------|------|--------|-------------|------------|
| stg_shipments_shipment_id_not_null | completeness | staging | dbt | shipment_id | Valida shipment_id is not null | stg_shipments |
| fact_shipments_is_on_time_consistency | validity | marts | dbt | is_on_time | Valida consistência com estimated_delay_minutes | fact_shipments |
| risk_route_analysis_risk_score_range | accuracy | marts | dbt | risk_score | Valida risk_score entre 0 e 100 | risk_route_analysis |

---

## Como Executar

```bash
# 1. Baixar dados
python API.py --count 1

# 2. Processar
python data_processing_pipeline.py

# 3. Carregar no PostgreSQL
python incremental_dbt_seed.py

# 4. Executar modelos dbt
cd logistica_dbt
dbt run --profiles-dir .

# 5. Ver resultados
# Opção A: usar psql
psql -U postgres -d logistica_db -f show_all_models_pure.sql

# Opção B: DBeaver / pgAdmin - executeshow_all_models_pure.sql
```

**Nota**: O schema padrão é `public`. Se usar outro schema (ex: `raw`), ajuste as queries.
