import Foundation

extension CoreAPI {
	public struct PlaintextTransactionMessage: Codable, Hashable {
		public private(set) var type: TransactionMessageType
		/** Intended to represent the RFC 2046 MIME type of the `content`. A client cannot trust that this field is a valid mime type - in particular, the choice between `String` or `Binary` representation of the content is not enforced by this `mime_type`.  */
		public private(set) var mimeType: String
		public private(set) var content: PlaintextMessageContent

		public init(type: TransactionMessageType, mimeType: String, content: PlaintextMessageContent) {
			self.type = type
			self.mimeType = mimeType
			self.content = content
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
			case mimeType = "mime_type"
			case content
		}
	}
}
