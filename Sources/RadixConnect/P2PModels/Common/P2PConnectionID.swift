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

extension P2PConnectionID {
	public var description: String {
		data.hex()
	}
}

extension P2PConnectionID {
	public enum Error: Swift.Error {
		case incorrectByteCount(got: Int, butExpected: Int)
	}

	public static let byteCount = 32
}

public func == (connectionIdString: String, connectionID: P2PConnectionID) -> Bool {
	connectionID == connectionIdString
}

public func == (connectionID: P2PConnectionID, connectionIdString: String) -> Bool {
	connectionID.hex() == connectionIdString
}

extension P2PConnectionID {
	public func hex(options: Data.HexEncodingOptions = []) -> String {
		data.hex(options: options)
	}
}

#if DEBUG
extension P2PConnectionID {
	public static let placeholder = try! Self(data: .deadbeef32Bytes)
}
#endif // DEBUG
