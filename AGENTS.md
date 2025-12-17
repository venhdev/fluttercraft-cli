# Agent Guidelines

## Core Principles

1. **Always plan before implementing** - See plans/PLAN-GUIDE.md
2. **Test-driven development** - Write tests for new features (see TEST-GUIDE.md)
3. **Documentation is mandatory** - Update docs with every feature change
4. **Zero warnings policy** - Code must pass static analysis before PR/release

---

## Version Planning Process

Before implementing any new version, **MUST** create planning documents.

👉 **See [plans/PLAN-GUIDE.md](plans/PLAN-GUIDE.md) for detailed workflow**

### Quick Checklist
- [ ] Create `v{x.x.x}_implementation_plan.md`
- [ ] Create `v{x.x.x}_task.md`
- [ ] Review plan before coding
- [ ] Write tests + verify
- [ ] Update docs (README, CHANGELOG, changes.md)

---

## Workflow

1. Create planning documents in `/plans/v{x.x.x}/`
2. Review and refine the plan
3. Implement following the plan phases
4. **⚠️ IMPORTANT: Update shell UI when adding/editing features**
   - Update interactive menu options
   - Update command prompts and help text
   - Ensure new features are discoverable in shell mode
5. Write tests for new features (see TEST-GUIDE.md)
6. Update task status as you progress
7. Run static analysis and fix warnings
8. Update documentation after completion:
   - `plans/v{x.x.x}_task.md`
   - `plans/v{x.x.x}_implementation_plan.md`
   - `plans/v{x.x.x}_changes.md`
   - `README.md`
   - `CHANGELOG.md`

---

## Project-Specific Commands

**ALWAYS use `fvm dart` instead of `dart`**

```powershell
# Run tests
fvm dart test --reporter=json > test/test_output.json

# Static analysis
fvm dart analyze 2>&1 | Select-String -Pattern "error|warning" | Select-Object -First 50

# Compile
fvm dart compile exe bin/fluttercraft.dart -o dist/flc.exe
```

---

## Coding Standards

- Use interactive shell for user-friendly UX
- Handle errors gracefully with clear messages
- Log important operations
- Keep config in `fluttercraft.yaml`
- Follow existing patterns in codebase

---

## Testing Requirements

- Unit tests in `test/v{x.x.x}/` for each version
- Manual verification steps in implementation plan
- All tests must pass before release
- See TEST-GUIDE.md for test organization

---

## Documentation Requirements

Update these files when relevant:
- **README.md** - User-facing features and usage
- **CHANGELOG.md** - Version history
- **plans/v{x.x.x}_changes.md** - Version-specific changes
- **Code comments** - Complex logic and design decisions

---

## Release Checklist

1. ✅ All tests pass
2. ✅ Zero analysis warnings
3. ✅ Version bumped (pubspec.yaml, lib/src/version.dart)
4. ✅ CHANGELOG.md updated
5. ✅ README.md reflects new features
6. ✅ Shell UI updated for new features
7. ✅ Committed and tagged

👉 **See PUBLISH_GUIDE.md for release process**