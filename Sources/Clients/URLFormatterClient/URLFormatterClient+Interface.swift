import ClientPrelude

// MARK: - URLFormatterClient
public struct URLFormatterClient: Sendable {
	public var fixedSizeImage: FixedSizeImage

	public init(
		fixedSizeImage: @escaping FixedSizeImage
	) {
		self.fixedSizeImage = fixedSizeImage
	}
}

// MARK: URLFormatterClient.FixedSizeImage
extension URLFormatterClient {
	public typealias FixedSizeImage = @Sendable (URL, CGSize) -> URL
}
