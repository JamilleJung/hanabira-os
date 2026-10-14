//! Small shared primitives. No timers, background threads or telemetry upload.

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotionIntensity {
    Cinematic,
    Balanced,
    Minimal,
    Reduced,
}

#[derive(Debug, Clone, Copy)]
pub struct Spring {
    pub position: f64,
    pub velocity: f64,
    pub target: f64,
}

impl Spring {
    pub fn new(position: f64) -> Self {
        Self {
            position,
            velocity: 0.0,
            target: position,
        }
    }

    /// Analytic critically damped spring. Time comes from the presentation clock,
    /// never a fixed number of animation frames. Returns whether more frames are needed.
    pub fn advance(&mut self, dt_seconds: f64, intensity: MotionIntensity) -> bool {
        if !dt_seconds.is_finite() || dt_seconds < 0.0 {
            return self.is_active();
        }
        if intensity == MotionIntensity::Reduced {
            self.position = self.target;
            self.velocity = 0.0;
            return false;
        }
        let omega = match intensity {
            MotionIntensity::Cinematic => 15.0,
            MotionIntensity::Balanced => 23.0,
            MotionIntensity::Minimal => 38.0,
            MotionIntensity::Reduced => unreachable!(),
        };
        let delta = self.position - self.target;
        let c = self.velocity + omega * delta;
        let decay = (-omega * dt_seconds).exp();
        self.position = self.target + (delta + c * dt_seconds) * decay;
        self.velocity = (self.velocity - omega * c * dt_seconds) * decay;
        if !self.is_active() {
            self.position = self.target;
            self.velocity = 0.0;
            return false;
        }
        true
    }
    pub fn is_active(&self) -> bool {
        (self.position - self.target).abs() > 0.001 || self.velocity.abs() > 0.001
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct FrameStats {
    pub intervals: usize,
    pub mean_ms: f64,
    pub p95_ms: f64,
    pub p99_ms: f64,
    pub max_ms: f64,
    pub average_fps: f64,
    pub estimated_missed_refreshes: u64,
    pub refresh_hz: f64,
}

pub fn analyze_frames(timestamps_ns: &[u64], refresh_hz: f64) -> Result<FrameStats, &'static str> {
    if !refresh_hz.is_finite() || refresh_hz <= 0.0 {
        return Err("refresh rate must be finite and positive");
    }
    if timestamps_ns.len() < 2 {
        return Err("at least two timestamps are required");
    }
    let mut times = Vec::with_capacity(timestamps_ns.len() - 1);
    for pair in timestamps_ns.windows(2) {
        if pair[1] <= pair[0] {
            return Err("timestamps must be strictly increasing");
        }
        times.push((pair[1] - pair[0]) as f64 / 1_000_000.0);
    }
    let mean = times.iter().sum::<f64>() / times.len() as f64;
    let budget = 1000.0 / refresh_hz;
    // An estimate from intervals, not a hardware presentation counter.
    let missed = times
        .iter()
        .map(|ms| ((ms / budget).round() as u64).saturating_sub(1))
        .sum();
    times.sort_by(f64::total_cmp);
    let percentile = |p: f64| times[((times.len() as f64 * p).ceil() as usize).saturating_sub(1)];
    Ok(FrameStats {
        intervals: times.len(),
        mean_ms: mean,
        p95_ms: percentile(0.95),
        p99_ms: percentile(0.99),
        max_ms: *times.last().unwrap(),
        average_fps: 1000.0 / mean,
        estimated_missed_refreshes: missed,
        refresh_hz,
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn animation_is_refresh_independent() {
        let run = |hz: usize| {
            let mut s = Spring::new(0.0);
            s.target = 100.0;
            for _ in 0..hz {
                s.advance(1.0 / hz as f64, MotionIntensity::Balanced);
            }
            s
        };
        let a = run(60);
        let b = run(240);
        assert!((a.position - b.position).abs() < 1e-8);
        assert!((a.velocity - b.velocity).abs() < 1e-8);
    }
    #[test]
    fn reduced_motion_schedules_no_extra_frames() {
        let mut s = Spring::new(0.0);
        s.target = 42.0;
        assert!(!s.advance(0.0, MotionIntensity::Reduced));
        assert_eq!(s.position, 42.0);
        assert!(!s.is_active());
    }
    #[test]
    fn invalid_time_does_not_corrupt_motion() {
        let mut s = Spring::new(10.0);
        s.target = 20.0;
        s.advance(f64::NAN, MotionIntensity::Balanced);
        assert_eq!(s.position, 10.0);
    }
    #[test]
    fn measures_stalls_and_quantiles() {
        let mut t = vec![0];
        for i in 0..100 {
            t.push(t.last().unwrap() + if i == 99 { 20_000_000 } else { 4_000_000 });
        }
        let s = analyze_frames(&t, 250.0).unwrap();
        assert_eq!(s.p95_ms, 4.0);
        assert_eq!(s.p99_ms, 4.0);
        assert_eq!(s.max_ms, 20.0);
        assert_eq!(s.estimated_missed_refreshes, 4);
    }
    #[test]
    fn rejects_invalid_captures() {
        assert!(analyze_frames(&[10, 10], 240.0).is_err());
        assert!(analyze_frames(&[10], 240.0).is_err());
        assert!(analyze_frames(&[10, 20], 0.0).is_err());
    }
}
