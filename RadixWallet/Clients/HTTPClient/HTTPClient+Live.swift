extension HTTPClient {
	static let liveValue: HTTPClient = {
		let session = URLSession.shared

		return .init(
			executeRequest: { request, acceptedStatusCodes in
				let (data, urlResponse) = try await {
					// Retrying only once seems to be enough, but better to be on the safe side and retry more.
					var retryAttempts = 5
					while retryAttempts > 0 {
						do {
							return try await session.data(for: request)
						} catch {
							// Handle the very obscure error when the CFNetwork drops the request after it being sent.
							// Note that NSURLErrorNetworkConnectionLost seems to be an opaque error hiding some other
							// possible error withing CFNetwork, it does not literally mean that hte network connection
							// was actually lost. This error will usually be thrown when the request was made right after
							// the app did come to foreground, it happens seldomly, but consistently.
							// As a workaround - retry the request if it failed initially.
							if let nsError = error as NSError?,
							   nsError.domain == NSURLErrorDomain,
							   nsError.code == NSURLErrorNetworkConnectionLost
							{
								retryAttempts -= 1
								continue
							}
							throw error
						}
					}
					throw RequestRetryAttemptsExceeded()
				}()

				guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
					throw ExpectedHTTPURLResponse()
				}

				guard let statusCode = httpURLResponse.status, acceptedStatusCodes.contains(statusCode) else {
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
