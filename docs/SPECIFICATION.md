# HANABIRA OS — COMPLETE CUSTOM ANIME OPERATING SYSTEM

## ROLE & MISSION

You are the Principal Operating System Architect, Senior Linux Distribution Engineer, Wayland Compositor Developer, Graphics Performance Engineer, UI/UX Design Director, and Release Engineer responsible for building **Hanabira OS (花びら OS)**.

Your mission is to transform the existing Hanabira OS GitHub repository into a fully functional, visually extraordinary, production-oriented Linux desktop operating system.

**Base Distribution:** Debian GNU/Linux Stable  
**Desktop Identity:** 100% custom Hanabira desktop experience  
**Design Language:** Premium Japanese Anime × Futuristic Glass × Sakura × Modern Desktop  
**Performance Goal:** Ultra-smooth hardware-accelerated rendering, targeting 240Hz / 240 FPS animations on capable hardware  
**Distribution:** Bootable, installable Debian-based ISO  
**Project Philosophy:** Beautiful by default. Fast by architecture. Reliable by design.

THIS IS NOT A THEME PROJECT.

DO NOT simply install KDE Plasma, GNOME, XFCE, Cinnamon, or Hyprland and apply an anime wallpaper.

We are creating a distinctive desktop operating system with its own compositor, desktop shell, interaction system, visual identity, installer experience, and integrated applications.

You may reuse established Linux infrastructure, protocols, drivers, toolkits, and system components. Custom 100% refers to the complete user-facing desktop experience and product identity, not reinventing the Linux kernel or every supporting service.

---

# 1. FIRST: AUDIT THE EXISTING REPOSITORY

This is an existing project, not a greenfield assignment.

Before changing anything:

1. Inspect the entire repository.
2. Read the README, documentation, manifests, scripts, CI workflows, build configuration, ISO generation scripts, and desktop implementation.
3. Identify which components are currently functional.
4. Identify placeholders, incomplete implementations, broken packages, and temporary workarounds.
5. Inspect the existing Git history and project structure.
6. Determine the current Debian base and ISO build pipeline.
7. Preserve completed work wherever technically appropriate.
8. Establish the actual baseline by running available tests and builds.
9. Create a concrete gap analysis against the requirements below.
10. Then immediately begin implementation.

Do not recreate the repository or discard previous progress.

Maintain the existing Hanabira OS identity.

If authenticated Git access exists, commit completed milestones and push safely to the existing repository without force-pushing or overwriting unrelated work.

Do not stop after writing an implementation plan.

**YOU MUST IMPLEMENT THE SYSTEM.**

---

# 2. DEBIAN FOUNDATION

Use official Debian Stable repositories as the primary operating system foundation.

Requirements:

- Debian-compatible kernel and userspace.
- Systemd initialization and service management.
- APT package management.
- Reproducible ISO builds using Debian live-build or an equivalent well-maintained Debian-native pipeline.
- Native system packages for Hanabira components.
- Reliable boot on modern UEFI systems.
- Legacy BIOS support where feasible and validated.
- Proper firmware inclusion and licensing.
- Intel, AMD, and NVIDIA graphics support.
- Intel and AMD hybrid graphics compatibility.
- Modern Wi-Fi, Bluetooth, audio, touchpad, and laptop hardware.
- PipeWire and WirePlumber.
- NetworkManager.
- BlueZ.
- UPower and appropriate power-profile integration.
- systemd-logind.
- Polkit authentication.
- XDG Desktop Portal integration.
- Flatpak compatibility.
- XWayland support for legacy applications.

Provide sensible defaults without forcing users to perform manual Linux configuration after installation.

Never silently replace stable Debian components with incompatible experimental packages.

Use carefully documented backports when newer drivers or firmware are required.

---

# 3. BUILD OUR OWN DESKTOP ENVIRONMENT

Create the custom desktop environment:

**Hanabira Desktop Environment (HDE)**

Its major components should include:

- `hanabira-compositor`
- `hanabira-shell`
- `hanabira-panel`
- `hanabira-dock`
- `hanabira-launcher`
- `hanabira-control-center`
- `hanabira-lockscreen`
- `hanabira-greeter`
- `hanabira-notifications`
- `hanabira-wallpaper-engine`
- `hanabira-theme-engine`
- `hanabira-session`
- `hanabira-installer`
- `hanabira-first-run`

