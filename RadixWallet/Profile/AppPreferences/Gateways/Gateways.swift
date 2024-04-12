

extension Profile {}

extension Gateways {
	private enum CodingKeys: String, CodingKey {
		case current
		case all = "saved"
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let urlOfCurrent = try container.decode(URL.self, forKey: .current)
		let all = try container.decode(IdentifiedArrayOf<Gateway>.self, forKey: .all)
		guard let current = all.first(where: { $0.id == urlOfCurrent }) else {
			struct DiscrepancyCurrentNotFoundAmongstSavedGateways: Swift.Error {}
			throw DiscrepancyCurrentNotFoundAmongstSavedGateways()
		}
		var other = all
		other.remove(id: current.id)
		try self.init(current: current, other: other)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(current.url, forKey: .current)
		try container.encode(all, forKey: .all)
	}
}

extension Gateways {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"current": current,
				"other": other,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		current: \(current),
		other: \(other)
		"""
	}
}
