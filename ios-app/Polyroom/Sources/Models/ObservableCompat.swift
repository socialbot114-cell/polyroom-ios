import Foundation

// Lightweight declarations so the pure model target also builds on hosts
// without Combine (e.g. Linux CI). Apple platforms use Combine's real types.
#if !canImport(Combine)
public protocol ObservableObject: AnyObject {}

@propertyWrapper
public struct Published<Value> {
    public var wrappedValue: Value
    public var projectedValue: Published<Value> { self }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}
#endif
