# v0.0.2-continuous-shell Manual Testing Guide

This guide covers interactive features that require manual testing.

---

## Prerequisites

```powershell
cd c:\src\self\flutter-dart\cli\mobile-build-cli
```

---

## 1. Shell Start & Basic Commands

### 1.1 Shell Startup
- [x] Run `fvm dart run bin/mobile_build_cli.dart`
- [x] Verify banner displays with version `v0.0.2-continuous-shell`
- [x] Verify `buildcraft>` prompt appears

### 1.2 Help Command
- [ ] Type `help` → verify command list displays
- [ ] Type `?` → verify same output as `help`
- [ ] Verify all commands listed: help, exit, clear, version, demo, context

### 1.3 Version Command
- [ ] Type `version` → verify shows `buildcraft v0.0.2-continuous-shell`

### 1.4 Clear Command
- [ ] Type `clear` → screen should clear
- [ ] Type `cls` → screen should clear (alias)

### 1.5 Exit Command
- [ ] Type `exit` → shell exits with "Goodbye!"
- [ ] Restart, type `quit` → shell exits
- [ ] Restart, type `q` → shell exits

---

## 2. Context Command

### 2.1 View Context
- [ ] Run shell: `fvm dart run bin/mobile_build_cli.dart`
- [ ] Type `context` → displays loaded config
- [ ] Verify shows: App Name, Version, Build Type, Flavor, Output Path
- [ ] Verify shows: Use FVM, Use Shorebird, Project Root, Loaded At
- [ ] Type `ctx` → same as `context` (alias)

---

## 3. Demo Command (Menu Test)

### 3.1 Numeric Menu
- [ ] Run shell
- [ ] Type `demo`
- [ ] Verify menu shows numbered options: `1)`, `2)`, `3)`, `4)`
- [ ] Type a number and press Enter → selection confirmed
- [ ] Press Enter without number → uses default selection

---

## 4. Single-Command Mode

### 4.1 Bypasses Shell
- [ ] Run `fvm dart run bin/mobile_build_cli.dart build --help`
- [ ] Verify shows build command help (NOT shell)
- [ ] Run `fvm dart run bin/mobile_build_cli.dart clean --help`
- [ ] Verify shows clean command help

### 4.2 Version Flag
- [ ] Run `fvm dart run bin/mobile_build_cli.dart --version`
- [ ] Verify shows version and exits (NOT shell)

### 4.3 Help Flag
- [ ] Run `fvm dart run bin/mobile_build_cli.dart --help`
- [ ] Verify shows global help with shell and single-command usage

---

## 5. Error Handling

### 5.1 Unknown Command
- [ ] In shell, type `unknowncommand`
- [ ] Verify warning message: "Unknown command: unknowncommand"
- [ ] Verify hint: 'Type "help" to see available commands.'
- [ ] Shell should NOT exit (continues running)

### 5.2 Empty Input
- [ ] In shell, just press Enter
- [ ] Shell continues with new prompt (no error)

---

## Notes

```
(Record your observations here)
```
