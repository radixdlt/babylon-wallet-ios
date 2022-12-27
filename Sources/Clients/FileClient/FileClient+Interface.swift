import Foundation

// MARK: - FileClient
public struct FileClient: Sendable {
	public var read: ReadEffect

	public init(read: @escaping ReadEffect.ReadAction) {
		self.read = .init(read)
	}
}

// MARK: FileClient.ReadEffect
public extension FileClient {
	struct ReadEffect: Sendable {
		public typealias ReadAction = @Sendable (URL, Data.ReadingOptions) throws -> Data

		private let read: ReadAction

		public init(_ read: @escaping ReadAction) {
			self.read = read
		}

		public func callAsFunction(from url: URL, options: Data.ReadingOptions) throws -> Data {
			try read(url, options)
		}
	}
}
