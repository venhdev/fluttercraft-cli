# enhance-help-layout.idea.md

Improve the greeting shell with open source information like what --help does.

# Change the help view

Base on below --help view of shorebird, to update my help view:
- related cmds e.g: 
  - 'fluttercraft' (default command will show help view)
  - 'fluttercraft help'
  - 'fluttercraft --help'
  - 'flc --help'
  - 'fluttercraft -h'
  - 'flc -h'
  - 'flc help'

```bash
$ shorebird
The shorebird command-line tool

Usage: shorebird <command> [arguments]

Global options:
-h, --help            Print this usage information.
    --version         Print the current version.
-v, --[no-]verbose    Noisy logging, including all shell commands executed.

Available commands:
  cache      Manage the Shorebird cache.
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

## Add Usage/subcommands section every run a specific cmd with opt help
eg: 
```bash
Usage: flutter build <subcommand> [arguments]
-h, --help    Print this usage information.

Available subcommands:
  aar         Build a repository containing an AAR and a POM file.
  apk         Build an Android APK file from your app.
  appbundle   Build an Android App Bundle file from your app.
  bundle      Build the Flutter assets directory from your app.
  web         Build a web application bundle.
  windows     Build a Windows desktop application
```