import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.8.0",
				gitHash: "aaec52b9ae9cda7bcfb8dd17bcf72b21c5968656"
			)
		)
	}
}
