use hanabira_core::analyze_frames;
use std::{env, fs, process};

fn run() -> Result<(), String> {
    let args: Vec<String> = env::args().skip(1).collect();
    if args == ["--help"] || args.is_empty() {
        println!("hanabira-perf analyze CAPTURE.csv --refresh-hz HZ\nCSV: timestamp_ns (monotonic nanoseconds, one per rendered frame).\nResults describe the capture clock; submission timestamps are not proof of presentation.");
        return Ok(());
    }
    if args.len() != 4 || args[0] != "analyze" || args[2] != "--refresh-hz" {
        return Err("usage: hanabira-perf analyze CAPTURE.csv --refresh-hz HZ".into());
    }
    let hz: f64 = args[3].parse().map_err(|_| "invalid refresh rate")?;
    let input = fs::read_to_string(&args[1]).map_err(|e| e.to_string())?;
    let mut stamps = Vec::new();
    for (n, line) in input.lines().enumerate() {
        let value = line.trim();
        if value.is_empty() || value.starts_with('#') || value == "timestamp_ns" {
            continue;
        }
        stamps.push(
            value
                .parse::<u64>()
                .map_err(|_| format!("invalid timestamp on line {}", n + 1))?,
        );
    }
    let s = analyze_frames(&stamps, hz).map_err(String::from)?;
    println!("{{\"intervals\":{},\"refresh_hz\":{},\"frame_budget_ms\":{:.4},\"mean_ms\":{:.4},\"p95_ms\":{:.4},\"p99_ms\":{:.4},\"max_ms\":{:.4},\"average_fps\":{:.3},\"estimated_missed_refreshes\":{}}}",
        s.intervals, s.refresh_hz, 1000.0/hz, s.mean_ms, s.p95_ms, s.p99_ms,
        s.max_ms, s.average_fps, s.estimated_missed_refreshes);
    Ok(())
}
fn main() {
    if let Err(error) = run() {
        eprintln!("hanabira-perf: {error}");
        process::exit(2);
    }
}
