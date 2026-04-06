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
class Entity {
  constructor(name) {
    this.name = name;
  }
}
class SmartRobot extends Entity {
  constructor(name, version) {
    super(name);
    this.version = version;
  }
  identity() {
    return console.log("I am " + this.name + " v" + this.version);
  }
}
function factorial(n) {
  if (n <= 1) {
    return 1;
  } else {
    return n * factorial(n - 1);
  }
}
function test_data() {
  scores = np.array([85, 92, 78, 90, 88]);
  console.log("Ruby NumPy Mean:");
  console.log(scores.mean());
  df = pd.DataFrame([{name: "Alice", math: 95}, {name: "Bob", math: 72}]);
  console.log("Ruby Pandas Description:");
  return console.log(df.describe());
}
function safe_execute(val) {
  try {
    console.log("Ruby checking value: " + val);
    if (val === "crash") {
      throw new Error("Ruby System Failure");
    };
    return console.log("Ruby System OK");
  } catch (e) {
    return console.log("Ruby caught crash! Recovery active.");
  } finally {
    console.log("Ruby cleanup complete.");
  }
}
function stress_test() {
  console.log("--- Starting 10,000 item stress test in Ruby ---");
  data = [];
  i = 0;
  while (i < 10000) {
    score = i * 17 % 100;
    data.push({id: i, score: score});
    i = i + 1;
  };
  df = pd.DataFrame(data);
  console.log("Stats for 10,000 Ruby-generated rows:");
  return console.log(df.describe());
}
console.log("--- [RV] STARTING RUBY MEGA SHOWCASE ---")
robot = new SmartRobot("RubyBot", "3.0")
robot.identity()
console.log("Ruby Factorial(5):")
console.log(factorial(5))
test_data()
console.log("--- Testing Ruby Error Handling ---")
safe_execute("startup")
safe_execute("crash")
stress_test()
console.log("--- [RV] RUBY MEGA SHOWCASE COMPLETE ---")