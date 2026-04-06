// RV Standard Library - High-End Frameworks (Optimized Phase)
const RV = {
  NumPyArray: class {
    constructor(data) {
      this.data = Array.isArray(data) ? data : [data];
      this.length = this.data.length;
      this._sum = null;
    }

    sum() {
      if (this._sum !== null) return this._sum;
      let s = 0;
      for (let i = 0; i < this.length; i++) s += this.data[i];
      this._sum = s;
      return s;
    }

    mean() {
      return this.length === 0 ? 0 : this.sum() / this.length;
    }

    min() {
      let m = Infinity;
      for (let i = 0; i < this.length; i++) if (this.data[i] < m) m = this.data[i];
      return m;
    }

    max() {
      let m = -Infinity;
      for (let i = 0; i < this.length; i++) if (this.data[i] > m) m = this.data[i];
      return m;
    }

    toString() {
      return `array([${this.data.length > 10 ? this.data.slice(0, 5).join(', ') + ' ...' : this.data.join(', ')}])`;
    }
  },

  DataFrame: class {
    constructor(data) {
      this.data = data || [];
      this.columns = this.data.length > 0 ? Object.keys(this.data[0]) : [];
    }

    head(n = 5) {
      return this.data.slice(0, n);
    }

    // ONE-PASS Statistics O(N)
    describe() {
      if (this.data.length === 0) return {};
      const stats = {};
      this.columns.forEach(col => {
        stats[col] = { count: 0, sum: 0, min: Infinity, max: -Infinity };
      });

      for (let i = 0; i < this.data.length; i++) {
        const row = this.data[i];
        for (let j = 0; j < this.columns.length; j++) {
          const col = this.columns[j];
          const val = row[col];
          if (typeof val === 'number') {
            const s = stats[col];
            s.count++;
            s.sum += val;
            if (val < s.min) s.min = val;
            if (val > s.max) s.max = val;
          }
        }
      }

      // Finalize means
      this.columns.forEach(col => {
        const s = stats[col];
        if (s.count > 0) {
          s.mean = s.sum / s.count;
          delete s.sum;
        } else {
          delete stats[col];
        }
      });

      return stats;
    }

    toString() {
      return `DataFrame(${this.data.length} rows x ${this.columns.length} columns)`;
    }
  }
};

RV.numpy = {
  array: (data) => new RV.NumPyArray(data)
};

RV.pandas = {
  DataFrame: (data) => new RV.DataFrame(data)
};

const np = RV.numpy;
const pd = RV.pandas;
console.log("--- [RV] DATA SCIENCE MODE STARTING ---")
scores = np.array([85, 92, 78, 90, 88])
console.log("Original Scores Array:")
console.log(scores)
avg_score = scores.mean()
console.log("Average Score (NumPy .mean()):")
console.log(avg_score)
total_score = scores.sum()
console.log("Total Sum (NumPy .sum()):")
console.log(total_score)
data = [{"name": "Alice", math: 95, science: 88}, {"name": "Bob", math: 72, science: 92}, {"name": "Charlie", math: 88, science: 85}, {"name": "Diana", math: 94, science: 90}]
df = pd.DataFrame(data)
console.log("\nDataFrame Summary (Pandas .describe()):")
console.log(df.describe())
console.log("\nFirst 2 rows (Pandas .head(2)):")
console.log(df.head(2))
console.log("\n--- [RV] DATA SCIENCE MODE COMPLETE ---")