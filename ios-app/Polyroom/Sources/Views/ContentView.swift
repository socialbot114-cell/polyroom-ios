import Foundation

#if canImport(SwiftUI)
import SwiftUI
#if canImport(SceneKit)
import SceneKit
#endif
#if canImport(Metal)
import Metal
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

extension Room {
    var titulo: String {
        switch self {
        case .quarto: return "Quarto"
        case .cozinha: return "Cozinha"
        case .sala: return "Sala"
        }
    }

    var icone: String {
        switch self {
        case .quarto: return "bed.double.fill"
        case .cozinha: return "fork.knife"
        case .sala: return "sofa.fill"
        }
    }
}

/// Tela principal do MVP: header com os 3 quartos + moedas + foto + Sobre,
/// `RoomSceneView2` no centro, `InspectorView2` colapsável e `CatalogView2`
/// fixo embaixo.
///
/// Não altera `RoomStore`/`CatalogView2`/`InspectorView2`/`RoomSceneView2`:
/// os ganhos de moeda (+5 por móvel novo) são detectados via
/// `.onReceive(store.$save)` comparando a contagem total de itens.
public struct ContentView: View {
    @ObservedObject public var store: RoomStore
    @ObservedObject public var coins: CoinsStore

    @State private var inspectorOpen = true
    @State private var showAbout = false
    @State private var noticeText = ""
    @State private var showNotice = false
    @State private var lastItemCount = 0

