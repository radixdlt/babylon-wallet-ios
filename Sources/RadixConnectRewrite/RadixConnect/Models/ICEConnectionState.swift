public enum ICEConnectionState: String, Sendable {
        case new
        case checking
        case connected
        case completed
        case failed
        case disconnected
        case closed
}
