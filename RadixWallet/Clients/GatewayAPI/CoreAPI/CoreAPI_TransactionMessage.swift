extension CoreAPI {
	public struct TransactionMessage: Codable, Hashable {
		public private(set) var type: TransactionMessageType

		public init(type: TransactionMessageType) {
			self.type = type
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case type
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(type, forKey: .type)
		}
	}
}
