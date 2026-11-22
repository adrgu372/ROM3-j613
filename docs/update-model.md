# Update model

ROM3 does not claim that an unrestricted `pacman -Syu` is safe. Arch Linux ARM
is rolling, while ROM3 qualifies a specific hardware stack.

## Policy

Packages listed in `stack/quarantine.packages` may move only when:

1. the source patch series applies to the new version;
2. packages build reproducibly;
3. the complete proposed package set passes dependency checks;
4. a Stage 2 candidate is generated separately;
5. a cold boot verifies display, GPU, render node and audio;
6. the new combination is signed and published as a new snapshot.

## Intended client flow

```text
rom3-j613-update
  -> refresh package databases
  -> compute proposed transaction
  -> compare quarantine with verified-stack.json
  -> stop if an unqualified sensitive package would move
  -> snapshot Btrfs and back up boot.bin
  -> install the qualified package set
  -> generate Stage 2 candidate
  -> require cold-boot validation
```

Ordinary packages can still follow Arch Linux ARM, but a transaction that
crosses an unqualified compatibility boundary must fail closed.

## Repository channels

The initial design has:

- `stable`: fully hardware-qualified J613 package set;
- `testing`: candidate snapshots not yet cold-boot qualified.

Only `stable` should be configured for normal users.

