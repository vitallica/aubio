# Aubio for Swift Package Manager

A Swift Package Manager wrapper for [aubio](https://aubio.org) - a powerful audio analysis library for tempo detection, pitch detection, beat tracking, and more.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20macOS-lightgrey.svg)](https://github.com/vitallica/aubio)
[![License](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](COPYING)

## Why This Fork?

The original [aubio library](https://github.com/aubio/aubio) is only available via CocoaPods. This fork adds **Swift Package Manager (SPM)** support, making it easy to integrate aubio into modern Swift and iOS projects without CocoaPods.

## About Aubio

aubio is a library to label music and sounds. It listens to audio signals and attempts to detect events such as:
- When a drum is hit
- At which frequency a note is playing
- At what tempo a rhythmic melody is playing

## Features

- 🎵 **Tempo/BPM Detection** - Accurate beat tracking and tempo estimation
- 🎼 **Pitch Detection** - Fundamental frequency analysis
- 🎹 **Note Detection** - Musical note tracking
- 📊 **Spectral Analysis** - FFT, phase vocoder, MFCC
- 🔊 **Onset Detection** - Attack time detection
- 🎚️ **Digital Filters** - Low pass, high pass, and more
- ⚡ **Accelerate Optimized** - Uses Apple's Accelerate framework for performance
- 📦 **SPM Ready** - No CocoaPods required
- 🍎 **Native Apple** - Built-in CoreAudio integration

## Quick Start

### Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/vitallica/aubio", from: "0.5.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and paste the repository URL.

### Basic Usage

```swift
import Aubio

// Detect tempo from audio samples
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

## Documentation

📖 **[Full Documentation](SPM_README.md)** - Complete API reference, examples, and integration guide

**Quick Links:**
- [Installation Instructions](SPM_README.md#installation)
- [Usage Examples](SPM_README.md#usage)
- [iOS App Integration Guide](SPM_README.md#ios-app-integration)
- [API Reference](SPM_README.md#api-reference)
- [Troubleshooting](SPM_README.md#troubleshooting)

### Original Aubio Documentation

- [Aubio Manual](https://aubio.org/manual/latest/) - Official aubio documentation
- [Developer Documentation](https://aubio.org/doc/latest/) - Doxygen-generated API docs
- [Homepage](https://aubio.org/) - Official aubio website

## Requirements

- iOS 13.0+ or macOS 11.0+
- Xcode 14.0+
- Swift 5.9+

## Examples

Check out [examples/AubioUsageExample.swift](examples/AubioUsageExample.swift) for complete working examples:

- ✅ Tempo detection with confidence scoring
- ✅ Pitch detection with YIN algorithm
- ✅ Musical key detection
- ✅ AVFoundation audio file loading
- ✅ Integration patterns for iOS apps

## What's Different from Original Aubio?

This fork adds:
- ✅ `Package.swift` manifest for SPM support
- ✅ C module map for Swift interop (`src/include/module.modulemap`)
- ✅ Swift usage examples
- ✅ iOS/macOS optimizations with Accelerate framework
- ✅ Comprehensive documentation for Swift developers

All original aubio functionality is preserved and unchanged.

## License

This wrapper maintains aubio's original **GPL v3** license. See [COPYING](COPYING) for full details.

aubio is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

⚠️ **Important for Commercial Apps:** GPL v3 is a copyleft license. If you're building a commercial app, you must either:
- Open source your app under GPL v3
- Obtain a commercial license from the aubio developers
- Use an alternative library

## Credits

- **Aubio Library:** [Paul Brossier](https://github.com/piem) and [contributors](https://github.com/aubio/aubio/graphs/contributors)
- **Original Repository:** [aubio/aubio](https://github.com/aubio/aubio)
- **SPM Wrapper:** Community contribution for Swift/iOS support

## Citation

When citing this work, please reference the original aubio project:

> The home page of this project can be found at: https://aubio.org/

For more information, see the [about page](https://aubio.org/manual/latest/about.html) in the [aubio manual](https://aubio.org/manual/latest/).

## Contributing

Found a bug or want to improve the SPM wrapper? Contributions are welcome!

- **For aubio library issues:** Report to [aubio/aubio](https://github.com/aubio/aubio/issues)
- **For SPM wrapper issues:** Open an issue in this repository

## Related Projects

- [aubio](https://github.com/aubio/aubio) - Original C library
- [aubio-iOS CocoaPod](https://cocoapods.org/pods/aubio-iOS) - CocoaPods version

---

**Happy audio analysis!** 🎵

Made with ❤️ for the Swift community
