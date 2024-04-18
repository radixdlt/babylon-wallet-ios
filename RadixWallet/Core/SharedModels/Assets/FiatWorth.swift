// MARK: - FiatWorth
public struct FiatWorth: Sendable, Hashable {
	enum Worth: Sendable, Hashable {
		case known(Decimal192)
		case unknown
	}

	var isVisible: Bool
	let worth: Worth
	var currency: FiatCurrency

	static func unknownWorth(isVisible: Bool, currency: FiatCurrency) -> Self {
		.init(isVisible: isVisible, worth: .unknown, currency: currency)
	}
}

extension FiatWorth {
	public static func + (lhs: Self, rhs: Self) -> Self {
		.init(
			isVisible: lhs.isVisible,
			worth: lhs.worth + rhs.worth,
			currency: lhs.currency
		)
	}
}

extension FiatWorth.Worth {
	public static func + (lhs: Self, rhs: Self) -> Self {
		switch (lhs, rhs) {
		case let (.known(lhsValue), .known(rhsValue)):
			.known(lhsValue + rhsValue)
		default:
			.unknown
		}
	}
}

extension FiatWorth.Worth {
	static let zero: Self = .known(.zero)

	var value: Decimal192? {
		if case let .known(value) = self {
			return value
		}
		return nil
	}

	var isUnknown: Bool {
		if case .unknown = self {
			return true
		}
		return false
	}
}

// MARK: - FiatWorth + Comparable
extension FiatWorth: Comparable {
	public static func < (
		lhs: Self,
		rhs: Self
	) -> Bool {
		lhs.worth < rhs.worth
	}
}

// MARK: - FiatWorth.Worth + Comparable
extension FiatWorth.Worth: Comparable {
	public static func < (
		lhs: Self,
		rhs: Self
	) -> Bool {
		switch (lhs, rhs) {
		case let (.known(lhsValue), .known(rhsValue)):
			lhsValue < rhsValue
		case (.known, .unknown):
			false
		case (.unknown, .known):
			true
		case (.unknown, .unknown):
			false
		}
	}
}

extension FiatWorth {
	private static let hiddenValue = "• • • •"
	private static let unknownValue = "—"

	func currencyFormatted(applyCustomFont: Bool = false) -> AttributedString {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = currency.currencyCode

		let value = worth.value ?? .zero // Zero for the unknown case, just to do to the base formatting

		let formattedValue = {
			let double = value.asDouble
			guard let value = formatter.string(for: double) else {
				// Good enough fallback
				return "\(currency.currencyCode)\(value.formattedPlain())"
			}
			return value
		}()

		let currencySymbol = formatter.currencySymbol ?? currency.currencyCode
		let symbolRange = formattedValue.range(of: currencySymbol)

		var attributedString: AttributedString = {
			guard isVisible, case .known = worth else {
				let placeholder = isVisible ? Self.unknownValue : Self.hiddenValue
				if let symbolRange, symbolRange.lowerBound == formattedValue.startIndex {
					return AttributedString(currencySymbol + " " + placeholder)
				} else {
					return AttributedString(placeholder + " " + currencySymbol)
				}
			}

			return AttributedString(formattedValue)
		}()

		if !isVisible || worth.isUnknown || value == .zero {
			attributedString.foregroundColor = .app.gray3
		}

		guard applyCustomFont else {
			return attributedString
		}

		// Apply main font size to entire string
		attributedString.font = .app.sheetTitle
		attributedString.kern = -0.5

		let decimalSeparator = formatter.decimalSeparator ?? "."

		if let symbolRange = attributedString.range(of: currencySymbol) {
			attributedString[symbolRange].font = .app.sectionHeader
			attributedString[symbolRange].kern = 0.0
		}

		if let decimalRange = attributedString.range(of: decimalSeparator) {
			attributedString[decimalRange.lowerBound...].font = .app.sectionHeader
			attributedString[decimalRange.lowerBound...].kern = 0.0
		}

		return attributedString
	}
}

extension FiatCurrency {
	var currencyCode: String {
		switch self {
		case .usd:
			"USD"
		}
	}
}
