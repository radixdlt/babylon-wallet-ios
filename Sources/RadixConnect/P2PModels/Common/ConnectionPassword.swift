import Prelude

// MARK: - ConnectionPassword
public struct ConnectionPassword:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible
{
	public let data: HexCodable

	public init(_ data: HexCodable) throws {
		guard data.count == Self.byteCount else {
			loggerGlobal.error("ConnectionPassword:data bad length: \(data.count)")
			throw Error.incorrectByteCount(got: data.count, butExpected: Self.byteCount)
		}
		self.data = data
	}

	public init(data: Data) throws {
		try self.init(HexCodable(data: data))
	}
}

extension ConnectionPassword {
	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(data)
	}

	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		try self.init(singleValueContainer.decode(HexCodable.self))
	}

	public init(hex: String) throws {
		do {
			let data = try Data(hex: hex)
			try self.init(data: data)
		} catch {
			loggerGlobal.error("ConnectionPassword:hexString hex to data error: \(error)")
			throw error
		}
	}
}

// MARK: CustomStringConvertible
extension ConnectionPassword {
	public var description: String {
		data.hex()
	}
}

extension ConnectionPassword {
	public enum Error: Swift.Error {
		case incorrectByteCount(got: Int, butExpected: Int)
	}

	public static let byteCount = 32

	public func hex(options: Data.HexEncodingOptions = []) -> String {
		data.hex(options: options)
	}
}

#if DEBUG
extension ConnectionPassword {
	public static let placeholder = try! Self(data: .deadbeef32Bytes)

	public static func random() throws -> Self {
		try .init(data: .random(byteCount: Self.byteCount))
	}
}
#endif // DEBUG
