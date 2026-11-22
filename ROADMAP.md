# ROM3-j613 roadmap

## Phase 0: verified J613 baseline

- [x] Document the working GPU, display and audio stack.
- [x] Record exact package versions.
- [x] Record Stage 2 and package hashes.
- [x] Add a live-system verification script.
- [x] Define the initial quarantine set.

## Phase 1: signed package repository

- [x] Import the tested kernel and Aura recipes.
- [x] Add exact-version meta and update-guard packages.
- [x] Build initial local test packages.
- [x] Exercise `repo-add`, package signatures and database signatures with an
  ephemeral non-production key.
- [x] Add the pacman client configuration and `rom3-j613-release` package.
- [x] Add keyring packaging, public-key import and GitHub release publishing
  tooling.
- [x] Validate package signing, database signing and keyring generation with
  ephemeral keys.
- [x] Create the ROM3 signing key outside the Git tree.
- [x] Build the initial `rom3-j613` pacman repository.
- [x] Sign packages and repository databases.
- [x] Publish immutable snapshots.
- [x] Test install and reinstall from the signed feed.
- [x] Bundle every direct sensitive dependency in the signed snapshot.

## Phase 2: fail-closed update guard

- [x] Implement `rom3-j613-update`.
- [x] Read and enforce `verified-stack.json`.
- [x] Refuse unqualified changes to quarantined packages.
- [ ] Create a Btrfs snapshot and ESP backup before sensitive changes.
- [ ] Generate Stage 2 as a separate candidate.
- [ ] Require cold-boot verification after publishing.

The initial signed feed has since been published and attached to the live J613
system; these boxes will be checked as their repeatability evidence is added.

## Phase 3: installer payload

- [x] Define the J613-only installer profile and payload plan.
- [x] Add the upstream image build patch and native build wrapper.
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

