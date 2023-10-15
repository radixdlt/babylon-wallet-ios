// MARK: - URLFormatterClient
public struct URLFormatterClient: Sendable {
	public var fixedSizeImage: FixedSizeImage
	public var generalImage: GeneralImage

	public init(
		fixedSizeImage: @escaping FixedSizeImage,
		generalImage: @escaping GeneralImage
	) {
		self.fixedSizeImage = fixedSizeImage
		self.generalImage = generalImage
	}
}

// MARK: URLFormatterClient.FixedSizeImage
extension URLFormatterClient {
	public typealias FixedSizeImage = @Sendable (URL, CGSize) -> URL
	public typealias GeneralImage = @Sendable (URL) -> URL
}
