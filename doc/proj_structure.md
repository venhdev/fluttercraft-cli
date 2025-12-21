# Project Structure

## Root Structure

```
fluttercraft/
├── bin/                    # CLI entry points
├── lib/src/                # Main source code
│   ├── commands/           # CLI commands
│   ├── core/               # Business logic & models
│   ├── ui/                 # Interactive shell UI
│   └── utils/              # Helpers & utilities
├── test/                   # Unit tests (mirrors lib/src/)
├── doc/                    # Documentation
├── scripts/                # Build scripts
└── .agent/                 # AI workflow configs
```

---

## Source Code (`lib/src/`)

### Commands (`commands/`)
| File | Description |
|------|-------------|
| `build_command.dart` | Build Flutter app with version management |
| `clean_command.dart` | Clean project and build folder |
| `convert_command.dart` | Convert AAB → universal APK |
| `gen_command.dart` | Generate `fluttercraft.yaml` |
| `run_command.dart` | Execute custom command aliases |

### Core (`core/`)
| File | Description |
|------|-------------|
| `build_config.dart` | YAML config parser & model |
| `build_flags.dart` | Build flag toggles |
| `flavor_config.dart` | Flavor override parser |
| `app_context.dart` | Application state/context |
| `flutter_runner.dart` | Flutter/Shorebird command executor |
| `artifact_mover.dart` | Moves build outputs to dist |
| `apk_converter.dart` | Bundletool AAB→APK conversion |
| `version_manager.dart` | Semantic version bumping |
| `pubspec_parser.dart` | Parse pubspec.yaml |
| `build_record.dart` | Build history JSONL records |
| `command_registry.dart` | Central command registration |
| `config_backup.dart` | Backup & restore user config |

### UI (`ui/`)
| File | Description |
|------|-------------|
| `shell.dart` | Interactive REPL shell |
| `menu.dart` | Menu/prompt utilities |

### Utils (`utils/`)
| File | Description |
|------|-------------|
| `console.dart` | Styled console output |
| `build_logger.dart` | Build logging to file |
| `logger.dart` | General logging |
| `process_runner.dart` | Process execution wrapper |

---

## Tests (`test/`)

```
test/
├── commands/              # Command tests
│   ├── build_command_test.dart
│   ├── clean_command_test.dart
│   ├── convert_command_test.dart
│   ├── gen_command_test.dart
│   ├── run_command_enhanced_test.dart
│   └── run_command_test.dart
├── core/                  # Core module tests
│   ├── app_context_test.dart
│   ├── build_config_test.dart
│   ├── build_flags_test.dart
│   ├── config_backup_test.dart
│   ├── flavor_config_test.dart
│   ├── flutter_runner_test.dart
│   ├── no_review_test.dart
│   └── pubspec_parser_test.dart
├── utils/                 # Utility tests
│   └── console_test.dart
├── fixtures/              # Test YAML configs
├── wrapper_test_mocks.dart # Shared mock classes
└── test_helper.dart       # Shared test utilities
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `fluttercraft.yaml` | Project build configuration |
| `pubspec.yaml` | Dart package manifest |
| `analysis_options.yaml` | Lint rules |
| `.fvmrc` | FVM Flutter version |
| `shorebird.yaml` | Shorebird config |

---

## Build Output

Default output: `.fluttercraft/dist/`

Structure with flavors:
```
.fluttercraft/
└── dist/
    ├── dev/
    ├── staging/
    └── prod/
```
