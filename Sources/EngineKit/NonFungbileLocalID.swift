import EngineToolkit
import Prelude

extension NonFungibleLocalId {
	struct InvalidLocalID: Error {}

	public static func from(stringFormat: String) throws -> Self {
		guard stringFormat.count >= 3 else {
			loggerGlobal.warning("Invalid nft id: \(stringFormat)")
			throw InvalidLocalID()
		}
		let prefix = stringFormat.prefix(1)
		let value = String(stringFormat.dropLast().dropFirst())
		switch prefix {
		case "#":
			guard let value = UInt64(value) else {
				throw InvalidLocalID()
			}
			return .integer(value: value)
		case "{":
			return .ruid(value: [])
		case "<":
			return .str(value: value)
		case "[":
			return try .bytes(value: value.map {
				guard let byte = UInt8(String($0)) else {
					throw InvalidLocalID()
				}
				return byte
			})
		default:
			throw InvalidLocalID()
		}
	}

	public func toString() throws -> String {
		try nonFungibleLocalIdAsStr(value: self)
	}
}
