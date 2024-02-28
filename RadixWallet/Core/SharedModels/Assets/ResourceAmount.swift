public struct ResourceAmount: Sendable, Hashable, Codable {
	let nominalAmount: RETDecimal
	var fiatWorth: FiatWorth?

	enum CodingKeys: CodingKey {
		case nominalAmount
	}

	init(nominalAmount: RETDecimal, fiatWorth: FiatWorth? = nil) {
		self.nominalAmount = nominalAmount
		self.fiatWorth = fiatWorth
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.nominalAmount = try container.decode(RETDecimal.self, forKey: .nominalAmount)
		self.fiatWorth = nil
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(nominalAmount, forKey: .nominalAmount)
	}

	public static let zero = ResourceAmount(nominalAmount: 0, fiatWorth: nil)

	public static func + (lhs: ResourceAmount, rhs: ResourceAmount) -> ResourceAmount {
		.init(
			nominalAmount: lhs.nominalAmount + rhs.nominalAmount,
			fiatWorth: {
				switch (lhs.fiatWorth, rhs.fiatWorth) {
				case let (lhsFiatWorth?, nil):
					lhsFiatWorth
				case let (nil, rhsFiatWorth?):
					rhsFiatWorth
				case let (lhsFiatWorth?, rhsFiatWorth?):
					lhsFiatWorth + rhsFiatWorth
				case (nil, nil):
					nil
				}
			}()
		)
	}
}
