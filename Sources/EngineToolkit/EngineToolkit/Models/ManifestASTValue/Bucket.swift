import CasePaths
import Foundation

// MARK: - Bucket
public struct Bucket: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .bucket
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.bucket

	// MARK: Stored properties
	public let value: String

	// MARK: Init

	public init(value: String) {
		self.value = value
	}
}

extension Bucket {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(value)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()

		// Decoding `identifier`
		try self.init(
			value: container.decode(String.self)
		)
	}
}
