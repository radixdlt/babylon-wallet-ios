// MARK: - AddressFormat
public enum AddressFormat: String, Sendable {
	case `default`
	case full
	case raw
}

extension LegacyOlympiaAccountAddress {
	public func formatted(_ format: AddressFormat = .default) -> String {
		switch format {
		case .default:
			address.truncatedMiddle(keepFirst: 3, last: 9)
		case .full, .raw:
			address
		}
	}
}

private extension String {
	func formattedAsAddressString(_ format: AddressFormat) -> Self {
		switch format {
		case .default:
			truncatedMiddle(keepFirst: 4, last: 6)
		case .full, .raw:
			self
		}
	}

	func truncatedMiddle(keepFirst first: Int, last: Int) -> Self {
		guard count > first + last else { return self }
		return prefix(first) + "..." + suffix(last)
	}
}
