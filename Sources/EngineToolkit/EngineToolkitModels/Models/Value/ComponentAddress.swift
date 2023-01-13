import Foundation

// MARK: - ComponentAddress
public struct ComponentAddress: ValueProtocol, Sendable, Codable, Hashable, AddressProtocol, CallMethodReceiverCompatible {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .componentAddress
	public func embedValue() -> Value_ {
		.componentAddress(self)
	}

	// MARK: Stored properties
	public let address: String

	// MARK: Init

	public init(address: String) {
		// TODO: Perform some simple Bech32m validation.
		self.address = address
	}
}

public extension ComponentAddress {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case address, type
	}

	// MARK: Codable
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .type)

		try container.encode(String(address), forKey: .address)
	}

	init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ValueKind = try container.decode(ValueKind.self, forKey: .type)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `address`
		try self.init(address: container.decode(String.self, forKey: .address))
	}
}

public extension ComponentAddress {
	func toCallMethodReceiver() -> CallMethodReceiver {
		.componentAddress(self)
	}
}
