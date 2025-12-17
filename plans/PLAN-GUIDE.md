# Version Planning Guide

## Required Files for `v{x.x.x}`

### 1. `v{x.x.x}_implementation_plan.md`
- Version goals and requirements
- Implementation phases with `[NEW]`, `[MODIFY]`, `[DELETE]` tags
- Architecture decisions
- Testing strategy (see TEST-GUIDE.md)
- Manual verification steps
- Breaking changes (if any)

### 2. `v{x.x.x}_task.md`
- Task breakdown with checkboxes
- Dependencies and priorities
- Status tracking (❌ TODO, 🔄 IN PROGRESS, ✅ DONE)

### 3. `v{x.x.x}_changes.md` (after completion)
- User-facing changes
- Technical changes
- Bug fixes

---

## Workflow

1. **Plan**: Create both `.md` files, review and refine
2. **Implement**: Follow phases, write tests
3. **⚠️ Update shell UI** when adding/editing features
4. **Test**: Run tests + static analysis
5. **Document**: Update README, CHANGELOG, version numbers
6. **Release**: Commit, tag, publish (see PUBLISH_GUIDE.md)

---

## Example Implementation Plan Structure

```markdown
# v{x.x.x} Implementation Plan

Brief description

## Phase 1 — Feature Name

### [NEW] [file.dart](path)
Description + code

### [MODIFY] [existing.dart](path)
What to change

## Verification Plan
- Automated tests
- Manual steps

## Breaking Changes
List if any
```

---

## Commands Reference

```powershell
# Test
fvm dart test --reporter=json > test/test_output.json

# Analyze
fvm dart analyze 2>&1 | Select-String -Pattern "error|warning" | Select-Object -First 50
```

---

## Version Numbering

- **MAJOR** (x.0.0): Breaking changes
- **MINOR** (0.x.0): New features (backward compatible)
- **PATCH** (0.0.x): Bug fixes

---

**IMPORTANT**: Always update shell UI when features affect user interaction!
