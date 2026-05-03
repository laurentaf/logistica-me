{% test positive_value(model, column_name) %}
-- Test that a column value is strictly positive (> 0)
SELECT *
FROM {{ model }}
WHERE {{ column_name }} <= 0
{% endtest %}