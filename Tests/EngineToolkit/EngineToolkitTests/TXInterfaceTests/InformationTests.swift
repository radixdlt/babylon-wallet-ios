import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "9d140797d5641179fa78566b0f3e66fc6fe01e4c"
			)
		)
	}
}
