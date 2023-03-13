import Foundation

// MARK: - Engine.ECPrimitive
extension Engine {
	public struct ECPrimitive: Sendable, Codable, Hashable {
		// MARK: Stored properties
		public let bytes: [UInt8]

		// MARK: Init
		public init(bytes: [UInt8]) {
			self.bytes = bytes
		}

		public init(hex: String) throws {
			// TODO: Validation of length of array
			try self.init(bytes: [UInt8](hex: hex))
		}

		// MARK: Codable

		public func encode(to encoder: Encoder) throws {
			var container: SingleValueEncodingContainer = encoder.singleValueContainer()
			try container.encode(bytes.hex())
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.singleValueContainer()
			try self.init(hex: container.decode(String.self))
		}
	}
}
