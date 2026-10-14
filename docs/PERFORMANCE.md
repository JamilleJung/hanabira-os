# Performance measurements

`desktop/core` provides `hanabira-perf` and a time-based critically damped
spring. Its tests verify equivalent results at 60 and 240 updates/second,
reduced-motion completion, invalid capture rejection and detected frame stalls.

Analyze an actual capture:

```sh
cargo run --release --manifest-path desktop/core/Cargo.toml --bin hanabira-perf -- \
  analyze frames.csv --refresh-hz 240
```

CSV contains `timestamp_ns` (optionally `timestamp_ns,kind`) on the first line and strictly increasing monotonic
nanoseconds, one per frame. Comments beginning with `#` can identify the clock
source/backend. The tool reports average FPS, mean/P95/P99/max interval and
estimated missed refreshes. Missed refreshes are an interval estimate, not a
driver counter. Submission timestamps do not establish physical presentation.
Optional kind values are `submitted` or `presented`; mixed clocks are rejected.
An event-driven idle capture includes long gaps by design. Average FPS from
that capture must not be represented as an animation benchmark or dropped
hardware frames; benchmark a sustained, identified animation workload separately.

Record alongside each capture: source commit, build profile, renderer/driver,
display mode, backend, resolution/scaling, workload, duration, CPU/GPU/memory
utilization and whether the display really supports the requested refresh.
Use idle, window movement/resize, launcher search, wallpaper animation, a real
application and mixed-refresh outputs. Hardware power and input latency need
hardware-specific measurement and are pending.

Never publish synthetic unit-test data as a desktop performance result. The
spring tests are numerical correctness checks, not FPS benchmarks.
