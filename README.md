# Projeto Logística-ME

**Autor da solução**: Laurent Alphonse Ferreira  
**Stack**: Python, dbt, PostgreSQL, Power BI

## Problema
Painel de Visibilidade de Entregas para Redução de Atrasos  
Desenvolver um pipeline em Python/dbt que consome os dados brutos disponibilizados pela API (https://api.datamission.com.br/projects/{project_id}/dataset?format=csv) e modela tabelas dimensionalizadas para insights de atrasos. A rotina deve deixar claro que os dados originais chegam exclusivamente pelo endpoint citado e, após transformação, gerar tabelas otimizadas e um dataset adicional pronto para visualização no Power BI.

## Contexto do Negócio
"Na Logística - ME, cada minuto de atraso representa contratos perdidos e multas que corroem o já enxuto lucro de R$ 106 milhões. Sem uma linha clara de visibilidade operacional alimentada pelos dados atualizados via API da plataforma, a empresa continuará reagindo aos atrasos em vez de preveni-los, deixando milhões em receita em risco e clientes migrando para concorrentes mais previsíveis."

## Arquitetura do Sistema

### 1. Estrutura de Dados

#### Schema dos Dados (CSV)
Cada arquivo CSV contém remessas logísticas com as seguintes colunas:

| Coluna | Tipo | Descrição |
|--------|------|-----------|
| shipment_id | string (UUID) | Identificador único da remessa |
| timestamp | ISO 8601 | Data/hora do evento de rastreamento |
| origin | string | Local de origem da remessa |
| destination | string | Local de destino da remessa |
| weight_kg | float | Peso da remessa em quilogramas |
| delivery_status | string | Status da entrega (ex: IN_TRANSIT, DELIVERED) |
| vehicle_type | string | Tipo de veículo utilizado (ex: AIRPLANE, MOTORCYCLE) |
| estimated_delay_minutes | integer | Atraso estimado em minutos |

#### Diretórios
```
data/raw/                    # Dados brutos da API
  dataset_*.csv              # Arquivos CSV originais
  dataset_*_metadata.json    # Metadados de cada download
  dataset_*_test_results.json # Resultados de testes de qualidade (gerados por API.py)
  
data/processed/              # Dados após limpeza e padronização
  dataset_*_processed.csv
  dataset_*_cleaning_report.json

logistica_dbt/              # Projeto dbt
  models/
    staging/
      stg_shipments.sql     # Staging: limpeza e padronização
    marts/
      fact_shipments.sql    # Tabela fato de remessas com métricas de atraso
      dim_routes.sql        # Dimensão de rotas (origem-destino)
      dim_vehicles.sql      # Dimensão de tipos de veículo
      dim_incidents.sql     # Dimensão de incidentes/ocorrências (atrasos)
      schema.yml            # Testes e documentação
  seeds/                    # Arquivos CSV carregados via dbt seed
    shipments_00001.csv
    shipments_00002.csv
  tests/                    # Testes de qualidade de dados
  macros/                   # Macros auxiliares

config/                    # Configuração local (não Commitada)
  seed_state.json          # Estado de carregamento incremental
```

### 2. Configuração do Banco de Dados

#### PostgreSQL Setup
**Localização**: PostgreSQL deve rodar em Docker no Windows para compatibilidade com Power BI Server

**Instalação via Docker no Windows**:

```powershell
# 1. Instalar Docker Desktop para Windows
# https://docs.docker.com/desktop/install/windows-install/

# 2. Usar docker-compose (recomendado)
docker-compose up -d

# OU usar script PowerShell simplificado
.\docker-commands.ps1

# 3. Verificar se está rodando
docker ps
docker-compose logs
```

**Arquivos de configuração**:
- `docker-compose.yml`: Configuração completa do PostgreSQL Docker
- `docker-commands.ps1`: Script PowerShell para setup automatizado
- `SETUP_POSTGRES.md`: Guia detalhado de instalação

**Configuração via .env**:
```bash
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=sua_senha_segura
POSTGRES_HOST=localhost  # Para Docker no Windows
POSTGRES_PORT=numero_da_porta
POSTGRES_DBNAME=nome_do_db
```

**Arquivo profiles.yml** (~/.dbt/profiles.yml):
```yaml
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: ${POSTGRES_HOST}  # Docker PostgreSQL no Windows, default: localhost
      user: ${POSTGRES_USERNAME}
      pass: ${POSTGRES_PASSWORD}
      port: ${POSTGRES_PORT}
      dbname: ${POSTGRES_DBNAME}
      schema: raw
      threads: 4
```

### 3. Testes de Qualidade de Dados

#### Categorias de Testes Implementadas
1. **Schema Validation**: Validação de tipos de dados e formatos
2. **Completeness Tests**: Verificação de valores nulos/missing
3. **Uniqueness Tests**: Detecção de duplicatas
4. **Validity Tests**: Validação de regras de negócio
5. **Accuracy Tests**: Validação de faixas de valores e formatos
6. **Consistency Tests**: Consistência entre arquivos
7. **Timeliness Tests**: Verificação de atualidade dos dados
8. **Integrity Tests**: Integridade de arquivos

#### Testes Específicos Implementados
- ✅ `valid_timestamp_format.sql`: Validação de timestamp ISO 8601
- ✅ `valid_weight_kg.sql`: Validação de peso positivo
- ✅ `valid_delay_minutes.sql`: Validação de atraso (não negativo)
- ✅ `cross_file_duplicate_detection.sql`: Detecção de duplicatas entre arquivos (shipment_id)
- ✅ `timestamp_freshness.sql`: Verificação de timestamps futuros
- ✅ `null_rate_analysis.sql`: Análise de taxas de valores nulos por coluna
- ✅ `statistical_outlier_detection.sql`: Detecção de outliers em peso e atraso
- ✅ `data_freshness_score.sql`: Score de atualidade dos dados

#### Registro de Testes (Test Tracking)
Todos os testes implementados são registrados na tabela `test_registry` no esquema `public` do PostgreSQL. Esta tabela contém metadados de cada teste, incluindo:

- `test_name`: Nome único do teste
- `test_type`: Tipo de teste (completeness, uniqueness, validity, accuracy, timeliness, etc.)
- `phase`: Fase do pipeline (staging, marts, dimension)
- `tool`: Ferramenta utilizada (dbt, custom_python)
- `metric`: Métrica ou coluna que o teste valida
- `description`: Descrição do que o teste verifica
- `model_name`: Modelo ao qual o teste pertence

**Como gerar a tabela de registro:**
```bash
cd logistica_dbt
dbt seed --select test_registry
```

A tabela `test_registry` estará disponível no PostgreSQL e pode ser utilizada para auditoria e monitoramento da cobertura de testes.

### 4. Power BI Integration

**Requisitos**:
- PostgreSQL rodando em Docker no Windows (recomendado)
- Power BI Server requer Windows Server
- Power BI Desktop funciona no Windows 10/11
- Docker Desktop instalado no Windows

**Conexão**:
- Usar conector nativo PostgreSQL do Power BI
- Conectar a `${POSTGRES_HOST}:${POSTGRES_PORT}` (PostgreSQL Docker)
- Principais tabelas para dashboard:
  - `fact_shipments`: Fatos de remessas com métricas de atraso
  - `dim_routes`, `dim_vehicles`, `dim_incidents`: Dimensões para slicing/dicing
  - `risk_route_analysis`, `risk_vehicle_analysis`, `risk_temporal_patterns`, `risk_delay_drivers`, `risk_forecast_features`: Modelos de previsão de risco
  - `test_registry`: Catálogo de testes de qualidade de dados

#### Gerando Datasets para Power BI

O pipeline gera automaticamente as tabelas necessárias no PostgreSQL. Siga os passos abaixo para popular o banco de dados:

**Passo 1: Baixar dados da API**
```bash
python API.py --count 1
```
- Baixa novos arquivos CSV da API para `data/raw/`
- Executa testes básicos de qualidade em cada arquivo
- Gera metadados e relatórios de conformidade

**Passo 2: Processar e limpar dados**
```bash
python data_processing_pipeline.py
```
- Limpa e padroniza os dados brutos
- Salva versão processada em `data/processed/`

**Passo 3: Carregar dados no PostgreSQL (incremental)**
```bash
python incremental_dbt_seed.py
```
- Carrega apenas arquivos novos no PostgreSQL via `dbt seed`
- Mantém histórico de arquivos carregados em `config/seed_state.json`

**Passo 4: Executar transformações dbt**
```bash
cd logistica_dbt
dbt run --profiles-dir .
```
- Executa todos os modelos: staging, dimensões, fatos, modelos de risco

**Passo 5: Executar testes de qualidade**
```bash
dbt test --profiles-dir .
```
- Valida a qualidade dos dados em todas as fases
- Exibe resultados no console

**Aplicação Pronta**: Após a execução completa, todas as tabelas listadas acima estarão disponíveis no PostgreSQL e prontas para conexão no Power BI.

**Atualização Incremental Diária**:
```bash
python API.py
python data_processing_pipeline.py
python incremental_dbt_seed.py
cd logistica_dbt && dbt run && dbt test
```

### 5. Pipeline de Dados Completo

#### Fluxo de Processamento de Dados
```
API (download) → data/raw → Limpeza → data/processed → dbt seed → PostgreSQL → Power BI
```

#### Scripts do Pipeline

| Script | Descrição | Como usar |
|--------|-----------|-----------|
| `API.py` | Download incremental da API + testes de qualidade | `python API.py --count 5` |
| `data_processing_pipeline.py` | Limpeza e padronização dos dados brutos | `python data_processing_pipeline.py` |
| `incremental_dbt_seed.py` | Carga incremental no PostgreSQL via dbt seed | `python incremental_dbt_seed.py` |
| `test_e2e_pipeline.py` | Teste completo do pipeline end-to-end | `python test_e2e_pipeline.py` |
| `preview_models.py` | Visualização dos schemas dos modelos dbt | `python preview_models.py` |
| `install_dbt.py` | Instalação do dbt-core + dbt-postgres | `python install_dbt.py` |
| `export_powerbi_dataset.py` | Exporta dataset Power BI do PostgreSQL para CSV | `python export_powerbi_dataset.py` |
| `docker-compose.powerbi.yml` | Pipeline automatizado via Docker (API → dbt → CSV) | `docker-compose -f docker-compose.powerbi.yml up` |

#### Detalhamento dos Scripts

1. **`API.py`** - Download de dados da API com testes de qualidade integrados
   ```bash
   python API.py --count 5
   ```
   - Baixa dados incrementais da API para `data/raw/` (opções: `--count N`, `--start N`)
   - Gera metadados JSON para cada arquivo baixado
   - Executa testes de qualidade de dados (colunas, schema, contagem de linhas)
   - Gera relatório de conformidade (100% para dados válidos)
   - Suporta detecção automática de sequência incremental

2. **`data_processing_pipeline.py`** - Pipeline de processamento e limpeza
   ```bash
   python data_processing_pipeline.py
   ```
   - Limpa dados brutos: timestamp, weight_kg, estimated_delay_minutes
   - Normaliza textos (delivery_status, vehicle_type)
   - Salva versão processada em `data/processed/`
   - Gera relatórios de limpeza JSON por arquivo

3. **`incremental_dbt_seed.py`** - Carga incremental no PostgreSQL
   ```bash
   python incremental_dbt_seed.py
   ```
   - Copia apenas arquivos novos para `logistica_dbt/seeds/`
   - Renomeia seeds para `shipments_XXXXX.csv`
   - Rastreia estado via `config/seed_state.json`
   - Executa `dbt seed --select` apenas para novos arquivos

4. **`test_e2e_pipeline.py`** - Validação completa do pipeline
   ```bash
   python test_e2e_pipeline.py
   ```
   - Executa todas as etapas do pipeline em sequência
   - Reporta status colorido de cada etapa (PASS/FAIL)
   - Inclui verificação de dependências (Python, dbt)
   - Verifica existência de todas as tabelas no banco de dados
   - Reporta contagem de linhas das tabelas principais

5. **`dbt`** - Transformação e carga
   ```bash
   cd logistica_dbt
   dbt deps --profiles-dir .   # Instalar dependências dbt (dbt_utils)
   dbt seed --profiles-dir .   # Carrega dados processados (shipments_*.csv) para PostgreSQL
   dbt run --profiles-dir .    # Executa staging → dims/fact
   dbt test --profiles-dir .   # Executa testes de qualidade
   ```

#### Setup Inicial (Windows com Docker)
1. **Instalar Docker Desktop** para Windows
2. **Instalar dependências Python** (requer Python 3.8+):
```bash
# Criar ambiente virtual para dbt (recomendado)
python -m venv .venv-dbt
.venv-dbt\Scripts\Activate.ps1  # Windows PowerShell

# Instalar dbt e suas dependências
pip install dbt-core dbt-postgres

# OU execute o script automatizado
python install_dbt.py
```
   - O projeto já inclui `.venv-dbt/` (crie se não existir)
   - O `dbt` precisa estar no PATH ou ativo no venv
3. **Instalar dependências Python**:
```bash
# Instalar dependências do projeto
pip install pandas numpy python-dotenv requests psycopg2-binary
# OU via requirements.txt
pip install -r requirements.txt
```
3. **Configurar ambiente**:
```powershell
# Copiar .env.example para .env e configurar credenciais
Copy-Item .env.example .env

# Editar .env com suas credenciais
notepad .env
```

4. **Iniciar PostgreSQL Docker**:
```powershell
# Método 1: Usar script automatizado
.\docker-commands.ps1

# Método 2: Usar docker-compose
docker-compose up -d
```

#### Operação Diária Completa (Incremental)
```bash
# 1. Baixar novos dados da API (só novos arquivos)
python API.py

# 2. Testes de consistência já integrados no passo 1

# 3. Processar e limpar dados (só novos arquivos)
python data_processing_pipeline.py

# 4. Carregar dados processados para PostgreSQL (incremental)
python incremental_dbt_seed.py

# 5. Executar transformações (se houver novos dados)
cd logistica_dbt
dbt run --profiles-dir .

# 6. Rodar testes de qualidade de dados
dbt test --profiles-dir .
```

#### Pipeline Incremental Automatizado
```bash
# Executar pipeline completo incremental
python incremental_dbt_seed.py
```
- **Carrega apenas arquivos novos** (tracked em `config/seed_state.json`)
- **Evita reprocessamento** de dados já carregados
- **Mantém histórico** de arquivos carregados
- **Renomeia seeds** para `raw_logs_{seq}.csv` automaticamente
- **Executa dbt seed** apenas para seeds novas

### 6. Dataset para Power BI

#### Exportar Dataset Final
```bash
python export_powerbi_dataset.py
```
Gera um CSV denormalizado em `data/powerbi/` com:
- `logistica_me_dataset_*.csv`: fact_shipments + dimensões (routes, vehicles, incidents)
- `risk_route_analysis_*.csv`, `risk_vehicle_analysis_*.csv`, etc.: tabelas de risco

#### Opções de Conexão Power BI
1. **DirectQuery (recomendado)**: Conecte diretamente ao PostgreSQL
2. **CSV Exportado**: Importe o CSV gerado por `export_powerbi_dataset.py`
3. **Docker Automatizado**: `docker-compose -f docker-compose.powerbi.yml up`

### 7. Dashboard no Power BI

Consulte `dashboard/POWERBI_DASHBOARD.md` para:
- KPIs críticos (taxa de atraso, atraso médio, score de risco)
- Layout sugerido (4 páginas: Visão Geral, Risco, Temporal, Forecasting)
- Medidas DAX recomendadas
- Formatação condicional
- Star Schema do modelo

### 8. Previsão de Risco e Análise de Drivers de Atraso

O projeto inclui uma série de modelos analíticos para identificar os principais fatores que contribuem para atrasos nas entregas:

#### Modelos de Análise de Risco

- **`risk_route_analysis`**: Análise de risco por rota (origem-destino)
  - Calcula métricas: taxa de atraso, atraso médio/mediano, desvio padrão
  - Score de risco combinado (0-100) baseado em atraso médio e percentual de atrasos
  - Categorização: HIGH, MEDIUM, LOW
  - Identifica rotas críticas que precisam de atenção

- **`risk_vehicle_analysis`**: Análise de risco por tipo de veículo
  - Avalia desempenho de cada tipo de veículo (caminhão, moto, avião, etc.)
  - Relaciona peso médio das cargas com atrasos
  - Identifica veículos com maior propensão a atrasos

- **`risk_temporal_patterns`**: Análise de padrões temporais
  - Identifica horários do dia, dias da semana e períodos (rush hour) com maiores atrasos
  - Agrupa em buckets: MORNING_RUSH, MIDDAY, AFTERNOON_RUSH, EVENING, NIGHT
  - Determina se fins de semana têm diferentes padrões de atraso

- **`risk_delay_drivers`**: Análise multidimensional de drivers
  - Combina múltiplos fatores (rota x veículo, rota x horário, veículo x horário, peso x atraso)
  - Fornece ranking geral dos fatores que mais contribuem para atrasos
  - Identifica combinações específicas de alto risco

- **`risk_forecast_features`**: Tabela de features para forecasting
  - Dados agregados diariamente por rota-veículo-período
  - Inclui features de lag (dia anterior) e tendência (média móvel 7 dias)
  - Pronta para uso em modelos de previsão ou análise de tendências no Power BI

#### Como Utilizar no Power BI

Conecte-se às tabelas de risco para criar dashboards de monitoramento:

- **Visão Geral de Riscos**: Use `risk_route_analysis` e `risk_vehicle_analysis` para identificar os principais responsáveis por atrasos
- **Análise Temporal**: Use `risk_temporal_patterns` para entender variações horárias e semanais
- **Drivers Detalhados**: Use `risk_delay_drivers` para investigar combinações específicas de fatores
- **Forecasting**: Use `risk_forecast_features` para analisar tendências e construir modelos preditivos

#### Registro de Uso de IA
O arquivo `.claude/memory.md` contém o contexto do projeto para assistentes de IA, incluindo:
- Schema de dados e estrutura do projeto
- Regras de segurança (nunca ler `.env`, usar `.env.example`)
- Configuração do ambiente dbt e fluxo de dados
- Diretrizes de operação para LLMs

#### Conexão Power BI
1. Abrir Power BI Desktop
2. Obter Dados → PostgreSQL
3. Configurar conexão:
   - Servidor: ${POSTGRES_HOST}
   - Banco de dados: ${POSTGRES_DBNAME}
   - Nome de usuário: ${POSTGRES_USERNAME}
   - Senha: ${POSTGRES_PASSWORD}
4. Principais tabelas para dashboard:
    - **Core**: `fact_shipments`, `dim_routes`, `dim_vehicles`, `dim_incidents`
    - **Risk Forecasting**: `risk_route_analysis`, `risk_vehicle_analysis`, `risk_temporal_patterns`, `risk_delay_drivers`, `risk_forecast_features`
    - **Data Quality**: `test_registry` (catálogo de testes)

#### Configuração do Projeto
- `requirements.txt` - Dependências Python (pandas, numpy, python-dotenv, requests, psycopg2-binary)
- `pyproject.toml` - Metadados do projeto e configuração de build (Python >=3.11)
- `install_dbt.py` - Script para instalar dbt-core + dbt-postgres + dbt_utils em `.venv-dbt`
- `preview_models.py` - Visualizar schema de todos os modelos dbt sem conexão ao banco
- `show_all_models.sql` - SQL para visualizar dados de todas as tabelas do modelo
- `EXAMPLE_OUTPUT.md` - Exemplos de saída do pipeline
