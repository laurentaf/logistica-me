# Power BI Dashboard — Logística-ME

## KPIs Críticos de Atraso

| KPI | Fórmula / Origem | Descrição |
|-----|-----------------|-----------|
| **Taxa de Atraso (%)** | `COUNTROWS(FILTER(fact_shipments, is_delayed = TRUE)) / COUNTROWS(fact_shipments)` | Percentual de remessas com atraso |
| **Atraso Médio (min)** | `AVERAGE(fact_shipments[estimated_delay_minutes])` | Tempo médio de atraso |
| **Atraso Máximo (min)** | `MAX(fact_shipments[estimated_delay_minutes])` | Maior atraso registrado |
| **Remessas no Prazo (%)** | `COUNTROWS(FILTER(fact_shipments, is_on_time = TRUE)) / COUNTROWS(fact_shipments)` | Percentual de entregas no prazo |
| **Score de Risco Médio** | `AVERAGE(risk_route_analysis[risk_score])` | Risco médio por rota |
| **Volume Total** | `COUNTROWS(fact_shipments)` | Total de remessas analisadas |
| **Peso Total (kg)** | `SUM(fact_shipments[weight_kg])` | Peso total transportado |
| **Rota Mais Arriscada** | `TOPN(1, risk_route_analysis, risk_route_analysis[risk_score])` | Rota com maior score de risco |

## Layout Sugerido (4 páginas)

---

### Página 1: Visão Geral (Executive Summary)

```
┌─────────────────────────────────────────────────────────────┐
│  Header: [Logística-ME]  Período: [Date Slicer]            │
├────────────┬────────────┬────────────┬──────────────────────┤
│  Taxa de   │  Atraso    │  Remessas  │  Volume Total        │
│  Atraso    │  Médio     │  no Prazo  │  36.000              │
│  42,3%     │  18 min    │  57,7%     │                      │
├────────────┴────────────┴────────────┴──────────────────────┤
│  Gráfico: Linha → Taxa de Atraso ao longo do tempo          │
│  (event_date no eixo X, % delayed no eixo Y)                │
├─────────────────────────────────────────────────────────────┤
│  Gráfico: Barras → Top 10 Rotas com maior atraso médio      │
│  (route_name no eixo X, avg_delay_minutes no eixo Y)        │
├─────────────────────────────────────────────────────────────┤
│  Tabela: risk_route_analysis (route, pct_delayed,           │
│           avg_delay_minutes, risk_score, risk_category)     │
└─────────────────────────────────────────────────────────────┘
```

**Elementos:**
- Card: Taxa de Atraso % (formato percentual)
- Card: Atraso Médio em minutos
- Card: Remessas no Prazo %
- Card: Volume Total
- Line Chart: Taxa de Atraso por dia
- Bar Chart: Top 10 rotas por atraso médio
- Table: Detalhamento por rota

---

### Página 2: Análise de Risco por Rota e Veículo

```
┌─────────────────────────────────────────────────────────────┐
│  Filtros: [Route] [Vehicle Type] [Delay Category]           │
├──────────────────────┬──────────────────────────────────────┤
│  Mapa de Calor       │  Gráfico: Rosca → Distribuição       │
│  Rotas (origem ×     │  por delay_category                  │
│  destino) com        │  (ON_TIME, MINOR, MODERATE, MAJOR)   │
│  risk_score          │                                      │
├──────────────────────┴──────────────────────────────────────┤
│  Gráfico: Barras Agrupadas → risk_vehicle_analysis          │
│  (vehicle_type, pct_delayed, avg_delay_minutes, risk_score) │
├─────────────────────────────────────────────────────────────┤
│  Tabela: risk_delay_drivers (driver_name, pct_delayed,      │
│           avg_delay_minutes, risk_score, impact_rank)       │
└─────────────────────────────────────────────────────────────┘
```

**DAX para Matriz de Risco:**
```
Risk Score = AVERAGE(risk_route_analysis[risk_score])
Risco Alto = COUNTROWS(FILTER(risk_route_analysis, risk_route_analysis[risk_category] = "HIGH"))
Risco Baixo = COUNTROWS(FILTER(risk_route_analysis, risk_route_analysis[risk_category] = "LOW"))
```

---

### Página 3: Padrões Temporais

```
┌─────────────────────────────────────────────────────────────┐
│  Filtros: [Hora do Dia] [Dia da Semana] [É Fim de Semana]  │
├──────────────────────┬──────────────────────────────────────┤
│  Gráfico: Colunas →  │  Gráfico: Colunas →                  │
│  Taxa de Atraso por  │  Taxa de Atraso por                  │
│  Hora do Dia         │  Dia da Semana                       │
│  (time_period_label) │  (day_of_week)                       │
├──────────────────────┴──────────────────────────────────────┤
│  Gráfico: Barras → risk_temporal_patterns                   │
│  (time_period_label, pct_delayed, avg_delay_minutes)        │
│  com destaque para períodos de pico (rush hour)             │
├─────────────────────────────────────────────────────────────┤
│  Tabela: risk_forecast_features                             │
│  (event_date, total_shipments, delay_rate_pct,              │
│   route_risk_score, vehicle_risk_score,                     │
│   combined_risk_level, lag_1d_delay_rate, ma_7d_delay_rate) │
└─────────────────────────────────────────────────────────────┘
```

