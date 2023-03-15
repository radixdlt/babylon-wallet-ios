import Prelude

// MARK: - MockURLProtocol
public class MockURLProtocol: URLProtocol {
	public static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
	override public class func canInit(with request: URLRequest) -> Bool { true }
	override public class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

	override public func startLoading() {
		guard let handler = MockURLProtocol.requestHandler else {
			fatalError("Handler unimplemented")
		}

		do {
			let (response, data) = try handler(request)
			client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
			if let data = data {
				client?.urlProtocol(self, didLoad: data)
			}
			client?.urlProtocolDidFinishLoading(self)
		} catch {
			client?.urlProtocol(self, didFailWithError: error)
		}
	}

	override public func stopLoading() {}
}
