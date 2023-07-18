// MARK: - Identified + Sendable
extension Identified: @unchecked Sendable where Value: Sendable, ID: Sendable {}

// MARK: - Identified + Equatable
extension Identified: @unchecked Equatable where Value: Equatable, ID: Equatable {}
