import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var videoGenerator = MetalVideoGenerator()
    @State private var isGenerating = false
    @State private var statusMessage = "Ready to generate video"
    @State private var showAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("M-Series Video Generator")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Harness the power of Apple Silicon")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let chipInfo = videoGenerator.chipInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Information:")
                        .font(.headline)
                    Text("Device: \(chipInfo.deviceName)")
                    Text("GPU Family: \(chipInfo.gpuFamily)")
                    Text("Metal Support: \(chipInfo.metalSupport ? "Yes" : "No")")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button(action: generateVideo) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    Text(isGenerating ? "Generating..." : "Generate Video")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: 300)
                .padding()
                .background(isGenerating ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isGenerating)
            
            Text(statusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .padding()
        .alert("Video Generated", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(statusMessage)
        }
    }
    
    private func generateVideo() {
        isGenerating = true
        statusMessage = "Initializing M-series GPU for video generation..."
        
        Task {
            do {
                let outputURL = try await videoGenerator.generateVideo()
                await MainActor.run {
                    isGenerating = false
                    statusMessage = "Video successfully generated at:\n\(outputURL.path)"
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    statusMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
