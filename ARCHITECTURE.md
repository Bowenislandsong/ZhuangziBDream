# Technical Architecture

## Overview

The M-Series Video Generator is a native macOS application that demonstrates hardware-accelerated video generation using Apple's Metal framework on M-series chips.

## System Architecture

```
┌─────────────────────────────────────────────────┐
│          VideoGeneratorApp (SwiftUI)            │
│                  App Entry Point                │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│            ContentView (SwiftUI)                │
│   - User Interface                              │
│   - Chip Information Display                    │
│   - Video Generation Controls                   │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         MetalVideoGenerator (Engine)            │
│   - Metal Device Management                     │
│   - Frame Generation                            │
│   - Video Encoding                              │
└──────────────────┬──────────────────────────────┘
                   │
        ┌──────────┴──────────┬──────────────┐
        ▼                     ▼              ▼
┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│    Metal     │    │ AVFoundation │  │ Core Video   │
│   GPU API    │    │Video Encoding│  │Pixel Buffers │
└──────────────┘    └──────────────┘  └──────────────┘
        │                     │              │
        └──────────┬──────────┴──────────────┘
                   ▼
        ┌────────────────────────┐
        │   M-Series Hardware    │
        │  - GPU Acceleration    │
        │  - Neural Engine       │
        │  - Unified Memory      │
        └────────────────────────┘
```

## Component Details

### 1. VideoGeneratorApp.swift
- **Purpose**: Application entry point
- **Framework**: SwiftUI
- **Responsibilities**:
  - App lifecycle management
  - Window scene configuration

### 2. ContentView.swift
- **Purpose**: Main user interface
- **Framework**: SwiftUI
- **Key Features**:
  - Displays chip information (M1/M2/M3 detection)
  - Video generation button with progress indicator
  - Status messages and alerts
  - Async/await integration for video generation

### 3. MetalVideoGenerator.swift
- **Purpose**: Core video generation engine
- **Frameworks**: Metal, AVFoundation, CoreVideo, CoreImage
- **Key Components**:

#### ChipInfo Structure
```swift
struct ChipInfo {
    let deviceName: String    // e.g., "Apple M1"
    let gpuFamily: String     // GPU family detection
    let metalSupport: Bool    // Metal availability
}
```

#### Metal Pipeline
1. **Device Initialization**
   - Creates MTLDevice (GPU interface)
   - Establishes command queue
   - Detects GPU family (Apple 7/8 for M1/M2/M3)

2. **Frame Generation**
   - Creates Metal textures (BGRA8 format)
   - Generates procedural content
   - Uses GPU for parallel processing

3. **Video Encoding**
   - AVAssetWriter for H.264 encoding
   - CVPixelBuffer management
   - Frame timing via CMTime

## Performance Optimizations

### Metal Acceleration
- **Unified Memory Architecture**: Direct GPU memory access on M-series
- **Texture Operations**: Hardware-accelerated pixel manipulation
- **Command Buffers**: Batched GPU operations

### Memory Management
- **Pixel Buffer Pooling**: Reuses buffers to reduce allocations
- **Metal Textures**: GPU-native memory layout
- **Async Operations**: Non-blocking UI during video generation

### Video Encoding
- **H.264 Codec**: Hardware-accelerated video encoding
- **Bitrate**: 6 Mbps for quality/size balance
- **Frame Rate**: 30 FPS for smooth playback

## Data Flow

```
User Action → ContentView → MetalVideoGenerator
                                    │
                                    ▼
                          Metal Device Init
                                    │
                                    ▼
                          Create Video Writer
                                    │
                                    ▼
                          ┌─────────────────┐
                          │ Frame Generation │
                          │   (Loop)         │
                          └─────────────────┘
                                    │
                            ┌───────┴───────┐
                            ▼               ▼
                    Generate Pixels    Metal Texture
                            │               │
                            └───────┬───────┘
                                    ▼
                            Pixel Buffer
                                    │
                                    ▼
                            AVAssetWriter
                                    │
                                    ▼
                            MP4 File Output
```

## GPU Family Detection

The application detects M-series chips through Metal GPU families:

| Chip Series | GPU Family | Metal Feature Set |
|-------------|------------|-------------------|
| M1 Series   | Apple 7    | Full Metal 3      |
| M2/M3 Series| Apple 8    | Full Metal 3      |
| A-Series    | Apple 6    | Metal 2/3         |

## Extension Points

### Custom Video Content
Modify `generateFrame()` in MetalVideoGenerator.swift to:
- Use Metal compute shaders for complex effects
- Integrate Core ML models
- Process external image sequences
- Generate parametric animations

### Advanced Features
Potential enhancements:
- Metal Performance Shaders (MPS) integration
- Neural Engine acceleration via Core ML
- Real-time preview during generation
- Custom codec support
- Multi-track audio/video

## File Output

**Location**: `~/Documents/metal_generated_video_[timestamp].mp4`

**Format Specification**:
- Container: MP4
- Video Codec: H.264 (AVC)
- Resolution: 1920x1080 (Full HD)
- Frame Rate: 30 FPS
- Pixel Format: BGRA8
- Color Space: sRGB
- Bitrate: 6 Mbps

## Security & Sandboxing

The application uses macOS sandboxing with entitlements:
- `com.apple.security.app-sandbox`: Enabled
- `com.apple.security.files.user-selected.read-write`: File access

This ensures secure file operations while maintaining system security.

## Dependencies

- **System Frameworks** (included with macOS):
  - SwiftUI
  - Metal
  - AVFoundation
  - CoreVideo
  - CoreImage
  - Foundation

- **No external dependencies required**

## Build Requirements

- Xcode 15.0+
- Swift 5.0+
- macOS SDK 13.0+
- Apple Silicon Mac for runtime

## Testing Considerations

While the current implementation focuses on core functionality, potential test areas include:

1. **Unit Tests**:
   - Chip detection logic
   - Video parameter validation
   - Error handling

2. **Integration Tests**:
   - Metal device initialization
   - Video writer setup
   - File output verification

3. **Performance Tests**:
   - Frame generation speed
   - Memory usage
   - GPU utilization

Note: Test infrastructure is not included in the minimal implementation but can be added using XCTest framework.
