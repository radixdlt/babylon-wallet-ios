import SemanticVersion

// MARK: - SemanticVersion + ExpressibleByStringLiteral
extension SemanticVersion: ExpressibleByStringLiteral {
	public init(stringLiteral value: String) {
		self.init(value)!
	}
}

// MARK: - SemanticVersion + Sendable
extension SemanticVersion: @unchecked Sendable {}
