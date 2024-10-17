// MARK: - URLFormatterClient
struct URLFormatterClient: Sendable {
	var fixedSizeImage: FixedSizeImage
	var generalImage: GeneralImage

	init(
		fixedSizeImage: @escaping FixedSizeImage,
		generalImage: @escaping GeneralImage
	) {
		self.fixedSizeImage = fixedSizeImage
		self.generalImage = generalImage
	}
}

// MARK: URLFormatterClient.FixedSizeImage
extension URLFormatterClient {
	typealias FixedSizeImage = @Sendable (URL, CGSize) -> URL
	typealias GeneralImage = @Sendable (URL) -> URL
}
