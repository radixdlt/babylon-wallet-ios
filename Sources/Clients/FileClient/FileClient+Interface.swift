import Foundation

public struct FileClient: Sendable {
	public typealias Read = @Sendable (URL, Data.ReadingOptions) throws -> Data

	private let read: Read

	public init(read: @escaping Read) {
		self.read = read
	}

	public func read(from url: URL, options: Data.ReadingOptions) throws -> Data {
		try read(url, options)
	}
}
