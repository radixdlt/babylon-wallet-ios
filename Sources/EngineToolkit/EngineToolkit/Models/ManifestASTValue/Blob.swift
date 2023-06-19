import CasePaths
import Prelude

// MARK: - Blob
public struct Blob: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .blob
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.blob

	// MARK: Stored properties
	public let bytes: [UInt8]

	// MARK: Init

	public init(bytes: [UInt8]) {
		self.bytes = bytes
	}

	public init(hex: String) throws {
		// TODO: Validation of length of Hash
		try self.init(bytes: [UInt8](hex: hex))
	}

	public init(data: Data) {
		self.init(bytes: [UInt8](data))
	}
}

extension Blob {
	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(bytes.hex())
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		// Decoding `hash`
		try self.init(
			hex: container.decode(String.self)
		)
	}
}
