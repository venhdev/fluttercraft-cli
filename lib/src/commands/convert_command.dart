import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../core/build_config.dart';
import '../core/build_flags.dart';
import '../core/apk_converter.dart';
import '../utils/console.dart';

/// Convert command - converts AAB to universal APK
class ConvertCommand extends Command<int> {
  @override
  final String name = 'convert';

  @override
  final String description = 'Convert AAB to universal APK using bundletool';

  ConvertCommand() {
    argParser
      ..addOption(
        'aab',
        abbr: 'a',
        help: 'Path to AAB file (auto-detects from dist if not specified)',
      )
      ..addOption('output', abbr: 'o', help: 'Output directory for APK')
      ..addOption('bundletool', help: 'Path to bundletool.jar')
      ..addOption('key-properties', help: 'Path to key.properties file');
  }

  @override
  Future<int> run() async {
    final console = Console();
    final projectRoot = Directory.current.path;

    console.header('AAB → UNIVERSAL APK CONVERTER');

    // Load config
    BuildConfig config;
    try {
      config = await BuildConfig.load();
    } on ConfigNotFoundException {
      // Use defaults if no config
      config = BuildConfig(
        projectRoot: projectRoot,
        appName: 'app',
        buildName: '1.0.0',
        buildNumber: 1,
        platform: 'aab',
        targetDart: 'lib/main.dart',
        outputPath: '.fluttercraft/dist',
        flags: BuildFlags.defaults,
        useFvm: false,
        useShorebird: false,
        shorebirdNoConfirm: true,
        keystorePath: 'android/key.properties',
      );
    }

    final converter = ApkConverter(projectRoot: projectRoot, console: console);

    // Find or prompt for AAB file
    String? aabPath = argResults?['aab'] as String?;

    if (aabPath == null || aabPath.isEmpty) {
      // Search in dist folder
      console.section('Searching for AAB files...');
      final searchPath = config.absoluteOutputPath;
      final aabFiles = await converter.findAabFiles(searchPath);

      if (aabFiles.isEmpty) {
        console.warning('No AAB files found in $searchPath');
        aabPath = console.prompt('Enter path to AAB file');

        if (aabPath.isEmpty) {
          console.error('No AAB file specified');
          return 1;
        }
      } else if (aabFiles.length == 1) {
        aabPath = aabFiles.first;
        console.success('Found: ${p.basename(aabPath)}');
      } else {
        // Multiple AAB files - let user choose
        console.info('Found ${aabFiles.length} AAB files:');
        final options = aabFiles.map((f) => p.basename(f)).toList();
        final choice = console.choose('Select AAB file:', options);
        aabPath = aabFiles[choice];
      }
    }

    // Validate AAB file
    if (!await File(aabPath).exists()) {
      console.error('AAB file not found: $aabPath');
      return 1;
    }

    console.keyValue('AAB File', p.basename(aabPath));

    // Find bundletool
    console.section('Locating bundletool...');
    String? bundletoolPath = argResults?['bundletool'] as String?;
    bundletoolPath ??= config.bundletoolPath;

    bundletoolPath = await converter.findBundletool(customPath: bundletoolPath);

    if (bundletoolPath == null) {
      console.warning('Bundletool not found automatically');
      bundletoolPath = console.prompt('Enter path to bundletool.jar');

      if (bundletoolPath.isEmpty || !await File(bundletoolPath).exists()) {
        console.error('Bundletool not found');
        return 1;
      }
    }

    console.success('Found bundletool: ${p.basename(bundletoolPath)}');

    // Find key.properties
    console.section('Loading keystore configuration...');
    String keyPropertiesPath = argResults?['key-properties'] as String? ?? '';

    if (keyPropertiesPath.isEmpty) {
      keyPropertiesPath = p.join(projectRoot, config.keystorePath);
    }

    if (!await File(keyPropertiesPath).exists()) {
      console.warning('key.properties not found at: $keyPropertiesPath');
      keyPropertiesPath = console.prompt('Enter path to key.properties');

      if (keyPropertiesPath.isEmpty ||
          !await File(keyPropertiesPath).exists()) {
        console.error('key.properties not found');
        return 1;
      }
    }

    // Parse key.properties
    final keystoreConfig = await converter.parseKeyProperties(
      keyPropertiesPath,
    );
    if (keystoreConfig == null || !keystoreConfig.isValid) {
      console.error('Invalid key.properties file');
      return 1;
    }

    console.success('Loaded key.properties');
    console.keyValue('Key Alias', keystoreConfig.keyAlias);

    // Resolve keystore path
    final keystorePath = await converter.resolveKeystorePath(
      keystoreConfig.storeFile,
      keyPropertiesPath,
    );

    if (keystorePath == null) {
      console.error('Keystore file not found: ${keystoreConfig.storeFile}');
      return 1;
    }

    console.success('Found keystore: ${p.basename(keystorePath)}');

    // Output path
    String outputPath = argResults?['output'] as String? ?? '';
    if (outputPath.isEmpty) {
      outputPath = config.absoluteOutputPath;
    }

    console.blank();
    console.keyValue('Output', outputPath);

    // Confirmation
    if (!console.confirm('Convert AAB to universal APK?')) {
      console.warning('Cancelled');
      return 0;
    }

    // Convert
    final result = await converter.convert(
      aabPath: aabPath,
      outputPath: outputPath,
      bundletoolPath: bundletoolPath,
      keystorePath: keystorePath,
      keystoreConfig: keystoreConfig,
    );

    if (result.success) {
      console.blank();
      console.success('Conversion complete!');
      console.keyValue('Output', result.outputPath ?? outputPath);
      return 0;
    } else {
      console.error('Conversion failed: ${result.error}');
      return 1;
    }
  }
}
