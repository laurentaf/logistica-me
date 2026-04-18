import os
import requests
from dotenv import load_dotenv

load_dotenv()

project_id = "b3884914-82a8-45c9-9c56-f37e87f45077"
token = os.getenv("API_KEY_DATASET")
url = f"https://api.datamission.com.br/projects/{project_id}/dataset?format=csv"

headers = {"Authorization": f"Bearer {token}"}

# Run 5 times incrementally
for i in range(1, 6):
    response = requests.get(url, headers=headers)
    response.raise_for_status()

    filename = f"dataset_{project_id}_{i}.csv"
    with open(filename, "wb") as file:
        file.write(response.content)

    print(f"Download {i}/5 concluído: {filename}")

print("Todos os downloads concluídos com sucesso!")
