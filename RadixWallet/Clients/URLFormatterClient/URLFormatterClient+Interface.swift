// MARK: - URLFormatterClient
struct URLFormatterClient {
	var fixedSizeImage: FixedSizeImage
	var generalImage: GeneralImage
}

// MARK: URLFormatterClient.FixedSizeImage
extension URLFormatterClient {
	typealias FixedSizeImage = @Sendable (URL, CGSize) -> URL
	typealias GeneralImage = @Sendable (URL) -> URL
}
