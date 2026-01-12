//
//  SoundGenerator.swift
//  Textory
//
//  Generates audio samples for message sounds (no files needed)
//

import AVFoundation
import Accelerate

class SoundGenerator {
    static let shared = SoundGenerator()

    let sampleRate: Double = 44100

    private init() {}

    // MARK: - Generate Send Sound (swoosh-like ascending tone)

    func generateSendSound(duration: Double = 0.15) -> [Float] {
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Ascending frequency from 800Hz to 1400Hz
            let frequency = 800.0 + (600.0 * progress)

            // Envelope: quick attack, quick decay
            let envelope = sin(Double.pi * progress) * (1.0 - progress * 0.5)

            // Generate sine wave
            let sample = sin(2.0 * Double.pi * frequency * t) * envelope * 0.5
            samples[i] = Float(sample)
        }

        return samples
    }

    // MARK: - Generate Receive Sound (ding-like two-tone)

    func generateReceiveSound(duration: Double = 0.2) -> [Float] {
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Two-tone ding: 1200Hz and 1500Hz harmonics
            let freq1 = 1200.0
            let freq2 = 1500.0

            // Envelope: sharp attack, gradual decay
            let envelope = exp(-progress * 5.0) * (1.0 - exp(-progress * 50.0))

            // Mix two frequencies
            let sample1 = sin(2.0 * Double.pi * freq1 * t)
            let sample2 = sin(2.0 * Double.pi * freq2 * t) * 0.5
            let sample = (sample1 + sample2) * envelope * 0.4

            samples[i] = Float(sample)
        }

        return samples
    }

    // MARK: - Generate Typing Sound (soft click)

    func generateTypingSound(duration: Double = 0.05) -> [Float] {
        let numSamples = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: numSamples)

        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let progress = t / duration

            // Short click sound
            let frequency = 600.0
            let envelope = exp(-progress * 30.0)
            let sample = sin(2.0 * Double.pi * frequency * t) * envelope * 0.2
            samples[i] = Float(sample)
        }

        return samples
    }

    // MARK: - Create Silent Audio

    func generateSilence(duration: Double) -> [Float] {
        let numSamples = Int(sampleRate * duration)
        return [Float](repeating: 0, count: numSamples)
    }

    // MARK: - Convert to PCM Buffer

    func createPCMBuffer(from samples: [Float]) -> AVAudioPCMBuffer? {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return nil
        }

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(samples.count)

        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<samples.count {
                channelData[i] = samples[i]
            }
        }

        return buffer
    }

    // MARK: - Create Audio Data for Video Export

    func createAudioSamples(
        for messages: [Message],
        messageTimes: [(message: Message, startTime: Double, isMe: Bool)],
        totalDuration: Double
    ) -> Data {
        let totalSamples = Int(sampleRate * totalDuration)
        var audioData = [Float](repeating: 0, count: totalSamples)

        // Pre-generate sounds
        let sendSound = generateSendSound()
        let receiveSound = generateReceiveSound()

        // Place sounds at message timestamps
        for (_, startTime, isMe) in messageTimes {
            let sound = isMe ? sendSound : receiveSound
            let startSample = Int(startTime * sampleRate)

            // Mix sound into audio data
            for (i, sample) in sound.enumerated() {
                let targetIndex = startSample + i
                if targetIndex < totalSamples {
                    audioData[targetIndex] += sample
                }
            }
        }

        // Clamp values to prevent clipping
        for i in 0..<totalSamples {
            audioData[i] = max(-1.0, min(1.0, audioData[i]))
        }

        // Convert to 16-bit PCM data
        var pcmData = Data()
        for sample in audioData {
            var int16Sample = Int16(sample * 32767.0)
            pcmData.append(Data(bytes: &int16Sample, count: 2))
        }

        return pcmData
    }
}