**DAX para Identificar Pico:**
```
Is Peak Period = SWITCH(TRUE(),
    SELECTEDVALUE(risk_temporal_patterns[time_period]) = "MORNING_RUSH", TRUE,
    SELECTEDVALUE(risk_temporal_patterns[time_period]) = "AFTERNOON_RUSH", TRUE,
    FALSE
)
```

---

### Página 4: Forecasting e Tendências

```
┌─────────────────────────────────────────────────────────────┐
│  Filtros: [Route] [Vehicle] [Combined Risk Level]           │
├──────────────────────┬──────────────────────────────────────┤
│  Gráfico: Linha →    │  Gráfico: Área →                    │
│  delay_rate_pct      │  total_shipments por dia             │
│  + lag_1d + ma_7d    │                                      │
├──────────────────────┴──────────────────────────────────────┤
│  Gráfico: Dispersão → route_risk_score × vehicle_risk_score │
│  (cada ponto = rota-veículo, cor = combined_risk_level)     │
├─────────────────────────────────────────────────────────────┤
│  Tabela: risk_forecast_features com formatação condicional  │
│  (combined_risk_level: HIGH=vermelho, MEDIUM=amarelo,      │
│   LOW=verde)                                                │
└─────────────────────────────────────────────────────────────┘
```

## Modelo de Dados (Star Schema)

```
┌───────────────────┐     ┌──────────────────┐
│   dim_routes      │     │  dim_vehicles     │
│   PK: route_id    │     │  PK: vehicle_id   │
└──────┬────────────┘     └───────┬───────────┘
       │                          │
       ▼                          ▼
┌──────────────────────────────────────────────┐
│              fact_shipments                   │
│  PK: shipment_id                             │
│  FK: route_id → dim_routes                   │
│  FK: vehicle_id → dim_vehicles               │
│  FK: incident_id → dim_incidents             │
│  Metrics: weight_kg, estimated_delay_minutes │
│  Flags: is_on_time, is_delayed               │
│  Dates: event_timestamp, event_date,         │
│         event_hour                           │
└──────────────────┬───────────────────────────┘
                   │
                   ▼
┌──────────────────────────────┐
│      dim_incidents           │
│  PK: incident_id             │
│  delivery_status,            │
│  delay_category,             │
│  is_on_time, is_delayed      │
└──────────────────────────────┘

┌─────────────────────────────────────────────┐
│  Risk Analysis Models (pré-agregados)        │
│  ─────────────────────────                  │
│  risk_route_analysis                         │
│  risk_vehicle_analysis                       │
│  risk_temporal_patterns                      │
│  risk_delay_drivers                          │
│  risk_forecast_features                      │
└─────────────────────────────────────────────┘
```

## Conexão com Power BI

### Opção A: Conexão Direta ao PostgreSQL (DirectQuery)
1. Power BI Desktop → Obter Dados → PostgreSQL
2. Servidor: `localhost` (ou IP do servidor PostgreSQL)
3. Banco: `logistica_db`
4. Modo: DirectQuery (dados sempre atualizados)
5. Relacionamentos criados automaticamente pelas FKs

### Opção B: Importar CSV Exportado
1. Execute `python export_powerbi_dataset.py`
2. Power BI Desktop → Obter Dados → Texto/CSV
3. Selecione o arquivo em `data/powerbi/logistica_me_dataset_*.csv`
4. Importe também os CSVs de risco em `data/powerbi/`
5. Crie relacionamentos manuais:
   - risk_route_analysis.route_id → fato.route_id
   - risk_vehicle_analysis.vehicle_id → fato.vehicle_id

### Opção C: Pipeline Automatizado com Docker
```powershell
docker-compose -f docker-compose.powerbi.yml up
# Gera CSVs atualizados em data/powerbi/
```

## Medidas DAX Recomendadas

```dax
// KPI Principal: Taxa de Atraso
DELAY_RATE = DIVIDE(
    COUNTROWS(FILTER(fact_shipments, fact_shipments[is_delayed])),
    COUNTROWS(fact_shipments),
    0
)

// Atraso Médio
AVG_DELAY = AVERAGE(fact_shipments[estimated_delay_minutes])

// Remessas no Prazo
ON_TIME_RATE = DIVIDE(
    COUNTROWS(FILTER(fact_shipments, fact_shipments[is_on_time])),
    COUNTROWS(fact_shipments),
    0
)

// Volume Total
TOTAL_SHIPMENTS = COUNTROWS(fact_shipments)

// Categoria de Risco por Rota
ROUTE_RISK = SELECTEDVALUE(risk_route_analysis[risk_category])

// Score de Risco Máximo
MAX_RISK_SCORE = MAX(risk_route_analysis[risk_score])
```

## Formatação Condicional

| Coluna | Regra | Cor |
|--------|-------|-----|
| `risk_category` | HIGH | Vermelho (#FF0000) |
| `risk_category` | MEDIUM | Amarelo (#FFD700) |
| `risk_category` | LOW | Verde (#00FF00) |
| `combined_risk_level` | HIGH | Vermelho |
| `combined_risk_level` | MEDIUM | Amarelo |
| `combined_risk_level` | LOW | Verde |
| `delay_rate_pct` | > 50% | Vermelho (#FF4444) |
| `delay_rate_pct` | 25-50% | Amarelo (#FFAA00) |
| `delay_rate_pct` | < 25% | Verde (#44FF44) |
