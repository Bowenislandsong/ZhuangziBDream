# Quick Start Guide

## What is this?

A native macOS application that uses Apple M-series chips (M1, M2, M3) to generate video using Metal GPU acceleration.

## Quick Setup (2 minutes)

1. **Open the project**:
   ```bash
   open VideoGenerator.xcodeproj
   ```

2. **Run in Xcode**:
   - Press `Cmd + R`
   - The app will launch automatically

3. **Generate a video**:
   - Click the "Generate Video" button
   - Wait ~5-10 seconds
   - Video is saved to `~/Documents/`

## What does it do?

- ✅ Detects your M-series chip (M1/M2/M3)
- ✅ Shows GPU information
- ✅ Generates a 5-second 1080p video with animated gradients
- ✅ Uses Metal for hardware acceleration
- ✅ Outputs H.264 MP4 files

## Requirements

- Mac with M1, M2, or M3 chip
- macOS 13.0 or later
- Xcode 15.0 or later

## Output

Videos are saved as:
```
~/Documents/metal_generated_video_[timestamp].mp4
```

Properties:
- Resolution: 1920x1080 (Full HD)
- Frame rate: 30 FPS
- Duration: 5 seconds
- Codec: H.264
- Size: ~2-3 MB

## Customization

Want different video content? Edit `VideoGenerator/MetalVideoGenerator.swift`:

```swift
// Change video parameters
let width = 1920        // Change resolution
let height = 1080
let fps: Int32 = 30     // Change frame rate
let duration: Double = 5.0  // Change duration in seconds

// Modify the generateFrame() function to change visual content
```

## Need Help?

- 📖 See [BUILD.md](BUILD.md) for detailed build instructions
- 🏗️ See [ARCHITECTURE.md](ARCHITECTURE.md) for technical details
- 📚 See [README.md](README.md) for complete documentation

## Common Issues

**Problem**: Build fails with code signing error
- **Solution**: In Xcode, set Team to "None" in project settings

**Problem**: "Metal is not supported"
- **Solution**: This app requires Apple Silicon (M1/M2/M3). Intel Macs won't run it optimally.

**Problem**: Can't find generated video
- **Solution**: Check `~/Documents/` folder or look for the path in the app's success message

## Next Steps

1. ✅ Run the app and generate your first video
2. 📊 Check the video output in Documents folder
3. 🎨 Customize the frame generation to create your own visuals
4. 🚀 Explore Metal compute shaders for advanced effects

Enjoy creating videos with Apple Silicon! 🎬
