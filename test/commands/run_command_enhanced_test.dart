import 'package:test/test.dart';
import 'package:fluttercraft/src/core/app_context.dart';
import 'package:fluttercraft/src/commands/run_command.dart';
import '../test_helper.dart';
import '../wrapper_test_mocks.dart';

void main() {
  group('Enhanced RunCommand', () {
    late String tempDir;
    late Future<void> Function() cleanup;
    late MockConsole mockConsole;
    late MockProcessRunner mockRunner;

    setUp(() async {
      (tempDir, cleanup) = TestHelper.createTempDirWithCleanup(
        'run_command_enhanced_test_',
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

    test('shows available aliases when no args provided', () async {
      final context = await createTestContext('''
build:
  app_name: testapp
alias:
  test_alias:
    cmds:
      - echo test
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      final exitCode = await runCmd.execute([]);
      expect(exitCode, 0);
      expect(mockConsole.logs, contains('[INFO] Available aliases:'));
      expect(mockConsole.logs, contains(contains('test_alias')));
    });

    test('replaces named parameters {key}', () async {
      final context = await createTestContext('''
build:
  app_name: testapp
alias:
  git_commit:
    cmds:
      - git commit -m "{message}"
''');
      final runCmd = RunCommand(
        context, 
        console: mockConsole, 
        runner: mockRunner,
      );

      final exitCode = await runCmd.execute(
        ['git_commit', '--message', 'initial commit'],
      );
      
      expect(exitCode, 0);
      expect(mockRunner.executedCommands.length, 1);
      // git is executable, args are [commit, -m, initial commit]
      expect(mockRunner.executedCommands[0], 
        ['git', 'commit', '-m', 'initial commit']);
    });

    test('replaces positional parameters {0}', () async {
       final context = await createTestContext('''
build:
  app_name: testapp
alias:
  echo_val:
    cmds:
      - echo {0}
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      final exitCode = await runCmd.execute(['echo_val', 'hello']);
      
      expect(exitCode, 0);
      expect(mockRunner.executedCommands[0], ['echo', 'hello']);
    });

    test('replaces {all} as named argument', () async {
      final context = await createTestContext('''
build:
  app_name: testapp
alias:
  wrapper:
    cmds:
      - wrapper {all}
''');
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      final exitCode = await runCmd.execute(
        ['wrapper', '--all', 'value'],
      );
      
      expect(exitCode, 0);
      expect(mockRunner.executedCommands[0], 
        ['wrapper', 'value']);
    });

    test('prompts for missing named parameter', () async {
      final context = await createTestContext('''
build:
  app_name: testapp
alias:
  greet:
    cmds:
      - echo {name}
''');
      mockConsole.setPromptResponse('{name}', 'World');
      
      final runCmd = RunCommand(
        context,
        console: mockConsole,
        runner: mockRunner,
      );

      // Missing --name argument
      final exitCode = await runCmd.execute(['greet']);
      
      expect(exitCode, 0);
      expect(mockConsole.logs, contains(contains('[PROMPT] Enter value for {name}')));
      expect(mockRunner.executedCommands[0], ['echo', 'World']);
    });
    
    test('prompts for missing positional parameter {0} via placeholder detection', () async {
       // Note: Currently my impl detects int placeholders but prompts for them if args missing
       final context = await createTestContext('''
build:
  app_name: testapp
alias:
  echo_pos:
    cmds:
      - echo {0}
''');
       mockConsole.setPromptResponse('argument {0}', 'test_value');
       
       final runCmd = RunCommand(
         context,
         console: mockConsole,
         runner: mockRunner,
       );

       final exitCode = await runCmd.execute(['echo_pos']);
       
       expect(exitCode, 0);
       expect(mockConsole.logs, contains(contains('[PROMPT] Enter value for argument {0}')));
       expect(mockRunner.executedCommands[0], ['echo', 'test_value']);
    });
  });
}
