import Foundation
#if canImport(AVFoundation)
import AVFoundation

/// Sons cozy 100% offline (`Resources/Sounds/*.wav`, ~118KB total).
///
/// - Gerados por script (sem assets externos): tons suaves com decaimento
///   exponencial, 44.1kHz 16-bit mono, pico -3dB.
/// - `AVAudioSession` em `.ambient` (não interrompe música do usuário).
/// - Falha silenciosa se o wav não estiver no bundle (nunca crasha).
public enum SoundName: String, CaseIterable {
    case tap, place, coin, photo, unlock, delete
}

public final class Sounds {
    public static let shared = Sounds()
    private var players: [SoundName: AVAudioPlayer] = [:]
    public static let enabledKey = "polyroomSoundsEnabled"
    /// Liga/desliga persistido; UI em `AboutView`.
    public var enabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }

    private init() {
        #if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        #endif
    }

    public func play(_ name: SoundName) {
        guard enabled else { return }
        do {
            if players[name] == nil {
                #if SWIFT_PACKAGE
                let bundle = Bundle.module
                #else
                let bundle = Bundle.main
                #endif
                guard let url = bundle.url(forResource: name.rawValue,
                                           withExtension: "wav",
                                           subdirectory: "Sounds") ??
                        bundle.url(forResource: "Sounds/" + name.rawValue,
                                   withExtension: "wav") ??
                        bundle.url(forResource: name.rawValue,
                                   withExtension: "wav") else { return }
                players[name] = try AVAudioPlayer(contentsOf: url)
                players[name]?.prepareToPlay()
            }
            players[name]?.currentTime = 0
            players[name]?.play()
        } catch {
            // offline e opcional: nunca quebra o app
        }
    }
}
#else
/// No-op target for hosts without AVFoundation (e.g. Linux pure-model tests).
public enum SoundName: String, CaseIterable {
    case tap, place, coin, photo, unlock, delete
}

public final class Sounds {
    public static let shared = Sounds()
    public static let enabledKey = "polyroomSoundsEnabled"
    public var enabled: Bool {
        get { UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: Self.enabledKey) }
    }
    private init() {}
    public func play(_ name: SoundName) {}
}
#endif
