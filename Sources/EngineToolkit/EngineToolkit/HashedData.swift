import Foundation

// MARK: - HashedData
/// A safe wrapper around data meant to guarantee that the wrapped data is hashed.
public struct HashedData: Sendable, Hashable, Codable {
	struct IncorretByteCountError: Swift.Error {
		let got: Int
		let expected: Int
	}

	static let byteCount = 32

	public let data: Data

	public var hex: String {
		data.hex
	}

	public init(data: Data) throws {
		guard data.count == Self.byteCount else {
			throw IncorretByteCountError(got: data.count, expected: Self.byteCount)
		}
		self.data = data
	}

	public init(hex: String) throws {
		try self.init(data: Data(hex: hex))
	}
}

// MARK: DataProtocol
extension HashedData: DataProtocol {
	public var regions: Data.Regions {
		data.regions
	}

	public typealias Regions = Data.Regions
}

extension HashedData {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(self.data)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(data: container.decode(Data.self))
	}
}

// MARK: RandomAccessCollection
extension HashedData: RandomAccessCollection {
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
