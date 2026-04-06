# RV Performance & Complexity Benchmark (10,000+ Items)
import numpy as np
import pandas as pd

print("--- [RV] BENCHMARK STARTING (10,000 Items) ---")

# 1. Stress-testing Data Generation
# We'll use a loop to create 10,000 data points
data = []
for i in range(10000):
    # Using a simple deterministic "random" for scores
    score = (i * 7) % 100
    data.append({"id": i, "score": score})

# 2. Stress-testing Pandas .describe() (O(N) Optimization)
df = pd.DataFrame(data)
print("Calculating stats for 10,000 rows...")
# Date.now() is a JS global, so we can call it if the generator allows it, 
# but let's just run the code and see it complete instantly.

stats = df.describe()
print("Stats for 'score' column:")
print(stats["score"])

# 3. Stress-testing NumPy .mean() (Efficient loop check)
raw_scores = []
for i in range(10000):
    raw_scores.append((i * 13) % 100)

scores_np = np.array(raw_scores)
print("\nNumPy Mean for 10,000 items:")
print(scores_np.mean())

print("\n--- [RV] BENCHMARK COMPLETE ---")
