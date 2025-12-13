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

3. **Compose & generate**:
   - Describe your scene in the prompt textbox
   - Click "Generate Video"
   - Video is saved to `~/Downloads/`

4. **Pick or add a model (optional)**:
   - Use the Model picker to choose a preloaded model
   - Click "Add Model from URL…" to download a model file (e.g., from Hugging Face)

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
~/Downloads/metal_generated_video_[model]_[prompt-fragment]_[timestamp].mp4
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
- **Solution**: Videos are saved to `~/Downloads/`. Use the "Reveal" button after generation if needed.

**Problem**: Terminal build fails with `xcodebuild` needs full Xcode
- **Solution**: Install Xcode from the App Store, then run:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```
   Then try building again.

## Next Steps

1. ✅ Run the app and generate your first video
2. 📊 Check the video output in Documents folder
3. 🎨 Customize the frame generation to create your own visuals
4. 🚀 Explore Metal compute shaders for advanced effects

Enjoy creating videos with Apple Silicon! 🎬

---

## Models (preloaded by default, add more later)

This app supports shipping preloaded models and adding more at runtime.

- To preload models into the app bundle: place files in `VideoGenerator/Models/` before building.
   - These files are copied into the app bundle and shown in the Model picker.
   - On first launch, the first bundled model is selected by default.
- To add models at runtime: click "Add Model from URL…" and paste a direct `https://` link (e.g., a Hugging Face file URL).
   - The file is downloaded to the app's Application Support directory and becomes selectable.

Notes:
- The app treats files as opaque "models". You can use `.mlmodelc`, `.mlmodel`, `.safetensors`, `.onnx`, `.gguf`, etc. Your generation pipeline can then load them as needed.
- The current sample video generation doesn't consume the model weights yet; it's wired so the chosen model is tracked and reflected in the output filename. You can integrate your runtime under `MetalVideoGenerator.generateVideo(model:)`.
- The UI exposes a menu item (**File → Download Model…**) for quick additions.
