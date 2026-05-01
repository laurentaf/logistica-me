# Instalação do dbt para o Projeto Logística-ME

## Contexto

O projeto requer **dbt (data build tool)** para executar as transformações SQL e testes de qualidade. O ambiente virtual `.venv-dbt` já existe no projeto, mas o dbt ainda não foi instalado.

## Verificação

Para verificar se o dbt está instalado:

```bash
# Ative o ambiente virtual (Windows PowerShell)
.venv-dbt\Scripts\Activate.ps1

# Ou no Linux/Mac
source .venv-dbt/bin/activate

# Verifique instalação
dbt --version
```

Se retornar erro "command not found", o dbt não está instalado.

## Instalação

### 1. Requisitos do Sistema

- Python 3.8+ (já existe no projeto)
- PostgreSQL client libraries (para o adaptador postgres)
- No Windows: Poderá ser necessário instalar [PostgreSQL ODBC drivers](https://www.postgresql.org/ftp/odbc/versions/msi/) se houver problemas com `psycopg2`

### 2. Instalar dbt via pip

```bash
# Ative o ambiente virtual primeiro
.venv-dbt\Scripts\Activate.ps1   # Windows PowerShell
# OU
source .venv-dbt/bin/activate    # Linux/Mac

# Instale dbt-core e dbt-postgres (adaptador PostgreSQL)
pip install dbt-core dbt-postgres

# Versão exata testada (recomendada)
pip install dbt-core==1.8.0 dbt-postgres==1.8.0
```

### 3. Verificar instalação

```bash
dbt --version
# Deve mostrar: dbt-core: 1.8.0, dbt-postgres: 1.8.0
```

### 4. Testar conexão com PostgreSQL

```bash
cd logistica_dbt
dbt debug --profiles-dir .
```

Deve mostrar `All checks passed!` se a conexão estiver OK.

---

## dbt Packages

O projeto usa `dbt_utils` (pacote da comunidade). Instale também:

```bash
cd logistica_dbt
dbt deps
```

Isso instalará o pacote definido em `packages.yml`:
```yaml
packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.0
```

---

## Estrutura do Ambiente Virtual

```
.venv-dbt/
├── Scripts/           # Windows: executáveis (dbt, python, pip)
├── bin/               # Linux/Mac: executáveis
├── Lib/               # Bibliotecas Python instaladas
└── pyvenv.cfg         # Configuração do venv
```

O dbt será instalado em:
- `Scripts/dbt.exe` (Windows)
- `bin/dbt` (Linux/Mac)

---

## Problemas Comuns

| Problema | Solução |
|----------|---------|
| `dbt: command not found` | Ative o ambiente virtual primeiro (`.venv-dbt\Scripts\Activate.ps1`) |
| `psycopg2` compilation error | Instale PostgreSQL ODBC drivers ou use `pip install psycopg2-binary` |
| `dbt deps` fails | Verifique conexão com internet e se o `packages.yml` está válido |
| `dbt debug` fails | Verifique `profiles.yml` (~/.dbt/profiles.yml ou `logistica_dbt/profiles.yml`) |

---

## Uso no Projeto

Após instalação completa:

```bash
# 1. Baixar dados da API
python API.py --count 1

# 2. Processar dados
python data_processing_pipeline.py

# 3. Carregar no PostgreSQL (incremental)
python incremental_dbt_seed.py

# 4. Executar modelos dbt
cd logistica_dbt
dbt run --profiles-dir .

# 5. Executar testes
dbt test --profiles-dir .

# 6. Ver tabelas geradas no PostgreSQL
psql -U postgres -d logistica_db -c "\dt"
```

---

## Remover e Reinstalar (se necessário)

```bash
# Desative o venv se estiver ativo
deactivate

# Remova o diretório .venv-dbt
rm -rf .venv-dbt  # Linux/Mac
# ou rmdir /s .venv-dbt no Windows

# Recrie o venv
python3 -m venv .venv-dbt

# Ative e instale dbt
.venv-dbt\Scripts\Activate.ps1  # Windows
pip install dbt-core dbt-postgres
cd logistica_dbt && dbt deps
```

---

## Notas

- O arquivo `profiles.yml` deve estar em `~/.dbt/profiles.yml` ou em `logistica_dbt/`
- O projeto está configurado para usar o schema `public` por padrão
- Consulte `README.md` para instruções completas do pipeline
