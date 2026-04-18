import os
import requests
from dotenv import load_dotenv

load_dotenv()

project_id = "b3884914-82a8-45c9-9c56-f37e87f45077"
token = os.getenv("API_KEY_DATASET")
url = f"https://api.datamission.com.br/projects/{project_id}/dataset?format=parquet"

headers = {"Authorization": f"Bearer {token}"}

response = requests.get(url, headers=headers)
response.raise_for_status()

# Salva o arquivo localmente
with open(f"dataset_{project_id}.parquet", "wb") as file:
    file.write(response.content)

print("Download concluído com sucesso!")