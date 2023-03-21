import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "557e37f3f857ceb3d4a0aa17a3b6a645b894be71"
			)
		)
	}
}
