# Changelog

All notable changes to the Swift Package Manager wrapper for aubio will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0-spm.1] - 2025-11-12

### Added
- Initial Swift Package Manager support for aubio
- `Package.swift` manifest with iOS 13+ and macOS 11+ support
- C module map for Swift interop (`src/include/module.modulemap`)
- Accelerate framework integration for optimized FFT/DSP performance
- Apple Audio I/O support (CoreFoundation, AudioToolbox)
- Comprehensive Swift usage examples (`examples/AubioUsageExample.swift`)
  - Tempo/BPM detection example
  - Pitch detection with YIN algorithm
  - Musical key detection helper functions
  - iOS app integration patterns
- Complete documentation (`README.md`, `SPM_README.md`)
  - Installation instructions for Xcode and Package.swift
  - API reference with all major functions
  - iOS app integration guide with AVFoundation examples
  - Troubleshooting section
  - Performance tips
- `CHANGELOG.md` for tracking version history

### Changed
- Main `README.md` updated to highlight SPM support and Swift integration
- Build configuration optimized for Apple platforms
  - Uses Accelerate framework instead of Ooura FFT
  - Enables Apple-specific audio I/O by default
  - Excludes external library dependencies (sndfile, avcodec, jack)

### Technical Details
- Based on aubio version 0.5.0-alpha
- Compiler flags: `HAVE_ACCELERATE`, `HAVE_SOURCE_APPLE_AUDIO`, `HAVE_SINK_APPLE_AUDIO`, `HAVE_AUDIO_UNIT` (iOS only), `HAVE_WAVREAD`, `HAVE_WAVWRITE`
- Linked frameworks: Accelerate, CoreFoundation, AudioToolbox
- C language standard: C11
- 62 C source files compiled
- No external dependencies required on Apple platforms

### Known Issues
- Harmless compiler warnings about `AUBIO_UNSTABLE` macro redefinition (can be safely ignored)
- Some excluded files in Package.swift don't exist in the source tree (non-blocking warnings)

## [Unreleased]

### Planned
- Example project demonstrating real-world usage
- Performance benchmarks for iOS devices
- Additional Swift convenience wrappers
- tvOS and watchOS support

---

## Original Aubio Releases

This SPM wrapper is based on [aubio 0.5.0-alpha](https://github.com/aubio/aubio). For the original aubio changelog and release history, see:
- [aubio ChangeLog](ChangeLog) - Original aubio version history
- [aubio releases](https://github.com/aubio/aubio/releases) - GitHub releases

## Version Numbering

This SPM wrapper uses the following versioning scheme:
- `X.Y.Z-spm.N` where:
  - `X.Y.Z` matches the upstream aubio version
  - `N` is the SPM wrapper revision number

Example: `0.5.0-spm.1` means:
- Based on aubio 0.5.0
- First SPM wrapper release

[0.5.0-spm.1]: https://github.com/vitallica/aubio/releases/tag/0.5.0-spm.1
[Unreleased]: https://github.com/vitallica/aubio/compare/0.5.0-spm.1...HEAD
