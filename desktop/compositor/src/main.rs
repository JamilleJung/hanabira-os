//! Hanabira Desktop Environment compositor.
//!
//! The initial Wayland protocol skeleton and pointer grabs are adapted from
//! Smithay's MIT-licensed Smallvil example (Smithay v0.7.0). See README.md.

mod grabs;
mod handlers;
mod input;
mod state;
mod winit;

use std::{ffi::OsString, fs::File, io::Write, path::PathBuf, process::Command, time::Duration};

use smithay::reexports::{
    calloop::{
        timer::{TimeoutAction, Timer},
        EventLoop,
    },
    wayland_server::{Display, DisplayHandle},
};
pub use state::Hanabira;

pub struct CalloopData {
    state: Hanabira,
    display_handle: DisplayHandle,
}

#[derive(Debug, PartialEq, Eq)]
struct Options {
    help: bool,
    backend: String,
    shell: Option<OsString>,
    command: Option<OsString>,
    frame_log: Option<PathBuf>,
    screenshot: Option<PathBuf>,
}

fn parse_args(args: impl IntoIterator<Item = OsString>) -> Result<Options, String> {
    let mut options = Options {
        help: false,
        backend: "nested".into(),
        shell: None,
        command: None,
        frame_log: None,
        screenshot: None,
    };
    let mut args = args.into_iter();
    while let Some(flag) = args.next() {
        let flag = flag.to_string_lossy();
        match flag.as_ref() {
            "--backend" => {
                let value = args.next().ok_or("--backend needs a value")?;
                options.backend = value.to_string_lossy().into_owned();
            }
            "--shell" => options.shell = Some(args.next().ok_or("--shell needs a path")?),
            "--command" => options.command = Some(args.next().ok_or("--command needs a path")?),
            "--frame-log" => {
                options.frame_log = Some(args.next().ok_or("--frame-log needs a path")?.into())
            }
            "--screenshot" => {
                options.screenshot = Some(args.next().ok_or("--screenshot needs a path")?.into())
            }
            "--help" | "-h" => options.help = true,
            other => return Err(format!("unknown option: {other}")),
        }
    }
    if options.backend != "nested" && options.backend != "drm" {
        return Err(format!("unsupported backend: {}", options.backend));
    }
    Ok(options)
}

fn spawn_client(path: &OsString, socket_name: &OsString) -> Result<(), Box<dyn std::error::Error>> {
    Command::new(path)
        .env("WAYLAND_DISPLAY", socket_name)
        .spawn()?;
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();
    let options = parse_args(std::env::args_os().skip(1))?;
    if options.help {
        println!("usage: hanabira-compositor [--backend nested|drm] [--shell PATH] [--command PATH] [--frame-log PATH] [--screenshot PATH]\nNative DRM/KMS is not yet implemented. The frame log records successful submissions, not presentation timestamps.");
        return Ok(());
    }
    if options.backend == "drm" {
        return Err("native DRM/KMS backend is not implemented; use --backend nested under a Wayland/X11 session".into());
    }

    let mut event_loop: EventLoop<CalloopData> = EventLoop::try_new()?;
    let display: Display<Hanabira> = Display::new()?;
    let display_handle = display.handle();
    let mut state = Hanabira::new(&mut event_loop, display);
    if let Some(path) = options
        .frame_log
        .or_else(|| std::env::var_os("HANABIRA_FRAME_LOG").map(PathBuf::from))
    {
        let mut log = File::create(path)?;
        writeln!(log, "timestamp_ns,kind")?;
        state.frame_log = Some(log);
    }
    if let Some(path) = options.screenshot {
        state.screenshot = Some(path);
        state.screenshot_needs_layer = options.shell.is_some();
        state.screenshot_needs_app = options.command.is_some();
    }
    let mut data = CalloopData {
        state,
        display_handle,
    };
    winit::init_winit(&mut event_loop, &mut data)?;
    if data.state.screenshot.is_some() {
        event_loop.handle().insert_source(
            Timer::from_duration(Duration::from_secs(2)),
            |_, _, data| {
                data.state.screenshot_ready = true;
                data.state.request_redraw();
                TimeoutAction::Drop
            },
        )?;
    }

    eprintln!(
        "Hanabira nested Wayland socket: {}",
        data.state.socket_name.to_string_lossy()
    );
    if let Some(shell) = options.shell.as_ref() {
        spawn_client(shell, &data.state.socket_name)?;
    }
    if let Some(command) = options.command.as_ref() {
        spawn_client(command, &data.state.socket_name)?;
    }

    event_loop.run(None, &mut data, |_| {})?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn parse(values: &[&str]) -> Result<Options, String> {
        parse_args(values.iter().map(OsString::from))
    }

    #[test]
    fn accepts_nested_shell_and_frame_log() {
        let options = parse(&[
            "--backend",
            "nested",
            "--shell",
            "/usr/bin/hanabira-shell",
            "--frame-log",
            "/tmp/frames.csv",
        ])
        .unwrap();
        assert_eq!(options.backend, "nested");
        assert_eq!(
            options.shell.as_deref(),
            Some(std::ffi::OsStr::new("/usr/bin/hanabira-shell"))
        );
        assert_eq!(options.frame_log, Some(PathBuf::from("/tmp/frames.csv")));
    }

    #[test]
    fn rejects_unrecognized_backend() {
        assert!(parse(&["--backend", "kms"]).is_err());
    }
}
