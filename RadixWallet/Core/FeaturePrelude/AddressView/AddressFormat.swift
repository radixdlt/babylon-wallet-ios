// MARK: - AddressFormat
public enum AddressFormat: String, Sendable {
	case `default`
	case olympia
	case full
	case nonFungibleLocalId
}

// FIXME: All this should be revisited when the LocalID support in ET is available
extension String {
	public func truncatedMiddle(keepFirst first: Int, last: Int) -> Self {
		guard count > first + last else { return self }
		return prefix(first) + "..." + suffix(last)
	}

	public func formatted(_ format: AddressFormat) -> Self {
		switch format {
		case .default:
			return truncatedMiddle(keepFirst: 4, last: 6)
		case .olympia:
			return truncatedMiddle(keepFirst: 3, last: 9)
		case .full:
			return self
		case .nonFungibleLocalId:
			guard let local = local(), local.count >= 3 else { return self }
			return String(local.dropFirst().dropLast())
		}
	}

	private func local() -> String? {
		let parts = split(separator: ":")
		guard parts.count == 2 else { return nil }
		return String(parts[1])
	}
}
