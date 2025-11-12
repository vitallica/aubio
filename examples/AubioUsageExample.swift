import Foundation
import Aubio

/// Example Swift code demonstrating how to use Aubio for tempo and pitch detection
/// This can be integrated into any iOS or macOS app

// MARK: - Tempo Detection Example

/// Detects the tempo (BPM) from audio samples
/// - Parameters:
///   - audioSamples: Array of audio samples (PCM float values)
///   - sampleRate: Sample rate in Hz (e.g., 44100)
/// - Returns: Detected BPM value, or nil if detection fails
func detectTempo(audioSamples: [Float], sampleRate: UInt32 = 44100) -> Double? {
    let hopSize: UInt32 = 512
    let windowSize: UInt32 = 1024

    // Create tempo detector
    guard let tempo = new_aubio_tempo("default", windowSize, hopSize, sampleRate) else {
        print("Failed to create tempo detector")
        return nil
    }

    defer {
        del_aubio_tempo(tempo)
    }

    // Create input buffer
    guard let inputBuffer = new_fvec(hopSize) else {
        print("Failed to create input buffer")
        return nil
    }

    defer {
        del_fvec(inputBuffer)
    }

    // Process audio in chunks
    var bpmValues: [Float] = []

    for chunkStart in stride(from: 0, to: audioSamples.count, by: Int(hopSize)) {
        let chunkEnd = min(chunkStart + Int(hopSize), audioSamples.count)
        let chunk = Array(audioSamples[chunkStart..<chunkEnd])

        // Copy samples to aubio buffer
        for (i, sample) in chunk.enumerated() {
            inputBuffer.pointee.data[i] = sample
        }

        // Process the buffer
        aubio_tempo_do(tempo, inputBuffer, nil)

        // Get current BPM estimate
        let bpm = aubio_tempo_get_bpm(tempo)
        if bpm > 0 {
            bpmValues.append(bpm)
        }
    }

    // Return median BPM value for stability
    guard !bpmValues.isEmpty else { return nil }
    let sortedBPMs = bpmValues.sorted()
    return Double(sortedBPMs[sortedBPMs.count / 2])
}

// MARK: - Pitch Detection Example

/// Detects the pitch from audio samples
/// - Parameters:
///   - audioSamples: Array of audio samples (PCM float values)
///   - sampleRate: Sample rate in Hz (e.g., 44100)
/// - Returns: Tuple of (frequency in Hz, confidence 0-1), or nil if detection fails
func detectPitch(audioSamples: [Float], sampleRate: UInt32 = 44100) -> (frequency: Double, confidence: Double)? {
    let hopSize: UInt32 = 512
    let windowSize: UInt32 = 2048

    // Create pitch detector using YIN algorithm (recommended for music)
    guard let pitch = new_aubio_pitch("yinfft", windowSize, hopSize, sampleRate) else {
        print("Failed to create pitch detector")
        return nil
    }

    defer {
        del_aubio_pitch(pitch)
    }

    // Set pitch detection parameters
    aubio_pitch_set_unit(pitch, "Hz")
    aubio_pitch_set_silence(pitch, -40.0) // Silence threshold in dB

    // Create buffers
    guard let inputBuffer = new_fvec(hopSize),
          let outputBuffer = new_fvec(1) else {
        print("Failed to create buffers")
        return nil
    }

    defer {
        del_fvec(inputBuffer)
        del_fvec(outputBuffer)
    }

    // Collect pitch estimates
    var pitchValues: [(frequency: Float, confidence: Float)] = []

    for chunkStart in stride(from: 0, to: audioSamples.count, by: Int(hopSize)) {
        let chunkEnd = min(chunkStart + Int(hopSize), audioSamples.count)
        let chunk = Array(audioSamples[chunkStart..<chunkEnd])

        // Copy samples to aubio buffer
        for (i, sample) in chunk.enumerated() {
            inputBuffer.pointee.data[i] = sample
        }

        // Detect pitch
        aubio_pitch_do(pitch, inputBuffer, outputBuffer)

        let frequency = outputBuffer.pointee.data[0]
        let confidence = aubio_pitch_get_confidence(pitch)

        // Only keep confident pitch estimates
        if frequency > 0 && confidence > 0.5 {
            pitchValues.append((frequency, confidence))
        }
    }

    guard !pitchValues.isEmpty else { return nil }

    // Calculate weighted average pitch
    let totalConfidence = pitchValues.reduce(0) { $0 + $1.confidence }
    let weightedFrequency = pitchValues.reduce(0.0) { $0 + Double($1.frequency * $1.confidence) }
    let avgConfidence = totalConfidence / Float(pitchValues.count)

    return (
        frequency: weightedFrequency / Double(totalConfidence),
        confidence: Double(avgConfidence)
    )
}

