# enhance-fluttercraft.yaml-layout.idea.md when run 'gen' cmd

## Add anotation (just add @read-only to the key that need to be read-only, otherwise it will be read-write by default to keep my code clean)
- @read-write (--user can edit then run 'reload' cmd to apply that config to current build context).
- @read-only (--cli's context never load this config key from fluttercraft.yaml, instead key with @read-only will using value from another source. eg: the [shorebird:artifact] will base on [build:type])

  - expected format:
```yaml
build:
  # options: aab | apk | ipa | app || null
  ## if null, it will build aab
  type: apk
  name: 2.2.0
  # <others...>
shorebird:
  enabled: true
  # @read-only [build:type]
  # --artifact <options>
  artifact: apk
```

## Re-format the fluttercraft.yaml structure (also update .example file)

- Remove uppercase comments (eg: APPNAME, BUILD_NAME, BUILD_NUMBER). It's not needed and it's from old times. Only keep the explanation after "-".
- The comment should above the line, not by (right) side.

eg:

from
```yaml
app:
  name: app_ft_luxen # APPNAME - app identifier
```
to
```yaml
# App identifier
app:
  name: app_name
<other settings...>

build:
  # options: aab | apk | ipa | app || null
  ## if null, it will build aab
  type: apk                  
<other settings...>
```

