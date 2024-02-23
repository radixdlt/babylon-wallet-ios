// MARK: - AddressFormat
public enum AddressFormat: String, Sendable {
	case `default`
	case olympia
	case full
	case nonFungibleLocalId
}

// FIXME: All this should be revisited when the LocalID support in ET is available
extension String {
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

extension SpecificAddress {
	public func formatted(_ format: AddressFormat) -> String {
		address.formattedAsAddressString(format)
	}
}

extension EngineToolkit.Address {
	public func formatted(_ format: AddressFormat) -> String {
		addressString().formattedAsAddressString(format)
	}
}

private extension String {
	func formattedAsAddressString(_ format: AddressFormat) -> Self {
		switch format {
		case .default:
			truncatedMiddle(keepFirst: 4, last: 6)
		case .olympia:
			truncatedMiddle(keepFirst: 3, last: 9)
		case .full:
			self
		case .nonFungibleLocalId:
			String(dropFirst().dropLast())
		}
	}

	func truncatedMiddle(keepFirst first: Int, last: Int) -> Self {
		guard count > first + last else { return self }
		return prefix(first) + "..." + suffix(last)
	}
}

// MARK: - NonFungibleFormat
public enum NonFungibleFormat: String, Sendable {
	case `default`
	case full
	case raw
}

extension NonFungibleGlobalId {
	public func formatted(_ format: NonFungibleFormat = .default) -> String {
		switch format {
		case .default:
			resourceAddress().formatted(.default) + ":" + localId().formatted(.default)
		case .full:
			resourceAddress().formatted(.full) + ":" + localId().formatted(.full)
		case .raw:
			asStr()
		}
	}
}

extension NonFungibleLocalId {
	public func formatted(_ format: NonFungibleFormat = .default) -> String {
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
