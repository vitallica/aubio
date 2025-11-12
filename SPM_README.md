# Aubio Swift Package Manager Wrapper

This repository provides a Swift Package Manager (SPM) wrapper for the [aubio](https://aubio.org) audio analysis library, enabling easy integration into Swift and iOS projects.

## Overview

**Aubio** is a powerful C library for audio analysis, providing:
- **Tempo/BPM Detection** - Beat tracking and tempo estimation
- **Pitch Detection** - Fundamental frequency detection
- **Onset Detection** - Attack time detection
- **Note Detection** - Musical note tracking
- **FFT & Spectral Analysis** - Various spectral processing tools

This SPM wrapper builds aubio from source for iOS and macOS, using Apple's Accelerate framework for optimized performance.

## Features

✅ **SPM Compatible** - No CocoaPods required
✅ **iOS & iOS Simulator** - Full support for iOS 13+
✅ **macOS Support** - Compatible with macOS 11+
✅ **Accelerate Optimized** - Uses Apple's Accelerate framework for fast FFT
✅ **Apple Audio I/O** - Native CoreAudio integration
✅ **Build from Source** - Full control and transparency

## Requirements

- iOS 13.0+ / macOS 11.0+
- Xcode 14.0+
- Swift 5.9+

## Installation

### Option 1: Add to Xcode Project

1. In Xcode, go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/vitallica/aubio` (or your fork URL)
3. Select the version/branch you want
4. Click **Add Package**

### Option 2: Add to Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/vitallica/aubio", from: "0.5.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["Aubio"]
    )
]
```

## Usage

### Import the Library

```swift
import Aubio
```

### Tempo Detection

```swift
func detectTempo(audioSamples: [Float], sampleRate: UInt32 = 44100) -> Double? {
    let hopSize: UInt32 = 512
    let windowSize: UInt32 = 1024

    guard let tempo = new_aubio_tempo("default", windowSize, hopSize, sampleRate) else {
        return nil
    }
    defer { del_aubio_tempo(tempo) }

    guard let inputBuffer = new_fvec(hopSize) else { return nil }
    defer { del_fvec(inputBuffer) }

    var bpmValues: [Float] = []

    for chunkStart in stride(from: 0, to: audioSamples.count, by: Int(hopSize)) {
        let chunkEnd = min(chunkStart + Int(hopSize), audioSamples.count)
        let chunk = Array(audioSamples[chunkStart..<chunkEnd])

        for (i, sample) in chunk.enumerated() {
            inputBuffer.pointee.data[i] = sample
        }

        aubio_tempo_do(tempo, inputBuffer, nil)

        let bpm = aubio_tempo_get_bpm(tempo)
        if bpm > 0 {
            bpmValues.append(bpm)
        }
    }

    guard !bpmValues.isEmpty else { return nil }
    let sortedBPMs = bpmValues.sorted()
    return Double(sortedBPMs[sortedBPMs.count / 2])
}
```

### Pitch Detection

```swift
func detectPitch(audioSamples: [Float], sampleRate: UInt32 = 44100) -> Double? {
    let hopSize: UInt32 = 512
    let windowSize: UInt32 = 2048

    guard let pitch = new_aubio_pitch("yinfft", windowSize, hopSize, sampleRate) else {
        return nil
    }
    defer { del_aubio_pitch(pitch) }

    aubio_pitch_set_unit(pitch, "Hz")
    aubio_pitch_set_silence(pitch, -40.0)

    guard let inputBuffer = new_fvec(hopSize),
          let outputBuffer = new_fvec(1) else { return nil }
    defer {
        del_fvec(inputBuffer)
        del_fvec(outputBuffer)
    }

    var frequencies: [Float] = []

    for chunkStart in stride(from: 0, to: audioSamples.count, by: Int(hopSize)) {
        let chunkEnd = min(chunkStart + Int(hopSize), audioSamples.count)
        let chunk = Array(audioSamples[chunkStart..<chunkEnd])

        for (i, sample) in chunk.enumerated() {
            inputBuffer.pointee.data[i] = sample
        }

        aubio_pitch_do(pitch, inputBuffer, outputBuffer)
        let freq = outputBuffer.pointee.data[0]

        if freq > 0 && aubio_pitch_get_confidence(pitch) > 0.5 {
            frequencies.append(freq)
        }
    }

    guard !frequencies.isEmpty else { return nil }
    return Double(frequencies.reduce(0, +) / Float(frequencies.count))
}
```

### Complete Example

See [examples/AubioUsageExample.swift](examples/AubioUsageExample.swift) for complete working examples including:
- Tempo detection
- Pitch detection
- Musical key detection
- Integration patterns for iOS apps

## iOS App Integration

Here's a recommended pattern for integrating aubio into your iOS app:

### 1. Create an Audio Analysis Service

```swift
protocol AudioAnalysisService {
    func analyzeTempo(audioURL: URL) async throws -> Double?
    func analyzePitch(audioURL: URL) async throws -> Double?
}

class AubioAnalysisService: AudioAnalysisService {
    func analyzeTempo(audioURL: URL) async throws -> Double? {
        let samples = try await loadAudioSamples(from: audioURL)
        return detectTempo(audioSamples: samples)
    }

    func analyzePitch(audioURL: URL) async throws -> Double? {
        let samples = try await loadAudioSamples(from: audioURL)
        return detectPitch(audioSamples: samples)
    }

    private func loadAudioSamples(from url: URL) async throws -> [Float] {
        // Use AVFoundation to load audio file
        // Convert to mono PCM float samples at 44100 Hz
        // Return sample array
    }
}
```

### 2. Loading Audio Files with AVFoundation

```swift
import AVFoundation

func loadAudioSamples(from url: URL) throws -> [Float] {
    let audioFile = try AVAudioFile(forReading: url)
    let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                               sampleRate: 44100,
                               channels: 1,
                               interleaved: false)!

    let frameCount = UInt32(audioFile.length)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
        throw NSError(domain: "AudioLoading", code: -1)
    }

    try audioFile.read(into: buffer, frameCount: frameCount)

    let samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0],
                                            count: Int(buffer.frameLength)))
    return samples
}
```

### 3. Using in Your App

```swift
// Example: Analyze audio in your view model
class AudioViewModel: ObservableObject {
    private let analysisService: AudioAnalysisService = AubioAnalysisService()

    @Published var detectedTempo: Double?
    @Published var detectedPitch: Double?

    func analyzeAudio(url: URL) async {
        do {
            async let tempo = analysisService.analyzeTempo(audioURL: url)
            async let pitch = analysisService.analyzePitch(audioURL: url)

            self.detectedTempo = try await tempo
            self.detectedPitch = try await pitch
        } catch {
            print("Analysis failed: \(error)")
        }
    }
}
```

## API Reference

### Core Functions

**Tempo Detection:**
- `new_aubio_tempo(method, buf_size, hop_size, samplerate)` - Create tempo detector
- `aubio_tempo_do(tempo, input, output)` - Process audio buffer
- `aubio_tempo_get_bpm(tempo)` - Get detected BPM
- `del_aubio_tempo(tempo)` - Cleanup

**Pitch Detection:**
- `new_aubio_pitch(method, buf_size, hop_size, samplerate)` - Create pitch detector
- `aubio_pitch_do(pitch, input, output)` - Process audio buffer
- `aubio_pitch_get_confidence(pitch)` - Get confidence (0-1)
- `aubio_pitch_set_unit(pitch, unit)` - Set output unit ("Hz", "midi", "cent")
- `del_aubio_pitch(pitch)` - Cleanup

**Buffer Management:**
- `new_fvec(length)` - Create float vector
- `del_fvec(fvec)` - Destroy float vector

### Detection Methods

**Tempo Methods:**
- `"default"` - Default tempo detection
- `"specflux"` - Spectral flux
- `"energy"` - Energy-based
- `"hfc"` - High frequency content
- `"complex"` - Complex domain
- `"phase"` - Phase-based
- `"kl"` - Kullback-Liebler
- `"mkl"` - Modified Kullback-Liebler

**Pitch Methods:**
- `"default"` - Default (YIN FFT)
- `"yinfft"` - YIN with FFT (recommended for music)
- `"yin"` - YIN algorithm
- `"yinfast"` - Fast YIN
- `"mcomb"` - Multiple comb filter
- `"fcomb"` - Fast comb filter
- `"schmitt"` - Schmitt trigger

## Architecture

This SPM wrapper:

1. **Builds from Source** - Compiles all aubio C code as part of SPM build
2. **Uses Accelerate** - Apple's Accelerate framework for optimized FFT/DSP
3. **Native Audio I/O** - CoreFoundation/AudioToolbox integration
4. **Minimal Dependencies** - No external libraries required on Apple platforms

### Files Structure

```
aubio/
├── Package.swift              # SPM manifest
├── src/
│   ├── aubio.h               # Main header (umbrella)
│   ├── include/              # Public headers for SPM
│   │   ├── module.modulemap  # C module map
│   │   └── aubio.h           # Umbrella header copy
│   ├── pitch/                # Pitch detection sources
│   ├── tempo/                # Tempo detection sources
│   ├── onset/                # Onset detection sources
│   ├── spectral/             # FFT & spectral analysis
│   ├── temporal/             # Time-domain processing
│   ├── io/                   # Audio I/O
│   └── ...
├── examples/
│   ├── AubioUsageExample.swift  # Swift usage examples
│   └── ...                      # Original C examples
└── SPM_README.md             # This file
```

## Build Configuration

The SPM wrapper is configured with:

**Compiler Flags:**
- `HAVE_ACCELERATE` - Use Accelerate framework
- `HAVE_SOURCE_APPLE_AUDIO` - Apple audio input
- `HAVE_SINK_APPLE_AUDIO` - Apple audio output
- `HAVE_AUDIO_UNIT` - iOS AudioUnit support
- `HAVE_WAVREAD` / `HAVE_WAVWRITE` - WAV file support

**Linked Frameworks:**
- Accelerate - FFT and DSP acceleration
- CoreFoundation - Apple platform APIs
- AudioToolbox - Audio I/O

**Excluded Files:**
- Alternative FFT implementations (FFTW, IPP)
- External library audio I/O (sndfile, avcodec, jack)

## Performance Tips

1. **Buffer Sizes** - Use power-of-2 sizes (512, 1024, 2048) for optimal FFT performance
2. **Hop Size** - Smaller hop sizes = more accurate but slower (512 is a good default)
3. **Sample Rate** - Aubio works best with 44100 Hz audio
4. **Mono Audio** - Mix stereo to mono before processing for better results

## Troubleshooting

### Build Warnings

You may see warnings about `AUBIO_UNSTABLE` macro redefinition - these are harmless and can be ignored.

### Missing Headers

If you get "header not found" errors, make sure:
1. The `src/include/aubio.h` file exists
2. The `src/include/module.modulemap` file exists
3. Clean build folder and rebuild

### Runtime Crashes

- Check buffer sizes match between creation and usage
- Ensure audio samples are valid float values
- Always call `del_*` functions to free memory

## License

This wrapper maintains aubio's original **GPL v3** license. See [COPYING](COPYING) for details.

**Important:** If you're building a commercial iOS app, verify GPL v3 compatibility with your project. You may need to:
- Open source your app under GPL v3
- Obtain a commercial license from aubio developers
- Consider alternative libraries

## Resources

- **Aubio Official Site:** https://aubio.org
- **Aubio Documentation:** https://aubio.org/manual/latest/
- **Original Repository:** https://github.com/aubio/aubio

## Credits

- **Aubio Library:** Paul Brossier and contributors
- **SPM Wrapper:** Community contribution for Swift/iOS support
- **Last Updated:** 2025-11-12

## Contributing

This is a fork/wrapper of aubio specifically for SPM support. For issues with:
- **Aubio library itself:** Report to [aubio/aubio](https://github.com/aubio/aubio)
- **SPM wrapper:** Report to this repository's Issues

## Changelog

### 0.5.0-spm.1 (2025-11-12)
- Initial SPM wrapper release
- iOS 13+ and macOS 11+ support
- Accelerate framework integration
- Example Swift usage code
- Built from aubio 0.5.0-alpha

---

**Happy tempo detecting!** 🎵