Keep component boundaries maintainable and avoid unnecessary fragmentation into dozens of background processes.

## Compositor Architecture

Preferred implementation:

**Rust + Smithay + Wayland + DRM/KMS + hardware-accelerated rendering**

Evaluate existing code before committing to the final compositor architecture.

The final desktop must not depend on KDE KWin, GNOME Mutter, or an off-the-shelf compositor as its permanent desktop identity.

Smithay, Mesa, DRM/KMS, GBM, EGL, Vulkan, and other lower-level infrastructure may be used.

Implement or integrate the necessary Wayland protocols to support real desktop applications and workflows.

Important capabilities:

- Modern Wayland window management.
- Hardware-accelerated composition.
- Window move, resize, maximize, minimize, and fullscreen.
- Multiple workspaces.
- Multi-monitor management.
- Independent monitor refresh rates.
- Fractional scaling.
- High-DPI displays.
- Touchpad gestures.
- Clipboard and drag-and-drop.
- Keyboard input methods and international layouts.
- Screen capture through appropriate portal integration.
- Screen sharing.
- XWayland compatibility.
- Session locking.
- Focus management.
- Accessibility foundations.
- Robust GPU resource management.

Support both tiled and floating window behavior where useful, but prioritize a polished, intuitive desktop experience rather than complex configuration.

Do not sacrifice compositor correctness or application compatibility for visual effects.

---

# 4. THE VISUAL IDENTITY MUST BE EXTRAORDINARY

Create a distinctive design system named:

**Hanabira Design Language — Sakura Motion**

The visual identity must immediately communicate that Hanabira OS is an anime-inspired operating system.

It must NOT resemble a generic Windows, macOS, or GNOME theme clone.

## Artistic Direction

Combine:

- High-quality Japanese anime aesthetics.
- Sakura petals and atmospheric Japanese scenery.
- Futuristic technology interfaces.
- Elegant glass surfaces.
- Cinematic lighting.
- Subtle neon accents.
- Soft gradients.
- Carefully controlled translucency.
- Atmospheric depth.
- Premium typography.
- Fluid motion.
- Beautiful iconography.
- Cohesive original illustrations.

The result should feel like an actual operating system from a premium Japanese science-fiction anime.

**Anime aesthetic must be present throughout the operating system, not just in the wallpaper.**

Create three complete themes:

### Sakura Dream

Soft pink, cherry blossoms, ivory, lavender, and warm atmospheric lighting.

### Midnight Hanabira

Deep navy, violet, dark translucent surfaces, neon pink highlights, and cyber-anime atmosphere.

### Celestial Blue

Cool blue, moonlight, subtle cyan highlights, and futuristic glass aesthetics.

All three themes must share consistent component geometry, typography, spacing, and animation behavior.

Use original or properly licensed artwork and assets only.

Do not use copyrighted anime characters, backgrounds, logos, or illustrations without permission.

If image generation is unavailable, create polished original vector or procedural artwork rather than inserting broken image paths or pretending unfinished placeholders are final assets.

---

# 5. COMPLETE CUSTOM DESKTOP UI

Design and implement the following features.

## Desktop Canvas

- Full-screen anime wallpaper engine.
- Static and animated wallpapers.
- Subtle animated sakura petals.
- Parallax effects where appropriate.
- Dynamic lighting.
- Desktop context menu.
- Desktop icons and shortcuts.
- Workspace transitions.
- Optional visual widgets.
- Automatic effect reduction on battery or constrained hardware.

## Hanabira Dock

Build an original, GPU-friendly application dock.

Features:

- Beautiful custom icons.
- App launching.
- Running application indicators.
- Pinned applications.
- Drag-and-drop reordering.
- Smooth hover animation.
- Intelligent magnification.
- Minimize and restore animations.
- Notification badges.
- Auto-hide.
- Intelligent hide.
- Adjustable location and sizing.

Animation must remain fluid at high refresh rates.

## Hanabira Launcher

Create a visually stunning application launcher.

Features:

