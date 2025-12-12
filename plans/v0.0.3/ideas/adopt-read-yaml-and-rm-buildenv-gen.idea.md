[Reasoned]

Here’s the **clean, final migration summary plan** for switching your CLI to use **`buildcraft.yaml`** as its only config source.

---

# **Migration Plan: Adopt `buildcraft.yaml` as the Single Config File**

## **1) Standardize the config filename**

* New required config file: **`buildcraft.yaml`**
* Location: **same directory as the CLI executable**
* Older ideas (`.conf`, `.conf.yaml`, `.env`) are discarded.

---

## **2) Replace all config-loading logic**

* Remove any previous parsing code (conf, env, json).
* Implement YAML-only loading:

```dart
final config = loadYaml(File('buildcraft.yaml').readAsStringSync());
```

* Convert YAML structure → internal config model.

---

### 3) Enforce a clear YAML schema

Instead of defining the schema now, instruct the Agent (or the developer phase) to produce a redesigned, improved YAML schema that fits all required build features.

#### **Directive to Agent**
- Analyze all build requirements (targets, flavors, paths, variables, context, overrides).
- Propose a more optimized, future-proof YAML schema.
- Ensure the schema is:
  - simple for users  
  - strict for CLI parsing  
  - predictable (no implicit magic)  
  - compatible with CLI preview output

#### **Result**
- The current example schema is removed.  
- The Agent will create a new schema proposal in a separate design step.


---

## **4) Detach config from logging**

* `buildcraft.yaml` is **read-only**, edited only by the user.
* Build output and history are not written back into YAML.

Logging remains:

```
.buildcraft/build_history.jsonl
.buildcraft/build_latest.log
.buildcraft/logs/<uuid>.log
```

No overlap with config.

---

## **5) Update CLI behavior**

* On startup:

  1. Check `buildcraft.yaml` exists.
  2. Load YAML.
  3. Validate fields.
  4. Merge runtime defaults.

* No fallback filenames, no legacy parsing.

---

## **6) Update documentation**

* All examples/instructions should now tell users:
  **“Edit buildcraft.yaml to configure the build.”**

* Remove any references to `.conf` files.

---

# **Summary**

You migrate the CLI to a single, consistent config system using **`buildcraft.yaml`**. The CLI loads YAML exclusively, strictly validates it, and treats it as the authoritative configuration. Logging is independent and stored under `.buildcraft/`. No backward compatibility is maintained — the previous config formats are removed.

If you want, I can now generate the **final YAML schema** or the **Dart loader implementation**.
