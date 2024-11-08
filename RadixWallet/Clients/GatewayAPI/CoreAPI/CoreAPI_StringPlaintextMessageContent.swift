import Foundation

extension CoreAPI {
	struct StringPlaintextMessageContent: Codable, Hashable {
		/** The value of a message that the author decided to provide as a UTF-8 string. */
		private(set) var value: String

		init(value: String) {
			self.value = value
		}
	}
}
