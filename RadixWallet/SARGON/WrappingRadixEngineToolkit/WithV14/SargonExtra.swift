import Foundation

extension TXID {
	public static func fromStr(string: String, networkId: NetworkID) -> Self {
		sargon()
	}
}

extension RETDecimal {
	public func asDouble() -> Double {
		sargon()
	}

	public static func min() -> Self {
		sargon()
	}

	public func abs() -> Self {
		sargon()
	}
}

extension ResourceAddress {
	public static var mainnetXRDAddress: Self {
		sargon()
	}
}

extension NonFungibleGlobalId {
	public func formatted(_ format: AddressFormat = .default) -> String {
//		switch format {
//		case .default, .full:
//			resourceAddress().formatted(format) + ":" + localId().formatted(format)
//		case .raw:
//			asStr()
//		}
		sargon()
	}
}

extension NonFungibleLocalId {
	public func formatted(_ format: AddressFormat = .default) -> String {
//		switch format {
//		case .default:
//			switch self {
//			case .integer, .str, .bytes:
//				toUserFacingString()
//			case .ruid:
//				toUserFacingString().truncatedMiddle(keepFirst: 4, last: 4)
//			}
//		case .full:
//			toUserFacingString()
//		case .raw:
//			(try? toString()) ?? "" // Should never throw
//		}
		sargon()
	}
}
