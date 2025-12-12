# Flutter Build Guide (PowerShell)

Fast, safe & repeatable builds with version bumping, Shorebird support, FVM, flavors and full logging.

## Prerequisites
- PowerShell 7+ (`pwsh`)
- Flutter SDK
- (Optional) FVM – auto-detected if `.fvmrc` exists
- (Optional) Shorebird – auto-detected if `shorebird.yaml` exists

## Folder structure
```
project-root/
├── scripts/
│   ├── gen-buildenv.ps1
│   ├── build.ps1
│   ├── buildenv.base        # defaults (git-tracked)
│   └── .buildenv            # generated + your overrides (git-ignore!)
├── pubspec.yaml
└── ...
```

## First-time setup
```powershell
cd scripts
./gen-buildenv.ps1
```
This reads `pubspec.yaml` (source of truth for name & version), FVM config, Shorebird config and your `buildenv.base`, then creates/updates `.buildenv`.

## Quick edit (optional)
Open `scripts\.buildenv` and adjust anything you need:

```ini
BUILD_TYPE=aab                 # aab | apk | ipa | app (macOS)
OUTPUT_PATH=dist
APPNAME=my_cool_app
FLAVOR=production
USE_SHOREBIRD=true
SHOREBIRD_AUTO_CONFIRM=true
USE_FVM=true
FLUTTER_VERSION=3.35.3
NEED_CLEAN=false
NEED_BUILD_RUNNER=false
```

## Build!

```powershell
cd scripts
./build.ps1          # normal build
./build.ps1 -Clean   # flutter clean first
```

You will be prompted for:
1. Version bump (Major / Minor / Patch / None)
2. Build number handling
3. Final confirmation – shows the exact command that will run

### Smart Shorebird behavior
| BUILD_TYPE | Result                                            |
|------------|---------------------------------------------------|
| `aab`      | Shorebird builds AAB (default)                    |
| `apk`      | Shorebird automatically adds `--artifact apk`    |
| manual     | Set `SHOREBIRD_ARTIFACT=apk` or `aab` in `.buildenv` to override |

## Output
Files are copied to your `OUTPUT_PATH` (default `dist`) with this naming:

```
{APPNAME}_{version}+{buildnumber}.{ext}
Example: my_cool_app_2.1.3+42.aab
```

All logs → `dist/logs/`
- `build-latest.log` (always overwritten)
- `build-2.1.3+42_2025-12-09_15-30-22.log` (archived)

## Common commands
```powershell
# Android AAB (Google Play)
BUILD_TYPE=aab && ./build.ps1

# Android APK (direct install)
BUILD_TYPE=apk && ./build.ps1

# iOS
BUILD_TYPE=ipa && ./build.ps1

# macOS app
BUILD_TYPE=app && ./build.ps1

# Force clean + rebuild everything
./build.ps1 -Clean
```

Enjoy zero-mistake, fully traceable builds!