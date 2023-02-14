import BigDecimal
import Foundation

extension FiatCurrency {
	var separatorWithAmount: String {
		switch self {
		case .eur, .usd, .gbp: return ""
		case .sek: return " "
		}
	}

	func formattedWith(
		amount formattedAmount: String
	) -> String {
		let components = formattingPlacement == .leading ? [sign, formattedAmount] : [formattedAmount, sign]
		return components.joined(separator: separatorWithAmount)
	}
}

extension BigDecimal {
	public func format(
		currency: FiatCurrency? = nil,
		maxPlaces: Int = 8,
		locale: Locale = .current
	) -> String {
		// N.B. We CANNOT use `Local.current.decimalSeperator` here because
		// `github.com/Zollerbo1/BigDecimal` package **hardcodes** usage of
		// the decimal separator ".", see this line here:
		// https://github.com/Zollerboy1/BigDecimal/blob/main/Sources/BigDecimal/BigDecimal.swift#L469
		let separatorRequiredByBigDecimalLib = "."
		let stringRepresentation = String(describing: self)

		guard
			case let components = stringRepresentation.split(separator: separatorRequiredByBigDecimalLib),
			components.count == 2
		else {
			if let currency {
				return currency.formattedWith(amount: stringRepresentation)
			} else {
				return stringRepresentation
			}
		}

		let integerPart = String(components[0])
		let decimalPart = String(components[1])
		let numberOfDecimalDigits = max(maxPlaces - integerPart.count, 1)

		let decimalSeparatorMaybeAccordingToLocal = locale.decimalSeparator ?? "."
		let decimalPartPrefixWith0AndSeparator = "0" + decimalSeparatorMaybeAccordingToLocal + decimalPart

		func bailout() -> String {
			// for some reason failed to create `Decimal` fall back to best we can do,
			// N.B. that this will format => `0.99999999999999999` as "0.9999999", and not as `"1"` (which we want)
			let truncatedDecimalPart = String(decimalPart.prefix(numberOfDecimalDigits))

			let formattedAmount = [
				integerPart,
				truncatedDecimalPart,
			].joined(separator: decimalSeparatorMaybeAccordingToLocal)

			if let currency {
				return currency.formattedWith(amount: formattedAmount)
			} else {
				return formattedAmount
			}
		}

		guard let decimal = Foundation.Decimal(string: decimalPartPrefixWith0AndSeparator, locale: locale) else {
			return bailout()
		}

		let numberFormatter = NumberFormatter()
		numberFormatter.locale = locale
		numberFormatter.maximumFractionDigits = numberOfDecimalDigits
		guard let formattedDecimalPartWith0AndSeparator = numberFormatter.string(for: decimal) else {
			return bailout()
		}

		let componentsFromDecimal = formattedDecimalPartWith0AndSeparator.split(separator: decimalSeparatorMaybeAccordingToLocal)

		if componentsFromDecimal.count == 1 {
			guard let bigInt = try? BigDecimal(fromString: integerPart) else {
				return bailout()
			}

			let formatted = bigInt.isZero ? formattedDecimalPartWith0AndSeparator : integerPart

			if let currency {
				return currency.formattedWith(amount: formatted)
			} else {
				return formatted
			}
		}

		guard
			componentsFromDecimal.count == 2,
			case let formattedDecimalPart = String(componentsFromDecimal[1])
		else {
			return bailout()
		}

		let formattedAmount = [
			integerPart,
			formattedDecimalPart,
		].joined(separator: decimalSeparatorMaybeAccordingToLocal)

		if let currency {
			return currency.formattedWith(amount: formattedAmount)
		} else {
			return formattedAmount
		}
	}
}
