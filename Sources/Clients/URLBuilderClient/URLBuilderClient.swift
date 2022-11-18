import Dependencies
import Foundation

// MARK: - URLBuilderClient
public struct URLBuilderClient: DependencyKey {
	public var urlFromInput: URLFromInput
	public var formatURL: FormatURL
	public var componentsFromURL: ComponentsFromURL

	public init(
		urlFromInput: @escaping URLFromInput,
		formatURL: @escaping FormatURL,
		componentsFromURL: @escaping ComponentsFromURL
	) {
		self.urlFromInput = urlFromInput
		self.formatURL = formatURL
		self.componentsFromURL = componentsFromURL
	}
}

// MARK: URLBuilderClient.URLFromString
public extension URLBuilderClient {
	typealias URLFromInput = @Sendable (URLInput) throws -> URL
	typealias ComponentsFromURL = @Sendable (URL) throws -> URLInput
	typealias FormatURL = @Sendable (URL) -> String
}

// MARK: - URLInput
public struct URLInput: Sendable, Hashable {
	/// https or http
	public let scheme: Scheme
	public let host: Host
	public let path: Path
	public let port: Port?

	public init(
		host: Host,
		scheme: Scheme = "https",
		path: Path = "",
		port: Port? = nil
	) {
		self.host = host
		self.scheme = scheme
		self.port = port
		self.path = path
	}
}

public extension URLInput {
	init?(components: URLComponents) {
		guard let host = components.host else {
			return nil
		}
		self.init(
			host: host,
			scheme: components.scheme ?? "https",
			path: components.path,
			port: components.port.map { Port($0) }
		)
	}
}

public extension URLInput {
	/// https or http
	typealias Scheme = String

	typealias Path = String

	typealias Port = UInt

	/// either DNS or IP address, without port or scheme
	typealias Host = String
}

public extension URLBuilderClient {
	static let liveValue: Self = .init(
		urlFromInput: { input in
			var components = URLComponents()
			components.scheme = input.scheme
			components.port = input.port.map { Int($0) }
			components.host = input.host
			components.path = input.path
			guard let url = components.url else {
				throw InvalidURLError(input: input)
			}
			return url
		},
		formatURL: { $0.absoluteString },
		componentsFromURL: { url in
			guard
				let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
			else {
				fatalError()
			}
			guard let urlInput = URLInput(components: components) else {
				throw FailedToDeserializeURLError(url: url)
			}
			return urlInput
		}
	)
}

public extension DependencyValues {
	var urlBuilder: URLBuilderClient {
		get { self[URLBuilderClient.self] }
		set { self[URLBuilderClient.self] = newValue }
	}
}

// MARK: - InvalidURLError
public struct InvalidURLError: LocalizedError {
	public let input: URLInput

	public var errorDescription: String? {
		"Invalid URL from input: scheme=\(input.scheme), host=\(input.host), port=\(String(describing: input.port))"
	}
}

// MARK: - FailedToDeserializeURLError
public struct FailedToDeserializeURLError: LocalizedError {
	public let url: URL

	public var errorDescription: String? {
		"Failed to get components from URL: \(url.absoluteString)"
	}
}
