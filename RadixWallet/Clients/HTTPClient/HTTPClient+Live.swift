extension HTTPClient {
	public static let liveValue: HTTPClient = {
		let session = URLSession.shared

		return .init(
			executeRequest: { request, isStatusCodeValid in
				let (data, urlResponse) = try await session.data(for: request)

				guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
					throw ExpectedHTTPURLResponse()
				}

				let isSuccessStatusCode = isStatusCodeValid?(httpURLResponse.statusCode) ?? (httpURLResponse.statusCode == BadHTTPResponseCode.expected)
				guard isSuccessStatusCode else {
					#if DEBUG
					loggerGlobal.error("Request with URL: \(request.url!.absoluteString) failed with status code: \(httpURLResponse.statusCode), data: \(data.prettyPrintedJSONString ?? "<NOT_JSON>")")
					#endif
					throw BadHTTPResponseCode(got: httpURLResponse.statusCode)
				}

				return data
			}
		)
	}()
}
