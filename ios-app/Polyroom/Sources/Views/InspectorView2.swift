import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Inspetor do item selecionado (`store.selectedItem`):
/// mover N/S/L/O (passo 0.25m), girar 45°, trocar cor (6 swatches),
/// duplicar e excluir.
/// (Não substitui `InspectorView` de `PlaceholderViews.swift`.)
public struct InspectorView2: View {
    @ObservedObject public var store: RoomStore

    /// Mesma ordem de `docs/CORES-PALETA.md`.
    private static let swatches: [(nome: String, hex: String)] = [
        ("Madeira", "C9A87A"),
        ("Terracota", "D08C60"),
        ("Creme", "F1E3D3"),
        ("Sálvia", "8FA98F"),
        ("Névoa", "A3B8CC"),
        ("Grafite", "6C584C"),
    ]

    public init(store: RoomStore) {
        self.store = store
    }

    public var body: some View {
        if let item = store.selectedItem {
            let id = item.id
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.catalogId).font(.headline)
                    Text(
                        String(
                            format: "x %.2f • z %.2f • %.0f° • cor %d",
                            item.x, item.z, item.rotationY, item.colorIndex
                        )
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Mover N/S/L/O — passo = snapStep (0.25m); clamp via store.move.
                VStack(spacing: 4) {
                    Button("▲ N") {
                        store.move(id: id, x: item.x, z: item.z - snapStep)
                    }
                    HStack(spacing: 4) {
                        Button("◀ O") {
                            store.move(id: id, x: item.x - snapStep, z: item.z)
                        }
                        Button("L ▶") {
                            store.move(id: id, x: item.x + snapStep, z: item.z)
                        }
                    }
                    Button("▼ S") {
                        store.move(id: id, x: item.x, z: item.z + snapStep)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                HStack {
                    Button("Girar 45°") { store.rotate(id: id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }

                // Cor: 6 swatches da paleta.
                HStack(spacing: 10) {
                    ForEach(0..<Self.swatches.count, id: \.self) { index in
                        Button {
                            store.setColor(id: id, index: index)
                        } label: {
                            Circle()
                                .fill(swatchColor(hex: Self.swatches[index].hex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            item.colorIndex % Self.swatches.count == index
                                                ? Color.accentColor : Color.secondary.opacity(0.3),
                                            lineWidth: item.colorIndex % Self.swatches.count == index ? 3 : 1
                                        )
                                )
                        }
                        .accessibilityLabel(Self.swatches[index].nome)
                    }
                }

                HStack {
                    Button("Duplicar") { _ = store.duplicate(id: id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    Button("Excluir", role: .destructive) { store.remove(id: id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding()
        } else {
            Text("Nada selecionado — toque em Colocar no catálogo.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
    }

    private func swatchColor(hex: String) -> Color {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
#endif
