import Foundation
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
    /// `false` = mudo (persistido p/ futura chave em Settings).
    public var enabled = true

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    public func play(_ name: SoundName) {
        guard enabled else { return }
        do {
            if players[name] == nil {
                guard let url = Bundle.main.url(forResource: name.rawValue,
                                                withExtension: "wav",
                                                subdirectory: "Sounds") ??
                      Bundle.main.url(forResource: "Sounds/" + name.rawValue,
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
