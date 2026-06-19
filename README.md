<!--
  Logistica-ME — Logistics cost optimization for MEI/self-employed
  README.md  |  github.com/laurentaf/Logistica-ME
  Brand: Each minute of delay is a lost contract.
  Tone: Practical, business-focused, bilingual.
  Adapted from the LAOS README (20/20) inline-HTML pattern.
-->

<div align="center" style="margin-top:48px;margin-bottom:24px;">

<!-- Emblem: route / delivery truck -->
<svg width="72" height="72" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-bottom:4px;">
  <rect x="4" y="4" width="56" height="56" rx="12" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.3"/>
  <rect x="14" y="22" width="24" height="18" rx="3" stroke="#00b894" stroke-width="2" fill="none"/>
  <rect x="36" y="26" width="14" height="14" rx="2" stroke="#00b894" stroke-width="1.5" fill="none"/>
  <line x1="38" y1="14" x2="38" y2="22" stroke="#00b894" stroke-width="2" stroke-linecap="round"/>
  <line x1="38" y1="14" x2="44" y2="14" stroke="#00b894" stroke-width="2" stroke-linecap="round"/>
  <line x1="44" y1="14" x2="44" y2="18" stroke="#00b894" stroke-width="1.5" stroke-linecap="round"/>
  <circle cx="20" cy="44" r="4" stroke="#00b894" stroke-width="1.5" fill="none"/>
  <circle cx="42" cy="44" r="4" stroke="#00b894" stroke-width="1.5" fill="none"/>
  <path d="M24 44 L38 44" stroke="#00b894" stroke-width="1" opacity="0.4"/>
  <circle cx="14" cy="32" r="2" fill="#00b894" opacity="0.3"/>
  <circle cx="52" cy="33" r="2" fill="#00b894" opacity="0.3"/>
</svg>

<br/>

# Logística-ME

<p style="margin:12px 0;">
  <img src="https://img.shields.io/badge/Python-%E2%89%A53.11-3776AB?style=flat&logo=python&logoColor=fff" alt="Python 3.11+"/>
  &nbsp;
  <img src="https://img.shields.io/badge/Status-STABLE-00b894?style=flat" alt="Status: STABLE"/>
  &nbsp;
  <img src="https://img.shields.io/badge/License-MIT-31c754?style=flat" alt="License: MIT"/>
  &nbsp;
  <img src="https://img.shields.io/badge/Stack-dbt%20|%20PostgreSQL%20|%20Power%20BI-0984e3?style=flat" alt="Stack: dbt | PostgreSQL | Power BI"/>
  &nbsp;
  <a href="https://github.com/laurentaf/laos"><img src="https://img.shields.io/badge/Ecosystem-LAOS-6c5ce7?style=flat" alt="LAOS Ecosystem"/></a>
</p>

<br/>

### Delivery Visibility &bull; Delay Reduction &bull; Risk Analytics

<p style="font-size:0.85em;color:#636e72;">
  EN: Logistics cost optimization &amp; delay reduction for MEI / self-employed carriers.
  <br/>
  PT: Otimização logística e redução de atrasos para MEI / autônomos.
</p>

<hr style="width:48px;margin:24px auto;border:none;border-top:2px solid #00b894;opacity:0.3;"/>

</div>

> **Cada minuto de atraso representa contratos perdidos e multas que corroem o lucro.**  
> Logística-ME transforma dados brutos da API DataMission em inteligência operacional: pipeline Python/dbt → PostgreSQL → Power BI, com modelos preditivos de risco que identificam rotas, veículos e padrões temporais críticos antes que o atraso aconteça.

---

## O que é Logística-ME

Logística-ME é um pipeline completo de inteligência logística para microempreendedores individuais (MEI) e transportadores autônomos. Ele consome dados de remessas da API DataMission, processa via Python + dbt, armazena em PostgreSQL e entrega um dashboard Power BI com KPIs de atraso, análise de risco e previsão.

**Por que existe:** Pequenos transportadores operam com margens apertadas — R$ 106M em receita em risco. Sem visibilidade operacional, cada atraso vira multa. Logística-ME dá ao MEI a mesma inteligência logística que grandes operadores têm.

---

## Arquitetura

```mermaid
flowchart LR
    API[DataMission API] --> RAW[data/raw/]
    RAW --> CLEAN[data/processed/]
    CLEAN --> DBT[dbt Models]
    DBT --> PG[(PostgreSQL)]
    PG --> PBI[Power BI Dashboard]

    subgraph RAW[Bronze — Raw]
        RAW
    end
    subgraph CLEAN[Silver — Cleaned]
        CLEAN
    end
    subgraph DBT[Gold — Modeled]
        DBT
    end
    subgraph PG[Warehouse]
        PG
    end
    subgraph PBI[Visualization]
        PBI
    end
```

