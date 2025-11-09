# Build Instructions

## Prerequisites

- macOS 13.0 or later
- Xcode 15.0 or later
- Apple Silicon Mac (M1, M2, or M3 chip)

## Building the Application

### Method 1: Using Xcode (Recommended)

1. Open the project:
   ```bash
   open VideoGenerator.xcodeproj
   ```

2. In Xcode:
   - Select your Mac as the run destination (Product → Destination → My Mac)
   - Build the project: `Cmd + B`
   - Run the application: `Cmd + R`

### Method 2: Command Line Build

Build for release:
```bash
xcodebuild -project VideoGenerator.xcodeproj \
           -scheme VideoGenerator \
           -configuration Release \
           -derivedDataPath ./build \
           build
```

The built application will be located at:
```
build/Build/Products/Release/VideoGenerator.app
```

Run the application:
```bash
open build/Build/Products/Release/VideoGenerator.app
```

### Method 3: Debug Build via Command Line

Build for debugging:
```bash
xcodebuild -project VideoGenerator.xcodeproj \
           -scheme VideoGenerator \
           -configuration Debug \
           -derivedDataPath ./build \
           build
```

## Troubleshooting

### "No scheme" error
Make sure the scheme exists:
```bash
xcodebuild -project VideoGenerator.xcodeproj -list
```

### Code signing issues
- For local development, you can set `CODE_SIGN_IDENTITY=""` in build settings
- Or configure your Apple Developer account in Xcode preferences

### Metal not available
- This application requires Apple Silicon (M1/M2/M3)
- Intel Macs with AMD GPUs are not supported for optimal performance

## Running the Application

1. Launch the application
2. The interface will display your chip information (M1/M2/M3)
3. Click "Generate Video" to create a sample video
4. Generated videos are saved to `~/Documents/metal_generated_video_[timestamp].mp4`

## Customizing Video Generation

Edit `VideoGenerator/MetalVideoGenerator.swift` to customize:
- Video resolution (default: 1920x1080)
- Frame rate (default: 30 FPS)
- Duration (default: 5 seconds)
- Video content (currently generates animated gradients)

## Performance Notes

- Video generation uses Metal GPU acceleration for optimal performance
- On M1/M2/M3 chips, expect near real-time rendering
- Memory usage scales with video resolution and duration
