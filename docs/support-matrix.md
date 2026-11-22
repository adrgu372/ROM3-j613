# Hardware support matrix

## Verified

| Board | Hardware | GPU | Display | Audio | Status |
|---|---|---|---|---|---|
| `apple,j613` | MacBook Air 13-inch M3 | Apple G15G | verified | verified | stable target |

## Explicitly unsupported

| Board | Hardware | Status |
|---|---|---|
| `apple,j615` | MacBook Air 15-inch M3 | build-only until tested |
| `apple,j504` | MacBook Pro 14-inch M3 | unsupported until tested |
| Other `t8122` boards | M3 family | unsupported until tested |

Shared `T8122` identification is not enough to claim support. The 15-inch
audio path already requires a different MCA sense timing fix, so device trees,
PMP state and audio profiles must be qualified separately.

Adding a board requires:

- its own cold-boot evidence;
- internal display and external-output checks;
- GPU render-node and renderer checks;
- speaker-safety and microphone checks;
- recovery and Stage 2 rollback evidence.

