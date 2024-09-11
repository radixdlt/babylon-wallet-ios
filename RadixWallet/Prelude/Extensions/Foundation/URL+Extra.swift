
extension URL {
	public var httpsURL: Self? {
		var absoluteString = self.absoluteString
		if let separator = absoluteString.range(of: "://") {
			absoluteString.removeSubrange(absoluteString.startIndex ..< separator.upperBound)
		}
		let httpsString = "https://" + absoluteString
		return .init(string: httpsString)
	}

	/// A computed property that parses the query parameters of the URL into a dictionary.
	///
	/// - Returns: A dictionary of query parameters, or `nil` if the URL has no query items.
	public var queryParameters: [String: String]? {
		guard
			let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
			let queryItems = components.queryItems
		else { return nil }

		return queryItems.reduce(into: [String: String]()) { result, item in
			result[item.name] = item.value
		}
	}

	/// Determines if the URL follows the [RFC 2397](https://datatracker.ietf.org/doc/html/rfc2397) specification for Data URLs.
	///
	/// A Data URL is a URI scheme that allows inclusion of small data items
	/// as "immediate" data, encoded in Base64 or as plain text, rather than referencing external files.
	///
	/// - Returns: `true` if the URL's scheme is "data", indicating it conforms to the Data URL format; otherwise, `false`.
	public var isDataURL: Bool {
		scheme == "data"
	}
}

// MARK: - URL + Identifiable
extension URL: Identifiable {
	public var id: URL { self.absoluteURL }
}
