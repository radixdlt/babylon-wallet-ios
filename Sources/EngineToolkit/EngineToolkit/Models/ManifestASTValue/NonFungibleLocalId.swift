import Foundation
import Tagged

// MARK: - NonFungibleLocalId
public struct NonFungibleLocalId: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
	public static let kind: ManifestASTValueKind = .nonFungibleLocalId
	public func embedValue() -> ManifestASTValue {
		.nonFungibleLocalId(self)
	}

	let value: String

	public init(value: String) {
		self.value = value
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(value: value)
	}
}

extension NonFungibleLocalId {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case value, kind
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)
		try container.encode(self.value, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		self = try .init(value: container.decode(String.self, forKey: .value))
	}
}
