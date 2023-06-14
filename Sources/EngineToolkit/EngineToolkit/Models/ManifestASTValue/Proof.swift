import Foundation

// MARK: - Proof
public struct Proof: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .proof
	public func embedValue() -> ManifestASTValue {
		.proof(self)
	}

	// MARK: Stored properties
	public let identifier: String

	// MARK: Init

	public init(identifier: String) {
		self.identifier = identifier
	}
}

extension Proof {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, kind
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)

		try container.encode(identifier, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `identifier`
		try self.init(identifier: container.decode(String.self, forKey: .value))
	}
}
