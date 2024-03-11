import Foundation

extension CoreAPI {
	public struct PlaintextTransactionMessage: Codable, Hashable {
		/** Intended to represent the RFC 2046 MIME type of the `content`. A client cannot trust that this field is a valid mime type - in particular, the choice between `String` or `Binary` representation of the content is not enforced by this `mime_type`.  */
		public private(set) var mimeType: String
		public private(set) var content: PlaintextMessageContent

		public init(mimeType: String, content: PlaintextMessageContent) {
			self.mimeType = mimeType
			self.content = content
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case mimeType = "mime_type"
			case content
		}
	}
}
