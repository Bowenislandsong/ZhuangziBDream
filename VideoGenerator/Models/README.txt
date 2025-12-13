Place your preloaded model files in this folder before building the app.

Supported file types are not enforced; the app treats files here as opaque model assets. Common types include:
- .mlmodelc (Core ML compiled models)
- .mlmodel (will be compiled by Xcode to .mlmodelc if added individually)
- .safetensors / .bin / .onnx / .gguf (for custom runtimes you integrate)

At runtime, these files are enumerated and shown in the app's Model picker. On first launch, the first listed model is selected by default.
