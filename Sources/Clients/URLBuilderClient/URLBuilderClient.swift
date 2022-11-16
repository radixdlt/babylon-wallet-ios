import Dependencies
import Foundation

// MARK: - URLBuilderClient
public struct URLBuilderClient: DependencyKey {
	public var urlFromString: URLFromString
	public var formatURL: FormatURL

	public init(
		urlFromString: @escaping URLFromString,
		formatURL: @escaping FormatURL
	) {
		self.urlFromString = urlFromString
		self.formatURL = formatURL
	}
}

// MARK: URLBuilderClient.URLFromString
public extension URLBuilderClient {
	typealias URLFromString = @Sendable (String) throws -> URL
	typealias FormatURL = @Sendable (URL) -> String
}

public extension URLBuilderClient {
	struct InvalidURL: Swift.Error, CustomStringConvertible {
		public let description: String
	}

	static let liveValue: Self = .init(
		urlFromString: { urlString in
			guard let url = URL(string: urlString) else {
				throw InvalidURL(description: "Invalid url string: \(urlString)")
			}
			return url
		},
		formatURL: { $0.absoluteString }
	)
}

public extension DependencyValues {
	var urlBuilder: URLBuilderClient {
		get { self[URLBuilderClient.self] }
		set { self[URLBuilderClient.self] = newValue }
	}
}
