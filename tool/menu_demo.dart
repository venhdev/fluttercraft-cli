// Interactive menu demo script
// Run with: fvm dart run tool/menu_demo.dart

import 'package:mobile_build_cli/src/ui/menu.dart';
import 'package:mobile_build_cli/src/ui/interactive_mode.dart';

void main() async {
  print('=== Menu Demo ===\n');
  
  // Test arrow mode
  print('Testing ARROW mode:');
  final arrowResult = await Menu.select(
    title: 'Select build target:',
    options: ['apk', 'aab', 'ipa', 'macos'],
    mode: InteractiveMode.arrow,
  );
  print('Arrow mode selected: $arrowResult\n');
  
  // Test numeric mode
  print('\nTesting NUMERIC mode:');
  final numericResult = await Menu.select(
    title: 'Select flavor:',
    options: ['dev', 'staging', 'prod'],
    mode: InteractiveMode.numeric,
  );
  print('Numeric mode selected: $numericResult\n');
  
  // Test confirm
  print('\nTesting CONFIRM:');
  final confirmed = await Menu.confirm(message: 'Proceed with build?');
  print('Confirmed: $confirmed\n');
  
  // Test prompt
  print('\nTesting PROMPT:');
  final input = await Menu.prompt(
    message: 'Enter version',
    defaultValue: '1.0.0',
  );
  print('Input: $input\n');
  
  print('=== Demo Complete ===');
}
