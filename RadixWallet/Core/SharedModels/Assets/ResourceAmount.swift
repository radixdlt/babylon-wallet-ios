// MARK: - ResourceAmount
public struct ResourceAmount: Sendable, Hashable, Codable {
	let nominalAmount: Decimal192
	var fiatWorth: FiatWorth?

	enum CodingKeys: CodingKey {
		case nominalAmount
	}

	init(nominalAmount: Decimal192, fiatWorth: FiatWorth? = nil) {
		self.nominalAmount = nominalAmount
		self.fiatWorth = fiatWorth
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.nominalAmount = try container.decode(Decimal192.self, forKey: .nominalAmount)
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

// MARK: Comparable
extension ResourceAmount: Comparable {
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.nominalAmount < rhs.nominalAmount
	}
}
