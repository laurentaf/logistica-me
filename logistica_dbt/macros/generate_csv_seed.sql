{% macro generate_csv_seed() %}
  {#
  Macro to list all shipment seed commands.
  Usage: dbt run-operation generate_csv_seed
  #}

  {% set shipment_seeds = [] %}
  {% for node in graph["nodes"].values() %}
    {% if node.resource_type == "seed" and node.name.startswith("shipments_") %}
      {% do shipment_seeds.append(node.name) %}
    {% endif %}
  {% endfor %}

  {% for seed_name in shipment_seeds %}
    {{ log("dbt seed --select " ~ seed_name, info=true) }}
  {% endfor %}

  {{ return(shipment_seeds) }}
{% endmacro %}
