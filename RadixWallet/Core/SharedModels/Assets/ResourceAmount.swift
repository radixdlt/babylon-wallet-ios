// MARK: - ResourceAmount
enum ResourceAmount: Sendable, Hashable, Codable {
	case exact(ExactResourceAmount)
	case atLeast(ExactResourceAmount)
	case atMost(ExactResourceAmount)
	case between(minimum: ExactResourceAmount, maximum: ExactResourceAmount)
	case unknown

	init(bounds: SimpleFungibleResourceBounds) {
		switch bounds {
		case let .exact(amount):
			self = .exact(.init(nominalAmount: amount))
		case let .atLeast(amount):
			self = .atLeast(.init(nominalAmount: amount))
		case let .atMost(amount):
			self = .atMost(.init(nominalAmount: amount))
		case let .between(minAmount, maxAmount):
			self = .between(
				minimum: .init(nominalAmount: minAmount),
				maximum: .init(nominalAmount: maxAmount)
			)
		case .unknownAmount:
			self = .unknown
		}
	}
}

extension ResourceAmount {
	var exactAmount: ExactResourceAmount? {
		switch self {
		case let .exact(amount):
			amount
		default:
			nil
		}
	}

	var isGreaterThanZero: Bool {
		switch self {
		case let .exact(amount),
		     let .atLeast(amount):
			amount.nominalAmount > 0
		case let .between(minAmount, maxAmount):
			minAmount.nominalAmount > 0
		case .atMost, .unknown:
			false
		}
	}

	var debugDescription: String {
		switch self {
		case let .exact(amount):
			amount.nominalAmount.formatted()
		case let .atLeast(amount):
			"At least \(amount.nominalAmount.formatted())"
		case let .atMost(amount):
			"No more than \(amount.nominalAmount.formatted())"
		case let .between(minAmount, maxAmount):
			"Min: \(minAmount.nominalAmount.formatted()); Max: \(maxAmount.nominalAmount.formatted())"
		case .unknown:
			"Unknown"
		}
	}

	func adjustedNominalAmount(_ adjust: (Decimal192) -> Decimal192) -> Self {
		switch self {
		case let .exact(amount):
			return .exact(.init(nominalAmount: adjust(amount.nominalAmount)))
		case let .atLeast(amount):
			return .atLeast(.init(nominalAmount: adjust(amount.nominalAmount)))
		case let .atMost(amount):
			return .atMost(.init(nominalAmount: adjust(amount.nominalAmount)))
		case let .between(minAmount, maxAmount):
			let min = adjust(minAmount.nominalAmount)
			let max = adjust(maxAmount.nominalAmount)
			return .between(
				minimum: .init(nominalAmount: min),
				maximum: .init(nominalAmount: max)
			)
		case .unknown:
			return .unknown
		}
	}
}

// MARK: - ExactResourceAmount
struct ExactResourceAmount: Sendable, Hashable, Codable {
	let nominalAmount: Decimal192
	var fiatWorth: FiatWorth?

	enum CodingKeys: CodingKey {
		case nominalAmount
	}

	init(nominalAmount: Decimal192, fiatWorth: FiatWorth? = nil) {
		self.nominalAmount = nominalAmount
		self.fiatWorth = fiatWorth
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.nominalAmount = try container.decode(Decimal192.self, forKey: .nominalAmount)
		self.fiatWorth = nil
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(nominalAmount, forKey: .nominalAmount)
	}

	static let zero = ExactResourceAmount(nominalAmount: 0, fiatWorth: nil)

	static func + (lhs: ExactResourceAmount, rhs: ExactResourceAmount) -> ExactResourceAmount {
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
extension ExactResourceAmount: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.nominalAmount < rhs.nominalAmount
	}
}

// MARK: - ResourceAmount + Comparable
extension ResourceAmount: Comparable {
	static func < (lhs: Self, rhs: Self) -> Bool {
		(lhs.exactAmount ?? .zero).nominalAmount < (rhs.exactAmount ?? .zero).nominalAmount
	}
}
