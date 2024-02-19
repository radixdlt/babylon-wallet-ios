import Foundation

extension CoreAPI {
	public struct PlaintextMessageContent: Codable, Hashable {
		public private(set) var type: PlaintextMessageContentType

		public init(type: PlaintextMessageContentType) {
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
