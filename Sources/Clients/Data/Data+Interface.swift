import Foundation

public struct DataEffect {
	public typealias ContentsOfURL = @Sendable (URL, Data.ReadingOptions) throws -> Data

	private let contentsOfURL: ContentsOfURL

	public init(contentsOfURL: @escaping ContentsOfURL) {
		self.contentsOfURL = contentsOfURL
	}

	public func callAsFunction(contentsOf url: URL, options: Data.ReadingOptions) throws -> Data {
		try contentsOfURL(url, options)
	}
}
