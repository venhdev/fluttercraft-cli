
# shorebird-official-docs.md
see (https://docs.shorebird.dev/)

**NOTICE**
- never add `--release` | `--debug` | `--profile` when using `shorebird`.

## Shorebird command-line

*_default global options cmd_*
```bash
> shorebird
The shorebird command-line tool

Usage: shorebird <command> [arguments]

Global options:
-h, --help            Print this usage information.
    --version         Print the current version.
-v, --[no-]verbose    Noisy logging, including all shell commands executed.

Available commands:
  cache      Manage the Shorebird cache.
  create     Create a new Flutter project with Shorebird.
  doctor     Show information about the installed tooling.
  flutter    Manage your Shorebird Flutter installation.
  init       Initialize Shorebird.
  login      Login as a new Shorebird user.
  login:ci   Login as a CI user.
  logout     Logout of the current Shorebird user
  patch      Creates a shorebird patch for the provided target platforms
  patches    Manage Shorebird patches
  preview    Preview a specific release on a device.
  release    Creates a shorebird release for the provided target platforms
  releases   Manage Shorebird releases
  upgrade    Upgrade your copy of Shorebird.

Run "shorebird help <command>" for more information about a command.
```

*_releases cmd_* to Manage Shorebird releases
```bash
shorebird releases -h
Manage Shorebird releases

Usage: shorebird releases <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  get-apks   Generates apk(s) for the specified release version

Run "shorebird help" to see global options.
```

*_release cmd_* to Creates a shorebird release for the provided target platforms
```bash
shorebird release -h
Creates a shorebird release for the provided target platforms

Usage: shorebird release [arguments]
-h, --help                     Print this usage information.
    --dart-define              Additional key-value pairs that will be available as constants from the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment constructors.
                               Multiple defines can be passed by repeating "--dart-define" multiple times.
    --dart-define-from-file    The path of a .json or .env file containing key-value pairs that will be available as environment variables.
                               These can be accessed using the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment constructors.
                               Multiple defines can be passed by repeating "--dart-define-from-file" multiple times.
                               Entries from "--dart-define" with identical keys take precedence over entries from these files.
-t, --target                   The main entrypoint file of the application.
    --flavor                   The product flavor to use when building the app.
    --build-name               A "x.y.z" string used as the version number shown to users.
                               For each new version of your app, you will provide a version number to differentiate it
                               from previous versions.
                               On Android it is used as "versionName".
                               On Xcode builds it is used as "CFBundleShortVersionString".
                               On Windows it is used as the major, minor, and patch parts of the product and file
                               versions.
    --build-number             An identifier used as an internal version number.
                               Each build must have a unique identifier to differentiate it from previous builds.
                               It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
                               On Android it is used as "versionCode".
                               On Xcode builds it is used as "CFBundleVersion".
                               (defaults to "1.0")
    --[no-]codesign            Codesign the application bundle (iOS only).
                               (defaults to on)
-n, --dry-run                  Validate but do not upload the release.
    --export-options-plist     Export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys (iOS only).
    --export-method            Specify how the IPA will be distributed (iOS only).

          [app-store]          Upload to the App Store
          [ad-hoc]             Test on designated devices that do not need to be registered with the Apple developer account.
                                   Requires a distribution certificate.
          [development]        Test only on development devices registered with the Apple developer account.
          [enterprise]         Distribute an app registered with the Apple Developer Enterprise Program.

    --flutter-version          The Flutter version to use when building the app (e.g: 3.16.3).
                               This option also accepts Flutter commit hashes (e.g. 611a4066f1).
                               Defaults to "latest" which builds using the latest stable Flutter version.
                               (defaults to "latest")
    --artifact                 The type of artifact to generate. Only relevant for Android releases.

          [aab] (default)      Android App Bundle
          [apk]                Android Package Kit

-p, --platforms                The platform(s) to to build this release for.
                               [aar, android, ios, linux, macos, ios-framework, windows]
    --no-confirm               Bypass all confirmation messages. It's generally not advised to use this unless running from a script.
    --release-version          The version of the associated release (e.g. "1.0.0"). This should be the version
                               of the iOS app that is using this module. (aar and ios-framework only)
    --target-platform          The target platform(s) for which the app is compiled.
                               [android-arm (default), android-arm64 (default), android-x64 (default)]
    --public-key-path          The path for a public key .pem file that will be used to validate patch signatures.
    --split-debug-info         In a release build, this flag reduces application size by storing Dart program symbols in a separate file on the host rather than   
                               in the application. The value of the flag should be a directory where program symbol files can be stored for later use. These       
                               symbol files contain the information needed to symbolize Dart stack traces. For an app built with this flag, the "flutter
                               symbolize" command with the right program symbol file is required to obtain a human readable stack trace.

Run "shorebird help" to see global options
```

*_patch cmd_*
```bash
shorebird patch --help
Creates a shorebird patch for the provided target platforms

Usage: shorebird patch [arguments]
-h, --help                     Print this usage information.
    --dart-define              Additional key-value pairs that will be available as constants from the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment constructors.
                               Multiple defines can be passed by repeating "--dart-define" multiple times.
    --dart-define-from-file    The path of a .json or .env file containing key-value pairs that will be available as environment variables.
                               These can be accessed using the String.fromEnvironment, bool.fromEnvironment, and int.fromEnvironment constructors.
                               Multiple defines can be passed by repeating "--dart-define-from-file" multiple times.
                               Entries from "--dart-define" with identical keys take precedence over entries from these files.
-p, --platforms                The platform(s) to to build this release for.
                               [aar, android, ios, linux, macos, ios-framework, windows]
    --build-name               A "x.y.z" string used as the version number shown to users.
                               For each new version of your app, you will provide a version number to differentiate it
                               from previous versions.
                               On Android it is used as "versionName".
                               On Xcode builds it is used as "CFBundleShortVersionString".
                               On Windows it is used as the major, minor, and patch parts of the product and file
                               versions.
    --build-number             An identifier used as an internal version number.
                               Each build must have a unique identifier to differentiate it from previous builds.
                               It is used to determine whether one build is more recent than another, with higher numbers indicating more recent build.
                               On Android it is used as "versionCode".
                               On Xcode builds it is used as "CFBundleVersion".
                               (defaults to "1.0")
-t, --target                   The main entrypoint file of the application.
    --flavor                   The product flavor to use when building the app.
    --release-version          The version of the associated release (e.g. "1.0.0").
                               If you are building an xcframework or aar, this number needs to match the host app's release version.
                               To target the latest release (e.g. the release that was most recently updated) use --release-version=latest.
    --allow-native-diffs       Patch even if native code diffs are detected.
                               NOTE: this is not recommended. Native code changes cannot be included in a patch and attempting to do so can cause your app to crash or behave unexpectedly.
    --allow-asset-diffs        Patch even if asset diffs are detected.
                               NOTE: this is not recommended. Asset changes cannot be included in a patch can cause your app to behave unexpectedly.
    --track                    The track to publish the patch to.
                               (defaults to "stable")
    --no-confirm               Bypass all confirmation messages. It's generally not advised to use this unless running from a script.
    --export-options-plist     Export an IPA with these options. See "xcodebuild -h" for available exportOptionsPlist keys (iOS only).
    --export-method            Specify how the IPA will be distributed (iOS only).

          [app-store]          Upload to the App Store
          [ad-hoc]             Test on designated devices that do not need to be registered with the Apple developer account.
                                   Requires a distribution certificate.
          [development]        Test only on development devices registered with the Apple developer account.
          [enterprise]         Distribute an app registered with the Apple Developer Enterprise Program.

    --[no-]codesign            Codesign the application bundle (iOS only).
                               (defaults to on)
-n, --dry-run                  Validate but do not upload the patch.
    --private-key-path         The path for a private key .pem file that will be used to sign the patch artifact.
    --public-key-path          The path for a public key .pem file that will be used to validate patch signatures.
    --split-debug-info         In a release build, this flag reduces application size by storing Dart program symbols in a separate file on the host rather than   
                               in the application. The value of the flag should be a directory where program symbol files can be stored for later use. These       
                               symbol files contain the information needed to symbolize Dart stack traces. For an app built with this flag, the "flutter
                               symbolize" command with the right program symbol file is required to obtain a human readable stack trace.
    --min-link-percentage      The minimum link percentage (0-100) required in order to generate a patch (Apple platforms only).

                               Patches with a lower link percentage than what is provided here will fail.
                               [0 (default), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100]

Run "shorebird help" to see global options.
```

## Official Shorebird - Create a Release
(https://docs.shorebird.dev/code-push/release/)

### Note using flutter argument

```
shorebird release wraps flutter build and can take any argument flutter build can. To pass arguments to the underlying flutter build you need to put flutter build arguments after a -- separator. For example: shorebird release android -- --dart-define="foo=bar" will define the "foo" environment variable inside Dart as you might have done with flutter build directly. In Powershell the -- separator must be quoted: '--'.
```

### Note using flutter version

```
By default shorebird release uses the Flutter version bundled within the shorebird installation.
That version can be checked by running `shorebird doctor`.

To release with a different Flutter version, you can specify the version using the `--flutter-version` flag.

`shorebird release android --flutter-version 3.35.3`

```

### Manage Releases

#### List Releases

You can view all of your releases for your current app (as defined by your shorebird.yaml) on the [Shorebird console](https://console.shorebird.dev/).

*Quick access link (replace <app_id> with your app id): `https://console.shorebird.dev/apps/<app_id>`

#### Side-loading and MDM

A common question we get asked is: Does Shorebird require publishing to the App Store or Play Store?

No. Shorebird works fine with side-loading and mobile device management (MDM) on Android. We’ve not had anyone try Shorebird with iOS Developer Enterprise program, but we expect it to work just as well.

To build Shorebird for distribution via APK (e.g. side-loading), use the `--artifact` flag with the `shorebird release` command. For example:

Terminal window
`shorebird release android --artifact=apk`

That will produce both .apk and .aab files. You can distribute either or both as needed.


## Official Shorebird - Create a Patch

Once you have published a release of your app, you can push updates using one of the shorebird patch commands.

This will do several things:

Builds the artifacts for the update.
Downloads the corresponding release artifacts.
Generates a patch using the diff between the release and the current changes.
Uploads the patch artifacts to the Shorebird backend
Promotes the patch to the stable channel.

By default, this uses the release version from the compiled artifact. If you want to target the latest release version, you can use --release-version latest. For example:

`shorebird patch android --release-version latest`

If you want to patch a different release version, you can use the --release-version option. For example:

`shorebird patch android --release-version 0.1.0+1`

If your application supports flavors or multiple release targets, you can specify the flavor and target using the --flavor and --target options:

`shorebird patch [android|ios] --target lib/main_development.dart --flavor development`

**IMPORTANT NOTE**
`shorebird patch` wraps `flutter build` and can take any argument `flutter build` can. To pass arguments to the underlying `flutter build` you need to put `flutter build` arguments after a `--` separator. For example: `shorebird patch android -- --dart-define="foo=bar"` will define the "foo" environment variable inside Dart as you might have done with `flutter build` directly.

