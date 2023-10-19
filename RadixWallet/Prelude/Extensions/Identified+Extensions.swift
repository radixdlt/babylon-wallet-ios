// MARK: - Identified + Sendable
extension Identified: @unchecked Sendable where Value: Sendable, ID: Sendable {}
