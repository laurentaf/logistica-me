#!/usr/bin/env python3
"""
Preview de Estrutura de Tabelas dbt
Mostra a estrutura (colunas e tipos) esperada para cada modelo
sem precisar executar o dbt nem conectar ao PostgreSQL.
"""

print("=" * 80)
print("PREVIEW DE ESTRUTURAS DE TABELAS - PROJETO LOGISTICA-ME")
print("=" * 80)

models = {
    "stg_shipments": {
        "descrição": "Staging: limpeza e cast de tipos a partir dos CSV",
        "colunas": [
            ("shipment_id", "VARCHAR / UUID", "Identificador único da remessa"),
            ("event_timestamp", "TIMESTAMP", "Timestamp convertido para tipo timestamp"),
            ("origin", "VARCHAR", "Origem da remessa"),
            ("destination", "VARCHAR", "Destino da remessa"),
            ("weight_kg", "NUMERIC", "Peso em kg (cast)"),
            ("delivery_status", "VARCHAR", "Status da entrega"),
            ("vehicle_type", "VARCHAR", "Tipo de veículo"),
            ("estimated_delay_minutes", "INTEGER", "Atraso estimado em minutos (cast)")
        ]
    },
    "dim_routes": {
        "descrição": "Dimensão de rotas (origem-destino)",
        "colunas": [
            ("route_id", "INTEGER", "Chave surrogate (PK)"),
            ("origin", "VARCHAR", "Origem"),
            ("destination", "VARCHAR", "Destino"),
            ("route_name", "VARCHAR", "Nome formatado: 'origin → destination'")
        ]
    },
    "dim_vehicles": {
        "descrição": "Dimensão de tipos de veículo",
        "colunas": [
            ("vehicle_id", "INTEGER", "Chave surrogate (PK)"),
            ("vehicle_type", "VARCHAR", "Tipo de veículo (ex: AIRPLANE, MOTORCYCLE)")
        ]
    },
    "dim_incidents": {
        "descrição": "Dimensão de incidentes/ocorrências baseada em status e categoria de atraso",
        "colunas": [
            ("incident_id", "INTEGER", "Chave surrogate (PK)"),
            ("delivery_status", "VARCHAR", "Status da entrega"),
            ("delay_category", "VARCHAR", "Categoria: ON_TIME, MINOR_DELAY, MODERATE_DELAY, MAJOR_DELAY"),
            ("is_on_time", "BOOLEAN", "TRUE se delay <= 0"),
            ("is_delayed", "BOOLEAN", "TRUE se delay > 0"),
            ("incident_type", "VARCHAR", "Combinado: 'status - category'")
        ]
    },
    "fact_shipments": {
        "descrição": "Tabela fato principal com métricas de atraso e FKs para dimensões",
        "colunas": [
            ("shipment_id", "VARCHAR / UUID", "PK (ou FK para stg)"),
            ("event_timestamp", "TIMESTAMP", "Timestamp do evento"),
            ("route_id", "INTEGER", "FK → dim_routes"),
            ("vehicle_id", "INTEGER", "FK → dim_vehicles"),
            ("incident_id", "INTEGER", "FK → dim_incidents"),
            ("weight_kg", "NUMERIC", "Peso da remessa"),
            ("estimated_delay_minutes", "INTEGER", "Atrraso estimado"),
            ("is_on_time", "BOOLEAN", "TRUE se <= 0"),
            ("is_delayed", "BOOLEAN", "TRUE se > 0"),
            ("event_date", "DATE", "Data truncada (dia)"),
            ("event_hour", "INTEGER", "Hora truncada (0-23)")
        ]
    },
    "risk_route_analysis": {
        "descrição": "Análise de risco por rota (score 0-100)",
        "colunas": [
            ("route_id", "INTEGER", "FK → dim_routes"),
            ("origin", "VARCHAR", "Origem da rota"),
            ("destination", "VARCHAR", "Destino da rota"),
            ("route_name", "VARCHAR", "Nome da rota"),
            ("total_shipments", "INTEGER", "Total de remessas na rota"),
            ("delayed_shipments", "INTEGER", "Remessas atrasadas"),
            ("on_time_shipments", "INTEGER", "Remessas no prazo"),
            ("avg_delay_minutes", "NUMERIC", "Média de atraso"),
            ("median_delay_minutes", "NUMERIC", "Mediana (PERCENTILE_CONT 0.5)"),
            ("max_delay_minutes", "INTEGER", "Máximo atraso"),
            ("stddev_delay_minutes", "NUMERIC", "Desvio padrão"),
            ("q1_delay", "NUMERIC", "1º quartil (25%)"),
            ("q3_delay", "NUMERIC", "3º quartil (75%)"),
            ("pct_delayed", "NUMERIC(5,2)", "Percentual atrasado (0-100)"),
            ("risk_score", "NUMERIC(5,2)", "Score de risco (0-100)"),
            ("risk_category", "VARCHAR", "HIGH / MEDIUM / LOW"),
            ("first_shipment_date", "TIMESTAMP", "Data da primeira remessa"),
            ("last_shipment_date", "TIMESTAMP", "Data da última remessa"),
            ("heavy_shipments_count", "INTEGER", "Remessas > 1000kg"),
            ("pct_heavy_shipments", "NUMERIC(5,2)", "% remessas pesadas")
        ]
    },
    "risk_vehicle_analysis": {
        "descrição": "Análise de risco por tipo de veículo (score 0-100)",
        "colunas": [
            ("vehicle_id", "INTEGER", "FK → dim_vehicles"),
            ("vehicle_type", "VARCHAR", "Tipo de veículo"),
            ("total_shipments", "INTEGER", "Total remessas"),
            ("delayed_shipments", "INTEGER", "Remessas atrasadas"),
            ("on_time_shipments", "INTEGER", "Remessas no prazo"),
            ("avg_delay_minutes", "NUMERIC", "Média atraso"),
            ("median_delay_minutes", "NUMERIC", "Mediana"),
            ("max_delay_minutes", "INTEGER", "Máximo"),
            ("stddev_delay_minutes", "NUMERIC", "Desvio padrão"),
            ("q1_delay", "NUMERIC", "1º quartil"),
            ("q3_delay", "NUMERIC", "3º quartil"),
            ("pct_delayed", "NUMERIC(5,2)", "% atrasado"),
            ("risk_score", "NUMERIC(5,2)", "Score (0-100)"),
            ("risk_category", "VARCHAR", "HIGH/MEDIUM/LOW"),
            ("avg_weight_kg", "NUMERIC", "Peso médio"),
            ("median_weight_kg", "NUMERIC", "Mediana peso"),
            ("heavy_shipments_count", "INTEGER", "Remessas >1000kg"),
            ("pct_heavy_shipments", "NUMERIC(5,2)", "% remessas pesadas"),
            ("avg_event_hour", "NUMERIC", "Hora média dos eventos")
        ]
    },
    "risk_temporal_patterns": {
        "descrição": "Padrões temporais de atraso (hora/dia da semana)",
        "colunas": [
            ("event_date", "DATE", "Data do evento"),
            ("event_hour", "INTEGER", "Hora do evento (0-23)"),
            ("day_of_week", "INTEGER", "0=Dom, 6=Sáb"),
            ("is_weekend", "BOOLEAN", "TRUE se fim de semana"),
            ("time_of_day_bucket", "VARCHAR", "MORNING_RUSH, MIDDAY, AFTERNOON_RUSH, EVENING, NIGHT"),
            ("total_shipments", "INTEGER", "Total no período"),
            ("delayed_shipments", "INTEGER", "Atrasadas no período"),
            ("avg_delay_minutes", "NUMERIC", "Média atraso"),
            ("median_delay_minutes", "NUMERIC", "Mediana"),
            ("max_delay_minutes", "INTEGER", "Máximo"),
            ("stddev_delay_minutes", "NUMERIC", "Desvio padrão"),
            ("pct_delayed", "NUMERIC(5,2)", "% atrasado"),
            ("avg_weight_kg", "NUMERIC", "Peso médio"),
            ("heavy_shipments_count", "INTEGER", "Remessas pesadas no período"),
            ("most_common_vehicle_type", "VARCHAR", "Veículo mais frequente")
        ]
    },
    "risk_delay_drivers": {
        "descrição": "Análise multidimensional de drivers (route×vehicle, route×time, vehicle×time, weight×delay, ranking geral)",
        "colunas": [
            ("analysis_type", "VARCHAR", "ROUTE_VEHICLE, ROUTE_TIME, VEHICLE_TIME, WEIGHT_DELAY, OVERALL_RANKING"),
            ("factor_type", "VARCHAR", "ROUTE, VEHICLE, TIME, WEIGHT (quando aplicável)"),
            ("route_id", "INTEGER", "FK → dim_routes (quando aplicável)"),
            ("route_name", "VARCHAR", "Nome da rota"),
            ("vehicle_id", "INTEGER", "FK → dim_vehicles (quando aplicável)"),
            ("vehicle_type", "VARCHAR", "Tipo de veículo"),
            ("secondary_factor", "VARCHAR", "Fator secundário (ex: time_of_day, weight_category)"),
            ("tertiary_factor", "VARCHAR", "Fator terciário (ex: weekday_weekend, delay_category)"),
            ("total_shipments", "INTEGER", "Total na combinação"),
            ("delayed_shipments", "INTEGER", "Atrasadas na combinação"),
            ("delay_rate_pct", "NUMERIC(5,2)", "Taxa atraso (%)"),
            ("avg_delay", "NUMERIC", "Atraso médio"),
            ("median_delay", "NUMERIC", "Mediana"),
            ("max_delay", "INTEGER", "Máximo atraso"),
            ("driver_dimension", "VARCHAR", "Nome da dimensão analisada")
        ]
    },
    "risk_forecast_features": {
        "descrição": "Features para forecasting (por data, rota, veículo, período do dia)",
        "colunas": [
            ("event_date", "DATE", "Data"),
            ("route_id", "INTEGER", "FK → dim_routes"),
            ("vehicle_id", "INTEGER", "FK → dim_vehicles"),
            ("time_of_day_bucket", "VARCHAR", "Período do dia"),
            ("weekday_weekend", "VARCHAR", "WEEKDAY ou WEEKEND"),
            ("avg_weight_kg", "NUMERIC", "Peso médio no dia/período"),
            ("total_shipments", "INTEGER", "Total remessas"),
            ("delayed_shipments", "INTEGER", "Remessas atrasadas"),
            ("on_time_shipments", "INTEGER", "Remessas no prazo"),
            ("avg_delay_minutes", "NUMERIC", "Atraso médio do dia"),
            ("median_delay_minutes", "NUMERIC", "Mediana atraso"),
            ("max_delay_minutes", "INTEGER", "Máximo atraso"),
            ("stddev_delay_minutes", "NUMERIC", "Desvio padrão"),
            ("q1_delay", "NUMERIC", "1º quartil"),
            ("q3_delay", "NUMERIC", "3º quartil"),
            ("delay_rate_pct", "NUMERIC(5,2)", "Taxa atraso (%)"),
            ("heavy_shipment_pct", "NUMERIC(5,2)", "% remessas >1000kg"),
            ("most_common_delay_category", "VARCHAR", "Categoria de atraso mais frequente"),
            ("most_common_vehicle_type", "VARCHAR", "Veículo mais frequente"),
            ("route_risk_score", "NUMERIC(5,2)", "Score da rota (do risk_route_analysis)"),
            ("route_risk_category", "VARCHAR", "Categoria de risco da rota"),
            ("vehicle_risk_score", "NUMERIC(5,2)", "Score do veículo (do risk_vehicle_analysis)"),
            ("vehicle_risk_category", "VARCHAR", "Categoria de risco do veículo"),
            ("combined_risk_level", "VARCHAR", "HIGH/MEDIUM/LOW combinado"),
            ("prev_day_shipments", "INTEGER", "Lag: remessas dia anterior"),
            ("prev_day_avg_delay", "NUMERIC", "Lag: atraso médio dia anterior"),
            ("prev_day_delay_rate", "NUMERIC(5,2)", "Lag: taxa atraso dia anterior"),
            ("moving_avg_7day_delay", "NUMERIC", "Média móvel 7 dias atraso"),
            ("moving_avg_7day_delay_rate", "NUMERIC(5,2)", "Média móvel 7 dias taxa"),
            ("delay_change_from_prev_day", "NUMERIC", "Variação atraso vs dia anterior"),
            ("delay_rate_change_from_prev_day", "NUMERIC(5,2)", "Variação taxa vs dia anterior")
        ]
    },
    "test_registry": {
        "descrição": "Catálogo de todos os testes (seed carregado via dbt seed)",
        "colunas": [
            ("test_name", "VARCHAR", "Nome único do teste"),
            ("test_type", "VARCHAR", "completeness, uniqueness, validity, accuracy, timeliness..."),
            ("phase", "VARCHAR", "staging, marts, dimension"),
            ("tool", "VARCHAR", "dbt, custom_python"),
            ("metric", "VARCHAR", "Métrica/coluna que o teste valida"),
            ("description", "TEXT", "Descrição do teste"),
            ("model_name", "VARCHAR", "Modelo ao qual o teste pertence")
        ]
    }
}

for model_name, info in models.items():
    print(f"\n📊 {model_name}")
    print(f"   {info['descrição']}")
    print("   " + "-" * 76)
    for col, dtype, desc in info["colunas"]:
        print(f"   {col:<35} {dtype:<25} {desc}")
    print()

print("=" * 80)
print("✅ Para compilar e popular no PostgreSQL, execute:")
print("""
1. cd logistica_dbt
2. dbt seed --profiles-dir .         # Carrega test_registry e outros seeds
3. dbt run --profiles-dir .          # Executa todos os modelos
4. dbt test --profiles-dir .         # Executa testes de qualidade
""")
print("=" * 80)
