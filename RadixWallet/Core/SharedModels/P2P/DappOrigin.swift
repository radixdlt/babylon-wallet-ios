import Foundation

// MARK: - DappOrigin
public struct DappOrigin: Sendable, Hashable, Codable {
	public static let wallet: DappOrigin = {
		let walletAppScheme = "com.radixpublishing.radixwallet.ios"
		return .init(urlString: .init(stringLiteral: walletAppScheme), url: .init(string: walletAppScheme)!)
	}()

	public let urlString: NonEmptyString
	public let url: URL

	public func encode(to encoder: Encoder) throws {
		var singleValueContainer = encoder.singleValueContainer()
		try singleValueContainer.encode(urlString.rawValue)
	}

	public init(urlString: NonEmptyString, url: URL) {
		self.urlString = urlString
		self.url = url
	}

	struct InvalidOriginURL: Error {}

	public init(string: String) throws {
		guard
			let urlNonEmpty = NonEmptyString(rawValue: string),
			let url = URL(string: string)
		else {
			throw InvalidOriginURL()
		}
		self.init(urlString: urlNonEmpty, url: url)
	}

	public init(from decoder: Decoder) throws {
		let singleValueContainer = try decoder.singleValueContainer()
		let urlStringString = try singleValueContainer.decode(String.self)
		try self.init(string: urlStringString)
	}
}
