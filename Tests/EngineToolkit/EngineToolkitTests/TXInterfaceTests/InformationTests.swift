import Prelude

final class InformationTests: TestCase {
	func test__information() throws {
		let information = try sut.information().get()
		XCTAssertNoDifference(
			information,
			.init(
				packageVersion: "0.9.0",
				lastCommitHash: "c9cd92a53fb6cdb9b67e1463eabe0cc164d9df16"
			)
		)
	}
}
