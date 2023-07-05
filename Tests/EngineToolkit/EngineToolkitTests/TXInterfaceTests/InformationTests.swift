import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "663e9cc3e04c388c03aff0a9e64406ae88d71325"
			)
		)
	}
}
