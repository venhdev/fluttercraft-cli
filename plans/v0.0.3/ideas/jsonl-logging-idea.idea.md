# **Idea Plan Name: BuildRecord JSONL Logging Plan**

### **Goal**

Implement a structured logging system for a Dart CLI that builds apps and records every build attempt using JSONL + plain log files.

---

# **1) BuildRecord model (for JSONL)**

Exact fields (in your order):

1. **id** — UUID generated for each build.
2. **status** — `"success"` or `"failed"`.
3. **cmd** — the final, fully resolved build command used.
4. **duration** — number of seconds the build took.
5. **timestamp** — UTC ISO string.

Record is stored as one JSON object per line.

---

# **2) Log file structure**

```
.buildcraft/
  build_history.jsonl       ← append all build records (JSONL)
  build_latest.log          ← plain text log for the most recent build
  logs/
    <uuid>.log              ← plain text log for each build (one file per run)
```

### Purpose of each:

* **build_history.jsonl**
  Persistent, append-only history of all builds.

* **build_latest.log**
  Overwritten each run; shows most recent output.

* **logs/<uuid>.log**
  Dedicated log file for a single build run.

---

# **3) Build flow**

### **a) Before running a build**

* Generate UUID for this build → `id`.
* Prepare paths:

  * `build_latest.log`
  * `logs/<id>.log`

### **b) During the build**

* Stream output (stdout/stderr) to:

  * `build_latest.log` (overwrite each run)
  * `logs/<id>.log` (per-build file)

### **c) After the build**

* Measure duration.
* Determine status (success/failed).
* Create record map:

  ```dart
  {
    "id": "...",
    "status": "...",
    "cmd": "...",
    "duration": 12.5,
    "timestamp": "2025-01-01T10:00:00Z"
  }
  ```
* Append JSONL line to:
  `.buildcraft/build_history.jsonl`

---

# **4) Reading history**

* Read `.buildcraft/build_history.jsonl` line-by-line.
* `jsonDecode` each line.
* Skip empty/corrupted lines.
* Provide simple access: last build, filter by status, etc.

---

# **Summary**

This updated plan defines a simple and robust logging system:

* **JSONL** → structured build history.
* **build_latest.log** → latest run output.
* **logs/<uuid>.log** → full logs per build.
* No optional log directories or extras.

If you want, I can now generate the **actual Dart code** for the logging system (writer, JSONL appender, log rotator, helpers, etc.).
