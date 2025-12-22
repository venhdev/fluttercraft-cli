# **CRITICAL** Build error but show success

```base
flc -s
Loading project context...

┌─────────────────────────────────────────┐
│         fluttercraft CLI                │
│         v0.1.9                          │
└─────────────────────────────────────────┘

Type "help" for available commands, "exit" to quit.

fluttercraft> build

=== fluttercraft CLI ===


Version Management
  Current Version : 0.2.2+61

Select version increment:
  > 0. No change (keep 0.2.2)
    1. Patch (+0.0.1) → 0.2.3
    2. Minor (+0.1.0) → 0.3.0
    3. Major (+1.0.0) → 1.0.0
Enter choice [0-3]:

Build number:
  > 0. Keep current (61)
    1. Auto-increment (+1) → 62
    2. Set custom number
Enter choice [0-2]:

Build Configuration
  App Name        : dms
  Version         : 0.2.2+61
  Build Type      : AAB
  Output          : C:\src\cds_apps\smac_dms\.fluttercraft/dist
  Use FVM         : true
  Use Shorebird   : true
  Build ID        : 20251222-090745-2140


Build Command
The following command will be executed:

  shorebird release android --no-confirm --flutter-version=3.35.3 -- --build-name=0.2.2 --build-number=61


Do you want to proceed? (y/n) or (e)dit command: e

Edit Command
Current command:
  shorebird release android --no-confirm --flutter-version=3.35.3 -- --build-name=0.2.2 --build-number=61

Enter modified command (or press Enter to keep current): shorebird release android --no-confirm --flutter-version=3.35.3 -- --build-name=0.2.2 --build-number=61 --dart-define-from-file .env
Command updated.
New command:
  shorebird release android --no-confirm --flutter-version=3.35.3 -- --build-name=0.2.2 --build-number=61 --dart-define-from-file .env

Do you want to proceed? (y/n) or (e)dit command: y

Building AAB...
Using Shorebird for build
Shorebird → building AAB (default)
Missing argument for "--build-number".

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

Run "shorebird help" to see global options.
Copied AAB → dms_0.2.2+61.sb.base.aab

═══════════════════════════════════════════
  BUILD COMPLETE
═══════════════════════════════════════════
  App Name        : dms
  Version         : 0.2.2+61
  Build Type      : AAB
  Output          : C:\src\cds_apps\smac_dms\.fluttercraft/dist\dms_0.2.2+61.sb.base.aab
  Duration        : 0s
═══════════════════════════════════════════

Log: C:\src\cds_apps\smac_dms\.fluttercraft\build_latest.log
Build Log: C:\src\cds_apps\smac_dms\.fluttercraft\logs\20251222-090745-2140.log
History: C:\src\cds_apps\smac_dms\.fluttercraft\build_history.jsonl
fluttercraft>
```