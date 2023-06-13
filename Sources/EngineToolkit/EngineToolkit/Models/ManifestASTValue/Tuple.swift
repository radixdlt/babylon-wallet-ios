import Foundation

// MARK: - Tuple
public struct Tuple: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByRadixEngineValues {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .tuple
	public func embedValue() -> ManifestASTValue {
		.tuple(self)
	}

	// MARK: Stored properties
	public let fields: [ManifestASTValue]

	// MARK: Init

	public init(values: [ManifestASTValue]) {
		self.fields = values
	}
}

extension Tuple {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case fields, kind
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)

		try container.encode(fields, forKey: .fields)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `elements`
		// TODO: Validate that all elements are of type `elementType`
		try self.init(values: container.decode([ManifestASTValue].self, forKey: .fields))
	}
}
