import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:mobile_build_cli/src/commands/build_command.dart';
import 'package:mobile_build_cli/src/commands/clean_command.dart';
import 'package:mobile_build_cli/src/commands/gen_env_command.dart';
import 'package:mobile_build_cli/src/commands/convert_command.dart';

/// Mobile Build CLI
/// 
/// A cross-platform CLI tool for building Flutter apps.
/// Replaces PowerShell build scripts with a single portable executable.
void main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'mycli',
    'Flutter Build CLI - Cross-platform build system\n'
    '\n'
    'Commands:\n'
    '  build     Build Flutter app (APK/AAB/IPA)\n'
    '  clean     Clean project and dist folder\n'
    '  gen-env   Generate .buildenv from project detection\n'
    '  convert   Convert AAB to universal APK',
  )
    ..addCommand(BuildCommand())
    ..addCommand(CleanCommand())
    ..addCommand(GenEnvCommand())
    ..addCommand(ConvertCommand());

  try {
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    print(e);
    exit(64); // EX_USAGE
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
