import Foundation

// MARK: - AddressFormat
public enum AddressFormat: String, Sendable {
	case `default`
	case nonFungibleLocalId
}

extension String {
	public func truncatedMiddle(keepFirst first: Int, last: Int) -> Self {
		guard count > first + last else { return self }
		return prefix(first) + "..." + suffix(last)
	}

	public func colonSeparated() -> Self {
		guard let index = range(of: ":")?.upperBound else { return self }
		return String(self[index...])
	}

	public func formatted(_ format: AddressFormat) -> Self {
		switch format {
		case .default:
			return truncatedMiddle(keepFirst: 4, last: 6)
		case .nonFungibleLocalId:
			return colonSeparated()
		}
	}
}