// MARK: - Musical Key Detection Helper

/// Converts frequency (Hz) to MIDI note number
func frequencyToMIDI(_ frequency: Double) -> Int {
    return Int(round(12.0 * log2(frequency / 440.0) + 69.0))
}

/// Converts MIDI note number to note name
func midiToNoteName(_ midi: Int) -> String {
    let noteNames = ["C", "C♯", "D", "D♯", "E", "F", "F♯", "G", "G♯", "A", "A♯", "B"]
    let octave = (midi / 12) - 1
    let noteIndex = midi % 12
    return "\(noteNames[noteIndex])\(octave)"
}

/// Detects musical key from audio samples
/// - Parameters:
///   - audioSamples: Array of audio samples
///   - sampleRate: Sample rate in Hz
/// - Returns: Estimated musical key (e.g., "C", "A♯")
func detectMusicalKey(audioSamples: [Float], sampleRate: UInt32 = 44100) -> String? {
    guard let (frequency, confidence) = detectPitch(audioSamples: audioSamples, sampleRate: sampleRate),
          confidence > 0.6 else {
        return nil
    }

    let midiNote = frequencyToMIDI(frequency)
    let noteName = midiToNoteName(midiNote)

    // Extract just the note name without octave for key
    let noteOnly = String(noteName.prefix(while: { !$0.isNumber }))
    return noteOnly
}

// MARK: - Audio File Processing Example

/// Example of processing an audio file URL (you'll need AVFoundation for actual file reading)
/// This shows a general integration pattern for iOS/macOS apps
func analyzeAudioFile(url: URL) async throws -> (tempo: Double?, key: String?) {
    // NOTE: You would use AVFoundation's AVAudioFile to load the audio
    // For this example, we'll show the structure:

    // 1. Load audio file using AVFoundation (implementation needed)
    // let audioFile = try AVAudioFile(forReading: url)
    // let audioFormat = audioFile.processingFormat
    // let audioBuffer = AVAudioPCMBuffer(...)
    // let samples = convertBufferToFloatArray(audioBuffer)

    // Placeholder - replace with actual audio loading
    let samples: [Float] = [] // Load your audio samples here
    let sampleRate: UInt32 = 44100

    // 2. Analyze tempo
    let tempo = detectTempo(audioSamples: samples, sampleRate: sampleRate)

    // 3. Analyze key
    let key = detectMusicalKey(audioSamples: samples, sampleRate: sampleRate)

    return (tempo: tempo, key: key)
}

// MARK: - Usage Example for iOS App Integration

/*
 Here's how you would integrate aubio into your iOS app:

 // 1. Create an audio analysis service protocol:
 protocol AudioAnalysisService {
     func analyzeTempo(audioURL: URL) async throws -> Double?
     func analyzePitch(audioURL: URL) async throws -> Double?
 }

 // 2. Implement the service using aubio:
 class AubioAnalysisService: AudioAnalysisService {
     func analyzeTempo(audioURL: URL) async throws -> Double? {
         let samples = try await loadAudioSamples(from: audioURL)
         return detectTempo(audioSamples: samples)
     }

     func analyzePitch(audioURL: URL) async throws -> Double? {
         let samples = try await loadAudioSamples(from: audioURL)
         guard let (frequency, _) = detectPitch(audioSamples: samples) else {
             return nil
         }
         return frequency
     }

     private func loadAudioSamples(from url: URL) async throws -> [Float] {
         // Use AVFoundation to load audio file
         // Convert to mono PCM float samples at 44100 Hz
         // See SPM_README.md for complete implementation
     }
 }

 // 3. Use in your view model or view controller:
 class AudioViewModel: ObservableObject {
     private let analysisService: AudioAnalysisService = AubioAnalysisService()

     @Published var tempo: Double?
     @Published var pitch: Double?

     func analyzeAudio(fileURL: URL) async {
         do {
             async let tempoResult = analysisService.analyzeTempo(audioURL: fileURL)
             async let pitchResult = analysisService.analyzePitch(audioURL: fileURL)

             self.tempo = try await tempoResult
             self.pitch = try await pitchResult
         } catch {
             print("Audio analysis failed: \(error)")
         }
     }
 }
 */
