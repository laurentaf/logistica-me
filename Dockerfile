FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy project files
COPY . .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install dbt
RUN pip install --no-cache-dir dbt-core dbt-postgres

# Install dbt packages
RUN cd logistica_dbt && dbt deps --profiles-dir .

# Create output directory
RUN mkdir -p data/powerbi config

CMD ["python", "export_powerbi_dataset.py"]
