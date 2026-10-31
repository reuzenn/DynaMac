# DynaMac

DynaMac is a native macOS utility that transforms the MacBook camera notch and menu bar into an interactive, context-aware Dynamic Island. It surfaces live system telemetry, media controls, quick file staging, and productivity tools directly from the display bezel.

## Overview

Designed specifically for Apple Silicon MacBooks featuring hardware display cutouts, DynaMac anchors seamlessly against the physical notch. For non-notched external monitors or older Mac hardware, it provides a floating capsule mode with identical capabilities and physics-based fluid animations.

## Core Capabilities

### Display Geometry and Notch Integration
* Hardware Boundary Detection: Queries display auxiliary areas to calculate exact physical notch dimensions and position on MacBook Pro (14-inch and 16-inch) and MacBook Air (13-inch and 15-inch) displays.
* Distributed Ear Navigation: When expanded, controls and navigation pills are distributed symmetrically to the left and right of the physical camera housing, preventing hardware occlusion.
* Floating Capsule Fallback: Automatically shifts to a centered pill on non-notched displays or secondary monitors.

### Media Remote Subsystem
* Control Center Integration: Interfaces with macOS MediaRemote framework to capture system-wide playback metadata across Apple Music, Spotify, Safari, and other media players.
* Real-Time Wall-Clock Interpolation: Reconstructs continuous elapsed playback time from baseline timestamps and playback rates, ensuring progress bars advance smoothly without polling lag.
* Sound Spectrum Visualization: Reactive multi-band audio spectrum indicator that automatically pauses and settles when playback stops.
* Safari YouTube Fallback: Direct tab inspection to retrieve title, channel, artwork thumbnail, playback state, and duration when native MediaRemote events are unavailable.

### Drop Shelf
* Drag-and-Drop Staging: Provides a temporary holding space for files dragged from Finder, browsers, or other applications.
* Quick Look and Action Integration: Preview staged items, open files in default applications, or clear batches with a single click.

### Focus Timer
* Configurable Focus Intervals: Pomodoro-style interval timer designed for uninterrupted work blocks.
* Background State Persistence: Maintains countdown tracking across space changes and display sleep cycles.

### Battery and Power Telemetry
* Real-Time Power Source Monitoring: Tracks battery percentage, charging state, time remaining, and power source transitions via IOKit.
* Compact Notch Indicators: Minimalist battery and power indicators visible within the compact notch ears during charging or low-battery thresholds.

### Gesture and Physics Engine
* Two-Finger Trackpad Navigation: Custom horizontal scroll gesture recognition featuring accumulated delta thresholds and momentum rejection to prevent accidental tab switching.
* Critically Damped Spring Animations: Fluid expand and collapse transitions built with Apple-standard spring damping and response curves.
* Direct Interaction Bounds: Precision hit-testing ensures background windows and menu bar items remain fully clickable outside the active Dynamic Island shape.

## System Requirements

* Operating System: macOS 14.0 (Sonoma) or later
* Architecture: Universal binary (Apple Silicon and Intel x86_64)
* Recommended Hardware: MacBook Pro (2021 or later) or MacBook Air (2022 or later) with built-in display notch

## Installation and Build Instructions

### Building via Xcode
1. Clone the repository:
   ```bash
   git clone https://github.com/reuzenn/DynaMac.git
   cd DynaMac
   ```
2. Open `DynaMac.xcodeproj` in Xcode 16 or later.
3. Select the `DynaMac` scheme with target `My Mac`.
4. Press `Cmd + B` to build or `Cmd + R` to run.

### Building via Terminal
An automated build script is provided to compile, sign, package, and install DynaMac directly into the `/Applications` directory:
```bash
chmod +x build.sh
./build.sh
```

Upon execution, the script performs the following operations:
* Compiles the release target using `xcodebuild`.
* Packages the standalone `DynaMac.app` application bundle.
* Embeds the application icon (`AppIcon.icns`) and configures bundle metadata.
* Applies an ad-hoc code signature.
* Installs the bundle to `/Applications/DynaMac.app` and refreshes macOS LaunchServices.

## Application Architecture

```text
DynaMac/
|-- App/
|   \-- AppDelegate.swift               # Application lifecycle and accessory mode initialization
|-- Models/
|   |-- MediaTrack.swift                # Playback data structures
|   |-- NotchConfig.swift               # Hardware geometry definitions and presets
|   |-- NotchState.swift                # Presentation and tab enumeration states
|   \-- NotchViewModel.swift            # Central state coordination and gesture handling
|-- Services/
|   |-- AudioService.swift              # CoreAudio volume observation
|   |-- BatteryService.swift            # IOKit power source telemetry
|   |-- HapticService.swift             # NSHapticFeedbackManager integration
|   |-- LocalizationManager.swift       # Multi-language string catalogs
|   |-- MediaService.swift              # MediaRemote bridge and player coordination
|   |-- NotchManager.swift              # Screen parameter observation and notch detection
|   |-- ShelfService.swift              # Drag-and-drop file staging management
|   \-- TimerService.swift              # High-resolution focus countdown timer
\-- Views/
    |-- Cards/                          # Expanded tab content cards (Media, Shelf, Timer, Battery)
    |-- FluidComponents.swift           # Button styles and visual modifiers
    |-- HUDView.swift                   # System volume and brightness overlay heads-up display
    |-- IslandLayout.swift              # Dimension rules and spring animation parameters
    |-- NotchContainerView.swift        # Primary Dynamic Island view hierarchy
    |-- NotchPanel.swift                # Non-activating transparent overlay window
    |-- NotchShape.swift                # Custom Bezier shape for bezel-aligned capsule
    |-- NotchWindowController.swift     # Window positioning, mouse tracking, and hit-testing
    |-- SettingsView.swift              # User configuration and calibration panel
    \-- StatusBarController.swift       # Menu bar icon and quick access menu
```

## Privacy and Permissions

DynaMac operates locally without network requirements or external telemetry. To provide system integration, it requests standard macOS permissions:
* Apple Events / Automation: Required to query playback status and dispatch media control events to Safari, Spotify, and Apple Music.
* Accessibility (Optional): Required for automatic window drag detection.

Developed by reuzen.