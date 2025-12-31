import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import '../test_helper.dart';
import '../wrapper_test_mocks.dart';

void main() {
  group('v0.1.7 Alias Enhancements', () {
    late String tempDir;
    late Future<void> Function() cleanup;
    late MockConsole mockConsole;
    late MockProcessRunner mockRunner;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'v0_1_7_alias_test_',
      );
      mockConsole = MockConsole();
      mockRunner = MockProcessRunner();
    });

    tearDown(() async {
      await cleanup();
    });

    Future<AppContext> createTestContext(String yamlContent) async {
      await TestHelper.writeFile(tempDir, 'fluttercraft.yaml', yamlContent);
      return await AppContext.load(projectRoot: tempDir);
    }

    test('Scenario 1: Mixed Substitution (Positional & Named)', () async {
      final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    commit_author:
      cmds:
        - git commit -m "{1}" --author="{0}"
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // flc run commit_author "Author Name" "Commit Message"
      // {0} -> "Author Name"
      // {1} -> "Commit Message"
      await runCmd.execute(['commit_author', 'Author Name', 'Commit Message']);
      
      expect(mockRunner.executedCommands.length, 1);
      final args = mockRunner.executedCommands[0];
      // Expected: git commit -m "Commit Message" --author="Author Name"
      // Note: _parseCommand splits by space but respects quotes.
      // The replacement happens on the STRING command first.
      // processed = 'git commit -m "Commit Message" --author="Author Name"'
      // Then _parseCommand parses it.
      
      expect(args, contains('git'));
      expect(args, contains('commit'));
      expect(args, contains('-m'));
      expect(args, contains('Commit Message')); // Check value inside quotes
      expect(args, contains('--author=Author Name')); 
    });

    test('Scenario 1b: Mixed Substitution (Named Key & Positional)', () async {
      final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    mixed:
      cmds:
        - echo {msg} {0}
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // flc run mixed --msg "Hello" "World"
      await runCmd.execute(['mixed', '--msg', 'Hello', 'World']);
      
      expect(mockRunner.executedCommands[0], ['echo', 'Hello', 'World']);
    });

    test('Scenario 1c: Quoted Arguments Preservation', () async {
       final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    print_arg:
      cmds:
        - echo {0}
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // flc run print_arg "hello world"
      // The argument passed to runCmd is ["print_arg", "hello world"] (shell stripped quotes)
      // Substituter replaces {0} with "hello world".
      // cmd becomes: echo hello world
      // WAIT. If we just string replace, we lose quotes if the original cmd didn't have them around {0}.
      // User config: echo {0} -> echo hello world -> [echo, hello, world]
      // This might be unintended if they wanted one arg.
      // User config SHOULD be: echo "{0}" if they want to safe-guard.
      // Let's test that behavior.
      
      await runCmd.execute(['print_arg', 'hello world']);
      
      // Since config is `echo {0}`, and replacement is text-based:
      // "echo hello world" -> [echo, hello, world]
      expect(mockRunner.executedCommands[0], ['echo', 'hello', 'world']);
    });

    test('Scenario 1d: Quoted Placeholder in Config', () async {
       final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    safe_print:
      cmds:
        - echo "{0}"
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // flc run safe_print "hello world"
      await runCmd.execute(['safe_print', 'hello world']);
      
      // Config: echo "{0}"
      // Replace: echo "hello world"
      // Parse: [echo, hello world]
      expect(mockRunner.executedCommands[0], ['echo', 'hello world']);
    });

    test('Scenario 2: Interactive Prompt for Missing Named', () async {
      final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    deploy:
      cmds:
        - deploy --env "{env}"
''');
      mockConsole.setPromptResponse('{env}', 'prod');
      
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // Missing --env
      await runCmd.execute(['deploy']);

      expect(mockConsole.logs, contains('[PROMPT] Enter value for {env}'));
      expect(mockRunner.executedCommands[0], ['deploy', '--env', 'prod']);
    });

    test('Scenario 2b: Interactive Prompt for Missing Positional {0}', () async {
      final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    echo_pos:
      cmds:
        - echo {0}
''');
       mockConsole.setPromptResponse('argument {0}', 'manual_value');
       
       final runCmd = RunCommand(
         context,
         console: mockConsole,
         runner: mockRunner,
       );

       await runCmd.execute(['echo_pos']);
       
       expect(mockConsole.logs, contains(contains('[PROMPT] Enter value for argument {0}')));
       expect(mockRunner.executedCommands[0], ['echo', 'manual_value']);
    });

    test('Scenario 4: Special Characters (Empty String)', () async {
        final context = await createTestContext('''
fluttercraft:
  build:
    app_name: testapp
  alias:
    check_empty:
      cmds:
        - process "{0}"
''');
       final runCmd = RunCommand(
         context,
         console: mockConsole,
         runner: mockRunner,
       );

       // flc run check_empty ""
       await runCmd.execute(['check_empty', '']);
       
       // Config: process "{0}"
       // Replace: process ""
       // Parse: [process, ] (empty string arg)
       expect(mockRunner.executedCommands[0], ['process', '']);
    });
  });
}
