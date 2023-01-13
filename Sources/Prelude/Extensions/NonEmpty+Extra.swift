import NonEmpty

// MARK: - NonEmpty + Sendable
extension NonEmpty: @unchecked Sendable where Element: Sendable {}
