# ROM3-j613 roadmap

## Phase 0: verified J613 baseline

- [x] Document the working GPU, display and audio stack.
- [x] Record exact package versions.
- [x] Record Stage 2 and package hashes.
- [x] Add a live-system verification script.
- [x] Define the initial quarantine set.

## Phase 1: signed package repository

- [ ] Introduce `linux-rom3-j613` and `aura-rom3-j613` package variants.
- [ ] Create the ROM3 signing key outside the Git tree.
- [ ] Build the initial `rom3-j613` pacman repository.
- [ ] Sign packages and repository databases.
- [ ] Publish immutable snapshots.
- [ ] Test install and reinstall from the signed feed.

## Phase 2: fail-closed update guard

- [ ] Implement `rom3-j613-update`.
- [ ] Read and enforce `verified-stack.json`.
- [ ] Refuse unqualified changes to quarantined packages.
- [ ] Create a Btrfs snapshot and ESP backup before sensitive changes.
- [ ] Generate Stage 2 as a separate candidate.
- [ ] Require cold-boot verification after publishing.

## Phase 3: installer payload

- [ ] Build an Arch ARM KDE image from the verified ROM3 stack.
- [ ] Add a signed catalog restricted to `apple,j613`.
- [ ] Reuse the existing Aurora Installer `arch-kde` profile.
- [ ] Replace only the payload and trust metadata initially.
- [ ] Test clean install, first boot, cold boot and recovery.

## Phase 4: release

- [ ] Publish installer download.
- [ ] Publish signed package repository.
- [ ] Document rollback and recovery.
- [ ] Add reproducible build instructions.
- [ ] Consider additional M3 boards only after hardware testing.

