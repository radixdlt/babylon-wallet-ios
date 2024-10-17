import Foundation

extension CoreAPI {
	struct BinaryPlaintextMessageContent: Codable, Hashable {
		/** The hex-encoded value of a message that the author decided to provide as raw bytes. */
		private(set) var valueHex: String

		init(valueHex: String) {
			self.valueHex = valueHex
		}

		enum CodingKeys: String, CodingKey, CaseIterable {
			case valueHex = "value_hex"
		}
	}
}
