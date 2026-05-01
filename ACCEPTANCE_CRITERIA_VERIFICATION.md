# ✅ Verificação de Critérios de Aceitação

Data: 2025-05-01  
Projeto: Logística-ME - Forecast de Risco

---

## 1. Script Python que chama API GET CSV e salva localmente

**Critério**: O projeto deve conter script Python que chama a API de datasets via GET com o formato CSV especificado e salva localmente antes de qualquer transformação.

**Status**: ✅ ATENDIDO

**Evidência**:
- **Arquivo**: `API.py`
- **Funcionalidade**:
  - Baixa dados via GET de `https://api.datamission.com.br/projects/{project_id}/dataset?format=csv`
  - Autenticação com token do `.env` (API_KEY_DATASET)
  - Salva arquivos em `data/raw/dataset_{project_id}_{seq:05d}.csv`
  - Executa **antes** de qualquer transformação
  - Inclui testes de qualidade integrados (`run_data_test()`)
- **Linhas de código**: 1-337

```python
# Exemplo de uso:
response = requests.get(url, headers=headers)
with open(filepath, "wb") as file:
    file.write(response.content)
```

---

## 2. Modelos dbt documentados que referenciam arquivos da API

**Critério**: Devem existir modelos dbt documentados que referenciem os arquivos resultantes do download da API.

**Status**: ✅ ATENDIDO

**Evidência**:

### 2.1 Modelo Staging que referencia seed
- **Arquivo**: `logistica_dbt/models/staging/stg_shipments.sql`
- **Referência**: `FROM {{ ref('shipments') }}`
- **Função**: Converte CSV → tipos estruturados (timestamp, numeric, integer)

### 2.2 Seeds que consumem arquivos processados
- **Arquivos**: `logistica_dbt/seeds/shipments_*.csv`
- **Origem**: Copiados de `data/processed/` por `incremental_dbt_seed.py`
- **Loop**: `API.py → data_processing_pipeline.py → incremental_dbt_seed.py → dbt seed`

### 2.3 Modelos downstream que referenciam staging
- `fact_shipments.sql`: `FROM {{ ref('stg_shipments') }}`
- `dim_routes.sql`: `FROM {{ ref('stg_shipments') }}`
- `dim_vehicles.sql`: `FROM {{ ref('stg_shipments') }}`
- `dim_incidents.sql`: `FROM {{ ref('stg_shipments') }}`
- Todos os modelos de risco referenciam `fact_shipments` ou dimensões

### 2.4 Documentação
- `logistica_dbt/models/README.md`: Documenta todos os modelos
- `logistica_dbt/models/marts/schema.yml`: Schema completo com descrições de colunas

---

## 3. Instruções claras no README para gerar datasets Power BI

**Critério**: A pasta de entrega deve incluir instruções claras (README) sobre como gerar os datasets consumidos pelo Power BI a partir do pipeline.

**Status**: ✅ ATENDIDO

**Evidência**:

### 3.1 Seção dedicada no README.md
- **Seção**: "4. Power BI Integration" → "Gerando Datasets para Power BI" (linhas 172-220)
- **Passos claros**:
  1. Baixar dados da API: `python API.py --count 1`
  2. Processar/limpar: `python data_processing_pipeline.py`
  3. Carregar no PostgreSQL: `python incremental_dbt_seed.py`
  4. Executar transformações: `cd logistica_dbt && dbt run --profiles-dir .`
  5. Executar testes: `dbt test --profiles-dir .`

### 3.2 Tabelas listadas para Power BI
- Core: `fact_shipments`, `dim_routes`, `dim_vehicles`, `dim_incidents`
- Risk: `risk_route_analysis`, `risk_vehicle_analysis`, `risk_temporal_patterns`, `risk_delay_drivers`, `risk_forecast_features`
- Quality: `test_registry`

### 3.3 Instruções de atualização incremental
- Comandos diários simplificados (linhas 216-219)

---

## 4. Testes/instrumentos dbt para conformidade com expectativas de negócio

**Critério**: Devem ser incluídos testes/instrumentos dbt que assegurem a conformidade das transformações com as expectativas de negócio.

