import CasePaths
import Foundation

// MARK: - NonFungibleLocalId
public struct NonFungibleLocalId: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
	public static let kind: ManifestASTValueKind = .nonFungibleLocalId
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.nonFungibleLocalId

	public let value: String

	public init(value: String) {
		self.value = value
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(value: value)
	}
}

extension NonFungibleLocalId {
	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()
		try self.init(value: container.decode(String.self))
	}
}
