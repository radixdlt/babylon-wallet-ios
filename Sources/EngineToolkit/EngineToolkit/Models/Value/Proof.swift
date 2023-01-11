import Foundation

// MARK: - Proof
public struct Proof: ValueProtocol, Sendable, Codable, Hashable, IdentifierConvertible {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .proof
	public func embedValue() -> Value_ {
		.proof(self)
	}

	// MARK: Stored properties
	public let identifier: TransientIdentifier

	// MARK: Init

	public init(identifier: TransientIdentifier) {
		self.identifier = identifier
	}
}

public extension Proof {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case identifier, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(identifier, forKey: .identifier)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `identifier`
		try self.init(identifier: container.decode(TransientIdentifier.self, forKey: .identifier))
	}
}
