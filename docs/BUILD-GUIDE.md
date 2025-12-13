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
fvm dart compile exe bin/buildcraft.dart -o bin/buildcraft.exe
```

## Output Structure

After building, you'll have:
```
bin/
└── buildcraft.exe              # Latest version (no version suffix)
```

The executable is always built to `bin/buildcraft.exe` and represents the latest version.


