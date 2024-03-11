import Foundation

extension CoreAPI {
	public struct StringPlaintextMessageContent: Codable, Hashable {
		/** The value of a message that the author decided to provide as a UTF-8 string. */
		public private(set) var value: String

		public init(value: String) {
			self.value = value
		}
	}
}
