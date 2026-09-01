# G2 hands-on comparison validation

Last updated: 2026-08-31

G2 cannot close from a build, launcher, ROM-recognition screenshot, synthetic save, or source inspection. It requires the exact upstream `1.0.1` comparison process to reach normal gameplay, accept real input, produce progress, exit, relaunch, and visibly restore that progress.

The native Metal canvas does not complete the available Computer Use accessibility-state handshake on this host. App-path, bundle-ID, and foreground-activation attempts all time out, and the control service refuses actions without a current state. Alternate OS event synthesis and blind coordinates are intentionally excluded. A human-observed pass is therefore the remaining supported route.

## Before starting

- Keep every Simulator shut down and every other DK64 process stopped.
- Do not move, rename, edit, or share `DK64.z64` or anything under the private evidence directory.
- Use the existing keyboard or a connected controller. Upstream defaults are summarized in `UPSTREAM-BASELINE.md`.
- Exit through the upstream UI and wait for the process to disappear; do not force-quit during save activity.

## Evidence session

From the repository root:

```sh
scripts/validate-upstream-play-session.sh begin
```

In the launched exact comparison:

1. choose `Start Game`;
2. reach the DK64 title/file flow;
3. create or select an Adventure file;
4. reach normal controllable gameplay with working video, audible game output, and responsive input;
5. make progress that is unmistakable after reload; and
6. exit cleanly.

Then record the actual changed Eep16k save:

```sh
scripts/validate-upstream-play-session.sh record-play-exit
scripts/validate-upstream-play-session.sh begin-reload
```

In the relaunched process, load the same Adventure file and visibly confirm the same progress. Capture a PNG that makes the restored state identifiable, write a short text note stating what was played, heard, controlled, saved, and restored, then exit cleanly. Record both:

```sh
scripts/validate-upstream-play-session.sh complete /absolute/path/reload.png /absolute/path/observation.txt
```

The session remains ignored and private at `generated/evidence/g2/play-session`. It contains artifact/source identity, pre/post save identities, a mode-`0600` private save backup, reload screenshot, observation note, and timestamps. The script rejects a missing, all-zero, wrong-sized, or unchanged save. It cannot judge screenshot truth; G2 status changes only after the evidence is reviewed against the PRD.

Use `status` to inspect the current phase. If a session cannot be completed, first exit the app and run `abort`; the entire session moves to a timestamped ignored archive rather than being deleted.
