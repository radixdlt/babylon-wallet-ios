

extension NonFungibleLocalId {
	public static func from(stringFormat: String) throws -> Self {
		try nonFungibleLocalIdFromStr(string: stringFormat)
	}

	public func toString() throws -> String {
		try nonFungibleLocalIdAsStr(value: self)
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

// MARK: - NonFungibleLocalId + Identifiable
extension NonFungibleLocalId: Identifiable {
	public var id: String {
		do {
			return try nonFungibleLocalIdAsStr(value: self)
		} catch {
			assertionFailure("Failed to convert nft id to string!! \(error)")
			return ""
		}
	}
}

// MARK: - NonFungibleLocalId + Codable
extension NonFungibleLocalId: Codable {
	enum CodingKeys: CodingKey {
		case integer
		case str
		case bytes
		case ruid
	}

	public init(from decoder: Decoder) throws {
		panic()
	}

	public func encode(to encoder: Encoder) throws {
//
		panic()
	}
}
