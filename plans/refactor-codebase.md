
- change default output dir `/dist` to `.fluttercraft/dist/`
- when run 'gen' cmd, add `.fluttercraft/dist/` to .gitignore
- enhace 'clean' cmd, add `clean -h` to show help
- enhace help for all subcommands, when run `flc <subcommand> -h`, show help for that subcommand
- **CRITICAL**: no longer manage by version, always use latest version.
  - REMOVE ALL plans/v<x.x.x>/*, current just save it as (`{rootDir}/.plans/{short-plan-name}/`)
  - REMOVE ALL test/v<x.x.x>/*. As we have new format "Testing: `/test/plans/{short-plan-name}_test`". For 'test_helper', we just keep useful methods.
  - as we REMOVE ALL test/... -> we follow the /lib/src structure to create test files (eg: `/lib/src/commands/build_command.dart` -> `/test/commands/build_command_test.dart`)