**Status**: ✅ ATENDIDO

**Evidência**:

### 4.1 Testes de qualidade de dados (logistica_dbt/tests/)
**9 arquivos de testes SQL**:
- `valid_timestamp_format.sql`: Valida formato ISO 8601
- `valid_weight_kg.sql`: Valida weight_kg > 0
- `valid_delay_minutes.sql`: Valida estimated_delay_minutes NOT NULL
- `cross_file_duplicate_detection.sql`: Detecta shipment_id duplicados
- `timestamp_freshness.sql`: Verifica timestamps excessivamente futuros
- `null_rate_analysis.sql`: Analisa taxa de nulos por coluna
- `statistical_outlier_detection.sql`: Detecta outliers (>3σ ou IQR×1.5)
- `data_freshness_score.sql`: Score de atualidade
- `valid_delay_minutes.sql`: Delay minutes not null

### 4.2 Testes de schema (schema.yml)
Definidos em `logistica_dbt/models/marts/schema.yml`:

**fact_shipments**:
- `unique` + `not_null` em `shipment_id`
- `not_null` em `event_timestamp`, `route_id`, `vehicle_id`, `incident_id`
- `positive_value` em `weight_kg`
- `accepted_values` em `is_on_time` e `is_delayed` ([true, false])
- `relationships` com dimensões
- **Testes de consistência de negócio**:
  - `dbt_utils.expression_is_true`: `(estimated_delay_minutes <= 0 AND is_on_time = true) OR (estimated_delay_minutes > 0 AND is_on_time = false)`
  - `dbt_utils.expression_is_true`: `(estimated_delay_minutes > 0 AND is_delayed = true) OR (estimated_delay_minutes <= 0 AND is_delayed = false)`

**dim_routes**:
- `unique` + `not_null` em `route_id`
- `not_null` em `origin` e `destination`

**dim_vehicles**:
- `unique` + `not_null` em `vehicle_id`
- `not_null` em `vehicle_type`

**dim_incidents**:
- `unique` + `not_null` em `incident_id`
- `not_null` em `delivery_status` e `delay_category`
- `accepted_values` em `delay_category`: ['ON_TIME','MINOR_DELAY','MODERATE_DELAY','MAJOR_DELAY']

**Modelos de risco**:
- `risk_route_analysis`: `dbt_utils.expression_is_true` para `pct_delayed` (0-100), `risk_score` (0-100), `accepted_values` em `risk_category` (HIGH/MEDIUM/LOW)
- `risk_vehicle_analysis`: similar
- `risk_temporal_patterns`: `dbt_utils.expression_is_true` para `pct_delayed`
- `risk_forecast_features`: validações de ranges (0-100) e categorias aceitas

### 4.3 Tabela de registro de testes (test_registry)
- **Seed**: `logistica_dbt/seeds/test_registry.csv` + `schema.yml`
- **Campos**: `test_name`, `test_type`, `phase`, `tool`, `metric`, `description`, `model_name`
- **Conteúdo**: 35 testes catalogados
- **Como gerar**: `dbt seed --select test_registry`

### 4.4 Modelo agregador de resultados
- **Arquivo**: `logistica_dbt/models/marts/test_results.sql`
- **Função**: Executa verificações diretamente em `stg_shipments` e agrega falhas
- **Categorias**: data_quality, uniqueness, timeliness, completeness, accuracy
- **Status**: PASS/FAIL baseado em contagem de falhas

---

## Resumo Final

| Critério | Status | Evidência |
|----------|--------|-----------|
| 1. Script Python API GET CSV | ✅ | `API.py` (linhas 1-337) |
| 2. Modelos dbt documentados referenciando API | ✅ | `stg_shipments.sql` + seeds + schema.yml |
| 3. README com instruções Power BI | ✅ | README.md seções 4 e 6 |
| 4. Testes dbt para conformidade | ✅ | 9 testes SQL + schema.yml + test_registry + test_results.sql |

**Todos os critérios foram atendidos**. O projeto está pronto para entrega.
