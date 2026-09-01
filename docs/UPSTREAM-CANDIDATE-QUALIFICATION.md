# Upstream candidate qualification

Use this only for a genuinely newer DK64Recompiled stable tag or deliberately selected exact fix. A same-pin rehearsal does not need a human qualification record.

First stage, regenerate, build, smoke, and run the mechanical test:

```sh
scripts/stage-upstream-update.sh <stable-tag-or-exact-commit> <label>
scripts/prepare-upstream-candidate.sh
BANANAPAD_SIMULATOR_UDID=<the-only-booted-iPad> \
BANANAPAD_ROM_PATH=/absolute/path/to/private-original-rom \
  scripts/build-upstream-candidate.sh --smoke
scripts/test-upstream-update.sh
```

For a new pin, the last command intentionally reports `needs-full-validation`. Review the upstream diff and generated manifests, run the affected macOS and iPad gameplay routes, prove save/reload and settings compatibility, and run the product audits. Record real evidence—not intended commands—in a private ignored JSON file:

```json
{
  "result": "pass",
  "qualifiedBy": "reviewer name",
  "checks": {
    "patchReplay": "pass",
    "deterministicGeneration": "pass",
    "macosGameplay": "pass",
    "ipadTouchGameplay": "pass",
    "saveReload": "pass",
    "settingsCompatibility": "pass",
    "audits": "pass"
  },
  "evidence": [
    "absolute path to gameplay notes or capture",
    "absolute path to save/reload evidence",
    "exact validation command and result"
  ]
}
```

Then bind it and rerun the gate:

```sh
scripts/qualify-upstream-candidate.sh /absolute/path/to/review-evidence.json
scripts/test-upstream-update.sh
scripts/promote-upstream-update.sh --apply
```

The qualification script supplies the commit, recursive submodule/worktree identities, BananaPad product identity, generated game/patch/decompressed-ROM hashes, app executable hash, and immutable Simulator receipt. It refuses incomplete checklists. The test gate refuses a qualification copied from another build. Any source, patch, generated-input, product, app, or receipt change invalidates promotion. Re-running candidate preparation archives an existing qualification as invalidated; candidate rollback archives it with the checkout.

Promotion remains a deliberate review action. Never manufacture `pass` values for work that was not performed, and never treat unreleased upstream `main` as an automatic update.
