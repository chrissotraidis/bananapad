# PaperPad-derived BananaPad Apple shell

The source files in this directory are a reviewed snapshot and adaptation of
the Apple shell at the pinned PaperPad reference revision recorded in
`dependencies.lock.json`. BananaPad deliberately preserves PaperPad's touch
overlay, layout behavior, settings presentation, ROM setup flow, diagnostics
flow, and top-right three-dot menu while adapting product labels, DK64 controls,
private paths, ROM validation, and integration boundaries.

The fidelity gate permits only the reviewed label substitutions in
`ios_main.mm`; other adapted files are inventoried in `docs/SOURCE-MAP.md` and
reviewed normally. Verify the protected UI source with:

```sh
scripts/test-paperpad-ui-fidelity.sh
```

The app icon and release notices are BananaPad-owned product assets. ROMs,
saves, generated recompilation output, signing credentials, and evidence do not
belong in this directory.
