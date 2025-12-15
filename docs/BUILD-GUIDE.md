# Build Guide

## Requirements
- Dart SDK installed
- `fvm` (optional, recommended)

## Using Build Scripts (Recommended)

The build scripts create a single executable in the `/bin` directory:

**Windows (PowerShell)**:
```powershell
.\scripts\compile.ps1
```

**Unix/Mac**:
```bash
./scripts/compile.sh
```

## Manual Build (Advanced)

If you want to build manually without the scripts:

```powershell
# Build executable
fvm dart compile exe bin/fluttercraft.dart -o bin/fluttercraft.exe
```

## Output Structure

After building, you'll have:
```
bin/
└── fluttercraft.exe              # Latest version
```

The executable is always built to `bin/fluttercraft.exe` and displays as "fluttercraft" when running.




