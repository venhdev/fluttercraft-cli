/// Flow step result indicating the action taken
enum FlowAction {
  /// Continue to next step
  next,
  
  /// Go back to previous step
  back,
  
  /// Skip this step (for optional steps)
  skip,
  
  /// Cancel the entire flow
  cancel,
}

/// Result from a single flow step
class StepResult<T> {
  final FlowAction action;
  final T? value;
  
  StepResult.next(this.value) : action = FlowAction.next;
  StepResult.back() : action = FlowAction.back, value = null;
  StepResult.skip() : action = FlowAction.skip, value = null;
  StepResult.cancel() : action = FlowAction.cancel, value = null;
  
  bool get isNext => action == FlowAction.next;
  bool get isBack => action == FlowAction.back;
  bool get isSkip => action == FlowAction.skip;
  bool get isCancelled => action == FlowAction.cancel;
}

/// Context for managing multi-step flow state
/// 
/// Tracks selected values, current step, and allows navigation
/// between steps (next, back, skip, cancel).
class FlowContext {
  final Map<String, dynamic> _values = {};
  final List<String> _history = [];
  
  int _currentStep = 0;
  bool _cancelled = false;
  
  /// Get current step index (0-based)
  int get currentStep => _currentStep;
  
  /// Check if flow was cancelled
  bool get isCancelled => _cancelled;
  
  /// Store a value with a key
  void setValue<T>(String key, T value) {
    _values[key] = value;
    if (!_history.contains(key)) {
      _history.add(key);
    }
  }
  
  /// Get a stored value
  T? getValue<T>(String key) {
    final value = _values[key];
    if (value is T) return value;
    return null;
  }
  
  /// Get value with default
  T getValueOrDefault<T>(String key, T defaultValue) {
    return getValue<T>(key) ?? defaultValue;
  }
  
  /// Check if a key has been set
  bool hasValue(String key) => _values.containsKey(key);
  
  /// Move to next step
  void next() {
    _currentStep++;
  }
  
  /// Go back one step
  bool back() {
    if (_currentStep > 0) {
      _currentStep--;
      return true;
    }
    return false;
  }
  
  /// Cancel the flow
  void cancel() {
    _cancelled = true;
  }
  
  /// Reset to initial state
  void reset() {
    _values.clear();
    _history.clear();
    _currentStep = 0;
    _cancelled = false;
  }
  
  /// Get all stored values
  Map<String, dynamic> get allValues => Map.unmodifiable(_values);
  
  /// Get step history (keys in order)
  List<String> get history => List.unmodifiable(_history);
  
  @override
  String toString() {
    return 'FlowContext(step: $_currentStep, cancelled: $_cancelled, values: $_values)';
  }
}

/// Base class for multi-step flows
abstract class BaseFlow {
  final FlowContext context;
  
  BaseFlow() : context = FlowContext();
  
  /// Execute the flow and return success status
  Future<bool> execute();
  
  /// Get the total number of steps
  int get totalSteps;
  
  /// Get names of all steps for progress display
  List<String> get stepNames;
}
