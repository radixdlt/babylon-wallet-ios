import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "632eb90dff8cdfe8195285588caf2f55cfb486ae"
			)
		)
	}
}
