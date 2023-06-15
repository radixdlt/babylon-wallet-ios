import CasePaths

// MARK: - Ok
public struct Ok: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ManifestASTValueKind = .ok
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.ok

	// MARK: Stored properties

	public let value: ManifestASTValue

	public init(_ value: ManifestASTValue) {
		self.value = value
	}
}

extension Ok {
	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()
		try self.init(container.decode(ManifestASTValue.self))
	}
}
