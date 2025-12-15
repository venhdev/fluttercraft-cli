# intergration-custom-cmd-idea
## allow user to custom cmds to run with alias like "flc run <cmd-alias>"
user setup custom cmds in config file like:

// fluttercraft.yaml
```yaml
alias:
    gen-icon:
        cmds:
        - fvm flutter pub get
        - fvm flutter pub run flutter_launcher_icons
    brn:
        cmds:
        - fvm flutter pub get
        - fvm flutter packages pub run build_runner build --delete-conflicting-outputs
```

then user can run:

```bash
flc run gen-icon
flc run brn
```

### user can list all available cmds with "flc run --list"