    public init(store: RoomStore, coins: CoinsStore) {
        self.store = store
        self.coins = coins
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            RoomSceneView2(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            DisclosureGroup("Inspetor", isExpanded: $inspectorOpen) {
                InspectorView2(store: store)
            }
            .padding(.horizontal)
            Divider()
            CatalogView2(store: store)
                .frame(height: 300)
        }
        .onAppear {
            lastItemCount = Self.totalItems(store.save)
        }
        .onReceive(store.$save) { newSave in
            let n = Self.totalItems(newSave)
            // Qualquer caminho que adicione item (botão "Colocar",
            // duplicar) rende +5 por item novo; remover não tira moedas.
            if n > lastItemCount {
                for _ in 0..<(n - lastItemCount) {
                    coins.earnPlace()
                }
            }
            lastItemCount = n
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .alert(isPresented: $showNotice) {
            Alert(title: Text("Polyroom"), message: Text(noticeText))
        }
    }

    // MARK: - Header (3 quartos + moedas + foto + Sobre)

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Polyroom")
                    .font(.headline)
                Spacer()
                Text("🪙 \(coins.coins)")
                    .font(.subheadline)
                    .accessibilityLabel("cozyCoins: \(coins.coins)")
                Button {
                    takeSnapshot()
                } label: {
                    Label("Foto", systemImage: "camera")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Sobre")
            }
            .padding(.horizontal)

            HStack(spacing: 8) {
                ForEach(Room.allCases, id: \.self) { room in
                    roomButton(room)
                }
            }
            .padding(.horizontal)

            Text("\(store.items.count) itens • snap 0,25 m • save offline")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    private func roomButton(_ room: Room) -> some View {
        let selected = store.currentRoom == room
        let unlocked = coins.isUnlocked(room)
        return Button {
            if unlocked {
                store.switchRoom(room)
            } else if coins.unlock(room) {
                store.switchRoom(room)
                showNotice("\(room.titulo) desbloqueada por \(coins.cost(for: room)) 🪙!")
            } else {
                let falta = coins.cost(for: room) - coins.coins
                showNotice(
                    "Faltam \(falta) 🪙 para a \(room.titulo). Decore (+5) e tire fotos (+10) para ganhar!"
                )
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: unlocked ? room.icone : "lock.fill")
                Text(room.titulo)
                if !unlocked {
                    Text("· \(coins.cost(for: room))🪙")
                        .font(.caption2)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(selected ? .accentColor : .secondary)
        .fontWeight(selected ? .semibold : .regular)
    }

    // MARK: - Snapshot (foto da cena)

    private func showNotice(_ text: String) {
        noticeText = text
        showNotice = true
    }

    private static func totalItems(_ save: RoomSave) -> Int {
        save.rooms.values.reduce(0) { $0 + $1.count }
    }

    private func takeSnapshot() {
        #if canImport(SceneKit) && canImport(UIKit)
        guard let image = renderPhoto() else {
            showNotice("Não foi possível renderizar a foto.")
            return
        }
        var extras: [String] = []
        if let url = savePNGToDocuments(image: image) {
            extras.append("Arquivo: \(url.lastPathComponent).")
        }
        // Álbum de fotos (pede permissão na 1ª vez; exige
        // NSPhotoLibraryAddUsageDescription no Info.plist do app).
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        coins.earnPhoto()
        showNotice("Foto salva! +\(CoinsStore.photoReward) 🪙 " + extras.joined(separator: " "))
        #elseif canImport(SceneKit) && canImport(AppKit)
        guard let image = renderPhoto() else {
            showNotice("Não foi possível renderizar a foto.")
            return
        }
        var extras: [String] = []
        if let url = savePNGToDocuments(image: image) {
            extras.append("Arquivo: \(url.lastPathComponent).")
        }
        coins.earnPhoto()
        showNotice("Foto salva! +\(CoinsStore.photoReward) 🪙 " + extras.joined(separator: " "))
        #else
        showNotice("Foto indisponível: SceneKit não encontrado.")
        #endif
    }

    #if canImport(SceneKit) && canImport(UIKit)
    /// Renderiza a cena atual em 1024x1024.
    /// Caminho 1 (confiável headless): `SCNRenderer.snapshot` com a câmera
    /// `camera_iso` do `RoomSceneBuilder`. Caminho 2 (fallback, o pedido no
    /// MVP): `SCNView.snapshot` → UIImage.
    private func renderPhoto(
        size: CGSize = CGSize(width: 1024, height: 1024)
    ) -> UIImage? {
        let scene = RoomSceneBuilder.makeScene(store: store)
        #if canImport(Metal)
        if let device = MTLCreateSystemDefaultDevice() {
            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = scene
            renderer.pointOfView = scene.rootNode.childNode(
                withName: "camera_iso", recursively: true
            )
            let img = renderer.snapshot(
                atTime: 0, with: size, antialiasingMode: .multisampling4X
            )
            if img.size.width > 1, img.size.height > 1 {
                return img
            }
        }
        #endif
        let view = SCNView(frame: CGRect(origin: .zero, size: size))
        view.scene = scene
        view.layoutIfNeeded()
        return view.snapshot()
    }

    /// Salva o PNG em Documents (funciona offline, sem permissão de Fotos).
    private func savePNGToDocuments(image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let dir = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        let url = dir.appendingPathComponent(
            "polyroom_foto_\(Int(Date().timeIntervalSince1970)).png"
        )
        guard (try? data.write(to: url, options: .atomic)) != nil else {
            return nil
        }
        return url
    }
    #elseif canImport(SceneKit) && canImport(AppKit)
    private func renderPhoto(
        size: CGSize = CGSize(width: 1024, height: 1024)
    ) -> NSImage? {
        let scene = RoomSceneBuilder.makeScene(store: store)
        #if canImport(Metal)
        if let device = MTLCreateSystemDefaultDevice() {
            let renderer = SCNRenderer(device: device, options: nil)
            renderer.scene = scene
            renderer.pointOfView = scene.rootNode.childNode(
                withName: "camera_iso", recursively: true
            )
            let img = renderer.snapshot(
                atTime: 0, with: size, antialiasingMode: .multisampling4X
            )
            if img.size.width > 1, img.size.height > 1 {
                return img
            }
        }
        #endif
        let view = SCNView(frame: CGRect(origin: .zero, size: size))
        view.scene = scene
        view.layoutIfNeeded()
        return view.snapshot()
    }

    private func savePNGToDocuments(image: NSImage) -> URL? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:])
        else { return nil }
        let dir = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]
        let url = dir.appendingPathComponent(
            "polyroom_foto_\(Int(Date().timeIntervalSince1970)).png"
        )
        guard (try? data.write(to: url, options: .atomic)) != nil else {
            return nil
        }
        return url
    }
    #endif
}

/// Folha "Sobre" com o crédito obrigatório do asset base.
private struct AboutView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Polyroom")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Fechar") { presentationMode.wrappedValue.dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Text("Decore quartos low-poly offline: coloque móveis, mova no grid, gire, pinte e salve tudo no aparelho.")
                .font(.body)
                .foregroundColor(.secondary)
            Divider()
            Text("Créditos")
                .font(.headline)
            Text("Baseado em Low-poly rooms por javiloz1604 (BlendSwap 24957), CC-BY.")
                .font(.body)
            Text("Paleta cozy de 6 cores • sala 6×6 m • snap 0,25 m.")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: RoomStore(autosaveEnabled: false), coins: CoinsStore())
    }
}
#endif
#endif
