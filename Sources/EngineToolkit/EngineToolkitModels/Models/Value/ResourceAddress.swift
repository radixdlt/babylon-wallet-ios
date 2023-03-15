import Foundation

// MARK: - ResourceAddress
public struct ResourceAddress: ValueProtocol, Sendable, Codable, Hashable, AddressProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .resourceAddress
	public func embedValue() -> ManifestASTValue {
		.resourceAddress(self)
	}

	// MARK: Stored properties
	public let address: String

	// MARK: Init

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}
}

extension ResourceAddress {
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
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `address`
		try self.init(
			address: container.decode(String.self, forKey: .address)
		)
	}
}
