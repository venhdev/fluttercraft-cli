# AGENTS.md

# Dev Flows

## Working Agreements
- Ask for confirmation before adding dependencies.
- Always run `fvm` when .fvmrc exists.

## Working Flows
User can change the mode for better responses (default: `--fast`)

### Ask Mode (`--ask`)
Only answer what the user asks.  
No modifications unless explicitly requested.

### Fast Work Mode (`--fast`)
Execute tasks directly for simple requests.

### Plan Work Mode (--plan`)

1. **Analyze**
   - Analyze the request.
   - Ask if any context is missing.

2. **Create Plan Docs** (`{rootDir}/.plans/{short-plan-name}/`)
   - `implementation_plan.md`: Goals, changes (`[NEW]` / `[MODIFY]`)
     - **NOTE**: Update all user-facing parts (e.g. shell, CLI output).
   - `test_plan.md`: Verification strategy.

3. **Proceed as Planned**
   - Implement following plan phases.
   - Testing: `/test/plans/{short-plan-name}_test` (Do NOT create version subdirectories like `test/v1.0.0`)
   - Verify and fix:
     ```bash
     fvm flutter analyze --no-fatal-infos | Select-String "error|warning"
     ```

4. **Finalize**
   - Docs: Update README, CHANGELOG.
   - Release (optional): Bump version → Commit → Tag → Publish.