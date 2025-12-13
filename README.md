# ZhuangziBDream - M-Series Video Generator

A native macOS application that leverages Apple M-series chipset (M1, M2, M3) to generate high-quality video content using Metal GPU acceleration.

## Features

- **Native Apple Silicon Support**: Optimized for M-series chips (M1, M2, M3)
- **Metal GPU Acceleration**: Uses Metal framework for hardware-accelerated video generation
- **Focused Prompt Workspace**: Large textbox for describing desired motion and style
- **Real-time Detection**: Automatically detects and displays chip information
- **High-Quality Output**: Generates 1080p videos at 30 FPS

## Requirements

- macOS 13.0 or later
- Apple Silicon Mac (M1, M2, or M3 chip)
- Xcode 15.0 or later

## Building and Running

### Using Xcode

1. Open `VideoGenerator.xcodeproj` in Xcode
2. Select your Mac as the run destination
3. Press `Cmd + R` to build and run

### Using Command Line

```bash
# Build the project
xcodebuild -project VideoGenerator.xcodeproj -scheme VideoGenerator -configuration Release build

# Run the application
open build/Release/VideoGenerator.app
```

## How It Works

The application uses several Apple technologies:

1. **Metal**: Apple's low-level GPU framework for hardware-accelerated graphics and compute
2. **AVFoundation**: For video encoding and writing
3. **Core Video**: For efficient pixel buffer management
4. **SwiftUI**: For the modern, native user interface

### Video Generation Process

1. Initializes Metal device (M-series GPU)
2. Creates Metal textures for frame rendering
3. Generates procedural frames using GPU acceleration
4. Encodes frames using H.264 codec
5. Writes final video to disk in MP4 format

## Architecture

```
VideoGenerator/
├── VideoGeneratorApp.swift      # App entry point and menu commands
├── AppUIState.swift             # Shared UI state for sheets and pickers
├── ContentView.swift            # Main ChatGPT-style workspace
├── ModelManager.swift           # Model enumeration, downloads, persistence
├── MetalVideoGenerator.swift    # Metal-based video generation engine
├── Models/                      # Bundled demo models and README
├── Assets.xcassets/             # App assets and icons
├── Info.plist                   # App configuration
└── VideoGenerator.entitlements  # App permissions
```

## Output

Generated videos default to:
```
~/Downloads/metal_generated_video_[model]_[prompt-fragment]_[timestamp].mp4
```

## Technical Details

- **Video Resolution**: 1920x1080 (Full HD)
- **Frame Rate**: 30 FPS
- **Duration**: 5 seconds
- **Codec**: H.264
- **Pixel Format**: BGRA8
- **Bitrate**: 6 Mbps

## GPU Families Supported

- Apple M1 Series (Apple GPU Family 7)
- Apple M2/M3 Series (Apple GPU Family 8)
- Apple A-Series (Apple GPU Family 6)

## License

MIT License - See LICENSE file for details