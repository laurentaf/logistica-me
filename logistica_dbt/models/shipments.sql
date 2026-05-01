{{ config(materialized='table') }}

{% set relations = adapter.list_relations(database=target.database, schema='raw') %}
{% set seed_names = [] %}
{% for rel in relations %}
  {% if rel.name.startswith('shipments_') %}
    {{ seed_names.append(rel.name) }}
  {% endif %}
{% endfor %}
{% set seed_names = seed_names | sort() %}

SELECT * FROM (
  {% for name in seed_names %}
    SELECT * FROM {{ ref(name) }}
    {% if not loop.last %} UNION ALL {% endif %}
  {% endfor %}
) unified
