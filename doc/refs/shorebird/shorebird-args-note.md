If your application supports flavors or multiple release targets, you can specify the flavor and target using the --flavor and --target options:

Terminal window
shorebird release android --target ./lib/main_development.dart --flavor development

Note

`shorebird release` wraps `flutter build` and can take any argument `flutter build` can. To pass arguments to the underlying flutter build you need to put `flutter build` arguments after a `--` separator. For example: `shorebird release android -- --dart-define="foo=bar"` will define the "foo" environment variable inside Dart as you might have done with `flutter build` directly. In Powershell the `--` separator must be quoted: `'--'`.