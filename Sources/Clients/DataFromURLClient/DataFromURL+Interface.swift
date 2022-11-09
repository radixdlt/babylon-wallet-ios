import Foundation

public struct ReadDataEffect {
	public typealias DataFromURL = @Sendable (URL, Data.ReadingOptions) throws -> Data

	private let dataFromURL: DataFromURL

	public init(dataFromURL: @escaping DataFromURL) {
	  self.dataFromURL = dataFromURL
	}

	public func callAsFunction(contentsOf url: URL, options: Data.ReadingOptions) throws -> Data {
		try dataFromURL(url, options)
	}
}
