// MARK: - URLFormatterClient + DependencyKey

extension URLFormatterClient: DependencyKey {
	public static let liveValue = Self.live()

	public static func live(
		url imageServiceURL: URL = defaultImageServiceURL
	) -> Self {
		Self(
			fixedSizeImage: { url, size in
				makeURL(url: url, imageServiceURL: imageServiceURL, size: size)
			},
			generalImage: { url in
				makeURL(url: url, imageServiceURL: imageServiceURL, size: maxFlexibleSize)
			}
		)
	}

	#if DEBUG
	public static let defaultImageServiceURL = URL(string: "https://image-service-dev.extratools.works")!
	#else
	public static let defaultImageServiceURL = URL(string: "https://image-service.radixdlt.com")!
	#endif

	private static func makeURL(url: URL, imageServiceURL: URL, size: CGSize) -> URL {
		if url.isDataURL {
			// Data URLs (e.g., `data:image/svg+xml,`) require special encoding to handle special characters.
			// Here, we encode the absolute string using percent encoding, allowing only alphanumeric characters.
			// This is needed because `url.appending(queryItems:)` does not encode special characters correctly for data URLs.
			let imageOrigin = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
			let imageSize = imageSizeString(size: size)

			// Manually construct the query string to ensure that the data URL is correctly encoded
			// and to avoid issues like double-encoding, which could corrupt the URL.
			var urlString = "\(imageServiceURL.absoluteString)/?imageOrigin=\(imageOrigin)&imageSize=\(imageSize)"

			if url.isVectorImage(type: .svg) {
				urlString.append("&format=png")
			}

			return URL(string: urlString)!
		} else {
			let originItem = URLQueryItem(name: "imageOrigin", value: url.absoluteString)
			let sizeItem = URLQueryItem(name: "imageSize", value: imageSizeString(size: size))
			let formatItem: URLQueryItem? = url.isVectorImage(type: .svg) ? URLQueryItem(name: "format", value: "png") : nil

			// Append the query items. This works fine for regular URLs (not data URLs) that don't require special encoding handling.
			return imageServiceURL.appending(queryItems: [originItem, sizeItem, formatItem].compactMap { $0 })
		}
	}

	private static func imageSizeString(size: CGSize) -> String {
		"\(max(minSize, Int(round(size.width))))x\(max(minSize, Int(round(size.height))))"
	}

	// MARK: Helpers for fixedSizeImage

	/// The minimum length of the sides, in pixels, of a requested image
	private static let minSize: Int = 64

	private static let maxFlexibleSize = CGSize(width: 1024, height: 1024)
}
