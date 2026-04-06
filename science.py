# RV Compiler: High-End Data Science Showcase (science.py)
import numpy as np
import pandas as pd

print("--- [RV] DATA SCIENCE MODE STARTING ---")

# 1. NumPy Operations (Vectorized Math)
# Support for np.array and .mean() / .sum()
scores = np.array([85, 92, 78, 90, 88])
print("Original Scores Array:")
print(scores)

avg_score = scores.mean()
print("Average Score (NumPy .mean()):")
print(avg_score)

total_score = scores.sum()
print("Total Sum (NumPy .sum()):")
print(total_score)

# 2. Pandas Operations (Tabular Data)
# Support for pd.DataFrame and .describe() / .head()
data = [
    {"name": "Alice", "math": 95, "science": 88},
    {"name": "Bob", "math": 72, "science": 92},
    {"name": "Charlie", "math": 88, "science": 85},
    {"name": "Diana", "math": 94, "science": 90}
]

df = pd.DataFrame(data)
print("\nDataFrame Summary (Pandas .describe()):")
print(df.describe())

print("\nFirst 2 rows (Pandas .head(2)):")
print(df.head(2))

print("\n--- [RV] DATA SCIENCE MODE COMPLETE ---")
