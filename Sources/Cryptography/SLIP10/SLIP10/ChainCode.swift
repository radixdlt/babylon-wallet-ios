import Foundation

// MARK: - ChainCode
public struct ChainCode: Hashable {
	public let chainCode: Data
	public init(data: Data) throws {
		guard data.count == Self.byteCount else {
			throw Error.incorrectByteCount(expected: Self.byteCount, butGot: data.count)
		}
		self.chainCode = data
	}
}

public extension ChainCode {
	static let byteCount = 32
	enum Error: Swift.Error {
		case incorrectByteCount(expected: Int, butGot: Int)
	}
}
