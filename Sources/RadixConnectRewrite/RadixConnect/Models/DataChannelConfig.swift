public struct DataChannelConfig: Sendable, Hashable {
        public let isOrdered: Bool
        public let isNegotiated: Bool
        public init(isOrdered: Bool, isNegotiated: Bool) {
                self.isNegotiated = isNegotiated
                self.isOrdered = isOrdered
        }
}

public extension DataChannelConfig {
        static let `default` = Self(isOrdered: true, isNegotiated: true)
}
