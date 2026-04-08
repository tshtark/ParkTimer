import AVFoundation

enum SoundEvent: String, CaseIterable {
    case warning = "warning"
    case expired = "expired"
    case tick = "tick"
}

enum AlertSound: String, CaseIterable, Codable {
    case standard = "warning"       // default, uses warning.wav
    case chime = "alert_chime"
    case bell = "alert_bell"
    case horn = "alert_horn"
    case pulse = "alert_pulse"

    var displayName: String {
        switch self {
        case .standard: "Standard"
        case .chime: "Chime"
        case .bell: "Bell"
        case .horn: "Horn"
        case .pulse: "Pulse"
        }
    }
}

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [String: AVAudioPlayer] = [:]

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

        // For warning/expired events, use the selected alert sound if Pro
        let filename: String
        if (event == .warning || event == .expired) && StoreManager.shared.isProUnlocked {
            filename = SettingsManager.shared.selectedAlertSound.rawValue
        } else {
            filename = event.rawValue
        }

        if let player = players[filename] {
            player.currentTime = 0
            player.play()
        }
    }

    func preview(_ sound: AlertSound) {
        guard let player = players[sound.rawValue] else { return }
        player.currentTime = 0
        player.play()
    }

    private func preloadSounds() {
        // Load default event sounds
        let filenames = SoundEvent.allCases.map(\.rawValue) + AlertSound.allCases.map(\.rawValue)
        let uniqueFilenames = Set(filenames)

        for name in uniqueFilenames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
                print("[AudioManager] Missing: \(name).wav")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = (name == "tick") ? 0.4 : 0.8
                players[name] = player
            } catch {
                print("[AudioManager] Load failed \(name): \(error)")
            }
        }
    }
}
