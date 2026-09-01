# PaperPad Apple shell snapshot

The source files in this directory are a byte-for-byte snapshot of the Apple
shell at the pinned PaperPad reference revision recorded in
`dependencies.lock.json`. This deliberately preserves PaperPad's touch overlay,
layout behavior, settings presentation, ROM setup flow, diagnostics flow, and
top-right three-dot menu as the UI reference requested for BananaPad.

Keep game-specific adaptation outside this snapshot or express it as a small,
reviewable build-time patch. Verify the snapshot with:

```sh
for file in apple/app/*; do
  name=${file##*/}
  reference="ref/paperpad/apple/app/$name"
  [[ ! -f "$reference" ]] || cmp "$file" "$reference"
done
```

The app icon asset is intentionally handled separately because BananaPad needs
its own product identity. ROMs, saves, generated recompilation output, signing
credentials, and evidence do not belong in this directory.
