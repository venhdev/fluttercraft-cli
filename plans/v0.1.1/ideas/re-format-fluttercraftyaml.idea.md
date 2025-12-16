# re-format-fluttercraftyaml.idea.md

[Reasoned]

Dưới đây là **docs migration & spec** theo **style brief**, có **giải thích kèm theo từng thay đổi**, dùng **Markdown thuần để copy**.
Schema đã được coi là **LOCKED** theo xác nhận của bạn.

---

# FlutterCraft YAML — Migration & Spec (Brief)

## Scope

* Refactor & optimize FlutterCraft Dart CLI config
* Support build flavors
* No legacy
* No backward compatibility

---

## 1. Design Principles

* **Predictable**: không magic, không implicit
* **Strict**: schema rõ ràng, dễ validate
* **Flavor = override layer**, không phải config độc lập
* **Environment tools global-only**
* **dart_define explicit & controlled**

---

## 2. High-level Structure

```text
build_defaults   → base config (anchor)
build            → runtime selector
flavors          → override by flavor
environments     → global tools (nullable)
paths            → output base
alias            → custom commands
```

---

## 3. Final YAML Schema (Locked)

```yaml
# fluttercraft.yaml

build_defaults: &build_defaults
  app_name: fluttercraft

  name: 0.1.1
  number: 1
  type: aab
  target: lib/main.dart

  # Always applied when should_add_dart_define = true
  global_dart_define:
    APP_NAME: fluttercraft

  # Flavor/build-specific
  dart_define: {}

  flags:
    should_add_dart_define: false
    should_clean: false
    should_build_runner: false

build:
  <<: *build_defaults

  # null | dev | staging | prod
  flavor: null

flavors:
  dev:
    flags:
      should_add_dart_define: true
    dart_define:
      IS_DEV: true
      LOG_LEVEL: debug

  staging:
    name: 0.1.1-rc
    flags:
      should_add_dart_define: true
      should_clean: true
    dart_define:
      IS_STAGING: true

  prod:
    flags:
      should_add_dart_define: true
      should_clean: true
      should_build_runner: true
    dart_define:
      IS_PROD: true

environments:
  fvm:
    enabled: true
    version: 3.35.3

  shorebird:
    enabled: true
    app_id: 12345678-f1f1-f2f2-f3f3-f4f4f4f4f4f4
    artifact: null
    no_confirm: true
  buildtool:
    ...

paths:
  output: dist

alias:
  test:
    cmds:
      - fvm dart test --reporter=json > test/test_output.json
```

---

## 4. Resolve Flow (CLI Behavior)

### 4.1 Build Context Resolution

```text
ctx = build_defaults
ctx = ctx + build

if build.flavor != null:
  if flavors[flavor] not found → HARD ERROR
  ctx = ctx + flavors[flavor]
```

---

### 4.2 dart_define Resolution

```text
if flags.should_add_dart_define == false:
  final_dart_define = {}

else:
  final_dart_define =
    global_dart_define + dart_define
```

Rules:

* Type: `Map<String, primitive>`
* Primitive only: `string | bool | number`
* Reject: object, list, null
* Flavor/build `dart_define` **override key trùng**

---

### 4.3 Environments

* Global only
* Nullable
* Flavor **cannot override**
* `environments.fvm == null` → fallback dùng `flutter` thường

---

### 4.4 Output Folder

```text
if flavor == null → dist/
else              → dist/<flavor>/
```

Derived value — **không cấu hình trong YAML**

---

## 5. Change Log (Old → New)

### 5.1 App name

```yaml
# OLD
app.name

# NEW
build.app_name
```

**Reason**: app identity là 1 phần của build context.

---

### 5.2 Flags rename

| Old               | New                    |
| ----------------- | ---------------------- |
| use_dart_define   | should_add_dart_define |
| need_clean        | should_clean           |
| need_build_runner | should_build_runner    |

**Reason**:

* `should_*` thể hiện intent, không phải imperative action.

---

### 5.3 Dart define

```yaml
dart_define:
  IS_DEV: true
  STORE_TOKEN: "xxx"
```

**Rules**:

* Map only
* Primitive only
* Explicit enable via `should_add_dart_define`

---

### 5.4 global_dart_define (NEW)

```yaml
global_dart_define:
  APP_NAME: fluttercraft
```

**Behavior**:

* Luôn merge vào `dart_define`
* Không bị override bởi flavor trừ khi key trùng

---

### 5.5 Environments grouping

```yaml
environments:
  fvm:
  shorebird:
```

**Rules**:

* Global-only
* Nullable
* Flavor override → reject

---

### 5.6 Removed fields

```text
❌ paths.env
❌ legacy flags
❌ implicit dart_define
❌ backward compatibility
```

**Reason**: giảm ambiguity, giảm special-case trong CLI.

---

## 6. Validation Rules (Must Reject)

* `build.flavor` không tồn tại trong `flavors`
* `dart_define` value không phải primitive
* Flavor có `environments`
* Field legacy còn xuất hiện
* Unknown top-level keys

---

## 7. CLI Responsibilities (Explicit)

* Validate schema
* Resolve & preview build context
* Log:

  * flavor
  * output path
  * final dart_define
* Không auto-fix
* Không silent fallback (trừ fvm)

---

## 8. Status

* ✅ Schema locked
* ✅ Flow confirmed
* ✅ No backward compatibility
* ⏭ Ready for implementation phase

---

Nếu bạn muốn, bước tiếp theo mình có thể:

* viết **formal YAML schema (spec-like)**
* viết **parser pseudo-code**
* hoặc **CLI validation checklist cho dev khác implement**
