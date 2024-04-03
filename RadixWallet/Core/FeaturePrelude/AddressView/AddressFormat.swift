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
			address.rawValue.truncatedMiddle(keepFirst: 3, last: 9)
		case .full, .raw:
			address.rawValue
		}
	}
}

extension SpecificAddress {
	/// The default format is truncated in the middle
	public func formatted(_ format: AddressFormat = .default) -> String {
		address.formattedAsAddressString(format)
	}
}

extension EngineToolkit.Address {
	/// The default format is truncated in the middle
	public func formatted(_ format: AddressFormat = .default) -> String {
		addressString().formattedAsAddressString(format)
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

extension NonFungibleGlobalId {
	public func formatted(_ format: AddressFormat = .default) -> String {
		switch format {
		case .default, .full:
			resourceAddress().formatted(format) + ":" + localId().formatted(format)
		case .raw:
			asStr()
		}
	}
}

extension NonFungibleLocalId {
	public func formatted(_ format: AddressFormat = .default) -> String {
		switch format {
		case .default:
			switch self {
			case .integer, .str, .bytes:
				toUserFacingString()
			case .ruid:
				toUserFacingString().truncatedMiddle(keepFirst: 4, last: 4)
			}
		case .full:
			toUserFacingString()
		case .raw:
			(try? toString()) ?? "" // Should never throw
		}
	}
}

extension TXID {
	public func formatted(_ format: AddressFormat = .default) -> String {
		let str = asStr()

		switch format {
		case .default:
			return str.truncatedMiddle(keepFirst: 4, last: 6)
		case .full, .raw:
			return str
		}
	}
}
