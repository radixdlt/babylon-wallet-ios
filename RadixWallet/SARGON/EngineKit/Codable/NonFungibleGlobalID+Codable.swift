

extension NonFungibleGlobalId: Codable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(asStr())
	}

	public convenience init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let raw = try container.decode(String.self)
		try self.init(nonFungibleGlobalId: raw)
	}
}
