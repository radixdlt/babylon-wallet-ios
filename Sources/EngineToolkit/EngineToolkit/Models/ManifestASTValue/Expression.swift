import Foundation

// MARK: - Expression
public struct Expression: ValueProtocol, Sendable, Codable, Hashable {
	/// Based on https://github.com/radixdlt/radixdlt-scrypto/blob/9ecc54ee658c77e5fc4e6776b06286c01ed70a35/radix-engine-common/src/data/manifest/model/manifest_expression.rs#L11
	public enum ManifestExpression: String, Sendable, Codable, Hashable {
		case entireWorktop = "ENTIRE_WORKTOP"
		case entireAuthZone = "ENTIRE_AUTH_ZONE"
	}

	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .expression
	public func embedValue() -> ManifestASTValue {
		.expression(self)
	}

	// MARK: Stored properties
	public let value: ManifestExpression

	// MARK: Init

	public init(value: ManifestExpression) {
		self.value = value
	}
}

extension Expression {
	// MARK: CodingKeys
	private enum CodingKeys: String, CodingKey {
		case value, kind
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(Self.kind, forKey: .kind)

		try container.encode(value, forKey: .value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let kind: ManifestASTValueKind = try container.decode(ManifestASTValueKind.self, forKey: .kind)
		if kind != Self.kind {
			throw InternalDecodingFailure.valueTypeDiscriminatorMismatch(expected: Self.kind, butGot: kind)
		}

		// Decoding `value`
		try self.init(value: container.decode(ManifestExpression.self, forKey: .value))
	}
}
