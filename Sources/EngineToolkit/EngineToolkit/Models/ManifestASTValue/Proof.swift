import CasePaths
import Foundation

// MARK: - Proof
public struct Proof: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .proof
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.proof

	// MARK: Stored properties
	public let identifier: String

	// MARK: Init

	public init(_ identifier: String) {
		self.identifier = identifier
	}
}

extension Proof {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(identifier)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.singleValueContainer()

		// Decoding `identifier`
		try self.init(container.decode(String.self))
	}
}
