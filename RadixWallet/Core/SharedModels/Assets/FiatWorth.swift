// MARK: - FiatWorth
public struct FiatWorth: Sendable, Hashable, Codable {
	var isVisible: Bool
	let worth: Double
	let currency: FiatCurrency
}

extension FiatWorth {
	public static func + (lhs: FiatWorth, rhs: FiatWorth) -> FiatWorth {
		.init(
			isVisible: lhs.isVisible,
			worth: lhs.worth + rhs.worth,
			currency: lhs.currency
		)
	}
}

extension FiatWorth {
	func currencyFormatted(applyCustomFont: Bool) -> AttributedString? {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.currencyCode = currency.currencyCode
		if self.worth < 1 {
			formatter.maximumFractionDigits = 10
		}

		var attributedString = AttributedString(formatter.string(for: self.worth)!)

		let currencySymbol = formatter.currencySymbol ?? ""
		let symbolRange = attributedString.range(of: currencySymbol)

		guard isVisible else {
			let hiddenValue = "••••"
			if symbolRange!.lowerBound == attributedString.startIndex {
				return AttributedString(currencySymbol + hiddenValue)
			} else {
				return AttributedString(hiddenValue + currencySymbol)
			}
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
