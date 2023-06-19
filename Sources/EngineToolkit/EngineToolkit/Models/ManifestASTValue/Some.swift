import CasePaths

// MARK: - Some
public struct Some: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ManifestASTValueKind = .some
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.some

	// MARK: Stored properties

	public let value: ManifestASTValue

	public init(_ value: ManifestASTValue) {
		self.value = value
	}
}

extension Some {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case kind, value
	}

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
