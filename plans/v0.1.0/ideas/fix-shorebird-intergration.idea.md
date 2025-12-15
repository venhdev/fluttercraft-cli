# fix-shorebird-intergration.idea.md

Because the `shorebird release` wraps `flutter build` and can take any argument `flutter build` can. So it has some diff cmd arguments (see [docs](doc\refs\shorebird\shorebird-official-docs.md))

**IMPORTANT**
- update the `shorebird` related (when exist file shorebird.yaml case only).
- never add `--release` | `--debug` | `--profile` when using `shorebird`.

## Rename auto_confirm to no_confirm

Change the "auto_confirm: true" to "no_confirm: true"
(still keep default value is true)