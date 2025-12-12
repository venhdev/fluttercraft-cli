# Agent Guidelines

## Version Planning Process

Before implementing any new version, **MUST** create planning documents in `/plans` folder.

### Required Files

For each version `x.x.x`, create:

1. **`v{x.x.x}_implementation_plan.md`**
   - Version goals and requirements
   - Implementation phases
   - Architecture decisions
   - Testing strategy

2. **`v{x.x.x}_task.md`**
   - Task breakdown
   - Dependencies and priorities
   - Status tracking

### Workflow

1. Create both planning documents first
2. Review and refine the plan
3. Implement following the plan
4. Update task status as you progress
5. Update documentation after completion

### Best Practices

- Keep plans detailed but concise
- Use `fvm dart` for all commands
- Follow Dart conventions
- Write tests for new features
- Update docs alongside code

## Using FVM

- **ALWAYS** use `fvm dart` instead of `dart`

### Specification commands:
1. run `fvm dart pub outdated` to use the latest version
2. run `fvm dart pub upgrade --major-versions --tighten` to upgrade to the latest version