- Instant keyboard activation.
- Fuzzy application search.
- Recently used applications.
- Favorite applications.
- Application categories.
- Search shortcuts.
- Keyboard navigation.
- Smooth open/close transitions.
- Anime-inspired background lighting and glass effects.

Prioritize very low input-to-result latency.

## Hanabira Panel

A fully custom desktop panel featuring:

- Workspaces.
- Application menu.
- Active application information.
- System status indicators.
- Network.
- Bluetooth.
- Battery.
- Audio.
- Date and time.
- Notifications.
- Quick settings.
- Session controls.

Use refined sizing and spacing. Avoid unnecessarily oversized UI.

## Quick Settings

Create a premium floating control center.

Include:

- Wi-Fi.
- Bluetooth.
- Volume.
- Brightness.
- Night light.
- Power mode.
- Display refresh rate.
- Dark/light mode.
- Wallpaper selector.
- Keyboard layout.
- Do Not Disturb.
- Screenshot and screen recording controls.

## Notification Center

- Beautiful notification cards.
- Smooth transitions.
- Grouped notifications.
- Inline actions.
- Notification history.
- Media controls.
- Do Not Disturb.
- Proper freedesktop notification compatibility.

## Lock Screen and Login

Create custom Hanabira-branded login and lock-screen experiences.

Include:

- Cinematic original artwork.
- Large elegant clock.
- Date display.
- User avatar.
- Password entry.
- Authentication errors.
- Session selection.
- Power controls.
- Blur and transition effects.
- Proper PAM integration.
- Secure screen locking.

The lock screen must be secure and must not merely be a fullscreen decorative application.

---

# 6. TARGET 240HZ / ULTRA-SMOOTH ANIMATION

Performance is a first-class architectural requirement.

**Target 240 FPS shell animation on compatible hardware with a verified 240Hz display mode.**

At 240Hz, the display frame budget is approximately 4.17 milliseconds.

Use this as a measurable engineering target, not an unconditional performance guarantee.

Support:

- 60Hz.
- 90Hz.
- 120Hz.
- 144Hz.
- 165Hz.
- 180Hz.
- 240Hz.
- Higher refresh rates when hardware and drivers permit.

## Rendering Rules

1. Prefer GPU rendering.
2. Synchronize frame presentation correctly.
3. Do not use software rendering for the normal desktop composition path.
4. Avoid unnecessary texture uploads.
5. Implement damage tracking and partial redraws where supported.
6. Avoid busy-loop rendering when the desktop is idle.
7. Cache expensive static layers.
8. Control blur and transparency costs.
9. Avoid expensive synchronous work on the presentation path.
10. Keep animation timing independent from fixed 60 FPS assumptions.
11. Handle mixed-refresh multi-monitor setups.
12. Avoid excessive redraws during cursor movement.
13. Implement appropriate frame scheduling.
14. Minimize compositor-induced input latency.
15. Measure CPU, GPU, memory, and frame-pacing behavior.

## Animation Quality

Build an original motion system supporting:

- Spring animation.
- Smooth easing.
- Physics-inspired window movement.
- Window opening and closing.
- Dock interactions.
- Workspace transitions.
- Application launcher transitions.
- Panel expansion.
- Notification entrance and dismissal.
- Wallpaper transitions.
- Lock-screen transitions.
- Hover and press feedback.

Animations must feel fluid and responsive, not slow or exaggerated.

Avoid animation stacking and excessive motion.

Expose motion intensity settings:

- Cinematic.
- Balanced.
- Minimal.
- Reduced Motion.

Support accessibility preferences for reduced motion.

## Performance Acceptance

Create benchmarks and telemetry for:

- Average rendered FPS.
- Frame-time distribution.
- P95 frame time.
- P99 frame time.
- Dropped frames.
- Input-to-presentation latency where measurable.
- CPU utilization.
- GPU utilization.
- Memory usage.
- Idle power consumption.
- Animation frame pacing.
- Multi-monitor performance.

Provide actual measured data whenever hardware supports measurement.

Never claim 240 FPS without measurements.

If current hardware cannot run at 240Hz, report the limitation and benchmark at the maximum supported refresh rate.

---

# 7. ANIME WALLPAPER ENGINE

Create `hanabira-wallpaper-engine`.

Features:

