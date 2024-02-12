import Foundation

// MARK: - NonFungibleLocalId
public enum NonFungibleLocalId: DummySargon {
	public static func from(stringFormat: Any) -> Self {
		panic()
	}

	public static func integer(value: Int) -> Self {
		panic()
	}

	public static func from(stringFormat: String) throws -> Self {
		try Sargon.nonFungibleLocalIdFromStr(string: stringFormat)
	}

	public func toString() throws -> String {
		Sargon.nonFungibleLocalIdAsStr(value: self)
	}

	public func toUserFacingString() -> String {
		do {
			let rawValue = try toString()
			// Just a safety guard. Each NFT Id should be of format <prefix>value<suffix>
			guard rawValue.count >= 3 else {
				loggerGlobal.warning("Invalid nft id: \(rawValue)")
				return rawValue
			}
			// Nothing fancy, just remove the prefix and suffix.
			return String(rawValue.dropLast().dropFirst())
		} catch {
			// Should not happen, just to not throw an error.
			return ""
		}
	}
}