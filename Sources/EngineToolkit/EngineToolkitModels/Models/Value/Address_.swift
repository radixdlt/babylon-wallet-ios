import Foundation

// MARK: - Address_
public struct Address_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .address
	public func embedValue() -> ManifestASTValue {
		.address(self)
	}

	// MARK: Stored properties
	public let address: String

	// MARK: Init

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}
}

extension Address_ {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case address, type
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(String(address), forKey: .address)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `address`
		try self.init(
			address: container.decode(String.self, forKey: .address)
		)
	}
}
