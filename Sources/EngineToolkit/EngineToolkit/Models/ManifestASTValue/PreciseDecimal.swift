import CasePaths
import Foundation

// MARK: - PreciseDecimal
public struct PreciseDecimal: ValueProtocol, Sendable, Codable, Hashable, ExpressibleByStringLiteral, ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .preciseDecimal
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.preciseDecimal

	// MARK: Stored properties
	// TODO: Convert this to a better numerical type
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}

	public init(integerLiteral value: Int) {
		self.init(value: "\(value)")
	}

	public init(stringLiteral value: StringLiteralType) {
		self.init(value: value)
	}

	// FIXME: investigate which `Locale` is being used here.. might need to use `NumberFormatter`, i.e.
	// does `"\(value)"` use "," or "." for decimals, and what does Scrypto expect?
	public init(floatLiteral value: Double) {
		self.init(value: "\(value)")
	}
}

extension PreciseDecimal {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(String(value))
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()
		// Decoding `value`
		try self.init(value: container.decode(String.self))
	}
}
