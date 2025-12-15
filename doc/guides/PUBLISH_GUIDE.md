# � Publishing Guide

Guide for publishing FlutterCraft CLI to GitHub and pub.dev.

---

## 🔄 Pre-Release Checklist

- [ ] Version bumped in `pubspec.yaml` and `lib/src/version.dart`
- [ ] `CHANGELOG.md` updated with changes
- [ ] Tests passing: `fvm dart test`
- [ ] No analysis issues: `fvm dart analyze`
- [ ] Git tag created: `git tag v{x.x.x}`

---

## 1️⃣ GitHub Release

### Compile Binaries
```bash
# Windows
.\scripts\compile.ps1

# macOS/Linux (if available)
./scripts/compile.sh
```

**Output:** `bin/fluttercraft-v{x.x.x}-windows-x64.exe`

### Create Tag
```bash
git tag v{x.x.x}
git push origin main --tags
```

### Create Release
1. Go to: https://github.com/venhdev/fluttercraft-cli/releases/new
2. Select tag: `v{x.x.x}`
3. Title: `v{x.x.x} - {Feature Name}`
4. Description: Copy from `CHANGELOG.md` or create release notes
5. **Attach binaries:** Drag and drop compiled `.exe` files
6. Click **"Publish release"**

---

## 2️⃣ pub.dev Release

### Dry Run
```bash
fvm dart pub publish --dry-run
```

### Publish
```bash
fvm dart pub publish
```

**Steps:**
1. Type `y` to confirm
2. Complete OAuth in browser (first time only)
3. Wait for processing (~1-2 minutes)
4. Verify: https://pub.dev/packages/fluttercraft

---

## 3️⃣ Post-Publication

### Test Installation
```bash
dart pub global activate fluttercraft
flc --version
flc --help
```

### Verification
- [ ] GitHub release is live
- [ ] pub.dev package page is live
- [ ] Global activation works
- [ ] Version displays correctly

---

## 📝 Quick Commands

```bash
# Complete workflow
git add .
git commit -m "chore: release v{x.x.x}"
git tag v{x.x.x}
git push origin main --tags
fvm dart pub publish --dry-run
fvm dart pub publish
```

---

## ⚠️ Notes

- **First-time:** Verify email with pub.dev and complete OAuth
- **Version:** Update both `pubspec.yaml` and `lib/src/version.dart`
- **Warnings:** `.ps1` and test file warnings are normal
- **Executables:** Users get both `flc` and `fluttercraft` commands
