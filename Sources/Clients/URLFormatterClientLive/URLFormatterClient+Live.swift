import ClientPrelude
import URLFormatterClient

// MARK: - URLFormatterClient + DependencyKey
extension URLFormatterClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
		url imageServiceURL: URL = defaultImageServiceURL
	) -> Self {
		Self(
			fixedSizeImage: { url, size in
				let originItem = URLQueryItem(name: "imageOrigin", value: url.absoluteString)
				let sizeItem = URLQueryItem(name: "imageSize", value: imageSizeString(size: size))

				return imageServiceURL.appending(queryItems: [originItem, sizeItem])
			}
		)
	}

	#if DEBUG
	public static let defaultImageServiceURL = URL(string: "https://image-service-dev.extratools.works")!
	#else
	public static let defaultImageServiceURL = URL(string: "https://image-service.radixdlt.com")!
	#endif

	private static func imageSizeString(size: CGSize) -> String {
		"\(max(minSize, Int(round(size.width))))x\(max(minSize, Int(round(size.height))))"
	}

	/// The minimum length of the sides, in pixels, of a requested image
	private static var minSize: Int { 64 }
}