<div align="center" style="margin:24px 0;">

<table style="border-collapse:separate;border-spacing:0;min-width:560px;">
  <tr>
    <td colspan="4" align="center" style="padding:0 0 8px 0;">
      <div style="display:inline-block;border:1.5px solid #00b894;border-radius:8px;padding:12px 24px;text-align:center;">
        <div style="font-weight:700;font-size:1em;letter-spacing:0.04em;color:#00b894;">Pipeline Logística-ME</div>
        <div style="font-size:0.8em;opacity:0.5;">Python · dbt · PostgreSQL · Power BI</div>
      </div>
    </td>
  </tr>
  <tr><td colspan="4" align="center" style="padding:0;"><div style="width:1.5px;height:14px;background:#00b894;opacity:0.2;margin:0 auto;"></div></td></tr>
  <tr>
    <td align="center" style="padding:0 6px;width:25%;">
      <div style="border:1px solid #00b894;border-radius:6px;padding:8px 10px;text-align:center;">
        <div style="font-weight:600;font-size:0.8em;letter-spacing:0.02em;">Ingestão</div>
        <div style="font-size:0.65em;opacity:0.5;">API DataMission<br/>→ CSV + metadados</div>
      </div>
    </td>
    <td align="center" style="padding:0 6px;width:25%;">
      <div style="border:1px solid #fdcb6e;border-radius:6px;padding:8px 10px;text-align:center;">
        <div style="font-weight:600;font-size:0.8em;letter-spacing:0.02em;">Transformação</div>
        <div style="font-size:0.65em;opacity:0.5;">Limpeza · dbt staging<br/>→ marts dimensionais</div>
      </div>
    </td>
    <td align="center" style="padding:0 6px;width:25%;">
      <div style="border:1px solid #00b894;border-radius:6px;padding:8px 10px;text-align:center;">
        <div style="font-weight:600;font-size:0.8em;letter-spacing:0.02em;">Análise de Risco</div>
        <div style="font-size:0.65em;opacity:0.5;">Rotas · Veículos · Padrões<br/>Temporais · Drivers</div>
      </div>
    </td>
    <td align="center" style="padding:0 6px;width:25%;">
      <div style="border:1px solid #0984e3;border-radius:6px;padding:8px 10px;text-align:center;">
        <div style="font-weight:600;font-size:0.8em;letter-spacing:0.02em;">Visualização</div>
        <div style="font-size:0.65em;opacity:0.5;">Power BI Dashboard<br/>KPIs + Forecasting</div>
      </div>
    </td>
  </tr>
</table>

</div>

---

## Modelos de Dados

O pipeline gera 4 camadas de tabelas no PostgreSQL:

<table style="width:100%;border-collapse:separate;border-spacing:0;font-size:0.9em;">
  <tr style="border-bottom:1px solid #00b894;opacity:0.4;">
    <th align="left" style="padding:10px 14px;font-weight:600;opacity:0.5;width:20%;">Camada</th>
    <th align="left" style="padding:10px 14px;font-weight:600;opacity:0.5;">Tabelas</th>
    <th align="left" style="padding:10px 14px;font-weight:600;opacity:0.5;width:30%;">Propósito</th>
  </tr>
  <tr>
    <td style="padding:8px 14px;font-weight:500;">Staging</td>
    <td style="padding:8px 14px;opacity:0.7;"><code>stg_shipments</code></td>
    <td style="padding:8px 14px;opacity:0.7;">Limpeza e padronização</td>
  </tr>
  <tr>
    <td style="padding:8px 14px;font-weight:500;">Marts</td>
    <td style="padding:8px 14px;opacity:0.7;"><code>fact_shipments</code>, <code>dim_routes</code>, <code>dim_vehicles</code>, <code>dim_incidents</code></td>
    <td style="padding:8px 14px;opacity:0.7;">Fatos e dimensões para análise</td>
  </tr>
  <tr>
    <td style="padding:8px 14px;font-weight:500;">Risco</td>
    <td style="padding:8px 14px;opacity:0.7;"><code>risk_route_analysis</code>, <code>risk_vehicle_analysis</code>, <code>risk_temporal_patterns</code>, <code>risk_delay_drivers</code>, <code>risk_forecast_features</code></td>
    <td style="padding:8px 14px;opacity:0.7;">Score de risco (0-100) e previsão</td>
  </tr>
  <tr>
    <td style="padding:8px 14px;font-weight:500;">Qualidade</td>
    <td style="padding:8px 14px;opacity:0.7;"><code>test_registry</code></td>
    <td style="padding:8px 14px;opacity:0.7;">Catálogo de testes DQ</td>
  </tr>
