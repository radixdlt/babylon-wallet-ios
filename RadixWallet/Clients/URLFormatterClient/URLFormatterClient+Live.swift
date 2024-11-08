// MARK: - URLFormatterClient + DependencyKey

extension URLFormatterClient: DependencyKey {
	static let liveValue = Self.live()

	static func live(
		url imageServiceURL: URL = defaultImageServiceURL
	) -> Self {
		Self(
			fixedSizeImage: { url, size in
				(try? url.imageURL(imageServiceURL: imageServiceURL, size: size)) ?? url
			},
			generalImage: { url in
				(try? url.imageURL(imageServiceURL: imageServiceURL, size: maxFlexibleSize)) ?? url
			}
		)
	}

	#if DEBUG
	static let defaultImageServiceURL = URL(string: "https://image-service-dev.extratools.works")!
	#else
	static let defaultImageServiceURL = URL(string: "https://image-service.radixdlt.com")!
	#endif

	private static let maxFlexibleSize = CGSize(width: 1024, height: 1024)
}
