# Agent Guidelines

## Version Planning Process

Before implementing any new version, **MUST** create planning documents in `/plans` folder.

### Required Files

For each version `x.x.x`, create:

1. **`/plans/v{x.x.x}_implementation_plan.md`**
   - Version goals and requirements
   - Implementation phases
   - Architecture decisions
   - Testing strategy

2. **`/plans/v{x.x.x}_task.md`**
   - Task breakdown
   - Dependencies and priorities
   - Status tracking

### Workflow

1. Create both planning documents first
2. Review and refine the plan
3. Implement following the plan, write tests for new features
4. Update task status as you progress
5. Update documentation after completion

## Notice

- **ALWAYS** use `fvm dart` instead of `dart`
- Run test with `--reporter=json > test/test_output.json`