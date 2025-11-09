import Foundation
import Metal
import AVFoundation
import CoreVideo
import CoreImage

struct ChipInfo {
    let deviceName: String
    let gpuFamily: String
    let metalSupport: Bool
}

class MetalVideoGenerator: ObservableObject {
    @Published var chipInfo: ChipInfo?
    
    private var device: MTLDevice?
    private var commandQueue: MTLCommandQueue?
    
    init() {
        setupMetal()
        detectChipInfo()
    }
    
    private func setupMetal() {
        // Get the default Metal device (M-series GPU)
        guard let metalDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            return
        }
        
        device = metalDevice
        commandQueue = metalDevice.makeCommandQueue()
        
        print("Metal device initialized: \(metalDevice.name)")
    }
    
    private func detectChipInfo() {
        guard let device = device else {
            chipInfo = ChipInfo(
                deviceName: "Unknown",
                gpuFamily: "Not Available",
                metalSupport: false
            )
            return
        }
        
        var gpuFamily = "Apple GPU"
        
        // Check for Apple Silicon GPU families
        if device.supportsFamily(.apple8) {
            gpuFamily = "Apple M2/M3 Series"
        } else if device.supportsFamily(.apple7) {
            gpuFamily = "Apple M1 Series"
        } else if device.supportsFamily(.apple6) {
            gpuFamily = "Apple A-Series"
        }
        
        chipInfo = ChipInfo(
            deviceName: device.name,
            gpuFamily: gpuFamily,
            metalSupport: true
        )
    }
    
    func generateVideo() async throws -> URL {
        guard let device = device,
              let commandQueue = commandQueue else {
            throw VideoGeneratorError.metalNotAvailable
        }
        
        // Video parameters
        let width = 1920
        let height = 1080
        let fps: Int32 = 30
        let duration: Double = 5.0 // 5 seconds
        let frameCount = Int(duration * Double(fps))
        
        // Create output URL in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("metal_generated_video_\(Date().timeIntervalSince1970).mp4")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 6000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                kCVPixelBufferMetalCompatibilityKey as String: true
            ]
        )
        
        videoWriter.add(videoWriterInput)
        
        guard videoWriter.startWriting() else {
            throw VideoGeneratorError.writerSetupFailed
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Create Metal textures and generate frames
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw VideoGeneratorError.textureCreationFailed
        }
        
        // Generate frames
        for frameIndex in 0..<frameCount {
            let presentationTime = CMTime(value: Int64(frameIndex), timescale: fps)
            
            while !videoWriterInput.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 10_000_000) // 10ms
            }
            
            // Generate frame using Metal
            try await generateFrame(
                texture: texture,
                frameIndex: frameIndex,
                totalFrames: frameCount,
                commandQueue: commandQueue
            )
            
            // Create pixel buffer from texture
            guard let pixelBuffer = adaptor.pixelBufferPool?.createPixelBuffer() else {
                throw VideoGeneratorError.pixelBufferCreationFailed
            }
            
            // Copy texture to pixel buffer
            copyTextureToPixelBuffer(texture: texture, pixelBuffer: pixelBuffer)
            
            // Append to video
            adaptor.append(pixelBuffer, withPresentationTime: presentationTime)
        }
        
        // Finalize video
        videoWriterInput.markAsFinished()
        
        await videoWriter.finishWriting()
        
        if videoWriter.status == .completed {
            print("Video generated successfully at: \(outputURL.path)")
            return outputURL
        } else if let error = videoWriter.error {
            throw error
        } else {
            throw VideoGeneratorError.unknownError
        }
    }
    
    private func generateFrame(
        texture: MTLTexture,
        frameIndex: Int,
        totalFrames: Int,
        commandQueue: MTLCommandQueue
    ) async throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            throw VideoGeneratorError.commandBufferCreationFailed
        }
        
        // Generate procedural content using Metal compute
        let width = texture.width
        let height = texture.height
        
        // Create a simple gradient animation
        let progress = Float(frameIndex) / Float(totalFrames)
        
        // Use CPU to generate frame data (in production, use Metal compute shaders)
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        
        for y in 0..<height {
            for x in 0..<width {
                let index = (y * width + x) * 4
                
                // Create animated gradient
                let r = UInt8((Float(x) / Float(width)) * 255.0)
                let g = UInt8((Float(y) / Float(height)) * 255.0)
                let b = UInt8(progress * 255.0)
                
                pixelData[index] = b     // B
                pixelData[index + 1] = g // G
                pixelData[index + 2] = r // R
                pixelData[index + 3] = 255 // A
            }
        }
        
        // Upload to texture
        let region = MTLRegionMake2D(0, 0, width, height)
        pixelData.withUnsafeBytes { ptr in
            texture.replace(
                region: region,
                mipmapLevel: 0,
                withBytes: ptr.baseAddress!,
                bytesPerRow: width * 4
            )
        }
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    private func copyTextureToPixelBuffer(texture: MTLTexture, pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }
        
        let width = texture.width
        let height = texture.height
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return
        }
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(
            baseAddress,
            bytesPerRow: bytesPerRow,
            from: region,
            mipmapLevel: 0
        )
    }
}

// Extension for pixel buffer creation
extension CVPixelBufferPool {
    func createPixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(
            kCFAllocatorDefault,
            self,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        return pixelBuffer
    }
}

enum VideoGeneratorError: LocalizedError {
    case metalNotAvailable
    case writerSetupFailed
    case textureCreationFailed
    case pixelBufferCreationFailed
    case commandBufferCreationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .metalNotAvailable:
            return "Metal GPU acceleration is not available on this device"
        case .writerSetupFailed:
            return "Failed to setup video writer"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .pixelBufferCreationFailed:
            return "Failed to create pixel buffer"
        case .commandBufferCreationFailed:
            return "Failed to create Metal command buffer"
        case .unknownError:
            return "An unknown error occurred during video generation"
        }
    }
}
