
extension GatewayAPI {
	struct ResourcePoolState: Decodable, Hashable, EmptyObjectDecodable {
		let poolUnitResourceAddress: String
		/// The rest of the fields are ignored for now.

		enum CodingKeys: String, CodingKey {
			case poolUnitResourceAddress = "pool_unit_resource_address"
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.poolUnitResourceAddress = try container.decode(String.self, forKey: .poolUnitResourceAddress)
		}
	}
}
