import Foundation

extension CoreAPI {
	public struct BinaryPlaintextMessageContent: Codable, Hashable {
		public private(set) var type: PlaintextMessageContentType
		/** The hex-encoded value of a message that the author decided to provide as raw bytes. */
		public private(set) var valueHex: String

		public init(type: PlaintextMessageContentType, valueHex: String) {
			self.type = type
			self.valueHex = valueHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case valueHex = "value_hex"
		}
	}
}
