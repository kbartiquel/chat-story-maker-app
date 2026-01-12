//
//  AudioService.swift
//  Textory
//
//  System sounds for messaging (no files needed)
//

import AudioToolbox

class AudioService {
    static let shared = AudioService()

    var soundsEnabled = true

    // System Sound IDs (built into iOS)
    private let sendSoundID: SystemSoundID = 1004      // SMS sent swoosh
    private let receiveSoundID: SystemSoundID = 1007   // SMS received ding
    private let typingSoundID: SystemSoundID = 1104    // Keyboard click

    private init() {}

    func playSendSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(sendSoundID)
    }

    func playReceiveSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(receiveSoundID)
    }

    func playTypingSound() {
        guard soundsEnabled else { return }
        AudioServicesPlaySystemSound(typingSoundID)
    }

    func playSendWithHaptic() {
        guard soundsEnabled else { return }
        AudioServicesPlayAlertSound(sendSoundID)
    }
}
