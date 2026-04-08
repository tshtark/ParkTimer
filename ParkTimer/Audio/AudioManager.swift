import AVFoundation

enum SoundEvent: String, CaseIterable {
    case warning = "warning"
    case expired = "expired"
    case tick = "tick"
}

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [SoundEvent: AVAudioPlayer] = [:]

    func configure() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("[AudioManager] Session config failed: \(error)")
        }
        preloadSounds()
    }

    func play(_ event: SoundEvent) {
        guard SettingsManager.shared.isSoundEnabled else { return }
        if let player = players[event] {
            player.currentTime = 0
            player.play()
        }
    }

    private func preloadSounds() {
        for event in SoundEvent.allCases {
            guard let url = Bundle.main.url(forResource: event.rawValue, withExtension: "wav") else {
                print("[AudioManager] Missing: \(event.rawValue).wav")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = event == .tick ? 0.4 : 0.8
                players[event] = player
            } catch {
                print("[AudioManager] Load failed \(event): \(error)")
            }
        }
    }
}
