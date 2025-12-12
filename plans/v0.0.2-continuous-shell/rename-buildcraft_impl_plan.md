# Rename CLI: mycli → buildcraft

## Goal
Rename all references from `mycli` to `buildcraft`.
Compiled executable naming: `buildcraft.v<x.x.x>.exe`

---

## Files to Modify

### 1. Source Code

#### `lib/src/ui/shell.dart`
- [ ] Prompt: `mycli>` → `buildcraft>`
- [ ] Banner: `MYCLI - Mobile Build CLI` → `BUILDCRAFT`
- [ ] Version: `mycli v0.0.2` → `buildcraft v0.0.2`
- [ ] Help messages referencing mycli

#### `bin/mobile_build_cli.dart`
- [ ] Version output: `mycli v0.0.2` → `buildcraft v0.0.2`
- [ ] Help text references

### 2. Compile Scripts

#### `scripts/compile.ps1`
- [ ] `$exeName = "mycli"` → `$exeName = "buildcraft"`
- [ ] Add version suffix: `buildcraft.v<version>.exe`

#### `scripts/compile.sh`
- [ ] `EXE_NAME="mycli"` → `EXE_NAME="buildcraft"`
- [ ] Add version suffix: `buildcraft.v<version>`

### 3. Documentation

#### `README.md`
- [ ] All `mycli` command examples → `buildcraft`
- [ ] `mycli.exe` → `buildcraft.exe`

### 4. Test Files

#### `test/v0.0.2/MANUAL_TESTING.md`
- [ ] All `mycli` prompts and examples → `buildcraft`

### 5. Plan Files (Optional - for consistency)

- [ ] `v0.0.2-continuous-shell_implementation_plan.md`
- [ ] `v0.0.2-continuous-shell_task.md`

---

## Compile Output Naming

**Pattern:** `buildcraft.v{version}.{ext}`

Examples:
- `buildcraft.v0.0.2.exe` (Windows)
- `buildcraft.v0.0.2` (Linux/macOS)

---

## Execution Order

1. Update `shell.dart` (prompt, banner, version)
2. Update `bin/mobile_build_cli.dart` (version output)
3. Update compile scripts with version suffix
4. Update README.md
5. Update test files
6. Run analysis and tests
7. (Optional) Update plan files

---

## Verification

- [ ] `fvm dart analyze` passes
- [ ] `fvm dart test` passes
- [ ] Shell shows `buildcraft>` prompt
- [ ] `buildcraft --version` shows correct name
- [ ] Compile produces `buildcraft.v0.0.2.exe`
