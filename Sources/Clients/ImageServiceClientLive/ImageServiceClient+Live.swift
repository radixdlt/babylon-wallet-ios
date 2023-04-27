import ClientPrelude
import ImageServiceClient

// MARK: - ImageServiceClient + DependencyKey
extension ImageServiceClient: DependencyKey {
	public typealias Value = ImageServiceClient

	public static let liveValue = Self.live()

	public static func live(
		url imageServiceURL: URL = defaultURL) -> Self
	{
		Self(
			fixedSize: { url, size in
				print("========= ImageServiceClient")
				let originItem = URLQueryItem(name: "imageOrigin", value: url.absoluteString)
				let sizeItem = URLQueryItem(name: "imageSize", value: size.imageSizeString)

				return imageServiceURL.appending(queryItems: [originItem, sizeItem])
			}
		)
	}

	public static var defaultURL: URL = .init(string: "https://images-service.extratools.works")!
}

private extension CGSize {
	var imageSizeString: String {
		"\(Int(round(width)))x\(Int(round(height)))"
	}
}
