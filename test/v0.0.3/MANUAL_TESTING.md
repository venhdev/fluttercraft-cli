# v0.0.3 Manual Testing Guide

This guide covers interactive features for the v0.0.3 release (YAML config + JSONL logging).

---

## Prerequisites

```powershell
cd c:\src\self\flutter-dart\cli\mobile-build-cli
```

---

## 1. Configuration Loading

### 1.1 Missing Config Error
- [x] Run `fvm dart run bin/buildcraft.dart build --no-confirm`
- [x] **Expected**: Error message "buildcraft.yaml not found"
- [x] **Expected**: Hint to create buildcraft.yaml

### 1.2 Config Loading Success
- [x] Copy `buildcraft.yaml.example` to a Flutter project root as `buildcraft.yaml`
- [ ] Edit values as needed
- [ ] Run `fvm dart run bin/buildcraft.dart` (starts shell)
- [ ] Type `context`
- [ ] **Expected**: Shows config values from buildcraft.yaml

---

## 2. Shell Mode

### 2.1 Shell Startup
- [ ] Run `fvm dart run bin/buildcraft.dart`
- [ ] **Expected**: Banner shows `v0.0.3`
- [ ] **Expected**: `buildcraft>` prompt appears

### 2.2 Version Command
- [ ] Type `version`
- [ ] **Expected**: Shows `buildcraft v0.0.3`

### 2.3 Help Command
- [ ] Type `help`
- [ ] **Expected**: Lists commands: build, clean, convert
- [ ] **Expected**: `gen-env` is NOT listed

---

## 3. Build Command

### 3.1 Build with New Config
- [ ] Create `buildcraft.yaml` in a Flutter project:
  ```yaml
  app:
    name: testapp
  build:
    type: apk
    name: 1.0.0
    number: 1
  paths:
    output: dist
  fvm:
    enabled: true
  ```
- [ ] Run: `fvm dart run bin/buildcraft.dart build --no-confirm`
- [ ] **Expected**: Build starts using config values
- [ ] **Expected**: Output shows "App Name: testapp"

### 3.2 Build Type Override
- [ ] Run: `fvm dart run bin/buildcraft.dart build --type aab --no-confirm`
- [ ] **Expected**: Build type shows AAB (overrides config)

---

## 4. JSONL Logging

### 4.1 Log File Creation
After running a build:
- [ ] Check `.buildcraft/` directory exists
- [ ] Check `.buildcraft/build_latest.log` exists
- [ ] Check `.buildcraft/logs/` directory exists
- [ ] Check `.buildcraft/logs/{build-id}.log` exists

### 4.2 JSONL History
- [ ] Open `.buildcraft/build_history.jsonl`
- [ ] **Expected**: Contains one JSON object per line
- [ ] **Expected**: Each line has fields: `id`, `status`, `cmd`, `duration`, `timestamp`

### 4.3 Latest Log Content
- [ ] Open `.buildcraft/build_latest.log`
- [ ] **Expected**: Contains header with Build ID and version
- [ ] **Expected**: Contains timestamped log entries
- [ ] **Expected**: Contains footer with COMPLETED/FAILED status

---

## 5. Clean Command

### 5.1 Clean with Config
- [ ] Run: `fvm dart run bin/buildcraft.dart clean -y`
- [ ] **Expected**: Uses output path from buildcraft.yaml
- [ ] **Expected**: Flutter clean runs if FVM enabled

---

## 6. Gen-Env Removed

### 6.1 Command Not Found
- [ ] Run: `fvm dart run bin/buildcraft.dart gen-env`
- [ ] **Expected**: Shows help (gen-env not recognized as command)

### 6.2 Not in Shell Help
- [ ] Start shell: `fvm dart run bin/buildcraft.dart`
- [ ] Type: `help`
- [ ] **Expected**: `gen-env` is NOT listed

---

## 7. Error Handling

### 7.1 Invalid YAML
- [ ] Create `buildcraft.yaml` with invalid syntax:
  ```yaml
  app:
    name: [invalid
  ```
- [ ] Run: `fvm dart run bin/buildcraft.dart build`
- [ ] **Expected**: YAML parse error message

### 7.2 Empty Config File
- [ ] Create empty `buildcraft.yaml`
- [ ] Run: `fvm dart run bin/buildcraft.dart build`
- [ ] **Expected**: Error about empty/invalid config

---

## 8. Compiled Executable

### 8.1 Compile
- [ ] Run: `fvm dart compile exe bin/buildcraft.dart -o dist/buildcraft-v0.0.3.exe`
- [ ] **Expected**: Compilation succeeds

### 8.2 Version Check
- [ ] Run: `.\dist\buildcraft-v0.0.3.exe --version`
- [ ] **Expected**: Shows `buildcraft v0.0.3`

---

## Notes

```
(Record your observations here)
```

---

## Test Results Summary

| Test Area | Status | Notes |
|-----------|--------|-------|
| Config Loading | ⬜ | |
| Shell Mode | ⬜ | |
| Build Command | ⬜ | |
| JSONL Logging | ⬜ | |
| Clean Command | ⬜ | |
| Gen-Env Removed | ⬜ | |
| Error Handling | ⬜ | |
| Compiled Exe | ⬜ | |
