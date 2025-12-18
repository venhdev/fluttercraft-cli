# Test Plan - v0.1.7 Run Alias Enhancements

## Scenarios

### 1. Complex Runtime Parameters
- **Mixed Substitution**: `git commit -m "{1}" --author="{0}"`
- **Quoted Arguments**: `flc run myalias "argument with spaces"`
- **Unused Arguments**: Providing more arguments than placeholders (should be ignored or handled if `{all}` is used).

### 2. Interactive Prompts
- **Missing Named**: Configure `{key}` but runs without `--key`. verify prompt.
- **Missing Positional**: Configure `{0}` but run with empty args. verify prompt or error (current impl prompts).

### 3. Precedence Rules
- **Shell Priority**: Register alias `build` and ensure global `build` command runs instead.
- **Run Priority**: Explicit `flc run build` should run the alias.

### 4. Special Characters
- **Empty Strings**: `""` as argument.
- **Shell Metachars**: `&`, `|` (passed as strings).

## Automated Test Strategy
Create `test/plans/v0_1_7_run_alias_enhancements_test.dart` utilizing `MockConsole` and `MockProcessRunner` to simulate these scenarios without actual shell execution.
