import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.8.0",
				gitHash: "2117ac3061ceaf609331a90f995f0bc0e75eb386"
			)
		)
	}
}
