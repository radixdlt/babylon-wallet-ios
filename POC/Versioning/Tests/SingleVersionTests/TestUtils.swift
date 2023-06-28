import Foundation
@testable import SingleVersion
import XCTest

extension XCTestCase {
	func assertFailingDecoding<T: Decodable>(
		json: String,
		type: T.Type = T.self
	) {
		let jsonDecoder = JSONDecoder()
		XCTAssertThrowsError(
			try jsonDecoder.decode(T.self, from: json.data(using: .utf8)!)
		)
	}
}
