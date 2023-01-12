import ClientPrelude

// MARK: - FileClient
/// A file client, able to load a local file from a given file URL and options.
///
/// While usage in remote contexts is possible, this is strictly discouraged.
/// For such use case, please start a download task on a `URLSession` instead.
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
