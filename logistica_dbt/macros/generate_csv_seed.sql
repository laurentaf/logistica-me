{% macro generate_csv_seed() %}
  {# 
    Macro to generate dbt seed commands for CSV files.
    Usage: dbt run-operation generate_csv_seed
  #}
  
  {% set csv_files = [] %}
  
  {# Scan for CSV files with project ID pattern #}
  {% set project_id = "b3884914-82a8-45c9-9c56-f37e87f45077" %}
  {% set files_query = "SELECT name FROM stv_tbl_perm WHERE name LIKE 'dataset_" ~ project_id ~ "_%'" %}
  
  {# Create seed commands #}
  {% for i in range(1, 100) %}
    {% set seq_num = "%05d"|format(i) %}
    {% set csv_file = "dataset_" ~ project_id ~ "_" ~ seq_num ~ ".csv" %}
    {% set seed_name = "raw_logs_" ~ seq_num %}
    
    {% set seed_command = "dbt seed --select " ~ seed_name %}
    {% do csv_files.append(seed_command) %}
  {% endfor %}
  
  {# Print commands #}
  {% for command in csv_files %}
    {{ log(command, info=true) }}
  {% endfor %}
  
  {{ return(csv_files) }}
{% endmacro %}