import Prelude

// MARK: - P2PConnectionID
public struct P2PConnectionID: Sendable, Hashable, Codable, CustomStringConvertible {
	public let data: HexCodable

	public init(data: Data) throws {
		guard data.count == Self.byteCount else {
			loggerGlobal.error("ConnectionPassword:data bad length: \(data.count)")
			throw Error.incorrectByteCount(got: data.count, butExpected: Self.byteCount)
		}
		self.data = HexCodable(data: data)
	}
}

public extension P2PConnectionID {
	var description: String {
		data.hex()
	}
}

public extension P2PConnectionID {
	enum Error: Swift.Error {
		case incorrectByteCount(got: Int, butExpected: Int)
	}

	static let byteCount = 32
}

public func == (connectionIdString: String, connectionID: P2PConnectionID) -> Bool {
	connectionID == connectionIdString
}

public func == (connectionID: P2PConnectionID, connectionIdString: String) -> Bool {
	connectionID.hex() == connectionIdString
}

public extension P2PConnectionID {
	func hex(options: Data.HexEncodingOptions = []) -> String {
		data.hex(options: options)
	}
}

#if DEBUG
public extension P2PConnectionID {
	static let placeholder = try! Self(data: .deadbeef32Bytes)
}
#endif // DEBUG
