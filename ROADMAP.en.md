# ROADMAP (EN)

Goals and development plan for AR-VR App — Snake3D (Godot).

## Done

- Core snake movement with continuous forward and smooth turning
- Head path buffer with evenly spaced points for tail following
- Tail segment smoothing (follow/look rates)
- Food increases tail; spikes cause Game Over
- Game Over screen with Restart button and `E` key
- Third-person camera: distance, height, smoothing
- Built-in console: `restart`, `speed`, `turn`, `auto_forward`, camera params, `segments_*`, `cubes`, `console`, `console_height`
- Web export (WASM) and a simple local server

## Near Term

- Score and basic HUD (UI polish)
- Mobile/touch controls (on-screen buttons, gestures)
- Sounds and basic VFX (eat, collision, game over)
- Field boundary interactions (bounce/lose variants)
- Optional grid-based movement mode
- Console: command history, autocomplete, syntax help
- Persist settings (speed, camera, auto-forward) to a file
- Performance profiles and optimizations for low-end devices
- Docs/CI to automate Web build

## Mid Term

- Level generation/obstacles, difficulty progression
- Multiplayer modes (local/online exploration)
- Leaderboard (local/online)
- Advanced effects: post-process, particles optimized for Web

## AR/VR Experiments

- Explore Godot XR (OpenXR) for potential VR mode
- UI/UX adaptation for HMD: camera, input, comfort
- Performance and render quality tuning for XR devices

## Risks & Assumptions

- WebAssembly constraints in browsers (memory/perf)
- Mobile browsers vary in build/input/performance behavior
- XR support depends on device and driver quality

## Quality Approach

- Smoke test the build via static server
- Manual scenarios: controls, eat/spikes, restart, console commands
- Browser profiling (FPS, GC, network) for fine-tuning