</table>

---

## Testes de Qualidade

8 categorias, 8+ testes implementados:

| Categoria | Exemplo |
|-----------|---------|
| Schema Validation | Tipos e formatos |
| Completeness | Nulos / missing |
| Uniqueness | Duplicatas por `shipment_id` |
| Validity | Regras de negócio |
| Accuracy | Faixas de valores (peso, atraso) |
| Consistency | Consistência entre arquivos |
| Timeliness | Timestamps futuros |
| Integrity | Integridade de arquivos |

---

## Quick Start

```bash
# 1. Clonar e configurar
git clone https://github.com/laurentaf/Logistica-ME.git
cd Logistica-ME
cp .env.example .env
# Editar .env com credenciais PostgreSQL

# 2. Iniciar PostgreSQL (Docker)
docker-compose up -d

# 3. Pipeline completo
python API.py
python data_processing_pipeline.py
python incremental_dbt_seed.py
cd logistica_dbt && dbt run && dbt test

# 4. Abrir Power BI — conectar ao PostgreSQL
```

### Requisitos

<table style="font-size:0.85em;border-collapse:separate;border-spacing:0;">
  <tr><td style="padding:6px 12px;font-weight:500;">Python</td><td style="padding:6px 12px;opacity:0.6;">≥ 3.11</td></tr>
  <tr><td style="padding:6px 12px;font-weight:500;">Infraestrutura</td><td style="padding:6px 12px;opacity:0.6;">Docker Desktop (PostgreSQL), dbt-core</td></tr>
  <tr><td style="padding:6px 12px;font-weight:500;">Visualização</td><td style="padding:6px 12px;opacity:0.6;">Power BI Desktop ou Power BI Server</td></tr>
</table>

---

## Exemplo: Pipeline Diário

```bash
# Download incremental + testes de qualidade
python API.py --count 5
# → data/raw/dataset_N.csv + relatório de conformidade

# Limpeza e padronização
python data_processing_pipeline.py
# → data/processed/dataset_N_processed.csv

# Carga incremental no PostgreSQL via dbt seed
python incremental_dbt_seed.py
# → Apenas arquivos novos, tracked em config/seed_state.json

# Transformações dbt
cd logistica_dbt
dbt run --profiles-dir .
dbt test --profiles-dir .
# → Tabelas prontas no PostgreSQL para Power BI
```

<details>
<summary><strong>📊 Dataset Power BI — detalhes</strong></summary>

```bash
# Exportar dataset denormalizado
python export_powerbi_dataset.py
# → data/powerbi/logistica_me_dataset_*.csv
```

**Opções de conexão:**
1. **DirectQuery (recomendado)** — Conecte diretamente ao PostgreSQL
2. **CSV Exportado** — Importe o CSV gerado
3. **Docker Automatizado** — `docker-compose -f docker-compose.powerbi.yml up`

</details>

---

## Contributing

| Escopo | Caminho |
|--------|---------|
| **Bug / melhoria** | Abra uma [issue](https://github.com/laurentaf/Logistica-ME/issues) |
| **Novo modelo de risco** | PR com especificação + testes |
| **Documentação** | PR com descrição — sem gate |

Veja o [modelo de governança LAOS](https://github.com/laurentaf/laos) para detalhes.

---

## License

<div style="margin:16px 0;">

**MIT** — veja [`LICENSE`](https://github.com/laurentaf/Logistica-ME/blob/master/LICENSE) para o texto completo.

Cada minuto de atraso que você evitar é um contrato preservado.

</div>

---

<div align="center" style="margin:36px 0;opacity:0.25;font-size:0.8em;">
<svg width="28" height="28" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-bottom:4px;">
  <rect x="4" y="4" width="56" height="56" rx="12" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.15"/>
  <rect x="16" y="24" width="20" height="16" rx="2" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.5"/>
  <rect x="35" y="28" width="12" height="12" rx="1.5" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.5"/>
  <circle cx="22" cy="44" r="3" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.3"/>
  <circle cx="42" cy="44" r="3" stroke="#00b894" stroke-width="1.5" fill="none" opacity="0.3"/>
</svg>
<br/>
Logística-ME — parte do ecossistema <a href="https://github.com/laurentaf/laos" style="text-decoration:none;">LAOS</a>
</div>