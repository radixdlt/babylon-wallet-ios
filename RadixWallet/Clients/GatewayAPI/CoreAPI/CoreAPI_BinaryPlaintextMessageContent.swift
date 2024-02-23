import Foundation

extension CoreAPI {
	public struct BinaryPlaintextMessageContent: Codable, Hashable {
		/** The hex-encoded value of a message that the author decided to provide as raw bytes. */
		public private(set) var valueHex: String

		public init(valueHex: String) {
			self.valueHex = valueHex
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case valueHex = "value_hex"
		}
	}
}
