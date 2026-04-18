import pandas as pd

df = pd.read_parquet("dataset_b3884914-82a8-45c9-9c56-f37e87f45077.parquet")
print(df.head().to_string())
