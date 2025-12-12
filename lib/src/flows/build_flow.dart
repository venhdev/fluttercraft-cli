import '../ui/interactive_mode.dart';
import '../ui/menu.dart';
import '../utils/console.dart';
import 'flow_context.dart';

/// Build targets available in the wizard
const List<String> buildTargets = ['apk', 'aab', 'ipa', 'macos'];

/// Flavors available in the wizard
const List<String> defaultFlavors = ['(none)', 'dev', 'staging', 'prod'];

/// Interactive build wizard flow
/// 
/// Guides the user through build configuration:
/// 1. Select build target (apk/aab/ipa)
/// 2. Select flavor (dev/staging/prod)
/// 3. Optional: dart-defines
/// 4. Show summary and confirm
/// 5. Execute build (returns config, execution handled externally)
class BuildFlow extends BaseFlow {
  final Console console;
  final InteractiveMode interactiveMode;
  
  BuildFlow({
    Console? console,
    this.interactiveMode = InteractiveMode.arrow,
  }) : console = console ?? Console();
  
  @override
  int get totalSteps => 4;
  
  @override
  List<String> get stepNames => [
    'Build Target',
    'Flavor',
    'Dart Defines',
    'Confirm',
  ];
  
  /// Execute the build flow wizard
  /// 
  /// Returns true if user confirmed, false if cancelled.
  /// Access selected values via [context.allValues]:
  /// - 'target': String (apk, aab, ipa, macos)
  /// - 'flavor': String? (dev, staging, prod, or null)
  /// - 'dartDefines': String? (custom dart defines, or null)
  /// - 'clean': bool (whether to run flutter clean)
  @override
  Future<bool> execute() async {
    console.section('Build Wizard');
    console.blank();
    
    // Step 1: Select build target
    while (context.currentStep == 0) {
      final result = await _stepSelectTarget();
      if (result.isCancelled) return false;
      if (result.isNext) {
        context.setValue('target', result.value);
        context.next();
      }
    }
    
    // Step 2: Select flavor
    while (context.currentStep == 1) {
      final result = await _stepSelectFlavor();
      if (result.isCancelled) return false;
      if (result.isBack) {
        context.back();
        continue;
      }
      if (result.isNext) {
        context.setValue('flavor', result.value);
        context.next();
      }
    }
    
    // Step 3: Dart defines (optional)
    while (context.currentStep == 2) {
      final result = await _stepDartDefines();
      if (result.isCancelled) return false;
      if (result.isBack) {
        context.back();
        continue;
      }
      if (result.isNext || result.isSkip) {
        if (result.value != null && result.value!.isNotEmpty) {
          context.setValue('dartDefines', result.value);
        }
        context.next();
      }
    }
    
    // Step 4: Summary and confirm
    while (context.currentStep == 3) {
      final result = await _stepConfirm();
      if (result.isCancelled) return false;
      if (result.isBack) {
        context.back();
        continue;
      }
      if (result.isNext && result.value == true) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Step 1: Select build target
  Future<StepResult<String>> _stepSelectTarget() async {
    _printStepHeader(1, 'Select Build Target');
    
    final selected = await Menu.select(
      title: 'Choose build output type:',
      options: buildTargets,
      mode: interactiveMode,
    );
    
    if (selected == null) {
      return StepResult.cancel();
    }
    
    return StepResult.next(selected);
  }
  
  /// Step 2: Select flavor
  Future<StepResult<String?>> _stepSelectFlavor() async {
    _printStepHeader(2, 'Select Flavor');
    console.info('Press Ctrl+C to go back');
    
    final selected = await Menu.select(
      title: 'Choose build flavor:',
      options: defaultFlavors,
      mode: interactiveMode,
    );
    
    if (selected == null) {
      // Treat as back if we have previous steps
      if (context.currentStep > 0) {
        return StepResult.back();
      }
      return StepResult.cancel();
    }
    
    // "(none)" means no flavor
    final flavor = selected == '(none)' ? null : selected;
    return StepResult.next(flavor);
  }
  
  /// Step 3: Dart defines (optional)
  Future<StepResult<String?>> _stepDartDefines() async {
    _printStepHeader(3, 'Dart Defines (Optional)');
    
    console.info('Enter custom dart-defines (e.g., API_URL=https://...)');
    console.info('Leave empty to skip, or type "back" to go back');
    
    final input = await Menu.prompt(
      message: 'Dart defines',
      defaultValue: '',
    );
    
    if (input.toLowerCase() == 'back') {
      return StepResult.back();
    }
    
    if (input.isEmpty) {
      return StepResult.skip();
    }
    
    return StepResult.next(input);
  }
  
  /// Step 4: Show summary and confirm
  Future<StepResult<bool>> _stepConfirm() async {
    _printStepHeader(4, 'Build Summary');
    console.blank();
    
    // Display summary
    final target = context.getValue<String>('target') ?? 'apk';
    final flavor = context.getValue<String?>('flavor');
    final dartDefines = context.getValue<String?>('dartDefines');
    
    console.keyValue('Target', target.toUpperCase());
    console.keyValue('Flavor', flavor ?? '(default)');
    if (dartDefines != null && dartDefines.isNotEmpty) {
      console.keyValue('Dart Defines', dartDefines);
    }
    console.blank();
    
    // Ask for clean
    final cleanBuild = await Menu.confirm(
      message: 'Run flutter clean before build?',
      defaultValue: false,
    );
    context.setValue('clean', cleanBuild);
    
    console.blank();
    
    // Final confirmation
    final confirmed = await Menu.confirm(
      message: 'Proceed with build?',
      defaultValue: true,
    );
    
    if (!confirmed) {
      // Ask if they want to go back or cancel
      final goBack = await Menu.confirm(
        message: 'Go back to edit?',
        defaultValue: true,
      );
      
      if (goBack) {
        return StepResult.back();
      }
      return StepResult.cancel();
    }
    
    return StepResult.next(true);
  }
  
  /// Print step header with progress
  void _printStepHeader(int step, String title) {
    console.blank();
    console.section('Step $step/$totalSteps: $title');
  }
  
  /// Get the selected build configuration
  BuildConfig get buildConfig => BuildConfig(
    target: context.getValue<String>('target') ?? 'apk',
    flavor: context.getValue<String?>('flavor'),
    dartDefines: context.getValue<String?>('dartDefines'),
    clean: context.getValue<bool>('clean') ?? false,
  );
}

/// Build configuration from the wizard
class BuildConfig {
  final String target;
  final String? flavor;
  final String? dartDefines;
  final bool clean;
  
  const BuildConfig({
    required this.target,
    this.flavor,
    this.dartDefines,
    this.clean = false,
  });
  
  /// Convert to command-line arguments for build command
  List<String> toArgs() {
    final args = <String>['--type', target];
    
    if (flavor != null && flavor!.isNotEmpty) {
      args.addAll(['--flavor', flavor!]);
    }
    
    if (clean) {
      args.add('--clean');
    }
    
    // Dart defines would be handled separately
    
    return args;
  }
  
  @override
  String toString() => 'BuildConfig(target: $target, flavor: $flavor, '
      'dartDefines: $dartDefines, clean: $clean)';
}