- High-resolution static wallpapers.
- GPU-accelerated animated wallpapers.
- Sakura particle effects.
- Animated atmospheric lighting.
- Day/night backgrounds.
- Subtle depth movement.
- Multi-monitor support.
- Ultra-wide layouts.
- 4K compatibility.
- Battery-aware rendering.
- Pause animated effects when unnecessary.
- User wallpaper import.

Provide a curated collection of original Hanabira wallpapers.

Wallpaper effects must never cause sustained unnecessary CPU or GPU load when the desktop is idle.

---

# 8. COMPLETE SYSTEM SETTINGS

Create a fully custom **Hanabira Control Center**.

Do not expose a mostly unmodified GNOME or KDE settings application as the primary experience.

Design a clean, consistent application with beautiful sidebar navigation, subtle animation, and meaningful responsive layouts.

Sections:

1. Appearance and Themes.
2. Wallpapers and Visual Effects.
3. Display and Refresh Rate.
4. Sound and Microphone.
5. Network and Wi-Fi.
6. Bluetooth.
7. Keyboard and Input Methods.
8. Mouse and Touchpad.
9. Gestures.
10. Power and Battery.
11. Storage.
12. Applications and Default Apps.
13. Notifications.
14. Privacy and Permissions.
15. Users and Authentication.
16. Date, Time, and Region.
17. Language and Localization.
18. System Updates.
19. Hardware Information.
20. About Hanabira OS.

Every interactive setting must connect to a real system capability.

Do not create decorative toggles that do nothing.

Use appropriate system APIs, D-Bus interfaces, and privilege boundaries.

---

# 9. FULLY CUSTOM GRAPHICAL INSTALLER

This is one of the most important requirements.

**The installation experience must be as visually impressive as the desktop itself.**

Create a Hanabira-branded graphical installer.

Calamares may be reused as a proven installation backend, but the complete visual experience must be custom-designed.

## Installer Design

- Edge-to-edge premium layout.
- Original anime background artwork.
- Frosted glass panels.
- Beautiful progress indicators.
- Sakura-inspired animation.
- Consistent Hanabira typography.
- Clear, modern navigation.
- Attractive selection controls.
- Well-designed validation and error states.
- Smooth transitions.
- Responsive layouts.
- High-DPI compatibility.

The installer should feel like entering the world of Hanabira OS.

## Installer Flow

Implement:

1. Beautiful welcome screen.
2. Language selection.
3. Region and timezone selection.
4. Keyboard layout selection.
5. Network status and connectivity.
6. Installation destination.
7. Disk partitioning.
8. User account creation.
9. Computer name.
10. Installation summary.
11. Installation progress.
12. Successful installation.
13. Restart and first boot.

Support automatic disk installation and safe manual partitioning.

Include EFI System Partition handling, appropriate filesystem choices, swap configuration, and optional disk encryption where supported by the installer backend.

Clearly communicate destructive operations before modifying storage.

Never erase or repartition the development machine while testing the installer.

---

# 10. BEAUTIFUL FIRST-BOOT EXPERIENCE

After installation, launch **Hanabira Welcome**.

This is a separate, polished onboarding experience.

Provide:

- Welcome to Hanabira OS.
- Theme selection.
- Wallpaper selection.
- Display scaling.
- Refresh rate selection.
- Keyboard configuration.
- Touchpad gesture introduction.
- Privacy preferences.
- Update check.
- Application recommendations.
- Finish and enter desktop.

Make the experience visually coherent with the installer and desktop.

Do not force users through unnecessary configuration steps.

---

# 11. HARDWARE AND NVIDIA SUPPORT

Pay special attention to modern gaming and development laptops.

Target representative hardware including:

**ASUS ROG Zephyrus G16 with NVIDIA GeForce RTX 5080 Laptop GPU and hybrid graphics.**

Requirements:

- Reliable Wayland startup.
- Intel/AMD integrated GPU support where applicable.
- NVIDIA proprietary driver support when required.
- Modern NVIDIA DRM/KMS integration.
- Correct synchronization support.
- PRIME render offload.
- External display compatibility.
- High refresh rate support.
- Laptop brightness control.
- Touchpad gestures.
- Keyboard backlighting where supported.
- Suspend and resume.
- Hybrid graphics switching where safely supported.
- Battery-aware power management.
- Thermal behavior.
- Proper device detection.

