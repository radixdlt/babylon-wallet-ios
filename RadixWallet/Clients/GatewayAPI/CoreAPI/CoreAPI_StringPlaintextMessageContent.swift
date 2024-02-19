import Foundation

extension CoreAPI {
	public struct StringPlaintextMessageContent: Codable, Hashable {
		public private(set) var type: PlaintextMessageContentType
		/** The value of a message that the author decided to provide as a UTF-8 string. */
		public private(set) var value: String

		public init(type: PlaintextMessageContentType, value: String) {
			self.type = type
			self.value = value
		}
	}
}
