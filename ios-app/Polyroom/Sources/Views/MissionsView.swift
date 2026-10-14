import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Progress view for the 12 local cozy missions.
public struct MissionsView: View {
    @ObservedObject private var store: RoomStore
    @ObservedObject private var missions: MissionStore

    public init(store: RoomStore, missions: MissionStore) {
        self.store = store
        self.missions = missions
    }

    public var body: some View {
        NavigationView {
            List(MissionStore.all) { mission in
                let progress = missions.progress(of: mission.id, in: store.save) { catalogId in
                    store.catalog.items.first(where: { $0.id == catalogId })?.categoria
                }
                let complete = missions.claimed.contains(mission.id)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(mission.title)
                            .font(.headline)
                        Spacer(minLength: 8)
                        Label("+\(mission.reward)", systemImage: complete ? "checkmark.seal.fill" : "sparkles")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(complete ? Color.green : Color.accentColor)
                    }
                    Text(mission.goalDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ProgressView(value: Double(progress.current), total: Double(max(progress.goal, 1)))
                    Text(complete ? "Concluída" : "\(progress.current) de \(progress.goal)")
                        .font(.caption)
                        .foregroundStyle(complete ? Color.green : Color.secondary)
                }
                .padding(.vertical, 5)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(mission.title), \(mission.goalDescription), \(complete ? "concluída" : "\(progress.current) de \(progress.goal)"), recompensa \(mission.reward) moedas")
            }
            .navigationTitle("Missões cozy")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}
#endif