Avoid hardcoding a single GPU layout.

Provide a working fallback session or rescue path when accelerated startup fails.

Investigate VMD/RST storage visibility issues and provide clear diagnostics rather than making unsafe BIOS changes automatically.

Secure Boot compatibility must be handled honestly; document signing or enrollment requirements where needed.

Do not assume NVIDIA hardware is available in the current build environment.

---

# 12. LOCALIZATION AND TYPOGRAPHY

Default language: English.

Provide first-class Thai language support.

Requirements:

- Complete Unicode support.
- Excellent Thai font rendering.
- Thai and English keyboard layouts.
- Keyboard layout switching.
- Appropriate font fallback.
- Correct text shaping.
- Consistent text sizes.
- High-DPI typography.
- Accessible contrast.
- Localization-ready application strings.

Use properly licensed fonts that can legally ship with the ISO.

Typography is an essential part of the visual identity.

---

# 13. DESIGN SYSTEM IMPLEMENTATION

Establish reusable design tokens for:

- Colors.
- Surface opacity.
- Blur radius.
- Corner radius.
- Typography.
- Font weight.
- Spacing.
- Shadows.
- Borders.
- Icon sizes.
- Animation duration.
- Animation curves.
- Focus indicators.
- Layout breakpoints.

Avoid inconsistent visual styling between applications.

All Hanabira interfaces should look as if they were designed by one unified product team.

Build reusable UI components rather than duplicating styling code across applications.

Maintain consistent compact-to-medium control sizing.

Do not use web-style oversized padding throughout native desktop applications.

Keep contrast and usability strong even when using translucent surfaces.

---

# 14. PERFORMANCE ENGINEERING

Prioritize Rust for system-facing custom components when appropriate.

Use memory-safe APIs and explicit error handling.

Avoid Electron for core desktop shell components.

Keep background processes lightweight.

Do not introduce unnecessary network requests, telemetry, or persistent daemons.

Measure startup time and optimize the critical path from boot to usable desktop.

Use:

- Asynchronous I/O where appropriate.
- Efficient GPU texture management.
- Bounded caches.
- Event-driven processing.
- Proper resource cleanup.
- Graceful error recovery.
- Minimal privilege requirements.

Performance must be verified through profiling, not assumed from implementation language.

Create a documented performance test suite.

---

# 15. SECURITY AND RELIABILITY

Preserve Debian's security model.

Requirements:

- Correct Unix permissions.
- Minimal privileged services.
- Secure PAM authentication.
- Proper Polkit integration.
- Safe IPC boundaries.
- No hardcoded secrets.
- Signed repository/package verification.
- Reliable APT updates.
- Secure session locking.
- No unnecessary root execution.
- Safe installation error handling.
- Reproducible builds.
- Crash logs and diagnostic tooling.

Desktop crashes must not silently corrupt configuration or require complete system reinstallation.

Introduce fallback behavior for critical shell components.

---

# 16. BUILD AND PACKAGE THE OPERATING SYSTEM

Create a real Debian-based installation ISO.

Deliver:

- Working live environment.
- Custom Hanabira desktop session.
- Beautiful graphical installer.
- Functional login experience.
- Preinstalled default applications.
- Correct driver and firmware integration.
- APT configuration.
- Hanabira packages.
- Build scripts.
- Boot configuration.
- ISO checksum.
- Build documentation.

The installation image should boot on appropriate physical systems and in supported virtualization environments.

Make ISO generation reproducible in CI where practical.

Provide a single documented build entry point, such as:

`./scripts/build-iso.sh`

The command must be implemented and functional, not merely mentioned in documentation.

---

# 17. VALIDATION AND SCREENSHOT QA

Do not treat compilation success as proof that the OS works.

Test the actual user journey:

- ISO boots.
- Live desktop starts.
- Login works.
- Window management works.
- Applications launch.
- Wallpaper renders.
- Dock works.
- Launcher works.
- Settings apply correctly.
- Notifications appear.
- Keyboard and mouse input works.
- Display settings function.
- Installer completes in a disposable test disk or VM.
- Installed system boots.
- First-run wizard works.
- System updates function.

