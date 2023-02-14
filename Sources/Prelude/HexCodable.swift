import Foundation

// MARK: - HexCodable
/// A thin wrapper around `Data` making sure it is always Encoded to a hexadecimal string and can
/// always be decoded from a hexadecimal string. It is also `Sendable`, `Identifiable`, and conforms
/// to `DataProtocol`.
///
/// This type is made obsolete if one is using custom Encoder/Decoder using `Hex` as Data encoding/
/// decoding strategy, but it is quite strict to require that because some data we might want to
/// Base64 encode/decode. An alternative is of course to create a variant of this type but `Base64Codable`,
/// which overrides the data coding strategy of the encoder.
public struct HexCodable:
	Sendable,
	Hashable,
	Codable,
	Identifiable,
	CustomStringConvertible,
	DataProtocol
{
	/// The underlying `Data` that is always hex coded.
	public let data: Data

	public init(data: Data) {
		self.data = data
	}
}

// MARK: Hex
extension HexCodable {
	public init(hex: String) throws {
		try self.init(data: Data(hex: hex))
	}

	public func hex(options: Data.HexEncodingOptions = []) -> String {
		data.hex(options: options)
	}
}

// MARK: Identifiable
extension HexCodable {
	public typealias ID = String

	/// The underlying `data` as a hex string.
	public var id: ID {
		data.hex()
	}
}

// MARK: DataProtocol
extension HexCodable {
	public typealias Regions = Data.Regions

	public var regions: Regions {
		data.regions
	}
}

// MARK: RandomAccessCollection
extension HexCodable {
	public typealias Element = Data.Element
	public typealias SubSequence = Data.SubSequence
	public typealias Index = Data.Index
	public typealias Indices = Data.Indices

	public var endIndex: Index {
		data.endIndex
	}

	public var indices: Indices {
		data.indices
	}

	public var startIndex: Index {
		data.startIndex
	}

	public func formIndex(after index: inout Index) {
		data.formIndex(after: &index)
	}

	public func formIndex(before index: inout Index) {
		data.formIndex(before: &index)
	}

	public subscript(bounds: Range<Index>) -> SubSequence {
		data[bounds]
	}

	public subscript(position: Index) -> Element {
		data[position]
	}
}

// MARK: Codable
extension HexCodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		let data = try Data(hex: container.decode(String.self))
		self.init(data: data)
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(data.hex())
	}
}

// MARK: CustomStringConvertible
extension HexCodable {
	public var description: String {
		data.hex()
	}
}

#if canImport(CustomDump)
import CustomDump
extension HexCodable: CustomDumpRepresentable {
	public var customDumpValue: Any {
		data.hex()
	}
}
#endif // canImport(CustomDump)

#if DEBUG
extension HexCodable: ExpressibleByStringLiteral {
	public init(stringLiteral value: StringLiteralType) {
		try! self.init(hex: value)
	}
}

extension HexCodable {
	public static let deadbeef32Bytes = Self(data: .deadbeef32Bytes)
}
#endif // DEBUG
