import Foundation

extension CoreAPI {
	public struct PublicKey: Codable, Hashable {
		public private(set) var keyType: PublicKeyType

		public init(keyType: PublicKeyType) {
			self.keyType = keyType
		}

		public enum CodingKeys: String, CodingKey, CaseIterable {
			case keyType = "key_type"
		}

		// Encodable protocol methods

		public func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(keyType, forKey: .keyType)
		}
	}
}