Use QEMU/KVM or other available virtualization tools for safe smoke tests.

Include screenshots of major UI screens whenever capture is possible.

Inspect screenshots for:

- Broken spacing.
- Overlapping elements.
- Incorrect scaling.
- Unreadable text.
- Inconsistent component geometry.
- Broken backgrounds.
- Missing assets.
- Poor contrast.
- Incomplete dialogs.
- Incorrect focus states.

Repair identified defects before considering the milestone complete.

Where GPU passthrough or physical displays are unavailable, document hardware validation as pending instead of inventing results.

---

# 18. DEVELOPMENT STRATEGY

Implement in sequential working milestones.

## Phase 1 — Foundation

Audit repository, repair existing builds, establish Debian packaging, create project architecture, and verify ISO generation.

## Phase 2 — Functional Desktop

Implement a bootable custom Hanabira session with functional window management, application launching, input, display output, and essential compatibility.

## Phase 3 — Anime Visual System

Implement the complete visual language, wallpaper engine, dock, panel, launcher, animation system, themes, and original assets.

## Phase 4 — Desktop Integration

Complete settings, notifications, system controls, authentication UI, portals, localization, and hardware integration.

## Phase 5 — Premium Installer

Create the fully branded installation experience, disk installation workflow, and first-run setup.

## Phase 6 — Performance Optimization

Profile compositor and shell performance, optimize frame pacing, test refresh rates, minimize power consumption, and remove animation stutters.

## Phase 7 — ISO and Release QA

Build the final ISO, perform installation testing, validate applications and services, fix regressions, and document known hardware limitations.

Each phase must produce verifiable working deliverables.

Do not replace implementation with mockups, screenshots, or static HTML demonstrations.

If a subsystem is too large to finish in one iteration, deliver the smallest genuinely functional vertical slice and continue expanding it.

Keep a clear record of incomplete requirements.

---

# 19. ABSOLUTE DESIGN QUALITY RULES

The following are unacceptable as final deliverables:

- Default GNOME desktop with anime wallpaper.
- Default KDE desktop with pink colors.
- Unmodified installer UI.
- Generic Linux login screen.
- Placeholder buttons.
- Fake application settings.
- Nonfunctional desktop widgets.
- Static desktop mockups masquerading as a real OS.
- Excessive blur that destroys readability.
- Excessive animation that increases input latency.
- Inconsistent icons.
- Low-resolution artwork.
- Broken high-DPI scaling.
- Forced 60 FPS animation timing.
- Unmeasured claims of 240 FPS performance.
- An ISO that only works in the original development environment.

Make design quality, reliability, and performance equally important.

---

# 20. EXECUTION RULES

You have permission to make architectural decisions and implement necessary changes within the project workspace.

Do not repeatedly ask for approval over minor implementation decisions.

Proceed autonomously wherever safe.

However:

- Never wipe the host machine.
- Never modify real partitions during testing.
- Never delete the existing Git repository.
- Never expose secrets.
- Never force-push.
- Never fabricate test results.
- Never claim an unfinished subsystem is production-ready.
- Never mark work completed merely because files exist.

After each milestone:

1. Summarize what was implemented.
2. Run relevant tests.
3. Fix discovered errors.
4. Record actual test results.
5. Update documentation.
6. Commit the working changes when appropriate.
7. Continue to the next milestone.

Do not end the assignment after only providing a roadmap or design proposal.

---

# FINAL PRODUCT VISION

Hanabira OS must feel like an entirely new operating system.

When the user boots the ISO, they should immediately see a breathtaking, original anime-inspired environment.

The installer should look exceptional.

The desktop should feel cohesive and alive.

The dock should animate fluidly.

The launcher should respond instantly.

Window movement and transitions should take advantage of high-refresh-rate displays.

The operating system should remain responsive during ordinary multitasking.

Every element should reflect a unified design language.

The visual experience must be distinctive enough that users recognize Hanabira OS immediately, without needing to see its logo.

**We are not building a Debian theme.**

**We are building Hanabira OS: a beautiful, custom Debian-based anime desktop operating system.**

Begin now.

First inspect the existing repository and current ISO implementation, report the verified baseline briefly, then start implementing the highest-priority missing components. Continue through the milestones without stopping at planning.