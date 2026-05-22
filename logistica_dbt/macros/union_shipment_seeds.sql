{% macro union_shipment_seeds() %}

  {% set shipment_seeds = [] %}
  {% for node in graph["nodes"].values() %}
    {% if node.resource_type == "seed" and node.name.startswith("shipments_") %}
      {% do shipment_seeds.append(node.name) %}
    {% endif %}
  {% endfor %}

  {% if not shipment_seeds %}
    {{ log("Warning: No shipment seeds found in seeds/. Returning empty schema placeholder.", info=true) }}
    SELECT
      CAST(NULL AS VARCHAR) AS shipment_id,
      CAST(NULL AS TIMESTAMP) AS timestamp,
      CAST(NULL AS VARCHAR) AS origin,
      CAST(NULL AS VARCHAR) AS destination,
      CAST(NULL AS NUMERIC) AS weight_kg,
      CAST(NULL AS VARCHAR) AS delivery_status,
      CAST(NULL AS VARCHAR) AS vehicle_type,
      CAST(NULL AS INTEGER) AS estimated_delay_minutes
    WHERE FALSE
  {% else %}
    {% for seed_name in shipment_seeds %}
      SELECT
        shipment_id,
        timestamp,
        origin,
        destination,
        weight_kg,
        delivery_status,
        vehicle_type,
        estimated_delay_minutes
      FROM {{ ref(seed_name) }}
      {% if not loop.last %} UNION ALL {% endif %}
    {% endfor %}
  {% endif %}
{% endmacro %}
