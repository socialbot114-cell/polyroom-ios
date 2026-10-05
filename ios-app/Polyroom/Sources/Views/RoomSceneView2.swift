import Foundation

#if canImport(SwiftUI) && canImport(SceneKit)
import SwiftUI
import SceneKit

#if canImport(UIKit)
import UIKit

/// SCNView embrulhada para SwiftUI (iOS). Reconstrói a cena via
/// `RoomSceneBuilder` a cada `updateUIView`.
public struct RoomSceneView2: UIViewRepresentable {
    @ObservedObject public var store: RoomStore

    public init(store: RoomStore) {
        self.store = store
    }

    public func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = UIColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1)
        view.scene = RoomSceneBuilder.makeScene(store: store)
        return view
    }

    public func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = RoomSceneBuilder.makeScene(store: store)
    }
}
#elseif canImport(AppKit)
import AppKit

/// SCNView embrulhada para SwiftUI (macOS). Reconstrói a cena via
/// `RoomSceneBuilder` a cada `updateNSView`.
public struct RoomSceneView2: NSViewRepresentable {
    @ObservedObject public var store: RoomStore

    public init(store: RoomStore) {
        self.store = store
    }

    public func makeNSView(context: Context) -> SCNView {
        let view = SCNView()
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = NSColor(srgbRed: 0.96, green: 0.94, blue: 0.90, alpha: 1)
        view.scene = RoomSceneBuilder.makeScene(store: store)
        return view
    }

    public func updateNSView(_ scnView: SCNView, context: Context) {
        scnView.scene = RoomSceneBuilder.makeScene(store: store)
    }
}
#endif

#elseif canImport(SwiftUI)
import SwiftUI

/// Fallback sem SceneKit (ex.: preview onde SceneKit não linka).
public struct RoomSceneView2: View {
    public var store: RoomStore?

    public init(store: RoomStore? = nil) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            Color(.sRGB, red: 0.96, green: 0.94, blue: 0.90, opacity: 1)
            Text("3D indisponível — SceneKit não encontrado")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
#endif
