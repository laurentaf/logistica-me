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
```
data/raw/                    # Dados brutos da API
  dataset_*.csv              # Arquivos CSV originais
  
logistica_dbt/              # Projeto dbt
  models/                   # Modelos SQL transformados
  tests/                    # Testes de qualidade de dados
  seeds/                    # Dados semeados
  
reports/                    # Relatórios e resultados
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
POSTGRES_PORT=5432
POSTGRES_DBNAME=logistica_db
```

**Arquivo profiles.yml** (~/.dbt/profiles.yml):
```yaml
logistica_dbt:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost          # Docker PostgreSQL no Windows
      user: ${POSTGRES_USERNAME}
      pass: ${POSTGRES_PASSWORD}
      port: 5432
      dbname: logistica_db
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
- ✅ `valid_ip_address.sql`: Validação de formato IPv4
- ✅ `valid_timestamp_format.sql`: Validação de timestamp ISO 8601
- ✅ `cross_file_duplicate_detection.sql`: Detecção de duplicatas entre arquivos
- ✅ `timestamp_freshness.sql`: Verificação de timestamps futuros
- ✅ `null_rate_analysis.sql`: Análise de taxas de valores nulos por coluna
- ✅ `statistical_outlier_detection.sql`: Detecção de outliers estatísticos
- ✅ `data_freshness_score.sql`: Score de atualidade dos dados
- ✅ `response_time_thresholds.sql`: Verificação de SLAs de tempo de resposta
- ✅ `anomalous_response_times.sql`: Detecção de anomalias estatísticas

### 4. Power BI Integration

**Requisitos**:
- PostgreSQL rodando em Docker no Windows (recomendado)
- Power BI Server requer Windows Server
- Power BI Desktop funciona no Windows 10/11
- Docker Desktop instalado no Windows

**Conexão**:
- Usar conector nativo PostgreSQL do Power BI
- Conectar a `localhost:5432` (PostgreSQL Docker)
- A tabela `test_results` consolida todos os resultados de testes
- Dashboard pode monitorar taxas de sucesso de testes ao longo do tempo

### 5. Pipeline de Dados Completo

#### Fluxo de Processamento de Dados
```
API (download) → data/raw → Limpeza → data/processed → dbt seed → PostgreSQL → Power BI
```

#### Scripts do Pipeline
1. **`API.py`** - Download de dados da API
   ```bash
   python API.py
   ```
   - Baixa dados da API para `data/raw/`
   - Cada execução gera novos arquivos
   - Executa testes básicos de consistência

2. **`API.py`** - Testes de qualidade integrados
   ```bash
   python API.py
   ```
   - Baixa dados da API para `data/raw/`
   - Cada execução gera novos arquivos
   - Executa testes básicos de consistência
   - Valida estrutura de todos os arquivos CSV
   - Verifica conformidade com schema esperado

3. **`data_processing_pipeline.py`** - Pipeline completo
   ```bash
   python data_processing_pipeline.py
   ```
   - Limpa dados brutos (timestamps, IPs, tipos)
   - Salva versão limpa em `data/processed/`
   - Prepara arquivos para `dbt seed`

4. **`dbt`** - Transformação e carga
   ```bash
   cd logistica_dbt
   dbt seed    # Carrega dados processados para PostgreSQL
   dbt run     # Executa modelos transformados
   dbt test    # Executa testes de qualidade
   ```

#### Setup Inicial (Windows com Docker)
1. **Instalar Docker Desktop** para Windows
2. **Configurar ambiente**:
```powershell
# Copiar .env.example para .env e configurar credenciais
Copy-Item .env.example .env

# Editar .env com suas credenciais
notepad .env
```

3. **Iniciar PostgreSQL Docker**:
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

# 7. Gerar relatório consolidado de testes
dbt run --model test_results --profiles-dir .
```

#### Pipeline Incremental Automatizado
```bash
# Executar pipeline completo incremental
python incremental_dbt_seed.py
```
- **Só processa arquivos novos** (tracked em `opencode/seed_state.json`)
- **Evita reprocessamento** de dados já carregados
- **Mantém histórico** de arquivos carregados

#### Registro de Uso de Tokens
**Localização**: `.claude/tokens.md`
```markdown
# Token Usage Log
| Date | Operation | Tokens Used |
|------|-----------|-------------|
| 2026-04-18 | Download dataset_2 + comparison | ~2,500 |
| 2026-04-18 | Delete datasets, API CSV, dbt setup | ~3,200 |
| 2026-04-18 | Create incremental token script | 800 |
```

**OBSERVAÇÃO**: Todo uso de tokens da API deve ser registrado neste arquivo.

#### Conexão Power BI
1. Abrir Power BI Desktop
2. Obter Dados → PostgreSQL
3. Configurar conexão:
   - Servidor: `localhost`
   - Banco de dados: `logistica_db`
   - Nome de usuário: `postgres`
   - Senha: (do arquivo `.env`)
4. Principais tabelas para dashboard:
   - `test_results`: Resultados consolidados de testes
   - `fact_log_events`: Tabela fato principal
   - `dim_endpoints`: Estatísticas por endpoint
   - `dim_time_periods`: Agregações temporais
