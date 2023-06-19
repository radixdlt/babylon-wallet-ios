import CasePaths
import Foundation

// MARK: - I128
public struct I128: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .i128
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.i128

	// MARK: Stored properties
	// TODO: Swift does not have any 128-bit types, so, we store this as a string. We need a better solution to this.
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}

	public init(stringLiteral value: String) {
		self.init(value: value)
	}
}

extension I128 {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()
		// Decoding `value`
		// TODO: Validation is needed here to ensure that this numeric and in the range of a Signed 128 bit number
		try self.init(value: container.decode(String.self))
	}
}
