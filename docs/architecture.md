# Architecture

ROM3-j613 is an integration distribution layer, not a new kernel, desktop or
package manager.

## Layers

1. **Arch Linux ARM base**
   - rolling `core`, `extra` and `alarm`.
2. **Aurora Silicon stack**
   - kernel, Aura, U-Boot, Mesa, Vulkan and hardware services.
3. **ROM3-j613 compatibility overlay**
   - replaces only packages that require board-specific fixes or version
     coordination.
4. **ROM3 update guard**
   - compares proposed transactions with `verified-stack.json`;
   - refuses unqualified movement of quarantined packages;
   - keeps recovery independent from the update itself.
5. **ROM3 installer delivery**
   - signed catalog restricted to `apple,j613`;
   - payload assembled from the same verified stack.

## Package naming

Replacement packages use ROM3 names and declare `provides`, `conflicts` and
`replaces` against their upstream package. This makes accidental replacement a
transaction conflict rather than a silent downgrade or upgrade.

## Non-goals

- supporting untested M3 boards;
- becoming a full Arch Linux ARM fork;
- weekly package churn for its own sake;
- claiming hardware verification from CI alone.

