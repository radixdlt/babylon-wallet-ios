
extension GatewayAPI {
	public struct ResourcePoolState: Decodable, Hashable, EmptyObjectDecodable {
		public let poolUnitResourceAddress: String
		/// The rest of the fields are ignored for now.

		public enum CodingKeys: String, CodingKey {
			case poolUnitResourceAddress = "pool_unit_resource_address"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.poolUnitResourceAddress = try container.decode(String.self, forKey: .poolUnitResourceAddress)
		}
	}
}
