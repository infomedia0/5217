/// A first click always silences; only a subsequent click requests confirmation.
/// Timer changes and cancellation start a fresh two-click sequence.
struct StopControl {
    enum Action { case silence, requestConfirmation }
    private(set) var armed = false
    mutating func press() -> Action {
        if armed { return .requestConfirmation }
        armed = true
        return .silence
    }
    mutating func reset() { armed = false }
}
