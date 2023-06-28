@_exported import Foundation
@_exported import JSONTesting
@_exported import XCTest

extension XCTestCase {
	public func assertFailingDecoding<T: Decodable>(
		json: String,
		type: T.Type = T.self
	) {
		let jsonDecoder = JSONDecoder()
		XCTAssertThrowsError(
			try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		)
	}
}
