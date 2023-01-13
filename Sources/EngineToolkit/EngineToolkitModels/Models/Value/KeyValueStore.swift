import Foundation

// MARK: - KeyValueStore
public struct KeyValueStore: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ValueKind = .keyValueStore
	public func embedValue() -> Value_ {
		.keyValueStore(self)
	}

	// MARK: Stored properties
	public let identifier: RENodeIdentifier

	// MARK: Init
	public init(identifier: RENodeIdentifier) {
		self.identifier = identifier
	}

	public init(hex: String) throws {
		try self.init(identifier: .init(hex: hex))
	}
}

public extension KeyValueStore {
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
		try self.init(identifier: container.decode(RENodeIdentifier.self, forKey: .identifier))
	}
}
