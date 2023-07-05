import CasePaths
import Foundation

// MARK: - Decimal_
public struct Decimal_: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .decimal
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.decimal

	// MARK: Stored properties
	// TODO: Convert this to a better numerical type
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}
}

extension Decimal_ {
	private var string: String {
		value
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(string)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()

		// Decoding `value`
		let string = try container.decode(String.self)
		self.init(value: string)
	}
}
