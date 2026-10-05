import Foundation

/// Grid step em metros (0.25m).
public let snapStep: Float = 0.25

/// Half-extent do quarto 6x6m centrado na origem: x,z ∈ [-3, 3].
public let roomHalfExtent: Float = 3.0

/// Arredonda para o grid de 0.25m.
public func snap(_ v: Float) -> Float {
    (v / snapStep).rounded() * snapStep
}

/// Clamp para o quarto 6x6m.
public func clampRoom(_ v: Float, halfExtent: Float = roomHalfExtent) -> Float {
    min(max(v, -halfExtent), halfExtent)
}

/// Snap + clamp combinados (ordem: snap depois clamp).
public func snapClamp(_ v: Float, halfExtent: Float = roomHalfExtent) -> Float {
    clampRoom(snap(v), halfExtent: halfExtent)
}
