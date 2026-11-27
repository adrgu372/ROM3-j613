# Daily upstream watch

`scripts/check-upstream-updates.py` compares the ROM3 pins with these upstream
repositories:

- `aurora-silicon/linux`;
- `aurora-silicon/aura`;
- `aurora-silicon/asahi-audio`;
- `aurora-silicon/alarm-aurora`;
- `aurora-silicon/aurora-installer`.

The `rom3-j613-upstream-watch` GitHub Actions workflow runs it every day and
updates one issue titled **ROM3-j613 daily upstream watch**. The issue retains
the last observed commit for each repository in a hidden state block, so each
report describes changes since the previous run rather than replaying the
entire upstream history.

## Decisions

- **BUILD CANDIDATE**: a new kernel change touches a J613-critical device tree
  or display, GPU, camera, audio, power or firmware path, or appears to fix a
  relevant crash, regression or security problem.
- **REVIEW MATCHED STACK**: The Aura-derived ROM3 bootloader or the matched audio package changed.
- **REVIEW REBUILD**: image-builder or installer code changed.
- **REVIEW**: upstream changed, but no high-priority J613 path was detected.
- **WAIT**: nothing changed since the previous check.

The utility does not compile, sign, publish or install anything. A `BUILD
CANDIDATE` is only a request to evaluate the change. Kernel compilation still
follows the full qualification and rollback process in
[`update-model.md`](update-model.md).

## Run manually

From a checkout with an authenticated `gh` CLI:

```bash
python3 scripts/check-upstream-updates.py \
  --state-out /tmp/rom3-upstream-state.json \
  --report /tmp/rom3-upstream-report.md
```

The first local run establishes a baseline and only shows the distance from the
current ROM3 pins. Later runs use the prior state to isolate new commits.

The source list and J613-critical paths are maintained in
`maintenance/watch-sources.json`.
