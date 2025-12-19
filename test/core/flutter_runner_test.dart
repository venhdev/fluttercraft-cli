import 'package:test/test.dart';
import 'package:fluttercraft/src/core/flutter_runner.dart';

void main() {
  group('FlutterRunner Clean Command', () {
    late FlutterRunner runner;

    setUp(() {
      runner = FlutterRunner(projectRoot: '.');
    });

    test('getCleanCommand returns plain flutter clean when useFvm is false', () {
      expect(runner.getCleanCommand(useFvm: false), 'flutter clean');
    });

    test('getCleanCommand returns fvm flutter clean when useFvm is true', () {
      expect(runner.getCleanCommand(useFvm: true), 'fvm flutter clean');
    });
  });
}
