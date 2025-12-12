import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/build_env.dart';
import '../core/pubspec_parser.dart';
import '../utils/console.dart';

/// GenEnv command - generates .buildenv from project detection
class GenEnvCommand extends Command<int> {
  @override
  final String name = 'gen-env';

  @override
  final String description = 'Generate .buildenv from project detection';

  GenEnvCommand() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing .buildenv',
        defaultsTo: false,
      );
  }

  @override
  Future<int> run() async {
    final console = Console();
    final projectRoot = Directory.current.path;

    console.header('BUILDENV GENERATOR');

    final buildEnv = BuildEnv(projectRoot: projectRoot);
    final pubspecParser = PubspecParser(projectRoot: projectRoot);

    // Check if .buildenv already exists
    if (await buildEnv.exists() && argResults?['force'] != true) {
      console.warning('.buildenv already exists.');
      if (!console.confirm('Overwrite?', defaultValue: false)) {
        console.info('Cancelled. Use --force to overwrite.');
        return 0;
      }
    }

    console.section('Detecting Project Configuration');

    // Load defaults from buildenv.base
    if (await buildEnv.baseExists()) {
      console.info('Found buildenv.base → loading defaults');
    }
    await buildEnv.load();

    // Detect from pubspec.yaml
    final pubspec = await pubspecParser.parse();
    if (pubspec != null) {
      console.success('Detected pubspec.yaml');
      console.keyValue('App Name', pubspec.name);
      console.keyValue('Version', pubspec.fullVersion);
      
      buildEnv.appName = pubspec.name;
      buildEnv.buildName = pubspec.buildName;
      buildEnv.buildNumber = pubspec.buildNumber;
    } else {
      console.warning('pubspec.yaml not found or invalid');
    }

    // Detect FVM
    final fvmrcPath = p.join(projectRoot, '.fvmrc');
    if (await File(fvmrcPath).exists()) {
      console.success('Detected .fvmrc → enabling FVM');
      buildEnv.useFvm = true;
      
      // Try to extract Flutter version
      try {
        final fvmContent = await File(fvmrcPath).readAsString();
        final versionMatch = RegExp(r'"flutter"\s*:\s*"([^"]+)"').firstMatch(fvmContent);
        if (versionMatch != null) {
          buildEnv.flutterVersion = versionMatch.group(1)!;
          console.keyValue('Flutter Version', buildEnv.flutterVersion);
        }
      } catch (_) {}
    }

    // Detect Shorebird
    final shorebirdPath = p.join(projectRoot, 'shorebird.yaml');
    if (await File(shorebirdPath).exists()) {
      console.success('Detected shorebird.yaml → enabling Shorebird');
      buildEnv.useShorebird = true;
    }

    // Detect main entry point
    final mainDart = p.join(projectRoot, 'lib', 'main.dart');
    if (!await File(mainDart).exists()) {
      // Search for main.dart
      final libDir = Directory(p.join(projectRoot, 'lib'));
      if (await libDir.exists()) {
        await for (final entity in libDir.list(recursive: true)) {
          if (entity is File && p.basename(entity.path) == 'main.dart') {
            final relativePath = p.relative(entity.path, from: projectRoot)
                .replaceAll(r'\', '/');
            buildEnv.set('TARGET_DART', relativePath);
            console.info('Found main.dart: $relativePath');
            break;
          }
        }
      }
    }

    // Detect .env file
    final envPath = p.join(projectRoot, '.env');
    if (await File(envPath).exists()) {
      buildEnv.set('ENV_PATH', './.env');
      console.info('Found .env file');
    }

    // Save .buildenv
    await buildEnv.save();

    // Show summary
    console.blank();
    console.success('BUILDENV GENERATED SUCCESSFULLY!');
    console.info('Location: ${buildEnv.buildEnvPath}');
    console.blank();
    
    console.section('Summary');
    console.keyValue('App Name', buildEnv.appName);
    console.keyValue('Version', buildEnv.fullVersion);
    console.keyValue('Build Type', buildEnv.buildType);
    console.keyValue('Output Path', buildEnv.outputPath);
    console.keyValue('FVM', buildEnv.useFvm ? 'Yes (${buildEnv.flutterVersion})' : 'No');
    console.keyValue('Shorebird', buildEnv.useShorebird ? 'Yes' : 'No');
    console.keyValue('Main Entry', buildEnv.targetDart);

    return 0;
  }
}
