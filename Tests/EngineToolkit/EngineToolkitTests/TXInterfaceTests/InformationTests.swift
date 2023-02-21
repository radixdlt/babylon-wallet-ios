import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.8.0",
				gitHash: "d6dbcead25e6e7cc2fb229e3b1ef79ea6371f423"
			)
		)
	}
}
